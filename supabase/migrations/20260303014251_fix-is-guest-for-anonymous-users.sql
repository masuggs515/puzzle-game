-- Migration: Fix is_guest for anonymous users in handle_new_user trigger
-- Spec: master-development-plan.md § 2.3 Anonymous Session Flow
-- Phase: 2 — Foundation
--
-- Bug: handle_new_user was reading `raw_app_meta_data->>'is_anonymous'` to set
-- is_guest, but Supabase stores anonymous identity in the dedicated boolean column
-- `auth.users.is_anonymous` — raw_app_meta_data is always `{}` for anonymous users.
-- Result: all anonymous sessions got is_guest = false.
--
-- Fix: use NEW.is_anonymous (the actual column) directly.
-- Also backfills existing rows: any player_profiles row whose auth user is
-- currently anonymous but has is_guest = false is corrected to is_guest = true.

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
    NEW.is_anonymous  -- use the dedicated column, not raw_app_meta_data
  );
  RETURN NEW;
END;
$$;


-- Backfill: correct any existing anonymous users that got is_guest = false
UPDATE public.player_profiles pp
SET is_guest = true, updated_at = now()
FROM auth.users u
WHERE pp.auth_id = u.id
  AND u.is_anonymous = true
  AND pp.is_guest = false;
