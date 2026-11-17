import 'package:flutter_test/flutter_test.dart';
import 'package:app_project/models/payroll_entry.dart';

void main() {
  test('Lương dự kiến dùng số giờ và lương giờ nếu chưa có snapshot', () {
    final entry = PayrollEntry(
      staffName: 'Staff', hours: 3, hourlyPay: 30000,
      commission: 10000, adjustments: -2000, status: 'Dự kiến',
    );
    expect(entry.wage, 90000);
    expect(entry.total, 98000);
  });

  test('Lương chốt sử dụng wage snapshot, không tính lại từ rate mới', () {
    final entry = PayrollEntry(
      staffName: 'Staff', hours: 3, hourlyPay: 30000,
      commission: 10000, adjustments: -2000,
      wageOverride: 105000, status: 'Chốt nội bộ',
    );
    expect(entry.wage, 105000);
    expect(entry.total, 113000);
  });
}
