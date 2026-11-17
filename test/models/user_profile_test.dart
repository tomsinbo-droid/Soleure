import 'package:flutter_test/flutter_test.dart';
import 'package:app_project/models/staff_member.dart';
import 'package:app_project/models/user_profile.dart';
import 'package:app_project/models/user_role.dart';

void main() {
  test('UserProfile đọc tên, email, vai trò trong cùng một document', () {
    final profile = UserProfile.fromMap('uid-001', {
      'displayName': 'Nhân viên mẫu',
      'email': 'staff@example.com',
      'phone': '0900000000',
      'role': 'staff',
      'hourlyRate': 30000,
      'active': true,
    });
    expect(profile.uid, 'uid-001');
    expect(profile.displayName, 'Nhân viên mẫu');
    expect(profile.email, 'staff@example.com');
    expect(profile.phone, '0900000000');
    expect(profile.role, UserRole.staff);
    expect(profile.hourlyRate, 30000);
    final row = StaffMember.fromProfile(profile, 200000);
    expect(row.name, 'Nhân viên mẫu');
    expect(row.role, 'Staff');
    expect(row.sales, 200000);
  });

  test('Hồ sơ cũ thiếu email và role không tự được cấp quyền', () {
    final profile = UserProfile.fromMap('uid-old', {
      'displayName': 'Tài khoản cũ',
      'active': false,
    });
    expect(profile.email, '');
    expect(profile.role, isNull);
    expect(profile.active, isFalse);
  });
}
