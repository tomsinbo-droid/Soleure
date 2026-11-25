// Công dụng tệp: Hàng hóa và tồn kho.

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'dart:typed_data';

import '../../core/theme/app_colors.dart';
import '../../core/utils/money_formatter.dart';
import '../../models/user_role.dart';
import '../../view_models/inventory_view_model.dart';
import '../../models/product.dart';
import '../../widgets/data_table_shell.dart';
import '../../widgets/page_header.dart';
import '../../widgets/section_card.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/app_loading_overlay.dart';
import 'inventory_sprint3_panels.dart';

class InventoryView extends StatefulWidget {
  const InventoryView({super.key, required this.role});
  final UserRole role;

  /// Tạo trạng thái quản lý vòng đời và dữ liệu của màn hình.
  @override
  State<InventoryView> createState() => _InventoryViewState();
}

class _InventoryViewState extends State<InventoryView> {
  final _vm = InventoryViewModel();
  int _tab = 0;
  String _search = '';
  String _location = '';

  /// Khởi tạo trạng thái cần thiết khi thành phần được tạo.
  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Tải dữ liệu hàng hóa và tồn kho và cập nhật trạng thái tương ứng.
  Future<void> _load() async {
    try {
      await AppLoading.run(_vm.load);
      if (mounted) setState(() {});
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Không tải được kho: $error')));
    }
  }

