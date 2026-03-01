-- Migration 002: Create player_profiles table
-- Spec: supabase-agent-spec.md § Table: player_profiles
-- Phase: 2 — Foundation

-- Function used by the updated_at trigger (created here, reused in migration 011)
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

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

-- Index on auth_id for fast lookup by Supabase auth user
CREATE INDEX idx_player_profiles_auth_id ON player_profiles(auth_id);

-- Auto-update updated_at on every UPDATE
CREATE TRIGGER player_profiles_updated_at
  BEFORE UPDATE ON player_profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
