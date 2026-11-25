// Công dụng tệp: Thanh toán QR.

import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/firebase_collections.dart';
import '../models/cart_item.dart';
import 'firestore_demo_guard.dart';
import 'pos_service.dart';

/// QR payment state is stored in Cloud Firestore.
class PaymentService {
  final PosService _posService = PosService();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Tạo giao dịch QR.
  Future<Map<String, dynamic>> createQrPayment(
    List<CartItem> items,
    String? customerId,
    String requestId,
  ) => _posService.createOrder(
    items: items
        .map(
          (e) => {
            'sku': e.product.sku,
            'quantity': e.quantity,
            'unitIds': List<String>.from(e.unitIds),
          },
        )
        .toList(),
    customerId: customerId,
    requestId: requestId,
    paymentMethod: 'qr',
  );

  /// Lấy các giao dịch QR đang chờ.
  Future<List<Map<String, dynamic>>> getPendingQr() async {
    await expirePendingQr();
    final orders = await _posService.getOrders();
    return orders.where((row) => row['status'] == 'PendingQr').toList();
  }

  /// Xác nhận giao dịch QR.
  Future<void> confirmQrPayment(
    String id,
    String bankTransactionId,
    int paidAmount,
  ) async {
    final uid = await FirestoreDemoGuard.requireRole(['admin', 'manager']);
    if (bankTransactionId.trim().isEmpty || paidAmount < 0) {
      throw StateError('Mã giao dịch và số tiền không hợp lệ.');
    }
    final ref = _db.collection(FirebaseCollections.orders).doc(id);
    await _db.runTransaction((tx) async {
      final order = await tx.get(ref);
      final data = order.data();
      if (data == null ||
          data['status'] != 'PendingQr' ||
          FirestoreDemoGuard.date(
                data['expiresAt'],
              )?.isBefore(DateTime.now()) !=
              false ||
          FirestoreDemoGuard.integer(data['total']) != paidAmount) {
        throw StateError('Hóa đơn QR không còn hợp lệ.');
      }
      final items = List<Map<String, dynamic>>.from(
        (data['items'] as List<dynamic>).map(
          (e) => Map<String, dynamic>.from(e as Map),
        ),
      );
      final products = <DocumentSnapshot<Map<String, dynamic>>>[];
      for (final line in items) {
        products.add(
          await tx.get(
            _db
                .collection(FirebaseCollections.products)
                .doc(line['sku'].toString()),
          ),
        );
      }
      final units = <DocumentSnapshot<Map<String, dynamic>>>[];
      for (final line in items) {
        for (final unitId in line['unitIds'] as List<dynamic>? ?? []) {
          units.add(
            await tx.get(
              _db.collection(FirebaseCollections.units).doc(unitId.toString()),
            ),
          );
        }
      }
      final customerId = data['customerId']?.toString();
      final customerRef = customerId != null
          ? _db.collection(FirebaseCollections.customers).doc(customerId)
          : null;
      final customer = customerRef != null ? await tx.get(customerRef) : null;
      for (var i = 0; i < items.length; i++) {
        final qty = FirestoreDemoGuard.integer(items[i]['quantity']);
        if (!products[i].exists ||
            FirestoreDemoGuard.integer(products[i].data()?['stock']) < qty ||
            FirestoreDemoGuard.integer(products[i].data()?['heldStock']) <
                qty) {
          throw StateError('Tồn đã giữ không nhất quán.');
        }
      }
      for (final unit in units) {
        if (unit.data()?['trackingStatus'] != 'HeldQr' ||
            unit.data()?['reservedOrderId'] != id) {
          throw StateError('Mã xe không thuộc đơn QR.');
        }
      }
      for (var i = 0; i < items.length; i++) {
        final qty = FirestoreDemoGuard.integer(items[i]['quantity']);
        tx.update(products[i].reference, {
          'stock': FieldValue.increment(-qty),
          'heldStock': FieldValue.increment(-qty),
        });
      }
      for (final unit in units)
        tx.update(unit.reference, {
          'trackingStatus': 'Sold',
          'reservedOrderId': FieldValue.delete(),
          'soldOrderId': id,
          'soldAt': FieldValue.serverTimestamp(),
        });
      if (customer?.exists == true && customerRef != null) {
        tx.update(customerRef, {
          'totalSpend': FieldValue.increment(paidAmount),
        });
      }
      tx.update(ref, {
        'status': 'Paid',
        'paymentVerification': 'ManualConfirmation',
        'bankTransactionId': bankTransactionId.trim(),
        'confirmedAmount': paidAmount,
        'verifiedBy': uid,
        'paidAt': FieldValue.serverTimestamp(),
      });
      tx.set(_db.collection(FirebaseCollections.commissions).doc(id), {
        'orderId': id,
        'staffUid': data['staffUid'],
        'amount': data['commission'],
        'eligibleSales': data['eligibleTotal'],
        'commissionRate': data['commissionRate'],
        'type': 'sale',
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// No Cloud Scheduler on Spark: cleanup is opportunistic when the POS opens.
  Future<void> expirePendingQr() async {
    final uid = await FirestoreDemoGuard.requireRole([
      'admin',
      'manager',
      'staff',
    ]);
    final profile = await _db
        .collection(FirebaseCollections.users)
        .doc(uid)
        .get();
    final pendingOrders = _db
        .collection(FirebaseCollections.orders)
        .where('status', isEqualTo: 'PendingQr');
    // Firestore evaluates rules against the query, not the post-filtered
    // result. Staff may only read their own orders, so include that constraint.
    final rows = profile.data()?['role'] == 'staff'
        ? await pendingOrders.where('staffUid', isEqualTo: uid).limit(100).get()
        : await pendingOrders.limit(100).get();
    for (final row in rows.docs) {
      final end = FirestoreDemoGuard.date(row.data()['expiresAt']);
      if (end != null && end.isBefore(DateTime.now())) {
        await _releaseQr(row.id, expired: true);
      }
    }
  }

  /// Hủy giao dịch QR.
  Future<void> cancelQrPayment(String id) async {
    await FirestoreDemoGuard.requireRole(['admin', 'manager', 'staff']);
    await _releaseQr(id, expired: false);
  }

  /// Giải phóng giao dịch QR.
  Future<void> _releaseQr(String id, {required bool expired}) async {
    final uid = await FirestoreDemoGuard.requireRole([
      'admin',
      'manager',
      'staff',
    ]);
    final ref = _db.collection(FirebaseCollections.orders).doc(id);
    await _db.runTransaction((tx) async {
      final order = await tx.get(ref);
      final data = order.data();
      if (data == null || data['status'] != 'PendingQr') return;
      final owner = data['staffUid'];
      if (owner != uid) {
        final profile = await tx.get(
          _db.collection(FirebaseCollections.users).doc(uid),
        );
        if (!['admin', 'manager'].contains(profile.data()?['role']) &&
            !expired) {
          throw StateError('Chỉ người tạo hoặc Manager được hủy đơn QR.');
        }
      }
      if (expired &&
          (FirestoreDemoGuard.date(
                data['expiresAt'],
              )?.isAfter(DateTime.now()) ??
              true))
        return;
      final lines = List<Map<String, dynamic>>.from(
        (data['items'] as List<dynamic>).map(
          (e) => Map<String, dynamic>.from(e as Map),
        ),
      );
      final products = <DocumentSnapshot<Map<String, dynamic>>>[];
      final units = <DocumentSnapshot<Map<String, dynamic>>>[];
      for (final line in lines) {
        products.add(
          await tx.get(
            _db
                .collection(FirebaseCollections.products)
                .doc(line['sku'].toString()),
          ),
        );
        for (final unitId in line['unitIds'] as List<dynamic>? ?? []) {
          units.add(
            await tx.get(
              _db.collection(FirebaseCollections.units).doc(unitId.toString()),
            ),
          );
        }
      }
      for (var i = 0; i < lines.length; i++) {
        final quantity = FirestoreDemoGuard.integer(lines[i]['quantity']);
        if (FirestoreDemoGuard.integer(products[i].data()?['heldStock']) <
            quantity) {
          throw StateError('Không đủ tồn đang giữ để giải phóng QR.');
        }
      }
      for (final unit in units) {
        if (unit.data()?['trackingStatus'] != 'HeldQr' ||
            unit.data()?['reservedOrderId'] != id) {
          throw StateError('Mã xe không thuộc đơn QR.');
        }
      }
      for (var i = 0; i < lines.length; i++) {
        tx.update(products[i].reference, {
          'heldStock': FieldValue.increment(
            -FirestoreDemoGuard.integer(lines[i]['quantity']),
          ),
        });
      }
      for (final unit in units)
        tx.update(unit.reference, {
          'trackingStatus': 'Available',
          'reservedOrderId': FieldValue.delete(),
        });
      tx.update(ref, {
        'status': expired ? 'Expired' : 'Cancelled',
        'closedAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
