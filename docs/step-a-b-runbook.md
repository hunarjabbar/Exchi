# Phase 5 · Steps A and B — local execution and certification runbook

Status: source candidate; SQL and full application runtime certification remain pending. This branch is independent of CCC, ICA, and any other existing infrastructure. It does not activate financial execution. No Step C expansion is included.

## A. Isolated repository and prerequisites

Recommended environment: Linux or WSL2 Ubuntu, Node 22.16+ (Node 22 LTS), npm 10+, Git, Python 3, Docker Engine with Compose v2, PostgreSQL client (`psql`), `curl`, and optional authenticated GitHub CLI (`gh`). On Ubuntu with Node/Docker already installed: `sudo apt-get update && sudo apt-get install -y git python3 postgresql-client curl util-linux`. Docker Desktop users can run from WSL2 with Docker integration enabled. Do not run against existing CCC/ICA databases. The isolated local database uses 127.0.0.1:55432, separate Compose project `wholesale-stepab-local`, and volume `wholesale_step_ab_data`. If the port is occupied, stop the procedure and choose a different isolated port consistently; never stop unrelated services.

From the supplied Git bundle (contains original main and incremental branch):

```bash
git bundle verify /absolute/path/wholesale-enterprise-step-ab.bundle # inside an existing Git repo, or skip until clone
git clone -b phase5/step-a-b /absolute/path/wholesale-enterprise-step-ab.bundle iraq-wholesale-enterprise
cd iraq-wholesale-enterprise
git branch main origin/main
git remote rename origin source-bundle
git log -2 --oneline
git status --short
```

For the existing Phase 5.1 working copy instead, first require a clean working tree, then import the branch without modifying main:

```bash
git status --short
git fetch /absolute/path/wholesale-enterprise-step-ab.bundle refs/heads/phase5/step-a-b:refs/heads/phase5/step-a-b
git switch phase5/step-a-b
```

For a new private remote only (optional until local verification):

```bash
gh auth status
gh repo create hunarjabbar/iraq-wholesale-enterprise --private
git remote add origin https://github.com/hunarjabbar/iraq-wholesale-enterprise.git
git push -u origin main
git push -u origin phase5/step-a-b
```

If the repo already exists, confirm it is the intended independent repository and use the `git remote add` command only if no origin exists. Do not overwrite or force-push any remote. The connector did not create a remote; the commands above are for the authenticated owner. Use an approved protected branch/PR workflow after CI. Avoid putting credentials in remote URLs.

## B. Local environment, dependency installation and database certification

From repository root:

```bash
node -v && npm -v && git --version && docker compose version && psql --version
npm install --package-lock-only --ignore-scripts --no-audit --no-fund # only if no lockfile exists
# Review and commit package-lock.json before certification.
npm run check:lock
bash scripts/bootstrap-step-ab.sh
```

The bootstrap is fully executable, not a placeholder. It installs dependencies, starts an isolated database, runs unit and static tests, validates Prisma, generates the client, deploys all six migrations, executes the Phase 3 and Phase 5 SQL acceptance suites, creates a restricted runtime login, installs synthetic local fixtures, tests the new auth SQL and reference data, checks Prisma migration status, writes a Prisma drift report, runs two-session stock and credit contention tests in a temporary separate database, and builds all seven application workspaces. Certification now refuses a missing lockfile and always uses `npm ci`. The separate lockfile generation command must be run on a connected development machine. Review vulnerability reports with `npm audit` and resolve findings before any release. Commit the generated lockfile only after review and successful clean build. No lockfile could be generated in the authoring environment.

Equivalent commands to inspect/re-run individual stages (bootstrap also creates the runtime login and fixtures):

```bash
set -a; source .local-stepab.env; set +a
npm ci --no-audit --no-fund # requires reviewed lockfile
docker compose -p wholesale-stepab-local -f compose.step-ab.yaml up -d --wait
npm run test:core
npm run test:auth
npm run test:static
npm run validate -w iraq-wholesale-phase3
npm run generate -w iraq-wholesale-phase3
npm run migrate -w iraq-wholesale-phase3
ALLOW_DISPOSABLE_DB_TEST=YES npm run test:db
(cd packages/database && npx --no-install prisma migrate status)
psql "${DATABASE_URL%%\?*}" -X -v ON_ERROR_STOP=1 -f packages/database/tests/step-ab-health.sql
psql "${DATABASE_URL%%\?*}" -X -v ON_ERROR_STOP=1 -f packages/database/tests/step-ab-auth.sql
python3 scripts/concurrency-step-ab.py
npm run build
```

