# Exchi — Gate 1 release candidate (not certified)

**Latest dependency candidate:** See [security recovery and exact verification](gate1-security-recovery.md). The audited lockfile is included on `release/gate-1-security`; use that bundle and `npm ci` rather than regenerating it. The historical import instructions below describe the original Gate 1 branch.

## Baseline and preservation
Remote `hunarjabbar/Exchi` is public and initially contained only README.md on main (5f2421de9f50b19935431eff776731ed5be6917e). Staging was created from that commit. The application source is in the separately supplied Git bundle, based on b0fd582. Do not overwrite either history. Confirm public source visibility is intended before pushing; no credentials are supplied or belong in Git. No other repository or database was changed.

## 1. Import the complete candidate into Exchi
From a networked Linux/WSL2 machine, install Git, GitHub CLI, Node 22.16.0 or a reviewed later 22 LTS patch, npm 10, Docker with local Compose v2, Python 3, PostgreSQL 16 client, curl and util-linux. Authenticate using `gh auth login` and `gh auth setup-git`. Then run:

```bash
git clone https://github.com/hunarjabbar/Exchi.git
cd Exchi
git fetch origin main staging
git fetch /absolute/path/exchi-gate1.bundle refs/heads/release/gate-1:refs/heads/foundation/gate1
git switch -c release/gate-1 origin/staging
git merge --allow-unrelated-histories -X theirs --no-commit foundation/gate1
mkdir -p docs
git show origin/main:README.md > docs/exchi-original-readme.md
git add docs/exchi-original-readme.md
git diff --cached --stat
git commit -m 'Import Exchi enterprise foundation and Gate 1 candidate'
```
`-X theirs` resolves the original README collision in favor of the application README; the original README is retained in docs and in the remote history. Inspect all staged changes before committing. If a branch already exists, inspect its history and do not force push.

## 2. Resolve dependencies and certify the local build
```bash
npm install --package-lock-only --ignore-scripts --no-audit --no-fund
npm run check:lock
npm ci
npm audit --audit-level=high
git add package-lock.json
git commit -m 'Pin reviewed Exchi dependency graph'
python3 -m venv .venv-cert
source .venv-cert/bin/activate
python -m pip install playwright==1.57.0
python -m playwright install --with-deps chromium
npm run test:gate1
```
The command uses a clean Git worktree, a new local Docker project, PostgreSQL/PostGIS, all seven migrations, existing SQL, contention, seed replay, index checks, Prisma validation and drift report, six Next builds, NestJS build, typechecks, lint, Zod tests, HTTP and browser tests, and cleanup. No Docker context or database is adopted from an existing deployment. The actual SQL and application build must run successfully. Review `acceptance-evidence/isolated-run.json`, `runtime-result.txt`, `prisma-diff.sql`, and the dependency audit. The Prisma diff may describe SQL-only objects; never apply it automatically. Investigate all unexplained differences. A pass does not certify external merchant or messaging services.

## 3. Staging branch and protection
```bash
git push -u origin release/gate-1
gh pr create --repo hunarjabbar/Exchi --base staging --head release/gate-1 --title 'Gate 1: Exchi foundation certification' --body 'Non-deploying Gate 1 acceptance; no financial execution.'
gh pr checks --watch
```
If npm connectivity is missing locally, push the candidate branch without the lockfile after reviewing public visibility. The dependency candidate workflow runs on initial branch push when its workflow file is changed. Retrieve the artifact from Actions, review its source SHA and checksum, audit, then commit the genuine lockfile; the ordinary acceptance pipeline refuses missing lockfiles. The staging PR is not to be merged while any gate fails. To configure protection after required check names are available, use a GitHub credential with repository administration permission:
```bash
EXCHI_PROTECTION_APPROVED=YES bash scripts/release/protect-branches.sh
for b in main staging; do gh api repos/hunarjabbar/Exchi/branches/$b/protection; done
```
Existing protection is never overwritten by the script. One independent reviewer is required; configure a reviewer before relying on this policy. This changes GitHub governance only, not deployed infrastructure. Do not bypass protections for Gate 1. The connector cannot apply the protection API.

## 4. Database seed and staging environment
Migration 003 includes 19 governorates and seven disabled provider records. Migration 007 adds seven additive indexes (three title trigram indexes, ingredients GIN, landmark and neighborhood trigram, tenant-governorate-district). Existing PostGIS point/zone indexes are preserved. These indexes are not a full cross-language fuzzy search service. Existing six migrations are unchanged.

