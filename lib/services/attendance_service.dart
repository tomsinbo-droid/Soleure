// Công dụng tệp: Chấm công và điều chỉnh giờ làm.

import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/firebase_collections.dart';
import '../models/user_role.dart';
import 'auth_service.dart';
import 'firestore_demo_guard.dart';

class AttendanceService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  /// Lấy dữ liệu chấm công.
  Future<List<Map<String, dynamic>>> getAttendance() async {
    final uid = await FirestoreDemoGuard.requireRole([
      'admin',
      'manager',
      'staff',
    ]);
    final session = await _authService.getCurrentSession();
    final q = _db.collection(FirebaseCollections.attendance);
    final snap = session?.role == UserRole.staff
        ? await q.where('staffUid', isEqualTo: uid).limit(200).get()
        : await q.limit(200).get();
    final rows = snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
    final staffUids = rows
        .map((row) => row['staffUid']?.toString() ?? '')
        .where((staffUid) => staffUid.isNotEmpty)
        .toSet();
    final names = <String, String>{};
    await Future.wait(
      staffUids.map((staffUid) async {
        try {
          final profile = await _db
              .collection(FirebaseCollections.users)
              .doc(staffUid)
              .get();
          final name = profile.data()?['displayName']?.toString().trim();
          if (name != null && name.isNotEmpty) names[staffUid] = name;
        } on FirebaseException catch (error) {
          if (error.code != 'permission-denied') rethrow;
        }
      }),
    );
    for (final row in rows) {
      final staffUid = row['staffUid']?.toString() ?? '';
      final savedName = row['staffName']?.toString().trim();
      row['staffName'] =
          names[staffUid] ??
          (savedName != null && savedName.isNotEmpty ? savedName : null) ??
          (staffUid.isEmpty ? '-' : staffUid);
    }
    return rows;
  }

  /// Thực hiện check-in hoặc check-out cho ca làm hợp lệ.
  Future<void> checkAttendance(bool checkIn) async {
    final uid = await FirestoreDemoGuard.requireRole(['staff']);
    final now = DateTime.now();
    if (checkIn) {
      final shifts = await _db
          .collection(FirebaseCollections.shifts)
          .where('staffUid', isEqualTo: uid)
          .limit(200)
          .get();
      final candidates = shifts.docs.where((doc) {
        final start = FirestoreDemoGuard.date(doc.data()['startAt']);
        final end = FirestoreDemoGuard.date(doc.data()['endAt']);
        return doc.data()['status'] == 'Approved' &&
            start != null &&
            end != null &&
            now.isAfter(start.subtract(const Duration(minutes: 30))) &&
            now.isBefore(end);
      }).toList();
      if (candidates.length != 1)
        throw StateError('Cần đúng một ca Approved đang trong giờ check-in.');
      final shift = candidates.single;
      final ref = _db.collection(FirebaseCollections.attendance).doc(shift.id);
      await _db.runTransaction((tx) async {
        final existing = await tx.get(ref);
        final shiftCheck = await tx.get(shift.reference);
        final profile = await tx.get(
          _db.collection(FirebaseCollections.users).doc(uid),
        );
        if (existing.exists ||
            shiftCheck.data()?['status'] != 'Approved' ||
            shiftCheck.data()?['staffUid'] != uid)
          throw StateError('Bạn đã chấm công ca này.');
        tx.set(ref, {
          'shiftId': shift.id,
          'staffUid': uid,
          'checkInAt': FieldValue.serverTimestamp(),
          'checkOutAt': null,
          'workStatus': 'Pending',
          'approvedMinutes': 0,
          'hourlyRateAtCheckIn': profile.data()?['hourlyRate'] ?? 0,
          'createdAt': FieldValue.serverTimestamp(),
        });
      });
      return;
    }
    final rows = await _db
        .collection(FirebaseCollections.attendance)
        .where('staffUid', isEqualTo: uid)
        .limit(200)
        .get();
    final open = rows.docs
        .where((r) => r.data()['checkOutAt'] == null)
        .toList();
    if (open.length != 1)
      throw StateError('Không có đúng một ca đang mở để check-out.');
    final ref = open.single.reference;
    await _db.runTransaction((tx) async {
      final row = await tx.get(ref);
      final checkInTime = FirestoreDemoGuard.date(row.data()?['checkInAt']);
      if (row.data()?['staffUid'] != uid ||
          row.data()?['checkOutAt'] != null ||
          checkInTime == null ||
          now.difference(checkInTime) > const Duration(hours: 18)) {
        throw StateError('Ca đã đóng hoặc quá 18 giờ.');
      }
      tx.update(ref, {'checkOutAt': FieldValue.serverTimestamp()});
    });
  }

  /// Từ chối hoặc xử lý ca chấm công quá hạn.
  Future<void> rejectStaleAttendance(String id) async {
    final uid = await FirestoreDemoGuard.requireRole(['manager', 'admin']);
    final ref = _db.collection(FirebaseCollections.attendance).doc(id);
    await _db.runTransaction((tx) async {
      final row = await tx.get(ref);
      final data = row.data();
      final start = FirestoreDemoGuard.date(data?['checkInAt']);
      if (data == null ||
          data['workStatus'] != 'Pending' ||
          data['checkOutAt'] != null ||
          start == null ||
          DateTime.now().difference(start) < const Duration(hours: 18)) {
        throw StateError('Chỉ xử lý ca quá hạn chưa check-out.');
      }
      final shift = await tx.get(
        _db
            .collection(FirebaseCollections.shifts)
            .doc(data['shiftId'].toString()),
      );
      final end = FirestoreDemoGuard.date(shift.data()?['endAt']);
      if (end == null || end.isAfter(DateTime.now()))
        throw StateError('Ca chưa kết thúc.');
      tx.update(ref, {
        'checkOutAt': Timestamp.fromDate(end),
        'workStatus': 'Rejected',
        'approvedMinutes': 0,
        'resolutionReason': 'Quên check-out',
        'resolvedBy': uid,
        'resolvedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Xem xét và xử lý dữ liệu chấm công.
  Future<void> reviewAttendance(String id, bool approved) async {
    final uid = await FirestoreDemoGuard.requireRole(['manager', 'admin']);
    final ref = _db.collection(FirebaseCollections.attendance).doc(id);
    await _db.runTransaction((tx) async {
      final row = await tx.get(ref);
      final correction = await tx.get(
        _db.collection(FirebaseCollections.attendanceCorrections).doc(id),
      );
      final data = row.data();
      final start = FirestoreDemoGuard.date(data?['checkInAt']);
      final end = FirestoreDemoGuard.date(data?['checkOutAt']);
      if (data == null ||
          data['workStatus'] != 'Pending' ||
          start == null ||
          end == null ||
          correction.data()?['status'] == 'Pending')
        throw StateError('Chưa đủ điều kiện duyệt công.');
      final minutes = end.difference(start).inMinutes;
      if (minutes < 1 || minutes > 18 * 60)
        throw StateError('Giờ công ngoài phạm vi hợp lệ.');
      final profile = await tx.get(
        _db
            .collection(FirebaseCollections.users)
            .doc(data['staffUid'].toString()),
      );
      if (profile.data()?['role'] != 'staff')
        throw StateError('Hồ sơ Staff không hợp lệ.');
      tx.update(ref, {
        'workStatus': approved ? 'Approved' : 'Rejected',
        'approvedMinutes': approved ? minutes : 0,
        'hourlyRateAtApproval': approved
            ? (data['hourlyRateAtCheckIn'] ??
                  profile.data()?['hourlyRate'] ??
                  0)
            : 0,
        'reviewedBy': uid,
        'reviewedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Gửi yêu cầu chỉnh công.
  Future<void> requestAttendanceCorrection(
    String id,
    DateTime start,
    DateTime end,
    String reason,
  ) async {
    final uid = await FirestoreDemoGuard.requireRole(['staff']);
    if (reason.trim().isEmpty ||
        !end.isAfter(start) ||
        end.difference(start) > const Duration(hours: 18))
      throw StateError('Dữ liệu chỉnh công không hợp lệ.');
    final ref = _db
        .collection(FirebaseCollections.attendanceCorrections)
        .doc(id);
    await _db.runTransaction((tx) async {
      final attendance = await tx.get(
        _db.collection(FirebaseCollections.attendance).doc(id),
      );
      final prev = await tx.get(ref);
      if (prev.exists ||
          attendance.data()?['staffUid'] != uid ||
          attendance.data()?['workStatus'] != 'Pending' ||
          attendance.data()?['checkOutAt'] == null) {
        throw StateError('Không thể xin sửa công này.');
      }
      tx.set(ref, {
        'attendanceId': id,
        'staffUid': uid,
        'reason': reason.trim(),
        'startAt': Timestamp.fromDate(start),
        'endAt': Timestamp.fromDate(end),
        'status': 'Pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Lấy các yêu cầu chỉnh công.
  Future<List<Map<String, dynamic>>> getAttendanceCorrections() async {
    final session = await _authService.getCurrentSession();
    final q = _db.collection(FirebaseCollections.attendanceCorrections);
    final docs = session?.role == UserRole.staff
        ? await q
              .where('staffUid', isEqualTo: _authService.currentUid)
              .limit(200)
              .get()
        : await q.limit(200).get();
    return docs.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  }

  /// Xem xét và xử lý yêu cầu chỉnh công.
  Future<void> reviewAttendanceCorrection(String id, bool approved) async {
    final uid = await FirestoreDemoGuard.requireRole(['manager', 'admin']);
    final ref = _db
        .collection(FirebaseCollections.attendanceCorrections)
        .doc(id);
    await _db.runTransaction((tx) async {
      final correction = await tx.get(ref);
      final attendanceRef = _db
          .collection(FirebaseCollections.attendance)
          .doc(id);
      final attendance = await tx.get(attendanceRef);
      if (correction.data()?['status'] != 'Pending' ||
          attendance.data()?['workStatus'] != 'Pending')
        throw StateError('Phiếu đã xử lý.');
      if (approved) {
        tx.update(attendanceRef, {
          'checkInAt': correction.data()?['startAt'],
          'checkOutAt': correction.data()?['endAt'],
          'correctedBy': uid,
        });
      }
      tx.update(ref, {
        'status': approved ? 'Approved' : 'Rejected',
        'reviewedBy': uid,
        'reviewedAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
