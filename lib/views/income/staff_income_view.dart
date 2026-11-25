// Công dụng tệp: Thu nhập cá nhân.

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/money_formatter.dart';
import '../../models/user_role.dart';
import '../../view_models/staff_income_view_model.dart';
import '../../widgets/metric_card.dart';
import '../../widgets/page_header.dart';
import '../../widgets/section_card.dart';
import '../../widgets/app_loading_overlay.dart';

class StaffIncomeView extends StatefulWidget {
  const StaffIncomeView({super.key, required this.role});
  final UserRole role;
  /// Tạo trạng thái quản lý vòng đời và dữ liệu của màn hình.
  @override
  State<StaffIncomeView> createState() => _StaffIncomeViewState();
}

class _StaffIncomeViewState extends State<StaffIncomeView> {
  final StaffIncomeViewModel _vm = StaffIncomeViewModel();
  /// Khởi tạo trạng thái cần thiết khi thành phần được tạo.
  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Tải dữ liệu thu nhập cá nhân và cập nhật trạng thái tương ứng.
  Future<void> _load() async {
    try {
      await AppLoading.run(_vm.load);
      if (mounted) setState(() {});
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không tải được thu nhập: $error')),
        );
    }
  }

  /// Xây dựng giao diện của thành phần từ trạng thái hiện tại.
  @override
  Widget build(BuildContext context) {
    final metrics = [
      (
        'Giờ làm',
        '${_vm.hours}h',
        'Tháng ${DateTime.now().month}/${DateTime.now().year}',
        Icons.schedule,
        AppColors.sky,
      ),
      (
        'Tiền công',
        formatVnd(_vm.hourlyIncome),
        '${formatVnd(_vm.hourlyRate)}/giờ',
        Icons.access_time_filled,
        AppColors.cream,
      ),
      (
        'KPI phát sinh',
        formatVnd(_vm.commission),
        '${(_vm.commissionRate * 100).toStringAsFixed(0)}% doanh số đủ điều kiện',
        Icons.trending_up,
        AppColors.pink,
      ),
      (
        'Thu nhập dự kiến',
        formatVnd(_vm.expectedIncome),
        'Sau thu hồi / điều chỉnh',
        Icons.account_balance_wallet,
        AppColors.blue,
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageHeader(
          title: 'Thu nhập dự kiến',
          subtitle:
              'Theo dõi giờ làm, doanh số đủ điều kiện, KPI và các khoản điều chỉnh.',
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
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Chi tiết tính thu nhập',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              _row(
                _vm.estimatedEligibleSales
                    ? 'Eligible Net Sales (ước tính)'
                    : 'Eligible Net Sales',
                formatVnd(_vm.eligibleSales),
              ),
              _row(
                'Commission rate',
                '${(_vm.commissionRate * 100).toStringAsFixed(0)}%',
              ),
              _row('KPI phát sinh', formatVnd(_vm.commission)),
              _row('KPI bị thu hồi', '-${formatVnd(_vm.revokedCommission)}'),
              _row('Adjustment khác', formatVnd(_vm.adjustments)),
              const Divider(height: 28),
              _row('Dự kiến nhận', formatVnd(_vm.expectedIncome), bold: true),
            ],
          ),
        ),
      ],
    );
  }

  /// Xây dựng một dòng thông tin để hiển thị.
  Widget _row(String label, String value, {bool bold = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: bold ? AppColors.ink : AppColors.muted,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: AppColors.ink,
            fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
            fontSize: bold ? 18 : 14,
          ),
        ),
      ],
    ),
  );
}