For an explicitly authorized empty staging database, use a dedicated migration owner with the capabilities required by the original migrations (PostGIS, role provisioning, definer ownership). Never use a shared or production database for test fixtures or contention tests. Set `DATABASE_URL` privately, then:
```bash
npm run validate -w iraq-wholesale-phase3
npm run generate -w iraq-wholesale-phase3
npm run migrate -w iraq-wholesale-phase3
(cd packages/database && npx --no-install prisma migrate status)
```
The actual tenant seed is separate from migration deployment. The runtime test automatically runs a two-pass synthetic seed on its disposable database; production seed requires explicit approved tenant/admin identity and sourced rates. Set these values from an authorized change record in a private environment: `EXCHI_SEED_PSQL_URL` (psql URL without Prisma schema parameter), `EXCHI_SEED_DATABASE` (exact expected database name), `EXCHI_TENANT_CODE`, `EXCHI_TENANT_NAME`, `EXCHI_BOOTSTRAP_PHONE`, `EXCHI_BOOTSTRAP_NAME`, `EXCHI_OFFICIAL_RATE`, `EXCHI_OFFICIAL_SOURCE` (CBI URL), `EXCHI_INDICATIVE_RATE`, `EXCHI_INDICATIVE_SOURCE` (lawful internal evidence), `EXCHI_FX_EFFECTIVE_FROM` (ISO timestamp). No production rates are supplied by this package. Both rate rows remain DRAFT, including official reference. Do not use synthetic test values outside the disposable database.
```bash
EXCHI_SEED_APPROVED=YES bash scripts/release/seed-tenant.sh
EXCHI_SEED_APPROVED=YES bash scripts/release/seed-tenant.sh
psql "$EXCHI_SEED_PSQL_URL" -X -v ON_ERROR_STOP=1 -f packages/database/tests/gate1-indexes.sql
```
The seed initializes 13 role definitions and minimal existing permissions, creates an explicitly supplied first Super Admin identity for a new tenant only, rejects reuse of another principal, refuses conflicting existing configuration, and never activates finance or provides credentials. Full permission assignment, authenticator enrollment and commercial CRUD are later gates. An existing tenant must be reconciled through a separately authorized migration; this seed cannot silently promote an existing member.

## 5. Staging build configuration and runtime checks
The API validates configuration through Zod and checks the actual DB login before binding its socket. `RELEASE_ENV=staging` requires separate runtime DB login, Redis, distinct JWT secrets, S3 credentials, and the requested payment credential sets, with auth and financial execution disabled. These secrets are readiness requirements only, not proof that the services have been integrated. A production boot also requires Redis TLS. No credentials belong in `.env.example` or frontend environment. Use a private secrets manager; keep migration-owner credentials separate. API listens on loopback; live infrastructure provisioning is Gate 5. Set `NODE_ENV=production` and `RELEASE_ENV=staging` explicitly for a staging API process. Do not expose the API directly.
```bash
npm ci
npm run lint
npm run build
npm run typecheck
npm run test:gate1:env
npm run start -w @wholesale/enterprise-api
# separate terminal:
curl -fsS http://127.0.0.1:4000/v1/health
curl -fsS http://127.0.0.1:4000/v1/ready
```
The complete isolated runtime command tests the six frontends using local origins and synthetic sessions. A deployed staging environment and its own build/health evidence are still required. No staging deployment was made here.

## 6. Acceptance criteria and actual limitations
Required: committed audited lockfile; seven migrations applied; seed twice without duplicate records; runtime role nonprivileged; Prisma validation and generation; reviewed drift; RLS and concurrency checks; zero build/type/lint errors; authenticated HTTP and Chromium acceptance; green checks on the exact PR head; protected staging/main; authorized staging configuration and health evidence. No Gate 2 implementation or release until approval. Existing incomplete commercial endpoints remain inaccessible/locked; do not certify them as implemented. Current local runtime cannot install dependencies (DNS EAI_AGAIN), has no Docker/psql, and cannot push Git directly. Zod unit suite cannot load until npm ci. Original 35 regression tests and syntax checks passed; SQL, build, lint and new runtime tests have not passed. All financial and regulatory gates remain closed.
