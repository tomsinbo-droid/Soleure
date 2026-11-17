import 'package:app_project/app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Soléure login screen renders', (tester) async {
    await tester.pumpWidget(const SoleureApp());

    expect(find.text('Đăng nhập'), findsWidgets);
    expect(find.text('Đăng nhập để quản lý hoạt động cửa hàng Soléure.'), findsOneWidget);
  });
}
