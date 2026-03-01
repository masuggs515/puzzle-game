-- Migration 004: Create coin_transactions table
-- Spec: supabase-agent-spec.md § Table: coin_transactions
-- Phase: 2 — Foundation

CREATE TABLE coin_transactions (
  id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id             uuid NOT NULL REFERENCES player_profiles(id) ON DELETE CASCADE,
  amount              integer NOT NULL, -- positive = earn, negative = spend
  transaction_type    transaction_type NOT NULL,
  reference_id        text, -- level number, achievement ID, IAP receipt, etc.
  idempotency_key     text UNIQUE, -- prevents duplicate transactions
  created_at          timestamptz DEFAULT now()
);

ALTER TABLE coin_transactions ENABLE ROW LEVEL SECURITY;

-- Balance computation queries
CREATE INDEX idx_coin_transactions_user_id ON coin_transactions(user_id);

-- Idempotency checks (unique already creates an index, this is explicit for clarity)
CREATE INDEX idx_coin_transactions_idempotency ON coin_transactions(idempotency_key);
