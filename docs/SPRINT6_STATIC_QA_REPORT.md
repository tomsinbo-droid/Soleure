# Sprint 6 — Báo cáo QA tại thời điểm đóng gói

- **Nguồn:** ZIP Sprint 5 (`Soleure_Sprint5_OriginalUI_Intern_MVVM_Firebase_Workforce_Payroll.zip`).
- **Source:** 83 file Dart; không thiếu import tương đối; bracket audit tĩnh đạt; không phát hiện nhánh dữ liệu demo trong Flutter.
- **UI parity:** 12/12 tệp assets, theme và widgets dùng chung không đổi byte so với Sprint 5. Các màn hình Finance và AppShell chỉ nối luồng nghiệp vụ mới; **chưa test hiển thị pixel-by-pixel**.
- **Node syntax:** `npm run check` PASS.
- **Backend regression:** `npm test` PASS (Workforce, Sprint 2–4 smoke, report-calculator và notification role mapping).
- **Seed:** `npm run seed:test` PASS; `node scripts/seed_firebase.js --project soleure-intern-dev --dry-run --with-users` PASS, không kết nối Firebase.
- **Firestore Rules:** có rule truy cập inbox theo người nhận; **chưa test trên Firestore Emulator**.
- **Flutter SDK:** không có trong môi trường này — `flutter analyze`, `flutter test`, `flutter build` **CHƯA CHẠY**.
- **Firebase DEV:** chưa deploy Functions, Rules, seed apply, chưa E2E. Không khẳng định production-ready.

## Nhóm cần kiểm thử Sprint 7

- Chạy Flutter SDK trên thiết bị, build UI, Permissions theo Admin/Manager/Staff.
- Kiểm thử report callable, trigger notifications, rules `notifications`, deadline và idempotency bằng emulator/DEV.
- Kiểm thử biểu đồ và CSV trên Windows, Android, web nếu dự án hỗ trợ.
- Trường hợp dữ liệu lớn cần thay giới hạn 1500 documents/kỳ bằng ledger tổng hợp.
