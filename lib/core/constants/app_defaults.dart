// Công dụng tệp: Khai báo các giá trị mặc định.

/// Giá trị mặc định chỉ dùng khi Firestore chưa có cấu hình cửa hàng.
abstract final class AppDefaults {
  static const double commissionRate = 0.05;
  static const int holdMinutes = 30;
  static const int hourlyRateDefault = 28000;
  static const int maxWeeklyHours = 48;

  static const Map<String, dynamic> settings = {
    'commissionRate': commissionRate,
    'holdMinutes': holdMinutes,
    'hourlyRateDefault': hourlyRateDefault,
    'maxWeeklyHours': maxWeeklyHours,
  };
}
