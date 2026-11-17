import '../models/product.dart';
import 'notification_view_model.dart';
import '../models/customer.dart';
import '../services/auth_service.dart';
import '../services/product_service.dart';
import '../services/customer_service.dart';
import '../models/user_role.dart';

class AppShellViewModel {
  final AuthService _authService = AuthService();
  final NotificationViewModel _notifications = NotificationViewModel();
  final CustomerService _customerService = CustomerService();
  final ProductService _productService = ProductService();

  UserRole role = UserRole.admin;
  String selectedRoute = 'dashboard';

  void changeRole(UserRole value) {
    role = value;
    selectedRoute = 'dashboard';
  }

  void select(String route) => selectedRoute = route;

  Future<(String, int)> loadTopBar() async {
    final session = await _authService.getCurrentSession();
    await _notifications.load();
    final count = _notifications.unreadCount;
    return (session?.displayName ?? 'Nhân viên', count);
  }

  Future<(List<Product>, List<Customer>)> search(String keyword) async {
    final products = await _productService.getProducts();
    final customers = await _customerService.getCustomers();
    final query = keyword.trim().toLowerCase();
    return (
      products
          .where(
            (p) =>
                '${p.sku} ${p.name} ${p.brand}'.toLowerCase().contains(query),
          )
          .take(8)
          .toList(),
      customers
          .where((c) => '${c.name} ${c.phone}'.toLowerCase().contains(query))
          .take(8)
          .toList(),
    );
  }

  Future<List<Map<String, dynamic>>> loadNotifications() async {
    await _notifications.load();
    return _notifications.notifications;
  }

  Future<void> markNotificationRead(String id) async {
    await _notifications.markRead(id);
  }

  Future<void> logout() => _authService.logout();

  bool canAccess(String route) {
    const staffRoutes = {
      'dashboard',
      'pos',
      'customers',
      'holds',
      'returns',
      'shifts',
      'attendance',
      'income',
    };
    const managerRoutes = {
      ...staffRoutes,
      'inventory',
      'staff',
      'payroll',
      'promotions',
    };
    const adminRoutes = {...managerRoutes, 'finance', 'settings'};

    return switch (role) {
      UserRole.staff => staffRoutes.contains(route),
      UserRole.manager => managerRoutes.contains(route),
      UserRole.admin => adminRoutes.contains(route),
    };
  }
}
