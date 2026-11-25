// Công dụng tệp: Hàng hóa và tồn kho.

import '../services/supplier_service.dart';
import '../services/product_service.dart';
import '../services/inventory_service.dart';
import '../services/damage_service.dart';
import '../services/auth_service.dart';
import 'dart:typed_data';
import '../models/product.dart';
import '../models/user_role.dart';

class InventoryViewModel {
  final AuthService _authService = AuthService();
  final ProductService _productService = ProductService();
  final DamageService _damageService = DamageService();

  List<Product> products = [];

  /// Tải danh sách sản phẩm.
  Future<void> loadProducts() async {
    products = await _productService.getProducts();
  }

  /// Tải dữ liệu hàng hóa và tồn kho và cập nhật trạng thái tương ứng.
  Future<void> load() async {
    await loadProducts();
    final session = await _authService.getCurrentSession();
    // Lấy danh sách báo cáo thiệt hại từ service, nhưng nếu là nhân viên thì không được xem.
    final rows = session?.role == UserRole.staff
        ? <Map<String, dynamic>>[]
    // lấy dũ liệu từ getDamageReports thông qua _damageService
        : await _damageService.getDamageReports();
    damageRows = rows;
    damageRecords = rows
        .map<(String, String, String, String, String)>(
          (r) => (
            r['sku']?.toString() ?? '-',
            r['reason']?.toString() ?? '-',
            (r['quantity'] ?? 0).toString(),
            '${r['loss'] ?? 0} đ',
            r['status']?.toString() ?? 'Pending',
          ),
        )
        .toList();
  }

  /// Ghi nhận hao hụt.
  Future<String> reportDamage(
    String sku,
    String reason,
    int quantity,
    int loss,
  ) async {
    final id = await _damageService.createDamageReport(
      sku,
      reason,
      quantity,
      loss,
    );
    await load();
    return id;
  }

  /// Tải lên ảnh biên bản hao hụt.
  Future<void> uploadDamagePhoto(String id, Uint8List bytes, String name) =>
      _damageService.uploadDamagePhoto(id, bytes, name);

  /// Lấy ảnh biên bản hao hụt.
  Future<Uint8List?> getDamagePhoto(String id) =>
      _damageService.getDamagePhoto(id);

  /// Lấy ảnh sản phẩm.
  Future<Uint8List?> getProductPhoto(String sku) =>
      _productService.getProductPhoto(sku);

  /// Tải lên ảnh sản phẩm.
  Future<void> uploadProductPhoto(String sku, Uint8List bytes, String name) =>
      _productService.uploadProductPhoto(sku, bytes, name);

  /// Chỉnh sửa sản phẩm.
  Future<void> editProduct(Product product) async {
    await _productService.updateProduct(
      product,
      'EDIT_${DateTime.now().microsecondsSinceEpoch}',
    );
    await loadProducts();
  }

  /// Thêm sản phẩm.
  Future<void> addProduct(Product product) async {
    await _productService.saveProduct(product);
    await loadProducts();
  }

  /// Lọc hàng hóa và tồn kho.
  List<Product> filter(String search, String location) {
    final q = search.trim().toLowerCase();
    final place = location.trim().toLowerCase();
    return products
        .where(
          (p) =>
              '${p.sku} ${p.name} ${p.brand}'.toLowerCase().contains(q) &&
              p.location.toLowerCase().contains(place),
        )
        .toList();
  }

  List<Map<String, dynamic>> damageRows = [];
  List<(String, String, String, String, String)> damageRecords = [];

  /// Xem xét và xử lý hao hụt.
  Future<void> reviewDamage(String id, bool approved) async {
    await _damageService.reviewDamage(id, approved);
    await load();
  }
}

// Sprint 3: ViewModel thuần Dart, không dùng Provider / Bloc / ChangeNotifier.
// View chỉ gọi các method ở đây; ViewModel gọi service đúng nghiệp vụ.
class InventorySprint3ViewModel {
  final ProductService _productService = ProductService();
  final InventoryService _inventoryService = InventoryService();
  final SupplierService _supplierService = SupplierService();

  List<Map<String, dynamic>> suppliers = [];
  List<Map<String, dynamic>> receipts = [];
  List<Map<String, dynamic>> stocktakes = [];
  List<Map<String, dynamic>> units = [];
  List<Map<String, dynamic>> stockSnapshot = [];
  List<Product> products = [];

  /// Tải danh sách nhà cung cấp.
  Future<void> loadSuppliers() async {
    suppliers = await _supplierService.getSuppliers();
  }

  /// Tải danh sách phiếu nhập kho.
  Future<void> loadReceipts() async {
    await loadSuppliers();
    receipts = await _inventoryService.getPurchaseReceipts();
    products = await _productService.getProducts();
  }

  /// Tải các phiếu kiểm kê.
  Future<void> loadStocktakes() async {
    stocktakes = await _inventoryService.getStocktakes();
    stockSnapshot = await _inventoryService.getStockSnapshot();
  }

  /// Tải các đơn vị hàng.
  Future<void> loadUnits() async {
    units = await _inventoryService.getInventoryUnits();
    products = await _productService.getProducts();
  }

  /// Thêm nhà cung cấp.
  Future<void> addSupplier(
    String name,
    String phone,
    String email,
    String note,
  ) async {
    await _supplierService.saveSupplier(name, phone, email, note);
    await loadSuppliers();
  }

  /// Ngưng sử dụng nhà cung cấp.
  Future<void> deactivateSupplier(String id) async {
    await _supplierService.deactivateSupplier(id);
    await loadSuppliers();
  }

  /// Thêm phiếu nhập.
  Future<void> addReceipt(
    String supplierId,
    List<Map<String, dynamic>> lines,
    String note,
  ) async {
    await _inventoryService.createPurchaseReceipt(supplierId, lines, note);
    receipts = await _inventoryService.getPurchaseReceipts();
  }

  /// Xem xét và xử lý phiếu nhập.
  Future<void> reviewReceipt(String id, bool approve) async {
    await _inventoryService.reviewPurchaseReceipt(id, approve);
    receipts = await _inventoryService.getPurchaseReceipts();
  }

  /// Thêm phiếu kiểm kê.
  Future<void> addCount(List<Map<String, dynamic>> lines) async {
    await _inventoryService.createStocktake(lines);
    stocktakes = await _inventoryService.getStocktakes();
  }

  /// Xem xét và xử lý phiếu kiểm kê.
  Future<void> reviewCount(String id, bool approve) async {
    await _inventoryService.reviewStocktake(id, approve);
    stocktakes = await _inventoryService.getStocktakes();
  }

  /// Thêm đơn vị hàng.
  Future<void> addUnit(
    String sku,
    String code,
    String condition,
    String location,
    String note,
  ) async {
    await _inventoryService.registerInventoryUnit(
      sku,
      code,
      condition,
      location,
      note,
    );
    units = await _inventoryService.getInventoryUnits();
  }
}
