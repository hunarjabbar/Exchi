# Step A/B certification increment — v0.5.1-alpha.2

This increment preserves all six migrations, application source and design/route contracts from 9e065e5. It changes the acceptance harness, not the commercial or financial domain. Step C and production execution remain unauthorized.

## Changes
- CI requires a tracked npm v3 lockfile and uses `npm ci` only. A structural guard checks workspace manifest agreement; npm ci remains the authoritative dependency-graph validation. No fake lockfile has been generated.
- The runtime CI job executes the same isolated Compose bootstrap as local development, including SQL acceptance, PostgreSQL contention, all builds, HTTP smoke, real Chromium auth and IndexedDB tests. The runtime runner clears its own prior acceptance markers, refuses occupied application ports and terminates only its application supervisor. CI cleans only its own named test database on the ephemeral runner.
- Chromium auth uses the actual React form and real API responses. It checks secure HttpOnly host-only cookies, reload, catalog price omission, independent browser contexts, cross-audience denial, simultaneous retailer and staff sessions, and logout. No token injection and no mocked network. The browser uses synthetic retailer 10 and staff 08 (separate from the HTTP smoke identities). The staff 08 local secret is appended without changing existing passwords by the private-file fixture upgrade script.
- Source tests cover missing lockfile, workspace drift, empty package graph, CI wiring and idempotent fixture upgrade. They do not certify real installed dependencies.

## Reproducible execution
Use Linux/WSL2 with Node 22.16.0, npm 10, Python, Docker Compose v2, psql, curl and util-linux. No production database URLs. Confirm ports 3000–3005, 4000 and 55432 are free for this independent project or already reserved solely for its isolated database. Do not stop unrelated infrastructure.

On a connected machine, only if the lockfile is absent:

```sh
npm install --package-lock-only --ignore-scripts --no-audit --no-fund
npm run check:lock
npm ci --no-audit --no-fund
npm audit --audit-level=high
# Review the actual lockfile and dependency changes before committing.
git add package-lock.json
git commit -m 'Pin reviewed wholesale dependency graph'
```

For subsequent acceptance runs:

```sh
python3 -m venv .venv-cert
source .venv-cert/bin/activate
python -m pip install playwright==1.57.0
python -m playwright install --with-deps chromium
npm run test:step-ab:runtime
```

The script uses only the named disposable development database. Existing local fixture credentials are preserved. Repeated smoke runs may hit legitimate OTP cooldowns; use a fresh isolated test environment or wait for the configured rate-limit windows. Do not reset or modify another project's data. Do not include .local-stepab.env, secrets, session tokens, or raw app logs in a shared archive. Review `acceptance-evidence/` for sensitive information before sharing it. A success marker means the runtime commands completed, not regulatory approval or schema-drift acceptance. Review Prisma drift SQL manually, dependency audit, CI results, and runtime test output before Step C.

## Actual local verification
15 core, 10 auth, 7 certification tests passed; 29 TS/TSX files syntax-transpiled. Static route and database checks passed. The full runtime runner was actually invoked and failed closed at the absent lockfile (exit 2). npm DNS EAI_AGAIN, Docker and psql absent. Browser, full build, PostgreSQL, concurrency, Prisma and live provider acceptance are not executed. Remote repository is not modified; branch protection and mandatory GitHub status configuration are not verified. No production financial or regulatory gates are changed.
