# SOLÉURE — FIREBASE DEV ACCEPTANCE CHECKLIST

Không test trên dữ liệu production. Tạo 3 tài khoản Auth + `users/{uid}` Admin, Manager, Staff ở Firebase DEV.

- [ ] `flutter pub get`, `flutter analyze`, `flutter test` đều PASS (kiểm tra plugin Firebase Storage và file_picker).
- [ ] `firebase deploy --only firestore:rules,firestore:indexes,storage,functions:soleure` chạy trên đúng DEV project.
- [ ] Login/logout/reset password, Staff không tự cấp quyền Manager/Admin.
- [ ] Admin, Manager, Staff thấy đúng menu; Firestore client không ghi trực tiếp `orders`, `commission_events`, `stock`, `heldStock`, `payroll_records`.
- [ ] Tạo SKU, sửa giá, tạo nhập kho và kiểm tra `stock_movements`; test requestId trùng không nhập lần hai.
- [ ] Tạo biên bản hao hụt có ảnh <5 MB, xem ảnh với Manager; Staff bị từ chối; ảnh khác loại/kích thước bị từ chối.
- [ ] Tạo Hold SKU tồn 1 chiếc, đồng thời thử hai nhân viên Hold/bán; chỉ một giao dịch thành công.
- [ ] Thanh toán cash thành công, retry requestId không nhân đôi bill/hoa hồng; thay giá khi POS đang mở phải dùng giá backend.
- [ ] Duyệt promotion và kiểm tra cash checkout áp dụng mức giảm đã duyệt; không tin giá client gửi.
- [ ] QR không thể tự đánh dấu Paid khi chưa có webhook đối soát từ ngân hàng.
- [ ] Hold hết hạn Scheduler giải phóng; Hold đã cash-paid không giải phóng lần nữa.
- [ ] Tạo return theo bill cash đã Paid, hoàn cash đã xác nhận, restock tùy tình trạng và commission adjustment chỉ ghi 1 lần.
- [ ] Exchange kiểm tra SKU thay thế, không cho đổi khi giá không ngang nhau hoặc tồn không đủ.
- [ ] Staff đăng ký ca, Manager duyệt; kiểm tra trùng ca và đổi ca Staff B phải đồng ý trước.
- [ ] Check-in/out, điều chỉnh công và Manager duyệt; kỳ lương không chốt nếu còn công Pending.
- [ ] Manager đề xuất điều chỉnh lương, Admin duyệt; chốt kỳ trước chỉ tạo snapshot ClosedInternal, không tạo payment.
- [ ] Dashboard, Finance, CRM history và Staff Income cập nhật đúng sau refund/damage/KPI adjustment.
- [ ] Thử internet gián đoạn và retry, xác nhận không có bill/tồn kho/hoa hồng phát sinh trùng.
- [ ] Chụp screenshot desktop 1366×768 và mobile đối chiếu source UI gốc, đặc biệt sidebar, POS và các DataTable.
- [ ] Xem logs Cloud Functions, kiểm tra quyền Storage cross-service và các Firestore indexes trước nghiệm thu.

**Điều kiện release:** đối soát QR, các tình huống race condition, phân quyền, báo cáo tài chính và pháp lý phải được chủ dự án xác nhận.
