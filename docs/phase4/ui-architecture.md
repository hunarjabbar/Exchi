# Phase 4 — enterprise UI architecture and design contract

Version 0.4.0 | 27 November 2026 | Design acceptance candidate

## Scope and boundaries

Six role-specific application shells, 70 prototype route concepts, 31 Command Centre workspaces. The standalone prototype deliberately has a role selector for review. It is not authentication, authorization, a production PWA or a connected administrative portal. All records and prices are synthetic. No API requests, personal information collection, real GPS/camera, actual OTP, payment or financial posting occur. Phase 3 source remains unchanged; its release blockers are reproduced separately. The provisional brand is Wholesale. (not a registered brand).

## Design foundations

Use semantic tokens from `design-system/tokens.json`. Tokens must be exposed as CSS variables in the shared UI package. Use a dark teal enterprise primary, mint functional tint, neutral cool canvas, and distinct semantic warning/danger/success values. Avoid using color alone for state. Display whitespace and subtle borders instead of ornamental gradients. Light and dark themes share component geometry. The working prototype uses local system font fallback rather than bundling fonts. Phase 5 must self-host licensed Inter, Cairo/Tajawal and verified Sorani-compatible Vazirmatn or equivalent; verify glyph coverage and PDF rendering.

- Desktop: 248px sidebar, sticky header, fluid max-width 1700px content, four-column KPI grid at large widths, 2:1 chart/exception split. Workspace header includes title, purpose and entitled actions.
- Tablet: two-column KPIs, adaptive grid, collapsible sidebar at 900px. Do not move operational actions into inaccessible hover menus.
- Mobile: minimum 44px control target for principal controls, narrow page gutters, bottom navigation for frequent retailer tasks, drawer navigation for all remaining sections, internally scrollable data grids with sticky SKU/identifier columns as a production enhancement. Admin workflows may use stacked cards for detail-first interaction; complex grids remain scrollable. Header role selector is prototype-only.
- Text: 12–14px metadata and table labels, 14–16px working copy, 18–22px section headers, 28–34px large headings/KPIs. Tabular figures for quantities and monetary values. Avoid aggressive tracking in Arabic/Sorani; isolate mixed scripts using bdi or Unicode isolation where appropriate.
- Motion: 120–180ms for short transitions, respect prefers-reduced-motion. No blocking animation. Avoid pulsing or animated KPI values that obscure precision.

## Application shells and routes

`design-system/routes.json` defines route concepts, trilingual titles, owner shell, domain resources, candidate permissions and scope note. Candidate permissions are derived from the actual Phase 3 permission CSV; they are not role grants. Production Next.js routes must use the authorized backend. Hash paths are prototype navigation, and detail example paths must become parameterized routes such as `/app/orders/[id]`.

Public: discover, price-masked catalog, staged registration. Retailer: procurement home, SKU search/scan, bulk order, cart, checkout, RFQ, delivery history, credit, invoices, returns, stores, team, documents, notifications, offline queue. Supplier: operations, catalog, stock/batches, fulfillment, promotions and settlement. Mandoob: daily agenda, territory, check-in, assisted onboarding, proxy order, collections, sync. Driver: assigned jobs, proof, custody and sync. Command Centre: 31 workspace concepts, grouped by Governance, Commercial, Supply chain, Finance and Administration.

Production session boundary: each application uses its own audience, host-scoped cookie and route manifest. The role switcher disappears outside a secured preview environment. UI checks improve usability but never authorize actions. The server derives tenant, user, membership and resource scope from the authenticated session; it must not trust submitted tenant or role labels. All requests must be rechecked after reconnect and account switch.

## Workspace template contracts

