// Công dụng tệp: Khách hàng và lịch sử mua.

import '../services/customer_service.dart';
import '../models/customer.dart';

class CustomerViewModel {
  final CustomerService _customerService = CustomerService();

  List<Customer> customers = [];
  /// Tải danh sách khách hàng.
  Future<void> loadCustomers() async {
    customers = await _customerService.getCustomers();
  }

  /// Thêm khách hàng.
  Future<void> addCustomer(Customer customer) async {
    await _customerService.saveCustomer(customer);
    await loadCustomers();
  }

  /// Chỉnh sửa khách hàng.
  Future<void> editCustomer(Customer customer) async {
    await _customerService.editCustomer(customer);
    await loadCustomers();
  }

  /// Lấy lịch sử.
  Future<List<Map<String, dynamic>>> getHistory(String customerId) =>
      _customerService.getCustomerHistory(customerId);

  /// Lọc khách hàng và lịch sử mua.
  List<Customer> filter(String query) {
    final q = query.trim().toLowerCase();
    return customers
        .where((c) => '${c.id} ${c.name} ${c.phone}'.toLowerCase().contains(q))
        .toList();
  }
}
