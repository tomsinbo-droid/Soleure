// Công dụng tệp: Tổng quan cửa hàng.

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/user_role.dart';
import '../../view_models/dashboard_view_model.dart';
import '../../widgets/metric_card.dart';
import '../../widgets/page_header.dart';
import '../../widgets/section_card.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/app_loading_overlay.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({
    super.key,
    required this.role,
    required this.onNavigate,
  });
  final UserRole role;
  final ValueChanged<String> onNavigate;
  /// Tạo trạng thái quản lý vòng đời và dữ liệu của màn hình.
  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  final DashboardViewModel _vm = DashboardViewModel();
  /// Khởi tạo trạng thái cần thiết khi thành phần được tạo.
  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Tải dữ liệu tổng quan cửa hàng và cập nhật trạng thái tương ứng.
  Future<void> _load() async {
    try {
      await AppLoading.run(() => _vm.load(widget.role));
      if (mounted) setState(() {});
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không tải được Dashboard: $error')),
        );
    }
  }

  /// Xây dựng giao diện của thành phần từ trạng thái hiện tại.
  @override
  Widget build(BuildContext context) {
    final metrics = _vm.metrics(widget.role);
    final tints = [
      AppColors.pink,
      AppColors.cream,
      AppColors.sky,
      AppColors.blue,
    ];
    final icons = [
      Icons.payments_outlined,
      Icons.receipt_long_outlined,
      Icons.inventory_2_outlined,
      Icons.trending_up_rounded,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          title: 'Tổng quan ${widget.role.label}',
          subtitle: 'Theo dõi nhanh hoạt động cửa hàng và các việc cần xử lý.',
          actions: [
            OutlinedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: Text(
                '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
              ),
            ),
            FilledButton.icon(
              onPressed: () => widget.onNavigate('pos'),
              icon: const Icon(Icons.point_of_sale),
              label: const Text('Mở POS'),
            ),
          ],
        ),
        const SizedBox(height: 22),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 1200
                ? 4
                : constraints.maxWidth >= 650
                ? 2
                : 1;
            final width = (constraints.maxWidth - (columns - 1) * 14) / columns;
            return Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                for (var i = 0; i < metrics.length; i++)
                  SizedBox(
                    width: width,
                    child: MetricCard(
                      label: metrics[i].label,
                      value: metrics[i].value,
                      caption: metrics[i].caption,
                      icon: icons[i],
                      tint: tints[i],
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 22),
        LayoutBuilder(
          builder: (context, constraints) {
            final stacked = constraints.maxWidth < 900;
            final sales = SectionCard(
              child: _SalesOverview(
                role: widget.role,
                values: _vm.weeklyRevenue,
              ),
            );
            final tasks = SectionCard(
              child: _PendingTasks(
                items: _vm.tasks,
                onNavigate: widget.onNavigate,
              ),
            );
            if (stacked)
              return Column(
                children: [sales, const SizedBox(height: 16), tasks],
              );
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 6, child: sales),
                const SizedBox(width: 16),
                Expanded(flex: 4, child: tasks),
              ],
            );
          },
        ),
        const SizedBox(height: 18),
        SectionCard(child: _RecentActivity(activities: _vm.activities)),
      ],
    );
  }
}

class _SalesOverview extends StatelessWidget {
  const _SalesOverview({required this.role, required this.values});
  final UserRole role;
  final List<double> values;

  /// Xây dựng giao diện của thành phần từ trạng thái hiện tại.
  @override
  Widget build(BuildContext context) {
    final maxValue = values.fold<double>(
      1,
      (current, v) => v > current ? v : current,
    );
    final chartValues = values
        .map((v) => (v / maxValue).clamp(0.02, 1.0))
        .toList();
    final labels = List.generate(7, (i) {
      final day = DateTime.now().subtract(Duration(days: 6 - i));
      return '${day.day}/${day.month}';
    });
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              role == UserRole.staff ? 'Doanh số cá nhân' : 'Doanh thu 7 ngày',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Spacer(),
            const Text(
              'Đơn vị: triệu đồng',
              style: TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 210,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < values.length; i++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: FractionallySizedBox(
                              heightFactor: chartValues[i],
                              widthFactor: 0.62,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: [AppColors.blue, AppColors.sky],
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          labels[i],
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PendingTasks extends StatelessWidget {
  const _PendingTasks({required this.items, required this.onNavigate});
  final List<(String, String, String, String)> items;
  final ValueChanged<String> onNavigate;

  /// Xây dựng giao diện của thành phần từ trạng thái hiện tại.
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Cần xử lý', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        for (final item in items)
          InkWell(
            onTap: () => onNavigate(item.$4),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 11),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.pink,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.$1,
                          style: const TextStyle(
                            color: AppColors.ink,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item.$2,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  StatusChip(item.$3),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _RecentActivity extends StatelessWidget {
  const _RecentActivity({required this.activities});
  final List<(String, String, String)> activities;

  /// Xây dựng giao diện của thành phần từ trạng thái hiện tại.
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hoạt động gần đây',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        for (final a in activities)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 9),
            child: Row(
              children: [
                SizedBox(
                  width: 54,
                  child: Text(
                    a.$1,
                    style: const TextStyle(
                      color: AppColors.blue,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    a.$2,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    a.$3,
                    style: const TextStyle(color: AppColors.muted),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
