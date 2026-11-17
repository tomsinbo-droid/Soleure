import '../services/shift_service.dart';
import '../services/auth_service.dart';
import '../services/staff_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/shift.dart';

class ShiftViewModel {
  final AuthService _authService = AuthService();
  final StaffService _staffService = StaffService();
  final ShiftService _shiftService = ShiftService();

  Future<List<Map<String, String>>> getStaffNames() =>
      _staffService.getStaffNames();
  String? get currentUid => _authService.currentUid;

  List<Shift> shifts = [];
  List<(String, String, String, String, String)> swaps = [];
  List<Map<String, dynamic>> swapDocs = [];

  String _date(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';
  String _clock(DateTime time) =>
      '${time.hour.toString().padLeft(2, '0')}:'
      '${time.minute.toString().padLeft(2, '0')}';

  Future<void> load() async {
    final rows = await _shiftService.getShifts();
    shifts = rows.map((data) {
      final start = (data['startAt'] as Timestamp?)?.toDate() ?? DateTime.now();
      final end = (data['endAt'] as Timestamp?)?.toDate() ?? start;
      return Shift(
        id: data['id']?.toString() ?? '',
        date: _date(start),
        time: '${_clock(start)} - ${_clock(end)}',
        staffName: data['staffName']?.toString() ?? '-',
        status: data['status']?.toString() ?? '-',
      );
    }).toList();
    swapDocs = await _shiftService.getShiftSwaps();
    swaps = swapDocs
        .map<(String, String, String, String, String)>(
          (doc) => (
            doc['id']?.toString() ?? '-',
            doc['requesterUid']?.toString() ?? '-',
            doc['shiftId']?.toString() ?? '-',
            doc['replacementUid']?.toString() ?? '-',
            doc['status']?.toString() ?? '-',
          ),
        )
        .toList();
  }

  Future<void> register(DateTime start, DateTime end) async {
    await _shiftService.registerShift(start, end);
    await load();
  }

  Future<void> assign(String uid, DateTime start, DateTime end) async {
    await _shiftService.assignShift(uid, start, end);
    await load();
  }

  Future<void> review(String id, bool approved) async {
    await _shiftService.reviewShift(id, approved);
    await load();
  }

  Future<void> requestSwap(String id, String uid, String reason) async {
    await _shiftService.requestShiftSwap(id, uid, reason);
    await load();
  }

  Future<void> cancelSwap(String id) async {
    await _shiftService.cancelShiftSwap(id);
    await load();
  }

  Future<void> acceptSwap(String id) async {
    await _shiftService.acceptShiftSwap(id);
    await load();
  }

  Future<void> reviewSwap(String id, bool approved) async {
    await _shiftService.reviewShiftSwap(id, approved);
    await load();
  }
}