The health/auth commands require the fixture and runtime login created by the bootstrap. All SQL test suites use synthetic disposable data. Prior migrations 001–005 are unchanged. Do not use `prisma db push` or apply the Prisma diff script: Prisma does not represent RLS, triggers, custom constraints or every index. Inspect `.local-stepab-logs/prisma-diff.sql`; unexplained drift is a failed gate, not an instruction to drop SQL protections. PostgreSQL 16/PostGIS 3.4 is the retained baseline. Migrations require a dedicated privileged owner due to existing SECURITY DEFINER functions; API runtime uses a separate NOINHERIT, NOBYPASSRLS, NOSUPERUSER login and transaction-local `SET ROLE wholesale_runtime`. The local owner is only for disposable testing. Production least-privilege migration ownership requires separate review.

## C. Start and test actual built application processes (still Step A/B acceptance, not Phase 5 Step C)

Terminal 1:

```bash
bash scripts/start-step-ab.sh
```

Terminal 2, from the repository root:

```bash
set -a; source .local-stepab.env; set +a
curl -fsS http://127.0.0.1:4000/v1/ready
npm run test:step-ab:smoke
```

The HTTP test requires running API and all six built applications. It verifies real HTTP status, page rendering, protected cookies, correct-role login, OTP replay and concurrent consumption, unauthorized origin, KYC price omission, exact-tier IQD prices, tenant isolation, approval gating, idempotent non-binding draft receipt, authorized catalog master creation/edit/archive/restore, stale revision rejection, role denial and session logout/revocation. No network provider credentials are required and no real messages are sent. Run on a fresh disposable fixture or wait at least 60 seconds after a previous OTP request and until hourly limits/TOTP replay windows clear. Seed is idempotent but intentionally never resets existing local data. Do not run the local seed on a real database.

Local URLs: public `http://localhost:3000`, retailer `http://localhost:3001`, supplier `http://localhost:3002`, Mandoob `http://localhost:3003`, driver `http://localhost:3004`, Command Centre `http://localhost:3005`. Use `localhost` rather than `127.0.0.1` for browser frontend URLs because the local origin allowlist uses localhost. All cookies retain Secure, HttpOnly, SameSite=Strict and host-only `__Host-` naming. Audience-specific cookie names prevent collisions when separate local applications share the same hostname. In deployment, use distinct HTTPS origins, trusted TLS and a private API network. Ctrl-C in Terminal 1 stops only these local processes. To stop the local database without removing data: `docker compose -p wholesale-stepab-local -f compose.step-ab.yaml stop`.

## D. Manual authentication verification

Organization code: `wholesale-local`. Synthetic phone fixtures (never use live providers with these):

| Account | Phone | Audience | Expected behavior |
|---|---|---|---|
| New retailer | +9647500000001 | retailer | OTP creates preview account; no price fields |
| Approved retailer | +9647500000002 | retailer | STANDARD IQD offer only; no VIP price |
| Command admin | +9647500000003 | command | OTP + TOTP; catalog master read/write |
| Mandoob | +9647500000004 | field | OTP + TOTP; no Command CRUD |
| Wholesaler | +9647500000005 | supplier | OTP + TOTP; no Command CRUD |
| Driver | +9647500000006 | driver | OTP + TOTP; no Command CRUD |
| Command viewer | +9647500000007 | command | OTP + TOTP; brand read only |

The dev OTP is shown by the UI solely in the explicitly enabled local synthetic environment. To get a current code for local staff, run `set -a; source .local-stepab.env; set +a; node --experimental-strip-types scripts/local-totp.ts 03` (replace 03 with 04, 05, 06 or 07). TOTP cannot be reused, so generate a fresh code for a fresh login. Do not put real TOTP secrets in source or frontend environments. The synthetic fixture does not contain real national IDs, documents, merchant credentials or funds.

## E. Authentication design, boundaries and remaining certification

