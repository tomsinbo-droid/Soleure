// Công dụng tệp: Sản phẩm.

class Product {
  const Product({
    required this.sku,
    required this.name,
    required this.brand,
    required this.series,
    required this.price,
    required this.cost,
    required this.stock,
    required this.location,
    this.promoPercent = 0,
    this.kpiEligible = true,
    this.imageBase64,
  });

  final String sku;
  final String name;
  final String brand;
  final String series;
  final double price;
  final double cost;
  final int stock;
  final String location;
  final double promoPercent;
  final bool kpiEligible;
  final String? imageBase64;

  double get sellingPrice => price * (1 - promoPercent / 100);

  /// Tạo đối tượng từ mã định danh và dữ liệu bản đồ.
  factory Product.fromMap(String sku, Map<String, dynamic> data) => Product(
    sku: sku,
    name: data['name'] as String? ?? '',
    brand: data['brand'] as String? ?? '',
    series: data['series'] as String? ?? '',
    price: (data['price'] as num? ?? 0).toDouble(),
    cost: (data['cost'] as num? ?? 0).toDouble(),
    // Stock trên UI = số hàng có thể bán (đã trừ số lượng đang Hold).
    stock:
        (((data['stock'] as num? ?? 0).toInt() -
                    (data['heldStock'] as num? ?? 0).toInt())
                .clamp(0, 999999999))
            .toInt(),
    location: data['location'] as String? ?? '',
    promoPercent: (data['promoPercent'] as num? ?? 0).toDouble(),
    kpiEligible: data['kpiEligible'] as bool? ?? true,
    imageBase64: data['imageBase64'] as String?,
  );

  /// Chuyển dữ liệu hiện tại thành bản đồ để lưu hoặc truyền đi.
  Map<String, dynamic> toMap() => {
    'name': name,
    'brand': brand,
    'series': series,
    'price': price,
    'cost': cost,
    'stock': stock,
    'location': location,
    'promoPercent': promoPercent,
    'kpiEligible': kpiEligible,
  };
}
