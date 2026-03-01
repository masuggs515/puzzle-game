-- Migration 011: Auth trigger — auto-create player profile on sign-up
-- Spec: supabase-agent-spec.md § Function: create-player-profile
-- Phase: 2 — Foundation
--
-- This database trigger runs immediately when a new auth.users row is inserted,
-- creating the corresponding player_profiles row atomically in the same transaction.
-- This is more reliable than an HTTP Edge Function webhook (no network, no partial state).
-- The Edge Function create-player-profile is still deployed for cloud environments
-- where the Auth webhook can be configured as a supplemental mechanism.

CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.player_profiles (auth_id, is_guest)
  VALUES (
    NEW.id,
    -- anonymous users have is_anonymous = true in raw_app_meta_data
    COALESCE((NEW.raw_app_meta_data->>'is_anonymous')::boolean, false)
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();
