// Công dụng tệp: Lưu thông tin phiên đăng nhập.

import 'user_role.dart';

class AppSession {
  const AppSession({required this.uid, required this.displayName, this.role});
  final String uid;
  final String displayName;

  /// null = tài khoản Firebase chưa được Admin cấp quyền.
  final UserRole? role;
}
