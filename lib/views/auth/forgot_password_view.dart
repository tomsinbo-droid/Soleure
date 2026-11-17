import '../../view_models/auth_view_model.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../widgets/brand_logo.dart';
import '../../widgets/app_loading_overlay.dart';

class ForgotPasswordView extends StatefulWidget {
  const ForgotPasswordView({super.key});

  @override
  State<ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<ForgotPasswordView> {
  final _email = TextEditingController();
  final _vm = AuthViewModel();

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _sendReset() async {
    if (!_email.text.trim().contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập email hợp lệ.')),
      );
      return;
    }
    try {
      await AppLoading.run(() => _vm.resetPassword(_email.text.trim()));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Nếu email hợp lệ, hãy kiểm tra hộp thư để đặt lại mật khẩu.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Không gửi được yêu cầu: $error')));
    }
  }

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
                    const BrandLogo(height: 110),
                    const SizedBox(height: 24),
                    Text(
                      'Quên mật khẩu',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Nhập email hoặc số điện thoại liên kết với tài khoản để nhận hướng dẫn đặt lại mật khẩu.',
                      style: TextStyle(color: AppColors.muted),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _email,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _sendReset,
                        child: const Text('Gửi yêu cầu'),
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
