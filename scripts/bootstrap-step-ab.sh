#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
[[ -f .local-stepab.env ]] || node scripts/local-env.mjs
node scripts/add-browser-fixture.mjs
set -a; source .local-stepab.env; set +a
[[ "$ALLOW_DISPOSABLE_DB_TEST" == YES && "$DATABASE_URL" == postgresql://postgres:*@127.0.0.1:55432/wholesale_test\?schema=public && "$RUNTIME_DATABASE_URL" == postgresql://wholesale_stepab_login:*@127.0.0.1:55432/wholesale_test ]] || { echo 'Refusing non-local database'; exit 2; }
command -v docker >/dev/null; command -v psql >/dev/null
# Certification never generates or silently changes the dependency graph.
node scripts/check-lock.mjs
npm ci --no-audit --no-fund
project="${WHOLESALE_CERT_PROJECT:-wholesale-stepab-local}"
[[ "$project" == wholesale-stepab-local || "$project" =~ ^wholesale-cert-[0-9a-f]{16}$ ]] || { echo "Invalid certification project"; exit 2; }
docker compose -p "$project" -f compose.step-ab.yaml up -d --wait
npm run test:core
npm run test:auth
npm run test:static
npm run test:certification
python3 tests/test_schema_drift.py
node scripts/syntax-check.cjs
npx --no-install tsc --noEmit --strict --target ES2022 --module nodenext --moduleResolution nodenext --allowImportingTsExtensions --lib ES2022,DOM packages/core/index.ts packages/core/auth.ts packages/ui/offline.ts
npm run test:db
# Establish a login that is neither the owner nor a privileged role. The role group is created by migration 002.
psql "${DATABASE_URL%%\?*}" -X -v ON_ERROR_STOP=1 -v pw="$WHOLESALE_LOCAL_RUNTIME_PASSWORD" <<'SQL'
SELECT format('CREATE ROLE wholesale_stepab_login LOGIN NOINHERIT NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS PASSWORD %L', :'pw') WHERE NOT EXISTS(SELECT 1 FROM pg_roles WHERE rolname='wholesale_stepab_login') \gexec
SELECT format('ALTER ROLE wholesale_stepab_login LOGIN NOINHERIT NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS PASSWORD %L', :'pw') \gexec
GRANT wholesale_runtime TO wholesale_stepab_login;
GRANT CONNECT ON DATABASE wholesale_test TO wholesale_stepab_login;
SQL
psql "${DATABASE_URL%%\?*}" -X -v ON_ERROR_STOP=1 -f packages/database/fixtures/step-ab-local.sql
psql "${DATABASE_URL%%\?*}" -X -v ON_ERROR_STOP=1 -f packages/database/tests/step-ab-health.sql
psql "${DATABASE_URL%%\?*}" -X -v ON_ERROR_STOP=1 -f packages/database/tests/step-ab-auth.sql
psql "$RUNTIME_DATABASE_URL" -X -v ON_ERROR_STOP=1 -c 'BEGIN; SET LOCAL ROLE wholesale_runtime; SELECT current_user; ROLLBACK;'
(cd packages/database && npx --no-install prisma migrate status)
# Prisma omits SQL-managed objects. Require the reviewed exact difference and valid live definitions.
mkdir -p .local-stepab-logs
(cd packages/database && npx --no-install prisma migrate diff --from-config-datasource --to-schema prisma/schema.prisma --script) > .local-stepab-logs/prisma-diff.sql
python3 scripts/release/check-schema-drift.py .local-stepab-logs/prisma-diff.sql --output .local-stepab-logs/schema-drift-result.json
python3 scripts/concurrency-step-ab.py
npm run build
npm run typecheck
npm run lint
npm run test:gate1:env
psql "${DATABASE_URL%%\?*}" -X -v ON_ERROR_STOP=1 -f packages/database/tests/gate1-indexes.sql
bash scripts/release/test-seed.sh
printf '\nLocal build/SQL gates passed. SQL-managed schema drift verified; continue to smoke tests.\n'
