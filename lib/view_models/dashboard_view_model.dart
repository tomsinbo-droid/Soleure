import '../services/staff_service.dart';
import '../models/finance_report.dart';
import '../services/report_service.dart';
import '../services/shift_service.dart';
import '../services/return_service.dart';
import '../services/promotion_service.dart';
import '../services/product_service.dart';
import '../services/pos_service.dart';
import '../services/payroll_service.dart';
import '../services/hold_service.dart';
import '../services/finance_service.dart';
import '../services/damage_service.dart';
import '../services/attendance_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/utils/money_formatter.dart';
import '../models/user_role.dart';

class DashboardMetricData {
  const DashboardMetricData(this.label, this.value, this.caption);
  final String label;
  final String value;
  final String caption;
}

class DashboardViewModel {
  final ProductService _productService = ProductService();
  final ReportService _reportService = ReportService();
  FinanceReport? monthlyReport;
  final DamageService _damageService = DamageService();
  final StaffService _staffService = StaffService();
  final PosService _posService = PosService();
  final HoldService _holdService = HoldService();
  final ReturnService _returnService = ReturnService();
  final ShiftService _shiftService = ShiftService();
  final AttendanceService _attendanceService = AttendanceService();
  final PayrollService _payrollService = PayrollService();
  final FinanceService _financeService = FinanceService();
  final PromotionService _promotionService = PromotionService();

  List<Map<String, dynamic>> orders = [];
  List<Map<String, dynamic>> returns = [];
  List<Map<String, dynamic>> damages = [];
  List<Map<String, dynamic>> holds = [];
  List<Map<String, dynamic>> shifts = [];
  List<Map<String, dynamic>> swaps = [];
  List<Map<String, dynamic>> promotions = [];
  List<Map<String, dynamic>> attendance = [];
  List<Map<String, dynamic>> commissions = [];
  List<Map<String, dynamic>> expenses = [];
  double staffHourlyRate = 0;
  int lowStock = 0;
  double inventoryValue = 0;
  List<double> weeklyRevenue = List.filled(7, 0);
  List<(String, String, String, String)> tasks = [];
  List<(String, String, String)> activities = [];

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
  bool _sameMonth(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month;
  DateTime? _created(Map<String, dynamic> item) =>
      (item['createdAt'] as Timestamp?)?.toDate();
  // QR chỉ được coi là doanh thu từ thời điểm đối soát đã xác nhận.
  DateTime? _saleDate(Map<String, dynamic> item) =>
      ((item['paidAt'] ?? item['createdAt']) as Timestamp?)?.toDate();
  bool _paid(Map<String, dynamic> item) =>
      ['Paid', 'Refunded'].contains(item['status']);
  double _amount(Map<String, dynamic> item, String key) =>
      (item[key] as num? ?? 0).toDouble();

  Future<void> load(UserRole role) async {
    final products = await _productService.getProducts();
    orders = await _posService.getOrders();
    returns = await _returnService.getReturns();
    holds = await _holdService.getHolds();
    shifts = await _shiftService.getShifts();
    commissions = await _payrollService.getCommissionEvents();
    attendance = await _attendanceService.getAttendance();
    if (role != UserRole.staff) {
      swaps = await _shiftService.getShiftSwaps();
      promotions = await _promotionService.getPromotions();
    }
    if (role == UserRole.admin) expenses = await _financeService.getExpenses();
    if (role != UserRole.staff)
      damages = await _damageService.getDamageReports();
    if (role == UserRole.staff) {
      final profile = await _staffService.getMyProfile();
      staffHourlyRate = (profile?['hourlyRate'] as num? ?? 0).toDouble();
    }

    lowStock = products.where((p) => p.stock <= 2).length;
    inventoryValue = products.fold<double>(
      0,
      (sum, p) => sum + p.cost * p.stock,
    );
    final today = DateTime.now();
    weeklyRevenue = List.filled(7, 0);
    for (final order in orders) {
      if (!_paid(order)) continue;
      final created = _saleDate(order);
      if (created == null) continue;
      for (var i = 0; i < 7; i++) {
        final day = today.subtract(Duration(days: 6 - i));
        if (_sameDay(created, day)) weeklyRevenue[i] += _amount(order, 'total');
      }
    }
    // Hoàn trả được tính vào ngày quản lý hoàn tất, không dồn ngược vào ngày bán.
    for (final result in returns.where((r) => r['status'] == 'Completed')) {
      final completed = result['reviewedAt'] is Timestamp
          ? (result['reviewedAt'] as Timestamp).toDate()
          : null;
      if (completed == null) continue;
      for (var i = 0; i < 7; i++) {
        final day = today.subtract(Duration(days: 6 - i));
        if (_sameDay(completed, day))
          weeklyRevenue[i] -= _amount(result, 'refundAmount');
      }
    }
    if (role == UserRole.admin) {
      // Admin: lấy doanh thu đã tổng hợp ở backend, không dựa vào 200 bill gần nhất.
      monthlyReport = await _reportService.getReport(
        DateTime(today.year, today.month, 1),
        today,
      );
      final week = await _reportService.getReport(
        today.subtract(const Duration(days: 6)),
        today,
      );
      weeklyRevenue = week
          .rows('days')
          .map((r) => (r['net'] as num? ?? 0).toDouble())
          .toList();
    }
    tasks = [];
    if (role == UserRole.staff) {
      tasks.add((
        'Ca đã đăng ký',
        '${shifts.length} ca trong danh sách',
        'Approved',
        'shifts',
      ));
      tasks.add((
        'Hold đang hoạt động',
        '${holds.where((h) => h['status'] == 'Active').length} phiếu',
        'Active',
        'holds',
      ));
      tasks.add((
        'Hoa hồng phát sinh',
        '${commissions.length} bản ghi',
        'Pending',
        'income',
      ));
    } else {
      final pendingSwap = swaps
          .where((s) => s['status'] == 'ACCEPTED_BY_STAFF')
          .length;
      final pendingPromo = promotions
          .where((s) => s['status'] == 'Pending')
          .length;
      tasks.add((
        'Phiếu đổi ca cần duyệt',
        '$pendingSwap phiếu',
        'Pending',
        'shifts',
      ));
      tasks.add((
        'Đề xuất khuyến mãi',
        '$pendingPromo phiếu',
        'Pending',
        'promotions',
      ));
      tasks.add((
        'Tồn kho thấp',
        '$lowStock SKU cần kiểm tra',
        'Pending',
        'inventory',
      ));
    }
    final recent =
        orders.where((o) => _paid(o) && _saleDate(o) != null).toList()
          ..sort((a, b) => _saleDate(b)!.compareTo(_saleDate(a)!));
    activities = recent.take(4).map<(String, String, String)>((o) {
      final time = _saleDate(o)!;
      final clock =
          '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      return (
        clock,
        'Bill ${o['id']} hoàn tất',
        '${o['staffName'] ?? '-'} · ${formatVnd(_amount(o, 'total'))}',
      );
    }).toList();
  }

