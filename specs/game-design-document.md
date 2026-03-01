# Game Design Document
**Project Codename:** TBD  
**Document Version:** 0.1  
**Status:** In Progress  
**Last Updated:** February 2026

---

## Table of Contents
1. [Game Overview](#1-game-overview)
2. [Core Mechanic](#2-core-mechanic)
3. [Puzzle Structure](#3-puzzle-structure)
4. [Difficulty System](#4-difficulty-system)
5. [Constraint Library](#5-constraint-library)
6. [Letter Pool System](#6-letter-pool-system)
7. [Level Types](#7-level-types)
8. [Boss Levels](#8-boss-levels)
9. [Player Feedback & UX](#9-player-feedback--ux)
10. [Coin Economy](#10-coin-economy)
11. [Hints & Skips](#11-hints--skips)
12. [Progression & World Map](#12-progression--world-map)
13. [The Vault](#13-the-vault)
14. [Achievements](#14-achievements)
15. [Streaks](#15-streaks)
16. [Level Complete Screen](#16-level-complete-screen)
17. [Puzzle Generation](#17-puzzle-generation)
18. [Tech Stack](#18-tech-stack)
19. [Database & Data Model](#19-database--data-model)
20. [Security](#20-security)
21. [Analytics & Reporting](#21-analytics--reporting)
22. [Account & Identity](#22-account--identity)
23. [Open Decisions](#23-open-decisions)

---

## 1. Game Overview

A level-based word and logic puzzle game targeting a broad, family-friendly audience. Players drag and connect letters on a puzzle board to form words that satisfy logical constraints. Words intersect at shared letters, meaning solving one word directly influences what's available for the next.

The game combines the accessibility of word games with the satisfaction of logic puzzles — designed to make players feel clever, not frustrated.

**Core emotional target:** *"The puzzle game that makes you feel clever."*

**Platform:** iOS and Android (Flutter, single codebase)  
**Target audience:** Broad/family, casual to mid-core, ages 10+  
**Session length:** 5–15 minutes  
**Monetization:** Hybrid — AdMob ads (free players) + coin bundles via IAP (all players) + rewarded video (optional, all players). Paying users never see interstitial ads.

---

## 2. Core Mechanic

Players are presented with a set of letter tiles arranged in a puzzle layout. The goal is to drag and connect letters to form words. Each word must satisfy a **logical constraint** displayed alongside its slot.

**Interaction:**
- Player drags a finger across letter tiles to form a word path
- Connected tiles highlight in real time as the player drags
- Invalid connections (tiles too far apart, already used) simply don't connect — no harsh feedback during drag
- A **Submit button** confirms the word when the player is ready
- Player can adjust or clear their path before submitting

**Why submit instead of immediate validation:**
The constraint-solving mechanic requires thinking time. Immediate rejection would interrupt the logical reasoning process. The submit button gives players agency and respect for their thought process.

---

## 3. Puzzle Structure

Puzzles are built around a **freeform intersection system** — not a fixed grid. Each puzzle defines a set of word slots that intersect at specific shared letter positions.

**How intersections work:**
- Two words share exactly one letter at a defined position
- The shared letter must satisfy the constraint of *both* words simultaneously
- Solving one word locks in its letters, narrowing the solution space for intersecting words

**Puzzle sizes by intersection count:**

| Intersections | Words | Difficulty Range |
|---|---|---|
| 1 | 2 | Tutorial / Early game |
| 2 | 3 | Early / Mid game |
| 3 | 4 | Mid game |
| 4+ | 5+ | Late game / bossLevel |

Puzzles grow in complexity as both the number of intersections and the difficulty of constraints increase independently.

---

## 4. Difficulty System

Difficulty is controlled by **two independent dials:**

**Dial 1 — Constraint Complexity (Tiers 1–5)**
How hard the logical rule is to satisfy. See Section 5.

**Dial 2 — Intersection Count**
How many words intersect. More intersections = more interdependence = harder puzzle.

These dials operate independently, enabling four distinct quadrants of difficulty:

| | Easy Constraints | Hard Constraints |
|---|---|---|
| **Few intersections** | Tutorial | Vocabulary challenge |
| **Many intersections** | Logic challenge | Expert / bossLevel |

This gives the level designer enormous variety without needing a large grid or complex UI.

---

## 5. Constraint Library

Constraints are organized into 5 tiers of increasing difficulty. Each constraint is implemented as a validation function: takes a word, returns true/false.

New constraint tiers are introduced gradually as new worlds on the world map, so players always understand what kind of thinking a level requires.

---

### Tier 1 — Category Constraints (Levels 1–20)
The word belongs to a semantic category. Pure vocabulary, no wordplay.

- "A type of fruit"
- "Something found in a kitchen"
- "An animal that lives in water"
- "A color"
- "A type of weather"
- "Something you wear"

---

### Tier 2 — Letter Rule Constraints (Levels 15–40)
Constraints about the structure of the word itself.

- "Starts and ends with the same letter" → LEVEL, RADAR, CIVIC
- "Contains a smaller word for a color" → GREED (GREEN), BLOWN (BLUE)
- "A 4-letter word" — length constraint combined with category
- "Has no repeated letters"
- "All vowels or all consonants"
- "Contains a double letter" → HAPPY, COFFEE

---

### Tier 3 — Wordplay Constraints (Levels 35–70)
Homophones, reversals, and anagrams introduced here.

- "Sounds like a number" → ATE (eight), FOR (four), WON (one)
- "Spelled backwards is also a valid word" → STOP/POTS, LIVE/EVIL
- "An anagram of LEAST" → STEAL, TALES, SLATE
- "Sounds like something you'd find in a garden"
- "Rhymes with a type of food"

---

### Tier 4 — Container / Deletion Constraints (Levels 60–100)
A word hidden inside another, or a word that transforms when letters are removed.

- "Remove the first letter to make a color" → BLAND → LAND
- "A word hidden inside MISFORTUNE" → FORT
- "Add one letter to make a body of water" → LAKE → FLAKE
- "Remove the last letter to make a verb"
- "Contains a 3-letter animal hidden inside it" → TEAPOT (APE), FOREST (ORC... no — BORE? ) — hand-validated carefully

---

### Tier 5 — Combined / Double Constraints (bossLevels and late game)
Two constraints that must both be satisfied simultaneously.

- "An anagram of STOP that is also something found in a garden" → POTS, SPOT
- "Sounds like a number AND contains a body part" 
- "Starts and ends with the same letter AND is a type of food"
- "Spelled backwards is a valid word AND is an animal"

---

### Constraint Implementation Notes
- Every constraint is a Dart function: `bool Function(String word)`
- Constraints are tagged by tier in the constraint library
- Category constraints reference pre-approved word lists (fruit_list, animal_list, etc.)
- All constraints are validated against the answer word list before being assigned to a puzzle
- Multiple valid answers are acceptable and encouraged — reduces player frustration

---

## 6. Letter Pool System

The letter pool evolves across the game to progressively increase challenge.

| Level Range | Letter Pool |
|---|---|
| 1–24 | Exact letters needed — no decoys. Pure logic challenge, no hunting. |
| 25–50 | 1–2 decoy letters introduced. Player must identify which letters to use. |
| 51–100 | 3–5 decoys. Recognizable wrong options included to test reasoning. |
| 100+ | Full keyboard available. Vocabulary and spelling become part of the challenge. |

**Design rationale:** Early levels teach the constraint mechanic without the cognitive overhead of letter hunting. Decoys are introduced gradually so the shift feels natural, not punishing. Full keyboard unlocks only once the player has deeply internalized the core loop.

---

## 7. Level Types

Two distinct level types provide pacing variety throughout the level sequence. They alternate to prevent monotony.

### Sprint Levels
- Small puzzle (1–2 intersections)
- Simple to mid-tier constraints (Tier 1–3)
- Designed for 1–3 minute completion
- Fast dopamine hit, move on quickly
- Majority of levels are Sprint type

### Puzzle Levels
- Larger puzzle (3–4+ intersections)
- Mid to hard constraints (Tier 3–5)
- Designed for 5–10 minute completion
- Slow burn satisfaction — the "aha" moment payoff
- Appear less frequently, typically before or after a bossLevel

---

## 8. Boss Levels

**Internal identifier:** `bossLevel`

A special level type appearing every **6–15 levels** throughout the main progression. Represents the hardest puzzle of its current tier — difficult relative to surrounding levels, but still scaled to where the player is in the game.

**Properties:**
- Higher intersection count than surrounding levels
- Constraint tier at the top of what's been introduced so far
- Worth **20 coins** on completion (vs. 10 for standard levels)
- Distinct visual treatment on the world map — clearly identifiable before the player enters
- No additional penalty for failure — same hint/skip system applies

**Design intent:** Natural checkpoints that give players a sense of milestone achievement. Completing a bossLevel should feel like a meaningful accomplishment, not just another level cleared.

---

## 9. Player Feedback & UX

### During Drag (real-time)
- Letter tiles highlight as connected
- Path animates smoothly between tiles
- Invalid connections simply don't respond — no harsh rejection
- Sound: soft tick as each letter connects

### On Submit — Correct
- Connected word tiles lock in with a satisfying snap animation
- Subtle particle effect on the completed word (not flashy)
- Sound: clean resolution tone
- If all words complete → level complete flow triggers

### On Submit — Wrong (two distinct states)

**State 1: Word not in dictionary**
- Word highlights in **red**
- Message: *"[WORD] isn't a word we recognize — try again."*
- Path resets, letter pool remains available
- Sound: soft, non-harsh rejection tone

**State 2: Word valid but misses constraint**
- Word highlights in **amber** (valid word, wrong logic)
- Message: *"[WORD] is a real word, but it doesn't satisfy '[constraint]'."*
- Path resets, letter pool remains available
- This distinction is critical — amber vs red teaches players the difference between vocabulary and logic failures

### Hint Active
- Highlights tiles that are part of a valid answer path without revealing the full word
- Constraint reminder shown: *"Remember — this word needs to [constraint]"*
- Does not reveal the answer, preserves the solve satisfaction

### Level Complete Screen
See Section 16.

---

## 10. Coin Economy

Coins are the single in-game currency. Earned through play, spendable on hints and skips, future cosmetics. Never pay-to-win.

**Earning:**

| Event | Coins Earned |
|---|---|
| Standard level complete | 10 coins |
| bossLevel complete | 20 coins |
| Achievement unlocked | Varies (see Section 14) |

**Spending (current):**

| Action | Coin Cost |
|---|---|
| Hint | 5–10 coins (TBD exact amount) |
| Skip level | 50 coins |
| Cosmetics (future) | ~1,000 coins |

**Design notes:**
- A player earns roughly 1 skip per 5 levels through normal play
- Cosmetics are a long-term savings goal — keeps veterans engaged
- Coin bundles available for purchase via IAP (RevenueCat)
- Coin balance never resets — persistent across sessions and devices

---

## 11. Hints & Skips

### Hints
- Cost: 5–10 coins (exact TBD)
- Behavior: Highlights valid tiles for the current word without revealing the full path
- Also shows a constraint reminder message
- Available at any point during a puzzle — player chooses when to use
- Multiple hints can be used on the same word

### Skips
- Cost: 50 coins
- Behavior: Marks the level as complete, awards 0 coins for that level, moves to next
- Available on any level including bossLevels
- Skipping a level does NOT unlock the "Master of Words" achievement (see Section 14)

---

## 12. Progression & World Map

### World Map
- Simple grid layout for v1 — revisit visual design post-launch
- Levels displayed as nodes on the grid
- bossLevels have a distinct visual treatment (icon/color TBD)
- Locked levels shown but not accessible until prior level complete
- Current level highlighted

### Level Progression Structure

```
Levels 1–200        Hand-crafted levels, ships with app at launch
Levels 201–300      Hand-crafted, added via update (ships post-launch)
Levels 301–400      Hand-crafted, added via future update
...                 Pattern continues with each major update
theVault            Procedurally generated, infinite, unlocked after level 200
                    (or latest hand-crafted tier if updates have been pushed)
```

**Update behavior:** When new hand-crafted levels are pushed (e.g. 201–300), players currently in theVault are routed back through the new hand-crafted content first, then return to theVault. theVault always sits at the end of the progression, acting as an infinite buffer between update cycles.

### World Themes
Levels are grouped into themed worlds on the map. Each world introduces a new constraint tier. Suggested world themes (placeholder names):

| World | Levels | Constraint Tier Introduced |
|---|---|---|
| World 1: The Garden | 1–30 | Tier 1 — Categories |
| World 2: The Workshop | 31–60 | Tier 2 — Letter Rules |
| World 3: The Library | 61–100 | Tier 3 — Wordplay |
| World 4: The Labyrinth | 101–150 | Tier 4 — Container/Deletion |
| World 5: The Observatory | 151–200 | Tier 5 — Combined/Double |
| theVault | 201+ | All tiers, procedurally generated |

---

## 13. The Vault

**Internal identifier:** `theVault`

An infinite prestige endgame mode unlocked after completing all available hand-crafted levels. Free to enter — no coin cost, no paywall. Entry is earned through completion.

**Properties:**
- Procedurally generated puzzles using the full constraint library
- Same coin economy applies (10 coins standard, 20 for vault bossLevels)
- Levels labeled as Vault 1, Vault 2, etc. — separate numbering from main progression
- Players return to hand-crafted content when updates push new levels, then re-enter theVault after completing them
- Distinct visual identity from main world map (TBD design)

**Design intent:** Players who reach theVault should feel like they've achieved something. The name communicates prestige and endlessness — there's always more inside.

---

## 14. Achievements

20 launch achievements, each rewards coins on unlock. Organized into 5 categories:

### Progression
| Achievement | Condition | Coins |
|---|---|---|
| First Word | Complete first puzzle | 10 |
| Getting Warmed Up | Complete 10 levels | 20 |
| Puzzle Apprentice | Complete 50 levels | 50 |
| Century | Complete 100 levels | 100 |
| Vault Dweller | Enter theVault for the first time | 150 |
| Boss Slayer | Complete first bossLevel | 30 |
| Unstoppable | Complete 10 bossLevels | 100 |

### Word Count (cumulative across all sessions, never resets)
| Achievement | Condition | Coins |
|---|---|---|
| Word Collector | Find 100 total words | 20 |
| Lexicon | Find 500 total words | 50 |
| Wordsmith | Find 1,000 total words | 100 |
| Grand Lexicon | Find 5,000 total words | 250 |

### Skill
| Achievement | Condition | Coins |
|---|---|---|
| No Hints Needed | Complete 10 levels in a row without a hint | 50 |
| First Try | Submit correct word on first attempt 50 times total | 75 |
| Perfectionist | Complete a bossLevel without using any hints | 100 |

### Streaks
| Achievement | Condition | Coins |
|---|---|---|
| Consistent | Maintain a 7-day streak | 50 |
| Dedicated | Maintain a 30-day streak | 150 |
| Obsessed | Maintain a 100-day streak | 500 |

### Economy
| Achievement | Condition | Coins |
|---|---|---|
| Saver | Accumulate 500 coins without spending | 50 |
| High Roller | Spend 1,000 coins total | 75 |

### Mastery
| Achievement | Condition | Coins |
|---|---|---|
| Master of Words | Complete all hand-crafted levels 1–200 without skipping any level | 500 |

---

## 15. Streaks

- A streak increments when the player completes at least one level per calendar day
- Missing a day resets the streak to 0
- Streak count displayed on home screen / world map
- Streak milestones trigger achievement unlocks (see Section 14)
- Streak count persists across devices via Supabase sync

**Future consideration:** Streak freeze item purchasable with coins — not in v1.

---

## 16. Level Complete Screen

Clean and minimal. Respects the player's time and gets them back into the game fast.

**Elements:**
- Header: "Level [XX] Complete"
- Performance indicator: star rating (1–3 stars) based on hints used
  - 3 stars: no hints used
  - 2 stars: 1–2 hints used
  - 1 star: 3+ hints used
- Coins earned displayed (10 or 20 for bossLevel)
- **Continue** button → next level
- **Home** button → world map

No excessive animation, no forced social share prompt, no interstitial ad between levels (respects session flow).

---

## 17. Puzzle Generation

### Word List
**Primary source:** SCOWL (Spell Checker Oriented Word Lists)  
**Secondary source:** Google 20k most common English words (frequency-ranked)

**Two-tier word system:**
- **Answer words (~15,000):** Common, family-friendly, 3–8 letters. Words the puzzle generator assigns as answers.
- **Valid guess words (~50,000+):** Broader dictionary. Any real word the player submits is accepted if it satisfies the constraints, even if it wasn't the intended answer.

**Filters applied to answer list:**
- Remove profanity and slurs
- Remove obscure proper nouns
- Remove words under 3 letters
- Remove words over 10 letters
- Keep both US and UK spellings in valid guess list, US only in answer list

### Generation Algorithm
Constraint Satisfaction Problem (CSP) solved with **Backtracking + Arc Consistency**, implemented in Dart.

**Step 1 — Define intersection structure**
Determine puzzle shape: number of words, number of intersections, which positions intersect. This is the puzzle skeleton, defined before any words are selected.

**Step 2 — Assign constraints to each word slot**
Pull constraints from the appropriate tier based on target difficulty. Each slot gets one constraint. For bossLevels, slots get Tier 5 (double) constraints.

**Step 3 — Arc consistency filtering**
For each intersecting word pair, filter the candidate word list to only words where the shared letter position is compatible with both constraints simultaneously. Dramatically reduces search space before backtracking begins.

**Step 4 — Backtracking search**
Iteratively assign words to slots. On conflict, backtrack and try the next candidate. Uses immutable data structures for efficient undo. Longest/most-constrained word placed first as seed to maximize branching factor.

**Step 5 — Validation pass**
Every generated puzzle must pass:
- At least one valid solution exists
- Solution is not trivially obvious (minimum viable solution space)
- No profanity or inappropriate words in any valid solution path

**Step 6 — Seed assignment**
Every validated puzzle receives a reproducible seed ID. Same seed always generates the same puzzle. Enables debugging, future daily challenge features, and player sharing.

### Pre-generation vs Runtime

| Mode | Levels | Method |
|---|---|---|
| Pre-generated | 1–200 + all hand-crafted updates | Run offline on dev machine, output JSON, ship with app |
| Runtime | theVault (201+) | Generated on-device or server-side as player progresses |

Pre-generated puzzles are stored as a JSON asset bundled with the app. Runtime generation uses the same algorithm but runs live, seeded by player ID + vault level number for reproducibility.

### Hand-crafted Levels
- All bossLevels are hand-crafted — never procedurally generated
- First 50 levels hand-crafted regardless of generation capability
- Any level introducing a new constraint tier for the first time is hand-crafted
- Generated levels get a human review pass before being locked into sequence

---

## 18. Tech Stack

| Layer | Tool | Notes |
|---|---|---|
| Framework | Flutter + Flame | Single codebase, iOS + Android + Web |
| Language | Dart | |
| Backend / Database | Supabase (PostgreSQL) | Relational, SQL queries, owned data |
| Authentication | Supabase Auth | JWT-based, anonymous + OAuth |
| Analytics | Mixpanel | Free to 1M events/month |
| IAP / Subscriptions | RevenueCat | Free to $2.5K revenue |
| Push Notifications | OneSignal | Free tier |
| Crash Reporting | Sentry | Free tier |
| CI/CD | GitHub Actions + Fastlane | Automated build and deploy |
| Word List | SCOWL + Google 20k | Bundled as local asset |
| Puzzle Storage | JSON asset (pre-gen) + Supabase (runtime) | |

---

## 19. Database & Data Model

### Tables

**`player_profiles`**
```
id              uuid (PK, = auth.uid())
created_at      timestamp
display_name    text (nullable, set on account creation)
is_guest        boolean
current_streak  integer
longest_streak  integer
last_played_at  date
total_words_found integer
```

**`player_progress`**
```
id              uuid (PK)
user_id         uuid (FK → player_profiles)
level_number    integer
level_type      enum (standard, bossLevel, vault)
completed       boolean
stars           integer (1–3)
hints_used      integer
completed_at    timestamp
```

**`coin_transactions`**
```
id              uuid (PK)
user_id         uuid (FK → player_profiles)
amount          integer (positive = earn, negative = spend)
transaction_type enum (level_complete, boss_complete, achievement, hint_purchase, skip_purchase, iap, cosmetic)
reference_id    text (level number, achievement ID, etc.)
created_at      timestamp
```

**`achievements`**
```
id              uuid (PK)
user_id         uuid (FK → player_profiles)
achievement_id  text (e.g. "century", "wordsmith")
unlocked_at     timestamp
coins_awarded   integer
```

**`analytics_events`**
```
id              uuid (PK)
user_id         uuid (FK → player_profiles)
event_name      text
properties      jsonb
created_at      timestamp
session_id      uuid
```

**`puzzles`**
```
id              uuid (PK)
seed            text
level_number    integer (nullable for vault puzzles)
level_type      enum
intersection_count integer
constraint_tiers integer[]
word_count      integer
is_boss         boolean
created_at      timestamp
```

### Computed Values
- `coin_balance` — always computed as SUM of coin_transactions for a user, never stored directly. Prevents client-side manipulation.
- `total_words_found` — stored on player_profiles, incremented via server-side function on level_complete event

---

## 20. Security

### Authentication
- Supabase Auth issues JWTs on every session (guest and authenticated)
- All database requests automatically carry the user's auth token via Supabase SDK
- Expired/invalid tokens rejected server-side automatically

### Row Level Security (RLS)
RLS enabled on every table. Players can only read and write their own rows.

Core policy pattern (applied to all player data tables):
```sql
CREATE POLICY "Players own their data"
ON [table_name] FOR ALL TO authenticated
USING (auth.uid() = user_id);
```

**Table-specific policies:**
- `player_profiles` — read/write own row only
- `player_progress` — read/write own rows only
- `coin_transactions` — read own rows, INSERT via server-side Edge Function only (never direct from client)
- `achievements` — read own rows, INSERT via server-side Edge Function only
- `analytics_events` — INSERT only from client, no reads
- `puzzles` — public read, no client writes ever

### API Key Management
- Flutter app holds **publishable key only**
- Secret key (bypasses RLS) lives server-side in Edge Functions only — never in app code
- Secret key never committed to version control

### Coin Transaction Security
Coin balance is never written directly by the client. All coin transactions go through a Supabase Edge Function that:
1. Validates the triggering event (level actually completed, achievement actually earned)
2. Checks for duplicate transactions (idempotency key)
3. Commits the transaction
4. Returns updated balance to client

This prevents arbitrary coin injection from a motivated player intercepting requests.

### Guest-to-Account Migration
The anonymous-to-authenticated user merge is the most sensitive auth flow. Implementation must:
- Preserve all guest progress, coins, and achievements on account creation
- Follow Supabase's documented anonymous user migration pattern exactly
- Be thoroughly tested before launch — losing progress on sign-up is a one-star review

---

## 21. Analytics & Reporting

### Event Tracking (Mixpanel + Supabase raw storage)

All events fire to both Mixpanel (dashboards/reporting) and Supabase analytics_events table (raw ownership).

**Events to track:**

| Event | Key Properties |
|---|---|
| `app_open` | session_id, timestamp, platform |
| `level_start` | level_number, level_type, coin_balance |
| `word_submitted` | level_number, word, constraint_type, result (correct/wrong_word/wrong_constraint), attempt_number, time_taken_ms |
| `hint_used` | level_number, coins_spent, word_slot |
| `level_complete` | level_number, time_taken_ms, hints_used, attempts_made, coins_earned, stars |
| `level_abandoned` | level_number, time_spent_ms, last_word_attempted |
| `level_skip` | level_number, coins_spent |
| `vault_entered` | first_time boolean |
| `boss_level_complete` | level_number, hints_used, time_taken_ms |
| `achievement_unlocked` | achievement_id, coins_awarded |
| `streak_updated` | new_streak_count |
| `coin_transaction` | transaction_type, amount, new_balance |
| `account_created` | method (email/apple/google), was_guest |

### Key Reports to Build

**Level drop-off funnel:**
Which levels have abnormally high `level_abandoned` rates? Filter by level_type, constraint_tier. Identifies broken or unfair puzzles immediately post-launch.

**Constraint failure analysis:**
Which constraint types generate the most `wrong_constraint` submissions? Identifies constraints that are too obscure or poorly communicated.

**Hint usage heatmap:**
Which levels and which word slots consume the most hints? Indicates difficulty spikes that need rebalancing.

**Coin economy health:**
Ratio of coins earned vs spent over time. Are players accumulating too fast (devalues IAP) or too slow (creates frustration)?

**Retention curves:**
Day 1, Day 7, Day 30 retention by acquisition source. Standard mobile game health metrics.

---

## 22. Account & Identity

### Guest Mode (default)
- Anonymous Supabase session created automatically on first launch
- All progress, coins, streaks, achievements saved to anonymous profile
- No sign-up required to play the full game

### Account Creation (optional)
- Prompted at natural milestone moments: entering theVault, earning a prestigious achievement, long streak milestone
- Never interrupts gameplay
- Sign-up methods: Email/password, Sign in with Apple, Sign in with Google (all via Supabase Auth)
- On account creation: anonymous session merges into new account, all progress preserved

### Cross-Device Sync
- All progress stored in Supabase, synced on login
- Player signs into existing account on new device → full progress restored
- Coin balance, level progress, achievements, streak all sync

### Data the Player Profile Holds
- Display name (optional, set post-signup)
- Current and longest streak
- Total words found (lifetime)
- Coin balance (computed from transactions)
- Level progress
- Achievement history

---

## 23. Open Decisions

These items have been identified but not yet decided. Flag for future sessions.

| Item | Notes |
|---|---|
| Game name | Placeholder TBD. Naming session deferred until core game is solid. |
| `bossLevel` visual treatment | Distinct icon/color on world map — design TBD |
| `theVault` visual identity | Separate visual treatment from main world map — design TBD |
| Hint cost exact amount | 5 or 10 coins — needs playtesting to balance |
| World theme names | Placeholder names in Section 12, final names TBD |
| Ad strategy | RESOLVED: Interstitial every 4–5 levels (not bossLevels), rewarded video optional, paying users (any IAP) permanently ad-free |
| Social features | Leaderboards / friend comparisons — deferred, architecture supports it |
| Streak freeze item | Purchasable with coins — deferred to post-launch |
| extendedMode name | `theVault` selected. Confirm final in-game copy. |
| Star rating thresholds | 3 stars = no hints, 2 stars = 1–2 hints, 1 star = 3+ hints — confirm via playtesting |
| bossLevel frequency | Every 6–15 levels — exact cadence to be tuned during level design |

---

*This document is a living reference. Update after every major design decision.*
