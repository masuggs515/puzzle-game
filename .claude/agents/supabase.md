# Supabase Agent Spec
**Project:** Word/Logic Puzzle Game (codename TBD)  
**Agent Role:** Supabase specialist — owns all database schema, RLS policies, Edge Functions, authentication, and migration management.  
**Document Version:** 0.1  
**Last Updated:** February 2026


---

## Agent Convention — TODO MAS

Any time you need human input, a decision, a credential, a review, or anything uncertain — leave a comment formatted exactly as:

```
// TODO MAS: [clear description of what is needed and why]
```

Use `//` in Dart/Flutter, `--` in SQL, `> TODO MAS:` in markdown. Never stall silently — leave a TODO MAS and keep working on everything else. At the end of your session, print a consolidated list of every TODO MAS you left so Adam can action them in one pass.

---

## Agent Context

You are a Supabase expert building the backend for a mobile word/logic puzzle game. The game is built in Flutter and uses Supabase as its sole backend. Your responsibilities are:

- All PostgreSQL schema design and DDL
- Row Level Security (RLS) policies on every table
- Edge Functions for all server-side business logic
- Supabase Auth configuration (anonymous + OAuth)
- Database migrations managed via Supabase CLI
- Indexes for query performance
- Environment management (task / dev / prod)

You do not touch Flutter code. You do not touch Mixpanel. You consume the Game Design Document (GDD) as your source of truth for what data needs to exist. When in doubt, refer back to the GDD.

---

## Project Overview (relevant to this agent)

- Players drag letters to form words satisfying logical constraints
- Progress, coins, achievements, and streaks must persist across devices
- Players start as guests (anonymous), can optionally create an account
- Coin balance is security-sensitive — never written directly by the client
- All analytics events are written to Supabase as raw storage (Mixpanel handles dashboards separately)
- Puzzle content is pre-generated JSON bundled with the app for levels 1–200; runtime generation for theVault (201+)

---

## Environment Setup

### Three environments — all Supabase cloud projects

| Environment | Database | Git Branch | Who applies migrations |
|---|---|---|---|
| Task | Local Supabase via Docker | `task/*` | Manager Agent — freely |
| Dev | `puzzle-game-dev` (Supabase cloud) | `dev` | Manager Agent — after Adam approves |
| Production | `puzzle-game-prod` (Supabase cloud) | `main` | Manager Agent — after Adam approves |

Task branch development uses a local Supabase instance running via Docker. This keeps cloud costs at zero — Supabase free tier allows two cloud projects, both reserved for dev and production. Docker Desktop must be running before any session that uses the local database.

### Migration promotion rules
- Manager applies migrations to local database freely during task branch work — `supabase db push`
- Before promoting to `puzzle-game-dev`: Manager leaves a TODO MAS, waits for Adam's explicit confirmation
- Before promoting to `puzzle-game-prod`: Manager leaves a TODO MAS, waits for Adam's explicit confirmation
- No migration ever skips an environment — local → prod directly is never permitted
- No manual schema changes in any Supabase dashboard — all changes via migration files only

### Rules
- All schema changes written as numbered migration files in `supabase/migrations/` and version-controlled in Git
- Local database started with `supabase start` — prints local URL and keys on first run
- Cloud projects linked via `supabase link --project-ref [ref]` and pushed with `supabase db push --linked`
- Environment-specific config stored in `.env.task`, `.env.dev`, `.env.production` — all gitignored
- Service role keys stored in a password manager, never in code, never committed

### CLI commands used by Manager Agent
```bash
# Start local Supabase (Docker must be running first)
supabase start

# Stop local Supabase
supabase stop

# Apply migrations to local database
supabase db push

# Link CLI to a cloud project
supabase link --project-ref [project-ref]

# Apply migrations to linked cloud project
supabase db push --linked

# Deploy an Edge Function to linked cloud project
supabase functions deploy [function-name]

# Check migration status
supabase migration list

# Create a new migration file
supabase migration new [migration-name]
```

---

## Authentication Configuration

### Anonymous sessions (guest mode)
- Enable anonymous sign-ins in Supabase Auth dashboard
- Every new player gets an anonymous session automatically on first app launch
- Anonymous users get a real `auth.uid()` — all RLS policies work identically for guests and authenticated users
- Anonymous session persists across app launches via Supabase's local session storage in Flutter

