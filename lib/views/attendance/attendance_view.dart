import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/user_role.dart';
import '../../view_models/attendance_view_model.dart';
import '../../widgets/data_table_shell.dart';
import '../../widgets/page_header.dart';
import '../../widgets/section_card.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/app_loading_overlay.dart';

class AttendanceView extends StatefulWidget {
  const AttendanceView({super.key, required this.role});
  final UserRole role;

  @override
  State<AttendanceView> createState() => _AttendanceViewState();
}

class _AttendanceViewState extends State<AttendanceView> {
  final _vm = AttendanceViewModel();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      await AppLoading.run(_vm.load);
      if (mounted) setState(() {});
    } catch (error) {
      _message('Không tải được chấm công: $error');
    }
  }

  void _message(String text) {
    if (mounted)
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _toggle() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await AppLoading.run(_vm.toggle);
      if (mounted) setState(() {});
    } catch (error) {
      _message('Chấm công thất bại: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _review(String id, bool approved) async {
    try {
      await AppLoading.run(() => _vm.review(id, approved));
      if (mounted) setState(() {});
      _message('Đã xử lý duyệt giờ công.');
    } catch (error) {
      _message('Không duyệt được: $error');
    }
  }

  Future<void> _rejectStale(String id) async {
    try {
      await _vm.rejectStale(id);
      if (mounted) setState(() {});
      _message('Đã đóng ca lỗi, không tự tính lương.');
    } catch (error) {
      _message('Không xử lý được ca: $error');
    }
  }

  Future<void> _requestCorrection() async {
    final candidates = _vm.attendanceRows
        .where(
          (r) =>
              r['checkOutAt'] != null &&
              r['workStatus'] == 'Pending' &&
              !_vm.corrections.any((c) => c['attendanceId'] == r['id']),
        )
        .toList();
    if (candidates.isEmpty) {
      _message('Không có bản ghi còn chờ duyệt phù hợp.');
      return;
    }
    String id = candidates.first['id'].toString(),
        start = '',
        end = '',
        reason = '';
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialog) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          title: const Text('Yêu cầu chỉnh giờ công'),
          content: SizedBox(
            width: 380,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: id,
                  decoration: const InputDecoration(
                    labelText: 'Ngày đã chấm công',
                  ),
                  items: candidates
                      .map(
                        (r) => DropdownMenuItem<String>(
                          value: r['id'].toString(),
                          child: Text(
                            AttendanceViewModel.formatDateTime(
                              (r['checkInAt'] as Timestamp?)?.toDate(),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => update(() => id = v ?? id),
                ),
                TextField(
                  decoration: const InputDecoration(labelText: 'Giờ vào HH:mm'),
                  onChanged: (v) => start = v,
                ),
                TextField(
                  decoration: const InputDecoration(labelText: 'Giờ ra HH:mm'),
                  onChanged: (v) => end = v,
                ),
                TextField(
                  decoration: const InputDecoration(labelText: 'Lý do'),
                  onChanged: (v) => reason = v,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialog, false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialog, true),
              child: const Text('Gửi'),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    final row = candidates.firstWhere((r) => r['id'] == id);
    final checkInDate = (row['checkInAt'] as Timestamp?)?.toDate();
    if (checkInDate == null) {
      _message('Không tìm thấy ngày chấm công.');
      return;
    }
    final date =
        '${checkInDate.year.toString().padLeft(4, '0')}-'
        '${checkInDate.month.toString().padLeft(2, '0')}-'
        '${checkInDate.day.toString().padLeft(2, '0')}';
    final checkIn = DateTime.tryParse('${date}T${start.trim()}:00');
    final checkOut = DateTime.tryParse('${date}T${end.trim()}:00');
    if (checkIn == null || checkOut == null || !checkOut.isAfter(checkIn)) {
      _message('Giờ chưa hợp lệ.');
      return;
    }
    try {
      await _vm.requestCorrection(id, checkIn, checkOut, reason);
      if (mounted) setState(() {});
      _message('Đã gửi yêu cầu chỉnh công.');
    } catch (error) {
      _message('Không gửi được: $error');
    }
  }

  Future<void> _reviewCorrection() async {
    final pending = _vm.corrections
        .where((r) => r['status'] == 'Pending')
        .toList();
    if (pending.isEmpty) {
      _message('Không có phiếu chỉnh công chờ duyệt.');
      return;
    }
    final item = pending.first;
    final approved = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('Duyệt chỉnh giờ công'),
        content: Text(
          'Mã công: ${item['attendanceId']}\nNhân viên: ${item['staffUid']}\nLý do: ${item['reason']}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            child: const Text('Từ chối'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialog, true),
            child: const Text('Duyệt'),
          ),
        ],
      ),
    );
    if (approved == null) return;
    try {
      await _vm.reviewCorrection(item['id'].toString(), approved);
      if (mounted) setState(() {});
      _message('Đã xử lý yêu cầu chỉnh giờ.');
    } catch (error) {
      _message('Không duyệt được: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          title: 'Check-in / Check-out',
          actions: [
            if (widget.role == UserRole.staff)
              OutlinedButton.icon(
                onPressed: _requestCorrection,
                icon: const Icon(Icons.edit_calendar_outlined),
                label: const Text('Xin chỉnh công'),
              ),
            if (widget.role != UserRole.staff)
              OutlinedButton.icon(
                onPressed: _reviewCorrection,
                icon: const Icon(Icons.fact_check_outlined),
                label: const Text('Duyệt chỉnh công'),
              ),
          ],
          subtitle: widget.role == UserRole.staff
              ? 'Ghi nhận thời gian làm việc và xem lịch sử chấm công.'
              : 'Theo dõi giờ vào / ra, đi trễ, về sớm và dữ liệu đầu vào bảng lương.',
        ),
        const SizedBox(height: 18),
        if (widget.role == UserRole.staff) ...[
          SectionCard(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: (_vm.checkedIn ? AppColors.success : AppColors.blue)
                        .withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    _vm.checkedIn ? Icons.work_history_outlined : Icons.login,
                    size: 34,
                    color: _vm.checkedIn ? AppColors.success : AppColors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _vm.checkedIn
                            ? 'Bạn đang trong ca làm'
                            : 'Chưa check-in',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _vm.checkedIn
                            ? 'Check-in lúc ${_vm.checkInTime}'
                            : 'Bấm Check-in để ghi giờ vào thực tế',
                        style: const TextStyle(color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: _busy ? null : _toggle,
                  icon: Icon(_vm.checkedIn ? Icons.logout : Icons.login),
                  label: Text(_vm.checkedIn ? 'Check-out' : 'Check-in'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Lịch sử chấm công',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              DataTableShell(
                child: DataTable(
                  columns: [
                    const DataColumn(label: Text('Nhân viên')),
                    const DataColumn(label: Text('Ngày')),
                    DataColumn(label: Text('Check-in')),
                    DataColumn(label: Text('Check-out')),
                    DataColumn(label: Text('Tổng giờ')),
                    DataColumn(label: Text('Ghi nhận')),
                  ],
                  rows: List.generate(_vm.history.length, (i) {
                    final row = _vm.history[i];
                    final id = _vm.attendanceRows[i]['id'].toString();
                    return DataRow(
                      cells: [
                        DataCell(
                          Text(
                            _vm.attendanceRows[i]['staffName']?.toString() ??
                                '-',
                          ),
                        ),
                        DataCell(Text(row.$1)),
                        DataCell(Text(row.$2)),
                        DataCell(Text(row.$3)),
                        DataCell(Text(row.$4)),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              StatusChip(row.$5),
                              if (widget.role != UserRole.staff &&
                                  _vm.isStale(_vm.attendanceRows[i]))
                                TextButton(
                                  onPressed: () => _rejectStale(id),
                                  child: const Text('Đóng ca lỗi'),
                                ),
                              if (widget.role != UserRole.staff &&
                                  row.$5 == 'Pending') ...[
                                IconButton(
                                  tooltip: 'Duyệt giờ công',
                                  icon: const Icon(Icons.check_circle_outline),
                                  onPressed: () => _review(id, true),
                                ),
                                IconButton(
                                  tooltip: 'Từ chối giờ công',
                                  icon: const Icon(Icons.cancel_outlined),
                                  onPressed: () => _review(id, false),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
