-- Migration 007: Create puzzles table
-- Spec: supabase-agent-spec.md § Table: puzzles
-- Phase: 2 — Foundation (empty; seeded in Phase 3)

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

-- Level lookup
CREATE INDEX idx_puzzles_level_number ON puzzles(level_number);

-- Vault puzzle lookup by seed
CREATE INDEX idx_puzzles_seed ON puzzles(seed);