### OAuth providers
Enable the following in Supabase Auth dashboard:
- **Sign in with Apple** (required for iOS App Store compliance when offering social login)
- **Sign in with Google**
- **Email/password**

### Anonymous → authenticated migration
When a guest creates an account, their anonymous session must be merged into the new account. All progress, coins, and achievements associated with the anonymous `user_id` must transfer to the new `auth.uid()`.

**Implementation pattern:**
```typescript
// In the account creation Edge Function
// 1. Get the anonymous user's existing data
// 2. Create/link the new authenticated account
// 3. Update all rows referencing old anonymous user_id to new user_id
// 4. This must be atomic — use a Postgres stored procedure wrapped in a transaction
// 5. Invalidate the anonymous session after successful migration
```

This is the most critical auth flow in the entire app. Test thoroughly. A failed migration that loses player progress is a one-star review event.

### JWT configuration
- Use default Supabase JWT expiry (1 hour) with automatic refresh
- Flutter Supabase SDK handles token refresh automatically
- Do not store JWTs manually in Flutter — use the SDK session management

---

## Database Schema

### Conventions
- All primary keys are `uuid` type, default `gen_random_uuid()`
- All timestamps are `timestamptz` (timezone-aware)
- All foreign keys reference `player_profiles(id)` as `user_id`
- Enum types defined before table creation
- RLS enabled on every table immediately after creation

---

### Enum Types

```sql
CREATE TYPE level_type AS ENUM ('standard', 'bossLevel', 'vault');
CREATE TYPE transaction_type AS ENUM (
  'level_complete',
  'boss_complete', 
  'achievement',
  'hint_purchase',
  'skip_purchase',
  'iap',
  'cosmetic'
);
```

---

### Table: `player_profiles`

```sql
CREATE TABLE player_profiles (
  id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  auth_id             uuid UNIQUE NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at          timestamptz DEFAULT now(),
  updated_at          timestamptz DEFAULT now(),
  display_name        text,
  is_guest            boolean NOT NULL DEFAULT true,
  current_streak      integer NOT NULL DEFAULT 0,
  longest_streak      integer NOT NULL DEFAULT 0,
  last_played_date    date,
  total_words_found   integer NOT NULL DEFAULT 0
);

ALTER TABLE player_profiles ENABLE ROW LEVEL SECURITY;

-- Index on auth_id for fast lookup
CREATE INDEX idx_player_profiles_auth_id ON player_profiles(auth_id);

-- Auto-update updated_at
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER player_profiles_updated_at
  BEFORE UPDATE ON player_profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
```

**Notes:**
- `auth_id` maps to `auth.users(id)` — the Supabase Auth user
- `id` is the internal profile ID used as `user_id` FK in all other tables
- `total_words_found` incremented server-side via Edge Function, never written directly by client
- `current_streak` and `longest_streak` updated server-side on level_complete event

---

### Table: `player_progress`

```sql
CREATE TABLE player_progress (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         uuid NOT NULL REFERENCES player_profiles(id) ON DELETE CASCADE,
  level_number    integer NOT NULL,
  level_type      level_type NOT NULL DEFAULT 'standard',
  completed       boolean NOT NULL DEFAULT false,
  stars           smallint CHECK (stars BETWEEN 1 AND 3),
  hints_used      smallint NOT NULL DEFAULT 0,
  attempts_made   smallint NOT NULL DEFAULT 0,
  completed_at    timestamptz,
  created_at      timestamptz DEFAULT now()
);

ALTER TABLE player_progress ENABLE ROW LEVEL SECURITY;

-- Unique constraint: one progress row per player per level
CREATE UNIQUE INDEX idx_player_progress_unique 
  ON player_progress(user_id, level_number, level_type);

-- Index for fast lookup by user
CREATE INDEX idx_player_progress_user_id ON player_progress(user_id);

-- Index for drop-off analytics queries
CREATE INDEX idx_player_progress_level_number ON player_progress(level_number);
```

**Notes:**
- A row is created on `level_start`, updated on `level_complete` or `level_skip`
- `stars` is nullable — null means level started but not completed
- `attempts_made` counts total word submissions across all attempts on this level

---

### Table: `coin_transactions`

