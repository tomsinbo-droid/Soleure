import '../core/constants/firebase_collections.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/customer.dart';
import '../models/user_role.dart';
import 'auth_service.dart';

/// Firebase - nghiệp vụ customer
class CustomerService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final AuthService _auth = AuthService();
  Future<List<Customer>> getCustomers() async {
    final result = await _db.collection(FirebaseCollections.customers).get();
    return result.docs
        .map((doc) => Customer.fromMap(doc.id, doc.data()))
        .toList();
  }

  Future<void> saveCustomer(Customer customer) async {
    final ref = _db.collection(FirebaseCollections.customers).doc(customer.id);
    await _db.runTransaction((tx) async {
      final existing = await tx.get(ref);
      if (existing.exists) throw StateError('Khách hàng đã có trong hệ thống.');
      tx.set(ref, customer.toMap());
    });
  }

  Future<void> editCustomer(Customer customer) async {
    await _db.collection(FirebaseCollections.customers).doc(customer.id).update(
      {
        'name': customer.name,
        'phone': customer.phone,
        'favorite': customer.favorite,
      },
    );
  }

  Future<List<Map<String, dynamic>>> getCustomerHistory(
    String customerId,
  ) async {
    final session = await _auth.getCurrentSession();
    if (session?.role == null)
      throw StateError('Tài khoản không được cấp quyền.');
    final query = _db.collection(FirebaseCollections.orders);
    // Staff chỉ được truy vấn các bill của mình (Rules production bảo vệ).
    // Manager/Admin được xem toàn bộ lịch sử khách.
    final result = session?.role == UserRole.staff
        ? await query
              .where('staffUid', isEqualTo: _auth.currentUid)
              .limit(1001)
              .get()
        : await query
              .where('customerId', isEqualTo: customerId)
              .limit(1001)
              .get();
    if (result.docs.length > 1000)
      throw StateError('Lịch sử quá lớn, cần thêm phân trang.');
    final rows = result.docs
        .where((doc) => doc.data()['customerId'] == customerId)
        .map((doc) => {'id': doc.id, ...doc.data()})
        .toList();
    rows.sort((a, b) {
      final aDate = a['createdAt'] as Timestamp?;
      final bDate = b['createdAt'] as Timestamp?;
      return (bDate?.millisecondsSinceEpoch ?? 0).compareTo(
        aDate?.millisecondsSinceEpoch ?? 0,
      );
    });
    return rows;
  }
}
