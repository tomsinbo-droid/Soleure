// Công dụng tệp: Hiển thị bảng có thể cuộn ngang.

import 'package:flutter/material.dart';

class DataTableShell extends StatelessWidget {
  const DataTableShell({super.key, required this.child});

  final Widget child;

  /// Xây dựng giao diện của thành phần từ trạng thái hiện tại.
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: child,
    );
  }
}