```sql
CREATE TABLE coin_transactions (
  id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id             uuid NOT NULL REFERENCES player_profiles(id) ON DELETE CASCADE,
  amount              integer NOT NULL, -- positive = earn, negative = spend
  transaction_type    transaction_type NOT NULL,
  reference_id        text, -- level number, achievement ID, IAP receipt, etc.
  idempotency_key     text UNIQUE, -- prevents duplicate transactions
  created_at          timestamptz DEFAULT now()
);

ALTER TABLE coin_transactions ENABLE ROW LEVEL SECURITY;

-- Index for balance computation
CREATE INDEX idx_coin_transactions_user_id ON coin_transactions(user_id);

-- Index for idempotency checks
CREATE INDEX idx_coin_transactions_idempotency ON coin_transactions(idempotency_key);
```

**Notes:**
- Coin balance is ALWAYS computed as `SUM(amount) WHERE user_id = ?` — never stored as a column
- Client NEVER writes directly to this table — all writes go through Edge Functions
- `idempotency_key` prevents duplicate coin awards if a network request retries
- Format for `idempotency_key`: `{user_id}:{transaction_type}:{reference_id}`

---

### Table: `achievements`

```sql
CREATE TABLE achievements (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         uuid NOT NULL REFERENCES player_profiles(id) ON DELETE CASCADE,
  achievement_id  text NOT NULL,
  unlocked_at     timestamptz DEFAULT now(),
  coins_awarded   integer NOT NULL DEFAULT 0,
  
  UNIQUE(user_id, achievement_id) -- each achievement unlocked once only
);

ALTER TABLE achievements ENABLE ROW LEVEL SECURITY;

CREATE INDEX idx_achievements_user_id ON achievements(user_id);
```

**Valid `achievement_id` values:**
```
first_word, getting_warmed_up, puzzle_apprentice, century, vault_dweller,
boss_slayer, unstoppable, word_collector, lexicon, wordsmith, grand_lexicon,
no_hints_needed, first_try, perfectionist, consistent, dedicated, obsessed,
saver, high_roller, master_of_words
```

---

### Table: `analytics_events`

```sql
CREATE TABLE analytics_events (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         uuid REFERENCES player_profiles(id) ON DELETE SET NULL,
  session_id      uuid NOT NULL,
  event_name      text NOT NULL,
  properties      jsonb NOT NULL DEFAULT '{}',
  created_at      timestamptz DEFAULT now()
);

ALTER TABLE analytics_events ENABLE ROW LEVEL SECURITY;

-- Index for reporting queries
CREATE INDEX idx_analytics_events_event_name ON analytics_events(event_name);
CREATE INDEX idx_analytics_events_created_at ON analytics_events(created_at);
CREATE INDEX idx_analytics_events_user_id ON analytics_events(user_id);

-- GIN index for JSONB property queries
CREATE INDEX idx_analytics_events_properties ON analytics_events USING GIN(properties);
```

**Notes:**
- Client can INSERT only — no SELECT, no UPDATE, no DELETE from client
- `user_id` nullable to handle events before profile creation completes
- All events also fire to Mixpanel from Flutter — this table is raw ownership backup

---

### Table: `puzzles`

```sql
CREATE TABLE puzzles (
  id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  seed                text NOT NULL UNIQUE,
  level_number        integer, -- null for vault puzzles
  level_type          level_type NOT NULL DEFAULT 'standard',
  intersection_count  smallint NOT NULL,
  constraint_tiers    integer[] NOT NULL,
  word_count          smallint NOT NULL,
  is_boss             boolean NOT NULL DEFAULT false,
  puzzle_data         jsonb NOT NULL, -- full puzzle definition
  created_at          timestamptz DEFAULT now()
);

ALTER TABLE puzzles ENABLE ROW LEVEL SECURITY;

CREATE INDEX idx_puzzles_level_number ON puzzles(level_number);
CREATE INDEX idx_puzzles_seed ON puzzles(seed);
```

**Notes:**
- Pre-generated puzzles (levels 1–200) inserted via migration seed file
- `puzzle_data` JSONB stores the full puzzle: word slots, intersection positions, constraints, letter pool
- Client has SELECT only — never writes to this table
- Vault puzzles have `level_number = null`, identified by seed

---

## Row Level Security Policies

