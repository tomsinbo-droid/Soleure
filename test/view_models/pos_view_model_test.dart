import 'package:app_project/view_models/pos_view_model.dart';
import 'package:app_project/models/product.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('POS adds product and calculates commission from selling price', () {
    final vm = PosViewModel();
    // Fixture chỉ thuộc unit test, ứng dụng thật luôn tải sản phẩm từ Firestore.
    const product = Product(
      sku: 'TEST-001', name: 'Xe test', brand: 'Test Brand', series: 'Test',
      price: 100000, cost: 60000, stock: 3, location: 'T01', promoPercent: 10,
    );

    vm.addProduct(product);

    expect(vm.cart.length, 1);
    expect(vm.subtotal, product.sellingPrice);
    expect(vm.commissionPreview, product.sellingPrice * 0.05);
  });
}
