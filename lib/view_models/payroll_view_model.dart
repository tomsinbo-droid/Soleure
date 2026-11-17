import '../services/staff_service.dart';
import '../services/payroll_service.dart';
import '../services/attendance_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/payroll_entry.dart';
import '../models/user_role.dart';

class PayrollViewModel {
  final StaffService _staffService = StaffService();
  final AttendanceService _attendanceService = AttendanceService();
  final PayrollService _payrollService = PayrollService();

  Future<List<Map<String, String>>> getStaffNames() =>
      _staffService.getStaffNames();

  List<PayrollEntry> entries = [];
  List<Map<String, dynamic>> pendingAdjustments = [];
  bool periodClosed = false;
  String selectedPeriod =
      '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}';
  String get period => selectedPeriod;
  void selectPeriod(String value) => selectedPeriod = value;

  Future<void> load() async {
    final profiles = await _staffService.getStaffProfiles();
    final attendance = await _attendanceService.getAttendance();
    final commissions = await _payrollService.getCommissionEvents();
    final adjustments = await _payrollService.getPayrollAdjustments();
    pendingAdjustments = adjustments
        .where((a) => a['status'] == 'Pending' && a['period'] == period)
        .toList();
    final closed = await _payrollService.getPayrollPeriods();
    periodClosed = closed.any((p) => p['id'] == period);
    final parts = period.split('-');
    final month = DateTime(int.parse(parts[0]), int.parse(parts[1]));
    bool thisMonth(DateTime? value) =>
        value != null && value.year == month.year && value.month == month.month;
    entries = profiles.where((u) => u.role == UserRole.staff).map((u) {
      final uid = u.uid;
      double hours = 0;
      double wage = 0;
      for (final a in attendance.where((a) => a['staffUid'] == uid)) {
        final start = (a['checkInAt'] as Timestamp?)?.toDate();
        final end = (a['checkOutAt'] as Timestamp?)?.toDate();
        if (start != null &&
            end != null &&
            end.isAfter(start) &&
            thisMonth(start) &&
            a['workStatus'] == 'Approved') {
          final minutes = (a['approvedMinutes'] as num? ?? 0).toDouble();
          hours += minutes / 60.0;
          final approvedRate =
              (a['hourlyRateAtApproval'] as num? ?? u.hourlyRate).toDouble();
          wage += (minutes / 60 * approvedRate).round();
        }
      }
      double commission = 0;
      for (final e in commissions.where((e) => e['staffUid'] == uid)) {
        if (!thisMonth((e['createdAt'] as Timestamp?)?.toDate())) continue;
        commission += (e['amount'] as num? ?? 0).toDouble();
      }
      final adj = adjustments
          .where(
            (e) =>
                e['staffUid'] == uid &&
                e['period'] == period &&
                e['status'] == 'Approved',
          )
          .fold<double>(
            0,
            (sum, e) => sum + (e['amount'] as num? ?? 0).toDouble(),
          );
      return PayrollEntry(
        staffName: u.displayName.isEmpty ? uid : u.displayName,
        hours: hours,
        hourlyPay: u.hourlyRate,
        wageOverride: wage,
        commission: commission,
        adjustments: adj,
        status: periodClosed ? 'Chốt nội bộ' : 'Dự kiến',
      );
    }).toList();
    if (periodClosed) {
      final snapshots = await _payrollService.getPayrollRecords();
      entries = snapshots
          .where((row) => row['period'] == period)
          .map(
            (row) => PayrollEntry(
              staffName:
                  row['displayName']?.toString() ?? row['uid'].toString(),
              hours: (row['approvedMinutes'] as num? ?? 0).toDouble() / 60,
              hourlyPay: (row['hourlyRate'] as num? ?? 0).toDouble(),
              wageOverride: (row['wage'] as num? ?? 0).toDouble(),
              commission: (row['commission'] as num? ?? 0).toDouble(),
              adjustments: (row['adjustment'] as num? ?? 0).toDouble(),
              status: 'Chốt nội bộ',
            ),
          )
          .toList();
    }
  }

  Future<void> createAdjustment(
    String staffUid,
    int amount,
    String reason,
  ) async {
    await _payrollService.addPayrollAdjustment(
      staffUid,
      period,
      amount,
      reason,
    );
    await load();
  }

  Future<void> reviewAdjustment(String id, bool approved) async {
    await _payrollService.reviewPayrollAdjustment(id, approved);
    await load();
  }

  Future<void> closePeriod() async {
    await _payrollService.closePayrollPeriod(period);
    await load();
  }
}
