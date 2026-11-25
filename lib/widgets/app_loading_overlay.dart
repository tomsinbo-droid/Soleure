// Công dụng tệp: Hiển thị trạng thái đang tải.

import 'package:flutter/material.dart';

/// Shared, reference-counted loading overlay for asynchronous UI work.
class AppLoading {
  AppLoading._();

  static final ValueNotifier<int> _pending = ValueNotifier<int>(0);

  /// Hiển thị trạng thái đang tải trong khi thực hiện tác vụ bất đồng bộ.
  static Future<T> run<T>(Future<T> Function() action) async {
    _pending.value++;
    try {
      return await action();
    } finally {
      _pending.value--;
    }
  }
}

class AppLoadingOverlay extends StatelessWidget {
  const AppLoadingOverlay({super.key, required this.child});

  final Widget child;

  /// Xây dựng giao diện của thành phần từ trạng thái hiện tại.
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: AppLoading._pending,
      builder: (context, pending, _) {
        return Stack(
          children: [
            child,
            if (pending > 0)
              const Positioned.fill(
                child: ColoredBox(
                  color: Color(0x33000000),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        );
      },
    );
  }
}
