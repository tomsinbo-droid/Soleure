import 'user_profile.dart';
import 'user_role.dart';

class StaffMember {
  const StaffMember({
    required this.id,
    required this.name,
    this.email="",
    this.password="",
    required this.role,
    required this.phone,
    required this.hourlyRate,
    required this.status,
    required this.sales,
  });

  final String id;
  final String name;
  final String email;
  final String password;
  final String role;
  final String phone;
  final double hourlyRate;
  final String status;
  final double sales;

  /// Hiển thị profile trong bảng Nhân sự. Không cần một bảng role riêng.
  factory StaffMember.fromProfile(UserProfile profile, double monthlySales) {
    return StaffMember(
      id: profile.uid,
      name: profile.displayName.isEmpty ? profile.uid : profile.displayName,
      email: profile.email,
      password: profile.password,
      role: profile.role?.label ?? 'Chưa cấp quyền',
      phone: profile.phone.isEmpty ? '-' : profile.phone,
      hourlyRate: profile.hourlyRate,
      status: profile.active ? 'Active' : 'Inactive',
      sales: monthlySales,
    );
  }
}
