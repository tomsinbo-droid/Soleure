// Công dụng tệp: Đổi trả hàng.

import 'package:flutter/material.dart';

import '../../models/user_role.dart';
import '../../core/utils/money_formatter.dart';
import '../../view_models/returns_view_model.dart';
import '../../widgets/data_table_shell.dart';
import '../../widgets/page_header.dart';
import '../../widgets/section_card.dart';
import '../../widgets/app_loading_overlay.dart';

class ReturnsView extends StatefulWidget {
  const ReturnsView({super.key, required this.role});
  final UserRole role;
  /// Tạo trạng thái quản lý vòng đời và dữ liệu của màn hình.
  @override
  State<ReturnsView> createState() => _ReturnsViewState();
}

class _ReturnsViewState extends State<ReturnsView> {
  final _vm = ReturnsViewModel();
  bool _isLoading = false;

  /// Khởi tạo trạng thái cần thiết khi thành phần được tạo.
  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Tải dữ liệu đổi trả hàng và cập nhật trạng thái tương ứng.
  Future<void> _load() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }
    try {
      await AppLoading.run(_vm.load);
      if (mounted) setState(() {});
    } catch (error) {
      _message('Không tải được yêu cầu: $error');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Hiển thị thông báo cho người dùng trên màn hình.
  void _message(String message) {
    if (mounted)
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
  }

  /// Tạo mới dữ liệu đổi trả hàng theo thông tin được cung cấp.
  Future<void> _create() async {
    String orderId = '',
        sku = '',
        reason = '',
        quantity = '1',
        type = 'Return',
        replacementSku = '';
    String unitCodes = '', replacementUnitCodes = '';
    final orders = _vm.returnableOrders;
    Map<String, dynamic>? selectedOrder() {
      for (final order in orders) {
        if (order['id'] == orderId) return order;
      }
      return null;
    }

    final yes = await showDialog<bool>(
      context: context,
      builder: (dialog) => StatefulBuilder(
        builder: (context, refresh) => AlertDialog(
          title: const Text('Tạo yêu cầu đổi / trả'),
          content: SizedBox(
            width: 380,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: orderId.isEmpty ? null : orderId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Bill gốc đã thanh toán',
                    ),
                    hint: const Text('Chọn bill đã thanh toán'),
                    items: orders
                        .map(
                          (order) => DropdownMenuItem(
                            value: order['id'].toString(),
                            child: Text(
                              '${order['id']} · ${formatVnd((order['total'] as num? ?? 0).toDouble())}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => refresh(() {
                      orderId = value ?? '';
                      sku = '';
                      unitCodes = '';
                    }),
                  ),
                  if (orders.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'Chưa có bill đã thanh toán để đổi/trả.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  if (selectedOrder() != null)
                    DropdownButtonFormField<String>(
                      value: sku.isEmpty ? null : sku,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Sản phẩm trên bill',
                      ),
                      hint: const Text('Chọn sản phẩm cần đổi/trả'),
                      items: (selectedOrder()!['items'] as List<dynamic>? ?? [])
                          .map((item) => Map<String, dynamic>.from(item as Map))
                          .map(
                            (item) => DropdownMenuItem(
                              value: item['sku']?.toString(),
                              child: Text(
                                '${item['sku']} ×${item['quantity']}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) => refresh(() => sku = value ?? ''),
                    ),
                  TextField(
                    onChanged: (v) => quantity = v,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Số lượng'),
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: type,
                    items: const [
                      DropdownMenuItem(
                        value: 'Return',
                        child: Text('Trả hàng'),
                      ),
                      DropdownMenuItem(
                        value: 'Exchange',
                        child: Text('Đổi hàng'),
                      ),
                    ],
                    onChanged: (v) => refresh(() => type = v ?? type),
                  ),
                  if (type == 'Exchange')
                    TextField(
                      onChanged: (v) => replacementSku = v,
                      decoration: const InputDecoration(
                        labelText: 'SKU đổi ngang giá',
                      ),
                    ),
                  TextField(
                    onChanged: (v) => unitCodes = v,
                    decoration: const InputDecoration(
                      labelText: 'Mã hồ sơ xe trả (ID, cách nhau dấu phẩy)',
                    ),
                  ),
                  if (type == 'Exchange')
                    TextField(
                      onChanged: (v) => replacementUnitCodes = v,
                      decoration: const InputDecoration(
                        labelText: 'Mã hồ sơ xe đổi (ID, tùy chọn)',
                      ),
                    ),
                  TextField(
                    onChanged: (v) => reason = v,
                    decoration: const InputDecoration(labelText: 'Lý do'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialog, false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialog, true),
              child: const Text('Gửi yêu cầu'),
            ),
          ],
        ),
      ),
    );
    if (yes != true) return;
    try {
      await _vm.create(
        orderId.trim(),
        sku.trim(),
        int.parse(quantity),
        type,
        reason,
        replacementSku: type == 'Exchange' ? replacementSku.trim() : null,
        unitIds: unitCodes
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
        replacementUnitIds: replacementUnitCodes
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
      );
      if (mounted) setState(() {});
      _message(
        'Đã gửi yêu cầu đổi/trả. Chưa hoàn tiền, hoàn kho hoặc thu hồi KPI.',
      );
    } catch (error) {
      _message('Không lưu được yêu cầu: $error');
    }
  }

  /// Hoàn tất xử lý đổi trả hàng.
  Future<void> _settle(Map<String, dynamic> row) async {
    bool restockable = true;
    String bankRefundId = '';
    String bankRefundAmount = '';
    bool checkedBankRefund = false;
    final bankRefund =
        row['paymentMethod'] == 'qr' && row['type'] != 'Exchange';
    final id = row['id'].toString();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialog) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          title: Text(
            row['type'] == 'Exchange'
                ? 'Hoàn tất đổi ngang giá'
                : bankRefund
                ? 'Xác nhận hoàn khoản ngân hàng'
                : 'Hoàn tất trả tiền mặt',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                bankRefund
                    ? 'Xác nhận sau khi ngân hàng đã hoàn khoản cho khách. Nhập mã giao dịch hoàn khoản thật.'
                    : 'Chỉ xác nhận khi đã nhận hàng và hoàn tiền mặt thực tế nếu là phiếu trả.',
              ),
              if (bankRefund)
                Text(
                  'Số tiền cần hoàn: ${formatVnd((row['expectedRefundAmount'] as num? ?? 0).toDouble())}',
                ),
              if (bankRefund)
                TextField(
                  onChanged: (v) => bankRefundId = v,
                  decoration: const InputDecoration(
                    labelText: 'Mã giao dịch hoàn khoản trên sao kê',
                  ),
                ),
              if (bankRefund)
                TextField(
                  onChanged: (v) => bankRefundAmount = v,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Số tiền thực hoàn trên sao kê (VNĐ)',
                  ),
                ),
              if (bankRefund)
                CheckboxListTile(
                  value: checkedBankRefund,
                  title: const Text(
                    'Đã đối chiếu sao kê hoàn khoản và đúng số tiền',
                  ),
                  onChanged: (v) =>
                      update(() => checkedBankRefund = v ?? false),
                ),
              CheckboxListTile(
                value: restockable,
                onChanged: (v) => update(() => restockable = v ?? false),
                title: const Text('Hàng đủ điều kiện nhập lại kho'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialog, false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: (!bankRefund || checkedBankRefund)
                  ? () => Navigator.pop(dialog, true)
                  : null,
              child: const Text('Xác nhận'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true) return;
    try {
      await _vm.settle(
        id,
        restockable,
        row['replacementSku']?.toString(),
        bankRefundId: bankRefund ? bankRefundId.trim() : null,
        bankRefundAmount: bankRefund
            ? int.tryParse(bankRefundAmount.trim())
            : null,
      );
      if (mounted) setState(() {});
      _message('Đã hoàn tất xử lý kho/doanh thu/KPI bằng giao dịch Firebase.');
    } catch (error) {
      _message('Không thể hoàn tất phiếu: $error');
    }
  }

  /// Xây dựng giao diện của thành phần từ trạng thái hiện tại.
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          title: 'Đổi / trả hàng',
          subtitle:
              'Tìm bill gốc, chọn sản phẩm, xác định lý do và ghi KPI Adjustment thay vì xóa lịch sử.',
          actions: [
            FilledButton.icon(
              onPressed: _isLoading ? null : _create,
              icon: const Icon(Icons.assignment_return_outlined),
              label: const Text('Tạo yêu cầu'),
            ),
          ],
        ),
        const SizedBox(height: 18),
        if (_isLoading)
          const SectionCard(
            child: SizedBox(
              height: 180,
              child: Center(child: CircularProgressIndicator()),
            ),
          )
        else if (_vm.records.isEmpty)
          const SectionCard(
            child: SizedBox(
              height: 120,
              child: Center(child: Text('Chưa có yêu cầu đổi/trả nào.')),
            ),
          )
        else
          SectionCard(
            child: DataTableShell(
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Bill gốc')),
                  DataColumn(label: Text('Sản phẩm')),
                  DataColumn(label: Text('Loại')),
                  DataColumn(label: Text('Lý do')),
                  DataColumn(label: Text('Điều chỉnh doanh thu')),
                  DataColumn(label: Text('KPI Adjustment')),
                ],
                rows: List.generate(_vm.records.length, (i) {
                  final row = _vm.records[i];
                  final request = _vm.requests[i];
                  return DataRow(
                    cells: [
                      DataCell(Text(row.$1)),
                      DataCell(Text(row.$2)),
                      DataCell(Text(row.$3)),
                      DataCell(Text(row.$4)),
                      DataCell(Text(row.$5)),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(row.$6),
                            if (widget.role != UserRole.staff &&
                                request['status'] == 'Pending')
                              IconButton(
                                tooltip: 'Hoàn tất phiếu',
                                icon: const Icon(Icons.check_circle_outline),
                                onPressed: () => _settle(request),
                              ),
                          ],
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
      ],
    );
  }
}
