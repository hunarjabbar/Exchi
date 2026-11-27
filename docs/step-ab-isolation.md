# Step A/B fresh-runtime certification (alpha.3)

This increment changes the certification harness only. Six original migrations, all application source, role/audience boundaries, visual identity and financial release gates remain unchanged. No Step C implementation.

## Root cause corrected
The previous acceptance runner reused a persistent development volume. Repeated HTTP/browser tests can be influenced by OTP cooldowns, prior authenticator steps and existing synthetic accounts. A certification run must not reset a developer's database or use existing services.

## New default certification command
On a connected Linux/WSL environment with Docker (local default Unix socket context), Node 22, npm, PostgreSQL client, Python/Playwright, curl and setsid:

```sh
# Only when no lockfile exists; review actual dependency graph before committing.
npm install --package-lock-only --ignore-scripts --no-audit --no-fund
npm run check:lock
npm ci
npm audit --audit-level=high
git add package-lock.json
git commit -m 'Pin reviewed wholesale dependencies'

python3 -m venv .venv-cert
source .venv-cert/bin/activate
python -m pip install playwright==1.57.0
python -m playwright install --with-deps chromium
npm run test:step-ab:fresh
```

The fresh runner requires a clean tracked commit and tracked lockfile. It checks required tools and free loopback ports (3000–3005, 4000, 55432), refuses a remote or externally selected Docker context, allocates a detached temporary worktree, creates fresh synthetic credentials and uses a uniquely named Compose project `wholesale-cert-<16 hex>`. It invokes the existing runtime suite, cleans up only the allocated project and its worktree, and copies an explicit allowlist of metadata. `acceptance-evidence/isolated-run.json` records outcome and cleanup state; a successful runtime marker is emitted only after cleanup. Existing development or production databases are not adopted or reset. A port conflict blocks the run; never stop another project's service to satisfy this test.

CI now invokes the fresh runner rather than the persistent development bootstrap. Abrupt process termination or Docker failure can leave an owned temporary project requiring manual inspection; never use global prune or delete other projects. If cleanup fails, the report records the worktree path and exact project name. The old runtime command remains available for intentional local debugging; it is not the canonical certification entry point.

## Verification and limitations
15 core + 10 auth + 9 certification tests executed locally. New tests verify fail-closed behavior with missing lockfile and stale-marker removal in a real temporary Git repository, and inspect unique project/worktree/CI wiring. Static route/schema checks and syntax transpilation also run. Docker/PostgreSQL, npm DNS access and full application runtime remain unavailable in this environment; no SQL or CI success is claimed. Chromium offline navigation was retried and failed with ERR_BLOCKED_BY_ADMINISTRATOR before assertions. The isolated execution path beyond preflight has not run. Remote GitHub, actual dependency lockfile, Prisma validation, migrations, authenticated browser tests and financial authorization remain outstanding.
