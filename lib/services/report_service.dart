// Công dụng tệp: Báo cáo.

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/finance_report.dart';

/// Báo cáo được tính tại máy khách cho cấu hình Firebase Spark
/// (Auth + Firestore, không dùng Cloud Functions).
class ReportService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Lấy báo cáo.
  Future<FinanceReport> getReport(DateTime from, DateTime to) async {
    final start = _day(from);
    final end = _day(to);
    if (end.isBefore(start) || end.difference(start).inDays > 92) {
      throw StateError('Chỉ xem tối đa 93 ngày mỗi lần.');
    }

    final endExclusive = end.add(const Duration(days: 1));
    final results = await Future.wait([
      _rows('orders'),
      _rows('return_requests'),
      _rows('expenses'),
      _rows('commission_events'),
      _rows('damage_reports'),
      _rows('payroll_records'),
    ]);
    final orders = results[0];
    final returns = results[1];
    final expenses = results[2];
    final commissions = results[3];
    final damages = results[4];
    final payroll = results[5];

    /// Kiểm tra thời điểm có nằm trong khoảng báo cáo hay không.
    bool within(dynamic value) {
      final date = _date(value);
      return date != null &&
          !date.isBefore(start) &&
          date.isBefore(endExclusive);
    }

    /// Kiểm tra trạng thái thanh toán của giao dịch.
    bool isPaid(Map<String, dynamic> row) =>
        row['status'] == 'Paid' || row['status'] == 'Refunded';
    /// Lấy thời điểm thanh toán dùng để tính báo cáo.
    dynamic paidAt(Map<String, dynamic> order) => order['paymentMethod'] == 'qr'
        ? order['paidAt']
        : order['paidAt'] ?? order['createdAt'];
    /// Lấy số tiền từ dữ liệu đầu vào.
    double amount(Map<String, dynamic> row, String key) =>
        (row[key] as num? ?? 0).toDouble();

    final sales = orders
        .where((row) => isPaid(row) && within(paidAt(row)))
        .toList();
    final completedReturns = returns
        .where(
          (row) => row['status'] == 'Completed' && within(row['reviewedAt']),
        )
        .toList();
    final expenseRows = expenses
        .where((row) => within(row['createdAt']))
        .toList();
    final commissionRows = commissions
        .where((row) => within(row['createdAt']))
        .toList();
    final damageRows = damages
        .where(
          (row) => row['status'] == 'Approved' && within(row['reviewedAt']),
        )
        .toList();

    final salesTotal = _sum(sales, 'total');
    final refunds = _sum(completedReturns, 'refundAmount');
    final cost =
        _sum(sales, 'totalCost') - _sum(completedReturns, 'costReversed');
    final kpi = _sum(commissionRows, 'amount');
    final loss = _sum(damageRows, 'actualLoss');
    final tax = _sum(
      expenseRows.where((row) => row['category'] == 'Thuế'),
      'amount',
    );
    final operating = _sum(
      expenseRows.where((row) => row['category'] != 'Thuế'),
      'amount',
    );
    final wages = payroll
        .where((row) => row['status'] == 'ClosedInternal')
        .fold<double>(
          0,
          (sum, row) => sum + amount(row, 'wage') + amount(row, 'adjustment'),
        );

    final days = <Map<String, dynamic>>[];
    for (
      var date = start;
      date.isBefore(endExclusive);
      date = date.add(const Duration(days: 1))
    ) {
      final dateKey = _dateKey(date);
      final daySales = sales
          .where((row) => _dateKey(_date(paidAt(row))!) == dateKey)
          .fold<double>(0, (sum, row) => sum + amount(row, 'total'));
      final dayRefunds = completedReturns
          .where((row) => _dateKey(_date(row['reviewedAt'])!) == dateKey)
          .fold<double>(0, (sum, row) => sum + amount(row, 'refundAmount'));
      days.add({
        'date': dateKey,
        'sales': daySales,
        'refunds': dayRefunds,
        'net': daySales - dayRefunds,
      });
    }

    return FinanceReport({
      'start': _dateKey(start),
      'end': _dateKey(end),
      'sales': salesTotal,
      'refunds': refunds,
      'revenue': salesTotal - refunds,
      'cost': cost,
      'kpi': kpi,
      'loss': loss,
      'tax': tax,
      'operating': operating,
      'wages': wages,
      'netEstimate':
          salesTotal - refunds - cost - kpi - loss - tax - operating - wages,
      'orderCount': sales.length,
      'refundCount': completedReturns.length,
      'payrollRecordCount': payroll.length,
      'days': days,
      'staff': const <Map<String, dynamic>>[],
      'expenseItems': expenseRows,
      'note': 'Ước tính từ dữ liệu Firestore (Firebase Spark).',
    });
  }

  /// Chuyển dữ liệu danh sách thành các dòng để xử lý hoặc hiển thị.
  Future<List<Map<String, dynamic>>> _rows(String collection) async {
    final snapshot = await _db.collection(collection).limit(1501).get();
    if (snapshot.size > 1500) {
      throw StateError('Báo cáo quá 1500 bản ghi ở $collection.');
    }
    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  /// Tính tổng giá trị của các dòng dữ liệu.
  static double _sum(Iterable<Map<String, dynamic>> rows, String key) =>
      rows.fold(0, (sum, row) => sum + (row[key] as num? ?? 0));

  /// Tạo giá trị ngày dùng để nhóm dữ liệu báo cáo.
  static DateTime _day(DateTime value) =>
      DateTime.utc(value.year, value.month, value.day);

  /// Chuyển hoặc định dạng giá trị ngày phục vụ xử lý.
  static DateTime? _date(dynamic value) {
    if (value is Timestamp)
      return _day(value.toDate().toUtc().add(const Duration(hours: 7)));
    if (value is DateTime)
      return _day(value.toUtc().add(const Duration(hours: 7)));
    return null;
  }

  /// Tạo khóa ngày phục vụ so sánh hoặc tra cứu.
  static String _dateKey(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
}
