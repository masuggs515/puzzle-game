-- Migration 005: Create achievements table
-- Spec: supabase-agent-spec.md § Table: achievements
-- Phase: 2 — Foundation

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
