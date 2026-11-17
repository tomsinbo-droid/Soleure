import '../services/return_service.dart';

class ReturnsViewModel {
  final ReturnService _returnService = ReturnService();

  List<(String, String, String, String, String, String)> records = [];
  List<Map<String, dynamic>> requests = [];
  List<Map<String, dynamic>> returnableOrders = [];

  Future<void> load() async {
    final results = await Future.wait([
      _returnService.getReturns(),
      _returnService.getReturnableOrders(),
    ]);
    final rows = results[0];
    requests = rows;
    returnableOrders = results[1];
    records = rows
        .map<(String, String, String, String, String, String)>(
          (e) => (
            e['orderId']?.toString() ?? '-',
            '${e['sku'] ?? '-'} ×${e['quantity'] ?? 0}',
            e['type']?.toString() ?? '-',
            e['reason']?.toString() ?? '-',
            e['refundAmount'] == null
                ? 'Chưa điều chỉnh'
                : '${e['refundAmount']} đ',
            e['kpiAdjustment'] == null
                ? (e['status']?.toString() ?? 'Pending')
                : '${e['kpiAdjustment']} đ',
          ),
        )
        .toList();
  }

  Future<void> create(
    String orderId,
    String sku,
    int quantity,
    String type,
    String reason, {
    String? replacementSku,
    List<String> unitIds = const [],
    List<String> replacementUnitIds = const [],
  }) async {
    await _returnService.requestReturn(
      orderId: orderId,
      sku: sku,
      quantity: quantity,
      type: type,
      reason: reason,
      replacementSku: replacementSku,
      unitIds: unitIds,
      replacementUnitIds: replacementUnitIds,
    );
    await load();
  }

  Future<void> settle(
    String id,
    bool restockable,
    String? replacementSku, {
    String? bankRefundId,
    int? bankRefundAmount,
  }) async {
    await _returnService.settleReturn(
      id,
      restockable: restockable,
      replacementSku: replacementSku,
      bankRefundId: bankRefundId,
      bankRefundAmount: bankRefundAmount,
    );
    await load();
  }
}
