// Công dụng tệp: Kiểm tra quyền và môi trường Firebase.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Shared Firestore helpers for role checks and Firestore value conversion.
class FirestoreDemoGuard {
  static final FirebaseFirestore db = FirebaseFirestore.instance;

  /// Kiểm tra tài khoản hiện tại có vai trò được phép thực hiện thao tác.
  static Future<String> requireRole(List<String> roles) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw StateError('Vui lòng đăng nhập.');
    final row = await db.collection('users').doc(uid).get();
    final data = row.data();
    if (data == null ||
        data['active'] == false ||
        !roles.contains(data['role'])) {
      throw StateError('Tài khoản không có quyền thực hiện thao tác này.');
    }
    return uid;
  }

  /// Chuyển giá trị đầu vào thành số nguyên theo quy tắc kiểm tra.
  static int integer(dynamic value) => (value as num? ?? 0).toInt();
  /// Chuyển giá trị đầu vào thành thời điểm để xử lý.
  static DateTime? date(dynamic value) =>
      value is Timestamp ? value.toDate() : null;
}
