import '../core/constants/firebase_collections.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_profile.dart';
import '../models/user_role.dart';
import 'auth_service.dart';

/// Firebase - nghiệp vụ staff
class StaffService {
  late final FirebaseFirestore _db = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();
  Future<Map<String, dynamic>?> getMyProfile() async {
    final uid = _authService.currentUid;
    if (uid == null) return null;
    final doc = await _db.collection(FirebaseCollections.users).doc(uid).get();
    return doc.data();
  }

  Future<List<Map<String, String>>> getStaffNames() async {
    final result = await _db
        .collection(FirebaseCollections.users)
        .where('role', isEqualTo: 'staff')
        .limit(200)
        .get();
    return result.docs
        .where((doc) => doc.data()['active'] != false)
        .map(
          (doc) => {
            'uid': doc.id,
            'name': doc.data()['displayName']?.toString() ?? doc.id,
          },
        )
        .toList();
  }

  Future<List<Map<String, dynamic>>> getStaffRequests() async {
    final docs = await _db
        .collection(FirebaseCollections.staffRequests)
        .limit(200)
        .get();
    return docs.docs.map((e) => {'id': e.id, ...e.data()}).toList();
  }

  Future<void> proposeStaff(
    String name,
    String email,
    String phone,
    int hourlyRate,
  ) async {
    if (name.trim().isEmpty || !email.contains('@') || hourlyRate < 0) {
      throw StateError('Hồ sơ Staff chưa hợp lệ.');
    }

    await _db.collection(FirebaseCollections.staffRequests).add({
      'name': name.trim(),
      'email': email.trim().toLowerCase(),
      'phone': phone.trim(),
      'hourlyRate': hourlyRate,
      'requestedBy': _authService.currentUid,
      'status': 'Pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> reviewStaff(String id, bool approved) async {
    final uid = _authService.currentUid;
    if (uid == null) throw StateError('Bạn chưa đăng nhập.');
    await _db.collection(FirebaseCollections.staffRequests).doc(id).update({
      'status': approved ? 'Approved' : 'Rejected',
      'reviewedBy': uid,
      'reviewedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<List<UserProfile>> getStaffProfiles() async {
    final session = await _authService.getCurrentSession();
    final collection = _db.collection(FirebaseCollections.users);
    // Manager chỉ xem Staff; Admin xem toàn bộ tài khoản.
    final docs = session?.role == UserRole.manager
        ? await collection.where('role', isEqualTo: 'staff').limit(200).get()
        : await collection.limit(200).get();
    return docs.docs
        .map((doc) => UserProfile.fromMap(doc.id, doc.data()))
        .toList();
  }

  /// Admin SDK required: Firebase Auth user management is not a client API.
  /// A request is created for offline execution by a privileged local script.
  Future<void> updateAccount({
    required String uid,
    required String name,
    required String phone,
    required String role,
    required int hourlyRate,
    required bool active,
  }) async {
    throw StateError(
      'Không chỉnh role/khóa Auth từ Flutter. Dùng Admin SDK script quản trị tài khoản DEV.',
    );
  }

  Future<void> createAccount({
    required String name,
    required String email,
    required String phone,
    required String role,
    required int hourlyRate,
  }) async {
    throw StateError(
      'Không thể tạo Auth từ Flutter. Dùng script seed/admin trên máy developer để tạo tài khoản.',
    );
  }
}
