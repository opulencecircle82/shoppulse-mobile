#!/usr/bin/env bash
# Builds the release APK with Supabase credentials baked in via
# --dart-define. Without these, the app boots straight to the "Missing
# SUPABASE_URL / SUPABASE_ANON_KEY" screen (see SupabaseConfig.isConfigured)
# — a plain `flutter build apk --release` is NOT enough.
set -euo pipefail
cd "$(dirname "$0")/.."

ENV_FILE=".env"
if [ ! -f "$ENV_FILE" ]; then
  echo "Missing $ENV_FILE. Copy .env.example to .env and fill in your Supabase project's URL + anon key." >&2
  exit 1
fi

SUPABASE_URL=$(grep "^SUPABASE_URL=" "$ENV_FILE" | cut -d '=' -f2-)
SUPABASE_ANON_KEY=$(grep "^SUPABASE_ANON_KEY=" "$ENV_FILE" | cut -d '=' -f2-)

if [ -z "$SUPABASE_URL" ] || [ -z "$SUPABASE_ANON_KEY" ]; then
  echo "SUPABASE_URL or SUPABASE_ANON_KEY is empty in $ENV_FILE." >&2
  exit 1
fi

flutter build apk --release \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY"

echo "Built build/app/outputs/flutter-apk/app-release.apk"
