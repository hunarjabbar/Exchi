# Wholesale. — Iraq/KRI enterprise monorepo

**v0.5.0-alpha.1 — Phase 5 implementation increment, not a complete or deployable enterprise system.**

This repository preserves the approved Phase 1–4.1 contracts and delivers a typed NestJS/Next.js source candidate, restricted catalog CRUD, session resolution, command-centre read projections and a non-binding retailer draft inbox. No cloud service or real merchant account was connected. Financial operations are not enabled. Read `docs/phase5-acceptance.md` before use.

## Structure

- `apps/public-web`, `apps/retailer-pwa`, `apps/distributor-portal`, `apps/field-sales-pwa`, `apps/driver-pwa`, `apps/command-centre`: six separate Next.js applications with fixed audiences and 70 approved routes. Generic routed shells are not full domain workstations.
- `apps/enterprise-api`: NestJS candidate using parameterized PostgreSQL queries and transaction-local RLS context. Only the command catalog masters have write endpoints. Other command views expose explicitly projected, RLS-filtered metadata; unsupported routes clearly report their status.
- `packages/database`: original three SQL migrations plus two additive migrations, Prisma schema, original and new SQL acceptance tests; 111 models and 19 governorates retained.
- `packages/core`: dependency-free validators, calculations, permission-boundary and execution-gate logic.
- `packages/ui`: shared React shell, theme/direction controls, IndexedDB draft module.
- `packages/contracts`: canonical runtime route registry and projection definitions.
- `docs/design-preview.html`: previous Phase 4.1 interactive design reference, not the new Next.js build.
- `.github/workflows/acceptance.yml`: non-deploying CI; never run in this environment.
- `evidence/`: actual local results and limitations.

## Run locally in a disposable environment

Prerequisites: Node.js 22, npm, Python 3, PostgreSQL/PostGIS with psql, Docker Compose (optional), TLS for authenticated frontend testing. Network access for npm is required. No lockfile was generated because npm registry access failed here; a successful install must generate and commit a reviewed package-lock.json before certification.

```bash
npm install --no-audit --no-fund
npm run test:core
npm run test:static
node scripts/syntax-check.cjs
npx tsc --noEmit --strict --target ES2022 --module nodenext --moduleResolution nodenext --allowImportingTsExtensions --lib ES2022,DOM packages/core/index.ts packages/ui/offline.ts
docker compose -f packages/database/compose.yaml up -d --wait
export DATABASE_URL='postgresql://postgres:local_test_only@localhost:55432/wholesale_test?schema=public'
ALLOW_DISPOSABLE_DB_TEST=YES npm run test:db
npm run build
```

The acceptance SQL rolls back synthetic fixtures. It must never be executed against production. The migration step creates persistent schema objects in the disposable database. The previous Phase 3 tests and new Phase 5 tests are both mandatory.

After runtime validation, create a separate restricted database login with `NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS NOINHERIT`, grant it membership in `wholesale_runtime`, and do not grant it migration/owner credentials. Use a secrets manager and local private network. The API executes `SET LOCAL ROLE wholesale_runtime`; it binds tenant and membership from the hashed, existing session record, not request-supplied tenant headers. Runtime SQL access must remain trusted backend only. The earlier Phase 3 security limitations still apply. OTP issuing, staff MFA, cookie issuing, full logout/revocation UI and production authentication are not implemented. No demo login bypass is provided.

Run API with `RUNTIME_DATABASE_URL` configured and working directory set by npm workspace:

```bash
npm run start -w @wholesale/enterprise-api
# in separate terminals, with application-specific APP_ORIGIN and ENTERPRISE_API_URL:
npm run dev -w @wholesale/public-web
npm run dev -w @wholesale/retailer-pwa
npm run dev -w @wholesale/distributor-portal
npm run dev -w @wholesale/field-sales-pwa
npm run dev -w @wholesale/driver-pwa
npm run dev -w @wholesale/command-centre
```

Local default ports: 3000 through 3005; API 4000, bound to loopback. Authenticated frontend calls require valid host-only `__Host-wholesale-session` secure cookies and the exact APP_ORIGIN; those cookies are deliberately not minted by this increment. Do not weaken TLS or introduce a hard-coded token to make the UI appear functional. Staff authentication and deployment architecture must be completed before real access.

## Independent GitHub repository

The GitHub connection was inspected and does not expose repository creation. No remote changes were made. Create a new **private, empty** repository named `iraq-wholesale-enterprise` under the intended account, then import the provided local Git bundle or initialize from this source. Do not reuse CCC or ICA repositories.

```bash
git clone wholesale-enterprise-v0.5.0.bundle iraq-wholesale-enterprise
cd iraq-wholesale-enterprise
git remote set-url origin https://github.com/YOUR_ACCOUNT/iraq-wholesale-enterprise.git
git push -u origin main
```

No release or deployment workflow is included. Do not promote until independent staging and all inherited financial/regulatory gates pass.

## Phase 5 Step A/B candidate

Read [the exact local execution and verification runbook](docs/step-a-b-runbook.md). Use `node scripts/local-env.mjs`, `bash scripts/bootstrap-step-ab.sh`, then `bash scripts/start-step-ab.sh` and `npm run test:step-ab:smoke` from another terminal (source `.local-stepab.env` first). Runtime certification is pending; no production infrastructure or financial execution has been changed.

## Step A/B certification increment

See [the updated acceptance runbook](docs/step-ab-certification.md). Certification now requires a reviewed npm lockfile and runs `npm run test:step-ab:runtime` to exercise the complete local runtime.

### Alpha.3 fresh certification
Use `npm run test:step-ab:fresh` for certification after generating, reviewing and committing the real dependency lockfile. It requires a clean commit, fresh worktree and unique local Compose project, refuses occupied ports, and never resets an existing database. See `docs/step-ab-isolation.md`. Step C and financial gates remain locked.

### Connected runner recovery for the missing dependency lockfile

If local npm networking is unavailable, the independent private GitHub repository can run the new **Dependency lockfile candidate (review only)** workflow. It creates an actual npm v3 lockfile with lifecycle scripts disabled, validates the graph, audits it and uploads a commit-bound candidate. It does not commit, deploy or certify the application. See [connected runtime recovery](docs/connected-runtime-recovery.md). All existing runtime and regulatory gates remain mandatory.

## Exchi Gate 1 release candidate
See [Gate 1 import, runtime certification and staging runbook](docs/exchi-gate1.md). This is a non-deploying candidate; no new release authorization is implied.
