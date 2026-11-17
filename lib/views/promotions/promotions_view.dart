import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/user_role.dart';
import '../../view_models/promotion_view_model.dart';
import '../../widgets/data_table_shell.dart';
import '../../widgets/page_header.dart';
import '../../widgets/section_card.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/app_loading_overlay.dart';

class PromotionsView extends StatefulWidget {
  const PromotionsView({super.key, required this.role});
  final UserRole role;
  @override
  State<PromotionsView> createState() => _PromotionsViewState();
}

class _PromotionsViewState extends State<PromotionsView> {
  final _vm = PromotionViewModel();
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
      _message('Không tải được khuyến mãi: $error');
    }
  }

  void _message(String message) {
    if (mounted)
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _propose() async {
    String name = '', scope = '', discount = '', from = '', to = '';
    final yes = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('Tạo đề xuất khuyến mãi'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Tên chương trình',
                ),
                onChanged: (v) => name = v,
              ),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Sản phẩm / Phạm vi',
                ),
                onChanged: (v) => scope = v,
              ),
              TextField(
                decoration: const InputDecoration(labelText: 'Giảm (%)'),
                keyboardType: TextInputType.number,
                onChanged: (v) => discount = v,
              ),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Từ ngày (YYYY-MM-DD)',
                ),
                onChanged: (v) => from = v,
              ),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Đến ngày (YYYY-MM-DD)',
                ),
                onChanged: (v) => to = v,
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
            child: const Text('Gửi đề xuất'),
          ),
        ],
      ),
    );
    if (yes != true) return;
    final start = DateTime.tryParse(from.trim());
    final end = DateTime.tryParse(to.trim());
    final percent = int.tryParse(discount.trim());
    if (start == null || end == null || percent == null) {
      _message('Ngày hoặc mức giảm không hợp lệ.');
      return;
    }
    await _perform(() => _vm.propose(name, scope, percent, start, end));
  }

  Future<void> _perform(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await AppLoading.run(action);
      if (mounted) setState(() {});
      _message('Đã cập nhật Firebase.');
    } catch (error) {
      _message('Không thực hiện được: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          title: 'Khuyến mãi',
          subtitle: widget.role == UserRole.admin
              ? 'Xem đề xuất, đánh giá tác động và duyệt / từ chối chương trình.'
              : 'Tạo đề xuất khuyến mãi và theo dõi trạng thái duyệt.',
          actions: [
            if (widget.role != UserRole.admin)
              FilledButton.icon(
                onPressed: _busy ? null : _propose,
                icon: const Icon(Icons.add),
                label: const Text('Tạo đề xuất'),
              ),
          ],
        ),
        const SizedBox(height: 18),
        SectionCard(
          child: DataTableShell(
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Chương trình')),
                DataColumn(label: Text('Phạm vi')),
                DataColumn(label: Text('Giảm')),
                DataColumn(label: Text('Thời gian')),
                DataColumn(label: Text('Người đề xuất')),
                DataColumn(label: Text('Trạng thái')),
                DataColumn(label: Text('Thao tác')),
              ],
              rows: _vm.promotions
                  .map(
                    (p) => DataRow(
                      cells: [
                        DataCell(Text(p.name)),
                        DataCell(Text(p.scope)),
                        DataCell(Text(p.discount)),
                        DataCell(Text(p.period)),
                        DataCell(Text(p.proposer)),
                        DataCell(StatusChip(p.status)),
                        DataCell(
                          widget.role == UserRole.admin && p.status == 'Pending'
                              ? Wrap(
                                  spacing: 4,
                                  children: [
                                    IconButton(
                                      tooltip: 'Duyệt',
                                      onPressed: _busy
                                          ? null
                                          : () => _perform(
                                              () => _vm.review(p.id, true),
                                            ),
                                      icon: const Icon(
                                        Icons.check_circle_outline,
                                        color: AppColors.success,
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Từ chối',
                                      onPressed: _busy
                                          ? null
                                          : () => _perform(
                                              () => _vm.review(p.id, false),
                                            ),
                                      icon: const Icon(
                                        Icons.cancel_outlined,
                                        color: AppColors.danger,
                                      ),
                                    ),
                                  ],
                                )
                              : const Text('Xem'),
                        ),
                      ],
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }
}
