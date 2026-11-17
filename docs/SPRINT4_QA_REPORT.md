# Sprint 4 — QA & trạng thái bàn giao (2026-11-14)

- Nền: Sprint 3.3, **giữ nguyên 4 assets + 2 theme + 6 widget dùng chung** (SHA-256 cùng bytes).
- Màn hình được sửa: `lib/views/pos/pos_view.dart`, `lib/views/returns/returns_view.dart` để thêm controls; cấu trúc màn hình gốc được giữ, chưa có screenshot pixel-level.
- Dart: 79 file, đường dẫn import và dấu phân tách cú pháp kiểm tra tĩnh **PASS**. Không còn nhánh demo hay danh sách sản phẩm giả trong client.
- Node.js `npm run check`: cú pháp `index.js`, `sprint4_qr.js` **PASS**.
- Node.js `npm test`: smoke regressions Sprint 2/3 + cash/serial, Hold cancel, mã xe sold/return, QR Pending/confirm/expire, xác nhận trùng, quyền role, sai số tiền, yêu cầu hoàn QR không có mã hoàn khoản: **PASS**.
- Node.js `npm run seed:test`: chế độ xem trước, bảo vệ project production, xác nhận ID và unique seed IDs **PASS**.
- Chưa có Flutter SDK trong môi trường tạo ZIP, nên `flutter analyze`, `flutter test`, `flutter run` và so sánh UI runtime **CHƯA KIỂM THỬ**.
- Chưa kết nối Firebase project DEV của người dùng; chưa deploy Firebase Rules/Functions/Indexes, chưa E2E trên Firestore thật.
- Smoke test dùng mock bộ nhớ, không chứng minh được transaction race thật, tích hợp ngân hàng hay quyền Firestore thực tế.
- **Chưa sẵn sàng production.** Không deploy thẳng vào môi trường có thanh toán thật hoặc chạy đồng thời client Sprint 3.3 và backend Sprint 4.

## Điều kiện nghiệm thu

1. Cấu hình FlutterFire DEV, deploy Rules/Indexes/Functions, seed DEV.
2. `flutter analyze && flutter test` PASS, UI POS/Returns giữ layout gốc trên màn hình mục tiêu.
3. Test 2 phiên đăng nhập cùng chọn/bán/hold một mã xe, 1 giao dịch phải bị chặn.
4. Kiểm tra pending QR, quá hạn, khác số tiền, bankRef dùng lặp và hoàn khoản đối soát với sao kê TEST; xem `SPRINT4_FIREBASE_DEV_TEST_PLAN.md`.
5. Đảm bảo callback ngân hàng tự động **chưa được tích hợp**; mọi xác nhận QR đang dựa vào người quản lý đối soát thủ công.
