import 'product.dart';

class CartItem {
  CartItem({required this.product, this.quantity = 1});

  final Product product;
  int quantity;
  final List<String> unitIds = []; // Mã từng xe, tùy chọn (<= quantity).

  double get lineTotal => product.sellingPrice * quantity;
}
