// Công dụng tệp: Biểu diễn hồ sơ tài khoản.

import 'user_role.dart';

/// Một tài khoản = một document Firestore: users/{uid}.
/// Thông tin và role nằm chung trong document này.
/// Firebase Authentication chỉ quản lý việc đăng nhập.
class UserProfile {
  const UserProfile({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.phone,
    required this.role,
    required this.hourlyRate,
    required this.active,
  });

  final String uid;
  final String displayName;
  final String email;
  final String phone;
  final UserRole? role;
  final double hourlyRate;
  final bool active;

  /// Tạo đối tượng từ mã định danh và dữ liệu bản đồ.
  factory UserProfile.fromMap(String uid, Map<String, dynamic> data) {
    return UserProfile(
      uid: uid,
      displayName: data['displayName']?.toString() ?? '',
      email: data['email']?.toString() ?? '',
      phone: data['phone']?.toString() ?? '',
      role: UserRoleLabel.fromFirestore(data['role']?.toString()),
      hourlyRate: (data['hourlyRate'] as num? ?? 0).toDouble(),
      active: data['active'] != false,
    );
  }

  // Cố ý không cung cấp toMap() ghi trực tiếp role/hourlyRate từ app.
  // Thay đổi quyền và mức lương phải đi qua backend Admin.
}
