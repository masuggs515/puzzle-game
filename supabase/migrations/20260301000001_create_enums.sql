-- Migration 001: Create enum types
-- Spec: supabase-agent-spec.md § Enum Types
-- Phase: 2 — Foundation

CREATE TYPE level_type AS ENUM ('standard', 'bossLevel', 'vault');

CREATE TYPE transaction_type AS ENUM (
  'level_complete',
  'boss_complete',
  'achievement',
  'hint_purchase',
  'skip_purchase',
  'iap',
  'cosmetic'
);
