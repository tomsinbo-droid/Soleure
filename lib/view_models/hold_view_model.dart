// Công dụng tệp: Giữ hàng.

import '../services/product_service.dart';
import '../services/pos_service.dart';
import '../services/hold_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/cart_item.dart';

class HoldViewModel {
  final ProductService _productService = ProductService();
  final PosService _posService = PosService();
  final HoldService _holdService = HoldService();

  List<Map<String, dynamic>> rows = [];
  final Map<String, String> productNames = {};

  /// Tải dữ liệu giữ hàng và cập nhật trạng thái tương ứng.
  Future<void> load() async {
    rows = await _holdService.getHolds();
    final products = await _productService.getProducts();
    productNames.clear();
    for (final p in products) productNames[p.sku] = p.name;
  }

  /// Xác định trạng thái hiển thị của phiếu giữ hàng.
  String status(Map<String, dynamic> row) {
    if (row['status'] != 'Active') return row['status']?.toString() ?? '-';
    final until = row['expiresAt'];
    if (until is Timestamp && until.toDate().isBefore(DateTime.now()))
      return 'Expired';
    return 'Active';
  }

  /// Tính thời gian còn lại của phiếu giữ hàng.
  String remaining(Map<String, dynamic> row) {
    if (status(row) != 'Active') return 'Hết hạn';
    final until = row['expiresAt'];
    if (until is! Timestamp) return '-';
    final minutes = until.toDate().difference(DateTime.now()).inMinutes;
    return '${minutes + 1} phút';
  }

  /// Tạo nội dung tên sản phẩm để hiển thị trong phiếu giữ hàng.
  String itemNames(Map<String, dynamic> row) {
    final items = row['items'];
    if (items is! List) return '-';
    return items
        .map((e) {
          if (e is! Map) return '?';
          final sku = e['sku']?.toString() ?? '';
          return '${productNames[sku] ?? sku} ×${e['quantity']}';
        })
        .join(', ');
  }

  /// Tạo mới dữ liệu giữ hàng theo thông tin được cung cấp.
  Future<void> create(String sku, int quantity, String? customerId) async {
    final matches = await _productService.getProducts();
    final product = matches.where((p) => p.sku == sku).firstOrNull;
    if (product == null) throw StateError('Không có SKU này.');
    if (quantity > product.stock) throw StateError('Không đủ hàng khả dụng.');
    await _holdService.createHold([
      CartItem(product: product, quantity: quantity),
    ], customerId);
    await load();
  }

  /// Thực hiện thanh toán tiền mặt cho giao dịch.
  Future<Map<String, dynamic>> payCash(Map<String, dynamic> hold) async {
    final requestId = _posService.newSaleRequestId();
    final result = await _posService.completeHoldCashSale(hold, requestId);
    await load();
    return result;
  }

  /// Hủy giữ hàng.
  Future<void> cancel(String id) async {
    await _holdService.cancelHold(id);
    await load();
  }
}
