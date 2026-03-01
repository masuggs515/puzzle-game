-- Migration 008: Row Level Security policies
-- Spec: supabase-agent-spec.md § Row Level Security Policies
-- Phase: 2 — Foundation
--
-- NOTE: player_progress, coin_transactions, achievements, and analytics_events
-- all use player_profiles.id as their user_id FK (not auth.uid() directly).
-- RLS policies use a subquery to resolve the profile id from auth.uid().
-- This is spec-correct behaviour: player_profiles.id != auth.uid().
-- All user_id indexes make these subqueries fast.


-- ─────────────────────────────────────────
-- player_profiles
-- ─────────────────────────────────────────

-- Users can read their own profile
CREATE POLICY "player_profiles_select_own"
ON player_profiles FOR SELECT
TO authenticated
USING (auth_id = (SELECT auth.uid()));

-- Users can update their own profile (display_name only — sensitive fields via Edge Functions)
CREATE POLICY "player_profiles_update_own"
ON player_profiles FOR UPDATE
TO authenticated
USING (auth_id = (SELECT auth.uid()))
WITH CHECK (auth_id = (SELECT auth.uid()));

-- Profile created automatically via DB trigger — no direct client INSERT


-- ─────────────────────────────────────────
-- player_progress
-- ─────────────────────────────────────────

-- Users can read their own progress
CREATE POLICY "player_progress_select_own"
ON player_progress FOR SELECT
TO authenticated
USING (user_id = (SELECT id FROM player_profiles WHERE auth_id = (SELECT auth.uid())));

-- Users can insert their own progress rows (level_start event)
CREATE POLICY "player_progress_insert_own"
ON player_progress FOR INSERT
TO authenticated
WITH CHECK (user_id = (SELECT id FROM player_profiles WHERE auth_id = (SELECT auth.uid())));

-- Users can update their own progress rows (level_complete event)
CREATE POLICY "player_progress_update_own"
ON player_progress FOR UPDATE
TO authenticated
USING (user_id = (SELECT id FROM player_profiles WHERE auth_id = (SELECT auth.uid())))
WITH CHECK (user_id = (SELECT id FROM player_profiles WHERE auth_id = (SELECT auth.uid())));


-- ─────────────────────────────────────────
-- coin_transactions
-- ─────────────────────────────────────────

-- Users can read their own transactions (for balance display)
CREATE POLICY "coin_transactions_select_own"
ON coin_transactions FOR SELECT
TO authenticated
USING (user_id = (SELECT id FROM player_profiles WHERE auth_id = (SELECT auth.uid())));

-- NO INSERT policy for authenticated role — all inserts go through Edge Functions
-- using service role key to prevent client-side coin manipulation


-- ─────────────────────────────────────────
-- achievements
-- ─────────────────────────────────────────

-- Users can read their own achievements
CREATE POLICY "achievements_select_own"
ON achievements FOR SELECT
TO authenticated
USING (user_id = (SELECT id FROM player_profiles WHERE auth_id = (SELECT auth.uid())));

-- NO INSERT policy for authenticated role — all inserts go through Edge Functions


-- ─────────────────────────────────────────
-- analytics_events
-- ─────────────────────────────────────────

-- Users can insert their own events (client fires and forgets)
CREATE POLICY "analytics_events_insert_own"
ON analytics_events FOR INSERT
TO authenticated
WITH CHECK (user_id = (SELECT id FROM player_profiles WHERE auth_id = (SELECT auth.uid())));

-- NO SELECT policy — client never reads analytics data back


-- ─────────────────────────────────────────
-- puzzles
-- ─────────────────────────────────────────

-- Public read — all authenticated users can read all puzzles
CREATE POLICY "puzzles_select_all"
ON puzzles FOR SELECT
TO authenticated
USING (true);

-- NO INSERT, UPDATE, DELETE from client ever
