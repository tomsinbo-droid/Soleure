import '../services/customer_service.dart';
import '../models/customer.dart';

class CustomerViewModel {
  final CustomerService _customerService = CustomerService();

  List<Customer> customers = [];
  Future<void> loadCustomers() async {
    customers = await _customerService.getCustomers();
  }

  Future<void> addCustomer(Customer customer) async {
    await _customerService.saveCustomer(customer);
    await loadCustomers();
  }

  Future<void> editCustomer(Customer customer) async {
    await _customerService.editCustomer(customer);
    await loadCustomers();
  }

  Future<List<Map<String, dynamic>>> getHistory(String customerId) =>
      _customerService.getCustomerHistory(customerId);

  List<Customer> filter(String query) {
    final q = query.trim().toLowerCase();
    return customers
        .where((c) => '${c.id} ${c.name} ${c.phone}'.toLowerCase().contains(q))
        .toList();
  }
}
