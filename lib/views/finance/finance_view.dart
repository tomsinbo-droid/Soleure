import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/money_formatter.dart';
import '../../models/user_role.dart';
import '../../view_models/finance_view_model.dart';
import '../../widgets/metric_card.dart';
import '../../widgets/page_header.dart';
import '../../widgets/section_card.dart';
import '../../widgets/app_loading_overlay.dart';

class FinanceView extends StatefulWidget {
  const FinanceView({super.key, required this.role});
  final UserRole role;
  @override
  State<FinanceView> createState() => _FinanceViewState();
}

class _FinanceViewState extends State<FinanceView> {
  final FinanceViewModel _vm = FinanceViewModel();
  String _period = 'month';

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
      _message('Không tải được tài chính: $error');
    }
  }

  void _message(String text) {
    if (mounted)
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _createExpense() async {
    String name = '', category = 'Biến phí', amount = '';
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialog) => StatefulBuilder(
        builder: (context, refresh) => AlertDialog(
          title: const Text('Ghi nhận khoản chi'),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: const InputDecoration(labelText: 'Tên chi phí'),
                  onChanged: (v) => name = v,
                ),
                DropdownButtonFormField<String>(
                  initialValue: category,
                  items: const ['Định phí', 'Biến phí', 'Thuế']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) => refresh(() => category = v ?? category),
                ),
                TextField(
                  decoration: const InputDecoration(labelText: 'Số tiền VND'),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => amount = v,
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
    if (ok != true) return;
    final money = int.tryParse(amount);
    if (money == null || money < 0) {
      _message('Số tiền không hợp lệ.');
      return;
    }
    try {
      await _vm.createExpense(name, category, money);
      if (mounted) setState(() {});
      _message('Đã ghi nhận chi phí.');
    } catch (error) {
      _message('Không ghi nhận được: $error');
    }
  }

  Future<void> _chooseRange(String period) async {
    final now = DateTime.now();
    DateTime first;
    DateTime last = DateTime(now.year, now.month, now.day);
    if (period == 'today') {
      first = last;
    } else if (period == 'week') {
      first = last.subtract(const Duration(days: 6));
    } else if (period == 'quarter') {
      first = DateTime(now.year, ((now.month - 1) ~/ 3) * 3 + 1, 1);
    } else if (period == 'custom') {
      final selected = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2020),
        lastDate: now,
        initialDateRange: DateTimeRange(start: _vm.from, end: _vm.to),
      );
      if (selected == null) return;
      first = selected.start;
      last = selected.end;
    } else {
      first = DateTime(now.year, now.month, 1);
    }
    if (last.difference(first).inDays > 92) {
      _message('Một báo cáo chỉ được chọn tối đa 93 ngày.');
      return;
    }
    try {
      await _vm.setRange(first, last);
      if (mounted) setState(() => _period = period);
    } catch (error) {
      _message('Không tải được báo cáo: $error');
    }
  }

  Future<void> _exportCsv() async {
    if (_vm.report == null) {
      _message('Chưa có dữ liệu báo cáo để xuất.');
      return;
    }
    try {
      final bytes = Uint8List.fromList([
        0xEF,
        0xBB,
        0xBF,
        ...utf8.encode(_vm.toCsv()),
      ]);
      await FilePicker.saveFile(
        fileName: 'soleure_finance_${_vm.report!.start}_${_vm.report!.end}.csv',
        mimeType: 'text/csv',
        bytes: bytes,
      );
    } catch (error) {
      _message('Không xuất được CSV: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final metrics = [
      (
        'Doanh thu thuần',
        formatVnd(_vm.grossRevenue),
        'Bán hàng trừ hoàn trả',
        Icons.payments_outlined,
        AppColors.sky,
      ),
      (
        'Tổng chi phí',
        formatVnd(_vm.totalExpenses),
        'Định phí + biến phí',
        Icons.receipt_long_outlined,
        AppColors.pink,
      ),
      (
        'Thuế đã ghi',
        formatVnd(_vm.tax),
        'Chưa quyết toán thuế',
        Icons.account_balance_outlined,
        AppColors.cream,
      ),
      (
        'Lợi nhuận tạm tính',
        formatVnd(_vm.netProfit),
        'Chưa gồm lương kỳ chưa chốt',
        Icons.trending_up,
        AppColors.blue,
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          title: 'Tài chính & báo cáo',
          subtitle:
              'Doanh thu, chi phí và lợi nhuận tạm tính từ Firebase theo kỳ.',
          actions: [
            OutlinedButton.icon(
              onPressed: _exportCsv,
              icon: const Icon(Icons.download),
              label: const Text('Xuất CSV'),
            ),
            OutlinedButton.icon(
              onPressed: _createExpense,
              icon: const Icon(Icons.add),
              label: const Text('Thêm chi phí'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            DropdownButton<String>(
              value: _period,
              items: const [
                DropdownMenuItem(value: 'today', child: Text('Hôm nay')),
                DropdownMenuItem(value: 'week', child: Text('7 ngày')),
                DropdownMenuItem(value: 'month', child: Text('Tháng này')),
                DropdownMenuItem(value: 'quarter', child: Text('Quý này')),
                DropdownMenuItem(value: 'custom', child: Text('Tùy chọn')),
              ],
              onChanged: (value) {
                if (value != null) _chooseRange(value);
              },
            ),
            Text(
              'Từ ${_vm.from.day}/${_vm.from.month}/${_vm.from.year} đến ${_vm.to.day}/${_vm.to.month}/${_vm.to.year}',
              style: const TextStyle(color: AppColors.muted),
            ),
            TextButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text('Tải lại'),
            ),
          ],
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, c) {
            final cols = c.maxWidth >= 1100
                ? 4
                : c.maxWidth >= 600
                ? 2
                : 1;
            final w = (c.maxWidth - (cols - 1) * 12) / cols;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final m in metrics)
                  SizedBox(
                    width: w,
                    child: MetricCard(
                      label: m.$1,
                      value: m.$2,
                      caption: m.$3,
                      icon: m.$4,
                      tint: m.$5,
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 18),
        if (_vm.report != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              _vm.report!.note,
              style: const TextStyle(color: AppColors.muted),
            ),
          ),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cơ cấu chi phí',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 14),
              for (final e in _vm.expenses)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          e.$1,
                          style: const TextStyle(
                            color: AppColors.ink,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 110,
                        child: Text(
                          e.$2,
                          style: const TextStyle(color: AppColors.muted),
                        ),
                      ),
                      Text(
                        formatVnd(e.$3),
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        if (_vm.report != null)
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Doanh thu theo ngày',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 220,
                  child: ListView(
                    children: [
                      for (final row in _vm.report!.rows('days'))
                        ListTile(
                          dense: true,
                          title: Text(row['date']?.toString() ?? ''),
                          trailing: Text(
                            formatVnd((row['net'] as num? ?? 0).toDouble()),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Hiệu suất nhân viên',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                for (final row in _vm.report!.rows('staff').take(15))
                  ListTile(
                    dense: true,
                    title: Text(row['name']?.toString() ?? ''),
                    subtitle: Text(
                      'Bill: ${row['orders']} · KPI: ${formatVnd((row['kpi'] as num? ?? 0).toDouble())}',
                    ),
                    trailing: Text(
                      formatVnd((row['revenue'] as num? ?? 0).toDouble()),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
