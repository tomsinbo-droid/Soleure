import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/firebase_collections.dart';
import '../models/user_role.dart';
import 'auth_service.dart';
import 'firestore_demo_guard.dart';

class ReturnService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  Future<List<Map<String, dynamic>>> getReturns() async {
    final session = await _authService.getCurrentSession();
    final collection = _db.collection(FirebaseCollections.returns);
    final docs = session?.role == UserRole.staff
        ? await collection
              .where('staffUid', isEqualTo: _authService.currentUid)
              .limit(200)
              .get()
        : await collection.limit(200).get();
    return docs.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  }

  /// Returns all paid orders that can be selected as a return source.
  Future<List<Map<String, dynamic>>> getReturnableOrders() async {
    final session = await _authService.getCurrentSession();
    if (session?.role == null) {
      throw StateError('Tài khoản không được cấp quyền.');
    }

    final docs = await _db
        .collection(FirebaseCollections.orders)
        .where('status', isEqualTo: 'Paid')
        .limit(200)
        .get();
    return docs.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  }

  Future<void> requestReturn({
    required String orderId,
    required String sku,
    required int quantity,
    required String type,
    required String reason,
    String? replacementSku,
    List<String> unitIds = const [],
    List<String> replacementUnitIds = const [],
  }) async {
    final uid = await FirestoreDemoGuard.requireRole([
      'admin',
      'manager',
      'staff',
    ]);
    if (orderId.isEmpty ||
        sku.isEmpty ||
        reason.trim().isEmpty ||
        quantity < 1 ||
        !['Return', 'Exchange'].contains(type))
      throw StateError('Phiếu đổi trả không hợp lệ.');
    if (unitIds.length > quantity ||
        replacementUnitIds.length > quantity ||
        replacementUnitIds.toSet().length != replacementUnitIds.length ||
        unitIds.toSet().length != unitIds.length) {
      throw StateError('Danh sách mã xe không hợp lệ.');
    }
    if (type == 'Exchange' &&
        (replacementSku == null || replacementSku == sku)) {
      throw StateError('Chọn một SKU thay thế khác.');
    }
    final orderRef = _db.collection(FirebaseCollections.orders).doc(orderId);
    final returnRef = _db
        .collection(FirebaseCollections.returns)
        .doc('${orderId}_$sku');
    await _db.runTransaction((tx) async {
      final order = await tx.get(orderRef);
      final previous = await tx.get(returnRef);
      if (previous.exists || order.data()?['status'] != 'Paid') {
        throw StateError('Bill không hợp lệ hoặc đã gửi phiếu.');
      }
      final items = List<dynamic>.from(
        order.data()?['items'] as List<dynamic>? ?? [],
      );
      final matches = items.where((e) => (e as Map)['sku'] == sku).toList();
      if (matches.isEmpty ||
          FirestoreDemoGuard.integer((matches.first as Map)['quantity']) <
              quantity) {
        throw StateError('SKU/số lượng vượt bill gốc.');
      }
      final item = Map<String, dynamic>.from(matches.first as Map);
      final originalUnits = List<String>.from(
        item['unitIds'] as List<dynamic>? ?? [],
      );
      if (unitIds.any((id) => !originalUnits.contains(id)) ||
          unitIds.toSet().length != unitIds.length) {
        throw StateError('Mã xe không có trong bill.');
      }
      final untracked =
          FirestoreDemoGuard.integer(item['quantity']) - originalUnits.length;
      if (unitIds.length < quantity - untracked)
        throw StateError('Cần chọn mã xe thuộc bill gốc.');
      tx.set(returnRef, {
        'orderId': orderId,
        'sku': sku,
        'quantity': quantity,
        'type': type,
        'reason': reason.trim(),
        'status': 'Pending',
        'staffUid': uid,
        'replacementSku': replacementSku,
        'unitIds': unitIds,
        'replacementUnitIds': replacementUnitIds,
        'paymentMethod': order.data()?['paymentMethod'],
        'expectedRefundAmount': type == 'Return'
            ? FirestoreDemoGuard.integer(item['unitPrice']) * quantity
            : 0,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> settleReturn(
    String id, {
    required bool restockable,
    String? replacementSku,
    String? bankRefundId,
    int? bankRefundAmount,
  }) async {
    final uid = await FirestoreDemoGuard.requireRole(['admin', 'manager']);
    if (bankRefundId != null) {
      throw StateError(
        'Không thể xác nhận hoàn khoản ngân hàng trong bản Firestore Only.',
      );
    }
    final ref = _db.collection(FirebaseCollections.returns).doc(id);
    await _db.runTransaction((tx) async {
      final ret = await tx.get(ref);
      final data = ret.data();
      if (data == null || data['status'] != 'Pending')
        throw StateError('Phiếu không còn chờ xử lý.');
      final orderRef = _db
          .collection(FirebaseCollections.orders)
          .doc(data['orderId'].toString());
      final originalRef = _db
          .collection(FirebaseCollections.products)
          .doc(data['sku'].toString());
      final replaceSku = data['type'] == 'Exchange'
          ? data['replacementSku']?.toString()
          : null;
      final replacementRef = replaceSku == null
          ? null
          : _db.collection(FirebaseCollections.products).doc(replaceSku);
      final order = await tx.get(orderRef);
      final original = await tx.get(originalRef);
      final replacement = replacementRef != null
          ? await tx.get(replacementRef)
          : null;
      if (!order.exists ||
          !['Paid', 'Refunded'].contains(order.data()?['status']) ||
          !original.exists ||
          (replacementRef != null && !(replacement?.exists ?? false))) {
        throw StateError('Bill hoặc sản phẩm không hợp lệ.');
      }
      if (order.data()?['paymentMethod'] == 'qr' && data['type'] == 'Return') {
        throw StateError('Hoàn khoản QR phải được xác minh ngoài ứng dụng.');
      }
      final lines = List<dynamic>.from(
        order.data()?['items'] as List<dynamic>? ?? [],
      );
      final line = Map<String, dynamic>.from(
        lines.firstWhere(
              (e) => (e as Map)['sku'] == data['sku'],
              orElse: () => <String, dynamic>{},
            )
            as Map,
      );
      if (line.isEmpty) throw StateError('Không thấy sản phẩm trong bill.');
      final qty = FirestoreDemoGuard.integer(data['quantity']);
      final returned = Map<String, dynamic>.from(
        order.data()?['returnedItems'] as Map? ?? {},
      );
      final previously = FirestoreDemoGuard.integer(
        returned[data['sku'].toString()],
      );
      if (previously + qty > FirestoreDemoGuard.integer(line['quantity']))
        throw StateError('Số lượng trả vượt bill gốc.');
      if (replacement != null) {
        final stock = FirestoreDemoGuard.integer(replacement.data()?['stock']);
        final held = FirestoreDemoGuard.integer(
          replacement.data()?['heldStock'],
        );
        if (stock - held < qty ||
            FirestoreDemoGuard.integer(replacement.data()?['price']) !=
                FirestoreDemoGuard.integer(line['unitPrice']))
          throw StateError('Chỉ đổi hàng ngang giá và đủ tồn.');
      }
      final oldUnits = <DocumentSnapshot<Map<String, dynamic>>>[];
      for (final unitId in List<dynamic>.from(
        data['unitIds'] as List<dynamic>? ?? [],
      )) {
        oldUnits.add(
          await tx.get(
            _db.collection(FirebaseCollections.units).doc(unitId.toString()),
          ),
        );
      }
      final newUnits = <DocumentSnapshot<Map<String, dynamic>>>[];
      for (final unitId in List<dynamic>.from(
        data['replacementUnitIds'] as List<dynamic>? ?? [],
      )) {
        newUnits.add(
          await tx.get(
            _db.collection(FirebaseCollections.units).doc(unitId.toString()),
          ),
        );
      }
      for (final unit in oldUnits) {
        if (unit.data()?['trackingStatus'] != 'Sold' ||
            unit.data()?['soldOrderId'] != order.id ||
            unit.data()?['sku'] != data['sku']) {
          throw StateError('Mã xe đã không còn thuộc bill.');
        }
      }
      for (final unit in newUnits) {
        if (unit.data()?['trackingStatus'] != 'Available' ||
            unit.data()?['sku'] != replaceSku) {
          throw StateError('Mã xe thay không khả dụng.');
        }
      }
      final customerId = order.data()?['customerId']?.toString();
      final customerRef = customerId != null && replacement == null
          ? _db.collection(FirebaseCollections.customers).doc(customerId)
          : null;
      final customer = customerRef != null ? await tx.get(customerRef) : null;
      final unitPrice = FirestoreDemoGuard.integer(line['unitPrice']);
      final unitCost = FirestoreDemoGuard.integer(line['unitCost']);
      final refund = replacement == null ? qty * unitPrice : 0;
      final returnedTotal =
          FirestoreDemoGuard.integer(order.data()?['refundedTotal']) + refund;
      if (returnedTotal > FirestoreDemoGuard.integer(order.data()?['total']))
        throw StateError('Hoàn tiền vượt bill.');
      final rate = (order.data()?['commissionRate'] as num? ?? 0.05).toDouble();
      final eligibleOld = line['kpiEligible'] == true ? qty * unitPrice : 0;
      final eligibleNew = replacement?.data()?['kpiEligible'] == true
          ? qty * unitPrice
          : 0;
      final adjustment = ((eligibleNew - eligibleOld) * rate).round();
      final reversedCost = restockable ? qty * unitCost : 0;
      final replacementCost = replacement == null
          ? 0
          : FirestoreDemoGuard.integer(replacement.data()?['cost']) * qty;
      if (restockable)
        tx.update(originalRef, {'stock': FieldValue.increment(qty)});
      if (replacement != null)
        tx.update(replacementRef!, {'stock': FieldValue.increment(-qty)});
      for (final unit in oldUnits)
        tx.update(unit.reference, {
          'trackingStatus': restockable ? 'Available' : 'Damaged',
          'soldOrderId': FieldValue.delete(),
          'returnId': id,
          'returnedAt': FieldValue.serverTimestamp(),
        });
      for (final unit in newUnits)
        tx.update(unit.reference, {
          'trackingStatus': 'Sold',
          'soldOrderId': order.id,
          'soldAt': FieldValue.serverTimestamp(),
        });
      if (customer?.exists == true && customerRef != null) {
        tx.update(customerRef, {'totalSpend': FieldValue.increment(-refund)});
      }
      returned[data['sku'].toString()] = previously + qty;
      tx.update(orderRef, {
        'refundedTotal': returnedTotal,
        'returnedItems': returned,
        'costReversed':
            FirestoreDemoGuard.integer(order.data()?['costReversed']) +
            reversedCost -
            replacementCost,
        'status':
            returnedTotal == FirestoreDemoGuard.integer(order.data()?['total'])
            ? 'Refunded'
            : 'Paid',
      });
      if (adjustment != 0) {
        tx.set(
          _db.collection(FirebaseCollections.commissions).doc('RETURN_$id'),
          {
            'orderId': order.id,
            'returnId': id,
            'staffUid': order.data()?['staffUid'],
            'amount': adjustment,
            'eligibleSales': eligibleNew - eligibleOld,
            'commissionRate': rate,
            'type': replacement == null
                ? 'return_adjustment'
                : 'exchange_adjustment',
            'createdAt': FieldValue.serverTimestamp(),
          },
        );
      }
      tx.update(ref, {
        'status': 'Completed',
        'restockable': restockable,
        'refundAmount': refund,
        'costReversed': reversedCost - replacementCost,
        'kpiAdjustment': adjustment,
        'reviewedBy': uid,
        'reviewedAt': FieldValue.serverTimestamp(),
      });
      if (replacement != null) {
        tx.set(
          _db
              .collection(FirebaseCollections.stockMovements)
              .doc('EXCHANGE_OUT_$id'),
          {
            'sku': replacement.id,
            'type': 'EXCHANGE_OUT',
            'quantity': -qty,
            'unitCost': replacement.data()?['cost'] ?? 0,
            'sourceId': id,
            'createdBy': uid,
            'createdAt': FieldValue.serverTimestamp(),
          },
        );
      }
      tx.set(
        _db.collection(FirebaseCollections.stockMovements).doc('RETURN_$id'),
        {
          'sku': original.id,
          'type': replacement == null ? 'RETURN' : 'EXCHANGE',
          'quantity': restockable ? qty : 0,
          'unitCost': unitCost,
          'sourceId': id,
          'createdBy': uid,
          'createdAt': FieldValue.serverTimestamp(),
        },
      );
    });
  }
}
