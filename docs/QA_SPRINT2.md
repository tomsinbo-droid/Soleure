# SOLÉURE — SPRINT 2 STATIC QA REPORT

**Đối chiếu với UI gốc:** `app_Project (1).zip`. Chưa chạy render thực tế trên Flutter.

## PASS (đã chạy trong môi trường đóng gói)

- 59 Dart source files trong `lib/` và `test/`: không thiếu local import.
- Không có thư viện state management Provider / Riverpod / Bloc / GetX; không khai báo `ChangeNotifier` / `ValueNotifier` / `StreamBuilder` để điều phối trạng thái.
- 4/4 ảnh gốc, 2/2 theme gốc, 6/6 widget dùng chung gốc: nội dung byte-for-byte giống file original.
- `functions/index.js`: `node --check` PASS.
- `functions/test/smoke.js`: PASS bằng Firestore/Auth mô phỏng cho cash sale, retry, Hold→Sold, nhập kho, duyệt hao hụt, return/exchange, KPI, promotion, role, chấm công/chỉnh công, duyệt điều chỉnh lương, khóa snapshot, sửa sản phẩm, lịch sử CRM.
- `pubspec.yaml` YAML hợp lệ; `firebase.json`, `firestore.indexes.json`, `functions/package.json` JSON hợp lệ.
- `storage.rules`: có role Manager/Admin, ảnh JPEG/PNG/WEBP <= 5 MB, upload chỉ 1 lần, chống sửa/xóa.
- Source ZIP có integrity check. (Kết quả chi tiết ghi khi đóng gói.)

## KHÔNG CHẠY / CHƯA ĐẠT RELEASE

- Không có Flutter/Dart SDK trong runtime đóng gói: **chưa thể chạy `flutter pub get`, `flutter analyze`, `flutter test`, build Windows/Android/Web, so sánh UI bằng screenshot**. Phần `pubspec.lock` sẽ được cập nhật khi intern chạy `flutter pub get`.
- Chưa deploy Firebase DEV; không có cấu hình project thật, nên chưa kiểm thử Cloud Functions, Storage Rules, Firestore Rules, Scheduler và giao dịch concurrent trên service thực.
- Firebase Storage 14 cần Android minSdk 24+ (đã cập nhật source). Có thể phải nâng cấu hình toolchain phía thiết bị.
- Smoke dùng memory DB mô phỏng, **không** xác nhận Firestore transaction/rules hay query indexes thực.
- QR/chuyển khoản, hoàn tiền qua gateway thiếu webhook/đối soát xác thực; chỉ tồn tại luồng nháp an toàn.
- Snapshot lương nội bộ không đồng nghĩa đã trả lương hoặc xử lý thuế đúng pháp lý.
- Dashboard / Finance chưa phải báo cáo kế toán đã kiểm toán.
- Trường hợp số lượng lớn cần phân trang, aggregation, audit toàn diện và kiểm thử tải.

## KẾT LUẬN

**Đã hoàn thiện mã nguồn Firebase mở rộng ở nhiều module để thực hành và nghiệm thu trên DEV; NOT PRODUCTION READY.** Chỉ chốt triển khai sau khi hoàn tất `FIREBASE_DEV_ACCEPTANCE_SPRINT2.md`.
