import '../services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_session.dart';

class AuthViewModel {
  final AuthService _authService = AuthService();

  Future<void> resetPassword(String email) => _authService.resetPassword(email);

  String? validateLogin(String account, String password) {
    if (account.trim().isEmpty) return 'Vui lòng nhập email.';
    if (!account.contains('@')) return 'Email không hợp lệ.';
    if (password.length < 6) return 'Mật khẩu cần ít nhất 6 ký tự.';
    return null;
  }

  Future<AppSession> login(String account, String password) async {
    try {
      await _authService.login(account.trim(), password);
      final session = await _authService.getCurrentSession();
      if (session == null) throw StateError('Không tìm thấy phiên đăng nhập.');
      if (session.role == null) {
        await _authService.logout();
        throw StateError(
          'Tài khoản chưa được Admin cấp vai trò trong Firestore.',
        );
      }
      return session;
    } on FirebaseAuthException catch (error) {
      if ([
        'invalid-credential',
        'wrong-password',
        'user-not-found',
      ].contains(error.code)) {
        throw StateError('Email hoặc mật khẩu không đúng.');
      }
      if (error.code == 'user-disabled')
        throw StateError('Tài khoản đã bị khóa.');
      throw StateError('Firebase Auth: ${error.code}');
    }
  }
}
