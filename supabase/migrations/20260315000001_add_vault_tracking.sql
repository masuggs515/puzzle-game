-- Migration: 20260315000001_add_vault_tracking
-- Phase: 8 — The Vault
-- Adds current_vault_level to player_profiles to track the highest vault level reached.

-- Add vault level tracking to player_profiles
ALTER TABLE player_profiles
  ADD COLUMN current_vault_level integer NOT NULL DEFAULT 0;
