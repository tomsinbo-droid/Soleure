// Công dụng tệp: Khuyến mãi.

class Promotion {
  const Promotion({
    this.id = '',
    required this.name,
    required this.scope,
    required this.discount,
    required this.period,
    required this.proposer,
    required this.status,
  });

  final String id;
  final String name;
  final String scope;
  final String discount;
  final String period;
  final String proposer;
  final String status;
}