1. Executive dashboard: date range, authorized branch/supplier scope, reporting currency, KPI definitions, data-as-of stamp, trend series, action queue and drilldown. Loading: skeleton + accessible busy state. Stale: show last timestamp, no fabricated data. Error: retry and correlation reference. Empty: zero only when actual zero, otherwise unavailable.
2. Registry/list: saved filters, column selection, cursor pagination, sorting, single/bulk selection, archive/restore and export. Empty filtered result differs from genuinely empty workspace. Server-side filters and exports must retain scope. Bulk operations require impact preview and per-row results. Generic prototype tables do not implement all production controls.
3. Master editor drawer: identity, localized fields, dependent lookup, validation and revision. Save draft; publish through separate approval if needed; compare current version with user changes on HTTP 412/409. Restore only eligible archived records. Never provide hard-delete for posted records. Dirty-state close confirmation is required in production.
4. Protected transaction detail: header with reference, actor/owner, status and timestamp; separate commercial/payment/stock/shipment/accounting states; related entities; evidence register; allowed action bar; activity timeline. Buttons derive from server capabilities. Disabled actions explain missing policy, permissions, MFA, approval or source evidence. No bypass by editing fields.
5. Approval queue: prepare, review, evidence, decision reason, approval payload digest, independent actor, fresh MFA, expiration, resubmission when payload changes. A single approval does not activate unrelated capabilities.
6. Bulk import: download versioned template, upload/quarantine, mapping, dry run, validation rows, duplicate resolution, sensitive change approval, commit, retry/report. Export sample button in prototype demonstrates CSV download only; production export is server generated and audited.
7. Audit inspector: actor, timestamp, scoped record, mutation action, before/after diff, correlation reference, integrity digest, redaction markers. Copy reference only; no editing/deletion. External anchor and privileged audit remain Phase 3 blockers.
8. Health dashboard: deployed commit, version, observed timestamp, release gates, worker lag, queue oldest age, backup freshness, payment reconciliation exceptions; unavailable instead of guessed health. No live status is connected in prototype.

## Critical user journeys and error flows

| Journey | Required UI sequence | Exceptional states / resolution |
|---|---|---|
| Phone OTP | Normalized +964 phone, consent, channel choice, challenge, OTP, verified preview | Timeout/resend countdown, rate limit, incorrect challenge, SMS fallback; never disclose account existence unnecessarily |
| Storefront | Name/category, hierarchy, landmark, GPS accuracy, evidence | Permission denied, bad accuracy, no connectivity -> manual review, never treat manual pin as live evidence |
| Identity evidence | Camera capture/challenge, document type, upload progress, review, submit | Scan rejected, duplicate, expired, unavailable camera -> approved alternative; no client cache of identity images |
| KYC review | Scoped queue, secure viewer, checklist, reasons, approve/reject/reupload | Maker cannot approve own work; changed evidence invalidates prior review; decision and buyer tier are distinct |
| Catalog | Authorized snapshot, search, packaging selection, availability, MOQ | No results, unauthorized price, expired price snapshot, restricted category, stock outdated |
| Bulk procurement | Grid, keyboard entry, scanner, paste/import, validate, paid/bonus quantities, cart | Unknown SKU, invalid UOM, below MOQ, insufficient combined stock, expired promo; preserve input and show row errors |
| Checkout | Server quotation, seller split, address/zone, shipping/tax/FX, payment choice, acceptance | Changed price/stock -> explicit reacceptance; provider unknown -> status inquiry, not second collection; no official quote offline |
| RFQ | Request, quote revisions, expiry, compare, accept, convert | Supplier counteroffer, expired quote, modified quantity, no entitlement; accepted revision immutable |
| Warehouse | Allocation, FEFO pick, exception, pack, scan, dispatch | Expired lot, shelf life below threshold, short pick, quality quarantine, cold-chain excursion -> hold and authorized review |
| Mandoob | Assigned visit, consent, check-in, proxy cart, retailer authorization | Out of territory, revoked delegation, stale GPS -> draft or deny, never impersonate |
| Driver | Assigned job, route, delivery, accepted/returned qty, proof, collection receipt | Refusal, partial delivery, damage, customer absence, COD discrepancy -> explicit exception and custody tracking |
| Trade credit | Exposure, due dates, available credit, limits/terms, independent approval | Overdue, facility frozen, concurrent exposure, disputed receivable, missing policy -> blocked with reason |
| COD | Expected vs actual cash, invoice mapping, discrepancy reason, handover, maker/checker | Missing proof, shortage, duplicate receipt, incorrect allocation -> investigation and controlled adjustment |
| Ledger | Source, balanced lines, period, independent approval, MFA, post | Unbalanced, closed period, self-approval, stale payload, unverified source -> refuse; reversal instead of editing |
| Return | Original invoice, batch/qty, reason, inspection, disposition, refund or credit note | Exceeds returnable qty, expiry, damaged evidence -> quarantine or review; no double refund |
| Offline | Draft, local queue, reconnect, reauthenticate, requote, explicit acceptance | Idempotent replay, expired session, changed pricing, revoked permissions; display pending until authoritative server accepts |

