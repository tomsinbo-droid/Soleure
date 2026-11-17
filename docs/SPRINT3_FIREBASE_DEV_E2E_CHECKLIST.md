# SOLÉURE — Sprint 3 Firebase DEV / Emulator Acceptance Checklist

## Chuẩn bị (trên project DEV, không dùng production)

- Sao lưu/export Firestore DEV trước khi nâng cấp; ghi mã project/bucket và các phiên bản Rules/Functions.
- Kiểm tra Firebase CLI, Flutter SDK, Dart SDK, Node.js 22, billing Functions khi cần.
- Tạo 3 tài khoản Auth + `users/{uid}` (`admin`, `manager`, `staff`), `active: true`.
- Chạy trên thư mục source:

```bash
flutter pub get
flutterfire configure --project YOUR_DEV_PROJECT_ID
flutter analyze
flutter test
cd functions
npm install
npm run check
npm test
cd ..
firebase deploy --project YOUR_DEV_PROJECT_ID --only firestore:rules,firestore:indexes,storage,functions:soleure
flutter run
```

Nên dùng Auth/Firestore/Storage/Functions Emulator trước khi deploy; mock Node.js không thay thế Emulator Test Rules.

## E2E — nghiệp vụ bắt buộc PASS

- [ ] Staff không tạo/sửa `suppliers`, `purchase_receipts`, `stocktakes`, `inventory_units` bằng client Firestore/Callable.
- [ ] Manager tạo NCC. Admin ngưng sử dụng; NCC ngưng không tạo phiếu nhập mới; phiếu cũ vẫn đọc được.
- [ ] Manager tạo SKU tồn 0. Manager không tạo SKU có tồn đầu kỳ > 0; Admin tạo được opening stock và có ledger `OPENING`.
- [ ] Manager tạo phiếu nhập 2 SKU, chỉ `Pending`: tồn/cost vẫn giữ nguyên.
- [ ] Manager không duyệt được; Admin duyệt cộng đúng số lượng, cập nhật giá bình quân và tạo đúng `PURCHASE_IN` movements.
- [ ] Admin bấm duyệt lại không cộng kho 2 lần; dùng lại requestId với dữ liệu khác bị từ chối.
- [ ] Phiếu nhập có SKU thiếu hoặc NCC không hợp lệ bị từ chối nguyên giao dịch.
- [ ] Admin từ chối phiếu nhập không cộng tồn; không thể đảo trạng thái từ chối sang duyệt.
- [ ] Kiểm kê snapshot tồn 10, đếm 9, duyệt tạo movement `-1`.
- [ ] Khi đang có Hold 2, kiểm kê 1 bị từ chối vì counted < heldStock.
- [ ] Sau khi lập phiếu kiểm kê, tạo bill bán/hold hoặc nhập hàng làm stock/heldStock thay đổi: Admin duyệt phải trả `aborted` và không ghi đè.
- [ ] Kiểm kê không chênh lệch được approve nhưng không tạo movement số lượng 0.
- [ ] Hai quản lý cùng đăng ký `unitCode` của một SKU: chỉ một ghi thành công.
- [ ] Ảnh JPG/PNG/WEBP 5 MB trở xuống upload/download được; Staff chỉ đọc; file > 5 MB và MIME khác bị Storage Rules chặn.
- [ ] POS tiền mặt / Hold / đổi trả Sprint 2 vẫn PASS sau nâng cấp Sprint 3.
- [ ] Mở các màn hình Kho cũ trên desktop và độ rộng tablet để kiểm tra layout/tabs và ảnh.
- [ ] Test Flutter Analyzer sạch; debug console không có exception; màn hình trống xử lý đúng.

## Chốt nghiệm thu

Chỉ đánh dấu **READY FOR DEV ACCEPTANCE** khi toàn bộ tình huống cần thiết có log, screenshot và kết quả test qua Firebase DEV. Trước production phải chốt kế toán giá vốn bình quân, serial tracking POS và cách xử lý chênh lệch kiểm kê vào Finance.