### Performance notes (applied globally)
Per Supabase RLS performance best practices:
- All `user_id` columns referenced in policies have indexes (defined above)
- Wrap `auth.uid()` in a `SELECT` to enable optimizer caching: `(SELECT auth.uid())`
- This provides 100x+ performance improvement on large tables
- Add explicit `.eq('user_id', userId)` filters in Flutter queries in addition to RLS

---

### `player_profiles` policies

```sql
-- Users can read their own profile
CREATE POLICY "player_profiles_select_own"
ON player_profiles FOR SELECT
TO authenticated
USING (auth_id = (SELECT auth.uid()));

-- Users can update their own profile (display_name only — other fields via Edge Functions)
CREATE POLICY "player_profiles_update_own"
ON player_profiles FOR UPDATE
TO authenticated
USING (auth_id = (SELECT auth.uid()))
WITH CHECK (auth_id = (SELECT auth.uid()));

-- Profile created automatically via Edge Function on first login — no direct client insert
-- Anonymous users same policies apply (auth.uid() works for anon sessions)
```

---

### `player_progress` policies

```sql
-- Users can read their own progress
CREATE POLICY "player_progress_select_own"
ON player_progress FOR SELECT
TO authenticated
USING (user_id = (SELECT auth.uid()));

-- Users can insert their own progress rows (level_start event)
CREATE POLICY "player_progress_insert_own"
ON player_progress FOR INSERT
TO authenticated
WITH CHECK (user_id = (SELECT auth.uid()));

-- Users can update their own progress rows (level_complete event)
CREATE POLICY "player_progress_update_own"
ON player_progress FOR UPDATE
TO authenticated
USING (user_id = (SELECT auth.uid()))
WITH CHECK (user_id = (SELECT auth.uid()));
```

---

### `coin_transactions` policies

```sql
-- Users can read their own transactions (for balance computation)
CREATE POLICY "coin_transactions_select_own"
ON coin_transactions FOR SELECT
TO authenticated
USING (user_id = (SELECT auth.uid()));

-- NO INSERT policy for authenticated role
-- All inserts go through Edge Functions using service role
-- This prevents client-side coin manipulation
```

---

### `achievements` policies

```sql
-- Users can read their own achievements
CREATE POLICY "achievements_select_own"
ON achievements FOR SELECT
TO authenticated
USING (user_id = (SELECT auth.uid()));

-- NO INSERT policy for authenticated role
-- All inserts go through Edge Functions using service role
```

---

### `analytics_events` policies

```sql
-- Users can insert their own events
CREATE POLICY "analytics_events_insert_own"
ON analytics_events FOR INSERT
TO authenticated
WITH CHECK (user_id = (SELECT auth.uid()));

-- NO SELECT policy — client never reads analytics data
```

---

### `puzzles` policies

```sql
-- Public read — all authenticated users can read all puzzles
CREATE POLICY "puzzles_select_all"
ON puzzles FOR SELECT
TO authenticated
USING (true);

-- NO INSERT, UPDATE, DELETE from client ever
```

---

### Auto-enable RLS on new tables (safety net)

```sql
-- Trigger to automatically enable RLS on any new table created in public schema
CREATE OR REPLACE FUNCTION enable_rls_on_new_table()
RETURNS event_trigger AS $$
DECLARE
  obj record;
BEGIN
  FOR obj IN SELECT * FROM pg_event_trigger_ddl_commands()
  WHERE command_tag = 'CREATE TABLE'
  LOOP
    EXECUTE format('ALTER TABLE %s ENABLE ROW LEVEL SECURITY', obj.object_identity);
  END LOOP;
END;
$$ LANGUAGE plpgsql;

CREATE EVENT TRIGGER auto_enable_rls
ON ddl_command_end
WHEN TAG IN ('CREATE TABLE')
EXECUTE FUNCTION enable_rls_on_new_table();
```

---

## Edge Functions

All Edge Functions use the Supabase service role key (bypasses RLS) and validate inputs before writing. Never expose the service role key to the client.

---

### Function: `on-level-complete`

**Triggered by:** Flutter client after successful puzzle completion  
**Purpose:** Awards coins, updates streak, increments word count, checks achievement triggers, writes progress

**Input:**
```typescript
{
  level_number: number,
  level_type: 'standard' | 'bossLevel' | 'vault',
  hints_used: number,
  attempts_made: number,
  words_found: number,        // number of words solved in this puzzle
  time_taken_ms: number,
  stars: 1 | 2 | 3,
  idempotency_key: string     // client generates: `{user_id}:{level_number}:{level_type}`
}
```

