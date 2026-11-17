import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/user_role.dart';
import '../../view_models/app_shell_view_model.dart';
import '../../widgets/brand_logo.dart';
import '../../widgets/app_loading_overlay.dart';
import '../attendance/attendance_view.dart';
import '../auth/login_view.dart';
import '../customers/customers_view.dart';
import '../dashboard/dashboard_view.dart';
import '../finance/finance_view.dart';
import '../holds/hold_items_view.dart';
import '../income/staff_income_view.dart';
import '../inventory/inventory_view.dart';
import '../payroll/payroll_view.dart';
import '../pos/pos_view.dart';
import '../promotions/promotions_view.dart';
import '../returns/returns_view.dart';
import '../settings/settings_view.dart';
import '../shifts/shifts_view.dart';
import '../staff/staff_view.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, this.role = UserRole.admin});
  final UserRole role;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final _vm = AppShellViewModel();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  String _displayName = 'Nhân viên';
  int _pendingCount = 0;

  @override
  void initState() {
    super.initState();
    _vm.changeRole(widget.role);
    _loadTopBar();
  }

  static const _items = <_NavItem>[
    _NavItem('dashboard', 'Tổng quan', Icons.grid_view_rounded),
    _NavItem('pos', 'POS bán hàng', Icons.point_of_sale_rounded),
    _NavItem('inventory', 'Kho & sản phẩm', Icons.inventory_2_outlined),
    _NavItem('customers', 'Khách hàng', Icons.people_alt_outlined),
    _NavItem('holds', 'Hold Item', Icons.lock_clock_outlined),
    _NavItem('returns', 'Đổi / trả', Icons.assignment_return_outlined),
    _NavItem('staff', 'Nhân sự', Icons.badge_outlined),
    _NavItem('shifts', 'Ca làm & đổi ca', Icons.calendar_month_outlined),
    _NavItem('attendance', 'Check-in / out', Icons.schedule_outlined),
    _NavItem('payroll', 'Bảng lương', Icons.payments_outlined),
    _NavItem('promotions', 'Khuyến mãi', Icons.sell_outlined),
    _NavItem(
      'income',
      'Thu nhập cá nhân',
      Icons.account_balance_wallet_outlined,
    ),
    _NavItem('finance', 'Tài chính & báo cáo', Icons.query_stats_outlined),
    _NavItem('settings', 'Cài đặt hệ thống', Icons.settings_outlined),
  ];

  List<_NavItem> get _visibleItems =>
      _items.where((item) => _vm.canAccess(item.route)).toList();

  Widget _screen() => switch (_vm.selectedRoute) {
    'pos' => PosView(role: _vm.role),
    'inventory' => InventoryView(role: _vm.role),
    'customers' => CustomersView(role: _vm.role),
    'holds' => HoldItemsView(role: _vm.role),
    'returns' => ReturnsView(role: _vm.role),
    'staff' => StaffView(role: _vm.role),
    'shifts' => ShiftsView(role: _vm.role),
    'attendance' => AttendanceView(role: _vm.role),
    'payroll' => PayrollView(role: _vm.role),
    'promotions' => PromotionsView(role: _vm.role),
    'income' => StaffIncomeView(role: _vm.role),
    'finance' => FinanceView(role: _vm.role),
    'settings' => SettingsView(role: _vm.role),
    _ => DashboardView(
      role: _vm.role,
      onNavigate: (route) => setState(() => _vm.select(route)),
    ),
  };

  void _select(String route) {
    setState(() => _vm.select(route));
    _loadTopBar();
  }

  Future<void> _loadTopBar() async {
    try {
      final data = await AppLoading.run(_vm.loadTopBar);
      if (!mounted) return;
      setState(() {
        _displayName = data.$1;
        _pendingCount = data.$2;
      });
    } catch (_) {
      /* Topbar vẫn hiển thị nếu đang offline. */
    }
  }

  Future<void> _globalSearch() async {
    String keyword = '';
    final query = await showDialog<String>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('Tìm nhanh'),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'SKU / tên sản phẩm / khách hàng',
          ),
          onChanged: (v) => keyword = v,
          onSubmitted: (v) => Navigator.pop(dialog, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialog, keyword),
            child: const Text('Tìm'),
          ),
        ],
      ),
    );
    if (query == null || query.trim().isEmpty) return;
    try {
      final results = await AppLoading.run(() => _vm.search(query));
      final matchedProducts = results.$1;
      final matchedCustomers = results.$2;
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialog) => AlertDialog(
          title: Text('Kết quả: ${query.trim()}'),
          content: SizedBox(
            width: 450,
            height: 330,
            child: ListView(
              children: [
                for (final p in matchedProducts)
                  ListTile(
                    leading: const Icon(Icons.inventory_2_outlined),
                    title: Text(p.name),
                    subtitle: Text('${p.sku} · ${p.stock} còn'),
                    onTap: () {
                      Navigator.pop(dialog);
                      _select(_vm.canAccess('inventory') ? 'inventory' : 'pos');
                    },
                  ),
                for (final c in matchedCustomers)
                  ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: Text(c.name),
                    subtitle: Text(c.phone),
                    onTap: () {
                      Navigator.pop(dialog);
                      _select('customers');
                    },
                  ),
                if (matchedProducts.isEmpty && matchedCustomers.isEmpty)
                  const ListTile(title: Text('Không có kết quả phù hợp.')),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialog),
              child: const Text('Đóng'),
            ),
          ],
        ),
      );
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Không thể tìm: $error')));
    }
  }

  Future<void> _showNotifications() async {
    try {
      final notes = await AppLoading.run(_vm.loadNotifications);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialog) => AlertDialog(
          title: const Text('Thông báo Soléure'),
          content: SizedBox(
            width: 420,
            height: 360,
            child: ListView(
              children: [
                if (notes.isEmpty)
                  const ListTile(title: Text('Chưa có thông báo mới.')),
                for (final note in notes)
                  ListTile(
                    leading: Icon(
                      note['isRead'] == true
                          ? Icons.notifications_none
                          : Icons.notifications_active_outlined,
                    ),
                    title: Text(note['title']?.toString() ?? 'Thông báo'),
                    subtitle: Text(note['message']?.toString() ?? ''),
                    onTap: () async {
                      try {
                        await _vm.markNotificationRead(note['id'].toString());
                        if (!dialog.mounted) return;
                        Navigator.pop(dialog);
                        final route = note['route']?.toString() ?? 'dashboard';
                        _select(_vm.canAccess(route) ? route : 'dashboard');
                      } catch (error) {
                        if (mounted)
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Không đọc được thông báo: $error'),
                            ),
                          );
                      }
                    },
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialog),
              child: const Text('Đóng'),
            ),
          ],
        ),
      );
      await _loadTopBar();
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không tải được thông báo: $error')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 980;
        return Scaffold(
          key: _scaffoldKey,
          drawer: compact
              ? Drawer(
                  child: SafeArea(
                    child: _Sidebar(
                      vm: _vm,
                      items: _visibleItems,
                      onSelect: (route) {
                        _select(route);
                        Navigator.of(context).pop();
                      },
                      onRoleChanged: (_) {},
                      onLogout: _logout,
                    ),
                  ),
                )
              : null,
          body: SafeArea(
            child: Row(
              children: [
                if (!compact)
                  SizedBox(
                    width: 270,
                    child: _Sidebar(
                      vm: _vm,
                      items: _visibleItems,
                      onSelect: _select,
                      onRoleChanged: (_) {},
                      onLogout: _logout,
                    ),
                  ),
                Expanded(
                  child: Column(
                    children: [
                      _TopBar(
                        compact: compact,
                        role: _vm.role,
                        displayName: _displayName,
                        pendingCount: _pendingCount,
                        onSearch: _globalSearch,
                        onNotifications: _showNotifications,
                        onMenu: compact
                            ? () => _scaffoldKey.currentState?.openDrawer()
                            : null,
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(22),
                          child: _screen(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _logout() async {
    await _vm.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginView()),
      (_) => false,
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.vm,
    required this.items,
    required this.onSelect,
    required this.onRoleChanged,
    required this.onLogout,
  });

  final AppShellViewModel vm;
  final List<_NavItem> items;
  final ValueChanged<String> onSelect;
  final ValueChanged<UserRole> onRoleChanged;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.darkBlue,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
      child: Column(
        children: [
          const BrandLogo(height: 86),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<UserRole>(
                value: vm.role,
                isExpanded: true,
                dropdownColor: AppColors.darkBlue,
                iconEnabledColor: AppColors.sky,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
                items: UserRole.values
                    .map(
                      (role) => DropdownMenuItem(
                        value: role,
                        child: Text('${role.label} · ${role.description}'),
                      ),
                    )
                    .toList(),
                onChanged: null,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 4),
              itemBuilder: (context, index) {
                final item = items[index];
                final selected = item.route == vm.selectedRoute;
                return Material(
                  color: selected
                      ? AppColors.sky.withValues(alpha: 0.22)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(13),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(13),
                    onTap: () => onSelect(item.route),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 11,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            item.icon,
                            color: selected ? AppColors.sky : Colors.white70,
                            size: 21,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              item.label,
                              style: TextStyle(
                                color: selected ? Colors.white : Colors.white70,
                                fontWeight: selected
                                    ? FontWeight.w800
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(color: Colors.white24),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 10),
            leading: const Icon(Icons.logout_rounded, color: AppColors.pink),
            title: const Text(
              'Đăng xuất',
              style: TextStyle(color: Colors.white),
            ),
            onTap: onLogout,
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.compact,
    required this.role,
    required this.displayName,
    required this.pendingCount,
    required this.onSearch,
    required this.onNotifications,
    this.onMenu,
  });

  final bool compact;
  final UserRole role;
  final String displayName;
  final int pendingCount;
  final VoidCallback onSearch;
  final VoidCallback onNotifications;
  final VoidCallback? onMenu;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          if (compact) ...[
            Builder(
              builder: (context) => IconButton(
                onPressed: () => Scaffold.of(context).openDrawer(),
                icon: const Icon(Icons.menu_rounded),
              ),
            ),
            const SizedBox(width: 8),
          ],
          const Text(
            'SOLÉURE',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.pink,
              shape: BoxShape.circle,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: onSearch,
            icon: const Icon(Icons.search_rounded),
          ),
          IconButton(
            onPressed: onNotifications,
            icon: Badge(
              isLabelVisible: pendingCount > 0,
              label: Text('$pendingCount'),
              child: Icon(Icons.notifications_none_rounded),
            ),
          ),
          const SizedBox(width: 10),
          CircleAvatar(
            backgroundColor: AppColors.cream,
            child: Text(
              role.label.substring(0, 1),
              style: const TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 10),
          if (!compact)
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: TextStyle(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  role.label,
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.route, this.label, this.icon);

  final String route;
  final String label;
  final IconData icon;
}
