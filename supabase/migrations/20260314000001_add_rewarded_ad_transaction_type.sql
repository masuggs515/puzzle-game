-- Migration: Add rewarded_ad transaction type
-- Spec: master-development-plan.md § 9.6 Rewarded Ad Edge Function
-- Phase: 7 — Ads & Monetization

ALTER TYPE transaction_type ADD VALUE IF NOT EXISTS 'rewarded_ad';
