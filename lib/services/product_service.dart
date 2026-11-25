// Công dụng tệp: Sản phẩm.

import '../core/constants/firebase_collections.dart';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/product.dart';
import 'promotion_service.dart';

/// Firebase - nghiệp vụ product
class ProductService {
  final PromotionService _promotionService = PromotionService();
  late final FirebaseFirestore _db = FirebaseFirestore.instance;
  /// Lấy danh sách sản phẩm.
  Future<List<Product>> getProducts() async {
    final result = await _db.collection(FirebaseCollections.products).get();
    // Khuyến mãi đã duyệt được áp dụng giống backend. UI vẫn dùng Product gốc.
    final campaigns = await _promotionService.getActivePromotions();
    final now = DateTime.now();
    return result.docs.map((doc) {
      final base = Product.fromMap(doc.id, doc.data());
      var discount = base.promoPercent;
      for (final campaign in campaigns) {
        final start = (campaign['startAt'] as Timestamp?)?.toDate();
        final end = (campaign['endAt'] as Timestamp?)?.toDate();
        if (start == null ||
            end == null ||
            now.isBefore(start) ||
            now.isAfter(end.add(const Duration(days: 1))))
          continue;
        final scopes = (campaign['scope']?.toString() ?? '')
            .split(',')
            .map((v) => v.trim())
            .toList();
        if (scopes.contains('ALL') || scopes.contains(base.sku)) {
          final value = (campaign['discount'] as num? ?? 0).toDouble();
          if (value > discount) discount = value;
        }
      }
      return Product(
        sku: base.sku,
        name: base.name,
        brand: base.brand,
        series: base.series,
        price: base.price,
        cost: base.cost,
        stock: base.stock,
        location: base.location,
        promoPercent: discount,
        kpiEligible: base.kpiEligible,
        imageBase64: base.imageBase64,
      );
    }).toList();
  }

  /// Lưu sản phẩm.
  Future<void> saveProduct(Product product) async {
    if (product.sku.trim().isEmpty ||
        product.sku.contains('/') ||
        product.price <= 0) {
      throw StateError('SKU hoặc giá bán chưa hợp lệ.');
    }
    final ref = _db.collection(FirebaseCollections.products).doc(product.sku);
    await _db.runTransaction((tx) async {
      final previous = await tx.get(ref);
      if (previous.exists)
        throw StateError('SKU đã tồn tại; sử dụng chức năng sửa sản phẩm.');
      tx.set(ref, {
        ...product.toMap(),
        'stock': 0,
        'cost': 0,
        'heldStock': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Cập nhật sản phẩm.
  Future<void> updateProduct(Product product, String _) async {
    await _db.collection(FirebaseCollections.products).doc(product.sku).update({
      'name': product.name,
      'brand': product.brand,
      'series': product.series,
      'location': product.location,
      'price': product.price.round(),
      'kpiEligible': product.kpiEligible,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Tải lên ảnh sản phẩm.
  Future<void> uploadProductPhoto(
    String sku,
    Uint8List bytes,
    String name,
  ) async {
    if (bytes.isEmpty || bytes.length > 600 * 1024) {
      throw StateError(
        'Ảnh phải nhỏ hơn 600 KB khi lưu Base64 trên Firestore.',
      );
    }
    final ext = name.split('.').last.toLowerCase();
    final mime = ext == 'png'
        ? 'image/png'
        : ext == 'webp'
        ? 'image/webp'
        : ext == 'jpg' || ext == 'jpeg'
        ? 'image/jpeg'
        : null;
    if (mime == null) throw StateError('Chỉ hỗ trợ PNG, JPG, WEBP.');
    await _db.collection(FirebaseCollections.products).doc(sku).update({
      'imageBase64': base64Encode(bytes),
      'imageMime': mime,
    });
  }

  /// Lấy ảnh sản phẩm.
  Future<Uint8List?> getProductPhoto(String sku) async {
    final doc = await _db
        .collection(FirebaseCollections.products)
        .doc(sku)
        .get();
    final encoded = doc.data()?['imageBase64'];
    if (encoded is! String || encoded.isEmpty) return null;
    return base64Decode(encoded);
  }
}
