# Gate 1 — SQL-managed schema drift disposition

Authoritative schema: the seven existing reviewed SQL migrations. Prisma's client model is not a replacement for these migrations. The exact previously reviewed difference is versioned in `packages/database/sql-managed-drift.json` and the SQL test fixture in `tests/fixtures/reviewed-prisma-diff.sql`.

The checker accepts only the exact 291 index and eight composite foreign-key drop suggestions in that reviewed difference. It queries the actual PostgreSQL catalog and checks index definitions, readiness and validity, and FK definitions and validation status. Unexpected statements, duplicate entries, missing entries or changed object definitions are hard failures. It never applies the diff. Changes to the manifest require human review against the migrations and a fresh database, not automatic baseline regeneration. This check is scoped to these known Prisma differences; it is not a comprehensive schema or RLS audit. Existing migration, SQL and concurrency tests remain mandatory.

## Execution

Use the isolated migration-owner connection, not a production application or runtime credential. From repository root:

```bash
python3 tests/test_schema_drift.py
(cd packages/database && npx --no-install prisma migrate diff --from-config-datasource --to-schema prisma/schema.prisma --script) > /tmp/exchi-prisma-diff.sql
python3 scripts/release/check-schema-drift.py /tmp/exchi-prisma-diff.sql --output acceptance-evidence/schema-drift-result.json
```

The existing bootstrap and CI acceptance sequence now invokes the check automatically and publishes the sanitized result.

## Evidence

On 27 November 2026, seven migrations applied in a fresh disposable PostgreSQL 16.4/PostGIS 3.4 cluster. The checker verified all 299 objects. An injected DROP TABLE statement failed before database access, with no success report. All 41 prior executable unit tests and nine new drift tests passed. A genuine loopback server was reachable by the HTTP client, but the installed Chromium returned ERR_BLOCKED_BY_ADMINISTRATOR; this is an environment constraint, not browser acceptance. No attempt was made to circumvent it.

Full Exchi source remains local because the named remote is public and source visibility has not been explicitly confirmed. Remote main and staging remain unprotected and at the original README commit. Complete staging and browser acceptance remain required. No financial or regulatory gate has been opened.
