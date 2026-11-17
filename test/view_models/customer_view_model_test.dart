import 'package:app_project/models/customer.dart';
import 'package:app_project/view_models/customer_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Search customer on original table works', () {
    final vm = CustomerViewModel();
    vm.customers = const [
      Customer(id: 'C1', name: 'Minh', phone: '09001', totalSpend: 0, favorite: '-', lastPurchase: '-'),
      Customer(id: 'C2', name: 'Hoa', phone: '09002', totalSpend: 0, favorite: '-', lastPurchase: '-'),
    ];
    expect(vm.filter('minh').length, 1);
    expect(vm.filter('0900').length, 2);
  });
}