- Normalize local `07xxxxxxxxx`, `00964...`, E.164 and Eastern digits to `+9647xxxxxxxxx`. This validates the mobile numbering shape, not a current CMC allocation database or ownership.
- OTP uses CSPRNG, keyed HMAC of challenge ID + phone + tenant + audience + code, five-minute TTL, per-phone 60-second cooldown, five sends per hour, global 300-per-minute admission budget, five verification attempts, row lock, one-time consume. Wrong valid-shaped codes increment attempts and are committed even when HTTP returns 401. Unknown users get no account-enumeration details.
- Retailer self-registration after OTP is allowed only for `AUTH_RETAILER_SIGNUP_TENANT`, with a provisioned tenant role code RETAILER; new account is PREVIEW with PHONE_VERIFIED KYC case. Existing users cannot auto-promote themselves. Other audiences require operator-provisioned membership, role assignment and audience grant (`auth.login.field`, `.supplier`, `.command`, `.driver`), plus TOTP. Supplier login additionally requires approved supplier profile and active party relationship.
- Session is a 256-bit random opaque token; only SHA-256 digest stored in DB. Every API request resolves active membership, role, scope, audience, expiry and revocation. Non-retailer session additionally requires recent MFA. New session rotates prior tokens for that membership/audience. Logout revokes server-side, then clears browser cookie and local drafts. Retail session expiry 24h; non-retailer 8h. No browser bearer token is returned by the BFF. No browser-supplied tenant or role overrides session context.
- `app_private.can` uses the transaction-local application audience to restrict permissions to roles carrying the same explicit audience grant. Database permissions and existing RLS remain authoritative. Existing legacy resolver remains for the historical Phase 5 tests, not HTTP. Browser clients never receive DB credentials or direct SQL access. Role/session context is trusted server input; a compromised runtime credential is a high-severity threat and needs private network/secret protection.
- `retail_catalog` returns only globally published, active, non-regulated root-category products in the authenticated tenant. Before approved KYC, the JSON lacks `price_rules` entirely. Approval requires active retailer party, matching profile + latest KYC case + independent decision record, non-preview tier. Approved output is exact-tier current IQD rules for operator-owned offers. Supplier marketplace offer eligibility, full category inheritance, pricing selection and commercial quotation belong to Step C. KYC suspension or expired/replaced case blocks pricing on next API call; no financial execution is activated. KYC full evidence upload/review workflow is outside this guard-layer increment. There is no public KYC approval endpoint. The fixture is operator-seeded, not a bypass in an application route.
- WhatsApp Cloud API uses approved copy-code authentication templates (code passed as body and URL-button parameter). SMS fallback is an explicit retry through the SMS button after cooldown; provider errors invalidate the current challenge. The SMS adapter uses Twilio Programmable Messaging Basic authentication with an approved sender. Provider acceptance of the request is not proof of delivery. Live delivery is disabled unless AUTH_MODE=live AND AUTH_LIVE_APPROVED=YES, and requires actual provider credentials/template/sender certification. No live credential or delivery exists in this package. Source tests use intercepted requests, not real provider certification.
- Staff TOTP is RFC 6238 with 30-second period, ±1 window and per-principal replay prevention. Per-phone 20-byte hexadecimal secret values are operator-provisioned in a protected API secret store (`AUTH_STAFF_TOTP_JSON`), not hardcoded. The production enrollment, reset/recovery, device binding/WebAuthn and external abuse-control/WAF workflows require separate secure acceptance before production. A server-side phone-to-secret map is a staging baseline, not a long-term enterprise secrets design. Use distinct environments and keys, never share dev secrets with live.
- No regulatory or financial gates have been opened. Domain CRUD and commercial lifecycle beyond existing catalog draft controls and non-binding draft reception remain outside Steps A/B. The earlier 70 route registry and Phase 4.1 visual identity are preserved.

## F. Gate before Step C

Require successful dependency resolution and lockfile, full build, all migrations and Prisma compiler success, clean or explained schema diff, all SQL assertions, all HTTP smoke assertions, actual Chromium/browser storage and security tests, concurrent stock and credit tests in `scripts/concurrency-step-ab.py`, and external provider sandbox certification for real WhatsApp/SMS. Do not promote based on static results alone. Phase 5 Step C is not authorized by this package.
