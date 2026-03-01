-- Migration 006: Create analytics_events table
-- Spec: supabase-agent-spec.md § Table: analytics_events
-- Phase: 2 — Foundation

CREATE TABLE analytics_events (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         uuid REFERENCES player_profiles(id) ON DELETE SET NULL,
  session_id      uuid NOT NULL,
  event_name      text NOT NULL,
  properties      jsonb NOT NULL DEFAULT '{}',
  created_at      timestamptz DEFAULT now()
);

ALTER TABLE analytics_events ENABLE ROW LEVEL SECURITY;

-- Reporting queries by event type
CREATE INDEX idx_analytics_events_event_name ON analytics_events(event_name);

-- Time-range reporting
CREATE INDEX idx_analytics_events_created_at ON analytics_events(created_at);

-- Per-user analytics
CREATE INDEX idx_analytics_events_user_id ON analytics_events(user_id);

-- JSONB property queries
CREATE INDEX idx_analytics_events_properties ON analytics_events USING GIN(properties);
