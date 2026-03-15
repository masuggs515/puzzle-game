#!/usr/bin/env bash
# scripts/run_dev.sh
# Runs the app against the task-branch local Supabase instance.
# Copy values from .env.task after running `supabase start`.
# This file is version-controlled — do NOT paste real credentials here.
# Real values are in .env.task (gitignored).

set -e

# Load .env.task if it exists.
# tr -d '\r' strips Windows CRLF so values aren't poisoned with a trailing ^M.
if [ -f .env.task ]; then
  export $(grep -v '^#' .env.task | tr -d '\r' | xargs)
fi

flutter run \
  --dart-define=SUPABASE_URL="${SUPABASE_URL:-}" \
  --dart-define=SUPABASE_ANON_KEY="${SUPABASE_ANON_KEY:-}" \
  --dart-define=MIXPANEL_TOKEN="${MIXPANEL_TOKEN:-}" \
  --dart-define=SENTRY_DSN="${SENTRY_DSN:-}" \
  --dart-define=REVENUECAT_KEY="${REVENUECAT_KEY:-}" \
  --dart-define=ONESIGNAL_APP_ID="${ONESIGNAL_APP_ID:-}" \
  --dart-define=ADMOB_INTERSTITIAL_IOS="${ADMOB_INTERSTITIAL_ID:-ca-app-pub-3940256099942544/4411468910}" \
  --dart-define=ADMOB_INTERSTITIAL_ANDROID="${ADMOB_INTERSTITIAL_ID:-ca-app-pub-3940256099942544/1033173712}" \
  --dart-define=ADMOB_REWARDED_IOS="${ADMOB_REWARDED_ID:-ca-app-pub-3940256099942544/1712485313}" \
  --dart-define=ADMOB_REWARDED_ANDROID="${ADMOB_REWARDED_ID:-ca-app-pub-3940256099942544/5224354917}" \
  "$@"
