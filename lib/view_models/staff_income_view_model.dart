// Công dụng tệp: Thu nhập cá nhân.

import '../core/constants/app_defaults.dart';
import '../services/staff_service.dart';
import '../services/settings_service.dart';
import '../services/payroll_service.dart';
import '../services/auth_service.dart';
import '../services/attendance_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StaffIncomeViewModel {
  final AuthService _authService = AuthService();
  final StaffService _staffService = StaffService();
  final AttendanceService _attendanceService = AttendanceService();
  final PayrollService _payrollService = PayrollService();
  final SettingsService _settingsService = SettingsService();

  double hours = 0;
  double _approvedWage = 0;
  double hourlyRate = 0;
  double eligibleSales = 0;
  bool estimatedEligibleSales = false;
  double commissionRate = AppDefaults.commissionRate;
  double revokedCommission = 0;
  double earnedCommission = 0;
  double adjustments = 0;

  double get hourlyIncome => _approvedWage;
  double get commission => earnedCommission;
  double get expectedIncome =>
      hourlyIncome + commission - revokedCommission + adjustments;

  /// Tải dữ liệu thu nhập cá nhân và cập nhật trạng thái tương ứng.
  Future<void> load() async {
    final uid = _authService.currentUid;
    hours = 0;
    _approvedWage = 0;
    hourlyRate = 0;
    eligibleSales = 0;
    estimatedEligibleSales = false;
    revokedCommission = 0;
    adjustments = 0;
    earnedCommission = 0;
    if (uid == null) return;
    final settings = await _settingsService.getSettings();
    commissionRate =
        (settings['commissionRate'] as num? ?? AppDefaults.commissionRate)
            .toDouble();
    final profile = await _staffService.getMyProfile();
    hourlyRate = (profile?['hourlyRate'] as num? ?? 0).toDouble();
    final attendance = await _attendanceService.getAttendance();
    final commissions = await _payrollService.getCommissionEvents();
    final month = DateTime.now();
    /// Kiểm tra hai thời điểm có cùng tháng hay không.
    bool sameMonth(DateTime d) =>
        d.year == month.year && d.month == month.month;
    for (final item in attendance) {
      if (item['staffUid'] != uid) continue;
      final start = (item['checkInAt'] as Timestamp?)?.toDate();
      final end = (item['checkOutAt'] as Timestamp?)?.toDate();
      if (start != null &&
          end != null &&
          sameMonth(start) &&
          end.isAfter(start) &&
          item['workStatus'] == 'Approved') {
        final minutes = (item['approvedMinutes'] as num? ?? 0).toDouble();
        hours += minutes / 60;
        _approvedWage +=
            (minutes /
                    60 *
                    (item['hourlyRateAtApproval'] as num? ?? hourlyRate)
                        .toDouble())
                .round();
      }
    }
    double earned = 0;
    double exactEligible = 0;
    bool missingEligible = false;
    for (final item in commissions) {
      if (item['staffUid'] != uid) continue;
      final created = (item['createdAt'] as Timestamp?)?.toDate();
      if (created == null || !sameMonth(created)) continue;
      final amount = (item['amount'] as num? ?? 0).toDouble();
      if (amount >= 0)
        earned += amount;
      else
        revokedCommission += -amount;
      if (item['eligibleSales'] is num) {
        exactEligible += (item['eligibleSales'] as num).toDouble();
      } else {
        missingEligible = true;
      }
    }
    // Với mức hoa hồng cố định 5%, suy ra net sales đủ điều kiện.
    // Chỉ dùng để hiển thị dự kiến, không chốt bảng lương.
    earnedCommission = earned;
    // Dữ liệu Sprint 5 có eligibleSales theo giao dịch (bao gồm đổi/trả).
    // Event cũ không có thì chỉ có thể hiển thị ước tính từ hoa hồng ròng.
    estimatedEligibleSales = missingEligible;
    eligibleSales = missingEligible
        ? (commissionRate == 0
              ? 0
              : (earned - revokedCommission) / commissionRate)
        : exactEligible;
    final adjustmentRows = await _payrollService.getPayrollAdjustments();
    final period = '${month.year}-${month.month.toString().padLeft(2, '0')}';
    for (final item in adjustmentRows) {
      if (item['staffUid'] == uid &&
          item['period'] == period &&
          item['status'] == 'Approved') {
        adjustments += (item['amount'] as num? ?? 0).toDouble();
      }
    }
  }
}