**Logic:**
```typescript
1. Validate idempotency_key — if already exists in coin_transactions, return cached result (prevents double-awards on retry)
2. Determine coin award: bossLevel = 20, standard/vault = 10
3. INSERT into coin_transactions with idempotency_key
4. UPDATE player_progress: set completed = true, stars, hints_used, attempts_made, completed_at
5. UPDATE player_profiles: increment total_words_found by words_found
6. Update streak:
   - If last_played_date = today: no change
   - If last_played_date = yesterday: increment current_streak, update longest_streak if needed
   - If last_played_date < yesterday: reset current_streak to 1
   - Set last_played_date = today
7. Check achievement triggers (see achievement logic below)
8. Return: { coins_awarded, new_balance, streak, achievements_unlocked[] }
```

**Achievement triggers to check after every level complete:**
- `first_word` — total completed levels = 1
- `getting_warmed_up` — total completed levels = 10
- `puzzle_apprentice` — total completed levels = 50
- `century` — total completed levels = 100
- `boss_slayer` — total bossLevel completions = 1
- `unstoppable` — total bossLevel completions = 10
- `word_collector` — total_words_found >= 100
- `lexicon` — total_words_found >= 500
- `wordsmith` — total_words_found >= 1000
- `grand_lexicon` — total_words_found >= 5000
- `no_hints_needed` — 10 consecutive levels with hints_used = 0 (requires checking last 10 progress rows)
- `first_try` — count of progress rows where attempts_made = 1 and completed = true >= 50
- `perfectionist` — bossLevel completed with hints_used = 0
- `consistent` — current_streak >= 7
- `dedicated` — current_streak >= 30
- `obsessed` — current_streak >= 100
- `master_of_words` — all levels 1–200 completed AND none were skipped

---

### Function: `on-hint-used`

**Triggered by:** Flutter client when player requests a hint  
**Purpose:** Deducts coins, validates player has enough balance

**Input:**
```typescript
{
  level_number: number,
  word_slot: number,          // which word they're getting a hint for
  idempotency_key: string
}
```

**Logic:**
```typescript
1. Check idempotency_key — prevent double-charge
2. Compute current coin balance: SELECT SUM(amount) FROM coin_transactions WHERE user_id = ?
3. Validate balance >= hint_cost (5 or 10 coins — defined as env variable)
4. If insufficient: return { success: false, reason: 'insufficient_coins' }
5. INSERT negative coin transaction
6. Check 'saver' achievement: if player reaches 500 coins without spending (requires checking transaction history)
7. Return { success: true, new_balance, hint_data }
   // hint_data = which tiles are valid for this word slot (computed from puzzle seed)
```

---

### Function: `on-level-skip`

**Triggered by:** Flutter client when player skips a level  
**Purpose:** Deducts 50 coins, marks level as skipped in progress

**Input:**
```typescript
{
  level_number: number,
  level_type: 'standard' | 'bossLevel' | 'vault',
  idempotency_key: string
}
```

**Logic:**
```typescript
1. Check idempotency_key
2. Compute balance, validate >= 50
3. If insufficient: return { success: false, reason: 'insufficient_coins' }
4. INSERT -50 coin transaction with type 'skip_purchase'
5. UPDATE player_progress: mark as completed = true, stars = null (skipped), completed_at = now()
   // stars = null distinguishes skip from earned completion
6. Check 'high_roller' achievement: SUM of negative transactions >= 1000
7. Return { success: true, new_balance }
```

---

### Function: `on-iap-purchase`

**Triggered by:** RevenueCat webhook after successful purchase  
**Purpose:** Awards purchased coin bundle to player

**Input (from RevenueCat webhook):**
```typescript
{
  user_id: string,
  product_id: string,         // e.g. 'coins_500', 'coins_1200', 'coins_2500'
  transaction_id: string,     // RevenueCat transaction ID used as idempotency_key
}
```

**Logic:**
```typescript
1. Validate request is from RevenueCat (webhook secret validation)
2. Check idempotency_key (transaction_id) — prevent double-award
3. Map product_id to coin amount (defined in env config)
4. INSERT positive coin transaction with type 'iap', reference_id = transaction_id
5. Return { success: true }
```

