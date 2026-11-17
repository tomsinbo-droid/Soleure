# Soléure Sprint 6 — Finance, Reporting & In-app Notifications

## Phạm vi

Sprint 6 tiếp tục từ **Sprint 5**, giữ UI Soléure, MVVM cơ bản cho intern:

`View (StatefulWidget / setState) → ViewModel → Service → Firebase (Firestore / Cloud Functions)`.

Không dùng Provider, Bloc, Riverpod, GetX, ChangeNotifier và không đưa dữ liệu demo hard-code vào Flutter.

## Chức năng đã bổ sung

| Hạng mục | Code | Giới hạn |
|---|---|---|
| Finance | `getFinanceReportV2`, `report_service.dart`, `finance_view_model.dart` | Admin, chưa kiểm thử E2E |
| Bộ lọc | Hôm nay, 7 ngày, tháng này, quý này, tùy chọn | Tối đa **93 ngày** mỗi lần |
| Doanh thu | Cash Paid + QR đã có `paidAt`, trừ hoàn theo ngày hoàn | Bill PendingQr không được tính |
| Giá vốn | Giá vốn đơn bán - costReversed từ phiếu hoàn tất | Chưa phải hạch toán kế toán chính thức |
| Chi phí | Theo Firestore `expenses`, hao hụt đã duyệt, KPI adjustment | Lương chỉ tính ở các kỳ `ClosedInternal` nằm trọn kỳ báo cáo |
| Dashboard Admin | Doanh thu tháng/lợi nhuận tháng và biểu đồ 7 ngày lấy từ Functions | KPI, workflow của Manager/Staff vẫn dùng danh sách giới hạn như Sprint 5 |
| Báo cáo nhân viên | Doanh số thuần, số đơn, KPI | Không phải kết quả quyết toán lương |
| Xuất dữ liệu | CSV UTF-8 có BOM và escape formula-like text | **Chưa có XLSX/PDF** |
| Thông báo | Firestore `notifications`, trigger trên thay đổi trạng thái + đánh dấu đã đọc | **In-app**, không phải FCM push |
| Seed DEV | Hai chi phí mẫu DEMO, yêu cầu chờ duyệt tạo thông báo khi trigger đã deploy | Không seed doanh thu giả hoặc dữ liệu thanh toán thành công giả |

## Data model

Không thêm bảng profile/role riêng. Tài khoản vẫn ở `users/{uid}`.

Thông báo dùng `notifications/{notificationId}`:

- `recipientUid`, `title`, `message`, `route`
- `sourceType`, `sourceId`, `status`
- `isRead`, `createdAt`, `readAt` (nếu đọc)

ID thông báo gồm collection + document + status + recipientUid, tránh phát trùng khi trigger retry. Cloud Functions mới được ghi/sửa document thông báo. Firestore Rules chỉ cho người nhận đang hoạt động đọc tài liệu của chính mình.

## Công thức báo cáo

- `sales` = tổng đơn Paid/Refunded theo ngày thanh toán; QR dùng `paidAt`, cash dùng `createdAt`.
- `refunds` = tổng `return_requests` Completed theo ngày `reviewedAt`.
- `revenue = sales - refunds`.
- `cost = totalCost từ orders - costReversed từ return_requests`.
- `netEstimate = revenue - cost - kpi - approvedDamageLoss - operatingExpenses - recordedTax - closedWages`.
- `closedWages` là `wage + adjustment` từ payroll snapshot `ClosedInternal` nằm **trọn** trong khoảng báo cáo. Hoa hồng lấy riêng từ `commission_events`, không cộng thêm `commission` từ snapshot lương để tránh cộng đôi.

**KHÔNG gọi đây là lợi nhuận ròng pháp lý** vì không đủ quyết toán thuế, chi lương và chi phí chưa nhập. Báo cáo hiển thị “Lợi nhuận tạm tính”. Khi chưa chốt kỳ lương thì khoản lương kỳ đó chưa được tính.

Để đảm bảo số liệu không âm thầm thiếu, callable giới hạn mỗi tập dữ liệu đến 1500 documents/kỳ; nếu vượt thì từ chối với `resource-exhausted`, không tự cắt thành báo cáo sai. Đây là giới hạn của demo/intern: khi production cần thay bằng indexed ledgers/rollups và pagination.

## Thông báo role

- Admin: hồ sơ Staff, đề xuất khuyến mãi, điều chỉnh lương Pending.
- Manager/Admin: biên bản hao hụt, đơn QR PendingQr, ca đăng ký, phiếu trả, chỉnh công, phiếu đổi ca đã được Staff B đồng ý.
- Người tạo/Staff liên quan: khi yêu cầu chuyển trạng thái qua phê duyệt/từ chối.
- Có thể mở module từ thông báo qua menu cũ; mỗi người chỉ đánh dấu đọc thông báo của mình.

Chưa có thông báo đẩy ra thiết bị hoặc email. Trigger hoạt động sau khi deploy; dữ liệu đã tạo trước thời điểm deploy không tự tạo thông báo quá khứ.

## Kiểm thử và hạn chế

- Node.js syntax + backend regression của Sprint 4/5: chạy bằng `npm run check && npm test`.
- `report_calculator_test.js`: verify QR, hoàn trả, KPI âm, lương snapshot, kỳ, doanh thu/ngày.
- `notifications_test.js`: role mapping.
- `seed_safety_test.js`: dry-run, từ chối production, yêu cầu xác nhận, duplicate.
- Chưa có Flutter SDK/Firebase DEV trong môi trường đóng gói nên **chưa chứng minh `flutter analyze`, `flutter test`, build hoặc E2E**.
- Chưa kiểm thử Firestore Security Rules/Firestore triggers thực trên emulator; cần làm trong Sprint 7.
- Không tự động đối soát ngân hàng; QR vẫn theo Sprint 4 (Manager/Admin kiểm sao kê thực tế trước khi xác nhận).

## Cách demo

1. Deploy Functions, Rules, Indexes trên project DEV (đúng project Flutter đã cấu hình).
2. Chạy seed từ `functions/scripts/seed_firebase.js` trên DEV theo `README_INTERNS.md`.
3. Admin mở Finance, chọn tháng, kiểm tra chi phí demo và báo cáo kỳ.
4. Tạo giao dịch tiền mặt **trên dữ liệu DEV** qua POS để kiểm tra doanh thu/giá vốn/KPI trong báo cáo.
5. Manager/Staff gửi phiếu chờ duyệt, Admin hoặc Manager mở chuông thông báo, mở đúng màn hình và đánh dấu đọc.
6. Dùng nút Xuất CSV và kiểm tra kết quả mở bằng Excel/Sheets.

Xem `docs/SPRINT6_FIREBASE_DEV_E2E_CHECKLIST.md` để nghiệm thu.
