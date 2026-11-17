import '../services/settings_service.dart';

/// ViewModel rất nhỏ: chỉ chuyển thao tác đọc/ghi sang SettingsService.
class SettingsViewModel {
  final SettingsService _settingsService = SettingsService();

  Future<Map<String, dynamic>> load() => _settingsService.getSettings();

  Future<void> save(Map<String, dynamic> values) =>
      _settingsService.saveSettings(values);
}
