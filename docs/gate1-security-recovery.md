# Exchi Gate 1 dependency recovery — candidate, not release

The dependency-only GitHub branch `release/gate-1-dependencies` is not an application and must not be merged into main or staging. Its successful run 46049571494 (commit `6a468558d7a96994c79e4abdd82de5a8a7c83de2`) produced artifact 15223139486. Artifact and lockfile SHA-256 values are recorded in `evidence/gate1-security/remote-review.json`. The lockfile in this branch is copied byte-for-byte from that artifact. The remote runner executed `npm ci --ignore-scripts`, then `npm audit --audit-level=high`, reporting zero known findings. Full lifecycle installation has not passed. ESLint 9 is flagged deprecated and needs a reviewed migration to a supported version before production approval.

Security candidate: Next 16.4.6, Prisma and Prisma Client 7.10.1, Zod 4.6.7, targeted @prisma/config Effect override resolving 3.22.5. All 12 workspace dependency declarations match the recovered lockfile. Prisma CLI configuration now lives in `packages/database/prisma.config.ts`; all seven original SQL migration files are unchanged. Prisma Client generation uses a workspace-local ignored output; no application currently instantiates Prisma Client (the API uses pg). If a client is integrated later, use the appropriate driver adapter. Do not apply the schema-drift report automatically.

## Verify on an isolated networked Linux/WSL2 machine

Use Node 22.23.5 (`.nvmrc`), npm 10.9.9, Docker with local Compose v2, PostgreSQL client and Playwright. Do not regenerate the reviewed lockfile merely to test it.

```bash
npm run check:lock
npm ci
npm audit --audit-level=high
python3 -m venv .venv-cert
source .venv-cert/bin/activate
python -m pip install playwright==1.57.0
python -m playwright install --with-deps chromium
npm run test:gate1
```

The isolated harness executes full migration, database, application, authentication and browser tests. Review the commit-linked acceptance metadata and Prisma drift. The remote dependency-only result cannot certify this candidate. No financial or regulatory gates were changed.

## Import after repository visibility is confirmed

Import the security candidate from `exchi-gate1-security.bundle` to a new branch rooted at Exchi staging; preserve both histories and the original README (see `docs/exchi-gate1.md`). Use the bundle's `refs/heads/release/gate-1-security` as the import source. Run mandatory CI against the full candidate. Do not merge the dependency-only branch and do not force-push main/staging. Confirm repository visibility and apply the required branch protections using authorized administration credentials. Gate 2 remains blocked until Gate 1 is certified and the owner explicitly approves progression.
