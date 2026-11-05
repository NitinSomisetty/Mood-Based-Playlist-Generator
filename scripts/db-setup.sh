#!/usr/bin/env bash
set -euo pipefail
: "${DATABASE_URL:?Set DATABASE_URL first}"
for f in db/00_extensions_check.sql db/01_schema.sql db/02_seed_data.sql db/04_advanced.sql db/06_rls_policies.sql; do
  echo "Applying $f"; psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f "$f"
done
