import '../../core/constants/app_defaults.dart';
import 'package:flutter/material.dart';

import '../../core/utils/money_formatter.dart';
import '../../models/user_role.dart';
import '../../view_models/staff_view_model.dart';
import '../../widgets/data_table_shell.dart';
import '../../widgets/page_header.dart';
import '../../widgets/section_card.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/app_loading_overlay.dart';

class StaffView extends StatefulWidget {
  const StaffView({super.key, required this.role});
  final UserRole role;
  @override
  State<StaffView> createState() => _StaffViewState();
}

class _StaffViewState extends State<StaffView> {
  final StaffViewModel _vm = StaffViewModel();
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      await AppLoading.run(_vm.load);
      if (mounted) setState(() {});
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không tải được nhân sự: $error')),
        );
    }
  }

  Future<void> _createStaff() async {
    String name = '',
        email = '',
        phone = '',
        hourly = '${AppDefaults.hourlyRateDefault}';
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(
          widget.role == UserRole.admin
              ? 'Tạo tài khoản Staff'
              : 'Đề xuất tài khoản Staff',
        ),
        content: SizedBox(
          width: 390,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: 'Họ tên'),
                onChanged: (v) => name = v,
              ),
              TextField(
                decoration: const InputDecoration(labelText: 'Email'),
                onChanged: (v) => email = v,
              ),
              TextField(
                decoration: const InputDecoration(labelText: 'Số điện thoại'),
                onChanged: (v) => phone = v,
              ),
              TextFormField(
                initialValue: hourly,
                decoration: const InputDecoration(labelText: 'Lương giờ (VND)'),
                keyboardType: TextInputType.number,
                onChanged: (v) => hourly = v,
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
            child: const Text('Gửi đề xuất'),
          ),
        ],
      ),
    );
    if (accepted != true) return;
    final amount = int.tryParse(hourly);
    if (amount == null) {
      _message('Lương giờ phải là số.');
      return;
    }
    try {
      if (widget.role == UserRole.admin) {
        await _vm.createAccount(name, email, phone, 'staff', amount);
      } else {
        await _vm.propose(name, email, phone, amount);
      }
      if (mounted) setState(() {});
      _message(
        widget.role == UserRole.admin
            ? 'Đã tạo Staff. Thiết lập mật khẩu qua email Quên mật khẩu.'
            : 'Đã gửi đề xuất. Admin duyệt trước khi Staff đặt mật khẩu.',
      );
    } catch (error) {
      _message('Không tạo được Staff: $error');
    }
  }

  Future<void> _reviewStaff(String id) async {
    final approved = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('Phê duyệt tài khoản Staff'),
        content: const Text(
          'Duyệt đề xuất Staff. Với Firebase Spark, tài khoản '
          'Authentication cần được tạo riêng trong Firebase Console.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            child: const Text('Từ chối'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialog, true),
            child: const Text('Duyệt'),
          ),
        ],
      ),
    );
    if (approved == null) return;
    try {
      await _vm.review(id, approved);
      if (mounted) setState(() {});
      _message('Đã xử lý đề xuất tài khoản.');
    } catch (error) {
      _message('Không phê duyệt được: $error');
    }
  }

  Future<void> _createManager() async {
    String name = '',
        email = '',
        phone = '',
        hourly = '${AppDefaults.hourlyRateDefault}';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('Tạo tài khoản Manager'),
        content: SizedBox(
          width: 390,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: 'Họ tên'),
                onChanged: (v) => name = v,
              ),
              TextField(
                decoration: const InputDecoration(labelText: 'Email'),
                onChanged: (v) => email = v,
              ),
              TextField(
                decoration: const InputDecoration(labelText: 'Điện thoại'),
                onChanged: (v) => phone = v,
              ),
              TextFormField(
                initialValue: hourly,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Lương giờ'),
                onChanged: (v) => hourly = v,
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
            child: const Text('Tạo'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final rate = int.tryParse(hourly);
    if (rate == null) {
      _message('Lương giờ chưa hợp lệ.');
      return;
    }
    try {
      await _vm.createAccount(name, email, phone, 'manager', rate);
      if (mounted) setState(() {});
      _message('Đã tạo Manager; đặt mật khẩu qua email Quên mật khẩu.');
    } catch (error) {
      _message('Không thể tạo Manager: $error');
    }
  }

  Future<void> _editAccount(
    String uid,
    String currentName,
    String currentPhone,
    String currentRole,
    double currentRate,
    bool currentActive,
  ) async {
    String name = currentName, phone = currentPhone;
    String role = currentRole == 'Manager' ? 'manager' : 'staff';
    String hourly = currentRate.toInt().toString();
    bool active = currentActive;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialog) => StatefulBuilder(
        builder: (dialog, refresh) => AlertDialog(
          title: const Text('Chỉnh sửa tài khoản nhân viên'),
          content: SizedBox(
            width: 390,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  initialValue: name,
                  decoration: const InputDecoration(labelText: 'Họ tên'),
                  onChanged: (v) => name = v,
                ),
                TextFormField(
                  initialValue: phone,
                  decoration: const InputDecoration(labelText: 'Số điện thoại'),
                  onChanged: (v) => phone = v,
                ),
                DropdownButtonFormField<String>(
                  initialValue: role,
                  decoration: const InputDecoration(labelText: 'Vai trò'),
                  items: const [
                    DropdownMenuItem(value: 'manager', child: Text('Manager')),
                    DropdownMenuItem(value: 'staff', child: Text('Staff')),
                  ],
                  onChanged: (v) => refresh(() => role = v ?? role),
                ),
                TextFormField(
                  initialValue: hourly,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Lương giờ (VND)',
                  ),
                  onChanged: (v) => hourly = v,
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(active ? 'Đang hoạt động' : 'Đã khóa'),
                  value: active,
                  onChanged: (v) => refresh(() => active = v),
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
      ),
    );
    if (confirmed != true) return;
    final rate = int.tryParse(hourly);
    if (rate == null) {
      _message('Lương giờ chưa hợp lệ.');
      return;
    }
    try {
      await _vm.updateAccount(uid, name, phone, role, rate, active);
      if (mounted) setState(() {});
      _message('Đã cập nhật hồ sơ và trạng thái Firebase.');
    } catch (error) {
      _message('Không lưu được tài khoản: $error');
    }
  }

  void _message(String text) {
    if (mounted)
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          title: 'Quản lý nhân sự',
          subtitle:
              'Theo dõi Staff, tình trạng làm việc, mức lương giờ và hiệu suất.',
          actions: [
            if (widget.role == UserRole.admin)
              OutlinedButton.icon(
                onPressed: _createManager,
                icon: const Icon(Icons.admin_panel_settings_outlined),
                label: const Text('Tạo Manager'),
              ),
            FilledButton.icon(
              onPressed: _createStaff,
              icon: const Icon(Icons.person_add_alt),
              label: const Text('Tạo Staff'),
            ),
          ],
        ),
        const SizedBox(height: 18),
        SectionCard(
          child: DataTableShell(
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Mã')),
                DataColumn(label: Text('Họ tên')),
                DataColumn(label: Text('Vai trò')),
                DataColumn(label: Text('Điện thoại')),
                DataColumn(label: Text('Lương giờ')),
                DataColumn(label: Text('Doanh số tháng')),
                DataColumn(label: Text('Trạng thái')),
              ],
              rows: _vm.staff
                  .map(
                    (s) => DataRow(
                      cells: [
                        DataCell(Text(s.id)),
                        DataCell(Text(s.name)),
                        DataCell(Text(s.role)),
                        DataCell(Text(s.phone)),
                        DataCell(Text(formatVnd(s.hourlyRate))),
                        DataCell(Text(s.sales == 0 ? '-' : formatVnd(s.sales))),
                        DataCell(
                          widget.role == UserRole.admin &&
                                  _vm.pendingIds.contains(s.id)
                              ? TextButton(
                                  onPressed: () => _reviewStaff(s.id),
                                  child: const Text('Pending · Duyệt'),
                                )
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    StatusChip(s.status),
                                    if (widget.role == UserRole.admin &&
                                        s.role != 'Admin' &&
                                        !_vm.pendingIds.contains(s.id))
                                      IconButton(
                                        tooltip: 'Chỉnh sửa / Khóa tài khoản',
                                        onPressed: () => _editAccount(
                                          s.id,
                                          s.name,
                                          s.phone == '-' ? '' : s.phone,
                                          s.role,
                                          s.hourlyRate,
                                          s.status == 'Active',
                                        ),
                                        icon: const Icon(
                                          Icons.edit_outlined,
                                          size: 18,
                                        ),
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
        ),
      ],
    );
  }
}
