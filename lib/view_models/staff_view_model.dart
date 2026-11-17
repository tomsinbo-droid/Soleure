import '../services/staff_service.dart';
import '../services/pos_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/staff_member.dart';

class StaffViewModel {
  final StaffService _staffService = StaffService();
  final PosService _posService = PosService();

  List<StaffMember> staff = [];
  final Set<String> pendingIds = {};

  Future<void> load() async {
    final profiles = await _staffService.getStaffProfiles();
    final orders = await _posService.getOrders();
    final requests = await _staffService.getStaffRequests();
    final month = DateTime.now();
    staff = profiles.map((profile) {
      double monthlySales = 0;
      for (final order in orders) {
        final created = (order['createdAt'] as Timestamp?)?.toDate();
        if (order['staffUid'] == profile.uid &&
            order['status'] == 'Paid' &&
            created != null &&
            created.year == month.year &&
            created.month == month.month) {
          monthlySales += (order['total'] as num? ?? 0).toDouble();
        }
      }
      return StaffMember.fromProfile(profile, monthlySales);
    }).toList();
    pendingIds.clear();
    for (final r in requests.where((e) => e['status'] == 'Pending')) {
      final id = r['id']?.toString() ?? '';
      pendingIds.add(id);
      staff.add(
        StaffMember(
          id: id,
          name: r['name']?.toString() ?? '-',
          role: 'Staff đề xuất',
          phone: r['phone']?.toString() ?? '-',
          hourlyRate: (r['hourlyRate'] as num? ?? 0).toDouble(),
          status: 'Pending',
          sales: 0,
        ),
      );
    }
  }

  Future<void> propose(
    String name,
    String email,
    String phone,
    int hourlyRate,
  ) async {
    await _staffService.proposeStaff(name, email, phone, hourlyRate);
    await load();
  }

  Future<void> review(String id, bool approved) async {
    await _staffService.reviewStaff(id, approved);
    await load();
  }

  Future<void> createAccount(
    String name,
    String email,
    String phone,
    String password,
    String role,
    int hourlyRate,
  ) async {
    await _staffService.createAccount(
      name: name,
      email: email,
      phone: phone,
      password: password,
      role: role,
      hourlyRate: hourlyRate,
    );
    await load();
  }

  Future<void> updateAccount(
    String uid,
    String name,
    String phone,
    String role,
    int hourlyRate,
    bool active,
  ) async {
    await _staffService.updateAccount(
      uid: uid,
      name: name,
      phone: phone,
      role: role,
      hourlyRate: hourlyRate,
      active: active,
    );
    await load();
  }
}
