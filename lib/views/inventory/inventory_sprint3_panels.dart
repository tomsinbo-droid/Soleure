import 'package:flutter/material.dart';

import '../../models/product.dart';
import '../../models/user_role.dart';
import '../../view_models/inventory_view_model.dart';
import '../../widgets/data_table_shell.dart';
import '../../widgets/section_card.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/app_loading_overlay.dart';

// UI Sprint 3 dùng cùng SectionCard/DataTable như màn Kho gốc.
// Mỗi màn chỉ có StatefulWidget + setState(), không có Provider hoặc Stream.
void showInventoryMessage(BuildContext context, String message) {
  if (context.mounted) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class SuppliersPanel extends StatefulWidget {
  const SuppliersPanel({super.key, required this.role});
  final UserRole role;
  @override
  State<SuppliersPanel> createState() => _SuppliersPanelState();
}

class _SuppliersPanelState extends State<SuppliersPanel> {
  final vm = InventorySprint3ViewModel();
  bool loading = true;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      await AppLoading.run(vm.loadSuppliers);
    } catch (e) {
      if (mounted)
        showInventoryMessage(context, 'Không tải được nhà cung cấp: $e');
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> _create() async {
    String name = '', phone = '', email = '', note = '';
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('Thêm nhà cung cấp'),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Tên nhà cung cấp *',
                  ),
                  onChanged: (v) => name = v,
                ),
                TextField(
                  decoration: const InputDecoration(labelText: 'Số điện thoại'),
                  onChanged: (v) => phone = v,
                ),
                TextField(
                  decoration: const InputDecoration(labelText: 'Email'),
                  onChanged: (v) => email = v,
                ),
                TextField(
                  decoration: const InputDecoration(labelText: 'Ghi chú'),
                  onChanged: (v) => note = v,
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
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await vm.addSupplier(name, phone, email, note);
      if (mounted) setState(() {});
      if (mounted) showInventoryMessage(context, 'Đã lưu nhà cung cấp.');
    } catch (e) {
      if (mounted) showInventoryMessage(context, 'Không thể lưu: $e');
    }
  }

  Future<void> _deactivate(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Ngưng sử dụng nhà cung cấp?'),
        content: const Text('Lịch sử phiếu nhập vẫn được giữ nguyên.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(d, true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await vm.deactivateSupplier(id);
      await _load();
    } catch (e) {
      if (mounted) showInventoryMessage(context, 'Không thể ngưng: $e');
    }
  }

  @override
  Widget build(BuildContext context) => SectionCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Danh mục nhà cung cấp',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: _create,
              icon: const Icon(Icons.add),
              label: const Text('Thêm nhà cung cấp'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (loading) const LinearProgressIndicator(),
        DataTableShell(
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Tên')),
              DataColumn(label: Text('Điện thoại')),
              DataColumn(label: Text('Email')),
              DataColumn(label: Text('Trạng thái')),
            ],
            rows: vm.suppliers
                .map(
                  (r) => DataRow(
                    cells: [
                      DataCell(Text('${r['name'] ?? ''}')),
                      DataCell(Text('${r['phone'] ?? ''}')),
                      DataCell(Text('${r['email'] ?? ''}')),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            StatusChip(
                              r['active'] == true ? 'Active' : 'Inactive',
                            ),
                            if (widget.role == UserRole.admin &&
                                r['active'] == true)
                              IconButton(
                                icon: const Icon(Icons.block),
                                tooltip: 'Ngưng sử dụng',
                                onPressed: () => _deactivate('${r['id']}'),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
                .toList(),
          ),
        ),
      ],
    ),
  );
}

class PurchaseReceiptsPanel extends StatefulWidget {
  const PurchaseReceiptsPanel({super.key, required this.role});
  final UserRole role;
  @override
  State<PurchaseReceiptsPanel> createState() => _PurchaseReceiptsPanelState();
}

