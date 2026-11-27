# Phase 4.1 — UX audit and engineering handoff

Status: local, synthetic interactive prototype. Phase 5 not started. The original Phase 4 source package is retained separately. The existing route registry, Phase 3 permission registry and release gate document are byte-for-byte unchanged (see tests/preserved-contracts.json).

## Implemented corrections

| Finding | Correction | Evidence |
|---|---|---|
| Tall header and crowded mobile controls | compact single-row header; theme/digits moved to preferences on mobile; short labels and direct cart navigation; safe-area-aware bottom bar | rendering matrix; menu interaction |
| Horizontal table dependence on mobile | labelled stacked cards below 600px, compact quick-order record grid; summary jump control | mobile screenshots; overflow checks |
| Generic workspace templates with weak task context | 23 command table workspaces receive specific review context and cross-workspace links; sort, status filter, reset, existing local CRUD drafts | sorting and workspace tests |
| Sparse Arabic and Sorani strings | additional dictionary for common fields, states, critical flows, warnings and navigation; RTL tracking and arrows; localized digit normalization | locale matrix and barcode/KYC tests |
| Checkout address lost on payment changes | in-memory path-keyed input state | checkout test |
| KYC form lost on back-navigation | in-memory synthetic state; clear after demo submission; localized OTP input | onboarding test |
| Role switch leaked demo cart and queue | role-scoped state store, restored on return | role-switch tests |
| Driver and field cash UI reused treasury reconcile screen | dedicated restricted custody view; disabled receipt action | driver test |
| Invalid delivery proof / negative COD | sample quantity and amount validation; invalid amount shown; no live confirmation | driver and COD tests |
| All queued items incorrectly become requotes | order drafts require requote; evidence drafts require evidence review | driver reconnect test |
| Keyboard focus could escape overlays or disappear on close | inert background, modal menu, Escape and return focus | focus tests |
| Search only exact raw strings | normalized Arabic/Sorani letters and digits, small curated product-alias dictionary; not full fuzzy search | normalized barcode and alias test |

## Component contracts for implementation

- AppShell: distinct application audiences, authorized organization context, mobile settings panel, focus recovery and safe-area navigation. Replace demo role chooser with authenticated server session.
- DataGrid: stable row identity; server filtering/sort/pagination; semantic column headers; mobile records with labels; preserve keyboard behavior; empty/error/loading states. Do not use client sorting over incomplete paginated data.
- RecordDrawer: restore focus, inert background, expected revision and conflict resolver, draft field values isolated by actor and scope. Production editor must use schema-specific controls and server validation.
- QuickOrderGrid: compact mobile rows, summary jump, UOM/MOQ/bonus quantities; support 50+ lines with virtualization and paste validation in production. Sample has six products only.
- KycStepper: synthetic data only in this prototype; real identity evidence must use protected API/storage and approved consent; no caching OTP or KYC files in production.
- PaymentMethodPicker: preserve non-sensitive address fields on method change; server-generated quotation, explicit gate status, no acceptance without verification.
- OfflineQueue: role-isolated in-memory command samples; order and evidence states distinct; production uses account/organization-scoped IndexedDB, expiry, idempotency and authenticated replay.
- Treasury and collections: field/driver custody is not finance reconciliation. No receipt issuance, cash posting, payments or journals enabled here.

## Phase 5 prerequisites and known limitations

1. Real authentication/RBAC, server authorization, PostgreSQL runtime acceptance, Prisma validation and cross-tenant tests remain open. No changes to Phase 3 SQL or permission registry.
2. 70 routes are navigable design concepts, not 70 fully implemented modules. The 23 context panels are not executable domain operations. Many complex workflows remain placeholders; generic CRUD edits are demo-only and the initial record is intentionally read-only for edit.
3. Arabic and Sorani translations are draft, not native-reviewed. Some English descriptions, sample names, status prose, technical identifiers and number/currency formatting remain. Fonts remain fallbacks. The dictionary is a prototype mechanism, not the production ICU translation system; use keys and pluralization in Next.js.
4. Desktop and mobile data grid sorting/filtering operate on local fixtures. Server-side bulk import/export, true pagination, audit history, conflict resolution and policy-specific forms still need full implementation.
5. Offline state is in memory only; browser reload clears drafts. The preview stores synthetic phone/OTP and form values temporarily in memory. Do not enter real data. No actual service worker, GPS, camera, WhatsApp, barcode camera or payment adapters exist here.
6. Render matrix and functional tests use Chromium with injected self-contained HTML. No screen-reader certification, WCAG audit, physical device testing or actual network throttling/production latency evidence. Semantic mobile table accessibility needs manual assistive-technology review. Contrast and focus styles are design targets, not a compliance certificate.
7. The prototype still uses provisional Wholesale. identity and original teal/mint palette. Do not assume a final brand or licensed font assets.
8. Financial and regulatory gates are unchanged. Do not enable posting, payouts, credit commitments or FX conversion on the basis of interface acceptance.

## Reproduction

`python scripts/build_preview.py`

`python tests/browser_acceptance.py`

`python tests/refinement_acceptance.py`

Test dependencies: Python Playwright and Chromium at /usr/bin/chromium (adjust on other platforms). The original regression suite has 15 checks; the refinement suite has 14 checks and 1,680 route/viewport/locale/theme render combinations. Results are local evidence, not live deployment certification.
