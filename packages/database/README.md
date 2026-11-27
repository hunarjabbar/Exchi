# Iraq wholesale enterprise — Phase 3 database foundation

**Status:** implementation candidate; static consistency checked; SQL and Prisma execution unverified. **Not a production release or certification.** Independent project; no existing CCC/ICA database touched. SQL is canonical; Prisma 6.19.0 is deliberately pinned as a conventional stable Prisma schema/migration interface. This is a new database baseline, not an upgrade migration for a populated system.

## Contents
- `prisma/schema.prisma`: 111 relational models, multi-schema, decimal financial primitives, explicit tenant-safe foreign keys and PostGIS types represented as Unsupported fields. Spatial writes/queries use reviewed parameterized SQL.
- `prisma/migrations/202611270001_foundation`: schema, FK, indexes and constraints.
- `...0002_controls`: exact-scope RBAC/RLS, runtime grants, audit, revision, immutable final journals/invoices, protected command functions, policy gates.
- `...0003_reference`: 19 governorates (internal codes; Sorani provisional), 7 disabled payment-provider records. District table ready; no fabricated nationwide district/boundary/landmark data.
- `tests/acceptance.sql`: transaction-rolled-back synthetic acceptance assertions.
- `scripts/static_check.py`, `scripts/test-db.sh`, `compose.yaml`, GitHub Actions workflow.
- `docs/model-registry.json`, `docs/permission-registry.csv`, `docs/acceptance-and-limitations.md`.

## Run on a disposable database (requires Docker, npm, psql, Python 3)

```sh
cp .env.example .env
export DATABASE_URL='postgresql://postgres:local_test_only@localhost:55432/wholesale_test?schema=public'
docker compose up -d --wait
npm install
npm run test:static
ALLOW_DISPOSABLE_DB_TEST=YES npm run test:db
```

The workflow installs the pinned top-level Prisma dependencies, validates and generates the client, applies migrations on an empty PostGIS database and runs the SQL tests. No lockfile is included because dependencies could not be resolved in the authoring environment; create, review and commit a lockfile before production CI and replace `npm install` with `npm ci`. After testing, `docker compose down -v` removes the local disposable database. Do not use these test credentials in production.

## Deployment boundary

The migrations require a dedicated migration administrator with BYPASSRLS or superuser and permission to create extensions/roles. The SECURITY DEFINER functions intentionally use a tightly controlled search path and a trusted owner so they can enforce permissions under FORCE RLS. Standard installation expects pgcrypto and PostGIS in public. Managed hosts must validate this arrangement (including extension schema and role creation) in staging. Do not grant the migration owner to application users. Do not expose PostgreSQL to end users or use the runtime role through a public SQL endpoint.

Create a distinct server-side login (not included, no secrets generated) with membership of the `wholesale_runtime` NOLOGIN role only. Authenticate sessions in trusted backend code, then use a transaction with `set_config('app.tenant_id', tenantId, true)` and `set_config('app.membership_id', membershipId, true)`, set correlation ID as appropriate, and perform authorized operations within that same transaction. Context values are not cryptographically verified by PostgreSQL; the runtime credential is a trusted server credential. Do not accept caller-controlled actor IDs. Use parameterized statements; never concatenate user input. The policies require an active tenant, principal, membership, assignment and permission. A null assigned scope is tenant-wide; exact non-null scope grants do not inherit descendants. Provision role assignments through restricted administrative services after policy review. All transactions must use the runtime identity (or a purpose-built restricted service identity), not a database owner.

Master-data CRUD is authorized by table/action permission. Protected transaction tables have no generic runtime mutation grants. The implementation includes commands for reserve/release stock, commit credit, confirm verified payment, and post journal; additional domain commands and approval services must be implemented before enabling full enterprise workflows. RLS scopes are operational scopes rather than automatic parent inheritance; Phase 5 must derive record scopes from authoritative membership and resource ownership, not accept arbitrary client scope IDs.

## Canonical migration policy

Do not run `prisma db push` or reset against production. Custom SQL includes critical triggers, policies, additional composite FKs, checks and indexes that Prisma cannot fully express; Prisma is the typed client projection, not a replacement for reviewed SQL migrations. Review introspection and schema diff after execution; custom constraints intentionally not all represented in the ORM. Use SQL-based maintenance for geography, immutable records, financial functions and RLS.

## Regulatory safeguards

No real tenant, merchant credentials, actual exchange rates, active financial policies, credit authorization, regulated product permissions or production data are seeded. Official/authorized FX records require an approved effective rate; indicative rates cannot stamp commercial documents. Authorized transaction rate additionally requires an active `AUTHORIZED_FX_CHECKOUT` policy. `FINANCIAL_POSTING`, `TRADE_CREDIT`, and `DIGITAL_PAYMENTS` policies are absent by default; protected commands fail closed. Provider records are disabled. Legal and payment-provider approvals are outside this package. Domestic IQD invoice/quote/payment constraints are used as the default. FX reference rates and USD procurement or costing fields do not authorize domestic currency conversion.
