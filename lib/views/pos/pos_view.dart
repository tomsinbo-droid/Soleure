import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/money_formatter.dart';
import '../../models/cart_item.dart';
import '../../models/customer.dart';
import '../../models/product.dart';
import '../../models/user_role.dart';
import '../../view_models/pos_view_model.dart';
import '../../widgets/page_header.dart';
import '../../widgets/section_card.dart';
import '../../widgets/app_loading_overlay.dart';

class PosView extends StatefulWidget {
  const PosView({super.key, required this.role});
  final UserRole role;

  @override
  State<PosView> createState() => _PosViewState();
}

class _PosViewState extends State<PosView> {
  final _vm = PosViewModel();
  final _search = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      await AppLoading.run(_vm.loadFromFirebase);
      if (mounted) setState(() {});
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Không tải được POS: $error')));
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          title: 'POS · Bán hàng tại quầy',
          subtitle:
              'Tìm SKU, thêm sản phẩm, gắn khách hàng, áp dụng promotion và thanh toán.',
          actions: [
            OutlinedButton.icon(
              onPressed: _scanSku,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Nhập / Scan SKU'),
            ),
          ],
        ),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, constraints) {
            final stacked = constraints.maxWidth < 980;
            final products = _productPanel();
            final cart = _cartPanel();
            if (stacked)
              return Column(
                children: [products, const SizedBox(height: 16), cart],
              );
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 6, child: products),
                const SizedBox(width: 16),
                Expanded(flex: 4, child: cart),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        _pendingQrPanel(),
      ],
    );
  }

  Widget _productPanel() {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _search,
            onChanged: (value) => setState(() => _vm.search = value),
            decoration: const InputDecoration(
              hintText: 'Tìm theo SKU, tên sản phẩm hoặc hãng...',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 820
                  ? 3
                  : constraints.maxWidth >= 520
                  ? 2
                  : 1;
              final width =
                  (constraints.maxWidth - (columns - 1) * 12) / columns;
              final products = _vm.filteredProducts;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final product in products)
                    SizedBox(
                      width: width,
                      child: _ProductCard(
                        product: product,
                        onTap: () => setState(() => _vm.addProduct(product)),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _cartPanel() {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Bill hiện tại',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.pink.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${_vm.cart.length} SKU',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<Customer>(
            initialValue: _vm.selectedCustomer,
            decoration: const InputDecoration(
              labelText: 'Khách hàng',
              prefixIcon: Icon(Icons.person_outline),
            ),
            items: _vm.customers
                .map(
                  (c) => DropdownMenuItem(
                    value: c,
                    child: Text('${c.name} · ${c.phone}'),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() {
              _vm.selectedCustomer = value;
              _vm.invalidateSale();
            }),
          ),
          const SizedBox(height: 14),
          if (_vm.cart.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.canvas,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 36,
                    color: AppColors.muted,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Chưa có sản phẩm trong bill',
                    style: TextStyle(color: AppColors.muted),
                  ),
                ],
              ),
            )
          else
            for (final item in _vm.cart)
              _CartRow(
                item: item,
                onMinus: () => setState(() => _vm.decrease(item)),
                onPlus: () => setState(() => _vm.increase(item)),
                onSelectUnits: () => _selectUnits(item),
                selectedCodes: item.unitIds.map((id) {
                  for (final u in _vm.units) {
                    if (u['id'] == id) return u['unitCode']?.toString() ?? id;
                  }
                  return id;
                }).toList(),
              ),
          const Divider(height: 28),
          _AmountRow('Tạm tính sau giảm', formatVnd(_vm.subtotal)),
          const SizedBox(height: 8),
          _AmountRow(
            'KPI Staff dự kiến (${(_vm.commissionRate * 100).toStringAsFixed(0)}%)',
            formatVnd(_vm.commissionPreview),
            valueColor: AppColors.success,
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: _vm.paymentMethod,
            decoration: const InputDecoration(
              labelText: 'Phương thức thanh toán',
              prefixIcon: Icon(Icons.account_balance_wallet_outlined),
            ),
            items: const [
              'Tiền mặt',
              'QR / Chuyển khoản',
            ].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
            onChanged: (value) => setState(() {
              _vm.paymentMethod = value ?? _vm.paymentMethod;
              _vm.invalidateSale();
            }),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _vm.cart.isEmpty || _saving
                      ? null
                      : _showHoldDialog,
                  icon: const Icon(Icons.lock_clock_outlined),
                  label: const Text('Hold'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: _vm.cart.isEmpty || _saving ? null : _completeBill,
                  icon: const Icon(Icons.check_circle_outline),
                  label: Text(
                    '${_vm.paymentMethod == 'Tiền mặt' ? 'Thu tiền mặt' : 'Tạo bill QR chờ đối soát'} · ${formatVnd(_vm.subtotal)}',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _selectUnits(CartItem item) async {
    final options = _vm.availableUnits(item.product);
    final chosen = <String>{...item.unitIds};
    final result = await showDialog<List<String>>(
      context: context,
      builder: (dialog) => StatefulBuilder(
        builder: (context, refresh) => AlertDialog(
          title: Text('Chọn mã xe · ${item.product.sku}'),
          content: SizedBox(
            width: 420,
            child: options.isEmpty
                ? const Text(
                    'SKU này chưa có mã xe khả dụng. Vẫn có thể bán theo SKU.',
                  )
                : ListView(
                    shrinkWrap: true,
                    children: options.map((unit) {
                      final id = unit['id'].toString();
                      return CheckboxListTile(
                        title: Text(unit['unitCode']?.toString() ?? id),
                        subtitle: Text(
                          '${unit['condition'] ?? ''} · ${unit['location'] ?? ''}',
                        ),
                        value: chosen.contains(id),
                        onChanged: (checked) => refresh(() {
                          if (checked == true && chosen.length < item.quantity)
                            chosen.add(id);
                          if (checked != true) chosen.remove(id);
                        }),
                      );
                    }).toList(),
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialog),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialog, chosen.toList()),
              child: const Text('Chọn xe'),
            ),
          ],
        ),
      ),
    );
    if (result != null && mounted) setState(() => _vm.setUnits(item, result));
  }

  Widget _pendingQrPanel() => SectionCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'QR / Chuyển khoản chờ đối soát',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            IconButton(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              tooltip: 'Tải lại',
            ),
          ],
        ),
        const Text(
          'Bill QR giữ tồn tối đa 20 phút. Staff không được tự xác nhận đã thu tiền.\n'
          'Manager/Admin nhập mã giao dịch sau khi kiểm tra sao kê ngân hàng.',
        ),
        const SizedBox(height: 8),
        if (_vm.pendingQr.isEmpty) const Text('Không có bill QR đang chờ.'),
        for (final row in _vm.pendingQr)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${row['id']} · ${formatVnd((row['total'] as num? ?? 0).toDouble())}',
                  ),
                ),
                if (widget.role != UserRole.staff)
                  OutlinedButton(
                    onPressed: () => _confirmQr(row),
                    child: const Text('Đối soát'),
                  ),
              ],
            ),
          ),
      ],
    ),
  );

  Future<void> _confirmQr(Map<String, dynamic> row) async {
    String bankId = '';
    String amount = '';
    bool checked = false;
    final approved = await showDialog<bool>(
      context: context,
      builder: (dialog) => StatefulBuilder(
        builder: (context, refresh) => AlertDialog(
          title: const Text('Đối chiếu giao dịch ngân hàng'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Bill ${row['id']} · ${formatVnd((row['total'] as num).toDouble())}',
              ),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Mã giao dịch trên sao kê',
                ),
                onChanged: (v) => bankId = v,
              ),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Số tiền thực nhận (VNĐ)',
                ),
                keyboardType: TextInputType.number,
                onChanged: (v) => amount = v,
              ),
              CheckboxListTile(
                value: checked,
                title: const Text('Đã kiểm tra giao dịch thực tế trên sao kê'),
                onChanged: (v) => refresh(() => checked = v ?? false),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialog, false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: checked ? () => Navigator.pop(dialog, true) : null,
              child: const Text('Xác nhận đã nhận tiền'),
            ),
          ],
        ),
      ),
    );
    if (approved != true || !mounted) return;
    final parsed = int.tryParse(amount.trim());
    if (parsed == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Nhập số tiền hợp lệ.')));
      return;
    }
    try {
      await _vm.confirmQrPayment(row['id'].toString(), bankId, parsed);
      await _load();
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã đối soát QR, trừ kho và ghi KPI.')),
        );
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Không xác nhận được QR: $e')));
    }
  }

  Future<void> _scanSku() async {
    String code = '';
    final result = await showDialog<String>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('Nhập / Scan SKU'),
        content: TextField(
          autofocus: true,
          onChanged: (v) => code = v,
          onSubmitted: (v) => Navigator.pop(dialog, v),
          decoration: const InputDecoration(
            labelText: 'SKU từ bàn phím hoặc máy quét',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialog, code),
            child: const Text('Tìm'),
          ),
        ],
      ),
    );
    if (result == null || result.trim().isEmpty) return;
    _search.text = result.trim();
    setState(() => _vm.search = result.trim());
  }

  Future<void> _completeBill() async {
    if (_saving || _vm.cart.isEmpty) return;
    final isCash = _vm.paymentMethod == 'Tiền mặt';
    if (isCash) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialog) => AlertDialog(
          title: const Text('Xác nhận đã thu tiền mặt'),
          content: Text(
            'Bạn đã thực sự nhận đủ ${formatVnd(_vm.subtotal)} từ khách? '
            'Sau khi xác nhận, hệ thống sẽ tạo đơn, trừ kho và ghi hoa hồng.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialog, false),
              child: const Text('Chưa nhận'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialog, true),
              child: const Text('Đã nhận tiền'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }
    setState(() => _saving = true);
    try {
      if (isCash) {
        final result = await _vm.completeCashSale();
        if (!mounted) return;
        setState(() => _vm.clearCart());
        await _load();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Đơn ${result['id']} đã ghi nhận. '
              'Số tiền được backend tính lại theo giá hiện hành.',
            ),
          ),
        );
      } else {
        final result = await _vm.completeQrPayment();
        if (!mounted) return;
        setState(() => _vm.clearCart());
        await _load();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Bill QR ${result['id']} · ${formatVnd((result['total'] as num).toDouble())}. '
              'Chờ đối chiếu sao kê, chưa tính doanh thu/KPI.',
            ),
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Không xử lý được bill: $error')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _showHoldDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('Tạo Hold Item'),
        content: const Text(
          'Giữ số lượng hàng trong bill trong 30 phút. '
          'Số lượng giữ sẽ không được bán cho bill khác. '
          'Hold hết hạn được giải phóng bởi Firebase Scheduler.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialog, true),
            child: const Text('Tạo Hold'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _saving = true);
    try {
      final id = await _vm.holdCart();
      if (!mounted) return;
      setState(() => _vm.clearCart());
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Đã giữ hàng. Mã: $id')));
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Không giữ được hàng: $error')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product, required this.onTap});
  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.divider),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 88,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.cream, AppColors.sky],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Icon(
                  Icons.directions_car_filled_outlined,
                  size: 42,
                  color: AppColors.darkBlue,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              product.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              '${product.sku} · ${product.brand}',
              style: const TextStyle(color: AppColors.muted, fontSize: 11),
            ),
            const SizedBox(height: 10),
            if (product.promoPercent > 0)
              Text(
                formatVnd(product.price),
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 11,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    formatVnd(product.sellingPrice),
                    style: const TextStyle(
                      color: AppColors.blue,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(
                  'Tồn ${product.stock}',
                  style: TextStyle(
                    color: product.stock <= 2
                        ? AppColors.danger
                        : AppColors.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              product.location,
              style: const TextStyle(color: AppColors.muted, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartRow extends StatelessWidget {
  const _CartRow({
    required this.item,
    required this.onMinus,
    required this.onPlus,
    required this.onSelectUnits,
    required this.selectedCodes,
  });
  final CartItem item;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final VoidCallback onSelectUnits;
  final List<String> selectedCodes;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  formatVnd(item.product.sellingPrice),
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
                TextButton(
                  onPressed: onSelectUnits,
                  child: Text(
                    selectedCodes.isEmpty
                        ? 'Chọn mã xe (tùy chọn)'
                        : 'Xe: ${selectedCodes.join(', ')}',
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onMinus,
            icon: const Icon(Icons.remove_circle_outline, size: 20),
          ),
          Text(
            '${item.quantity}',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          IconButton(
            onPressed: onPlus,
            icon: const Icon(Icons.add_circle_outline, size: 20),
          ),
          SizedBox(
            width: 94,
            child: Text(
              formatVnd(item.lineTotal),
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _AmountRow extends StatelessWidget {
  const _AmountRow(this.label, this.value, {this.valueColor = AppColors.ink});
  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(label, style: const TextStyle(color: AppColors.muted)),
      ),
      Text(
        value,
        style: TextStyle(color: valueColor, fontWeight: FontWeight.w900),
      ),
    ],
  );
}
