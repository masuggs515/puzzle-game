-- Migration 003: Create player_progress table
-- Spec: supabase-agent-spec.md § Table: player_progress
-- Phase: 2 — Foundation

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

-- One progress row per player per level (prevents duplicates)
CREATE UNIQUE INDEX idx_player_progress_unique
  ON player_progress(user_id, level_number, level_type);

-- Fast lookup by user (RLS + application queries)
CREATE INDEX idx_player_progress_user_id ON player_progress(user_id);

-- Analytics: level drop-off queries
CREATE INDEX idx_player_progress_level_number ON player_progress(level_number);
