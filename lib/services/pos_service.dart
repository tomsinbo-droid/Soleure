import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/firebase_collections.dart';
import '../models/cart_item.dart';
import '../models/user_role.dart';
import 'auth_service.dart';
import 'firestore_demo_guard.dart';

/// POS transactions update all involved Cloud Firestore documents atomically.
class PosService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  Future<void> saveOrderDraft(List<CartItem> cart, String? customerId) async {
    if (cart.isEmpty) throw StateError('Giỏ hàng trống.');
    final uid = await FirestoreDemoGuard.requireRole([
      'admin',
      'manager',
      'staff',
    ]);
    await _db.collection(FirebaseCollections.orderDrafts).add({
      'staffUid': uid,
      'customerId': customerId,
      'status': 'draft',
      'createdAt': FieldValue.serverTimestamp(),
      'items': cart
          .map(
            (item) => {
              'sku': item.product.sku,
              'name': item.product.name,
              'quantity': item.quantity,
              'unitPricePreview': item.product.sellingPrice,
            },
          )
          .toList(),
      'totalPreview': cart.fold<double>(0, (sum, item) => sum + item.lineTotal),
    });
  }

  String newSaleRequestId() =>
      _db.collection(FirebaseCollections.orders).doc().id;

  Future<Map<String, dynamic>> completeCashSale(
    List<CartItem> items,
    String? customerId,
    String requestId,
  ) => createOrder(
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
    paymentMethod: 'cash',
  );

  Future<Map<String, dynamic>> completeHoldCashSale(
    Map<String, dynamic> hold,
    String requestId,
  ) => createOrder(
    items: List<dynamic>.from(
      hold['items'] as List<dynamic>? ?? [],
    ).map((e) => Map<String, dynamic>.from(e as Map)).toList(),
    customerId: hold['customerId']?.toString(),
    requestId: requestId,
    holdId: hold['id']?.toString(),
    paymentMethod: 'cash',
  );

  Future<Map<String, dynamic>> createOrder({
    required List<Map<String, dynamic>> items,
    required String requestId,
    required String paymentMethod,
    String? customerId,
    String? holdId,
  }) async {
    final uid = await FirestoreDemoGuard.requireRole([
      'admin',
      'manager',
      'staff',
    ]);
    if (!['cash', 'qr'].contains(paymentMethod))
      throw StateError('Phương thức không hợp lệ.');
    if (items.isEmpty || items.length > 30 || requestId.isEmpty)
      throw StateError('Giỏ hàng không hợp lệ.');

    final quantities = <String, int>{};
    final selected = <String, List<String>>{};
    for (final item in items) {
      final sku = (item['sku'] ?? '').toString();
      final qty = FirestoreDemoGuard.integer(item['quantity']);
      final ids = (item['unitIds'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList();
      if (sku.isEmpty ||
          qty < 1 ||
          qty > 100 ||
          quantities.containsKey(sku) ||
          ids.toSet().length != ids.length ||
          ids.length > qty) {
        throw StateError('SKU trùng, mã xe trùng hoặc số lượng không hợp lệ.');
      }
      quantities[sku] = qty;
      selected[sku] = ids;
    }
    final sorted = quantities.keys.toList()..sort();
    final signature = jsonEncode([
      uid,
      paymentMethod,
      customerId,
      holdId,
      ...sorted.map(
        (sku) => [
          sku,
          quantities[sku],
          [...selected[sku]!]..sort(),
        ],
      ),
    ]);
    final orderRef = _db.collection(FirebaseCollections.orders).doc(requestId);
    final holdRef = holdId == null
        ? null
        : _db.collection(FirebaseCollections.holds).doc(holdId);
    final customerRef = customerId == null || customerId.isEmpty
        ? null
        : _db.collection(FirebaseCollections.customers).doc(customerId);
    return _db.runTransaction((tx) async {
      final order = await tx.get(orderRef);
      if (order.exists) {
        if (order.data()?['staffUid'] != uid ||
            order.data()?['requestSignature'] != signature) {
          throw StateError('Mã giao dịch đã được sử dụng cho nội dung khác.');
        }
        return {
          'id': requestId,
          'total': order.data()?['total'],
          'status': order.data()?['status'],
          'duplicate': true,
        };
      }
      final hold = holdRef != null ? await tx.get(holdRef) : null;
      if (holdRef != null) {
        final h = hold?.data();
        if (h == null ||
            h['status'] != 'Active' ||
            (FirestoreDemoGuard.date(
                  h['expiresAt'],
                )?.isBefore(DateTime.now()) ??
                true)) {
          throw StateError('Hold không còn hiệu lực.');
        }
        if (h['staffUid'] != uid || h['customerId'] != customerId) {
          throw StateError('Người bán hoặc khách không khớp Hold.');
        }
        final original = List<Map<String, dynamic>>.from(
          (h['items'] as List<dynamic>).map(
            (e) => Map<String, dynamic>.from(e as Map),
          ),
        );
        if (original.length != items.length ||
            original.any(
              (row) =>
                  quantities[row['sku']] != row['quantity'] ||
                  jsonEncode(row['unitIds'] ?? []) !=
                      jsonEncode(selected[row['sku']] ?? []),
            )) {
          throw StateError('Bill phải thanh toán đúng các item của Hold.');
        }
      }
      final settings = await tx.get(
        _db.collection(FirebaseCollections.settings).doc('store'),
      );
      final rateValue = (settings.data()?['commissionRate'] as num? ?? 0.05)
          .toDouble();
      final rate = rateValue >= 0 && rateValue <= 0.2 ? rateValue : 0.05;
      final products = <DocumentSnapshot<Map<String, dynamic>>>[];
      for (final sku in sorted) {
        products.add(
          await tx.get(_db.collection(FirebaseCollections.products).doc(sku)),
        );
      }
      final units = <DocumentSnapshot<Map<String, dynamic>>>[];
      for (final sku in sorted) {
        for (final unitId in selected[sku]!) {
          units.add(
            await tx.get(_db.collection(FirebaseCollections.units).doc(unitId)),
          );
        }
      }
      final customer = customerRef != null ? await tx.get(customerRef) : null;
      if (customerRef != null && !(customer?.exists ?? false))
        throw StateError('Khách không tồn tại.');
      for (final unit in units) {
        final u = unit.data();
        final sku = u?['sku']?.toString();
        if (u == null ||
            sku == null ||
            !(selected[sku]?.contains(unit.id) ?? false) ||
            (holdRef == null
                ? u['trackingStatus'] != 'Available'
                : u['trackingStatus'] != 'Held' || u['holdId'] != holdId)) {
          throw StateError('Mã xe đã bán hoặc không thuộc Hold.');
        }
      }
      final lines = <Map<String, dynamic>>[];
      var total = 0, totalCost = 0, eligibleTotal = 0;
      for (final p in products) {
        final data = p.data();
        if (data == null) throw StateError('SKU ${p.id} không tồn tại.');
        final qty = quantities[p.id]!;
        final stock = FirestoreDemoGuard.integer(data['stock']);
        final held = FirestoreDemoGuard.integer(data['heldStock']);
        if ((holdRef != null
                ? stock >= qty && held >= qty
                : stock - held >= qty) ==
            false) {
          throw StateError('SKU ${p.id} không đủ tồn.');
        }
        final discount = ((data['promoPercent'] as num? ?? 0).toDouble()).clamp(
          0,
          100,
        );
        final price =
            ((data['price'] as num? ?? 0).toDouble() * (1 - discount / 100))
                .round();
        final cost = FirestoreDemoGuard.integer(data['cost']);
        if (price < 0 || cost < 0)
          throw StateError('Giá bán hoặc giá vốn không hợp lệ.');
        final subtotal = price * qty;
        total += subtotal;
        totalCost += cost * qty;
        if (data['kpiEligible'] == true) eligibleTotal += subtotal;
        lines.add({
          'sku': p.id,
          'name': data['name'],
          'quantity': qty,
          'unitPrice': price,
          'unitCost': cost,
          'lineTotal': subtotal,
          'kpiEligible': data['kpiEligible'] == true,
          'promotionPercent': discount,
          'unitIds': selected[p.id],
        });
      }
      final commission = (eligibleTotal * rate).round();
      for (final p in products) {
        final qty = quantities[p.id]!;
        tx.update(p.reference, {
          if (paymentMethod == 'cash') 'stock': FieldValue.increment(-qty),
          if (paymentMethod == 'qr') 'heldStock': FieldValue.increment(qty),
          if (holdRef != null) 'heldStock': FieldValue.increment(-qty),
        });
      }
      for (final unit in units) {
        tx.update(
          unit.reference,
          paymentMethod == 'cash'
              ? {
                  'trackingStatus': 'Sold',
                  'holdId': FieldValue.delete(),
                  'soldOrderId': requestId,
                  'soldAt': FieldValue.serverTimestamp(),
                }
              : {'trackingStatus': 'HeldQr', 'reservedOrderId': requestId},
        );
      }
      if (holdRef != null) {
        if (paymentMethod != 'cash')
          throw StateError('QR từ Hold chưa được hỗ trợ.');
        tx.update(holdRef, {
          'status': 'Sold',
          'orderId': requestId,
          'closedAt': FieldValue.serverTimestamp(),
        });
      }
      if (paymentMethod == 'cash' && customerRef != null) {
        tx.update(customerRef, {
          'totalSpend': FieldValue.increment(total),
          'lastPurchase': DateTime.now().toIso8601String().substring(0, 10),
        });
      }
      tx.set(orderRef, {
        'status': paymentMethod == 'cash' ? 'Paid' : 'PendingQr',
        'paymentMethod': paymentMethod,
        'paymentVerification': 'Pending',
        'staffUid': uid,
        'customerId': customerId,
        'holdId': holdId,
        'items': lines,
        'total': total,
        'totalCost': totalCost,
        'eligibleTotal': eligibleTotal,
        'commission': commission,
        'commissionRate': rate,
        'refundedTotal': 0,
        'costReversed': 0,
        'requestSignature': signature,
        if (paymentMethod == 'qr')
          'expiresAt': Timestamp.fromDate(
            DateTime.now().add(const Duration(minutes: 20)),
          ),
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (paymentMethod == 'cash') {
        tx.set(_db.collection(FirebaseCollections.commissions).doc(requestId), {
          'orderId': requestId,
          'staffUid': uid,
          'amount': commission,
          'eligibleSales': eligibleTotal,
          'commissionRate': rate,
          'type': 'sale',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      return {
        'id': requestId,
        'total': total,
        'commission': commission,
        'status': paymentMethod == 'cash' ? 'Paid' : 'PendingQr',
        'duplicate': false,
      };
    });
  }

  Future<List<Map<String, dynamic>>> getOrders() async {
    final session = await _authService.getCurrentSession();
    final q = _db.collection(FirebaseCollections.orders);
    final docs = session?.role == UserRole.staff
        ? await q
              .where('staffUid', isEqualTo: _authService.currentUid)
              .limit(300)
              .get()
        : await q.limit(300).get();
    return docs.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  }
}