## Localization and accessibility

Locale identifiers: `en`, `ar-IQ`, `ckb-IQ` in production. Prototype uses en/ar/ckb shell values. Direction follows locale. Use logical properties, mirror directional controls, do not reverse product images, barcodes, identifiers or meaningful charts. Use ICU plurals and full message IDs instead of concatenated fragments. Explicit numeral toggle applies to displayed numeric values, while canonical IDs and barcode strings stay unchanged. Dates use approved Iraqi time zone and locale; API timestamps remain UTC. Avoid translating brand names unless approved alias exists. Provide native editorial review and complete localization coverage before release. Prototype nav, key headings, selected labels and product names are localized; many detailed forms, table headings, status messages and sample records remain English.

WCAG 2.2 AA target: keyboard-only navigation, focus visible, focus return after dialogs, modal trap, programmatic field labels and errors, semantic tables, live regions for async results, text alternatives for meaningful charts, status text alongside color, zoom 200% and reflow. Prototype includes focus styling, labels, skip link, basic dialog trap and responsive layout; independent contrast, keyboard and screen-reader audit not completed. Production must test on TalkBack, VoiceOver, Chromium and Safari including low-end Android devices.

## Server contracts and blocked actions

- List queries: server cursor, scoped filters, sort, row revision, capability flags, data timestamp. Never compute entitlement from role names in the client.
- Mutations: `If-Match` revision, idempotency key when applicable, server-side audit, validation and approval. On 401 refresh/re-authenticate; 403 show denied without revealing protected data; 409/412 show conflict; 422 inline validation; 429 retry guidance; 5xx preserve draft and give correlation reference. Exact status conventions to be finalized in Phase 5 OpenAPI.
- Payment return: pending until verified provider callback/status; never mark paid from redirect. FX quote stores approved source/rate/effective version. Tax must be jurisdiction-specific. No parallel-rate checkout unless authorized. COD/credit/journal/payout remain disabled in prototype and production until Phase 3/5 controls pass.
- Offline production: IndexedDB scoped cache, operation queue, TTL, revocation and account-switch purge; background sync opportunistic with app-open/online fallback. Prototype uses in-memory state only, no service worker. The public masking sample hides display only; all synthetic prices exist in the JS fixture. Real prices must be omitted by authorized API before transmission.

## Component acceptance checklist

See `design-system/components.json` for component-level contracts and `tests/results.json` for observed Chromium results. All tests use synthetic data and are UI-only. Browser navigation was restricted in the execution environment, so the harness injects the self-contained HTML with Playwright set_content rather than connecting to a real HTTP origin. Direct-host routing, PWA install, service worker, CSP, authentication, API, data security, real localization, payment SDK, PDF/thermal output and field-device tests remain pending.

## Phase 5 handoff

Convert prototype to Next.js App Router shells with shared React components, tokens, next-intl message catalogs, typed REST clients and TanStack Query/Table; implement server capability responses and canonical routes; connect NestJS bounded contexts only after database acceptance. Preserve Phase 3 regulatory defaults and execute all unresolved database/concurrency/authorization tests. No live deployment or credentials have been provisioned in Phase 4.

## Phase 4.1 refinement
See [refinement-audit.md](refinement-audit.md) for the latest layout decisions, interface behavior, tests and limitations. Existing database and permission contracts remain unchanged.
