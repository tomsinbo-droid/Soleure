import 'package:flutter/material.dart';

import '../../core/utils/money_formatter.dart';
import '../../models/user_role.dart';
import '../../view_models/customer_view_model.dart';
import '../../models/customer.dart';
import '../../widgets/data_table_shell.dart';
import '../../widgets/page_header.dart';
import '../../widgets/section_card.dart';
import '../../widgets/app_loading_overlay.dart';

class CustomersView extends StatefulWidget {
  const CustomersView({super.key, required this.role});
  final UserRole role;

  @override
  State<CustomersView> createState() => _CustomersViewState();
}

class _CustomersViewState extends State<CustomersView> {
  final CustomerViewModel _vm = CustomerViewModel();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      await AppLoading.run(_vm.loadCustomers);
      if (mounted) setState(() {});
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không tải được khách hàng: $error')),
        );
    }
  }

  Future<void> _addCustomer() async {
    String name = '', phone = '', favorite = '';
    final customer = await showDialog<Customer>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Thêm khách hàng'),
        content: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                onChanged: (v) => name = v,
                decoration: const InputDecoration(labelText: 'Họ tên'),
              ),
              TextField(
                onChanged: (v) => phone = v,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Điện thoại'),
              ),
              TextField(
                onChanged: (v) => favorite = v,
                decoration: const InputDecoration(labelText: 'Sở thích'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              if (name.trim().isEmpty || phone.trim().isEmpty) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                    content: Text('Vui lòng nhập họ tên và số điện thoại.'),
                  ),
                );
                return;
              }
              Navigator.pop(
                dialogContext,
                Customer(
                  id: DateTime.now().microsecondsSinceEpoch.toString(),
                  name: name.trim(),
                  phone: phone.trim(),
                  totalSpend: 0,
                  favorite: favorite.trim(),
                  lastPurchase: '-',
                ),
              );
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
    if (customer == null) return;
    try {
      await _vm.addCustomer(customer);
      if (mounted) setState(() {});
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không lưu được khách hàng: $error')),
        );
    }
  }

  Future<void> _showHistory(Customer customer) async {
    try {
      final orders = await _vm.getHistory(customer.id);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialog) => AlertDialog(
          title: Text('Lịch sử mua · ${customer.name}'),
          content: SizedBox(
            width: 440,
            height: 320,
            child: orders.isEmpty
                ? const Center(child: Text('Chưa có bill đã lưu.'))
                : ListView(
                    children: orders
                        .map(
                          (order) => ListTile(
                            title: Text(
                              'Bill ${order['id']} · ${formatVnd((order['total'] as num? ?? 0).toDouble())}',
                            ),
                            subtitle: Text(
                              'Trạng thái: ${order['status']} · Đã hoàn: ${formatVnd((order['refundedTotal'] as num? ?? 0).toDouble())}',
                            ),
                          ),
                        )
                        .toList(),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không tải được lịch sử: $error')),
        );
    }
  }

  Future<void> _editCustomer(Customer customer) async {
    if (widget.role == UserRole.staff) return;
    String name = customer.name,
        phone = customer.phone,
        favorite = customer.favorite;
    final yes = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text('Sửa khách hàng ${customer.id}'),
        content: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: name,
                onChanged: (v) => name = v,
                decoration: const InputDecoration(labelText: 'Họ tên'),
              ),
              TextFormField(
                initialValue: phone,
                onChanged: (v) => phone = v,
                decoration: const InputDecoration(labelText: 'Điện thoại'),
              ),
              TextFormField(
                initialValue: favorite,
                onChanged: (v) => favorite = v,
                decoration: const InputDecoration(labelText: 'Sở thích'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialog, true),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
    if (yes != true) return;
    try {
      await _vm.editCustomer(
        Customer(
          id: customer.id,
          name: name.trim(),
          phone: phone.trim(),
          favorite: favorite.trim(),
          totalSpend: customer.totalSpend,
          lastPurchase: customer.lastPurchase,
        ),
      );
      if (mounted) setState(() {});
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Không cập nhật được: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          title: 'Khách hàng · VIP Profile',
          subtitle: 'Hồ sơ, lịch sử mua, sở thích và tổng chi tiêu của khách.',
          actions: [
            FilledButton.icon(
              onPressed: _addCustomer,
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Tạo khách hàng'),
            ),
          ],
        ),
        const SizedBox(height: 18),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 340,
                child: TextField(
                  onChanged: (value) => setState(() => _query = value),
                  decoration: const InputDecoration(
                    hintText: 'Tìm tên / số điện thoại...',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              DataTableShell(
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Mã')),
                    DataColumn(label: Text('Khách hàng')),
                    DataColumn(label: Text('Điện thoại')),
                    DataColumn(label: Text('Tổng chi tiêu')),
                    DataColumn(label: Text('Sở thích')),
                    DataColumn(label: Text('Lần mua gần nhất')),
                  ],
                  rows: _vm
                      .filter(_query)
                      .map(
                        (c) => DataRow(
                          cells: [
                            DataCell(Text(c.id)),
                            DataCell(
                              Text(c.name),
                              onTap: () => _editCustomer(c),
                            ),
                            DataCell(Text(c.phone)),
                            DataCell(
                              Text(formatVnd(c.totalSpend)),
                              onTap: () => _showHistory(c),
                            ),
                            DataCell(
                              SizedBox(width: 180, child: Text(c.favorite)),
                            ),
                            DataCell(Text(c.lastPurchase)),
                          ],
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
