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

  Future<void> loadProducts() async {
    products = await _productService.getProducts();
  }

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

  Future<void> uploadDamagePhoto(String id, Uint8List bytes, String name) =>
      _damageService.uploadDamagePhoto(id, bytes, name);

  Future<Uint8List?> getDamagePhoto(String id) =>
      _damageService.getDamagePhoto(id);

  Future<Uint8List?> getProductPhoto(String sku) =>
      _productService.getProductPhoto(sku);

  Future<void> uploadProductPhoto(String sku, Uint8List bytes, String name) =>
      _productService.uploadProductPhoto(sku, bytes, name);

  Future<void> editProduct(Product product) async {
    await _productService.updateProduct(
      product,
      'EDIT_${DateTime.now().microsecondsSinceEpoch}',
    );
    await loadProducts();
  }

  Future<void> addProduct(Product product) async {
    await _productService.saveProduct(product);
    await loadProducts();
  }

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

  Future<void> loadSuppliers() async {
    suppliers = await _supplierService.getSuppliers();
  }

  Future<void> loadReceipts() async {
    await loadSuppliers();
    receipts = await _inventoryService.getPurchaseReceipts();
    products = await _productService.getProducts();
  }

  Future<void> loadStocktakes() async {
    stocktakes = await _inventoryService.getStocktakes();
    stockSnapshot = await _inventoryService.getStockSnapshot();
  }

  Future<void> loadUnits() async {
    units = await _inventoryService.getInventoryUnits();
    products = await _productService.getProducts();
  }

  Future<void> addSupplier(
    String name,
    String phone,
    String email,
    String note,
  ) async {
    await _supplierService.saveSupplier(name, phone, email, note);
    await loadSuppliers();
  }

  Future<void> deactivateSupplier(String id) async {
    await _supplierService.deactivateSupplier(id);
    await loadSuppliers();
  }

  Future<void> addReceipt(
    String supplierId,
    List<Map<String, dynamic>> lines,
    String note,
  ) async {
    await _inventoryService.createPurchaseReceipt(supplierId, lines, note);
    receipts = await _inventoryService.getPurchaseReceipts();
  }

  Future<void> reviewReceipt(String id, bool approve) async {
    await _inventoryService.reviewPurchaseReceipt(id, approve);
    receipts = await _inventoryService.getPurchaseReceipts();
  }

  Future<void> addCount(List<Map<String, dynamic>> lines) async {
    await _inventoryService.createStocktake(lines);
    stocktakes = await _inventoryService.getStocktakes();
  }

  Future<void> reviewCount(String id, bool approve) async {
    await _inventoryService.reviewStocktake(id, approve);
    stocktakes = await _inventoryService.getStocktakes();
  }

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
