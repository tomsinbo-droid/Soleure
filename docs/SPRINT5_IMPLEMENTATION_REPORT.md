# SOLÉURE — SPRINT 5 IMPLEMENTATION REPORT

**Baseline:** Sprint 4 (`Soleure_Sprint4_OriginalUI_Intern_MVVM_Firebase_POS_QR_Returns.zip`).
**Scope:** Staff, Shift, Shift Swap, Attendance, KPI, Payroll. Firebase DEV only. Original UI retained (no redesign).

## 1. Kiến trúc dành cho intern

`View (StatefulWidget + setState) → ViewModel (Dart thông thường) → [Staff | Shift | Attendance | Payroll]Service → Firebase/Cloud Functions`.

- Không Provider, Riverpod, Bloc, GetX, ChangeNotifier, dependency injection framework hoặc hard-coded demo data.
- Một nhân sự = **một document `users/{uid}`** chứa `displayName`, `email`, `phone`, `role`, `hourlyRate`, `active`. Không tạo bảng role hoặc bảng profile riêng.
- Dữ liệu giao dịch cần audit giữ collection riêng (`shifts`, `shift_swaps`, `attendance`, `commission_events`, `payroll_adjustments`, `payroll_records`, `staff_account_audit`).
- Khóa/tạo account, quản lý ca, check-in/out, duyệt công và snapshot lương dùng Cloud Functions, không tin trường role hoặc số tiền do Flutter tự gửi.

## 2. Những chức năng đã bổ sung

| Phân hệ | Đã code Sprint 5 | Ghi chú |
|---|---|---|
| Admin - Nhân sự | Tạo Manager/Staff, sửa tên/điện thoại/role/mức lương giờ, khóa/mở qua Firebase Auth + Firestore; ghi audit | Không được đổi quyền/khóa tài khoản Admin |
| Manager - Staff | Đề xuất tài khoản Staff để Admin duyệt (tiếp tục flow cũ) | Mật khẩu phải đặt lại qua email, không hard-code |
| Lịch làm | Đăng ký ca qua `registerShiftV2`; duyệt/phân ca; giới hạn tối đa giờ/tuần trong `system_settings/store` | Ca mới 30 phút–12 giờ; không trùng ca Approved; Pending trùng giờ bị chặn ở luồng đăng ký |
| Đổi ca | Gửi phiếu, Staff B đồng ý, Manager/Admin duyệt hoặc từ chối; Staff A được hủy phiếu chưa duyệt | `CANCELLED` không làm đổi lịch; 1 mã phiếu/ca |
| Chấm công | Check-in/out theo ca Approved bằng thời gian server, hỗ trợ nhiều ca trong ngày; duyệt hoặc từ chối công | Chỉ ca đã duyệt đúng cửa sổ thời gian mới check-in được |
| Quên checkout | Manager/Admin xử lý ca mở quá 18h thành Rejected, không tự tính công | Có lý do và lịch sử, Staff phải đối soát với Manager |
| KPI | Ghi `eligibleSales` và `commissionRate` tại sự kiện bán Cash/QR; điều chỉnh đổi trả; dashboard thu nhập đọc dữ liệu lịch sử | Event cũ thiếu các trường này được hiển thị **ước tính** |
| Payroll | Snapshot chốt nội bộ lấy lương giờ khi duyệt công thay vì lương giờ hiện tại; duyệt điều chỉnh, chặn công/điều chỉnh chờ duyệt | Không tự đánh dấu đã chi lương hoặc nộp thuế |
| Seed DEV | 4 tài khoản Admin, Manager, 2 Staff, một phiếu đề xuất tài khoản Staff và một ca Pending sắp bắt đầu | Seed chỉ tạo nếu chưa tồn tại; không tạo bill Paid/KPI giả |

## 3. File quan trọng theo luồng học

- `lib/views/staff/staff_view.dart` → `lib/view_models/staff_view_model.dart` → `lib/services/staff_service.dart` → `functions/sprint5_workforce.js`.
- `lib/views/shifts/shifts_view.dart` → `lib/view_models/shift_view_model.dart` → `lib/services/shift_service.dart` → `functions/sprint5_workforce.js` và `functions/index.js`.
- `lib/views/attendance/attendance_view.dart` → `lib/view_models/attendance_view_model.dart` → `lib/services/attendance_service.dart` → `functions/index.js`.
- `lib/views/payroll/payroll_view.dart` → `lib/view_models/payroll_view_model.dart` → `lib/services/payroll_service.dart` → `functions/index.js`.
- `functions/workforce_rules.js` chứa phép tính tuần và validation thuần JavaScript để intern test không cần Firebase.

