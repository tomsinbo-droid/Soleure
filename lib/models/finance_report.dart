// Dữ liệu đã được backend tính: View chỉ hiển thị, không tự cộng bill.
class FinanceReport {
  FinanceReport(this.data);
  final Map<String, dynamic> data;
  double value(String key) => (data[key] as num? ?? 0).toDouble();
  int get orderCount => (data['orderCount'] as num? ?? 0).toInt();
  String get start => data['start']?.toString() ?? '';
  String get end => data['end']?.toString() ?? '';
  String get note => data['note']?.toString() ?? '';
  List<Map<String, dynamic>> rows(String key) => (data[key] as List? ?? [])
      .map((x) => Map<String, dynamic>.from(x as Map))
      .toList();
}
