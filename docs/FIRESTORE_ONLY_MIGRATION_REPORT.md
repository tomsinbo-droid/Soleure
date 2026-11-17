# Soléure — Firestore-only migration (Intern Demo)

## Scope / status

Starting point: `app_Project.zip` provided by user on 2026-11-15.
Flutter runtime refactored away from `cloud_functions` and `firebase_storage` imports.
Architecture remains View → ViewModel → domain Service → Firestore/Auth.
Existing Views, themes and assets were **not edited**.

The application is **not production-ready** and has not been compiled or tested
with a running Firebase Emulator in this environment. It must not be presented
as a verified, deployed end-to-end application.

## Changes made

- `inventory_service.dart`: direct receipt/stocktake creation and serial/condition records; emulator-only transaction approval, moving average cost, movement ledger.
- `supplier_service.dart`: Firestore CRUD with Manager/Admin permissions.
- `damage_service.dart`: direct reports and images; emulator-only damage approval/stock adjustment.
- `hold_service.dart`: create/cancel/expire-on-read transactions with reserved stock and inventory units.
- `pos_service.dart`: cash demo transaction, draft, Hold→Sold, demo KPI and customer totals. Repeated order request IDs are detected.
- `payment_service.dart`: pending QR reservation; emulator-only simulation of QR confirmation, cancellation and expiry. **Not bank verification**.
- `return_service.dart`: request and settlement with stock/KPI ledgers, cash demo only for refunds; no real bank refunds.
- `shift_service.dart`: registration/review/assign/swap using per-staff schedule lock docs to reduce concurrent overlaps.
- `attendance_service.dart`: check-in/out against approved shift, review, correction, reject stale attendance.
- `payroll_service.dart`: adjustment, approval and internal-only snapshot.
- `staff_service.dart`: privileged Auth account creation/role/disable operations cannot run from Flutter; uses offline Admin SDK instead (intentionally blocked in UI).
- `product_service.dart`: new products must start stock/cost 0 and be stocked by receipt; avoids overwrite on create.
- `customer_service.dart`: no overwrite on create, Staff customer history limited to own orders to respect production Rules.
- `main.dart`: opt-in connection to local Auth + Firestore emulator.

## Rules / safety

- `firestore.rules` is a conservative shared-project policy. POS, Hold, stock approvals, payroll ledger and other sensitive client writes are rejected on online Firebase.
- `firestore.emulator.rules` is for local isolated testing ONLY. It intentionally allows some client-driven ledger transitions. **Never deploy this file to production/shared DEV.**
- `firebase.emulator.json` points to local-only emulator rules. The normal `firebase.json` never deploys Functions or Storage.
- High-risk Flutter methods call `FirestoreDemoGuard.requireEmulator(...)` before any write. Server Rules, not the client flag, control permission on real Firebase.
- No real QR/bank verification, real salary payment, tax filing or refunds.
- No scheduler in Spark: expired Hold/QR rows are released on next relevant UI read or explicit method call; do not promise automatic background cleanup.

## Known limitations and blockers

1. Requires Flutter SDK (project declares Dart `^3.10.7`) and Firebase CLI for build/runtime QA.
2. Client-side financial/inventory invariants cannot be made tamper-proof using transaction plus Firestore Rules alone; restricted to emulator.
3. `StaffService.createAccount` and `updateAccount` intentionally show a clear Admin SDK requirement rather than silently claiming success. The existing UI remains unchanged.
4. Lương đóng kỳ is illustrative; because source selection happens before the Firestore transaction, concurrent creation of previously unseen rows is not fully serialized.
5. Shift lock docs protect shifts created by new code; pre-existing shift data must be backfilled into `shift_schedule` (seed script now handles its own sample shifts).
6. No production-compatible bank reconciliation; QR code data is demo-only.
7. Refunds for QR payment are blocked; only emulator cash refund is simulated.
8. Demo report queries have a 1500-document cap; not a scalable production reporting system.
9. New product inventory starts at zero; use approved purchase receipt to increase it.
10. `firestore.emulator.rules` needs explicit Emulator rules tests before accepting correctness, and client flows need real Flutter tests.

## Credentials security

The uploaded ZIP contained an **Admin SDK private-key JSON file** and a
`functions/scripts/.seed-credentials...json` file. Both are EXCLUDED from the
new deliverable. Treat the Admin SDK key as potentially exposed: revoke/rotate
it with the relevant Google Cloud/Firebase administrator, and reset any demo
credentials that may have been distributed. Never commit private credentials.

## Runtime audit

No `FirebaseCallable`, `httpsCallable`, `FirebaseFunctions`, `cloud_functions`
or `firebase_storage` dependencies remain in `lib/` or `pubspec.yaml`.
Legacy server implementation was not included in the new ZIP, and is recoverable
from the user's original archive if rollback is required.
