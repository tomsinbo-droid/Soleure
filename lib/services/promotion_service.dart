import '../core/constants/firebase_collections.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'auth_service.dart';

/// Firebase - nghiệp vụ promotion
class PromotionService {
  late final FirebaseFirestore _db = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();
  Future<List<Map<String, dynamic>>> getPromotions() async {
    final docs = await _db
        .collection(FirebaseCollections.promotions)
        .limit(200)
        .get();
    return docs.docs.map((e) => {'id': e.id, ...e.data()}).toList();
  }

  Future<List<Map<String, dynamic>>> getActivePromotions() async {
    final docs = await _db
        .collection(FirebaseCollections.promotions)
        .where('status', isEqualTo: 'Approved')
        .limit(200)
        .get();
    return docs.docs.map((e) => {'id': e.id, ...e.data()}).toList();
  }

  Future<void> proposePromotion(
    String name,
    String scope,
    int discount,
    DateTime start,
    DateTime end,
  ) async {
    if (name.trim().isEmpty ||
        scope.trim().isEmpty ||
        discount < 1 ||
        discount > 100 ||
        end.isBefore(start)) {
      throw StateError('Thông tin khuyến mãi chưa hợp lệ.');
    }

    await _db.collection(FirebaseCollections.promotions).add({
      'name': name.trim(),
      'scope': scope.trim(),
      'discount': discount,
      'startAt': Timestamp.fromDate(start),
      'endAt': Timestamp.fromDate(end),
      'proposerUid': _authService.currentUid,
      'status': 'Pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> reviewPromotion(String id, bool approved) async {
    await _db.collection(FirebaseCollections.promotions).doc(id).update({
      'status': approved ? 'Approved' : 'Rejected',
      'reviewedBy': _authService.currentUid,
      'reviewedAt': FieldValue.serverTimestamp(),
    });
  }
}
