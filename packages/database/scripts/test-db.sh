#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
: "${DATABASE_URL:?Set DATABASE_URL to a disposable PostgreSQL database}"
# psql does not understand Prisma's schema URL parameter.
DB_URL="${PSQL_DATABASE_URL:-${DATABASE_URL%%\?*}}"
if [[ "${ALLOW_DISPOSABLE_DB_TEST:-}" != "YES" ]]; then
  echo 'Set ALLOW_DISPOSABLE_DB_TEST=YES only for a disposable test database.' >&2; exit 2
fi
npm run validate
npm run generate
npm run migrate
psql "$DB_URL" -X -v ON_ERROR_STOP=1 -f tests/acceptance.sql
psql "$DB_URL" -X -v ON_ERROR_STOP=1 -f tests/phase5.sql
