// Công dụng tệp: Hao hụt và hư hỏng.

import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/firebase_collections.dart';
import 'auth_service.dart';
import 'firestore_demo_guard.dart';

class DamageService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  /// Lấy các biên bản hao hụt.
  Future<List<Map<String, dynamic>>> getDamageReports() async {
    final result = await _db
        .collection(FirebaseCollections.damages)
        .limit(200)
        .get();
    return result.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  }

  /// Tạo biên bản hao hụt.
  Future<String> createDamageReport(
    String sku,
    String reason,
    int quantity,
    int loss,
  ) async {
    if (sku.isEmpty || reason.trim().isEmpty || quantity < 1 || loss < 0) {
      throw StateError('Biên bản chưa hợp lệ.');
    }
    await FirestoreDemoGuard.requireRole(['admin', 'manager']);
    final doc = await _db.collection(FirebaseCollections.damages).add({
      'sku': sku,
      'reason': reason,
      'quantity': quantity,
      'loss': loss,
      'status': 'Pending',
      'reportedBy': _authService.currentUid,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  /// Tải lên ảnh biên bản hao hụt.
  Future<void> uploadDamagePhoto(
    String id,
    Uint8List bytes,
    String fileName,
  ) async {
    if (bytes.isEmpty || bytes.lengthInBytes > 600 * 1024) {
      throw StateError('Ảnh phải nhỏ hơn 600 KB.');
    }
    final name = fileName.toLowerCase();
    final mime = name.endsWith('.png')
        ? 'image/png'
        : name.endsWith('.webp')
        ? 'image/webp'
        : name.endsWith('.jpg') || name.endsWith('.jpeg')
        ? 'image/jpeg'
        : '';
    if (mime.isEmpty) throw StateError('Chỉ nhận PNG/JPEG/WEBP.');
    await _db.collection(FirebaseCollections.damages).doc(id).update({
      'imageBase64': base64Encode(bytes),
      'imageMime': mime,
    });
  }

  /// Lấy ảnh biên bản hao hụt.
  Future<Uint8List?> getDamagePhoto(String id) async {
    final doc = await _db.collection(FirebaseCollections.damages).doc(id).get();
    final value = doc.data()?['imageBase64'];
    return value is String && value.isNotEmpty ? base64Decode(value) : null;
  }

  /// Xem xét và xử lý hao hụt.
  Future<void> reviewDamage(String id, bool approved) async {
    final uid = await FirestoreDemoGuard.requireRole(['admin', 'manager']);
    final ref = _db.collection(FirebaseCollections.damages).doc(id);
    await _db.runTransaction((tx) async {
      final damage = await tx.get(ref);
      if (!damage.exists || damage.data()?['status'] != 'Pending')
        throw StateError('Biên bản không còn chờ duyệt.');
      final p = await tx.get(
        _db
            .collection(FirebaseCollections.products)
            .doc(damage.data()!['sku'].toString()),
      );
      if (approved) {
        final qty = FirestoreDemoGuard.integer(damage.data()?['quantity']);
        final stock = FirestoreDemoGuard.integer(p.data()?['stock']);
        final held = FirestoreDemoGuard.integer(p.data()?['heldStock']);
        if (!p.exists || stock - held < qty)
          throw StateError('Không đủ tồn để ghi hao hụt.');
        tx.update(p.reference, {'stock': stock - qty});
        tx.set(
          _db.collection(FirebaseCollections.stockMovements).doc('DAMAGE_$id'),
          {
            'sku': p.id,
            'type': 'DAMAGE',
            'quantity': -qty,
            'stockBefore': stock,
            'stockAfter': stock - qty,
            'unitCost': p.data()?['cost'] ?? 0,
            'sourceId': id,
            'createdBy': uid,
            'createdAt': FieldValue.serverTimestamp(),
          },
        );
      }
      tx.update(ref, {
        'status': approved ? 'Approved' : 'Rejected',
        'actualLoss': approved ? (damage.data()?['loss'] ?? 0) : 0,
        'reviewedBy': uid,
        'reviewedAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
