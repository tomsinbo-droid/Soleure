import '../core/constants/firebase_collections.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'auth_service.dart';

/// Firebase - nghiệp vụ finance
class FinanceService {
  late final FirebaseFirestore _db = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();
  Future<List<Map<String, dynamic>>> getExpenses() async {
    final docs = await _db
        .collection(FirebaseCollections.expenses)
        .limit(200)
        .get();
    return docs.docs.map((e) => {'id': e.id, ...e.data()}).toList();
  }

  Future<void> addExpense(String name, String category, int amount) async {
    if (name.trim().isEmpty || amount < 0)
      throw StateError('Chi phí chưa hợp lệ.');

    await _db.collection(FirebaseCollections.expenses).add({
      'name': name.trim(),
      'category': category,
      'amount': amount,
      'createdBy': _authService.currentUid,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
