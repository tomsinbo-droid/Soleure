import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

class StatusChip extends StatelessWidget {
  const StatusChip(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final normalized = label.toLowerCase();
    final color =
        normalized.contains('active') ||
            normalized.contains('approved') ||
            normalized.contains('đang làm') ||
            normalized.contains('đã kiểm tra')
        ? AppColors.success
        : normalized.contains('reject') ||
              normalized.contains('expired') ||
              normalized.contains('trễ')
        ? AppColors.danger
        : normalized.contains('pending') || normalized.contains('chờ')
        ? AppColors.warning
        : AppColors.blue;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
