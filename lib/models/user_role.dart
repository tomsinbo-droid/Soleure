enum UserRole { admin, manager, staff }

extension UserRoleLabel on UserRole {
  String get label {
    if (this == UserRole.admin) return 'Admin';
    if (this == UserRole.manager) return 'Manager';
    return 'Staff';
  }

  String get description {
    if (this == UserRole.admin) return 'Chủ cửa hàng';
    if (this == UserRole.manager) return 'Quản lý cửa hàng';
    return 'Nhân viên part-time';
  }

  static UserRole? fromFirestore(String? role) {
    if (role == 'admin') return UserRole.admin;
    if (role == 'manager') return UserRole.manager;
    if (role == 'staff') return UserRole.staff;
    return null;
  }
}
