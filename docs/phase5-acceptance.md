# Phase 5 acceptance and limitations — v0.5.0-alpha.1

## Actual changes

1. Six Next.js application source shells, fixed audiences, 70 canonical route allowlists, same-origin backend proxy, shared UI and day/night RTL/LTR behavior. No application build was executed.
2. NestJS API candidate with hashed-token session lookup; transaction-local tenant and membership context, `wholesale_runtime` role, parameterized SQL, explicit route read projections, no generic arbitrary-table write. 28 command route projections; 3 command routes remain explicitly unimplemented. Non-command data access remains largely unimplemented.
3. Restricted catalog brands, categories and product drafts: list, create, update and archive/restore commands; revision checks. Product publication, category regulatory policy, supplier-specific catalog access, reference-aware archival, bulk imports and other CRUD remain pending. No API or database runtime test executed.
4. New session boundary migration: checks active tenant, principal, membership, scope, device if present, expiry, revocation and audience. Revokes generic session/device SELECT because those tables expose digests or credential data. Session issuance, role-to-audience provisioning, OTP, MFA, secure recovery, session rotation/logout and full policy tests still required.
5. IndexedDB draft storage partitioned by tenant, membership, scope and application audience, with positive-quantity validation, single-line and bulk paste (up to 250 lines). A new database inbox function requires cart-create permission, active retailer party delegation and retailer scope. It hashes payload, deduplicates per member and operation key, rejects conflicting replay, and returns REQUOTE_REQUIRED. No real order, credit, stock reservation, or payment is performed. Actual IndexedDB persistence and server receipt are unverified; local partition is a UI/storage separation, not an encrypted security boundary. Clear local data and sign-out handling must be implemented before production. Offline launch provides only a public fallback page.
6. All original three SQL migrations retained unchanged; two additive migrations. Prisma SyncOperation adds one nullable JSON field. No production authorization or legal policy relaxed.
7. Existing provider schema retained; live webhook endpoint responds 503 and does not process data. Provider contracts and real implementations are still pending. Do not treat the presence of tables or endpoints as working integrations.

## Executed evidence

| Test | Result |
| --- | --- |
| Node dependency-free core | 15/15 |
| Static route, schema and guard checks | Pass |
| TypeScript syntax-only transpilation | 23 files, 0 syntax errors |
| Strict dependency-free TypeScript check | Pass (core + offline module) |
| Browser IndexedDB module test | Blocked before assertions: browser navigation denied |
| Prisma validate/generate and Postgres migrations | Not run: PostgreSQL/Docker unavailable; npm registry DNS failed |
| Next.js/NestJS full build and type checking | Not run: dependencies unavailable |
| GitHub CI | Not run: no remote repository created |
| Provider or regulatory certification | Not initiated |

Phase 4.1 previous 29/29 browser checks and 1,680 rendering combinations apply only to the design prototype. They do not prove the new application build.

## Remaining release-critical work (not delivered)

- Remote private repository, dependency lockfile, successful CI, database owner/grant verification, migration rollback/restore, Prisma client generation, concurrent stock/credit/payment and negative authorization tests.
- OTP via actual WhatsApp/SMS, session issuing, passwordless staff MFA, recovery, KYC document lifecycle, supplier and field onboarding, private object storage, native-reviewed localization, permission assignments, and audit log governance.
- Complete retailer product search and price entitlements, quote engine, promotion and tier rules, UOM, MOQ, authoritative stock, RFQ, checkout, order acceptance, reorders, service worker app-shell caching, robust offline sync and account logout cache clearing.
- Complete supplier, warehouse, procurement, field sales and driver workflows, routes, courier and GPS integrations, deliveries/returns, cold chain, district registry.
- Full domain-specific Command Centre CRUD and approval workstations, executive dashboards, advanced data grids, import/export, proper conflict resolution, contextual records, complete financial and accounting views. Read projections are not substitutes for these workstations.
- Treasury, COD closure, payment allocations/refunds, credit-to-receivable conversion, settlement, official FX/legal policy, journal maker-checker with fresh MFA, invoice and tax controls, signed provider adapter verification, private PDFs and WhatsApp delivery. No money-moving or financial posting endpoint is exposed in this increment.
- Durable event workers, production observability, signed audit anchoring and archival, security testing, device/browser and WCAG testing, performance/load, real hosting and disaster recovery. Original Phase 3 limitations and Phase 4 release gates remain binding.

## Next engineering gate

First execute clean migrations and the actual framework builds in an isolated staging environment. Fix failures without bypassing financial or authorization controls. Then implement and certify one real identity→KYC→catalog→quotation→order→fulfillment→COD/ledger flow before broadening domain CRUD and provider integrations. All payment, credit, FX and journal execution remain locked.
