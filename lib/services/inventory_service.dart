// Công dụng tệp: Hàng hóa và tồn kho.

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/firebase_collections.dart';
import '../core/utils/id_helper.dart';
import 'firestore_demo_guard.dart';

/// Chứng từ kho được lưu trên Cloud Firestore; duyệt sử dụng transaction.
class InventoryService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Lấy các phiếu nhập kho.
  Future<List<Map<String, dynamic>>> getPurchaseReceipts() =>
      _rows(FirebaseCollections.receipts);
  /// Lấy các phiếu kiểm kê.
  Future<List<Map<String, dynamic>>> getStocktakes() =>
      _rows(FirebaseCollections.stocktakes);
  /// Lấy các đơn vị hàng.
  Future<List<Map<String, dynamic>>> getInventoryUnits() =>
      _rows(FirebaseCollections.units);
  /// Lấy lịch sử biến động kho.
  Future<List<Map<String, dynamic>>> getStockMovements() =>
      _rows(FirebaseCollections.stockMovements);

  /// Lấy số liệu tồn kho.
  Future<List<Map<String, dynamic>>> getStockSnapshot() async {
    final rows = await _db
        .collection(FirebaseCollections.products)
        .limit(200)
        .get();
    return rows.docs.map((d) => {'sku': d.id, ...d.data()}).toList();
  }

  /// Chuyển dữ liệu danh sách thành các dòng để xử lý hoặc hiển thị.
  Future<List<Map<String, dynamic>>> _rows(String collection) async {
    final result = await _db.collection(collection).limit(200).get();
    return result.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  /// Tạo phiếu nhập kho.
  Future<void> createPurchaseReceipt(
    String supplierId,
    List<Map<String, dynamic>> lines,
    String note,
  ) async {
    final uid = await FirestoreDemoGuard.requireRole(['admin', 'manager']);
    if (supplierId.isEmpty || lines.isEmpty || lines.length > 30) {
      throw StateError('Chọn nhà cung cấp và tối đa 30 dòng nhập.');
    }
    final supplier = await _db
        .collection(FirebaseCollections.suppliers)
        .doc(supplierId)
        .get();
    if (!supplier.exists || supplier.data()?['active'] != true) {
      throw StateError('Nhà cung cấp không hoạt động.');
    }
    final clean = <Map<String, dynamic>>[];
    final seen = <String>{};
    for (final line in lines) {
      final sku = (line['sku'] ?? '').toString();
      final qty = FirestoreDemoGuard.integer(line['quantity']);
      final cost = FirestoreDemoGuard.integer(line['unitCost']);
      if (sku.isEmpty || !seen.add(sku) || qty <= 0 || cost < 0) {
        throw StateError('SKU trùng hoặc số lượng/giá vốn không hợp lệ.');
      }
      clean.add({'sku': sku, 'quantity': qty, 'unitCost': cost});
    }
    final id = IdHelper.newId('PUR');
    await _db.collection(FirebaseCollections.receipts).doc(id).set({
      'supplierId': supplierId,
      'supplierName': supplier.data()?['name'],
      'lines': clean,
      'note': note.trim(),
      'status': 'Pending',
      'createdBy': uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Xem xét và xử lý phiếu nhập kho.
  Future<void> reviewPurchaseReceipt(String id, bool approved) async {
    final uid = await FirestoreDemoGuard.requireRole(['admin']);
    final ref = _db.collection(FirebaseCollections.receipts).doc(id);
    await _db.runTransaction((tx) async {
      final receipt = await tx.get(ref);
      if (!receipt.exists) throw StateError('Không tìm thấy phiếu nhập.');
      if (receipt.data()?['status'] != 'Pending')
        throw StateError('Phiếu đã được xử lý.');
      final lines = List<Map<String, dynamic>>.from(
        (receipt.data()?['lines'] as List<dynamic>?)?.map(
              (e) => Map<String, dynamic>.from(e),
            ) ??
            [],
      );
      final products = <DocumentSnapshot<Map<String, dynamic>>>[];
      for (final line in lines) {
        products.add(
          await tx.get(
            _db
                .collection(FirebaseCollections.products)
                .doc(line['sku'].toString()),
          ),
        );
      }
      if (approved) {
        for (var i = 0; i < lines.length; i++) {
          final product = products[i];
          if (!product.exists)
            throw StateError('SKU không tồn tại: ${lines[i]['sku']}');
          final before = FirestoreDemoGuard.integer(product.data()?['stock']);
          final qty = FirestoreDemoGuard.integer(lines[i]['quantity']);
          final oldCost = FirestoreDemoGuard.integer(product.data()?['cost']);
          final cost = FirestoreDemoGuard.integer(lines[i]['unitCost']);
          final after = before + qty;
          if (after > 100000000) throw StateError('Số lượng vượt giới hạn.');
          final average = ((oldCost * before + cost * qty) / after).round();
          tx.update(product.reference, {'stock': after, 'cost': average});
          tx.set(
            _db
                .collection(FirebaseCollections.stockMovements)
                .doc('RCPT_${id}_$i'),
            {
              'sku': product.id,
              'type': 'PURCHASE_IN',
              'quantity': qty,
              'stockBefore': before,
              'stockAfter': after,
              'unitCost': cost,
              'sourceId': id,
              'createdBy': uid,
              'createdAt': FieldValue.serverTimestamp(),
            },
          );
        }
      }
      tx.update(ref, {
        'status': approved ? 'Approved' : 'Rejected',
        'reviewedBy': uid,
        'reviewedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Tạo phiếu kiểm kê.
  Future<void> createStocktake(List<Map<String, dynamic>> lines) async {
    final uid = await FirestoreDemoGuard.requireRole(['admin', 'manager']);
    if (lines.isEmpty || lines.length > 30)
      throw StateError('Cần 1–30 dòng kiểm kê.');
    if (lines.map((e) => e['sku']?.toString()).toSet().length != lines.length) {
      throw StateError('Phiếu kiểm kê có SKU trùng.');
    }
    final id = IdHelper.newId('CNT');
    final ref = _db.collection(FirebaseCollections.stocktakes).doc(id);
    await _db.runTransaction((tx) async {
      final products = <DocumentSnapshot<Map<String, dynamic>>>[];
      for (final line in lines) {
        products.add(
          await tx.get(
            _db
                .collection(FirebaseCollections.products)
                .doc(line['sku'].toString()),
          ),
        );
      }
      final snapshot = <Map<String, dynamic>>[];
      for (var i = 0; i < lines.length; i++) {
        final p = products[i];
        if (!p.exists)
          throw StateError('Không tìm thấy SKU ${lines[i]['sku']}');
        final counted = FirestoreDemoGuard.integer(lines[i]['counted']);
        final stock = FirestoreDemoGuard.integer(p.data()?['stock']);
        final held = FirestoreDemoGuard.integer(p.data()?['heldStock']);
        if (counted < held || counted < 0)
          throw StateError('Kiểm đếm thấp hơn hàng Hold.');
        snapshot.add({
          'sku': p.id,
          'counted': counted,
          'expected': stock,
          'heldAtCount': held,
          'difference': counted - stock,
          'note': lines[i]['note'] ?? '',
        });
      }
      tx.set(ref, {
        'lines': snapshot,
        'status': 'Pending',
        'createdBy': uid,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Xem xét và xử lý phiếu kiểm kê.
  Future<void> reviewStocktake(String id, bool approved) async {
    final uid = await FirestoreDemoGuard.requireRole(['admin']);
    final ref = _db.collection(FirebaseCollections.stocktakes).doc(id);
    await _db.runTransaction((tx) async {
      final doc = await tx.get(ref);
      if (!doc.exists || doc.data()?['status'] != 'Pending')
        throw StateError('Phiếu không còn chờ duyệt.');
      final lines = List<Map<String, dynamic>>.from(
        (doc.data()?['lines'] as List<dynamic>).map(
          (e) => Map<String, dynamic>.from(e),
        ),
      );
      final products = <DocumentSnapshot<Map<String, dynamic>>>[];
      for (final line in lines) {
        products.add(
          await tx.get(
            _db
                .collection(FirebaseCollections.products)
                .doc(line['sku'].toString()),
          ),
        );
      }
      if (approved) {
        for (var i = 0; i < lines.length; i++) {
          final p = products[i];
          final line = lines[i];
          if (!p.exists ||
              FirestoreDemoGuard.integer(p.data()?['stock']) !=
                  line['expected'] ||
              FirestoreDemoGuard.integer(p.data()?['heldStock']) !=
                  line['heldAtCount']) {
            throw StateError('Tồn kho đã thay đổi. Hãy kiểm kê lại.');
          }
          final counted = FirestoreDemoGuard.integer(line['counted']);
          if (counted < FirestoreDemoGuard.integer(line['heldAtCount']))
            throw StateError('Sai số Hold.');
          if (counted == line['expected']) continue;
          tx.update(p.reference, {'stock': counted});
          tx.set(
            _db
                .collection(FirebaseCollections.stockMovements)
                .doc('COUNT_${id}_$i'),
            {
              'sku': p.id,
              'type': 'STOCKTAKE',
              'quantity':
                  counted - FirestoreDemoGuard.integer(line['expected']),
              'stockBefore': line['expected'],
              'stockAfter': counted,
              'unitCost': p.data()?['cost'] ?? 0,
              'sourceId': id,
              'createdBy': uid,
              'createdAt': FieldValue.serverTimestamp(),
            },
          );
        }
      }
      tx.update(ref, {
        'status': approved ? 'Approved' : 'Rejected',
        'reviewedBy': uid,
        'reviewedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Đăng ký đơn vị hàng.
  Future<void> registerInventoryUnit(
    String sku,
    String code,
    String condition,
    String location,
    String note,
  ) async {
    final uid = await FirestoreDemoGuard.requireRole(['admin', 'manager']);
    if (sku.trim().isEmpty ||
        code.trim().isEmpty ||
        !['Sealed', 'Good', 'BoxDamaged', 'Defective'].contains(condition)) {
      throw StateError('Mã xe hoặc tình trạng không hợp lệ.');
    }
    final ref = _db
        .collection(FirebaseCollections.units)
        .doc(IdHelper.newId('UNIT'));
    final uniqueId = base64Url
        .encode(utf8.encode('${sku.trim()}:${code.trim()}'))
        .replaceAll('=', '');
    final codeRef = _db.collection('inventory_unit_codes').doc(uniqueId);
    await _db.runTransaction((tx) async {
      final product = await tx.get(
        _db.collection(FirebaseCollections.products).doc(sku.trim()),
      );
      final previous = await tx.get(codeRef);
      if (!product.exists || previous.exists)
        throw StateError('SKU không có hoặc mã xe bị trùng.');
      tx.set(codeRef, {
        'sku': sku.trim(),
        'unitCode': code.trim(),
        'unitId': ref.id,
      });
      tx.set(ref, {
        'sku': sku.trim(),
        'unitCode': code.trim(),
        'condition': condition,
        'location': location.trim(),
        'note': note.trim(),
        'trackingStatus': 'Available',
        'createdBy': uid,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
