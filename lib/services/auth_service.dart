// Công dụng tệp: Đăng nhập và tài khoản.

import '../core/constants/firebase_collections.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_session.dart';
import '../models/user_profile.dart';

/// Firebase - nghiệp vụ auth
class AuthService {
  late final FirebaseFirestore _db = FirebaseFirestore.instance;
  String? get currentUid => FirebaseAuth.instance.currentUser?.uid;

  /// Lấy phiên đăng nhập hiện tại.
  Future<AppSession?> getCurrentSession() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    // Vai trò chỉ đọc từ Firestore (không tin role tự gửi từ ứng dụng).
    final document = await _db
        .collection(FirebaseCollections.users)
        .doc(user.uid)
        .get();
    if (!document.exists) {
      return AppSession(uid: user.uid, displayName: user.email ?? 'Người dùng');
    }
    final profile = UserProfile.fromMap(user.uid, document.data() ?? {});
    return AppSession(
      uid: profile.uid,
      displayName: profile.displayName.isEmpty
          ? (user.email ?? 'Người dùng')
          : profile.displayName,
      role: profile.active ? profile.role : null,
    );
  }

  /// Đăng nhập bằng thông tin tài khoản được cung cấp.
  Future<void> login(String email, String password) async {
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Đăng xuất tài khoản hiện tại.
  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
  }

  /// Gửi yêu cầu đặt lại mật khẩu qua email.
  Future<void> resetPassword(String email) async {
    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
  }
}
