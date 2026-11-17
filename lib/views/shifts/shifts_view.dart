import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/user_role.dart';
import '../../view_models/shift_view_model.dart';
import '../../widgets/data_table_shell.dart';
import '../../widgets/page_header.dart';
import '../../widgets/section_card.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/app_loading_overlay.dart';

class ShiftsView extends StatefulWidget {
  const ShiftsView({super.key, required this.role});
  final UserRole role;

  @override
  State<ShiftsView> createState() => _ShiftsViewState();
}

class _ShiftsViewState extends State<ShiftsView> {
  final _vm = ShiftViewModel();
  int _tab = 0;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _message(String message) {
    if (mounted)
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _load() async {
    try {
      await AppLoading.run(_vm.load);
      if (mounted) setState(() {});
    } catch (error) {
      _message('Không tải được lịch: $error');
    }
  }

  Future<void> _perform(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await AppLoading.run(action);
      if (mounted) setState(() {});
      _message('Đã cập nhật trên Firebase.');
    } catch (error) {
      _message('Không thực hiện được: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _createShift() async {
    var selectedDate = DateTime.now().add(const Duration(days: 1));
    var startTime = const TimeOfDay(hour: 9, minute: 0);
    var endTime = const TimeOfDay(hour: 14, minute: 0);
    String selectedUid = '';
    List<Map<String, String>> members = [];
    if (widget.role != UserRole.staff) {
      try {
        members = await _vm.getStaffNames();
      } catch (error) {
        _message('Không tải được nhân viên: $error');
        return;
      }
      if (members.isNotEmpty) selectedUid = members.first['uid'] ?? '';
    }
    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialog) => StatefulBuilder(
        builder: (context, refresh) => AlertDialog(
          title: Text(
            widget.role == UserRole.staff
                ? 'Đăng ký ca làm'
                : 'Sắp lịch cho Staff',
          ),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.role != UserRole.staff)
                  DropdownButtonFormField<String>(
                    initialValue: selectedUid.isEmpty ? null : selectedUid,
                    decoration: const InputDecoration(labelText: 'Nhân viên'),
                    items: members
                        .map(
                          (m) => DropdownMenuItem(
                            value: m['uid'],
                            child: Text(m['name'] ?? '-'),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => refresh(() => selectedUid = v ?? ''),
                  ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Ngày làm'),
                  subtitle: Text(
                    '${selectedDate.day.toString().padLeft(2, '0')}/'
                    '${selectedDate.month.toString().padLeft(2, '0')}/'
                    '${selectedDate.year}',
                  ),
                  trailing: const Icon(Icons.calendar_today_outlined),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) refresh(() => selectedDate = picked);
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Bắt đầu'),
                  subtitle: Text(startTime.format(context)),
                  trailing: const Icon(Icons.access_time_outlined),
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: startTime,
                    );
                    if (picked != null) refresh(() => startTime = picked);
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Kết thúc'),
                  subtitle: Text(endTime.format(context)),
                  trailing: const Icon(Icons.access_time_outlined),
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: endTime,
                    );
                    if (picked != null) refresh(() => endTime = picked);
                  },
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
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true) return;
    final start = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      startTime.hour,
      startTime.minute,
    );
    final end = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      endTime.hour,
      endTime.minute,
    );
    if (!end.isAfter(start) || !start.isAfter(DateTime.now())) {
      _message('Ngày và giờ không hợp lệ hoặc không ở tương lai.');
      return;
    }
    await _perform(
      () => widget.role == UserRole.staff
          ? _vm.register(start, end)
          : _vm.assign(selectedUid, start, end),
    );
  }

  Future<void> _reviewShift(String id) async {
    final approved = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('Duyệt đăng ký ca?'),
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
    await _perform(() => _vm.review(id, approved));
  }

  Future<void> _createSwap() async {
    final approvedShifts = _vm.shifts
        .where((s) => s.status == 'Approved')
        .toList();
    if (approvedShifts.isEmpty) {
      _message('Bạn chưa có ca Approved để đổi.');
      return;
    }
    String shiftId = approvedShifts.first.id, replacementUid = '', reason = '';
    final members = await _vm.getStaffNames();
    if (members.isNotEmpty) replacementUid = members.first['uid'] ?? '';
    if (!mounted) return;
    final yes = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('Phiếu đổi ca'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: shiftId,
                decoration: const InputDecoration(labelText: 'Ca cần đổi'),
                items: approvedShifts
                    .map(
                      (s) => DropdownMenuItem(
                        value: s.id,
                        child: Text('${s.date} · ${s.time}'),
                      ),
                    )
                    .toList(),
                onChanged: (v) => shiftId = v ?? shiftId,
              ),
              DropdownButtonFormField<String>(
                initialValue: replacementUid.isEmpty ? null : replacementUid,
                decoration: const InputDecoration(labelText: 'Người thay'),
                items: members
                    .map(
                      (m) => DropdownMenuItem(
                        value: m['uid'],
                        child: Text(m['name'] ?? '-'),
                      ),
                    )
                    .toList(),
                onChanged: (v) => replacementUid = v ?? '',
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
            child: const Text('Gửi phiếu'),
          ),
        ],
      ),
    );
    if (yes == true)
      await _perform(() => _vm.requestSwap(shiftId, replacementUid, reason));
  }

  Future<void> _acceptSwap(String id) async =>
      _perform(() => _vm.acceptSwap(id));
  Future<void> _cancelSwap(String id) async =>
      _perform(() => _vm.cancelSwap(id));
  Future<void> _reviewSwap(String id, bool approved) async =>
      _perform(() => _vm.reviewSwap(id, approved));

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          title: 'Ca làm & Phiếu đổi ca',
          subtitle: widget.role == UserRole.staff
              ? 'Đăng ký ca, xem lịch cá nhân và gửi yêu cầu đổi ca.'
              : 'Sắp lịch, kiểm tra trùng ca và xử lý phiếu đổi ca.',
          actions: [
            FilledButton.icon(
              onPressed: _busy ? null : _createShift,
              icon: Icon(
                widget.role == UserRole.staff
                    ? Icons.add_circle_outline
                    : Icons.calendar_month,
              ),
              label: Text(
                widget.role == UserRole.staff ? 'Đăng ký ca' : 'Sắp lịch',
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 0, label: Text('Lịch làm')),
            ButtonSegment(value: 1, label: Text('Phiếu đổi ca')),
          ],
          selected: {_tab},
          onSelectionChanged: (v) => setState(() => _tab = v.first),
        ),
        const SizedBox(height: 16),
        if (_tab == 0) _schedule() else _swaps(),
      ],
    );
  }

  Widget _schedule() => SectionCard(
    child: DataTableShell(
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Mã ca')),
          DataColumn(label: Text('Ngày')),
          DataColumn(label: Text('Thời gian')),
          DataColumn(label: Text('Nhân viên')),
          DataColumn(label: Text('Trạng thái')),
        ],
        rows: _vm.shifts
            .map(
              (s) => DataRow(
                cells: [
                  DataCell(Text(s.id)),
                  DataCell(Text(s.date)),
                  DataCell(Text(s.time)),
                  DataCell(Text(s.staffName)),
                  DataCell(
                    widget.role != UserRole.staff && s.status == 'Pending'
                        ? TextButton(
                            onPressed: _busy ? null : () => _reviewShift(s.id),
                            child: const Text('Pending · Duyệt'),
                          )
                        : StatusChip(s.status),
                  ),
                ],
              ),
            )
            .toList(),
      ),
    ),
  );

  Widget _swaps() {
    final uid = _vm.currentUid;
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Yêu cầu đổi ca',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Spacer(),
              if (widget.role == UserRole.staff)
                OutlinedButton.icon(
                  onPressed: _busy ? null : _createSwap,
                  icon: const Icon(Icons.swap_horiz),
                  label: const Text('Tạo phiếu đổi ca'),
                ),
            ],
          ),
          const SizedBox(height: 14),
          DataTableShell(
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Mã')),
                DataColumn(label: Text('Người yêu cầu')),
                DataColumn(label: Text('Ca cần đổi')),
                DataColumn(label: Text('Người thay')),
                DataColumn(label: Text('Trạng thái')),
                DataColumn(label: Text('Xử lý')),
              ],
              rows: _vm.swaps
                  .map(
                    (s) => DataRow(
                      cells: [
                        DataCell(Text(s.$1)),
                        DataCell(Text(s.$2)),
                        DataCell(Text(s.$3)),
                        DataCell(Text(s.$4)),
                        DataCell(StatusChip(s.$5)),
                        DataCell(
                          widget.role == UserRole.staff
                              ? (s.$4 == uid && s.$5 == 'PENDING'
                                    ? TextButton(
                                        onPressed: _busy
                                            ? null
                                            : () => _acceptSwap(s.$1),
                                        child: const Text('Đồng ý thay'),
                                      )
                                    : s.$2 == uid &&
                                          [
                                            'PENDING',
                                            'ACCEPTED_BY_STAFF',
                                          ].contains(s.$5)
                                    ? TextButton(
                                        onPressed: _busy
                                            ? null
                                            : () => _cancelSwap(s.$1),
                                        child: const Text('Hủy phiếu'),
                                      )
                                    : const Text('Xem chi tiết'))
                              : Wrap(
                                  spacing: 6,
                                  children: [
                                    IconButton(
                                      tooltip: 'Duyệt',
                                      onPressed:
                                          _busy || s.$5 != 'ACCEPTED_BY_STAFF'
                                          ? null
                                          : () => _reviewSwap(s.$1, true),
                                      icon: const Icon(
                                        Icons.check_circle_outline,
                                        color: AppColors.success,
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Từ chối',
                                      onPressed:
                                          _busy ||
                                              ![
                                                'PENDING',
                                                'ACCEPTED_BY_STAFF',
                                              ].contains(s.$5)
                                          ? null
                                          : () => _reviewSwap(s.$1, false),
                                      icon: const Icon(
                                        Icons.cancel_outlined,
                                        color: AppColors.danger,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ],
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Rule: không trùng ca · Staff active · ca chưa bắt đầu · đổi lịch chỉ có hiệu lực sau khi Manager duyệt.',
            style: TextStyle(color: AppColors.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
