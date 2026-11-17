import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/user_role.dart';
import '../../view_models/hold_view_model.dart';
import '../../widgets/data_table_shell.dart';
import '../../widgets/page_header.dart';
import '../../widgets/section_card.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/app_loading_overlay.dart';

class HoldItemsView extends StatefulWidget {
  const HoldItemsView({super.key, required this.role});
  final UserRole role;
  @override
  State<HoldItemsView> createState() => _HoldItemsViewState();
}

class _HoldItemsViewState extends State<HoldItemsView> {
  final _vm = HoldViewModel();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      await AppLoading.run(_vm.load);
      if (mounted) setState(() {});
    } catch (error) {
      _message('Không tải được Hold: $error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _message(String text) {
    if (mounted)
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _create() async {
    String sku = '', count = '1', customerId = '';
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('Tạo Hold 30 phút'),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: 'SKU'),
                onChanged: (v) => sku = v,
              ),
              TextField(
                decoration: const InputDecoration(labelText: 'Số lượng'),
                keyboardType: TextInputType.number,
                onChanged: (v) => count = v,
              ),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Mã khách (không bắt buộc)',
                ),
                onChanged: (v) => customerId = v,
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
            child: const Text('Tạo'),
          ),
        ],
      ),
    );
    if (accepted != true || !mounted) return;
    try {
      await _vm.create(
        sku.trim(),
        int.parse(count.trim()),
        customerId.trim().isEmpty ? null : customerId.trim(),
      );
      if (mounted) setState(() {});
      _message('Đã tạo Hold trên Firebase.');
    } catch (error) {
      _message('Không tạo được Hold: $error');
    }
  }

  Future<void> _cancel(String id) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('Hủy phiếu giữ hàng?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            child: const Text('Không'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialog, true),
            child: const Text('Hủy Hold'),
          ),
        ],
      ),
    );
    if (yes != true) return;
    try {
      await _vm.cancel(id);
      if (mounted) setState(() {});
    } catch (error) {
      _message('Hủy Hold thất bại: $error');
    }
  }

  Future<void> _payHold(Map<String, dynamic> hold) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('Xác nhận đã thu tiền mặt cho Hold'),
        content: const Text(
          'Chỉ bấm khi khách đã thanh toán đủ tiền mặt thực tế. Backend tính lại giá, trừ hàng đang Hold và ghi KPI.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            child: const Text('Chưa nhận'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialog, true),
            child: const Text('Đã nhận tiền'),
          ),
        ],
      ),
    );
    if (yes != true) return;
    try {
      final order = await _vm.payCash(hold);
      if (mounted) setState(() {});
      _message('Đã bán Hold. Mã bill: ${order['id']}');
    } catch (error) {
      _message('Chưa thanh toán được Hold: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          title: 'Hold Item',
          subtitle:
              'Giữ hàng tạm thời và tránh trường hợp Staff khác bán cùng sản phẩm.',
          actions: [
            FilledButton.icon(
              onPressed: _loading ? null : _create,
              icon: const Icon(Icons.add),
              label: const Text('Tạo Hold'),
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
                  color: AppColors.cream.withValues(alpha: .42),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text(
                  'Hold 30 phút → Sold hoặc Expired/Available. Firebase Scheduler giải phóng tồn kho khi Hold hết hạn.',
                ),
              ),
              const SizedBox(height: 14),
              DataTableShell(
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Mã')),
                    DataColumn(label: Text('Khách')),
                    DataColumn(label: Text('Sản phẩm')),
                    DataColumn(label: Text('Staff tạo')),
                    DataColumn(label: Text('Còn lại')),
                    DataColumn(label: Text('Trạng thái')),
                  ],
                  rows: _vm.rows
                      .map(
                        (h) => DataRow(
                          cells: [
                            DataCell(Text(h['id']?.toString() ?? '-')),
                            DataCell(
                              Text(h['customerId']?.toString() ?? 'Khách lẻ'),
                            ),
                            DataCell(Text(_vm.itemNames(h))),
                            DataCell(Text(h['staffName']?.toString() ?? '-')),
                            DataCell(Text(_vm.remaining(h))),
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  StatusChip(_vm.status(h)),
                                  if (_vm.status(h) == 'Active')
                                    IconButton(
                                      onPressed: () => _payHold(h),
                                      tooltip: 'Thu tiền mặt cho Hold',
                                      icon: const Icon(Icons.payments_outlined),
                                    ),
                                  if (_vm.status(h) == 'Active')
                                    IconButton(
                                      onPressed: () =>
                                          _cancel(h['id'].toString()),
                                      tooltip: 'Hủy Hold',
                                      icon: const Icon(Icons.cancel_outlined),
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
            ],
          ),
        ),
      ],
    );
  }
}
