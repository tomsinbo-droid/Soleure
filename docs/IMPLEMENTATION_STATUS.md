> **LƯU Ý:** Tài liệu này thuộc Sprint 1/prototype. Xem `FIREBASE_SPRINT2_COVERAGE.md` và `FIREBASE_DEV_ACCEPTANCE_SPRINT2.md` để biết trạng thái mở rộng hiện tại.

# SOLÉURE — MVVM BASIC + FIREBASE — SPRINT 1

**STATUS: IMPLEMENTED IN SOURCE / DEV E2E NOT VERIFIED / NOT PRODUCTION READY**

- UI baseline: `app_Project (1).zip`.
- Thiết kế state: View dùng `StatefulWidget`/`setState`; ViewModel lớp Dart thuần; FirebaseService tập trung.
- Tích hợp Auth, Products, Customers, Cash POS with atomic Firestore transaction, QR draft, Hold transaction + expiry scheduler, return request validated, staff request/admin approval, shifts/swap approvals, attendance, promotion proposal approval, damage reports, expense intake, dashboard, read-only payroll/income, settings.
- Không thực hiện live deploy vì không có cấu hình Firebase project của người dùng.
- Lựa chọn an toàn: QR chưa ghi Paid; Return chưa tự hoàn tiền/stock/KPI; Damage chưa tự trừ stock; Payroll chưa chốt; giới hạn giờ/tuần chưa enforce.
- `firebase_options.dart` chỉ là placeholder. Cần chạy `flutterfire configure`.
- Nút Chốt kỳ lương disabled; dữ liệu Payroll/Finance chỉ để ước tính từ tập document có giới hạn và chưa phải báo cáo tài chính đầy đủ.
- Tests: `node --check functions/index.js` và các bài kiểm tra cấu trúc/asset/import/ZIP sẽ ghi tại `docs/STATIC_QA_REPORT.md`. Không chạy được `flutter analyze`/`flutter test` hoặc Firebase staging E2E trên máy đóng gói nếu không có Flutter SDK và project Firebase DEV.
