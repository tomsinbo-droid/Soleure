class Customer {
  const Customer({
    required this.id,
    required this.name,
    required this.phone,
    required this.totalSpend,
    required this.favorite,
    required this.lastPurchase,
  });
  final String id;
  final String name;
  final String phone;
  final double totalSpend;
  final String favorite;
  final String lastPurchase;

  factory Customer.fromMap(String id, Map<String, dynamic> data) => Customer(
    id: id,
    name: data['name'] as String? ?? '',
    phone: data['phone'] as String? ?? '',
    totalSpend: (data['totalSpend'] as num? ?? 0).toDouble(),
    favorite: data['favorite'] as String? ?? '',
    lastPurchase: data['lastPurchase'] as String? ?? '-',
  );

  Map<String, dynamic> toMap() => {
    'name': name,
    'phone': phone,
    'totalSpend': totalSpend,
    'favorite': favorite,
    'lastPurchase': lastPurchase,
  };
}
