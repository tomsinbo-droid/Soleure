> **LƯU TRỮ / SPRINT CŨ:** Tài liệu này thuộc Sprint 3.1–3.2. Hướng dẫn demo offline và các ví dụ code có thể không còn đúng ở Sprint 3.3. Xem `README_INTERNS.md` và `docs/SPRINT3_3_SEED_AND_REUSE.md` cho phiên bản hiện tại.

# Soléure Sprint 3.2 — QA và phạm vi bàn giao

## Phạm vi sửa

Tách `lib/services/firebase_service.dart` (Sprint 3.1: 904 dòng) thành 16 service nghiệp vụ và một helper Cloud Function, chuyển mock data thành `lib/data/demo_data.dart`, bổ sung `lib/core/constants/demo_mode.dart`, cập nhật ViewModel và import/callback của các View. Không thay đổi schema database hay ý nghĩa nghiệp vụ.

## Kết quả kiểm thử thực hiện trong môi trường này

| Kiểm tra | Kết quả |
|---|---|
| Sự tồn tại các local imports, không còn import `firebase_service.dart` | PASS trên 83 file Dart trong `lib/` và `test/` |
| Kiểm tra cân bằng dấu ngoặc Dart bằng lexer | PASS (kiểm tra tĩnh, không thay thế Dart analyzer) |
| View không trực tiếp gọi `...Service()` | PASS |
| Đồng nhất các widget layout của Views so với Sprint 3.1 (đối chiếu chuỗi widget) | PASS |
| File `assets/`, `lib/core/theme/`, `lib/widgets/` | PASS, 12/12 file khớp byte-for-byte |
| `functions/index.js`, Firebase rules và cấu hình deploy | PASS, không chỉnh sửa so với Sprint 3.1 |
| `node --check functions/index.js` | PASS |
| `npm --prefix functions test` | PASS: Sprint 2 regressions + Sprint 3 inventory/approval/roles |
| `flutter analyze`, `flutter test`, render Flutter thực tế | CHƯA CHẠY: không có Flutter/Dart SDK |
| Firebase DEV Emulator / E2E / máy thật | CHƯA CHẠY: chưa có project DEV được kết nối |

## Điều cần intern thực hiện trên máy có Flutter

```bash
flutter pub get
flutter analyze
flutter test
flutter test --dart-define=SOLEURE_DEMO=true
flutter run --dart-define=SOLEURE_DEMO=true
```

Tiếp theo cấu hình riêng Firebase DEV bằng `flutterfire configure`, deploy đúng rules/functions, kiểm thử đăng nhập theo role, nhập kho một lần, duyệt phiếu trùng, kiểm kê bị thay đổi tồn, QR chỉ lưu nháp, và kiểm tra đối chiếu layout trên màn hình thực tế.

## Lưu ý

Backend được giữ nguyên để tránh thay đổi cơ chế giao dịch/role lúc đơn giản hóa phía Flutter. File `functions/index.js` vẫn tương đối dài; phân rã backend sẽ là một thay đổi có phạm vi riêng và cần regression Firebase Emulator kỹ hơn.

Đây là **source đã refactor và kiểm tra tĩnh + regression mô phỏng backend**, chưa xác nhận build trên Flutter, chưa nghiệm thu Firebase DEV và chưa thể coi là production-ready.
