import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'views/auth/login_view.dart';
import 'widgets/app_loading_overlay.dart';

class SoleureApp extends StatelessWidget {
  const SoleureApp({super.key, this.setupError});

  final String? setupError;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Soléure Retail Operations',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      builder: (context, child) =>
          AppLoadingOverlay(child: child ?? const SizedBox.shrink()),
      home: setupError == null
          ? const LoginView()
          : Scaffold(
              appBar: AppBar(title: const Text('Cấu hình Firebase')),
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Firebase chưa sẵn sàng: $setupError\n\n'
                    'Chạy flutterfire configure và kết nối Firebase DEV.',
                  ),
                ),
              ),
            ),
    );
  }
}
