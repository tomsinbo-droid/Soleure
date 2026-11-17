# SOLÉURE — FIREBASE SPRINT 2 — GHI NHẬN PHẠM VI

**Nguồn UI:** app_Project (1).zip; assets, theme và 6 widgets dùng chung không thay đổi. Các dialog, nút và handler mới nằm trong các màn hình gốc.

## Đã có mã nguồn Firebase

1. **Auth/RBAC:** đăng nhập, quên mật khẩu, role trong `users`, Manager đề nghị và Admin duyệt nhân sự.
2. **Inventory:** sản phẩm, cập nhật thông tin/giá có audit, nhập kho, `heldStock`, biên bản thiệt hại và ảnh qua Cloud Storage, duyệt trừ kho có stock movements.
3. **CRM:** lưu khách hàng, chỉnh thông tin, tìm lịch sử mua bằng callable; doanh số khách được backend cập nhật.
4. **POS:** bill tiền mặt khi nhân viên đánh dấu đã nhận tiền; giao dịch tính giá từ backend, giảm tồn, ghi doanh thu/KPI; retry cùng transaction ID an toàn. QR chỉ lưu nháp.
5. **Hold:** tạo/hủy/đóng theo lịch, cash checkout trọn Hold, kiểm tra không bán trùng hàng đã giữ.
6. **Returns/Exchange:** tạo phiếu theo bill gốc, quản lý xác nhận nhận hàng và trả tiền mặt; đổi SKU ngang giá, ghi hoàn tiền/cập nhật tồn/KPI adjustment.
7. **Shifts/Swap:** đăng ký ca, phân ca, Manager duyệt, phiếu đổi người và người thay đồng ý.
8. **Attendance:** check-in/out, yêu cầu chỉnh công, duyệt/không duyệt giờ công.
9. **Promotion:** Admin duyệt và áp dụng giảm giá tại thời điểm cash checkout.
10. **Payroll:** điều chỉnh lương hai cấp, đọc giờ đã duyệt, KPI phát sinh; snapshot đóng kỳ trước chỉ để kiểm tra nội bộ.
11. **Finance, Dashboard, Staff Income:** đọc dữ liệu Firestore và tổng hợp từ đơn hàng/hoàn tiền/chi phí/hao hụt/hoa hồng/giờ duyệt.
12. **Settings:** cấu hình phí/KPI/giữ hàng/lương cơ bản.

## Chưa thể tuyên bố toàn bộ tính năng hoàn thiện trong thực tế

- **QR/chuyển khoản, hoàn tiền QR:** thiếu dịch vụ ngân hàng/gateway thực tế và webhook đối soát; không tạo Paid hoặc Refund từ ảnh/screenshot.
- **Tiền lương/thực chi, thuế:** snapshot ClosedInternal không phải bảng lương đã trả hoặc đã quyết toán thuế.
- **Báo cáo lợi nhuận:** chưa bao gồm kiểm toán giá vốn, toàn bộ thuế và nghĩa vụ chi trả; các truy vấn có giới hạn kích thước, chưa có aggregation theo kỳ tối ưu.
- **Kho:** chưa có kiểm kê nhiều vòng, chứng từ mua hàng/nhà cung cấp chuyên sâu, serial hóa từng mô hình hoặc valuation accounting hoàn chỉnh.
- **Shift swap:** chưa xác thực đầy đủ giới hạn số giờ theo tuần trong mọi trường hợp.
- **Security:** cần chạy Firestore Rules/Storage Rules/Callable trên Firebase Emulator và DEV bằng 3 vai trò; chỉ có QA tĩnh và mock backend.
- **Bảo toàn UI:** đối chiếu file tĩnh không chứng minh UI render chính xác từng pixel; cần chạy trên kích thước desktop/mobile thực tế.

**Trạng thái:** Source expanded, NOT VERIFIED ON LIVE FIREBASE / NOT PRODUCTION READY.
