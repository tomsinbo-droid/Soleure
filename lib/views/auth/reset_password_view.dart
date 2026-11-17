import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class ResetPasswordView extends StatefulWidget {
  const ResetPasswordView({super.key});

  @override
  State<ResetPasswordView> createState() => _ResetPasswordViewState();
}

class _ResetPasswordViewState extends State<ResetPasswordView> {
  bool _hidden = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Đặt lại mật khẩu',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tạo mật khẩu mới cho tài khoản Soléure.',
                      style: TextStyle(color: AppColors.muted),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      obscureText: _hidden,
                      decoration: InputDecoration(
                        labelText: 'Mật khẩu mới',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => _hidden = !_hidden),
                          icon: Icon(
                            _hidden ? Icons.visibility_off : Icons.visibility,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      obscureText: _hidden,
                      decoration: const InputDecoration(
                        labelText: 'Xác nhận mật khẩu',
                        prefixIcon: Icon(Icons.lock_reset_outlined),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.sky.withValues(alpha: 0.20),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Text(
                        'Tối thiểu 8 ký tự · Có chữ in hoa · Có chữ số',
                        style: TextStyle(color: AppColors.ink),
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => Navigator.of(
                          context,
                        ).popUntil((route) => route.isFirst),
                        child: const Text('Đặt lại mật khẩu'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
