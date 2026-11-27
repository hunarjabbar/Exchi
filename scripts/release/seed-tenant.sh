#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
: "${EXCHI_SEED_APPROVED:?Set explicit seed approval}" "${EXCHI_SEED_DATABASE:?Set expected database}" "${EXCHI_SEED_PSQL_URL:?Set dedicated migration-owner psql URL}"
[[ "$EXCHI_SEED_APPROVED" == YES ]] || exit 2
for k in EXCHI_TENANT_CODE EXCHI_TENANT_NAME EXCHI_BOOTSTRAP_PHONE EXCHI_BOOTSTRAP_NAME EXCHI_OFFICIAL_RATE EXCHI_OFFICIAL_SOURCE EXCHI_INDICATIVE_RATE EXCHI_INDICATIVE_SOURCE EXCHI_FX_EFFECTIVE_FROM; do
 [[ -n "${!k:-}" ]] || { echo "Missing $k" >&2; exit 2; }
done
# A seed never enables payment policies or authentication delivery.
psql "$EXCHI_SEED_PSQL_URL" -X -v ON_ERROR_STOP=1 -f packages/database/fixtures/gate1-tenant-seed.sql
