// Công dụng tệp: Khai báo tên các collection Firestore.

/// Tên collection Firestore dùng chung cho tất cả service.
/// Thống nhất với Firestore Rules và Firebase Admin seed scripts.
abstract final class FirebaseCollections {
  static const users = 'users';
  static const products = 'products';
  static const customers = 'customers';
  static const orderDrafts = 'order_drafts';
  static const holds = 'holds';
  static const orders = 'orders';
  static const commissions = 'commission_events';
  static const returns = 'return_requests';
  static const damages = 'damage_reports';
  static const staffRequests = 'staff_requests';
  static const shifts = 'shifts';
  static const shiftSchedule = 'shift_schedule';
  static const shiftSwaps = 'shift_swaps';
  static const attendance = 'attendance';
  static const attendanceCorrections = 'attendance_corrections';
  static const promotions = 'promotion_proposals';
  static const settings = 'system_settings';
  static const stockMovements = 'stock_movements';
  static const productChanges = 'product_changes';
  static const payrollAdjustments = 'payroll_adjustments';
  static const payrollPeriods = 'payroll_periods';
  static const payrollRecords = 'payroll_records';
  static const expenses = 'expenses';
  static const notifications = 'notifications';
  static const suppliers = 'suppliers';
  static const receipts = 'purchase_receipts';
  static const stocktakes = 'stocktakes';
  static const units = 'inventory_units';
  static const storeSettingsDocument = 'store';
}
