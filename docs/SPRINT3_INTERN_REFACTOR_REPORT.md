> **LƯU TRỮ / SPRINT CŨ:** Tài liệu này thuộc Sprint 3.1–3.2. Hướng dẫn demo offline và các ví dụ code có thể không còn đúng ở Sprint 3.3. Xem `README_INTERNS.md` và `docs/SPRINT3_3_SEED_AND_REUSE.md` cho phiên bản hiện tại.

> Lưu ý: tài liệu ghi nhận Sprint 3.1. Trong Sprint 3.2, `FirebaseService` đã được tách theo module; xem `SPRINT3_2_SERVICE_REFACTOR.md`.

# Soléure — Sprint 3.1 / Intern Demo Cleanup

**Nền:** Sprint 3 Inventory. **Sprint 4 chưa triển khai.**

## Điều chỉnh đã thực hiện

1. **User model đơn giản, một document:** thêm `lib/models/user_profile.dart` đọc các trường `uid`, `displayName`, `email`, `phone`, `role`, `hourlyRate`, `active` từ `users/{uid}`. Không tách bảng role. Model không có hàm ghi quyền trực tiếp để intern không nhầm role có thể tự cập nhật.
2. **Staff + Payroll dùng chung model:** `StaffViewModel` và `PayrollViewModel` đọc `UserProfile` thay vì map rời rạc, giữ nguyên layout bảng và logic doanh số dự kiến.
3. **Backend tạo Staff:** khi Admin duyệt `staff_requests`, cùng một document `users/{uid}` có thêm `email` bên cạnh `displayName`, `phone`, `role`, `hourlyRate`, `active`. Phiếu đề xuất vẫn lưu lịch sử riêng. Đã thêm Node mock test kiểm tra trường email và role, xử lý lặp bị chặn.
4. **Inventory View chỉ gọi ViewModel:** thay các lần `vm.service.*` ở tab Nhà cung cấp/Phiếu nhập/Kiểm kê/Từng xe bằng các hàm ngắn `vm.loadSuppliers`, `vm.loadReceipts`, `vm.loadStocktakes`, `vm.loadUnits`, `vm.deactivateSupplier`. Không đổi widget hay xử lý giao dịch backend.
5. **Dữ liệu demo:** thêm 3 user mẫu (Admin, Manager, Staff) và 1 nhà cung cấp mẫu; chế độ demo giữ dữ liệu trong bộ nhớ, không truy cập Firebase.
6. **Test / docs:** thêm `test/models/user_profile_test.dart` và `docs/SPRINT3_INTERN_SCHEMA.md`, `docs/SPRINT3_INTERN_DEMO.md`.

## Những gì cố ý KHÔNG thay đổi

- Toàn bộ UI gốc, theme, assets, widgets dùng chung; không redesign.
- Không thêm Provider/Riverpod/Bloc/GetX/ChangeNotifier; dùng `StatefulWidget`, `setState()`.
- Không tạo các collection `user_profiles`, `user_roles`, `receipt_lines`, `stocktake_lines`.
- Không gom các collection giao dịch (`orders`, `stock_movements`, `commission_events`) vào `users`/`products`: các bản ghi này cần lịch sử và quyền giao dịch độc lập.
- Không đơn giản hóa/chuyển logic tồn, thanh toán, KPI hay phân quyền khỏi Cloud Functions, vì sẽ làm hỏng tính toàn vẹn dữ liệu.
- Không thêm webhook QR hoặc gắn `unitCode` xuyên suốt POS (ngoài Sprint 3.1).

## QA thực thi tại môi trường chỉnh sửa

- `node --check functions/index.js` — PASS.
- `npm --prefix functions test` — PASS, bao gồm mock nhân sự mới + regression Sprint 2/3.
- Kiểm tra import nội bộ Dart, cấu trúc token sơ bộ, JSON/YAML — PASS (đây KHÔNG phải Flutter analyzer).
- So với ZIP Sprint 3: **19 file View, 18 file không đổi; 1 file (`inventory_sprint3_panels.dart`) chỉ đổi cách gọi ViewModel**. 12/12 file assets/theme/widgets khớp UI gốc.
- **Chưa chạy** `flutter analyze`, `flutter test`, build trên thiết bị, Firebase Rules Emulator, DEV E2E do môi trường không có Flutter/Dart SDK hoặc Firebase project đã kết nối.

## Tương thích / triển khai

- Không đổi tên field hay collection; `email` mới là trường bổ sung. Tài khoản cũ chưa có `email` trên Firestore vẫn được xử lý bằng chuỗi rỗng trong model, không thay role.
- Client và Functions Sprint 3.1 nên được deploy cùng nhau trên **Firebase DEV** trước khi demo online. Không deploy production dựa trên test mô phỏng.
- Nếu chạy offline, `--dart-define=SOLEURE_DEMO=true` không cần Firebase; dữ liệu chỉ tồn tại trong bộ nhớ ứng dụng.
