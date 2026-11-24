import '../services/attendance_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceViewModel {
  final AttendanceService _attendanceService = AttendanceService();

  bool checkedIn = false;
  String checkInTime = '-';
  List<(String, String, String, String, String)> history = [];
  List<Map<String, dynamic>> attendanceRows = [];
  List<Map<String, dynamic>> corrections = [];

  String _clock(DateTime? d) => d == null
      ? '-'
      : '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  static String formatDate(DateTime? date) => date == null
      ? '-'
      : '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  static String formatDateTime(DateTime? date) => date == null
      ? '-'
      : '${formatDate(date)} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

  Future<void> load() async {
    final rows = await _attendanceService.getAttendance();
    rows.sort(
      (a, b) =>
          ((b['checkInAt'] as Timestamp?)?.toDate() ??
                  DateTime.fromMillisecondsSinceEpoch(0))
              .compareTo(
                (a['checkInAt'] as Timestamp?)?.toDate() ??
                    DateTime.fromMillisecondsSinceEpoch(0),
              ),
    );
    attendanceRows = rows;
    corrections = await _attendanceService.getAttendanceCorrections();
    history = rows.map<(String, String, String, String, String)>((r) {
      final start = (r['checkInAt'] as Timestamp?)?.toDate();
      final end = (r['checkOutAt'] as Timestamp?)?.toDate();
      final minutes = start == null || end == null
          ? 0
          : end.difference(start).inMinutes;
      return (
        formatDate(start),
        formatDateTime(start),
        formatDateTime(end),
        end == null ? '-' : '${minutes ~/ 60}h ${minutes % 60}m',
        end == null ? 'Đang làm' : (r['workStatus']?.toString() ?? 'Pending'),
      );
    }).toList();
    final open = rows.where((r) => r['checkOutAt'] == null).toList();
    checkedIn = open.isNotEmpty;
    if (checkedIn)
      checkInTime = _clock((open.first['checkInAt'] as Timestamp?)?.toDate());
  }

  Future<void> rejectStale(String id) async {
    await _attendanceService.rejectStaleAttendance(id);
    await load();
  }

  bool isStale(Map<String, dynamic> row) {
    final start = (row['checkInAt'] as Timestamp?)?.toDate();
    return row['checkOutAt'] == null &&
        start != null &&
        DateTime.now().difference(start).inHours >= 18;
  }

  Future<void> review(String id, bool approved) async {
    await _attendanceService.reviewAttendance(id, approved);
    await load();
  }

  Future<void> requestCorrection(
    String id,
    DateTime start,
    DateTime end,
    String reason,
  ) async {
    await _attendanceService.requestAttendanceCorrection(
      id,
      start,
      end,
      reason,
    );
    await load();
  }

  Future<void> reviewCorrection(String id, bool approved) async {
    await _attendanceService.reviewAttendanceCorrection(id, approved);
    await load();
  }

  Future<void> toggle() async {
    await _attendanceService.checkAttendance(!checkedIn);
    await load();
  }
}
