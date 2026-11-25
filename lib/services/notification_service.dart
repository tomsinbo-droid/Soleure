// Công dụng tệp: Thông báo.

import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/firebase_collections.dart';
import 'auth_service.dart';

/// In-app notifications stored in Firestore, not Firebase Cloud Messaging.
class NotificationService {
  final AuthService _auth = AuthService();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Lấy thông báo.
  Future<List<Map<String, dynamic>>> getNotifications() async {
    final uid = _auth.currentUid;
    if (uid == null) return [];
    final snap = await _db
        .collection(FirebaseCollections.notifications)
        .where('recipientUid', isEqualTo: uid)
        .limit(100)
        .get();
    final items = snap.docs
        .map((doc) => {'id': doc.id, ...doc.data()})
        .toList();
    items.sort((a, b) {
      final aTime = a['createdAt'] as Timestamp?;
      final bTime = b['createdAt'] as Timestamp?;
      return (bTime?.millisecondsSinceEpoch ?? 0).compareTo(
        aTime?.millisecondsSinceEpoch ?? 0,
      );
    });
    return items;
  }

  /// Đánh dấu thông báo đã đọc.
  Future<void> markRead(String id) async {
    await _db.collection(FirebaseCollections.notifications).doc(id).update({
      'readAt': FieldValue.serverTimestamp(),
    });
  }
}
