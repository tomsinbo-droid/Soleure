# Soléure Sprint 3.3 — Báo cáo kiểm tra

## Kết quả có thể xác nhận trong môi trường hiện tại

| Hạng mục | Kết quả |
|---|---|
| Xóa `demo_data.dart`, `demo_mode.dart`, tham chiếu `DemoData`/`SOLEURE_DEMO` trong `lib/` | PASS |
| Dữ liệu sản phẩm, khách hàng, POS không còn fixture khởi tạo trong ViewModel | PASS |
| Tên collection & defaults dùng chung | PASS |
| Không còn import Dart nội bộ tới file đã xóa | PASS |
| Kiểm tra cơ bản cân bằng dấu ngoặc và đường dẫn 78 file Dart | PASS tĩnh |
| Đối chiếu 12 tài nguyên theme/assets/widgets chung với Sprint 3.2 | 12/12 byte-for-byte PASS |
| Giữ đủ các file màn hình từ Sprint 3.2 | PASS |
| `node --check functions/index.js` | PASS |
| `node --check functions/scripts/seed_firebase.js` | PASS |
| `node functions/test/smoke.js` | PASS (backend mock) |
| `node functions/test/seed_safety_test.js` | PASS (CLI guard/schema/preview) |
| `node functions/scripts/seed_firebase.js --project soleure-intern-dev --dry-run` | PASS, không truy cập Firebase |
| `flutter analyze` | CHƯA CHẠY — không có Flutter SDK |
| `flutter test` | CHƯA CHẠY — không có Flutter SDK |
| Firebase Auth + Firestore DEV seed `--apply` | CHƯA CHẠY — chưa có project/credentials DEV |
| Firebase DEV E2E + UI visual | CHƯA CHẠY |

## Lưu ý

- Kiểm tra tĩnh không thay thế compiler Flutter. Cần chạy `flutter analyze` và `flutter test` trước demo.
- Chưa có bằng chứng `--apply` ghi thành công, tạo Auth users hay deploy Cloud Functions.
- Script mặc định **không ghi**, yêu cầu tham số xác nhận project DEV; account mẫu tự sinh mật khẩu và cất cục bộ.
- Dữ liệu mẫu chỉ tồn tại trên DEV sau khi tự chạy script; bản ZIP không chứa secret hoặc database export.
- 8 View thay đổi phần import/khởi tạo/listener demo hoặc dùng biến mặc định; không thay màu sắc, ảnh, widget chung hay tái thiết kế layout.
- Đối chiếu UI byte-for-byte chỉ áp dụng assets/theme/widgets chung, chưa xác nhận pixel-perfect.
