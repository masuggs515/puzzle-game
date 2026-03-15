#!/usr/bin/env bash
# scripts/run_dev_cloud.sh
# Runs the app against the puzzle-game-dev cloud Supabase project.
# Use this when testing on a physical device — localhost is not reachable
# from a phone.
#
# Credentials go in .env.dev (gitignored). Format:
#   SUPABASE_URL=https://xgqqpyehkmzyrtvqsofe.supabase.co
#   SUPABASE_ANON_KEY=<dev anon key>
#
# IMPORTANT: String.fromEnvironment() values are baked in at COMPILE TIME via
# --dart-define. The app does NOT read .env.dev at runtime. You MUST use this
# script (or pass --dart-define flags manually) — running flutter run directly
# or using the IDE run button will produce empty credentials and Supabase will
# not initialize.

set -e

ENV_FILE=".env.dev"

if [ ! -f "$ENV_FILE" ]; then
  echo "ERROR: $ENV_FILE not found."
  echo "Create it with your puzzle-game-dev credentials:"
  echo "  SUPABASE_URL=https://xgqqpyehkmzyrtvqsofe.supabase.co"
  echo "  SUPABASE_ANON_KEY=<dev anon key>"
  exit 1
fi

# Load .env.dev into the current shell environment.
# set -a exports every variable that is set; source reads the file;
# set +a stops auto-exporting. This is more reliable than export $(xargs).
set -a
# shellcheck source=../.env.dev
source "$ENV_FILE"
set +a

echo "Loaded credentials from $ENV_FILE"
echo "  SUPABASE_URL=${SUPABASE_URL}"
echo "  SUPABASE_ANON_KEY=${SUPABASE_ANON_KEY:0:20}..."

flutter run \
  --dart-define=SUPABASE_URL="${SUPABASE_URL}" \
  --dart-define=SUPABASE_ANON_KEY="${SUPABASE_ANON_KEY}" \
  --dart-define=MIXPANEL_TOKEN="${MIXPANEL_TOKEN:-}" \
  --dart-define=SENTRY_DSN="${SENTRY_DSN:-}" \
  --dart-define=REVENUECAT_KEY="${REVENUECAT_KEY:-}" \
  --dart-define=ONESIGNAL_APP_ID="${ONESIGNAL_APP_ID:-}" \
  --dart-define=ADMOB_INTERSTITIAL_IOS="${ADMOB_INTERSTITIAL_ID:-ca-app-pub-3940256099942544/4411468910}" \
  --dart-define=ADMOB_INTERSTITIAL_ANDROID="${ADMOB_INTERSTITIAL_ID:-ca-app-pub-3940256099942544/1033173712}" \
  --dart-define=ADMOB_REWARDED_IOS="${ADMOB_REWARDED_ID:-ca-app-pub-3940256099942544/1712485313}" \
  --dart-define=ADMOB_REWARDED_ANDROID="${ADMOB_REWARDED_ID:-ca-app-pub-3940256099942544/5224354917}" \
  "$@"
