# Sprint 4 — Checklist kiểm thử intern trên Firebase DEV

**Chỉ dùng project DEV/TEST/DEMO**, không dùng tài khoản ngân hàng thật cho kiểm thử thủ công. Test bằng các tài khoản Auth từ `functions/scripts/seed_firebase.js`.

## Chuẩn bị

```powershell
cd app_Project
flutter pub get
flutter analyze
flutter test
cd functions
npm install
npm run check
node --check sprint4_qr.js
npm test
npm run seed:test
node scripts/seed_firebase.js --project soleure-intern-dev --dry-run --with-users
```

Khi xác nhận đúng project và credentials DEV, chạy `--apply --confirm-project ... --with-users` theo `README_INTERNS.md`, sau đó từ gốc `app_Project`:

```powershell
firebase use soleure-intern-dev
firebase deploy --only firestore:rules,firestore:indexes,storage,functions --project soleure-intern-dev
flutterfire configure --project soleure-intern-dev
flutter run
```

## Các ca kiểm tra bắt buộc

1. Staff đăng nhập, POS hiển thị sản phẩm từ Firestore và mã xe từ `inventory_units`. Không có danh sách hard-code.
2. Manager tạo mã xe hợp lệ; Staff thêm SKU, chọn unitCode → bán **tiền mặt** khi đã giả lập nhận tiền → order `Paid`, unit `Sold`, stock giảm 1, commission event tạo 1.
3. Nhấn bán lại mã xe vừa bán → backend từ chối; không trừ kho thêm.
4. Tạo Hold có mã xe → `Held`; tạo bill khác chọn cùng mã xe bị từ chối; hủy Hold → `Available`.
5. Staff chọn QR → tạo `PendingQr`, giữ hàng (`heldStock` tăng); chưa có doanh thu/KPI, số tiền chốt từ server.
6. Staff không thể đối soát; Manager nhập mã ngân hàng với **số tiền sai** → từ chối; đúng số tiền và đã đối chiếu sao kê → chuyển `Paid` một lần.
7. Đối soát lặp cùng bill/same bankRef là idempotent; dùng cùng bankRef cho bill khác bị từ chối.
8. Tạo QR khác, chỉnh `expiresAt` trong emulator bằng dữ liệu test → chạy scheduler → `ExpiredQr`, giải phóng tồn; không thể xác nhận sau hết hạn.
9. Return bill QR có mã xe: request Pending; không có mã hoàn khoản từ ngân hàng thì backend không thực thi; khi đã có mã hoàn thật, hệ thống cập nhật Return Completed, unit Available, `commission_events` adjustment, chống lặp.
10. Kiểm thử exchange cùng giá, mã xe thay thế khác SKU, không cho bán lại mã đã đổi.
11. Kiểm tra giao diện trên desktop/web/mobile: so sánh sidebar, bảng, theme, logo và POS với ảnh/bản gốc; chỉ nút chọn xe và panel QR là mới.
12. Kiểm tra giao dịch ngân hàng đến sau hết hạn, không khớp số tiền, đơn chờ quá hạn: **không được tự ghi nhận Paid**; Manager xử lý nghiệp vụ ngoại lệ bằng sao kê ngoài app.

**Bằng chứng:** chụp màn hình role, Firestore document trước/sau, Cloud Function log, kết quả `flutter analyze/test`, test với 2 phiên đăng nhập xử lý cùng một mã xe. Chỉ xác nhận PASS khi kiểm thử trên Firebase DEV thực tế, không coi Node mock là E2E.