  /// Thêm sản phẩm.
  Future<void> _addProduct() async {
    if (widget.role == UserRole.staff) return;
    String sku = '', name = '', brand = '', series = '', location = '';
    String price = '', cost = '', stock = '';

    final product = await showDialog<Product>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Thêm sản phẩm'),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  onChanged: (v) => sku = v,
                  decoration: const InputDecoration(labelText: 'SKU'),
                ),
                TextField(
                  onChanged: (v) => name = v,
                  decoration: const InputDecoration(labelText: 'Tên sản phẩm'),
                ),
                TextField(
                  onChanged: (v) => brand = v,
                  decoration: const InputDecoration(labelText: 'Hãng'),
                ),
                TextField(
                  onChanged: (v) => series = v,
                  decoration: const InputDecoration(labelText: 'Series'),
                ),
                TextField(
                  onChanged: (v) => price = v,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Giá bán (VND)'),
                ),
                TextField(
                  onChanged: (v) => cost = v,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Giá nhập (VND)',
                  ),
                ),
                TextField(
                  onChanged: (v) => stock = v,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Tồn kho'),
                ),
                TextField(
                  onChanged: (v) => location = v,
                  decoration: const InputDecoration(labelText: 'Vị trí'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              final sellingPrice = int.tryParse(price.trim());
              final purchaseCost = int.tryParse(cost.trim());
              final quantity = int.tryParse(stock.trim());
              if (widget.role == UserRole.manager &&
                  quantity != null &&
                  quantity > 0) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Manager tạo SKU tồn 0; nhập hàng qua phiếu chờ Admin duyệt.',
                    ),
                  ),
                );
                return;
              }
              if (sku.trim().isEmpty ||
                  name.trim().isEmpty ||
                  brand.trim().isEmpty ||
                  series.trim().isEmpty ||
                  location.trim().isEmpty ||
                  sellingPrice == null ||
                  sellingPrice <= 0 ||
                  purchaseCost == null ||
                  purchaseCost < 0 ||
                  quantity == null ||
                  quantity < 0) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                    content: Text('Vui lòng nhập đủ thông tin và số hợp lệ.'),
                  ),
                );
                return;
              }
              Navigator.pop(
                dialogContext,
                Product(
                  sku: sku.trim(),
                  name: name.trim(),
                  brand: brand.trim(),
                  series: series.trim(),
                  price: sellingPrice.toDouble(),
                  cost: purchaseCost.toDouble(),
                  stock: quantity,
                  location: location.trim(),
                ),
              );
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
    if (product == null) return;
    try {
      await _vm.addProduct(product);
      if (mounted) setState(() {});
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không lưu được sản phẩm: $error')),
        );
    }
  }

  /// Chỉnh sửa sản phẩm.
  Future<void> _editProduct(Product product) async {
    if (widget.role == UserRole.staff) return;
    String name = product.name, brand = product.brand, series = product.series;
    String location = product.location,
        price = product.price.round().toString();
    bool eligible = product.kpiEligible;
    final yes = await showDialog<bool>(
      context: context,
      builder: (dialog) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          title: Text('Sửa SKU ${product.sku}'),
          content: SizedBox(
            width: 390,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    initialValue: name,
                    decoration: const InputDecoration(labelText: 'Tên'),
                    onChanged: (v) => name = v,
                  ),
                  TextFormField(
                    initialValue: brand,
                    decoration: const InputDecoration(labelText: 'Hãng'),
                    onChanged: (v) => brand = v,
                  ),
                  TextFormField(
                    initialValue: series,
                    decoration: const InputDecoration(labelText: 'Series'),
                    onChanged: (v) => series = v,
                  ),
                  TextFormField(
                    initialValue: location,
                    decoration: const InputDecoration(labelText: 'Vị trí'),
                    onChanged: (v) => location = v,
                  ),
                  TextFormField(
                    initialValue: price,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Giá bán VND'),
                    onChanged: (v) => price = v,
                  ),
                  CheckboxListTile(
                    value: eligible,
                    onChanged: (v) => update(() => eligible = v ?? true),
                    title: const Text('Tính KPI cho sản phẩm'),
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
    if (yes != true) return;
    final amount = int.tryParse(price);
    if (amount == null || amount <= 0) {
      _message('Giá bán không hợp lệ.');
      return;
    }
    try {
      await _vm.editProduct(
        Product(
          sku: product.sku,
          name: name.trim(),
          brand: brand.trim(),
          series: series.trim(),
          price: amount.toDouble(),
          cost: product.cost,
          stock: product.stock,
          location: location.trim(),
          promoPercent: product.promoPercent,
          kpiEligible: eligible,
        ),
      );
      if (mounted) setState(() {});
      _message('Đã cập nhật SKU trên Firebase.');
    } catch (error) {
      _message('Không cập nhật được SKU: $error');
    }
  }

  /// Xem xét và xử lý hao hụt.
  Future<void> _reviewDamage(String id, bool approved) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(approved ? 'Duyệt trừ tồn kho?' : 'Từ chối biên bản?'),
        content: Text(
          approved
              ? 'Chỉ duyệt khi đã kiểm tra thực tế. Hệ thống trừ kho và ghi sổ hao hụt.'
              : 'Không điều chỉnh tồn kho.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialog, true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _vm.reviewDamage(id, approved);
      if (mounted) setState(() {});
      _message('Đã xử lý biên bản.');
    } catch (error) {
      _message('Không xử lý được: $error');
    }
  }

  /// Hiển thị và xử lý ảnh của sản phẩm.
  Future<void> _productPhoto(Product p) async {
    Uint8List? bytes;
    try {
      bytes = await _vm.getProductPhoto(p.sku);
    } catch (error) {
      _message('Không đọc được ảnh: $error');
      return;
    }
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialog) => StatefulBuilder(
        builder: (dialog, update) => AlertDialog(
          title: Text('Ảnh sản phẩm ${p.sku}'),
          content: SizedBox(
            width: 400,
            child: bytes == null
                ? const Text('SKU này chưa có ảnh.')
                : Image.memory(
                    bytes!,
                    width: 360,
                    height: 260,
                    fit: BoxFit.contain,
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialog),
              child: const Text('Đóng'),
            ),
            if (widget.role != UserRole.staff)
              FilledButton.icon(
                icon: const Icon(Icons.upload_outlined),
                label: const Text('Chọn ảnh'),
                onPressed: () async {
                  try {
                    final picked = await FilePicker.pickFiles(
                      type: FileType.custom,
                      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
                    );
                    if (picked.isEmpty) return;
                    final file = picked.single;
                    final fileBytes = await file.readAsBytes();
                    await _vm.uploadProductPhoto(p.sku, fileBytes, file.name);
                    if (dialog.mounted) update(() => bytes = fileBytes);
                    _message('Đã lưu ảnh Base64 vào Firestore.');
                  } catch (error) {
                    _message('Không tải được ảnh lên: $error');
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  /// Hiển thị thông báo cho người dùng trên màn hình.
  void _message(String text) {
    if (mounted)
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  /// Tạo hao hụt.
  Future<void> _createDamage() async {
    String sku = '', reason = '', quantity = '1', loss = '0';
    String? imageName;
    Uint8List? imageBytes;
    final yes = await showDialog<bool>(
      context: context,
      builder: (dialog) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          title: const Text('Tạo biên bản hao hụt'),
          content: SizedBox(
            width: 380,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    onChanged: (v) => sku = v,
                    decoration: const InputDecoration(labelText: 'SKU'),
                  ),
                  TextField(
                    onChanged: (v) => reason = v,
                    decoration: const InputDecoration(
                      labelText: 'Sự cố / nguyên nhân',
                    ),
                  ),
                  TextField(
                    onChanged: (v) => quantity = v,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Số lượng'),
                  ),
                  TextField(
                    onChanged: (v) => loss = v,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Giá trị thiệt hại (VND)',
                    ),
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.image_outlined),
                    label: Text(
                      imageName ?? 'Chọn ảnh chứng từ (tối đa 600 KB)',
                    ),
                    onPressed: () async {
                      try {
                        final file = await FilePicker.pickFile(
                          type: FileType.image,
                        );
                        if (file == null) return;
                        final bytes = await file.readAsBytes();
                        if (bytes.lengthInBytes > 600 * 1024 || bytes.isEmpty) {
                          if (dialog.mounted)
                            ScaffoldMessenger.of(dialog).showSnackBar(
                              const SnackBar(
                                content: Text('Ảnh phải nhỏ hơn 600 KB.'),
                              ),
                            );
                          return;
                        }
                        update(() {
                          imageName = file.name;
                          imageBytes = bytes;
                        });
                      } catch (error) {
                        if (dialog.mounted)
                          ScaffoldMessenger.of(dialog).showSnackBar(
                            SnackBar(
                              content: Text('Không chọn được ảnh: $error'),
                            ),
                          );
                      }
                    },
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
              child: const Text('Lưu biên bản'),
            ),
          ],
        ),
      ),
    );
    if (yes != true) return;
    final count = int.tryParse(quantity);
    final value = int.tryParse(loss);
    if (count == null || value == null) {
      _message('Số lượng và thiệt hại phải là số.');
      return;
    }
    try {
      final id = await _vm.reportDamage(
        sku.trim(),
        reason.trim(),
        count,
        value,
      );
      if (imageBytes != null && imageName != null) {
        try {
          await _vm.uploadDamagePhoto(id, imageBytes!, imageName!);
        } catch (error) {
          _message('Biên bản đã lưu nhưng tải ảnh thất bại: $error');
          if (mounted) setState(() {});
          return;
        }
      }
      if (mounted) setState(() {});
      _message('Đã lưu biên bản chờ duyệt, chưa tự trừ tồn kho.');
    } catch (error) {
      _message('Không lưu được biên bản: $error');
    }
  }

  /// Hiển thị ảnh biên bản hao hụt.
  Future<void> _showDamagePhoto(String id) async {
    try {
      final bytes = await _vm.getDamagePhoto(id);
      if (!mounted) return;
      if (bytes == null) {
        _message('Biên bản này chưa có ảnh.');
        return;
      }
      await showDialog<void>(
        context: context,
        builder: (dialog) => AlertDialog(
          title: const Text('Ảnh biên bản'),
          content: Image.memory(bytes, width: 500, fit: BoxFit.contain),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialog),
              child: const Text('Đóng'),
            ),
          ],
        ),
      );
    } catch (error) {
      _message('Không đọc được ảnh chứng từ: $error');
    }
  }

  /// Xây dựng giao diện của thành phần từ trạng thái hiện tại.
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          title: 'Kho & sản phẩm',
          subtitle:
              'Quản lý SKU, tồn kho, vị trí vật lý và biên bản hao hụt / hư hỏng.',
          actions: [
            if (widget.role != UserRole.staff)
              OutlinedButton.icon(
                onPressed: () => setState(() => _tab = 3),
                icon: const Icon(Icons.inventory_2_outlined),
                label: const Text('Nhập kho'),
              ),
            FilledButton.icon(
              onPressed: widget.role == UserRole.staff ? null : _addProduct,
              icon: const Icon(Icons.add),
              label: const Text('Thêm sản phẩm'),
            ),
          ],
        ),
        const SizedBox(height: 18),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SegmentedButton<int>(
            segments: [
              const ButtonSegment(value: 0, label: Text('Sản phẩm & tồn kho')),
              const ButtonSegment(value: 1, label: Text('Hao hụt / hư hỏng')),
              if (widget.role != UserRole.staff) ...[
                const ButtonSegment(value: 2, label: Text('Nhà cung cấp')),
                const ButtonSegment(value: 3, label: Text('Phiếu nhập')),
                const ButtonSegment(value: 4, label: Text('Kiểm kê')),
                const ButtonSegment(value: 5, label: Text('Từng xe')),
              ],
            ],
            selected: {_tab},
            onSelectionChanged: (value) {
              setState(() => _tab = value.first);
              if (_tab == 0) _load();
            },
          ),
        ),
        const SizedBox(height: 16),
        if (_tab == 0) _products(),
        if (_tab == 1) _damage(),
        if (_tab == 2) SuppliersPanel(role: widget.role),
        if (_tab == 3) PurchaseReceiptsPanel(role: widget.role),
        if (_tab == 4) StocktakePanel(role: widget.role),
        if (_tab == 5) const InventoryUnitsPanel(),
      ],
    );
  }

  /// Xây dựng danh sách sản phẩm và tồn kho.
  Widget _products() {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 280,
                child: TextField(
                  // nhận dữ liệu vơi onChanged và lưu vào biến _search để filter danh sách sản phẩm
                  onChanged: (value) => setState(() => _search = value),
                  decoration: const InputDecoration(
                    hintText: 'Tìm SKU / tên / hãng...',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),
              SizedBox(
                width: 180,
                child: TextField(
                  onChanged: (value) => setState(() => _location = value),
                  decoration: const InputDecoration(
                    hintText: 'Vị trí',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          DataTableShell(
            child: DataTable(
              columns: const [
                DataColumn(label: Text('SKU')),
                DataColumn(label: Text('Sản phẩm')),
                DataColumn(label: Text('Hãng / Series')),
                DataColumn(label: Text('Giá bán')),
                DataColumn(label: Text('Tồn')),
                DataColumn(label: Text('Vị trí')),
                DataColumn(label: Text('Trạng thái')),
              ],
              rows: _vm
                  .filter(_search, _location)
                  .map(
                    (p) => DataRow(
                      cells: [
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _productThumbnail(p),
                              const SizedBox(width: 8),
                              Text(p.sku),
                              IconButton(
                                icon: const Icon(Icons.image_outlined),
                                tooltip: 'Ảnh sản phẩm',
                                onPressed: () => _productPhoto(p),
                              ),
                            ],
                          ),
                        ),
                        DataCell(
                          SizedBox(width: 220, child: Text(p.name)),
                          onTap: () => _editProduct(p),
                        ),
                        DataCell(Text('${p.brand}\n${p.series}')),
                        DataCell(Text(formatVnd(p.sellingPrice))),
                        DataCell(Text('${p.stock}')),
                        DataCell(Text(p.location)),
                        DataCell(
                          StatusChip(p.stock <= 2 ? 'Sắp hết' : 'Available'),
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

  /// Xây dựng ảnh thu nhỏ của sản phẩm.
  Widget _productThumbnail(Product product) {
    final encoded = product.imageBase64;
    if (encoded == null || encoded.isEmpty) {
      return const CircleAvatar(
        radius: 18,
        child: Icon(Icons.image_not_supported_outlined, size: 18),
      );
    }
    try {
      return ClipOval(
        child: Image.memory(
          base64Decode(encoded),
          width: 36,
          height: 36,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => const CircleAvatar(
            radius: 18,
            child: Icon(Icons.broken_image_outlined, size: 18),
          ),
        ),
      );
    } catch (_) {
      return const CircleAvatar(
        radius: 18,
        child: Icon(Icons.broken_image_outlined, size: 18),
      );
    }
  }

  /// Xây dựng danh sách biên bản hao hụt và hư hỏng.
  Widget _damage() {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Biên bản gần đây',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: _createDamage,
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: const Text('Tạo biên bản'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          DataTableShell(
            child: DataTable(
              columns: const [
                DataColumn(label: Text('SKU')),
                DataColumn(label: Text('Sự cố')),
                DataColumn(label: Text('SL')),
                DataColumn(label: Text('Thiệt hại')),
                DataColumn(label: Text('Trạng thái')),
              ],
              // dữ liệu được lấy từ danh sách tên damageRecords
              rows: List.generate(_vm.damageRecords.length, (i) {
                final row = _vm.damageRecords[i];
                final id = _vm.damageRows[i]['id'].toString();
                return DataRow(
                  cells: [
                    DataCell(Text(row.$1)),
                    DataCell(Text(row.$2)),
                    DataCell(Text(row.$3)),
                    DataCell(Text(row.$4)),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          StatusChip(row.$5),
                          if (widget.role != UserRole.staff)
                            IconButton(
                              tooltip: 'Xem ảnh chứng từ',
                              icon: const Icon(Icons.image_outlined),
                              onPressed: () => _showDamagePhoto(id),
                            ),
                          if (row.$5 == 'Pending' &&
                              widget.role != UserRole.staff) ...[
                            IconButton(
                              tooltip: 'Duyệt hao hụt',
                              onPressed: () => _reviewDamage(id, true),
                              icon: const Icon(Icons.check_circle_outline),
                            ),
                            IconButton(
                              tooltip: 'Từ chối',
                              onPressed: () => _reviewDamage(id, false),
                              icon: const Icon(Icons.cancel_outlined),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.cream.withValues(alpha: .38),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text(
              'Biên bản đang ở trạng thái chờ xử lý. Chỉ xác nhận điều chỉnh tồn kho qua backend sau khi kiểm tra thực tế; không tự trừ kho khi mới tạo biên bản.',
            ),
          ),
        ],
      ),
    );
  }
}
