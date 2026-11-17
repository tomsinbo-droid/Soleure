import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/firebase_collections.dart';
import '../core/utils/id_helper.dart';
import 'firestore_demo_guard.dart';

class SupplierService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> getSuppliers() async {
    final result = await _db
        .collection(FirebaseCollections.suppliers)
        .limit(200)
        .get();
    return result.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  Future<void> saveSupplier(
    String name,
    String phone,
    String email,
    String note,
  ) async {
    if (name.trim().isEmpty) throw StateError('Chưa nhập tên nhà cung cấp.');
    final uid = await FirestoreDemoGuard.requireRole(['admin', 'manager']);
    await _db
        .collection(FirebaseCollections.suppliers)
        .doc(IdHelper.newId('SUP'))
        .set({
          'name': name.trim(),
          'phone': phone.trim(),
          'email': email.trim(),
          'note': note.trim(),
          'active': true,
          'createdBy': uid,
          'createdAt': FieldValue.serverTimestamp(),
        });
  }

  Future<void> deactivateSupplier(String id) async {
    await FirestoreDemoGuard.requireRole(['admin', 'manager']);
    await _db.collection(FirebaseCollections.suppliers).doc(id).update({
      'active': false,
    });
  }
}
