import '../core/constants/firebase_collections.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../firebase_options.dart';
import '../models/user_profile.dart';
import '../models/user_role.dart';
import 'auth_service.dart';

/// Firebase - nghiệp vụ staff
class StaffService {
  late final FirebaseFirestore _db = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  Future<FirebaseApp> _provisioningApp() async {
    const name = 'staff-account-provisioning';
    try {
      return Firebase.app(name);
    } on FirebaseException {
      return Firebase.initializeApp(
        name: name,
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  }

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

  Future<void> updateAccount({
    required String uid,
    required String name,
    required String phone,
    required String role,
    required int hourlyRate,
    required bool active,
  }) async {
    if (!_isManagedRole(role) || name.trim().isEmpty || hourlyRate < 0) {
      throw StateError('Dữ liệu tài khoản chưa hợp lệ.');
    }
    await _db.collection(FirebaseCollections.users).doc(uid).update({
      'displayName': name.trim(),
      'phone': phone.trim(),
      'role': role,
      'hourlyRate': hourlyRate,
      'active': active,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> createAccount({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String role,
    required int hourlyRate,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (name.trim().isEmpty ||
        !_isValidEmail(normalizedEmail) ||
        password.length < 6 ||
        !_isManagedRole(role) ||
        hourlyRate < 0) {
      throw StateError('Thông tin tài khoản chưa hợp lệ.');
    }

    final secondaryAuth = FirebaseAuth.instanceFor(
      app: await _provisioningApp(),
    );
    if (const bool.fromEnvironment('SOLEURE_FIRESTORE_EMULATOR')) {
      secondaryAuth.useAuthEmulator('127.0.0.1', 9099);
    }
    UserCredential? credential;
    var profileCreated = false;
    try {
      credential = await secondaryAuth.createUserWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );
      final uid = credential.user?.uid;
      if (uid == null) throw StateError('Không tạo được mã tài khoản.');
      await _db.collection(FirebaseCollections.users).doc(uid).set({
        'uid': uid,
        'displayName': name.trim(),
        'email': normalizedEmail,
        'phone': phone.trim(),
        'role': role,
        'hourlyRate': hourlyRate,
        'active': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      profileCreated = true;
    } on FirebaseAuthException catch (error) {
      if (!profileCreated && credential != null) {
        await credential.user?.delete();
      }
      throw StateError(
        '${profileCreated ? 'Tài khoản đã tạo nhưng không gửi được email đặt mật khẩu: ' : 'Không thể tạo tài khoản: '}'
        '${error.message ?? error.code}',
      );
    } catch (_) {
      if (!profileCreated && credential != null) {
        await credential.user?.delete();
      }
      rethrow;
    } finally {
      await secondaryAuth.signOut();
    }
  }

  bool _isManagedRole(String role) => role == 'manager' || role == 'staff';

  bool _isValidEmail(String email) =>
      RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email);
}