class _PurchaseReceiptsPanelState extends State<PurchaseReceiptsPanel> {
  final vm = InventorySprint3ViewModel();
  List<Product> products = [];
  bool loading = true;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      await AppLoading.run(vm.loadReceipts);
      products = vm.products;
    } catch (e) {
      if (mounted)
        showInventoryMessage(context, 'Không tải được phiếu nhập: $e');
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> _create() async {
    final choices = vm.suppliers.where((r) => r['active'] == true).toList();
    if (choices.isEmpty || products.isEmpty) {
      showInventoryMessage(
        context,
        'Cần tạo nhà cung cấp và SKU trước khi nhập hàng.',
      );
      return;
    }
    String supplierId = choices.first['id'].toString();
    String sku = products.first.sku, quantity = '1', cost = '0', note = '';
    final lines = <Map<String, dynamic>>[];
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialog) => StatefulBuilder(
        builder: (dialog, update) => AlertDialog(
          title: const Text('Lập phiếu nhập kho (chờ Admin duyệt)'),
          content: SizedBox(
            width: 470,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: supplierId,
                    decoration: const InputDecoration(
                      labelText: 'Nhà cung cấp',
                    ),
                    items: choices
                        .map(
                          (s) => DropdownMenuItem(
                            value: s['id'].toString(),
                            child: Text(s['name'].toString()),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => supplierId = v ?? supplierId,
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: sku,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'SKU'),
                    items: products
                        .map(
                          (p) => DropdownMenuItem(
                            value: p.sku,
                            child: Text(
                              '${p.sku} — ${p.name}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => sku = v ?? sku,
                  ),
                  TextField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Số lượng'),
                    onChanged: (v) => quantity = v,
                  ),
                  TextField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Đơn giá vốn (VND)',
                    ),
                    onChanged: (v) => cost = v,
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () {
                        final q = int.tryParse(quantity),
                            c = int.tryParse(cost);
                        if (q == null ||
                            q < 1 ||
                            c == null ||
                            c < 0 ||
                            lines.any((e) => e['sku'] == sku)) {
                          showInventoryMessage(
                            dialog,
                            'SL/giá không hợp lệ hoặc SKU đã có trong phiếu.',
                          );
                          return;
                        }
                        if (lines.length >= 20) {
                          showInventoryMessage(dialog, 'Tối đa 20 SKU/phiếu.');
                          return;
                        }
                        update(
                          () => lines.add({
                            'sku': sku,
                            'quantity': q,
                            'unitCost': c,
                          }),
                        );
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Thêm dòng'),
                    ),
                  ),
                  ...lines.map(
                    (e) => ListTile(
                      dense: true,
                      title: Text(
                        '${e['sku']} · SL ${e['quantity']} · ${e['unitCost']} đ',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => update(() => lines.remove(e)),
                      ),
                    ),
                  ),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Ghi chú chứng từ',
                    ),
                    onChanged: (v) => note = v,
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
              onPressed: lines.isEmpty
                  ? null
                  : () => Navigator.pop(dialog, true),
              child: const Text('Gửi duyệt'),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    try {
      await vm.addReceipt(supplierId, lines, note);
      await _load();
      if (mounted)
        showInventoryMessage(context, 'Đã lập phiếu, tồn chưa thay đổi.');
    } catch (e) {
      if (mounted) showInventoryMessage(context, 'Không tạo được phiếu: $e');
    }
  }

  Future<void> _review(String id, bool approved) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text(approved ? 'Duyệt phiếu nhập kho?' : 'Từ chối phiếu nhập?'),
        content: Text(
          approved
              ? 'Sau khi duyệt, hệ thống cộng tồn và tính lại giá vốn bình quân.'
              : 'Phiếu bị từ chối, tồn kho không thay đổi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(d, true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await vm.reviewReceipt(id, approved);
      await _load();
      if (mounted) showInventoryMessage(context, 'Đã xử lý phiếu nhập.');
    } catch (e) {
      if (mounted) showInventoryMessage(context, 'Không duyệt được: $e');
    }
  }

  @override
  Widget build(BuildContext context) => SectionCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Phiếu nhập kho',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: _create,
              icon: const Icon(Icons.add),
              label: const Text('Lập phiếu nhập'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (loading) const LinearProgressIndicator(),
        DataTableShell(
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Mã phiếu')),
              DataColumn(label: Text('Nhà cung cấp')),
              DataColumn(label: Text('SKU / SL / Giá vốn')),
              DataColumn(label: Text('Trạng thái')),
            ],
            rows: vm.receipts.map((r) {
              final lines = (r['lines'] as List? ?? [])
                  .map(
                    (e) => '${e['sku']} × ${e['quantity']} @ ${e['unitCost']}',
                  )
                  .join('\n');
              return DataRow(
                cells: [
                  DataCell(Text('${r['id']}')),
                  DataCell(Text('${r['supplierName'] ?? ''}')),
                  DataCell(SizedBox(width: 250, child: Text(lines))),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        StatusChip(r['status']?.toString() ?? '-'),
                        if (widget.role == UserRole.admin &&
                            r['status'] == 'Pending') ...[
                          IconButton(
                            tooltip: 'Duyệt',
                            onPressed: () => _review(r['id'].toString(), true),
                            icon: const Icon(Icons.check_circle_outline),
                          ),
                          IconButton(
                            tooltip: 'Từ chối',
                            onPressed: () => _review(r['id'].toString(), false),
                            icon: const Icon(Icons.cancel_outlined),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    ),
  );
}

class StocktakePanel extends StatefulWidget {
  const StocktakePanel({super.key, required this.role});
  final UserRole role;
  @override
  State<StocktakePanel> createState() => _StocktakePanelState();
}

class _StocktakePanelState extends State<StocktakePanel> {
  final vm = InventorySprint3ViewModel();
  List<Map<String, dynamic>> stock = [];
  bool loading = true;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      await AppLoading.run(vm.loadStocktakes);
      stock = vm.stockSnapshot;
    } catch (e) {
      if (mounted) showInventoryMessage(context, 'Không tải được kiểm kê: $e');
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> _create() async {
    if (stock.isEmpty) {
      showInventoryMessage(context, 'Chưa có SKU để kiểm kê.');
      return;
    }
    String sku = stock.first['sku'].toString(), counted = '', note = '';
    final lines = <Map<String, dynamic>>[];
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialog) => StatefulBuilder(
        builder: (dialog, update) => AlertDialog(
          title: const Text('Lập phiếu kiểm kê thực tế'),
          content: SizedBox(
            width: 470,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Đếm toàn bộ hàng vật lý, kể cả hàng đang Hold. Tồn có thể thay đổi trong lúc duyệt.',
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: sku,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'SKU'),
                    items: stock
                        .map(
                          (p) => DropdownMenuItem(
                            value: p['sku'].toString(),
                            child: Text(
                              '${p['sku']} · Tồn ${p['stock']} · Hold ${p['heldStock']}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => sku = v ?? sku,
                  ),
                  TextField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Đếm thực tế (bao gồm Hold)',
                    ),
                    onChanged: (v) => counted = v,
                  ),
                  TextField(
                    decoration: const InputDecoration(labelText: 'Ghi chú'),
                    onChanged: (v) => note = v,
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () {
                        final count = int.tryParse(counted);
                        if (count == null ||
                            count < 0 ||
                            lines.any((l) => l['sku'] == sku)) {
                          showInventoryMessage(
                            dialog,
                            'Số lượng không hợp lệ hoặc SKU trùng.',
                          );
                          return;
                        }
                        if (lines.length >= 20) {
                          showInventoryMessage(dialog, 'Tối đa 20 SKU.');
                          return;
                        }
                        update(
                          () => lines.add({
                            'sku': sku,
                            'counted': count,
                            'note': note,
                          }),
                        );
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Thêm dòng'),
                    ),
                  ),
                  ...lines.map(
                    (l) => ListTile(
                      dense: true,
                      title: Text('${l['sku']}: đếm ${l['counted']}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => update(() => lines.remove(l)),
                      ),
                    ),
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
              onPressed: lines.isEmpty
                  ? null
                  : () => Navigator.pop(dialog, true),
              child: const Text('Gửi kiểm kê'),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    try {
      await vm.addCount(lines);
      await _load();
      if (mounted)
        showInventoryMessage(context, 'Đã lưu phiếu kiểm kê chờ Admin duyệt.');
    } catch (e) {
      if (mounted) showInventoryMessage(context, 'Không lưu được: $e');
    }
  }

  Future<void> _review(String id, bool approve) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text(approve ? 'Duyệt chênh lệch kiểm kê?' : 'Từ chối kiểm kê?'),
        content: const Text(
          'Nếu tồn hoặc Hold đã thay đổi kể từ lúc lập phiếu, hệ thống sẽ chặn duyệt để tránh ghi đè dữ liệu mới.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(d, true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await vm.reviewCount(id, approve);
      await _load();
      if (mounted) showInventoryMessage(context, 'Đã xử lý phiếu kiểm kê.');
    } catch (e) {
      if (mounted) showInventoryMessage(context, 'Không thể duyệt: $e');
    }
  }

  @override
  Widget build(BuildContext context) => SectionCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Kiểm kê & điều chỉnh tồn',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: _create,
              icon: const Icon(Icons.fact_check_outlined),
              label: const Text('Lập phiếu kiểm kê'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (loading) const LinearProgressIndicator(),
        DataTableShell(
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Phiếu')),
              DataColumn(label: Text('Đếm / Tồn hệ thống / Chênh lệch')),
              DataColumn(label: Text('Trạng thái')),
            ],
            rows: vm.stocktakes.map((r) {
              final lines = (r['lines'] as List? ?? [])
                  .map(
                    (l) =>
                        '${l['sku']} · đếm ${l['counted']} / tồn ${l['expected']} · lệch ${l['difference']}',
                  )
                  .join('\n');
              return DataRow(
                cells: [
                  DataCell(Text('${r['id']}')),
                  DataCell(SizedBox(width: 340, child: Text(lines))),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        StatusChip('${r['status']}'),
                        if (widget.role == UserRole.admin &&
                            r['status'] == 'Pending') ...[
                          IconButton(
                            tooltip: 'Duyệt',
                            onPressed: () => _review(r['id'].toString(), true),
                            icon: const Icon(Icons.check_circle_outline),
                          ),
                          IconButton(
                            tooltip: 'Từ chối',
                            onPressed: () => _review(r['id'].toString(), false),
                            icon: const Icon(Icons.cancel_outlined),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    ),
  );
}

class InventoryUnitsPanel extends StatefulWidget {
  const InventoryUnitsPanel({super.key});
  @override
  State<InventoryUnitsPanel> createState() => _InventoryUnitsPanelState();
}

class _InventoryUnitsPanelState extends State<InventoryUnitsPanel> {
  final vm = InventorySprint3ViewModel();
  List<Product> products = [];
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      await AppLoading.run(vm.loadUnits);
      products = vm.products;
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) showInventoryMessage(context, 'Không tải hồ sơ xe: $e');
    }
  }

  Future<void> _create() async {
    if (products.isEmpty) {
      showInventoryMessage(context, 'Cần tạo SKU trước.');
      return;
    }
    String sku = products.first.sku, code = '', location = '', note = '';
    String condition = 'Good';
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialog) => StatefulBuilder(
        builder: (dialog, update) => AlertDialog(
          title: const Text('Ghi nhận tình trạng một xe'),
          content: SizedBox(
            width: 410,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: sku,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'SKU'),
                    items: products
                        .map(
                          (p) => DropdownMenuItem(
                            value: p.sku,
                            child: Text(
                              '${p.sku} — ${p.name}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => sku = v ?? sku,
                  ),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Mã định danh xe *',
                    ),
                    onChanged: (v) => code = v,
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: condition,
                    decoration: const InputDecoration(labelText: 'Tình trạng'),
                    items: const [
                      DropdownMenuItem(value: 'Sealed', child: Text('Sealed')),
                      DropdownMenuItem(value: 'Good', child: Text('Good')),
                      DropdownMenuItem(
                        value: 'BoxDamaged',
                        child: Text('Box Damaged'),
                      ),
                      DropdownMenuItem(
                        value: 'Defective',
                        child: Text('Defective'),
                      ),
                    ],
                    onChanged: (v) => update(() => condition = v ?? condition),
                  ),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Tủ / kệ / ngăn *',
                    ),
                    onChanged: (v) => location = v,
                  ),
                  TextField(
                    decoration: const InputDecoration(labelText: 'Ghi chú'),
                    onChanged: (v) => note = v,
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
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    try {
      await vm.addUnit(sku, code, condition, location, note);
      await _load();
      if (mounted) showInventoryMessage(context, 'Đã ghi nhận tình trạng xe.');
    } catch (e) {
      if (mounted) showInventoryMessage(context, 'Không lưu được: $e');
    }
  }

  @override
  Widget build(BuildContext context) => SectionCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Hồ sơ tình trạng từng xe',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: _create,
              icon: const Icon(Icons.add),
              label: const Text('Ghi nhận xe'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        const Text(
          'Thông tin kiểm tra từng xe, chưa tự liên kết mã xe với POS. Không dùng số hồ sơ này để xác nhận tồn thực tế.',
        ),
        const SizedBox(height: 12),
        DataTableShell(
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Mã xe')),
              DataColumn(label: Text('SKU')),
              DataColumn(label: Text('Tình trạng')),
              DataColumn(label: Text('Vị trí')),
              DataColumn(label: Text('Ghi chú')),
            ],
            rows: vm.units
                .map(
                  (u) => DataRow(
                    cells: [
                      DataCell(Text('${u['unitCode']}')),
                      DataCell(Text('${u['sku']}')),
                      DataCell(Text('${u['condition']}')),
                      DataCell(Text('${u['location']}')),
                      DataCell(Text('${u['note'] ?? ''}')),
                    ],
                  ),
                )
                .toList(),
          ),
        ),
      ],
    ),
  );
}
