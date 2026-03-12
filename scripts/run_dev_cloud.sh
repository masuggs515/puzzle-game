#!/usr/bin/env bash
# scripts/run_dev_cloud.sh
# Runs the app against the puzzle-game-dev cloud Supabase project.
# Use this when testing on a physical device — localhost is not reachable
# from a phone on the same network.
#
# Credentials go in .env.dev (gitignored). See CLAUDE.md for the format:
#   SUPABASE_URL=https://xgqqpyehkmzyrtvqsofe.supabase.co
#   SUPABASE_ANON_KEY=<dev anon key>
#   MIXPANEL_TOKEN=<dev token>
#   ...

set -e

ENV_FILE=".env.dev"

if [ ! -f "$ENV_FILE" ]; then
  echo "ERROR: $ENV_FILE not found."
  echo "Create it with your puzzle-game-dev credentials. See CLAUDE.md for the format."
  exit 1
fi

# Load .env.dev — tr -d '\r' strips Windows CRLF.
export $(grep -v '^#' "$ENV_FILE" | tr -d '\r' | xargs)

flutter run \
  --dart-define=SUPABASE_URL="${SUPABASE_URL:-}" \
  --dart-define=SUPABASE_ANON_KEY="${SUPABASE_ANON_KEY:-}" \
  --dart-define=MIXPANEL_TOKEN="${MIXPANEL_TOKEN:-}" \
  --dart-define=SENTRY_DSN="${SENTRY_DSN:-}" \
  --dart-define=REVENUECAT_KEY="${REVENUECAT_KEY:-}" \
  --dart-define=ONESIGNAL_APP_ID="${ONESIGNAL_APP_ID:-}" \
  --dart-define=ADMOB_INTERSTITIAL_IOS="ca-app-pub-3940256099942544/4411468910" \
  --dart-define=ADMOB_INTERSTITIAL_ANDROID="ca-app-pub-3940256099942544/1033173712" \
  --dart-define=ADMOB_REWARDED_IOS="ca-app-pub-3940256099942544/1712485313" \
  --dart-define=ADMOB_REWARDED_ANDROID="ca-app-pub-3940256099942544/5224354917" \
  "$@"
