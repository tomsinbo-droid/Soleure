// Công dụng tệp: Bảng lương.

import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/firebase_collections.dart';
import '../models/user_role.dart';
import 'auth_service.dart';
import 'firestore_demo_guard.dart';

/// Bảng lương minh họa, không thực hiện chi lương hoặc quyết toán thuế.
class PayrollService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  /// Chuyển dữ liệu danh sách thành các dòng để xử lý hoặc hiển thị.
  Future<List<Map<String, dynamic>>> _rows(
    String name, {
    String? field,
    String? value,
  }) async {
    final session = await _authService.getCurrentSession();
    final q = _db.collection(name);
    final docs = session?.role == UserRole.staff && field != null
        ? await q
              .where(field, isEqualTo: _authService.currentUid)
              .limit(200)
              .get()
        : await q.limit(200).get();
    return docs.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  }

  /// Lấy các điều chỉnh lương.
  Future<List<Map<String, dynamic>>> getPayrollAdjustments() =>
      _rows(FirebaseCollections.payrollAdjustments, field: 'staffUid');
  /// Lấy các bản ghi lương.
  Future<List<Map<String, dynamic>>> getPayrollRecords() =>
      _rows(FirebaseCollections.payrollRecords, field: 'uid');
  /// Lấy các kỳ lương.
  Future<List<Map<String, dynamic>>> getPayrollPeriods() =>
      _rows(FirebaseCollections.payrollPeriods);
  /// Lấy các sự kiện KPI.
  Future<List<Map<String, dynamic>>> getCommissionEvents() =>
      _rows(FirebaseCollections.commissions, field: 'staffUid');

  /// Thêm điều chỉnh lương.
  Future<void> addPayrollAdjustment(
    String staffUid,
    String period,
    int amount,
    String reason,
  ) async {
    final uid = await FirestoreDemoGuard.requireRole(['manager', 'admin']);
    if (!RegExp(r'^\d{4}-(0[1-9]|1[0-2])$').hasMatch(period) ||
        amount.abs() > 100000000 ||
        reason.trim().isEmpty) {
      throw StateError('Kỳ lương hoặc khoản điều chỉnh không hợp lệ.');
    }
    final profile = await _db
        .collection(FirebaseCollections.users)
        .doc(staffUid)
        .get();
    final periodDoc = await _db
        .collection(FirebaseCollections.payrollPeriods)
        .doc(period)
        .get();
    if (profile.data()?['role'] != 'staff' || periodDoc.exists)
      throw StateError('Nhân viên/kỳ lương không hợp lệ.');
    await _db.collection(FirebaseCollections.payrollAdjustments).add({
      'staffUid': staffUid,
      'period': period,
      'amount': amount,
      'reason': reason.trim(),
      'status': 'Pending',
      'createdBy': uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Xem xét và xử lý điều chỉnh lương.
  Future<void> reviewPayrollAdjustment(String id, bool approved) async {
    final uid = await FirestoreDemoGuard.requireRole(['admin']);
    final ref = _db.collection(FirebaseCollections.payrollAdjustments).doc(id);
    await _db.runTransaction((tx) async {
      final row = await tx.get(ref);
      if (row.data()?['status'] != 'Pending')
        throw StateError('Không còn phiếu chờ duyệt.');
      final period = await tx.get(
        _db
            .collection(FirebaseCollections.payrollPeriods)
            .doc(row.data()!['period'].toString()),
      );
      if (period.exists) throw StateError('Kỳ lương đã chốt.');
      tx.update(ref, {
        'status': approved ? 'Approved' : 'Rejected',
        'reviewedBy': uid,
        'reviewedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Xác định kỳ tháng theo múi giờ Việt Nam.
  String _vietnamMonth(dynamic time) {
    final d = FirestoreDemoGuard.date(time);
    if (d == null) return '';
    final v = d.toUtc().add(const Duration(hours: 7));
    return '${v.year}-${v.month.toString().padLeft(2, '0')}';
  }

  /// Chốt hoặc đóng kỳ lương.
  Future<void> closePayrollPeriod(String period) async {
    final uid = await FirestoreDemoGuard.requireRole(['admin']);
    final current = _vietnamMonth(Timestamp.now());
    if (!RegExp(r'^\d{4}-(0[1-9]|1[0-2])$').hasMatch(period) ||
        period.compareTo(current) >= 0) {
      throw StateError('Chỉ chốt kỳ tháng đã kết thúc (YYYY-MM).');
    }
    // Giới hạn số bản ghi. Nếu dữ liệu lớn hơn thì không chốt bản tạm thiếu.
    /// Kiểm tra dữ liệu nguồn có vượt giới hạn truy vấn của báo cáo hay không.
    Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> limited(
      String collection,
    ) async {
      final result = await _db.collection(collection).limit(301).get();
      if (result.docs.length > 300)
        throw StateError('$collection vượt giới hạn 300 bản ghi.');
      return result.docs;
    }

    final profiles = await _db
        .collection(FirebaseCollections.users)
        .where('role', isEqualTo: 'staff')
        .limit(151)
        .get();
    if (profiles.docs.length > 150)
      throw StateError('Quá nhiều nhân viên để chốt kỳ lương.');
    final attendance = await limited(FirebaseCollections.attendance);
    final commissions = await limited(FirebaseCollections.commissions);
    final adjustments = await limited(FirebaseCollections.payrollAdjustments);
    final corrections = await limited(
      FirebaseCollections.attendanceCorrections,
    );
    if (adjustments.any(
          (d) =>
              d.data()['period'] == period && d.data()['status'] == 'Pending',
        ) ||
        corrections.any(
          (d) =>
              d.data()['status'] == 'Pending' &&
              _vietnamMonth(d.data()['startAt']) == period,
        )) {
      throw StateError('Còn yêu cầu điều chỉnh chưa được duyệt.');
    }
    final relevantAttendance = attendance
        .where((d) => _vietnamMonth(d.data()['checkInAt']) == period)
        .toList();
    if (relevantAttendance.any(
      (d) =>
          !['Approved', 'Rejected'].contains(d.data()['workStatus']) ||
          d.data()['checkOutAt'] == null,
    ))
      throw StateError('Còn giờ công chưa duyệt.');
    final ref = _db.collection(FirebaseCollections.payrollPeriods).doc(period);
    await _db.runTransaction((tx) async {
      final previous = await tx.get(ref);
      if (previous.exists) throw StateError('Kỳ lương đã chốt.');
      // Read each source document inside the transaction so a concurrent
      // modification invalidates the snapshot and the transaction retries.
      final profileRows = <DocumentSnapshot<Map<String, dynamic>>>[];
      for (final d in profiles.docs) profileRows.add(await tx.get(d.reference));
      final attendRows = <DocumentSnapshot<Map<String, dynamic>>>[];
      for (final d in relevantAttendance)
        attendRows.add(await tx.get(d.reference));
      final commissionRows = <DocumentSnapshot<Map<String, dynamic>>>[];
      for (final d in commissions)
        commissionRows.add(await tx.get(d.reference));
      final adjustRows = <DocumentSnapshot<Map<String, dynamic>>>[];
      for (final d in adjustments) adjustRows.add(await tx.get(d.reference));
      for (final profile in profileRows) {
        if (!profile.exists)
          throw StateError('Hồ sơ nhân viên thay đổi trong lúc chốt.');
        final staffUid = profile.id;
        final minutes = attendRows
            .where(
              (row) =>
                  row.data()?['staffUid'] == staffUid &&
                  row.data()?['workStatus'] == 'Approved',
            )
            .fold<int>(
              0,
              (sum, row) =>
                  sum +
                  FirestoreDemoGuard.integer(row.data()?['approvedMinutes']),
            );
        final wage = attendRows
            .where(
              (row) =>
                  row.data()?['staffUid'] == staffUid &&
                  row.data()?['workStatus'] == 'Approved',
            )
            .fold<int>(
              0,
              (sum, row) =>
                  sum +
                  (FirestoreDemoGuard.integer(row.data()?['approvedMinutes']) /
                          60 *
                          FirestoreDemoGuard.integer(
                            row.data()?['hourlyRateAtApproval'] ??
                                profile.data()?['hourlyRate'],
                          ))
                      .round(),
            );
        final kpi = commissionRows
            .where(
              (row) =>
                  row.data()?['staffUid'] == staffUid &&
                  _vietnamMonth(row.data()?['createdAt']) == period,
            )
            .fold<int>(
              0,
              (sum, row) =>
                  sum + FirestoreDemoGuard.integer(row.data()?['amount']),
            );
        final adjustmentsTotal = adjustRows
            .where(
              (row) =>
                  row.data()?['staffUid'] == staffUid &&
                  row.data()?['period'] == period &&
                  row.data()?['status'] == 'Approved',
            )
            .fold<int>(
              0,
              (sum, row) =>
                  sum + FirestoreDemoGuard.integer(row.data()?['amount']),
            );
        tx.set(
          _db
              .collection(FirebaseCollections.payrollRecords)
              .doc('${period}_$staffUid'),
          {
            'uid': staffUid,
            'period': period,
            'displayName': profile.data()?['displayName'] ?? staffUid,
            'approvedMinutes': minutes,
            'hourlyRate': profile.data()?['hourlyRate'] ?? 0,
            'wage': wage,
            'commission': kpi,
            'adjustment': adjustmentsTotal,
            'expectedTotal': wage + kpi + adjustmentsTotal,
            'status': 'ClosedInternal',
          },
        );
      }
      tx.set(ref, {
        'period': period,
        'status': 'ClosedInternal',
        'closedBy': uid,
        'createdAt': FieldValue.serverTimestamp(),
        'count': profileRows.length,
        'taxFinalized': false,
        'paymentFinalized': false,
      });
    });
  }
}
