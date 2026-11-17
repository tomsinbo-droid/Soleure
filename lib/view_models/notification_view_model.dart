import '../services/notification_service.dart';

class NotificationViewModel {
  final NotificationService _service = NotificationService();
  List<Map<String, dynamic>> notifications = [];
  int get unreadCount => notifications.where((n) => n['isRead'] != true).length;

  Future<void> load() async {
    notifications = await _service.getNotifications();
  }

  Future<void> markRead(String id) async {
    await _service.markRead(id);
    await load();
  }
}
