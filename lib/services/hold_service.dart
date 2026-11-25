// Công dụng tệp: Giữ hàng.

import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/firebase_collections.dart';
import '../models/cart_item.dart';
import 'firestore_demo_guard.dart';

class HoldService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Lấy danh sách phiếu giữ hàng.
  Future<List<Map<String, dynamic>>> getHolds() async {
    await expireHolds();
    final docs = await _db
        .collection(FirebaseCollections.holds)
        .limit(200)
        .get();
    return docs.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  }

  /// Tạo phiếu giữ hàng.
  Future<String> createHold(List<CartItem> items, String? customerId) async {
    final uid = await FirestoreDemoGuard.requireRole([
      'admin',
      'manager',
      'staff',
    ]);
    if (items.isEmpty) throw StateError('Giỏ hàng trống.');
    if (items.map((e) => e.product.sku).toSet().length != items.length ||
        items.expand((e) => e.unitIds).toSet().length !=
            items.fold<int>(0, (sum, e) => sum + e.unitIds.length)) {
      throw StateError('SKU hoặc mã xe bị trùng trong giỏ Hold.');
    }
    final ref = _db.collection(FirebaseCollections.holds).doc();
    final settings = _db.collection(FirebaseCollections.settings).doc('store');
    await _db.runTransaction((tx) async {
      final config = await tx.get(settings);
      final duration = FirestoreDemoGuard.integer(
        config.data()?['holdMinutes'],
      );
      final minutes = duration >= 1 && duration <= 120 ? duration : 30;
      final products = <DocumentSnapshot<Map<String, dynamic>>>[];
      for (final item in items) {
        products.add(
          await tx.get(
            _db.collection(FirebaseCollections.products).doc(item.product.sku),
          ),
        );
      }
      final units = <DocumentSnapshot<Map<String, dynamic>>>[];
      for (final item in items) {
        if (item.quantity < 1 || item.unitIds.length > item.quantity)
          throw StateError('Số lượng/mã xe không hợp lệ.');
        for (final id in item.unitIds) {
          units.add(
            await tx.get(_db.collection(FirebaseCollections.units).doc(id)),
          );
        }
      }
      for (var i = 0; i < items.length; i++) {
        final p = products[i];
        final data = p.data();
        if (data == null ||
            FirestoreDemoGuard.integer(data['stock']) -
                    FirestoreDemoGuard.integer(data['heldStock']) <
                items[i].quantity) {
          throw StateError(
            'SKU ${items[i].product.sku} không đủ tồn khả dụng.',
          );
        }
      }
      for (final unit in units) {
        final sku = unit.data()?['sku'];
        if (!unit.exists ||
            unit.data()?['trackingStatus'] != 'Available' ||
            !items.any(
              (i) => i.product.sku == sku && i.unitIds.contains(unit.id),
            )) {
          throw StateError('Mã xe không còn khả dụng.');
        }
      }
      for (var i = 0; i < items.length; i++) {
        final p = products[i];
        tx.update(p.reference, {
          'heldStock': FieldValue.increment(items[i].quantity),
        });
      }
      for (final unit in units)
        tx.update(unit.reference, {'trackingStatus': 'Held', 'holdId': ref.id});
      tx.set(ref, {
        'staffUid': uid,
        'customerId': customerId,
        'status': 'Active',
        'items': items
            .map(
              (e) => {
                'sku': e.product.sku,
                'quantity': e.quantity,
                'unitIds': List<String>.from(e.unitIds),
              },
            )
            .toList(),
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(
          DateTime.now().add(Duration(minutes: minutes)),
        ),
      });
    });
    return ref.id;
  }

  /// Hủy phiếu giữ hàng.
  Future<void> cancelHold(String id) async {
    final uid = await FirestoreDemoGuard.requireRole([
      'admin',
      'manager',
      'staff',
    ]);
    final ref = _db.collection(FirebaseCollections.holds).doc(id);
    await _db.runTransaction((tx) async {
      final hold = await tx.get(ref);
      final data = hold.data();
      if (data == null) throw StateError('Không tìm thấy Hold.');
      if (data['staffUid'] != uid) {
        final profile = await tx.get(
          _db.collection(FirebaseCollections.users).doc(uid),
        );
        if (!['admin', 'manager'].contains(profile.data()?['role']))
          throw StateError('Không có quyền hủy Hold.');
      }
      if (data['status'] != 'Active') throw StateError('Hold đã đóng.');
      final items = List<dynamic>.from(data['items'] as List<dynamic>? ?? []);
      final products = <DocumentSnapshot<Map<String, dynamic>>>[];
      final units = <DocumentSnapshot<Map<String, dynamic>>>[];
      for (final item in items) {
        final row = Map<String, dynamic>.from(item as Map);
        products.add(
          await tx.get(
            _db
                .collection(FirebaseCollections.products)
                .doc(row['sku'].toString()),
          ),
        );
        for (final unitId in List<dynamic>.from(
          row['unitIds'] as List<dynamic>? ?? [],
        )) {
          units.add(
            await tx.get(
              _db.collection(FirebaseCollections.units).doc(unitId.toString()),
            ),
          );
        }
      }
      for (var i = 0; i < items.length; i++) {
        final quantity = FirestoreDemoGuard.integer(
          (items[i] as Map)['quantity'],
        );
        if (FirestoreDemoGuard.integer(products[i].data()?['heldStock']) <
            quantity) {
          throw StateError('Tồn hàng đang giữ không nhất quán.');
        }
        tx.update(products[i].reference, {
          'heldStock': FieldValue.increment(-quantity),
        });
      }
      for (final unit in units) {
        if (unit.data()?['holdId'] != id ||
            unit.data()?['trackingStatus'] != 'Held') {
          throw StateError('Mã xe không thuộc Hold này.');
        }
        tx.update(unit.reference, {
          'trackingStatus': 'Available',
          'holdId': FieldValue.delete(),
        });
      }
      final expiry = FirestoreDemoGuard.date(data['expiresAt']);
      tx.update(ref, {
        'status': expiry != null && expiry.isBefore(DateTime.now())
            ? 'Expired'
            : 'Cancelled',
        'closedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Release expired holds opportunistically (there is no server scheduler).
  /// A Staff member can release their own hold; Manager/Admin can release all.
  Future<void> expireHolds() async {
    final uid = await FirestoreDemoGuard.requireRole([
      'admin',
      'manager',
      'staff',
    ]);
    final profile = await _db
        .collection(FirebaseCollections.users)
        .doc(uid)
        .get();
    final manager = ['admin', 'manager'].contains(profile.data()?['role']);
    final docs = await _db
        .collection(FirebaseCollections.holds)
        .where('status', isEqualTo: 'Active')
        .limit(100)
        .get();
    for (final doc in docs.docs) {
      final expires = FirestoreDemoGuard.date(doc.data()['expiresAt']);
      if ((manager || doc.data()['staffUid'] == uid) &&
          expires != null &&
          expires.isBefore(DateTime.now())) {
        await cancelHold(doc.id);
      }
    }
  }
}
