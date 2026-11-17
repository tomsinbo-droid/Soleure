> **LƯU TRỮ / SPRINT CŨ:** Tài liệu này thuộc Sprint 3.1–3.2. Hướng dẫn demo offline và các ví dụ code có thể không còn đúng ở Sprint 3.3. Xem `README_INTERNS.md` và `docs/SPRINT3_3_SEED_AND_REUSE.md` cho phiên bản hiện tại.

> Cập nhật Sprint 3.2: service được tách theo module; xem `docs/SPRINT3_2_SERVICE_REFACTOR.md`.

# Soléure — Hướng dẫn intern demo Sprint 3.1

## Mục tiêu

- Giới thiệu kiến trúc **View → ViewModel → Service theo module → Firebase**, giữ nguyên UI gốc.
- Minh họa nhân viên + vai trò ở cùng **users/{uid}**; danh sách Role không có bảng phụ.
- Minh họa quá trình **phiếu nhập Pending → Admin duyệt → tồn kho thay đổi**, và kiểm kê tương tự.
- Nói đúng giới hạn: demo là dữ liệu trong bộ nhớ; không có thanh toán thực, không có Firebase DEV thật nếu chưa cấu hình.

## Chạy demo không cần kết nối mạng/Firebase

Tại thư mục `app_Project`:

```bash
flutter pub get
flutter run --dart-define=SOLEURE_DEMO=true
```

Đăng nhập với email `admin@soleure.vn` / password demo `123456` (chỉ để qua UI; demo mode **không xác thực** Firebase). Không dùng mật khẩu này cho tài khoản Firebase thật. Nên sử dụng Flutter desktop hoặc thiết bị thử nghiệm để trình diễn giao diện gốc.

## Kịch bản thực hành (8 bước)

1. **Login:** giới thiệu `LoginView` → `AuthViewModel` → `AuthService`; giải thích `UserProfile` nhận tên, email, điện thoại, role từ một document.
2. **Nhân sự:** mở menu Nhân sự; dữ liệu demo có Admin, Manager và Staff. Đọc `StaffViewModel.load()`; không tự cấp `role` từ giao diện.
3. **Kho:** mở Kho & sản phẩm; xem các SKU mẫu đang có.
4. **Nhà cung cấp:** đã có `SUP-DEMO`, có thể tạo nhà cung cấp mới bằng dialog. Thực hiện View → ViewModel → Service.
5. **Phiếu nhập:** chọn nhà cung cấp, SKU, số lượng, đơn giá, nhấn Gửi duyệt. Phiếu hiển thị `Pending`; tồn kho chưa tăng.
6. **Admin duyệt:** tại tab Phiếu nhập nhấn Duyệt. Chuyển tab Sản phẩm và quan sát tồn thay đổi; không duyệt hai lần.
7. **Kiểm kê:** chọn SKU, điền số đếm thực tế và gửi. Phiếu `Pending`; duyệt mới cập nhật tồn. Giải thích khi tồn thay đổi phải lập lại phiếu.
8. **Từng xe:** lưu mã xe riêng, tình trạng hộp/vị trí; thử nhập trùng cùng SKU và mã xe sẽ báo lỗi. Nhắc rằng hồ sơ này chưa tự trừ tồn khi POS bán.

Trong bản demo, các thay đổi chỉ tồn tại khi ứng dụng còn chạy. Không coi đây là test chứng minh Cloud Functions hoạt động.

## Đọc code theo thứ tự

| Thứ tự | File | Intern tìm hiểu gì |
|---|---|---|
| 1 | `lib/models/user_profile.dart` | Một user gồm những field nào, role đọc từ đâu |
| 2 | `lib/views/staff/staff_view.dart` | Cách hiển thị bảng nhân sự, nút tạo và duyệt |
| 3 | `lib/view_models/staff_view_model.dart` | Cách ViewModel lấy thông tin rồi chuẩn bị dòng dữ liệu |
| 4 | `lib/views/inventory/inventory_sprint3_panels.dart` | Một dialog nhập dữ liệu và một nút duyệt |
| 5 | `lib/view_models/inventory_view_model.dart` | `loadReceipts`, `addReceipt`, `reviewReceipt` |
| 6 | `lib/services/inventory_service.dart` | `getPurchaseReceipts`, `createPurchaseReceipt`, `reviewPurchaseReceipt` |
| 7 | `functions/index.js` | Transaction bảo vệ nhập kho, chỉ xem sau khi hiểu Flutter |
| 8 | `firestore.rules` | Vì sao Staff không thể tự sửa số liệu quan trọng |

**Intern chỉ cần đọc service của màn hình đang demo; không phải đọc toàn bộ Cloud Functions trước khi thực hành.** Bắt đầu từ một tính năng rồi lần theo một hàm.

## Kiểm thử Firebase thật (sau demo)

1. Dùng **Firebase DEV riêng**. `flutterfire configure --project <DEV_PROJECT>` và kiểm tra project ID trước khi deploy.
2. Bật Authentication, Firestore, Storage; deploy Rules + Functions theo `README_INTERNS.md`. Không đưa service-account key vào Flutter.
3. Tạo Admin/Auth UID; tạo `users/{uid}` có `displayName`, `email`, `phone`, `role`, `hourlyRate`, `active` bằng Firebase Console hoặc Admin SDK, không từ app.
4. Kiểm thử Manager tạo phiếu, Admin duyệt; kiểm thử Staff bị từ chối ghi kho; thử duyệt lại để không tăng tồn lần nữa.
5. Chạy `flutter analyze`, `flutter test` và Firebase Emulator/E2E; kiểm tra UI trên thiết bị. Chưa có bằng chứng các bước này đã đạt.

## Trạng thái

Bản này refactor cho intern và đã kiểm thử tĩnh/Node mock. Không thiết kế lại UI. **Chưa thể xác nhận build Flutter và Firebase DEV E2E** nếu không có SDK/project đang kết nối.
