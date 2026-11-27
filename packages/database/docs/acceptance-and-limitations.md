# Acceptance register and release blockers

## Authored database acceptance coverage (not executed here)

- 19 governorates; Halabja present; providers disabled.
- Cross-tenant and cross-scope generic insert denial; scope-limited read; missing actor denial.
- Composite tenant FK rejection; revision increment.
- No generic journal mutation; missing financial policy denies posting and trade-credit commitment.
- Reservation replay idempotence; insufficient stock denial.
- Credit replay idempotence; over-limit denial.
- Maker cannot post own journal; unbalanced journal rejected; independently posted balanced journal.
- Posted journal and child rows immutable; audit log visible to authorized role, immutable even under ordinary owner DML.

## Required before production approval

1. Execute clean migration and Prisma validation/generation on PostgreSQL/PostGIS, run SQL suite and inspect actual database privileges and SQL/ORM drift. Current environment had neither PostgreSQL nor Docker; npm registry DNS resolution failed. Static validation is not a substitute.
2. Add concurrent two-session stock and credit tests, payment webhook replay and mismatch tests, refund/allocation caps, period closure races, invoice totals and split fulfillment tests. The current reserve and commitment commands use row locks, but races have not been exercised. FEFO indexes and lot eligibility exist; a complete multi-lot FEFO allocation service is not yet implemented.
3. Complete protected transaction commands and policies for KYC state transitions, pricing publication and non-overlapping effective dates, MOQ and promotions, order submission/cancellation, quote and invoice totals, procurement receiving/landed cost, inventory movement and reservation consumption, credit-to-receivable transitions, credit payment allocation, payment refunds/payouts, COD reconciliation, returns and approvals. Tables and some structural checks exist; full state-machine/aggregate enforcement does not. A posted journal has SQL balancing and independent maker/checker checks; approval-payload binding, fresh MFA and approved posting source evidence are still application/service duties. Reversal account totals are checked but reversal issuance workflow is pending.
4. Verify direct writes by all deployed service roles, protect write scopes and document evidence with narrow command functions, implement buyer price masking at the API (RLS table permission supports denying access, but does not implement all dynamic pricing entitlements), verify actual tenant/branch/retailer ownership and membership derivation. Generic table grants are not suitable for untrusted SQL access. No global administrative cross-tenant bypass is implemented for runtime; global operations require separately governed service paths.
5. Certify provider adapter signature checks/status inquiries. `confirm_payment` requires trusted verified webhook evidence bound to the intent, merchant, amount, currency and provider reference; verification and exact merchant credential identity are service duties. Provider event ID deduplication is merchant-scoped. Payout/refund and manual COD services not implemented. Keep all payment execution disabled until verified.
6. Add complete official district/subdistrict registry and validated geometry sources, local Sorani editorial review, licensed product rules, local tax/FX legal opinions and approved commercial model. Governorate codes in seeds are internal identifiers, not ISO codes.
7. Audit events are redacted before/after snapshots with per-event SHA-256 digests and append-only triggers. This does not protect against privileged database administration, and external anchoring, WORM archive, retention and redaction verification are still required. Do not store arbitrary secrets or national ID details in JSON or free-text fields. Identity/tenant/global reference mutations require separate privileged audit trail; only tenant-owned mutations are audited by the current trigger design. Correlation IDs must be opaque and non-sensitive.
8. Add signed production deployment manifest, dependency lockfile, backup restore and disaster recovery tests, query/load benchmarks, comprehensive RLS tests for each permission and actual application routes. Neither a GitHub repo nor cloud database was created or altered.

## Geographic reference

UK Permanent Committee on Geographical Names, Iraq Toponymic Factfile (updated 2025): https://assets.publishing.service.gov.uk/media/6144b2cde90e07043e85e0c5/Iraq-PCGN_Toponymic_Factfile-2021-final_version.pdf . EUAA country information also confirms Halabja as the 19th governorate: https://dip-aws.euaa.europa.eu/country-origin-information-report/148-kurdistan-region-iraq-erbil-dohuk-sulaymaniyah .

## PostgreSQL and Prisma reference

https://www.postgresql.org/docs/17/ddl-rowsecurity.html
https://docs.prisma.io/docs/orm/prisma-schema/data-model/multi-schema
https://www.prisma.io/docs/orm/v6/prisma-client/using-raw-sql/safeql