## 4. Security và dữ liệu

1. Firestore Rules chặn **client create/update/delete** `shifts`, `shift_swaps`, `attendance`, `users`, `payroll_records`. Cloud Functions dùng Admin SDK sau khi kiểm tra role từ `users/{uid}`.
2. Manager chỉ được đọc profile role `staff` qua query `where(role == 'staff')`; Admin xem đầy đủ. Staff chỉ xem profile của bản thân.
3. `adminUpdateAccount` không cho sửa quyền Admin, đồng bộ `FirebaseAuth.disabled` và `users.active`, lưu audit. Nếu kết nối giữa Auth/Firestore thất bại, cần kiểm tra đối soát thủ công vì đây là hai hệ thống không có transaction chung.
4. Ca làm kiểm tra chồng lấp và giới hạn giờ/tuần theo giờ Việt Nam (thứ Hai–Chủ nhật); không dùng giờ máy client làm nguồn xác thực.
5. Chấm công phát sinh theo ca, không thể tự upload bảng công đã duyệt. Đóng ca quá hạn chỉ tạo Rejected.
6. Snapshot payroll tính wage theo từng dòng chấm công và `hourlyRateAtApproval` (lưu dựa trên `hourlyRateAtCheckIn`) nếu có, thay vì lấy mức lương hiện tại để hồi tố. Bản ghi cũ không có snapshot vẫn fallback về `users.hourlyRate`: cần kiểm tra thủ công nếu dữ liệu cũ thay đổi mức lương.

## 5. Giới hạn chưa thể gọi là hoàn tất production

- **Chưa chạy `flutter analyze`, `flutter test`, Flutter UI runtime hoặc Firebase DEV thật.** Môi trường đóng gói không có Flutter SDK hay Firebase credentials của dự án.
- Chốt payroll là **ClosedInternal**, chưa có ghi nhận chi lương, kê khai/khấu trừ thuế, quyết toán thuế hoặc xuất phiếu lương pháp lý.
- Không có thiết bị/kiosk xác thực vị trí chấm công; check-in dựa trên tài khoản + ca đã duyệt + thời gian server, chưa chống người dùng chia sẻ tài khoản.
- Chưa có quy trình sửa ca quên checkout để được công tự động; Manager đóng ca Rejected và phải đối soát ngoài hệ thống.
- Theo thiết kế đơn giản cho intern, mỗi ca chỉ tạo được một phiếu đổi ca (kể cả đã Cancelled/Rejected); tạo lại phiếu cho cùng ca cần cải tiến lịch sử nhiều lần ở phiên bản sau.
- Admin tạo/sửa account trên Firebase Auth và Firestore là hai hệ thống độc lập; cần nghiệm thu các trường hợp lỗi mạng giữa các bước. Seed chỉ chạy trên DEV/emulator; tuyệt đối không đưa khóa Admin SDK vào Flutter.
- Payroll preview trong Flutter giới hạn số record đọc (phù hợp demo nhỏ). Khi có dữ liệu lớn cần triển khai tổng hợp server và phân trang trước production.
- Sprint 4 QR vẫn là **đối soát sao kê thủ công**, không phải webhook ngân hàng tự động. Sprint 6 Reporting/Notifications và Sprint 7 full E2E vẫn là công việc tiếp theo.

## 6. QA thực hiện tại môi trường này

- `node --check`: `functions/index.js`, `sprint4_qr.js`, `sprint5_workforce.js`, `workforce_rules.js` — PASS.
- `npm test`: logic thuần + smoke mô phỏng Cash/QR/Hold/Kho, quyền tài khoản, tạo/duyệt ca, đổi ca, chấm công và snapshot lương lịch sử — PASS.
- `npm run seed:test`: kiểm tra chỉ dùng project DEV, dry-run, xác nhận trước khi ghi, UID/email không trùng — PASS.
- QA tĩnh Dart: 79 file, import nội bộ, đối chiếu delimiter, không có demo hard-code — PASS.
- UI assets/theme/widget dùng chung đối chiếu byte-for-byte với Sprint 4: 12/12 không đổi — PASS. Không có xác nhận pixel-by-pixel.

**Trạng thái:** Code Sprint 5 + kiểm tra mô phỏng hoàn thành; cần deploy DEV và Flutter E2E trước khi nghiệm thu demo chính thức. Không đánh dấu đã đưa lên Firebase của người dùng.
