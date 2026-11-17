import '../services/promotion_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/promotion.dart';

class PromotionViewModel {
  final PromotionService _promotionService = PromotionService();

  List<Promotion> promotions = [];

  String _date(dynamic value) {
    if (value is! Timestamp) return '-';
    final d = value.toDate();
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
  }

  Future<void> load() async {
    final rows = await _promotionService.getPromotions();
    promotions = rows
        .map(
          (e) => Promotion(
            id: e['id']?.toString() ?? '',
            name: e['name']?.toString() ?? '',
            scope: e['scope']?.toString() ?? '',
            discount: '${e['discount'] ?? 0}%',
            period: '${_date(e['startAt'])} - ${_date(e['endAt'])}',
            proposer: e['proposerUid']?.toString() ?? '-',
            status: e['status']?.toString() ?? 'Pending',
          ),
        )
        .toList();
  }

  Future<void> propose(
    String name,
    String scope,
    int discount,
    DateTime start,
    DateTime end,
  ) async {
    await _promotionService.proposePromotion(name, scope, discount, start, end);
    await load();
  }

  Future<void> review(String id, bool approved) async {
    await _promotionService.reviewPromotion(id, approved);
    await load();
  }
}
