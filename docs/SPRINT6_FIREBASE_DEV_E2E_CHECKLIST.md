# Sprint 6 — Firebase DEV / Flutter E2E checklist (chưa chạy)

## A. Môi trường và build

- [ ] Firebase project **DEV** đúng với `flutterfire configure`; không dùng production
- [ ] Bật Authentication, Firestore, Cloud Functions và Storage cần thiết
- [ ] `firebase deploy --only firestore,functions,storage --project <DEV-ID>` thành công
- [ ] `flutter pub get`, `flutter analyze`, `flutter test`, `flutter run` đều đạt
- [ ] So sánh UI Dashboard, Finance, sidebar và assets với bản Sprint 5 gốc

## B. Finance (Admin)

- [ ] Admin tải 7 ngày/tháng/quý/tùy chọn, hiển thị đúng khoảng theo giờ Việt Nam
- [ ] Manager/Staff gọi `getFinanceReportV2` bị `permission-denied`
- [ ] Bill Cash Paid có doanh thu; QR PendingQr không tạo doanh thu
- [ ] Sau khi kiểm sao kê và xác nhận QR, doanh thu ghi ngày `paidAt`, không phải ngày tạo nháp
- [ ] Trả hàng khác tháng bán: doanh thu âm ở ngày hoàn, giá vốn đảo đúng
- [ ] KPI thu hồi âm được ghi vào kỳ giao dịch điều chỉnh
- [ ] Biên bản hư hỏng chưa duyệt không trừ lợi nhuận; đã duyệt mới tính
- [ ] Chi phí có category Định phí / Biến phí / Thuế hiển thị đúng
- [ ] Chưa chốt payroll: ghi rõ lợi nhuận tạm tính chưa đủ lương; đã chốt chỉ tính snapshot của tháng nằm trọn khoảng
- [ ] Chọn khoảng quá 93 ngày bị chặn
- [ ] Kho dữ liệu >1500 rows/kỳ được báo lỗi, không hiển thị báo cáo thiếu
- [ ] Xuất CSV UTF-8 mở được tiếng Việt; text bắt đầu `=`, `+`, `@`, `-` không chạy công thức

## C. In-app notifications

- [ ] Seed dữ liệu sau khi deploy trigger tạo thông báo đúng role
- [ ] Admin nhận đề xuất Staff/khuyến mãi chờ duyệt
- [ ] Manager nhận ca Pending, phiếu đổi ca ACCEPTED_BY_STAFF, QR PendingQr
- [ ] Staff chỉ xem thông báo của mình; không đọc được `notifications` của uid khác
- [ ] Chạm thông báo điều hướng đúng màn hình và đánh dấu đọc
- [ ] Gọi `markNotificationRead` với ID người khác bị permission-denied
- [ ] Trigger chạy lại không tạo hai notification cùng source/status/người nhận
- [ ] Thông báo cũ từ trước deploy không được hiểu là sẽ tự backfill

## D. Regression và bảo mật

- [ ] POS cash, Hold, QR, refund, tồn kho, KPI không bị ảnh hưởng
- [ ] Quy trình Staff/Shift/Attendance/Payroll Sprint 5 không bị ảnh hưởng
- [ ] `users/{uid}` vẫn chứa profile + role, không có collection phụ
- [ ] Không có data demo hard-code trong Flutter; sample chỉ tồn tại ở seed script
- [ ] Không có Admin credentials/service account/private key trong ZIP/Git
- [ ] Không gắn nhãn production ready khi E2E chưa hoàn tất
