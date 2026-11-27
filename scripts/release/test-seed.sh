#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
[[ "${ALLOW_DISPOSABLE_DB_TEST:-}" == YES && "$DATABASE_URL" == postgresql://postgres:*@127.0.0.1:55432/wholesale_test\?schema=public ]] || exit 2
export EXCHI_SEED_APPROVED=YES EXCHI_SEED_DATABASE=wholesale_test EXCHI_SEED_PSQL_URL="${DATABASE_URL%%\?*}"
export EXCHI_TENANT_CODE=exchi-seed-test EXCHI_TENANT_NAME='Synthetic seed acceptance' EXCHI_BOOTSTRAP_PHONE=+9647500000099 EXCHI_BOOTSTRAP_NAME='Synthetic administrator'
export EXCHI_OFFICIAL_RATE=1 EXCHI_INDICATIVE_RATE=2 EXCHI_OFFICIAL_SOURCE='Synthetic test only' EXCHI_INDICATIVE_SOURCE='Synthetic test only' EXCHI_FX_EFFECTIVE_FROM=2026-01-01T00:00:00Z
bash scripts/release/seed-tenant.sh
bash scripts/release/seed-tenant.sh
psql "$EXCHI_SEED_PSQL_URL" -X -v ON_ERROR_STOP=1 <<'SQL'
DO $$ DECLARE t uuid; BEGIN
 SELECT id INTO STRICT t FROM organizations.tenant WHERE code='exchi-seed-test';
 IF (SELECT count(*) FROM "authorization".role WHERE tenant_id=t)<>13 OR (SELECT count(*) FROM "authorization".assignment WHERE tenant_id=t)<>1 OR (SELECT count(*) FROM treasury.fx_rate WHERE tenant_id=t AND status='DRAFT')<>2 THEN RAISE EXCEPTION 'Seed replay integrity failure'; END IF;
 IF EXISTS(SELECT 1 FROM treasury.fx_rate WHERE tenant_id=t AND status<>'DRAFT') THEN RAISE EXCEPTION 'FX unexpectedly enabled'; END IF;
END $$;
SQL
