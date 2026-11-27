# Gate 1 runtime qualification (2026-11-27)

## Verified scope
- Remote toolchain run 46050075751, commit 260074b11f17ecab1b4b96250387e328fc51ad37: exact audited lockfile, lifecycle-enabled npm ci, zero known npm audit findings, PostgreSQL 16.4/PostGIS 3.4, Prisma 7 CLI fixture migration and zero fixture drift, Next 16 fixture compilation. Dependency artifact 15224880225 ZIP SHA-256 67dcddb0be771d775d069fdece2696c8fb46a93ac3ba1f7a06b4f5e17c1785c0.
- Remote public-image transfer run 46050608098, commit 0cd2f9fbb8a9888d47d9a12e2735cd80e8f362f0: public PostGIS image pinned by digest. Artifact 15225125552 ZIP SHA-256 bf4f137ee47cd09e8588f1cb1b77daf23b15fea1b005910d72166701fe88fc51.
- Locally imported verified Linux dependency archive, ran actual source on Node 22.16.0 (remote Node 22.23.5). The native PostgreSQL process was non-root and bound to loopback, with disposable credentials and a fresh test cluster. No production data or credentials involved. Image is an old qualification fixture, not a recommended production image.
- All six Next.js production builds and NestJS compilation succeeded; repeated whole build exited 0. Required Next 16 TypeScript config updates retained; generated Prisma and Next files excluded from source lint/syntax. Backend was rebuilt after the permission fix; final strict typecheck and lint passed.
- Prisma validates and generates the real 111-model schema. All seven migrations applied twice on fresh test DBs. SQL acceptance, authentication SQL, reference health, new indexes, two-pass synthetic seed and two-session inventory/credit concurrency passed. Actual Prisma diff has 291 proposed index removals and 8 composite FK removals; catalog confirms all those indexes valid/ready and FKs validated. Do not apply destructive drift SQL; SQL migrations are authoritative; formal model/SQL parity disposition still required.
- Initial HTTP smoke failed because the API called app_private.require_permission, whose execution is intentionally not granted to runtime. Replaced those five calls with a typed check of existing granted app_private.can, requiring a positive boolean. RLS remains independently enforced, and no privilege was added. The new run passed 73 HTTP assertions, including authorized and unauthorized catalog reads/writes and all financial execution flags false.
- 35 existing source tests plus 6 Zod environment tests passed. Browser authentication blocked by missing Playwright binary; IndexedDB blocked by browser navigation policy. No browser acceptance claimed.

## Reproduction on connected CI
Import source only after confirming repository visibility. Use a clean committed worktree and `npm ci`, `npm run test:gate1` per the Gate 1 runbook. This full Docker-based orchestration has not yet passed end to end. Use an up-to-date reviewed PostgreSQL 16/PostGIS image for staging and verify its extensions and patch level. Review SQL-only schema objects before approving any schema drift changes. Never apply Prisma db push or generated diff to the database.

## Remaining gates
Private/public visibility confirmation and full source import, branch protections, actual full CI on exact imported commit, browser acceptance, formal drift disposition, staging service health and independent reviewer approval. Gate 2 remains unauthorized. Payment, trade credit, posting, payout, FX, binding order and regulated goods execution remain locked.

Evidence log formatting: terminal table padding and trailing whitespace normalized for Git; substantive output unchanged.
