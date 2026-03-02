#!/usr/bin/env bash
set -euo pipefail

if [ -z "${DATABASE_URL:-}" ]; then
  echo "Error: DATABASE_URL is not set. Export your Postgres connection string, e.g."
  echo "  export DATABASE_URL='postgres://user:pass@host:5432/dbname'"
  exit 1
fi

echo "Checking pgcrypto extension..."
psql "$DATABASE_URL" -c "SELECT extname FROM pg_extension WHERE extname='pgcrypto';"

echo "\nChecking support_tickets table existence..."
psql "$DATABASE_URL" -c "SELECT to_regclass('public.support_tickets') AS table_exists;"

echo "\nColumns for support_tickets:" 
psql "$DATABASE_URL" -c "SELECT column_name, data_type FROM information_schema.columns WHERE table_name='support_tickets' ORDER BY ordinal_position;"

echo "\nRow count:" 
psql "$DATABASE_URL" -c "SELECT count(*) FROM public.support_tickets;"

echo "\nSample rows (most recent 5):"
psql "$DATABASE_URL" -c "SELECT * FROM public.support_tickets ORDER BY created_at DESC LIMIT 5;"

echo "\nTable schema (psql descriptive):"
psql "$DATABASE_URL" -c '\d+ public.support_tickets'

echo "\nVerification complete."
