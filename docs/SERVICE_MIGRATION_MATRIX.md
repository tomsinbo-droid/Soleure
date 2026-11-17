# Service Migration Matrix — 2026-11-15

Status terms:
- `FIRESTORE`: direct Firestore CRUD (local validation + Rules).
- `EMULATOR_ONLY`: Firestore transaction implemented but not secure on shared projects.
- `BLOCKED_ADMIN_SDK`: cannot be performed using Flutter Auth privileges.
- `NOT_E2E_TESTED`: runtime and Rules tests still required before acceptance.

| Existing Flutter service | Original Cloud Functions actions | Target | Status |
|---|---|---|---|
| InventoryService | createPurchaseReceipt, reviewPurchaseReceipt, createStocktake, reviewStocktake, registerInventoryUnit | purchase_receipts, stocktakes, products, stock_movements, inventory_units | FIRESTORE creation; EMULATOR_ONLY approvals |
| SupplierService | saveSupplier, deactivateSupplier | suppliers | FIRESTORE |
| DamageService | reviewDamage | damage_reports, products, stock_movements | EMULATOR_ONLY approval |
| HoldService | createHold, cancelHold | holds, products, inventory_units | EMULATOR_ONLY |
| PosService | completeCashSale | orders, products, customers, commission_events | EMULATOR_ONLY |
| PaymentService | createQrPayment, confirmQrPayment | orders, products, inventory_units, commission_events | EMULATOR_ONLY; bank proof is simulated only |
| ReturnService | submitReturnRequest, settleReturn | return_requests, orders, products, commission_events, stock_movements | EMULATOR_ONLY; real bank refund BLOCKED |
| ShiftService | registerShiftV2, reviewShift, requestShiftSwapV2, cancelShiftSwapV2, acceptShiftSwap, reviewShiftSwap, assignShift | shifts, shift_swaps, shift_schedule | EMULATOR_ONLY |
| AttendanceService | checkAttendance, rejectStaleAttendance, reviewAttendance, requestAttendanceCorrection, reviewAttendanceCorrection | attendance, attendance_corrections | EMULATOR_ONLY |
| PayrollService | addPayrollAdjustment, reviewPayrollAdjustment, closePayrollPeriod | payroll_adjustments, payroll_periods, payroll_records | EMULATOR_ONLY; not payroll disbursement |
| StaffService | adminCreateAccount, adminUpdateAccount | Firebase Auth + users | BLOCKED_ADMIN_SDK (intentionally unavailable to client) |
| CustomerService | getCustomerHistory | orders | FIRESTORE, staff scoped to own sales |
| ReportService | getFinanceReportV2 | orders, returns, expenses, KPI, damage, payroll | FIRESTORE+Dart aggregation |
| NotificationService | markNotificationRead | notifications | FIRESTORE |
| ProductService | prior callable product CRUD | products | FIRESTORE |

**Runtime Cloud Functions callers remaining: 0.**

**Actual Flutter compile / Firebase Emulator E2E: NOT_E2E_TESTED.**
Changing client code alone does not make privileged operations secure.
