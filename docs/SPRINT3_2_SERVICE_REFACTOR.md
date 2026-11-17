> **LƯU TRỮ / SPRINT CŨ:** Tài liệu này thuộc Sprint 3.1–3.2. Hướng dẫn demo offline và các ví dụ code có thể không còn đúng ở Sprint 3.3. Xem `README_INTERNS.md` và `docs/SPRINT3_3_SEED_AND_REUSE.md` cho phiên bản hiện tại.

# Soléure — Sprint 3.2: Tách Firebase Service theo nghiệp vụ

## Mục tiêu

- **Giữ nguyên UI gốc**: sidebar, bảng, form, tab, theme, ảnh và widget hiển thị.
- **Giữ MVVM đơn giản**: `View → ViewModel → Service → Firebase`, không Provider, BLoC, Riverpod, GetX, `ChangeNotifier` hoặc listener nâng cao.
- **Tách FirebaseService cũ (~900 dòng)** thành 16 service độc lập. Không giữ file `firebase_service.dart` dạng façade để intern không phải tìm đúng hàm trong một class quá lớn.
- Tách dữ liệu giả ra `lib/data/demo_data.dart`, bật demo bằng `SOLEURE_DEMO=true`.
- Giữ dữ liệu Firestore hiện tại, không tạo collection `roles` hay `profiles` riêng: `users/{uid}` vẫn chứa `displayName`, `email`, `phone`, `role`, `hourlyRate`, `active`.

## Sơ đồ source

```text
lib/
  models/               # Product, UserProfile, Customer...
  views/                # Widget Flutter, UI gốc, setState()
  view_models/           # Xử lý sự kiện, gọi service theo module
  services/
    auth_service.dart       # Login/logout/session
    staff_service.dart      # Danh sách staff, phiếu đề xuất, profile
    product_service.dart    # Sản phẩm, giá, hình ảnh sản phẩm
    supplier_service.dart   # Nhà cung cấp
    inventory_service.dart  # Phiếu nhập, kiểm kê, từng xe, sổ tồn
    damage_service.dart     # Hao hụt và ảnh biên bản
    customer_service.dart   # Khách hàng, lịch sử mua
    pos_service.dart        # Đơn nháp, đơn tiền mặt, đơn bán
    hold_service.dart       # Giữ và hủy giữ hàng
    return_service.dart     # Phiếu đổi/trả
    shift_service.dart      # Ca làm và đổi ca
    attendance_service.dart # Chấm công và yêu cầu chỉnh công
    payroll_service.dart    # KPI, điều chỉnh lương, chốt kỳ nội bộ
    finance_service.dart    # Chi phí
    promotion_service.dart  # Khuyến mãi
    settings_service.dart   # Cài đặt
    firebase_callable.dart  # Helper gọi Cloud Functions
  data/
    demo_data.dart          # Dữ liệu giả dùng chung cho các service
  core/constants/
    demo_mode.dart          # Cờ môi trường demo
  core/utils/
    id_helper.dart          # Mã request
functions/index.js           # Giữ nguyên transaction backend Sprint 3.1
```

## Ví dụ: intern lần theo nút từ UI đến Firebase

**Danh sách sản phẩm:**
1. `views/inventory/inventory_view.dart` gọi `_vm.loadProducts()`.
2. `view_models/inventory_view_model.dart` gọi `ProductService().getProducts()`.
3. `services/product_service.dart` gọi Firestore collection `products` (hoặc `DemoData.products` khi demo).
4. View dùng `setState()` sau khi dữ liệu được tải.

**Duyệt nhập kho:**
1. Panel Kho gọi `InventorySprint3ViewModel.reviewReceipt(...)`.
2. ViewModel gọi `InventoryService().reviewPurchaseReceipt(...)`.
3. `InventoryService` gọi `FirebaseCallable.call('reviewPurchaseReceipt', ...)`.
4. `functions/index.js` xử lý quyền, transaction, cộng tồn và giá vốn. Không sửa `products.stock` từ Flutter.

## Dữ liệu Firestore

Không sửa schema, rule, index hoặc tên collection. Một document `users/{uid}` chứa các trường người dùng và role. Các collection transaction (`orders`, `purchase_receipts`, `stocktakes`, `stock_movements`, `commission_events`) vẫn riêng để giữ lịch sử và phân quyền.

## Bảo vệ nghiệp vụ

- Không đơn giản hóa các giao dịch tiền, kho, KPI bằng cách ghi trực tiếp từ Flutter.
- Cloud Functions, Firestore/Storage rules và Firebase cấu hình DEV **giữ nguyên bản Sprint 3.1**.
- QR chưa có webhook đối soát thì chỉ được tạo đơn nháp.
- Không chứa credentials của Firebase project thật; cần `flutterfire configure` trước khi chạy trên DEV.

## Kiểm thử

- `npm --prefix functions test` — backend smoke/regression mô phỏng.
- `flutter analyze` và `flutter test` — bắt buộc chạy trên máy có Flutter SDK.
- `flutter test --dart-define=SOLEURE_DEMO=true` — test demo service.
- `flutter run --dart-define=SOLEURE_DEMO=true` — review giao diện không cần Firebase.
- `flutter run` — chạy Firebase DEV sau khi cấu hình, bắt buộc kiểm thử phân quyền và transaction trên Firebase Emulator/DEV.

Đây là **refactor client**, không phải tuyên bố Firebase DEV E2E hoặc production đã PASS.
