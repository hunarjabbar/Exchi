# Gate 2 — Identity, KYC, RBAC and Audit

Status: implementation branch opened; this document records the verified baseline and the acceptance contract. This is not a Gate 2 completion or production approval.

## Branch and source boundary

- Repository: `hunarjabbar/Exchi` (public).
- Base: `release/gate-1`.
- Working branch: `feature/gate-2-identity-kyc`.
- Gate 1 source and historical migrations are additive-only inputs. Do not rewrite or squash migrations 001–007.
- All payment, trade-credit, accounting-posting, payout, FX-execution, binding-order and regulated-goods gates remain false.

## Verified baseline from Gate 1 source

- The API already has Iraqi `+9647xxxxxxxxx` phone validation, OTP challenge request/verify, WhatsApp template delivery and Twilio SMS delivery adapters.
- OTP issuance is serialized in PostgreSQL and has global, per-phone cooldown and hourly limits. OTP digests use HMAC; session tokens are stored as SHA-256 digests.
- Staff audiences require RFC 6238 TOTP. TOTP replay is prevented with `identity.principal.last_totp_step`.
- Login creates and rotates audience-specific sessions; the session resolver checks membership, role assignment, audience permission, tenant and scope.
- The schema already includes `identity.device`, `identity.session`, `organizations.retailer_profile`, `compliance.kyc_case`, `compliance.document`, `compliance.kyc_decision`, and `audit.event`.
- Retailer entitlement is fail-closed: exact-tier pricing is withheld unless both the latest KYC case and retailer profile are approved.
- The existing HTTP API has no complete retailer KYC submission/review endpoints, no complete shop-profile/location onboarding workflow, and no complete device/session management API. Existing OTP login returns a bearer token; refresh-token rotation and device-bound session lifecycle are not yet a complete Gate 2 workflow.
- The existing event model has before/after JSON columns, but a complete append-only audit writer, tamper-evident chain verification, and end-to-end coverage for every sensitive action have not been certified.

## Implementation sequence

### 2.1 Authentication and session lifecycle

1. Keep the current WhatsApp-first OTP and SMS fallback adapters; do not return OTP values outside the explicit local-only development fixture.
2. Add a refresh-token family model with one-time rotation, reuse detection, revocation propagation, absolute and idle expiry, and hashed-at-rest secrets. Access tokens remain short-lived and audience-bound.
3. Bind sessions to registered device records where supported. Add list/revoke-current/revoke-other-device endpoints; revoke all sessions on credential or account compromise.
4. Require fresh TOTP/AAL2 for staff-sensitive actions, with server-side replay prevention and step-up age checks. Retailer OTP must not satisfy staff MFA.
5. Add integration tests for concurrent OTP issuance, concurrent refresh reuse, token rotation, logout, audience isolation, device revocation and TOTP replay.

### 2.2 Retailer onboarding and KYC

1. Implement the four explicit states: account/phone verified; business profile completed; documents uploaded and submitted; command-centre review and decision.
2. Collect legal/trading name, shop type, governorate, district/landmark, verified map coordinates, owner/contact data and declared business details. Validate Iraqi governorate membership against the reference table.
3. Implement private object storage upload intents. The browser must upload directly to a private bucket using short-lived scoped URLs; the API stores object key, SHA-256, MIME, byte count, capture metadata and scan state. Never store public object URLs or image bytes in PostgreSQL.
4. Require malware scanning and quarantine before a document is reviewable. Reject MIME/extension mismatch, oversized objects, invalid hashes, and unapproved document kinds.
5. Implement draft save, submit, return-for-correction, resubmit, approve and reject transitions. Decisions require an authorized command-centre reviewer, reason, evidence, timestamp and immutable decision record.
6. Keep all pricing, credit and order-acceptance entitlements fail-closed until the final KYC state and buyer tier are approved. No preview path may reveal prices or regulated catalog items.

### 2.3 RBAC and audit

1. Enforce role and permission checks in API/database boundaries, not only navigation or UI. Keep the audience allowlist and tenant/scope RLS as independent controls.
2. Verify Super Admin, CEO/GM, Finance Controller, Warehouse Manager, Logistics Dispatcher, Regional Sales Manager, Mandoob, Retailer and Supplier role matrices. A role assignment must be tenant-bound, scope-bound, time-bounded where applicable, and audited.
3. Implement an append-only audit writer for authentication, profile changes, document actions, KYC transitions, role/permission changes, session/device actions and sensitive command-centre operations.
4. Capture actor, tenant, scope, correlation ID, action, resource ID, before/after JSON and server timestamp. Add a cryptographic hash chain and a verifier; deny application-role UPDATE/DELETE on audit rows.
5. Do not log OTP values, access/refresh tokens, TOTP secrets, identity-document contents, signed upload URLs or payment secrets.

## Gate 2 acceptance criteria

- All tests run against a fresh disposable PostgreSQL instance and the exact PR head.
- Phone normalization and OTP tests cover Iraqi formats, invalid prefixes, consent, expiry, attempt limits, global/per-phone rate limits, provider failure, WhatsApp-to-SMS fallback and duplicate requests.
- Refresh rotation is atomic under concurrency; reuse of an already-rotated refresh token revokes the token family and emits an audit event.
- Device and session revocation take effect on the next request; sessions cannot cross audience, tenant or scope.
- TOTP replay, stale step-up, missing MFA and cross-role access all fail closed.
- Retailer onboarding covers each state transition, invalid governorate/coordinates, missing documents, malicious/unscanned uploads, expired documents, reviewer separation, return-for-correction, resubmission and final approval/rejection.
- No retailer can access tier prices, credit or order acceptance before approved KYC and explicit entitlement policy.
- Every sensitive mutation emits exactly one audit event with before/after evidence; application runtime cannot update or delete audit records; hash-chain verification detects tampering.
- All historical migrations remain unchanged; new schema changes are additive and repeatable.
- Existing financial/regulatory execution gates remain disabled in all test fixtures and runtime health output.

## Explicit non-goals for Gate 2

- No live payment-provider integration, wallet settlement, credit drawdown, accounting posting, payout, FX execution, binding order acceptance or regulated-goods enablement.
- No production deployment or production credentials.
- No weakening of tenant RLS, staff TOTP, audience separation or least-privilege database roles to make tests pass.

## Current Gate 2 blockers

The source baseline is not yet a complete Gate 2 implementation. The implementation must add the missing refresh-token family and device lifecycle, full retailer KYC/profile/document workflows, role-matrix acceptance, and tamper-evident append-only audit behavior. This contract alone is not evidence that those capabilities are implemented.
