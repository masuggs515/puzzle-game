-- Migration 010: Stored procedures
-- Spec: supabase-agent-spec.md § Stored Procedures
-- Phase: 2 — Foundation


-- compute_coin_balance: returns current coin balance for a player
-- Used internally by Edge Functions. Not exposed to client via RLS.
CREATE OR REPLACE FUNCTION compute_coin_balance(p_user_id uuid)
RETURNS integer
LANGUAGE sql
SECURITY DEFINER
AS $$
  SELECT COALESCE(SUM(amount), 0)::integer
  FROM coin_transactions
  WHERE user_id = p_user_id;
$$;


-- migrate_anonymous_to_authenticated: atomic migration of anonymous session data
-- Called from the on-account-created Edge Function via SECURITY DEFINER.
-- Updates player_profiles.auth_id and is_guest — all child tables stay intact
-- because they FK on player_profiles.id (which does not change).
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