---

### Function: `on-account-created`

**Triggered by:** Flutter client after successful account creation (email/Apple/Google)  
**Purpose:** Migrates anonymous session data to new authenticated account

**Input:**
```typescript
{
  anonymous_user_id: string,  // the old auth.uid() from anonymous session
  new_auth_id: string         // the new auth.uid() after account creation
}
```

**Logic:**
```typescript
// This entire operation must be atomic — use a Postgres stored procedure
1. Verify anonymous_user_id exists in player_profiles
2. Verify new_auth_id exists in auth.users
3. BEGIN TRANSACTION:
   a. UPDATE player_profiles SET auth_id = new_auth_id, is_guest = false WHERE auth_id = anonymous_user_id
   b. (All other tables reference player_profiles.id via FK — no changes needed if profile id stays the same)
4. COMMIT
5. Return { success: true, profile_id }
```

**Critical:** If step 3 fails for any reason, the entire transaction rolls back. The player retains their anonymous session until migration succeeds. Never leave a partial migration state.

---

### Function: `create-player-profile`

**Triggered by:** Supabase Auth webhook on new user creation (`auth.users` insert)  
**Purpose:** Creates a player_profiles row for every new auth user automatically

**Logic:**
```typescript
1. Extract new user id from webhook payload
2. INSERT into player_profiles (auth_id = new_user_id, is_guest = true if anonymous)
3. Return { success: true }
```

This ensures every auth user always has a corresponding player_profiles row. No client-side profile creation needed.

---

## Stored Procedures

### `compute_coin_balance(p_user_id uuid)`

```sql
CREATE OR REPLACE FUNCTION compute_coin_balance(p_user_id uuid)
RETURNS integer
LANGUAGE sql
SECURITY DEFINER
AS $$
  SELECT COALESCE(SUM(amount), 0)::integer
  FROM coin_transactions
  WHERE user_id = p_user_id;
$$;
```

Used internally by Edge Functions. Not exposed to client directly.

---

### `migrate_anonymous_to_authenticated(p_anon_auth_id uuid, p_new_auth_id uuid)`

```sql
CREATE OR REPLACE FUNCTION migrate_anonymous_to_authenticated(
  p_anon_auth_id uuid,
  p_new_auth_id uuid
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE player_profiles
  SET 
    auth_id = p_new_auth_id,
    is_guest = false,
    updated_at = now()
  WHERE auth_id = p_anon_auth_id;
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Anonymous profile not found for auth_id: %', p_anon_auth_id;
  END IF;
END;
$$;
```

Called atomically from `on-account-created` Edge Function.

---

## Indexes Summary

All indexes defined inline with table creation above. Summary for reference:

| Table | Index | Purpose |
|---|---|---|
| player_profiles | auth_id | Fast lookup by Supabase auth user |
| player_progress | user_id | RLS + user queries |
| player_progress | level_number | Analytics drop-off queries |
| player_progress | (user_id, level_number, level_type) UNIQUE | Prevent duplicate progress rows |
| coin_transactions | user_id | Balance computation |
| coin_transactions | idempotency_key | Duplicate prevention |
| achievements | user_id | RLS + user queries |
| analytics_events | event_name | Reporting by event type |
| analytics_events | created_at | Time-range reporting |
| analytics_events | user_id | Per-user analytics |
| analytics_events | properties (GIN) | JSONB property queries |
| puzzles | level_number | Level lookup |
| puzzles | seed | Vault puzzle lookup by seed |

---

## Migration File Structure

```
supabase/
  migrations/
    001_create_enums.sql
    002_create_player_profiles.sql
    003_create_player_progress.sql
    004_create_coin_transactions.sql
    005_create_achievements.sql
    006_create_analytics_events.sql
    007_create_puzzles.sql
    008_rls_policies.sql
    009_indexes.sql
    010_stored_procedures.sql
    011_triggers.sql
    012_auto_rls_trigger.sql
    013_seed_puzzles.sql          -- pre-generated levels 1–200
  functions/
    on-level-complete/
      index.ts
    on-hint-used/
      index.ts
    on-level-skip/
      index.ts
    on-iap-purchase/
      index.ts
    on-account-created/
      index.ts
    create-player-profile/
      index.ts
```

---

## Environment Variables

