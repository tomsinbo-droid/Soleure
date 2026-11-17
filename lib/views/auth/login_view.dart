import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../view_models/auth_view_model.dart';
import '../../widgets/brand_logo.dart';
import '../../widgets/app_loading_overlay.dart';
import '../shell/app_shell.dart';
import 'forgot_password_view.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final AuthViewModel _vm = AuthViewModel();

  final TextEditingController _accountController = TextEditingController();

  final TextEditingController _passwordController = TextEditingController();

  bool _obscure = true;
  bool _loggingIn = false;
  String? _error;

  @override
  void dispose() {
    _accountController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_loggingIn) return;
    FocusScope.of(context).unfocus();
    final error = _vm.validateLogin(
      _accountController.text.trim(),
      _passwordController.text,
    );
    setState(() => _error = error);
    if (error != null) return;

    setState(() => _loggingIn = true);
    try {
      final session = await AppLoading.run(
        () =>
            _vm.login(_accountController.text.trim(), _passwordController.text),
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => AppShell(role: session.role!)),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString().replaceFirst('Bad state: ', ''));
    } finally {
      if (mounted) setState(() => _loggingIn = false);
    }
  }

  void _openForgotPassword() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ForgotPasswordView()));
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;

            // iPad portrait thường khoảng 768 - 834 logical pixels.
            final isTabletPortrait = width >= 600 && width < 900;

            return _buildPortraitLayout(
              context,
              isTabletPortrait: isTabletPortrait,
              keyboardHeight: mediaQuery.viewInsets.bottom,
            );
          },
        ),
      ),
    );
  }

  Widget _buildPortraitLayout(
    BuildContext context, {
    required bool isTabletPortrait,
    required double keyboardHeight,
  }) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.sky, AppColors.blue],
        ),
      ),
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.only(bottom: keyboardHeight > 0 ? 8 : 0),
        child: Center(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.symmetric(
              horizontal: isTabletPortrait ? 48 : 20,
              vertical: 32,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: _buildLoginCard(context, showMobileBrand: true),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBrandPanel(BuildContext context, {required bool compact}) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.blue, AppColors.sky],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(compact ? 32 : 46),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BrandLogo(height: compact ? 110 : 140, fit: BoxFit.contain),

            const Spacer(),

            Text(
              'Retail Operations\nManagement System',
              style: TextStyle(
                color: AppColors.ink,
                fontSize: compact ? 30 : 38,
                height: 1.1,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 18),

            const Text(
              'POS · Inventory · CRM · Workforce\nPayroll · KPI · Finance',
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 15,
                height: 1.5,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 28),

            const Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _Tag('DIECAST 1:64', AppColors.pink),
                _Tag('OFFLINE STORE', AppColors.cream),
                _Tag('SOLÉURE', AppColors.sky),
              ],
            ),

            const Spacer(),

            Text(
              'SOLÉURE • Store Operations',
              style: TextStyle(
                color: AppColors.ink.withValues(alpha: 0.65),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginCard(
    BuildContext context, {
    required bool showMobileBrand,
  }) {
    final theme = Theme.of(context);

    return Card(
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showMobileBrand) ...[
                Center(child: BrandLogo(height: 105, fit: BoxFit.contain)),
                const SizedBox(height: 28),
              ],

              Text(
                'Đăng nhập',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Đăng nhập để quản lý hoạt động cửa hàng Soléure.',
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 30),

              TextField(
                controller: _accountController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [
                  AutofillHints.username,
                  AutofillHints.email,
                ],
                decoration: const InputDecoration(
                  labelText: 'Email hoặc số điện thoại',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
                onChanged: (_) {
                  if (_error != null) {
                    setState(() {
                      _error = null;
                    });
                  }
                },
              ),

              const SizedBox(height: 18),

              TextField(
                controller: _passwordController,
                obscureText: _obscure,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                onSubmitted: (_) => _login(),
                decoration: InputDecoration(
                  labelText: 'Mật khẩu',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    tooltip: _obscure ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
                    onPressed: () {
                      setState(() {
                        _obscure = !_obscure;
                      });
                    },
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                  ),
                ),
                onChanged: (_) {
                  if (_error != null) {
                    setState(() {
                      _error = null;
                    });
                  }
                },
              ),

              if (_error != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: AppColors.danger,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(
                            color: AppColors.danger,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 10),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _openForgotPassword,
                  child: const Text('Quên mật khẩu?'),
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton.icon(
                  onPressed: _loggingIn ? null : _login,
                  icon: const Icon(Icons.login_rounded),
                  label: const Text(
                    'Đăng nhập',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.label, this.color);

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.ink,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
