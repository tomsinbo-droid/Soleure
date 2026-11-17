# Soléure Sprint 5 — Firebase DEV E2E Checklist

Đánh dấu PASS/FAIL sau khi chạy; file này là **kịch bản**, không phải kết quả đã chạy.

## 0. Chuẩn bị an toàn

- [ ] Dùng Firebase project riêng tên chứa `-dev`, `-test`, hoặc `-demo`. KHÔNG deploy rules/function này lên production đang sử dụng.
- [ ] Xác minh `firebase use` / `firebase projects:list` đúng project DEV.
- [ ] `cd app_Project && flutter pub get && flutterfire configure --project <DEV_ID>` (thay `<DEV_ID>` bằng ID thật).
- [ ] `firebase deploy --only firestore:rules,firestore:indexes,storage,functions --project <DEV_ID>`.
- [ ] `cd functions && npm install && npm run check && npm test && npm run seed:test`.
- [ ] Chạy `node scripts/seed_firebase.js --project <DEV_ID> --dry-run --with-users`.
- [ ] Khi chắc chắn đúng DEV, cấu hình Application Default Credentials đúng project rồi chạy `--apply --confirm-project <DEV_ID> --with-users`.
- [ ] Không commit service account, file credentials seed hoặc file bí mật vào Git.

## 1. Admin / Manager / Staff

- [ ] Login với 4 account seed (Admin, Manager, Staff A, Staff B).
- [ ] Kiểm tra từng menu hiện đúng quyền. Manager KHÔNG đọc hồ sơ Admin, Staff không đọc Staff khác.
- [ ] Manager gửi đề xuất Staff; Admin duyệt; Auth và `users/{uid}` được tạo, `role=staff`.
- [ ] Admin tạo Manager; login Manager sau khi đặt mật khẩu qua chức năng Quên mật khẩu.
- [ ] Admin sửa tên/phone/hourlyRate/role Staff; kiểm tra role ở Firestore thay đổi và nhật ký `staff_account_audit`.
- [ ] Admin khóa Staff: account bị disabled trong Auth, `users.active=false`, Cloud Function từ token cũ bị từ chối. Admin mở lại và xác thực login.
- [ ] Manager hoặc Staff gọi callable `adminUpdateAccount` bị từ chối.

## 2. Shift / Shift Swap

- [ ] Staff A đăng ký ca trong tương lai, 30 phút đến 12 giờ; Manager duyệt.
- [ ] Không duyệt được lịch trùng giờ Approved hoặc quá `maxWeeklyHours` trong `system_settings/store`.
- [ ] Ca Pending trùng giờ khi Staff đăng ký phải bị chặn.
- [ ] Staff A nhờ Staff B thay, Staff B đồng ý, Manager duyệt. Ca phải đổi `staffUid` sang B.
- [ ] Test phiếu Cancelled và Rejected: không thay đổi ca.
- [ ] Test nhân viên bị khóa/ca đã bắt đầu: không được duyệt swap.
- [ ] Truy cập Firestore SDK từ Staff để ghi `shifts` hoặc `shift_swaps` trực tiếp phải bị DENY.

## 3. Attendance

- [ ] Seed Shift `SEED_SPRINT5_SHIFT_01` bắt đầu khoảng 20 phút sau khi **seed mới**; Manager duyệt ngay, Staff A check-in ngay trước giờ bắt đầu (trong cửa sổ 30 phút).
- [ ] Check-in lần 2 phải lỗi; check-out lần đầu thành công.
- [ ] Manager chỉ được duyệt công đã check-out tối thiểu 1 phút, không còn correction Pending.
- [ ] Staff tạo yêu cầu điều chỉnh giờ công, Manager duyệt hoặc từ chối; audit lưu đúng.
- [ ] Test ca bỏ quên checkout quá 18 giờ bằng Firebase Emulator/time fixture: Manager có thể đóng `Rejected`, không được cộng giờ lương.
- [ ] Staff không có ca Approved đang đến giờ không được check-in.

## 4. KPI / Payroll

- [ ] Bán một đơn tiền mặt qua POS DEV, kiểm tra order Paid và commission_events chứa `eligibleSales`, `commissionRate`.
- [ ] Trả/đổi hàng, kiểm tra event KPI điều chỉnh âm, không xóa event cũ; Staff Income hiển thị theo tháng.
- [ ] Thử thay đổi `users.hourlyRate` sau chấm công; dữ liệu payroll đã duyệt phải dùng rate snapshot của ca cũ.
- [ ] Manager tạo điều chỉnh lương, Admin duyệt, trạng thái Pending -> Approved/Rejected.
- [ ] Tạo kỳ kiểm thử đã kết thúc trong **emulator fixture**; Admin chốt, `payroll_records` có `wage`, `commission`, `adjustment`, `expectedTotal` và `status=ClosedInternal`.
- [ ] Chốt cùng kỳ lần 2 phải bị chặn; kỳ có công/điều chỉnh đang chờ duyệt phải bị chặn.
- [ ] Kiểm tra không phát sinh chi lương hoặc quyết toán thuế tự động.

## 5. Flutter & nghiệm thu UI

- [ ] `flutter analyze` PASS trên máy intern.
- [ ] `flutter test` PASS trên máy intern.
- [ ] Mở tất cả màn hình của ba role, kiểm tra sidebar, cards, tables, dialogs, responsive layout.
- [ ] So sánh UI với bản gốc trên cùng độ phân giải; không thay đổi theme, logo hoặc widget cơ sở.
- [ ] Lưu log Firebase Functions, ảnh màn hình kiểm thử và kết quả PASS/FAIL từng bước.

**Chú ý:** Script seed là idempotent và không update ca cũ. Nếu đã seed từ trước hoặc thời gian bắt đầu ca đã qua, tạo một ca mới từ UI và duyệt; không chỉnh trực tiếp dữ liệu production.
