# Sprint 3.3 — Clean MVVM + Tái sử dụng biến + Firebase seed

## Phạm vi

Nền: Sprint 3.2. Giữ giao diện Soléure, theme, images và widget chung. Không thay Cloud Functions, Firestore Rules hay cấu trúc user/role. Không dùng state-management package.

## Refactor

- Xóa `lib/data/demo_data.dart` và `lib/core/constants/demo_mode.dart`. Không còn `SOLEURE_DEMO` hay nhánh giả lập dữ liệu trong các service và màn hình.
- Đổi `InventoryViewModel.products`, `CustomerViewModel.customers`, `PosViewModel.products` từ danh sách hard-code thành `[]`, đọc qua service.
- `PosViewModel.walkInCustomer` là một đối tượng UI bất biến, không có document Firebase và không được tính là data demo.
- Dùng các service lưu tại trường `_productService`, `_customerService`, `_inventoryService`... trong ViewModel để không `new Service()` mỗi thao tác.
- Các service lưu `_db` hoặc `_storage` dưới dạng `late final` để tái sử dụng Firebase instance; tránh khởi tạo Firebase trước khi chạy `Firebase.initializeApp()`.
- `FirebaseCollections` tập trung tên collection trong Flutter; tên tương ứng trong Cloud Functions/rules được giữ nguyên theo hợp đồng backend. `AppDefaults` tập trung giá trị mặc định trong Flutter.
- Thay unit test POS vốn lấy dòng sản phẩm hard-code từ ViewModel bằng fixture riêng trong `test/view_models/pos_view_model_test.dart`.
- Đã loại bỏ unit test `test/services_demo_test.dart` (chỉ kiểm thử chế độ demo cũ).

## Đường đọc dữ liệu của intern

`InventoryView` → `InventoryViewModel.loadProducts()` → `ProductService.getProducts()` → `products` (Firestore) → `setState()` tại View.

`PosView` → `PosViewModel.completeCashSale()` → `PosService.completeCashSale()` → Cloud Function `completeCashSale` → transaction cập nhật `orders`, `products`, `commission_events`.

`AuthViewModel.login()` → `AuthService.login()` (Firebase Auth) → `AuthService.getCurrentSession()` → `users/{uid}` (name, email, role, active trong một document).

## Script seed

Một nguồn dữ liệu mẫu `functions/scripts/seed_data.js`. Script `functions/scripts/seed_firebase.js` là lệnh quản trị Node.js, dùng Firebase Admin SDK từ thư mục `functions`. Theo mặc định không ghi, phải có `--apply --confirm-project <exact-ID> --with-users`. Chỉ hỗ trợ project có tên DEV/TEST/DEMO hoặc emulator; không tự xóa, reset, nâng quyền tài khoản cũ hoặc ghi đè tồn kho.

Script tạo product và opening ledger trong cùng transaction, đồng thời tạo hồ sơ từng xe và khóa chống trùng mã trong cùng transaction. Các chứng từ mẫu chỉ Pending; script không tạo hóa đơn Paid hay thanh toán giả.

## Kết quả QA trong môi trường hiện tại

- `node --check functions/index.js`: PASS.
- `node --check functions/scripts/seed_firebase.js`: PASS.
- `node functions/test/smoke.js`: PASS (mô phỏng Cloud Functions).
- `node functions/test/seed_safety_test.js`: PASS (preview và guard, dữ liệu).
- `flutter analyze`, `flutter test`, UI device và Firebase DEV thực: CHƯA CHẠY do không có Flutter SDK và cấu hình DEV.

**Không xem dry-run là bằng chứng seed Firebase thật thành công.**
