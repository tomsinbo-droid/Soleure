// Công dụng tệp: Nhân sự.

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
  static Future<FirebaseAuth>? _secondaryAuthFuture;

  /// Lấy ứng dụng Firebase phụ phục vụ quản trị tài khoản.
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

  /// Lấy hồ sơ cá nhân của tài khoản hiện tại.
  Future<Map<String, dynamic>?> getMyProfile() async {
    final uid = _authService.currentUid;
    if (uid == null) return null;
    final doc = await _db.collection(FirebaseCollections.users).doc(uid).get();
    return doc.data();
  }

  /// Lấy tên nhân viên.
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

  /// Lấy các đề xuất tài khoản nhân viên.
  Future<List<Map<String, dynamic>>> getStaffRequests() async {
    final docs = await _db
        .collection(FirebaseCollections.staffRequests)
        .limit(200)
        .get();
    return docs.docs.map((e) => {'id': e.id, ...e.data()}).toList();
  }

  /// Đề xuất nhân viên.
  Future<void> proposeStaff(
    String name,
    String email,
    String phone,
    int hourlyRate,
  ) async {
    if (name.trim().isEmpty ||
        !_isValidEmail(email.trim().toLowerCase()) ||
        hourlyRate < 0 ||
        hourlyRate > 1000000) {
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

  /// Xem xét và xử lý nhân viên.
  Future<void> reviewStaff(String id, bool approved) async {
    final uid = _authService.currentUid;
    if (uid == null) throw StateError('Bạn chưa đăng nhập.');
    if (approved) throw StateError('Duyệt cần tạo tài khoản Staff.');
    final ref = _db.collection(FirebaseCollections.staffRequests).doc(id);
    await _db.runTransaction((transaction) async {
      final request = await transaction.get(ref);
      if (!request.exists || request.data()?['status'] != 'Pending') {
        throw StateError('Đề xuất không còn chờ duyệt.');
      }
      transaction.update(ref, {
        'status': 'Rejected',
        'reviewedBy': uid,
        'reviewedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Duyệt nhân viên.
  Future<void> approveStaff(String id, String password) async {
    final reviewer = _authService.currentUid;
    if (reviewer == null) throw StateError('Bạn chưa đăng nhập.');
    if (password.length < 6) {
      throw StateError('Mật khẩu phải có ít nhất 6 ký tự.');
    }
    final requestRef = _db.collection(FirebaseCollections.staffRequests).doc(id);
    final request = await requestRef.get();
    final data = request.data();
    if (data == null || data['status'] != 'Pending') {
      throw StateError('Đề xuất không còn chờ duyệt.');
    }
    final email = (data['email'] as String? ?? '').trim().toLowerCase();
    final name = (data['name'] as String? ?? '').trim();
    final phone = (data['phone'] as String? ?? '').trim();
    final rate = data['hourlyRate'];
    if (!_isValidEmail(email) || name.isEmpty || rate is! int ||
        rate < 0 || rate > 1000000) {
      throw StateError('Thông tin đề xuất chưa hợp lệ.');
    }
    final secondaryAuth = await _secondaryAuth();
    User? createdUser;
    var committed = false;
    try {
      final credential = await secondaryAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      createdUser = credential.user;
      if (createdUser == null) throw StateError('Không tạo được mã tài khoản.');
      final user = createdUser;
      await _db.runTransaction((transaction) async {
        final current = await transaction.get(requestRef);
        final currentData = current.data();
        if (currentData == null || currentData['status'] != 'Pending' ||
            currentData['email'] != data['email'] ||
            currentData['name'] != data['name'] ||
            currentData['phone'] != data['phone'] ||
            currentData['hourlyRate'] != rate) {
          throw StateError('Đề xuất đã thay đổi hoặc không còn chờ duyệt.');
        }
        transaction.set(_db.collection(FirebaseCollections.users).doc(user.uid), {
          'uid': user.uid,
          'displayName': name,
          'email': email,
          'phone': phone,
          'role': 'staff',
          'hourlyRate': rate,
          'active': true,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        transaction.update(requestRef, {
          'status': 'Approved',
          'reviewedBy': reviewer,
          'reviewedAt': FieldValue.serverTimestamp(),
        });
      });
      committed = true;
    } catch (error) {
      if (!committed && createdUser != null) {
        try {
          await createdUser.delete();
        } catch (_) {
          throw StateError('Không hoàn tất duyệt và không thể xóa tài khoản '
              'Authentication vừa tạo. Admin cần kiểm tra Firebase Console.');
        }
      }
      rethrow;
    } finally {
      await secondaryAuth.signOut();
    }
  }

  /// Lấy phiên xác thực phụ phục vụ xử lý tài khoản.
  Future<FirebaseAuth> _secondaryAuth() =>
      _secondaryAuthFuture ??= _initSecondaryAuth();

  /// Chuẩn bị phiên xác thực phụ phục vụ xử lý tài khoản.
  Future<FirebaseAuth> _initSecondaryAuth() async {
    final auth = FirebaseAuth.instanceFor(app: await _provisioningApp());
    if (const bool.fromEnvironment('SOLEURE_FIRESTORE_EMULATOR')) {
      await auth.useAuthEmulator('127.0.0.1', 9099);
    }
    return auth;
  }

  /// Lấy hồ sơ nhân viên.
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

  /// Cập nhật tài khoản.
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

  /// Tạo tài khoản.
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

    final secondaryAuth = await _secondaryAuth();
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

  /// Kiểm tra vai trò có thuộc nhóm được quản lý hay không.
  bool _isManagedRole(String role) => role == 'manager' || role == 'staff';

  /// Kiểm tra định dạng email trước khi xử lý.
  bool _isValidEmail(String email) =>
      RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email);
}
