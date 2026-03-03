-- Migration: Fix mutable search_path in all functions
-- Spec: specs/master-development-plan.md
-- Phase: 2 — Foundation
--
-- Supabase security linter flagged 5 functions with mutable search_path.
-- Adding SET search_path = '' (empty string) to each function definition
-- is the Supabase-recommended secure default — prevents search_path injection.
--
-- Functions fixed:
--   1. update_updated_at
--   2. compute_coin_balance
--   3. migrate_anonymous_to_authenticated
--   4. handle_new_user
--   5. enable_rls_on_new_table


-- 1. update_updated_at
--    Trigger function: auto-updates updated_at column on any UPDATE.
--    Source: migration 20260301000002_create_player_profiles.sql
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = ''
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;


-- 2. compute_coin_balance
--    Returns current coin balance for a player by summing coin_transactions.
--    Source: migration 20260301000010_stored_procedures.sql
CREATE OR REPLACE FUNCTION compute_coin_balance(p_user_id uuid)
RETURNS integer
LANGUAGE sql
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT COALESCE(SUM(amount), 0)::integer
  FROM public.coin_transactions
  WHERE user_id = p_user_id;
$$;


-- 3. migrate_anonymous_to_authenticated
--    Atomically migrates anonymous session to authenticated account.
--    Source: migration 20260301000010_stored_procedures.sql
CREATE OR REPLACE FUNCTION migrate_anonymous_to_authenticated(
  p_anon_auth_id uuid,
  p_new_auth_id uuid
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  UPDATE public.player_profiles
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


-- 4. handle_new_user
--    Auth trigger function: creates player_profiles row on new auth.users insert.
--    Source: migration 20260301000011_triggers.sql
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  INSERT INTO public.player_profiles (auth_id, is_guest)
  VALUES (
    NEW.id,
    -- anonymous users have is_anonymous = true in raw_app_meta_data
    COALESCE((NEW.raw_app_meta_data->>'is_anonymous')::boolean, false)
  );
  RETURN NEW;
END;
$$;


-- 5. enable_rls_on_new_table
--    Event trigger function: auto-enables RLS on any new table in public schema.
--    Source: migration 20260301000012_auto_rls_trigger.sql
CREATE OR REPLACE FUNCTION enable_rls_on_new_table()
RETURNS event_trigger
LANGUAGE plpgsql
SET search_path = ''
AS $$
DECLARE
  obj record;
BEGIN
  FOR obj IN SELECT * FROM pg_event_trigger_ddl_commands()
  WHERE command_tag = 'CREATE TABLE'
  LOOP
    EXECUTE format('ALTER TABLE %s ENABLE ROW LEVEL SECURITY', obj.object_identity);
  END LOOP;
END;
$$;
