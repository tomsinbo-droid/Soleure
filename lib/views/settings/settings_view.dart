import '../../core/constants/app_defaults.dart';
import '../../view_models/settings_view_model.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/user_role.dart';
import '../../widgets/page_header.dart';
import '../../widgets/section_card.dart';
import '../../widgets/app_loading_overlay.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key, required this.role});
  final UserRole role;
  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final _vm = SettingsViewModel();
  double commissionRate = AppDefaults.commissionRate;
  int holdMinutes = AppDefaults.holdMinutes;
  int hourlyRateDefault = AppDefaults.hourlyRateDefault;
  int maxWeeklyHours = AppDefaults.maxWeeklyHours;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await AppLoading.run(_vm.load);
      commissionRate =
          (data['commissionRate'] as num? ?? AppDefaults.commissionRate)
              .toDouble();
      holdMinutes = (data['holdMinutes'] as num? ?? AppDefaults.holdMinutes)
          .toInt();
      hourlyRateDefault =
          (data['hourlyRateDefault'] as num? ?? AppDefaults.hourlyRateDefault)
              .toInt();
      maxWeeklyHours =
          (data['maxWeeklyHours'] as num? ?? AppDefaults.maxWeeklyHours)
              .toInt();
      if (mounted) setState(() {});
    } catch (error) {
      _message('Không đọc được cài đặt: $error');
    }
  }

  void _message(String text) {
    if (mounted)
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _edit(String key, String label, String oldValue) async {
    String value = oldValue;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text('Cập nhật $label'),
        content: TextFormField(
          initialValue: oldValue,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: label),
          onChanged: (text) => value = text,
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
    );
    if (confirmed != true) return;
    final number = int.tryParse(value.trim());
    if (number == null) {
      _message('Giá trị phải là số nguyên.');
      return;
    }
    double newRate = commissionRate;
    int newHold = holdMinutes,
        newHourly = hourlyRateDefault,
        newLimit = maxWeeklyHours;
    if (key == 'commission') newRate = number / 100;
    if (key == 'hold') newHold = number;
    if (key == 'hourly') newHourly = number;
    if (key == 'weekly') newLimit = number;
    if (newRate < 0 ||
        newRate > .2 ||
        newHold < 1 ||
        newHold > 120 ||
        newHourly < 0 ||
        newLimit < 1 ||
        newLimit > 80) {
      _message('Giá trị nằm ngoài giới hạn cấu hình.');
      return;
    }
    try {
      await _vm.save({
        'commissionRate': newRate,
        'holdMinutes': newHold,
        'hourlyRateDefault': newHourly,
        'maxWeeklyHours': newLimit,
      });
      await _load();
      _message('Đã lưu cấu hình Firebase.');
    } catch (error) {
      _message('Lưu cấu hình thất bại: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageHeader(
          title: 'Cài đặt hệ thống',
          subtitle: 'Các thông số vận hành cần cấu hình thay vì hard-code.',
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, c) {
            final stacked = c.maxWidth < 800;
            final a = _group(context, 'KPI & Payroll', [
              _SettingRow(
                'Tỷ lệ hoa hồng mặc định',
                '${(commissionRate * 100).round()}%',
                onTap: () => _edit(
                  'commission',
                  'Hoa hồng (%)',
                  '${(commissionRate * 100).round()}',
                ),
              ),
              _SettingRow(
                'Lương giờ mặc định',
                '$hourlyRateDefault đ',
                onTap: () =>
                    _edit('hourly', 'Lương giờ (đ)', '$hourlyRateDefault'),
              ),
              const _SettingRow('Rule hoàn KPI', 'KPI Adjustment Transaction'),
            ]);
            final b = _group(context, 'Vận hành cửa hàng', [
              _SettingRow(
                'Hold Item',
                '$holdMinutes phút',
                onTap: () => _edit('hold', 'Hold (phút)', '$holdMinutes'),
              ),
              _SettingRow(
                'Giới hạn giờ / tuần',
                '$maxWeeklyHours giờ',
                onTap: () =>
                    _edit('weekly', 'Giới hạn giờ / tuần', '$maxWeeklyHours'),
              ),
              const _SettingRow('Thuế', 'Theo chi phí thuế trong kỳ'),
            ]);
            if (stacked)
              return Column(children: [a, const SizedBox(height: 16), b]);
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: a),
                const SizedBox(width: 16),
                Expanded(child: b),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Màu thương hiệu',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 14),
              const Wrap(
                spacing: 14,
                runSpacing: 14,
                children: [
                  _Color('#FE9EC7', AppColors.pink),
                  _Color('#F9F6C4', AppColors.cream),
                  _Color('#89D4FF', AppColors.sky),
                  _Color('#44ACFF', AppColors.blue),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _group(BuildContext context, String title, List<Widget> children) =>
      SectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      );
}

class _SettingRow extends StatelessWidget {
  const _SettingRow(this.label, this.value, {this.onTap});
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(color: AppColors.muted)),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.ink,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.edit_outlined, size: 18, color: AppColors.blue),
        ],
      ),
    ),
  );
}

class _Color extends StatelessWidget {
  const _Color(this.label, this.color);
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Container(
        width: 92,
        height: 54,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
      ),
      const SizedBox(height: 7),
      Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
    ],
  );
}