```bash
# Never commit these — stored in .env files per environment

SUPABASE_URL=                     # project URL
SUPABASE_ANON_KEY=                # safe for client, respects RLS
SUPABASE_SERVICE_ROLE_KEY=        # server-side only, bypasses RLS, NEVER in Flutter app
REVENUECAT_WEBHOOK_SECRET=        # validates IAP webhook authenticity
HINT_COST_COINS=5                 # adjust via env without code change
SKIP_COST_COINS=50
```

---

## Security Checklist

Before deploying to production, verify all of the following:

- [ ] RLS enabled on every table in public schema
- [ ] Auto-RLS trigger deployed
- [ ] Service role key not present anywhere in Flutter codebase
- [ ] All coin writes go through Edge Functions only
- [ ] Idempotency keys implemented on all coin-awarding functions
- [ ] Anonymous-to-authenticated migration tested end-to-end
- [ ] RLS policies tested by connecting as different test users and verifying data isolation
- [ ] All Edge Functions validate input before writing
- [ ] RevenueCat webhook secret validation implemented
- [ ] `create-player-profile` Auth webhook configured in Supabase Auth dashboard
- [ ] All migrations verified on local database before promotion to puzzle-game-dev
- [ ] All migrations verified on puzzle-game-dev before promotion to puzzle-game-prod
- [ ] Adam approval confirmed via TODO MAS before every upward migration promotion
- [ ] Local Supabase starts cleanly via `supabase start` with Docker running
- [ ] Database backups configured in Supabase dashboard
- [ ] Connection pooling mode set correctly (Transaction mode on port 5432)

---

## Reporting Queries (for future dashboard)

These queries answer the key business questions defined in the GDD analytics section. Run against Supabase SQL editor or connect a BI tool.

### Level drop-off rate
```sql
SELECT 
  level_number,
  COUNT(*) FILTER (WHERE completed = true) as completions,
  COUNT(*) FILTER (WHERE completed = false) as abandonments,
  ROUND(
    COUNT(*) FILTER (WHERE completed = false)::numeric / COUNT(*)::numeric * 100, 
    2
  ) as abandonment_rate_pct
FROM player_progress
GROUP BY level_number
ORDER BY level_number;
```

### Constraint failure analysis
```sql
SELECT 
  properties->>'constraint_type' as constraint_type,
  properties->>'result' as result,
  COUNT(*) as occurrences
FROM analytics_events
WHERE event_name = 'word_submitted'
  AND properties->>'result' = 'wrong_constraint'
GROUP BY constraint_type, result
ORDER BY occurrences DESC;
```

### Hint usage by level
```sql
SELECT 
  properties->>'level_number' as level_number,
  COUNT(*) as hint_count
FROM analytics_events
WHERE event_name = 'hint_used'
GROUP BY level_number
ORDER BY hint_count DESC
LIMIT 20;
```

### Coin economy health
```sql
SELECT
  DATE_TRUNC('day', created_at) as day,
  SUM(amount) FILTER (WHERE amount > 0) as coins_earned,
  ABS(SUM(amount) FILTER (WHERE amount < 0)) as coins_spent,
  SUM(amount) as net
FROM coin_transactions
GROUP BY day
ORDER BY day DESC;
```

### Day 1 / Day 7 / Day 30 retention
```sql
WITH first_sessions AS (
  SELECT user_id, MIN(DATE(created_at)) as first_day
  FROM analytics_events
  WHERE event_name = 'app_open'
  GROUP BY user_id
)
SELECT
  COUNT(DISTINCT fs.user_id) as cohort_size,
  COUNT(DISTINCT CASE WHEN DATE(ae.created_at) = fs.first_day + 1 THEN fs.user_id END) as day1_retained,
  COUNT(DISTINCT CASE WHEN DATE(ae.created_at) = fs.first_day + 7 THEN fs.user_id END) as day7_retained,
  COUNT(DISTINCT CASE WHEN DATE(ae.created_at) = fs.first_day + 30 THEN fs.user_id END) as day30_retained
FROM first_sessions fs
LEFT JOIN analytics_events ae ON fs.user_id = ae.user_id;
```

---

*This spec is the single source of truth for the Supabase agent. Do not deviate from the schema, RLS policies, or Edge Function logic defined here without updating this document and the GDD accordingly.*
