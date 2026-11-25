// Công dụng tệp: Ca làm và đổi ca.

import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/firebase_collections.dart';
import '../models/user_role.dart';
import 'auth_service.dart';
import 'firestore_demo_guard.dart';

/// Mẫu lịch dùng khoá transaction shift_schedule/{uid} để tránh tạo ca trùng.
class ShiftService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  /// Lấy danh sách ca làm.
  Future<List<Map<String, dynamic>>> getShifts() async {
    final session = await _authService.getCurrentSession();
    final q = _db.collection(FirebaseCollections.shifts);
    final rows = session?.role == UserRole.staff
        ? await q
              .where('staffUid', isEqualTo: _authService.currentUid)
              .limit(200)
              .get()
        : await q.limit(200).get();
    return rows.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  }

  /// Xác định khoảng thời gian liên quan đến ca làm.
  void _window(DateTime start, DateTime end) {
    if (!end.isAfter(start) ||
        !start.isAfter(DateTime.now()) ||
        end.difference(start) > const Duration(hours: 12) ||
        end.difference(start) < const Duration(minutes: 30)) {
      throw StateError('Ca phải ở tương lai, dài từ 30 phút tới 12 giờ.');
    }
  }

  DocumentReference<Map<String, dynamic>> _lock(String uid) =>
      _db.collection('shift_schedule').doc(uid);

  /// Tạo danh sách các khoảng thời gian từ dữ liệu ca làm.
  List<Map<String, dynamic>> _slots(Map<String, dynamic>? data) {
    return (data?['slots'] as List<dynamic>? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  /// Thêm ca làm.
  List<Map<String, dynamic>> _addSlot(
    List<Map<String, dynamic>> slots,
    String id,
    DateTime start,
    DateTime end,
    int maxHours,
  ) {
    final a = start.millisecondsSinceEpoch;
    final b = end.millisecondsSinceEpoch;
    for (final slot in slots) {
      final from = FirestoreDemoGuard.integer(slot['startMs']);
      final to = FirestoreDemoGuard.integer(slot['endMs']);
      if (a < to && b > from)
        throw StateError('Ca bị trùng với lịch đã đăng ký.');
    }
    // Rolling 7-day window prevents obvious overbooking.
    var minutes = b - a;
    for (final slot in slots) {
      final from = FirestoreDemoGuard.integer(slot['startMs']);
      final to = FirestoreDemoGuard.integer(slot['endMs']);
      if ((from - a).abs() < const Duration(days: 7).inMilliseconds)
        minutes += to - from;
    }
    if (minutes > maxHours * 3600000)
      throw StateError('Vượt giới hạn giờ làm trong 7 ngày.');
    return [
      ...slots,
      {'id': id, 'startMs': a, 'endMs': b},
    ];
  }

  /// Đăng ký ca làm.
  Future<void> registerShift(DateTime start, DateTime end) async {
    final uid = await FirestoreDemoGuard.requireRole(['staff']);
    _window(start, end);
    final ref = _db.collection(FirebaseCollections.shifts).doc();
    await _db.runTransaction((tx) async {
      final profile = await tx.get(
        _db.collection(FirebaseCollections.users).doc(uid),
      );
      final lockRef = _lock(uid);
      final lockDoc = await tx.get(lockRef);
      final setting = await tx.get(
        _db.collection(FirebaseCollections.settings).doc('store'),
      );
      final max = FirestoreDemoGuard.integer(setting.data()?['maxWeeklyHours']);
      final slots = _addSlot(
        _slots(lockDoc.data()),
        ref.id,
        start,
        end,
        max > 0 ? max : 48,
      );
      tx.set(lockRef, {'slots': slots});
      tx.set(ref, {
        'staffUid': uid,
        'staffName': profile.data()?['displayName'] ?? uid,
        'startAt': Timestamp.fromDate(start),
        'endAt': Timestamp.fromDate(end),
        'status': 'Pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Xem xét và xử lý ca làm.
  Future<void> reviewShift(String id, bool approved) async {
    final uid = await FirestoreDemoGuard.requireRole(['manager', 'admin']);
    final ref = _db.collection(FirebaseCollections.shifts).doc(id);
    await _db.runTransaction((tx) async {
      final shift = await tx.get(ref);
      if (!shift.exists || shift.data()?['status'] != 'Pending')
        throw StateError('Ca không còn chờ duyệt.');
      final staffUid = shift.data()!['staffUid'].toString();
      final lockRef = _lock(staffUid);
      final lock = await tx.get(lockRef);
      final slots = _slots(lock.data());
      if (!approved) {
        tx.set(lockRef, {'slots': slots.where((e) => e['id'] != id).toList()});
      } else {
        if (FirestoreDemoGuard.date(
                  shift.data()?['startAt'],
                )?.isBefore(DateTime.now()) !=
                false ||
            !slots.any((e) => e['id'] == id))
          throw StateError('Ca đã bắt đầu hoặc thiếu khoá lịch.');
      }
      tx.update(ref, {
        'status': approved ? 'Approved' : 'Rejected',
        'reviewedBy': uid,
        'reviewedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Lấy các phiếu đổi ca.
  Future<List<Map<String, dynamic>>> getShiftSwaps() async {
    final session = await _authService.getCurrentSession();
    final collection = _db.collection(FirebaseCollections.shiftSwaps);
    if (session?.role != UserRole.staff) {
      final docs = await collection.limit(200).get();
      return docs.docs.map((d) => {'id': d.id, ...d.data()}).toList();
    }
    final sent = await collection
        .where('requesterUid', isEqualTo: _authService.currentUid)
        .get();
    final received = await collection
        .where('replacementUid', isEqualTo: _authService.currentUid)
        .get();
    final merged = <String, Map<String, dynamic>>{};
    for (final row in [...sent.docs, ...received.docs]) {
      merged[row.id] = {'id': row.id, ...row.data()};
    }
    return merged.values.toList();
  }

  /// Gửi yêu cầu phiếu đổi ca.
  Future<void> requestShiftSwap(
    String shiftId,
    String replacementUid,
    String reason,
  ) async {
    final uid = await FirestoreDemoGuard.requireRole(['staff']);
    if (replacementUid == uid || reason.trim().isEmpty)
      throw StateError('Người nhận/lý do không hợp lệ.');
    final ref = _db.collection(FirebaseCollections.shiftSwaps).doc(shiftId);
    await _db.runTransaction((tx) async {
      final shift = await tx.get(
        _db.collection(FirebaseCollections.shifts).doc(shiftId),
      );
      final replacement = await tx.get(
        _db.collection(FirebaseCollections.users).doc(replacementUid),
      );
      final existing = await tx.get(ref);
      if (existing.exists ||
          shift.data()?['staffUid'] != uid ||
          shift.data()?['status'] != 'Approved' ||
          FirestoreDemoGuard.date(
                shift.data()?['startAt'],
              )?.isBefore(DateTime.now()) !=
              false ||
          replacement.data()?['active'] == false ||
          replacement.data()?['role'] != 'staff') {
        throw StateError('Không thể gửi yêu cầu đổi ca.');
      }
      tx.set(ref, {
        'shiftId': shiftId,
        'requesterUid': uid,
        'replacementUid': replacementUid,
        'reason': reason.trim(),
        'status': 'PENDING',
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Hủy phiếu đổi ca.
  Future<void> cancelShiftSwap(String id) async {
    final uid = await FirestoreDemoGuard.requireRole(['staff']);
    await _updateSwap(
      id,
      uid,
      ['PENDING', 'ACCEPTED_BY_STAFF'],
      'CANCELLED',
      'cancelledAt',
    );
  }

  /// Chấp nhận phiếu đổi ca.
  Future<void> acceptShiftSwap(String id) async {
    final uid = await FirestoreDemoGuard.requireRole(['staff']);
    final ref = _db.collection(FirebaseCollections.shiftSwaps).doc(id);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (snap.data()?['status'] != 'PENDING' ||
          snap.data()?['replacementUid'] != uid) {
        throw StateError('Phiếu không còn chờ xác nhận.');
      }
      tx.update(ref, {
        'status': 'ACCEPTED_BY_STAFF',
        'acceptedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Cập nhật phiếu đổi ca.
  Future<void> _updateSwap(
    String id,
    String uid,
    List<String> from,
    String to,
    String field,
  ) async {
    final ref = _db.collection(FirebaseCollections.shiftSwaps).doc(id);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!from.contains(snap.data()?['status']) ||
          snap.data()?['requesterUid'] != uid) {
        throw StateError('Không được hủy phiếu này.');
      }
      tx.update(ref, {'status': to, field: FieldValue.serverTimestamp()});
    });
  }

  /// Xem xét và xử lý phiếu đổi ca.
  Future<void> reviewShiftSwap(String id, bool approved) async {
    final uid = await FirestoreDemoGuard.requireRole(['admin', 'manager']);
    final swapRef = _db.collection(FirebaseCollections.shiftSwaps).doc(id);
    final shiftRef = _db.collection(FirebaseCollections.shifts).doc(id);
    await _db.runTransaction((tx) async {
      final swap = await tx.get(swapRef);
      final shift = await tx.get(shiftRef);
      if (swap.data()?['status'] != 'ACCEPTED_BY_STAFF' ||
          shift.data()?['status'] != 'Approved' ||
          shift.data()?['staffUid'] != swap.data()?['requesterUid']) {
        throw StateError('Phiếu không hợp lệ.');
      }
      final from = swap.data()!['requesterUid'].toString();
      final to = swap.data()!['replacementUid'].toString();
      final oldLockRef = _lock(from);
      final newLockRef = _lock(to);
      final oldLock = await tx.get(oldLockRef);
      final newLock = await tx.get(newLockRef);
      final config = await tx.get(
        _db.collection(FirebaseCollections.settings).doc('store'),
      );
      if (approved) {
        final start = FirestoreDemoGuard.date(shift.data()?['startAt']);
        final end = FirestoreDemoGuard.date(shift.data()?['endAt']);
        if (start == null || end == null || !start.isAfter(DateTime.now())) {
          throw StateError('Ca đã bắt đầu.');
        }
        final max = FirestoreDemoGuard.integer(
          config.data()?['maxWeeklyHours'],
        );
        final next = _addSlot(
          _slots(newLock.data()),
          id,
          start,
          end,
          max > 0 ? max : 48,
        );
        tx.set(newLockRef, {'slots': next});
        tx.set(oldLockRef, {
          'slots': _slots(oldLock.data()).where((e) => e['id'] != id).toList(),
        });
        tx.update(shiftRef, {
          'staffUid': to,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      tx.update(swapRef, {
        'status': approved ? 'APPROVED' : 'REJECTED',
        'reviewedBy': uid,
        'reviewedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Phân công ca làm.
  Future<void> assignShift(
    String staffUid,
    DateTime start,
    DateTime end,
  ) async {
    await FirestoreDemoGuard.requireRole(['manager', 'admin']);
    _window(start, end);
    final ref = _db.collection(FirebaseCollections.shifts).doc();
    await _db.runTransaction((tx) async {
      final user = await tx.get(
        _db.collection(FirebaseCollections.users).doc(staffUid),
      );
      final lockRef = _lock(staffUid);
      final lock = await tx.get(lockRef);
      final config = await tx.get(
        _db.collection(FirebaseCollections.settings).doc('store'),
      );
      if (user.data()?['role'] != 'staff' || user.data()?['active'] == false)
        throw StateError('Staff không hoạt động.');
      final max = FirestoreDemoGuard.integer(config.data()?['maxWeeklyHours']);
      final slots = _addSlot(
        _slots(lock.data()),
        ref.id,
        start,
        end,
        max > 0 ? max : 48,
      );
      tx.set(lockRef, {'slots': slots});
      tx.set(ref, {
        'staffUid': staffUid,
        'staffName': user.data()?['displayName'] ?? staffUid,
        'startAt': Timestamp.fromDate(start),
        'endAt': Timestamp.fromDate(end),
        'status': 'Approved',
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