  List<DashboardMetricData> metrics(UserRole role) {
    final today = DateTime.now();
    final todayOrders = orders
        .where(
          (o) =>
              _paid(o) &&
              _saleDate(o) != null &&
              _sameDay(_saleDate(o)!, today),
        )
        .toList();
    final todayRefunds = returns
        .where(
          (r) =>
              r['status'] == 'Completed' &&
              r['reviewedAt'] is Timestamp &&
              _sameDay((r['reviewedAt'] as Timestamp).toDate(), today),
        )
        .fold<double>(0, (sum, r) => sum + _amount(r, 'refundAmount'));
    final todayRevenue =
        todayOrders.fold<double>(0, (sum, o) => sum + _amount(o, 'total')) -
        todayRefunds;
    if (role == UserRole.admin && monthlyReport != null) {
      final month = monthlyReport!;
      return [
        DashboardMetricData(
          'Doanh thu tháng',
          formatVnd(month.value('revenue')),
          'Đã trừ khoản hoàn trong kỳ',
        ),
        DashboardMetricData(
          'Đơn hoàn tất',
          '${month.orderCount}',
          'Trong tháng',
        ),
        DashboardMetricData(
          'Giá trị tồn kho',
          formatVnd(inventoryValue),
          'Theo dữ liệu sản phẩm',
        ),
        DashboardMetricData(
          'Lợi nhuận tạm tính',
          formatVnd(month.value('netEstimate')),
          'Chỉ bao gồm lương kỳ đã chốt nội bộ',
        ),
      ];
    }
    if (role == UserRole.manager) {
      return [
        DashboardMetricData(
          'Nhân viên đang làm',
          '${attendance.where((a) => a['checkOutAt'] == null).length}',
          'Chưa check-out',
        ),
        DashboardMetricData(
          'Đơn hoàn tất',
          '${todayOrders.length}',
          'Bill Paid hôm nay',
        ),
        DashboardMetricData('SKU sắp hết', '$lowStock', 'Tồn khả dụng <= 2'),
        DashboardMetricData(
          'Yêu cầu chờ xử lý',
          '${swaps.where((s) => s['status'] == 'ACCEPTED_BY_STAFF').length + promotions.where((p) => p['status'] == 'Pending').length}',
          'Ca làm / khuyến mãi',
        ),
      ];
    }
    final personalSales = orders
        .where(
          (o) =>
              _paid(o) &&
              _saleDate(o) != null &&
              _sameMonth(_saleDate(o)!, today),
        )
        .fold<double>(
          0,
          (sum, o) => sum + _amount(o, 'total') - _amount(o, 'refundedTotal'),
        );
    final kpi = commissions
        .where((c) => _created(c) != null && _sameMonth(_created(c)!, today))
        .fold<double>(0, (sum, c) => sum + _amount(c, 'amount'));
    double hours = 0;
    for (final a in attendance) {
      final start = a['checkInAt'] is Timestamp
          ? (a['checkInAt'] as Timestamp).toDate()
          : null;
      final end = a['checkOutAt'] is Timestamp
          ? (a['checkOutAt'] as Timestamp).toDate()
          : null;
      if (start != null &&
          end != null &&
          _sameMonth(start, today) &&
          end.isAfter(start) &&
          a['workStatus'] == 'Approved') {
        hours += _amount(a, 'approvedMinutes') / 60;
      }
    }
    return [
      DashboardMetricData(
        'Doanh số cá nhân',
        formatVnd(personalSales),
        'Bill trong tháng',
      ),
      DashboardMetricData(
        'KPI phát sinh',
        formatVnd(kpi),
        'Theo giao dịch đã ghi',
      ),
      DashboardMetricData(
        'Giờ làm tháng này',
        '${hours.toStringAsFixed(1)}h',
        'Giờ làm đã duyệt',
      ),
      DashboardMetricData(
        'Thu nhập dự kiến',
        formatVnd(kpi + hours * staffHourlyRate),
        'Chưa duyệt công / điều chỉnh',
      ),
    ];
  }
}
