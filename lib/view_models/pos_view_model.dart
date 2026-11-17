import '../core/constants/app_defaults.dart';
import '../services/settings_service.dart';
import '../services/inventory_service.dart';
import '../services/product_service.dart';
import '../services/pos_service.dart';
import '../services/payment_service.dart';
import '../services/hold_service.dart';
import '../services/customer_service.dart';
import '../models/cart_item.dart';
import '../models/customer.dart';
import '../models/product.dart';

class PosViewModel {
  final CustomerService _customerService = CustomerService();
  final ProductService _productService = ProductService();
  final PosService _posService = PosService();
  final PaymentService _paymentService = PaymentService();
  final HoldService _holdService = HoldService();
  final SettingsService _settingsService = SettingsService();
  final InventoryService _inventoryService = InventoryService();
  List<Map<String, dynamic>> units = [];
  List<Map<String, dynamic>> pendingQr = [];

  List<Product> products = [];

  // Khách lẻ chỉ là lựa chọn UI; không tạo document customers/C001.
  static const walkInCustomer = Customer(
    id: 'C001',
    name: 'Khách lẻ',
    phone: '-',
    totalSpend: 0,
    favorite: '-',
    lastPurchase: '-',
  );
  List<Customer> customers = [walkInCustomer];

  double commissionRate = AppDefaults.commissionRate;

  Future<void> loadFromFirebase() async {
    final settings = await _settingsService.getSettings();
    commissionRate =
        (settings['commissionRate'] as num? ?? AppDefaults.commissionRate)
            .toDouble();
    products = await _productService.getProducts();
    units = await _inventoryService.getInventoryUnits();
    pendingQr = await _paymentService.getPendingQr();
    final selectedId = selectedCustomer?.id;
    final list = await _customerService.getCustomers();
    customers = [walkInCustomer, ...list];
    // Sau khi reload, Dropdown phải dùng đúng object trong danh sách mới.
    selectedCustomer = selectedId == null
        ? null
        : customers.where((customer) => customer.id == selectedId).firstOrNull;
  }

  Future<void> saveDraft() => _posService.saveOrderDraft(
    cart,
    selectedCustomer?.id == walkInCustomer.id ? null : selectedCustomer?.id,
  );

  String? _saleRequestId;

  Future<String> holdCart() async => _holdService.createHold(
    cart,
    selectedCustomer?.id == walkInCustomer.id ? null : selectedCustomer?.id,
  );

  Future<Map<String, dynamic>> completeQrPayment() async {
    _saleRequestId ??= _posService.newSaleRequestId();
    return _paymentService.createQrPayment(
      cart,
      selectedCustomer?.id == walkInCustomer.id ? null : selectedCustomer?.id,
      _saleRequestId!,
    );
  }

  Future<void> confirmQrPayment(
    String id,
    String bankId,
    int paidAmount,
  ) async {
    await _paymentService.confirmQrPayment(id, bankId, paidAmount);
    pendingQr = await _paymentService.getPendingQr();
  }

  List<Map<String, dynamic>> availableUnits(Product product) => units
      .where(
        (unit) =>
            unit['sku'] == product.sku &&
            (unit['trackingStatus'] == 'Available' ||
                unit['trackingStatus'] == 'ObservationOnly') &&
            unit['condition'] != 'Defective',
      )
      .toList();

  void setUnits(CartItem item, List<String> ids) {
    if (ids.length > item.quantity)
      throw StateError('Số mã xe vượt số lượng mua.');
    item.unitIds
      ..clear()
      ..addAll(ids);
    _saleRequestId = null;
  }

  void invalidateSale() {
    _saleRequestId = null;
  }

  Future<Map<String, dynamic>> completeCashSale() async {
    _saleRequestId ??= _posService.newSaleRequestId();
    return _posService.completeCashSale(
      cart,
      selectedCustomer?.id == walkInCustomer.id ? null : selectedCustomer?.id,
      _saleRequestId!,
    );
  }

  final List<CartItem> cart = [];
  Customer? selectedCustomer;
  String paymentMethod = 'Tiền mặt';
  String search = '';

  List<Product> get filteredProducts {
    final q = search.trim().toLowerCase();
    if (q.isEmpty) return products;
    return products
        .where(
          (p) =>
              p.name.toLowerCase().contains(q) ||
              p.sku.toLowerCase().contains(q) ||
              p.brand.toLowerCase().contains(q),
        )
        .toList();
  }

  void addProduct(Product product) {
    _saleRequestId = null;
    final existing = cart
        .where((item) => item.product.sku == product.sku)
        .toList();
    if (existing.isNotEmpty) {
      if (existing.first.quantity < product.stock) existing.first.quantity++;
      return;
    }
    cart.add(CartItem(product: product));
  }

  void increase(CartItem item) {
    if (item.quantity < item.product.stock) {
      item.quantity++;
      _saleRequestId = null;
    }
  }

  void decrease(CartItem item) {
    _saleRequestId = null;
    if (item.quantity > 1) {
      item.quantity--;
      while (item.unitIds.length > item.quantity) {
        item.unitIds.removeLast();
      }
    } else {
      cart.remove(item);
    }
  }

  double get subtotal => cart.fold(0, (sum, item) => sum + item.lineTotal);
  double get commissionPreview => cart
      .where((e) => e.product.kpiEligible)
      .fold(0, (sum, item) => sum + item.lineTotal * commissionRate);

  void clearCart() {
    cart.clear();
    _saleRequestId = null;
  }
}
