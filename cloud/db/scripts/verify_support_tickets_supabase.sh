#!/usr/bin/env bash
set -euo pipefail

if ! command -v supabase >/dev/null 2>&1; then
  echo "supabase CLI not found. Install it from https://supabase.com/docs/guides/cli"
  exit 1
fi

if [ -z "${SUPABASE_PROJECT_REF:-}" ]; then
  echo "Set SUPABASE_PROJECT_REF environment variable to your project ref, e.g. 'abc123xyz'"
  echo "Alternatively set DATABASE_URL and run the psql script directly:"
  echo "  ./cloud/db/scripts/verify_support_tickets_psql.sh"
  exit 1
fi

cat <<EOF
This helper shows a recommended flow to run the verification using the supabase CLI.

1) If you have a remote DATABASE_URL you can register it for the CLI (one-off):

   supabase db remote set <YOUR_DATABASE_URL> --project-ref ${SUPABASE_PROJECT_REF}

2) Then run the psql verifier (psql is required):

   ./cloud/db/scripts/verify_support_tickets_psql.sh

If you prefer, paste the migration SQL into the Supabase SQL editor and run the sample SELECTs there.
EOF
