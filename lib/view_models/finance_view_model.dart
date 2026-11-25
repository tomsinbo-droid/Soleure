// Công dụng tệp: Tài chính và chi phí.

import '../models/finance_report.dart';
import '../services/finance_service.dart';
import '../services/report_service.dart';

class FinanceViewModel {
  final ReportService _reportService = ReportService();
  final FinanceService _financeService = FinanceService();
  FinanceReport? report;

  DateTime from = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime to = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );

  double get grossRevenue => report?.value('revenue') ?? 0;
  double get totalExpenses =>
      (report?.value('operating') ?? 0) +
      (report?.value('cost') ?? 0) +
      (report?.value('loss') ?? 0) +
      (report?.value('kpi') ?? 0) +
      (report?.value('wages') ?? 0);
  double get tax => report?.value('tax') ?? 0;
  double get netProfit => report?.value('netEstimate') ?? 0;
  List<(String, String, double)> get expenses => report == null
      ? []
      : [
          ('Giá vốn hàng đã bán (sau hoàn)', 'Biến phí', report!.value('cost')),
          ('Hao hụt đã duyệt', 'Biến phí', report!.value('loss')),
          ('Hoa hồng KPI (có điều chỉnh)', 'Biến phí', report!.value('kpi')),
          ('Lương kỳ đã chốt (nội bộ)', 'Định phí', report!.value('wages')),
          for (final e in report!.rows('expenseItems'))
            (
              e['name']?.toString() ?? '',
              e['category']?.toString() ?? '',
              (e['amount'] as num? ?? 0).toDouble(),
            ),
        ];
  /// Tải dữ liệu tài chính và chi phí và cập nhật trạng thái tương ứng.
  Future<void> load() async {
    report = await _reportService.getReport(from, to);
  }

  /// Thiết lập khoảng thời gian.
  Future<void> setRange(DateTime start, DateTime end) async {
    from = start;
    to = end;
    await load();
  }

  /// Tạo khoản chi.
  Future<void> createExpense(String name, String category, int amount) async {
    await _financeService.addExpense(name, category, amount);
    await load();
  }

  // UTF-8 CSV; escape formulas to keep spreadsheet imports safe.
  /// Chuyển dữ liệu hiện tại thành nội dung CSV.
  String toCsv() {
    final current = report;
    if (current == null) return '';
    /// Chuyển giá trị thành ô dữ liệu CSV.
    String cell(Object? v) {
      var text = v?.toString() ?? '';
      if (v is String && RegExp(r'^\s*[=+@\-\t\r]').hasMatch(text))
        text = "'${text}";
      final escaped = text.replaceAll('"', '""');
      return '"$escaped"';
    }

    /// Tạo một dòng dữ liệu CSV.
    String line(List<Object?> fields) => fields.map(cell).join(',');
    final rows = <String>[
      line([
        'Soléure — Báo cáo tài chính tạm tính',
        current.start,
        current.end,
      ]),
      line(['Chỉ số', 'VND']),
      for (final pair in [
        ['Doanh thu bán', 'sales'],
        ['Hoàn tiền', 'refunds'],
        ['Doanh thu thuần', 'revenue'],
        ['Giá vốn', 'cost'],
        ['Hoa hồng', 'kpi'],
        ['Hao hụt', 'loss'],
        ['Chi phí vận hành', 'operating'],
        ['Thuế đã ghi', 'tax'],
        ['Lương snapshot', 'wages'],
        ['Lợi nhuận ước tính', 'netEstimate'],
      ])
        line([pair[0], current.value(pair[1])]),
      '',
      line(['Ngày', 'Bán hàng', 'Hoàn trả', 'Doanh thu thuần']),
      for (final r in current.rows('days'))
        line([r['date'], r['sales'], r['refunds'], r['net']]),
      '',
      line(['Nhân viên', 'Số bill', 'Doanh số thuần', 'Hoa hồng']),
      for (final r in current.rows('staff'))
        line([r['name'], r['orders'], r['revenue'], r['kpi']]),
      '',
      line(['Lưu ý', current.note]),
    ];
    return rows.join('\r\n');
  }
}
