// Công dụng tệp: Cài đặt hệ thống.

import '../services/settings_service.dart';

/// ViewModel rất nhỏ: chỉ chuyển thao tác đọc/ghi sang SettingsService.
class SettingsViewModel {
  final SettingsService _settingsService = SettingsService();

  /// Tải dữ liệu cài đặt hệ thống và cập nhật trạng thái tương ứng.
  Future<Map<String, dynamic>> load() => _settingsService.getSettings();

  /// Lưu cài đặt hệ thống.
  Future<void> save(Map<String, dynamic> values) =>
      _settingsService.saveSettings(values);
}
