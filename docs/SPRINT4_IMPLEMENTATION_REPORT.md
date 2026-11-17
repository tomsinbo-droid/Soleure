# SOLÉURE — SPRINT 4 / POS, QR, SERIAL & RETURNS

## Phạm vi và nguyên tắc

Nền: `Soleure_Sprint3_3_Intern_Clean_MVVM_Firebase_Seed_OriginalUI.zip`.
Giữ layout POS / Đổi-trả, sidebar, theme, assets và widget dùng chung. Chỉ bổ sung các nút/dialog trong màn hình sẵn có. Vẫn sử dụng `StatefulWidget` + `setState()`, không Provider/Bloc/Riverpod/GetX/ChangeNotifier. Dữ liệu mẫu lấy từ Firebase qua script seed DEV, không hard-code sản phẩm hoặc giao dịch Paid trong Flutter.

## Chức năng có code

| Luồng | Mô tả |
|---|---|
| POS tiền mặt | Giữ nghiệp vụ Sprint 2, bổ sung chọn `inventory_units/{unitId}` khi có mã xe; lưu `unitIds` trong snapshot dòng bill |
| Hold | Có thể giữ mã xe, khóa trạng thái `Held`; hủy/hết hạn giải phóng về `Available`; bán từ Hold đổi sang `Sold` |
| POS QR/chuyển khoản | `createQrPayment`: khóa giá sau promotion, giữ `heldStock` và unit trong 20 phút; tạo `orders/{id}` trạng thái `PendingQr` |
| Đối soát QR | `confirmQrPayment`: chỉ Admin/Manager, yêu cầu mã giao dịch sao kê và đúng số tiền; tạo `bank_transaction_refs` chống dùng lại, ghi `Paid`, trừ tồn, KPI trong cùng transaction |
| Hết hạn QR | `expirePendingQr`: Firebase Scheduler xử lý từng đơn quá hạn, trả lại số lượng giữ, `ExpiredQr`. Không tự đánh dấu Paid nếu tiền vào trễ |
| Return/Exchange | Giữ luật hóa đơn gốc, bổ sung `unitIds` và `replacementUnitIds`; xe trả được mở lại hoặc ghi `Damaged`; xe thay được đánh dấu `Sold` |
| Hoàn khoản QR | `settleReturn` nhận mã hoàn khoản sao kê cho bill QR; chống trùng ở `bank_refund_refs`, đồng thời cập nhật giá vốn, KPI và tồn kho |
| Dashboard | Bỏ `PendingQr` / `ExpiredQr` ra khỏi doanh thu; QR đã đối soát được tính từ `paidAt` |
| Bảo mật | Firestore Rules chặn mọi client write vào đơn, giữ hàng, unit, ledger, mã đối soát; Staff chỉ đọc dữ liệu unit để chọn xe |

**Ràng buộc:** Đây là luồng **đối soát thủ công dựa trên sao kê**. Chưa tích hợp webhook ngân hàng/VietQR thật, chưa có ảnh QR sinh từ tài khoản ngân hàng. Checkbox xác nhận do Manager/Admin tích vào **không phải xác minh từ API ngân hàng**. Không thử nghiệm với giao dịch tiền thật khi chưa nghiệm thu và có quy trình kiểm soát.

## MVVM / service

```
views/pos/pos_view.dart (giữ UI gốc + chọn mã xe và panel đối soát)
  -> view_models/pos_view_model.dart
    -> services/pos_service.dart       (cash / bill)
    -> services/payment_service.dart   (QR / đối soát)
    -> services/hold_service.dart      (hold)
    -> services/inventory_service.dart (đọc mã xe)

views/returns/returns_view.dart
  -> view_models/returns_view_model.dart
    -> services/return_service.dart

functions/index.js                 (cash, hold, return, inventory transactions)
functions/sprint4_qr.js            (QR transaction, xác nhận, scheduler)
```

## Các Firestore documents

- `orders/{orderId}`: một document chứa `staffUid`, `customerId`, `paymentMethod`, `status`, `items[]` (mỗi item gồm SKU, giá snapshot, số lượng, `unitIds`), `total`, `commission`, `expiresAt`/`bankTransactionId` nếu QR.
- `inventory_units/{unitId}`: mã xe, tình trạng hộp, vị trí, `trackingStatus` và order/hold liên kết. Không tách bảng mã/tình trạng xe ra làm nhiều bảng hồ sơ. Collection `inventory_unit_codes` chỉ là khóa kỹ thuật chống trùng mã.
- `return_requests/{id}`: bill gốc, SKU, quantity, type, `unitIds`, `replacementUnitIds`, `paymentMethod`, `expectedRefundAmount`, trạng thái.
- `bank_transaction_refs/{sha256(ref)}` và `bank_refund_refs/{sha256(ref)}`: khóa kỹ thuật chống dùng cùng một mã ngân hàng cho nhiều bill/phiếu hoàn. Không dùng làm nguồn xác thực tự động.

## Giới hạn chưa hoàn thiện

1. Không có provider ngân hàng/webhook, không tạo ảnh QR VietQR; nhân viên chỉ có thông tin bill và nội dung chuyển khoản.
2. Sau 20 phút, QR quá hạn bị nhả kho. Nếu tiền đến trễ hoặc số tiền không khớp, Manager phải xử lý đối soát/hoàn thủ công bên ngoài ứng dụng. Không được ép một QR Expired thành Paid.
3. Truy vết từng xe là **tùy chọn** cho SKU; với hàng không gắn mã, POS theo số lượng SKU. Cần kiểm kê bổ sung cho tất cả xe nếu muốn truy vết 100%.
4. Biên bản đổi trả đang giới hạn 1 yêu cầu cho mỗi cặp bill/SKU. Đổi chênh giá và hoàn một phần chuyển khoản chưa có quy trình ngân hàng tự động.
5. Màn POS liệt kê tối đa 300 đơn cho bản demo intern; sản phẩm và unit lấy theo giới hạn hiện tại 200. Chưa có phân trang/lưu truy vấn sản xuất.
6. Có code backend và test giả lập, **chưa có Flutter SDK trên máy thực thi để chạy `flutter analyze/test/build`**; chưa triển khai vào Firebase DEV và chưa E2E thực.
7. Firebase Scheduler/Cloud Functions có thể yêu cầu gói tính phí, hạn mức và quyền triển khai phù hợp.

## Thay đổi cần triển khai đồng bộ

Không deploy riêng `functions/index.js` hoặc `sprint4_qr.js` lên ứng dụng production đang chạy Sprint 3: hợp đồng dữ liệu unit/Hold/QR thay đổi. Cần backup Firestore DEV, triển khai Rules + Functions + client đồng bộ rồi mới chạy kiểm thử.
