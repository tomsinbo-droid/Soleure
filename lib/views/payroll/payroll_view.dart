import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/money_formatter.dart';
import '../../models/user_role.dart';
import '../../view_models/payroll_view_model.dart';
import '../../widgets/data_table_shell.dart';
import '../../widgets/page_header.dart';
import '../../widgets/section_card.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/app_loading_overlay.dart';

class PayrollView extends StatefulWidget {
  const PayrollView({super.key, required this.role});
  final UserRole role;
  @override
  State<PayrollView> createState() => _PayrollViewState();
}

class _PayrollViewState extends State<PayrollView> {
  final PayrollViewModel _vm = PayrollViewModel();
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
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không tải được dự kiến lương: $error')),
        );
    }
  }

  void _message(String message) {
    if (mounted)
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _adjust() async {
    final staff = await _vm.getStaffNames();
    if (!mounted || staff.isEmpty) {
      _message('Không tìm thấy Staff.');
      return;
    }
    String staffUid = staff.first['uid']!, amount = '0', reason = '';
    final yes = await showDialog<bool>(
      context: context,
      builder: (dialog) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          title: const Text('Đề xuất điều chỉnh lương'),
          content: SizedBox(
            width: 380,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: staffUid,
                  decoration: const InputDecoration(labelText: 'Nhân viên'),
                  items: staff
                      .map(
                        (e) => DropdownMenuItem(
                          value: e['uid'],
                          child: Text(e['name']!),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => update(() => staffUid = v ?? staffUid),
                ),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Điều chỉnh +/- VND',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => amount = v,
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
    if (yes != true) return;
    final value = int.tryParse(amount);
    if (value == null) {
      _message('Số tiền không hợp lệ.');
      return;
    }
    try {
      await _vm.createAdjustment(staffUid, value, reason);
      if (mounted) setState(() {});
      _message('Đã tạo đề xuất điều chỉnh. Admin phải duyệt.');
    } catch (error) {
      _message('Không tạo được điều chỉnh: $error');
    }
  }

  Future<void> _reviewAdjustments() async {
    if (_vm.pendingAdjustments.isEmpty) {
      _message('Không có phiếu điều chỉnh chờ duyệt.');
      return;
    }
    final item = _vm.pendingAdjustments.first;
    final approved = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('Duyệt điều chỉnh lương'),
        content: Text(
          'Nhân viên: ${item['staffUid']}\nSố tiền: ${formatVnd((item['amount'] as num).toDouble())}\nLý do: ${item['reason']}',
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
      await _vm.reviewAdjustment(item['id'].toString(), approved);
      if (mounted) setState(() {});
      _message('Đã duyệt phiếu điều chỉnh.');
    } catch (error) {
      _message('Không duyệt được: $error');
    }
  }

  Future<void> _close() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text('Chốt dữ liệu kỳ ${_vm.period}?'),
        content: const Text(
          'Chỉ khóa dữ liệu giờ công đã duyệt + KPI + điều chỉnh. CHƯA xác nhận thuế hay thanh toán lương.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialog, true),
            child: const Text('Chốt dữ liệu'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _vm.closePeriod();
      if (mounted) setState(() {});
      _message('Đã khóa snapshot lương nội bộ, chưa đánh dấu trả lương.');
    } catch (error) {
      _message('Không chốt được: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          title: 'Bảng lương',
          subtitle: 'Lương giờ + KPI - KPI thu hồi + điều chỉnh hợp lệ.',
          actions: [
            DropdownButton<String>(
              value: _vm.period,
              items: List.generate(6, (i) {
                final d = DateTime(
                  DateTime.now().year,
                  DateTime.now().month - i,
                );
                final id = '${d.year}-${d.month.toString().padLeft(2, '0')}';
                return DropdownMenuItem(value: id, child: Text(id));
              }),
              onChanged: (value) async {
                if (value == null) return;
                _vm.selectPeriod(value);
                await _load();
              },
            ),
            if (!_vm.periodClosed)
              OutlinedButton.icon(
                onPressed: _adjust,
                icon: const Icon(Icons.edit_note),
                label: const Text('Điều chỉnh'),
              ),
            if (widget.role == UserRole.admin &&
                _vm.pendingAdjustments.isNotEmpty)
              OutlinedButton.icon(
                onPressed: _reviewAdjustments,
                icon: const Icon(Icons.fact_check_outlined),
                label: const Text('Duyệt điều chỉnh'),
              ),
            FilledButton.icon(
              onPressed:
                  widget.role == UserRole.admin &&
                      !_vm.periodClosed &&
                      _vm.period !=
                          '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}'
                  ? _close
                  : null,
              icon: const Icon(Icons.lock_outline),
              label: const Text('Chốt dữ liệu kỳ'),
            ),
          ],
        ),
        const SizedBox(height: 18),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.sky.withValues(alpha: .18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text(
                  'Dữ liệu dự kiến chỉ tính giờ công đã được Manager duyệt. Chốt nội bộ không đồng nghĩa đã thanh toán lương hoặc hoàn tất thuế.',
                  style: TextStyle(color: AppColors.ink),
                ),
              ),
              const SizedBox(height: 14),
              DataTableShell(
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Nhân viên')),
                    DataColumn(label: Text('Giờ')),
                    DataColumn(label: Text('Lương giờ')),
                    DataColumn(label: Text('KPI')),
                    DataColumn(label: Text('Điều chỉnh')),
                    DataColumn(label: Text('Dự kiến')),
                    DataColumn(label: Text('Trạng thái')),
                  ],
                  rows: _vm.entries
                      .map(
                        (e) => DataRow(
                          cells: [
                            DataCell(Text(e.staffName)),
                            DataCell(Text('${e.hours}h')),
                            DataCell(Text(formatVnd(e.hourlyPay))),
                            DataCell(Text(formatVnd(e.commission))),
                            DataCell(Text(formatVnd(e.adjustments))),
                            DataCell(
                              Text(
                                formatVnd(e.total),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            DataCell(StatusChip(e.status)),
                          ],
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
