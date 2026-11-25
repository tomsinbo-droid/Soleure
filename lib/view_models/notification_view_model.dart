// Công dụng tệp: Thông báo.

import '../services/notification_service.dart';

class NotificationViewModel {
  final NotificationService _service = NotificationService();
  List<Map<String, dynamic>> notifications = [];
  int get unreadCount => notifications.where((n) => n['isRead'] != true).length;

  /// Tải dữ liệu thông báo và cập nhật trạng thái tương ứng.
  Future<void> load() async {
    notifications = await _service.getNotifications();
  }

  /// Đánh dấu thông báo đã đọc.
  Future<void> markRead(String id) async {
    await _service.markRead(id);
    await load();
  }
}
