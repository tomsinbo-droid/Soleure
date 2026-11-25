// Công dụng tệp: Cài đặt hệ thống.

import '../core/constants/firebase_collections.dart';
import '../core/constants/app_defaults.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Firebase - nghiệp vụ settings
class SettingsService {
  late final FirebaseFirestore _db = FirebaseFirestore.instance;
  /// Lấy cài đặt.
  Future<Map<String, dynamic>> getSettings() async {
    final doc = await _db
        .collection(FirebaseCollections.settings)
        .doc(FirebaseCollections.storeSettingsDocument)
        .get();
    return doc.data() ?? Map.of(AppDefaults.settings);
  }

  /// Lưu cài đặt.
  Future<void> saveSettings(Map<String, dynamic> settings) async {
    await _db
        .collection(FirebaseCollections.settings)
        .doc(FirebaseCollections.storeSettingsDocument)
        .set(settings);
  }
}
