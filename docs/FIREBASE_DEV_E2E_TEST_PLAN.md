> **LƯU Ý:** Tài liệu này thuộc Sprint 1/prototype. Xem `FIREBASE_SPRINT2_COVERAGE.md` và `FIREBASE_DEV_ACCEPTANCE_SPRINT2.md` để biết trạng thái mở rộng hiện tại.

# Soléure — kế hoạch nghiệm thu Firebase DEV

**Điều kiện trước chạy:** Flutter SDK, Firebase Auth, Firestore Rules/Indexes và Functions đã deploy trên project DEV. Môi trường hiện tại chưa thực hiện test E2E hoặc deploy. Mỗi testcase ghi `PASS/FAIL`, ảnh/video và Firestore document ID tương ứng.

| ID | Flow | Kỳ vọng |
|---|---|---|
| AUTH-01 | Staff đăng nhập đúng UID/role | Chỉ thấy menu Staff, không truy cập tài chính |
| AUTH-02 | Staff tự sửa `users/{uid}.role` | Firestore PERMISSION_DENIED |
| AUTH-03 | Manager tạo Staff, Admin duyệt | Firebase Auth có email, `users/{uid}` role staff, request Approved |
| CAT-01 | Manager thêm SKU, Staff cố thêm | Manager tạo được; Staff bị rules từ chối |
| CAT-02 | Hai Manager đồng thời thêm cùng SKU | Chỉ một ghi thành công, không ghi đè |
| CRM-01 | Staff thêm khách VIP | Firestore tạo bản ghi totalSpend=0 |
| CRM-02 | Staff sửa tổng chi tiêu | Bị rules từ chối |
| HOLD-01 | SKU tồn 1; Staff A Hold 1, Staff B Hold 1 | Chỉ A thành công; tồn khả dụng = 0 |
| HOLD-02 | Hủy Hold đã tạo | heldStock giảm về 0 đúng một lần |
| HOLD-03 | Hold hết hạn | Scheduler đổi Expired và hoàn tồn giữ (trễ tối đa ~5 phút nếu job chạy đều) |
| POS-01 | Đã thu đủ tiền mặt | Backend tạo Paid order + trừ stock + ghi commission + cập nhật customer trong transaction |
| POS-02 | Cash sale SKU hết hàng | Giao dịch thất bại, không có đơn mới/KPI/tồn âm |
| POS-03 | Hai Staff đồng thời bán SKU tồn 1 | Chỉ một giao dịch thành công |
| POS-04 | Cùng requestId gọi lại | Không tạo đơn/KPI hai lần |
| POS-05 | QR chưa đối soát | Chỉ tạo order_drafts; không trừ kho / không cộng KPI |
| POS-06 | Sửa giá sản phẩm tại server trước lúc thanh toán | Backend dùng giá server, không tin tổng tiền từ Flutter |
| RET-01 | Gửi Return sai bill hoặc số lượng quá bill | Cloud Function từ chối |
| RET-02 | Gửi Return hợp lệ | Pending, chưa hoàn tiền/hoàn kho/KPI |
| SHIFT-01 | Staff đăng ký ca | Chỉ tạo Pending |
| SHIFT-02 | Manager duyệt hai ca trùng cho cùng Staff | Ca duyệt sau bị chặn |
| SWAP-01 | Staff A gửi, Staff B chấp nhận, Manager duyệt | Ca đổi người chỉ sau Manager duyệt |
| SWAP-02 | Staff A tự ý Approve swap | Rules/Functions từ chối |
| ATT-01 | Check-in hai lần cùng ngày | Lần thứ 2 bị từ chối |
| ATT-02 | Check-out khi chưa check-in | Bị từ chối |
| PROMO-01 | Manager tạo, Admin duyệt | Proposal Approved; không sửa price trên sản phẩm |
| FIN-01 | Admin thêm chi phí, Staff truy cập expenses | Admin thành công; Staff bị từ chối |
| PAY-01 | Thử chốt kỳ lương | Nút bị vô hiệu; chỉ xem dự kiến |
| UI-01 | Chụp màn hình 3 role so với UI gốc | Không mất sidebar, card, bảng, logo, màu, các tab |

**Trước production:** cần thêm luồng nhập/xuất kho đầy đủ, QR webhook, hoàn/đổi tiền và KPI Adjustment, duyệt công/lương, chính sách giờ làm/ca, đồng bộ thời gian giữ hàng chính xác, kiểm soát hồ sơ nhân sự, kế toán/thống kê phân trang và kiểm thử tải.
