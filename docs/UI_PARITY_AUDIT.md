# SOLÉURE — SO SÁNH VỚI UI GỐC

**Baseline duy nhất:** ZIP người dùng gửi `app_Project (1).zip`.

## Kiểm tra byte-level

| Thành phần | Kết quả |
|---|---|
| `assets/` | **4/4 file giữ nguyên nội dung byte** |
| `lib/core/theme/` | **2/2 file giữ nguyên nội dung byte** |
| `lib/widgets/` | **6/6 file giữ nguyên nội dung byte** |
| 18 view files | **1/18 giữ nguyên byte**, 17 view thay callback/tải dữ liệu/chuyển Stateful hoặc thêm dialog |

Không tạo UI thay thế. Các màn hình tiếp tục dùng bố cục gốc (sidebar, PageHeader, các SectionCard, DataTable, POS catalog/cart, tab ca làm/kho, metric cards, font/màu gốc). Một số tiêu đề/nội dung/danh sách trở thành **dữ liệu thực**, một số nút mới hiển thị quy trình thật hoặc được vô hiệu hóa, nên **không thể nói giao diện giống 100% từng pixel** khi chưa chạy so ảnh.

## View có sửa để nối chức năng

- `lib/views/attendance/attendance_view.dart`
- `lib/views/auth/forgot_password_view.dart`
- `lib/views/auth/login_view.dart`
- `lib/views/customers/customers_view.dart`
- `lib/views/dashboard/dashboard_view.dart`
- `lib/views/finance/finance_view.dart`
- `lib/views/holds/hold_items_view.dart`
- `lib/views/income/staff_income_view.dart`
- `lib/views/inventory/inventory_view.dart`
- `lib/views/payroll/payroll_view.dart`
- `lib/views/pos/pos_view.dart`
- `lib/views/promotions/promotions_view.dart`
- `lib/views/returns/returns_view.dart`
- `lib/views/settings/settings_view.dart`
- `lib/views/shell/app_shell.dart`
- `lib/views/shifts/shifts_view.dart`
- `lib/views/staff/staff_view.dart`

## View giữ nguyên

- `lib/views/auth/reset_password_view.dart`

## Cần xác nhận trên máy có Flutter SDK

1. Chạy app ở DEMO và DEV, chụp cùng kích thước Android/iPad/Desktop để so với bản gốc.
2. Xác nhận không mất `assets`, logo, màu #FE9EC7 / #F9F6C4 / #89D4FF / #44ACFF, menu, bảng, giỏ hàng POS.
3. Kiểm tra breakpoint nhỏ/mở bàn phím với dialog nhập liệu (chưa có screenshot E2E ở môi trường đóng gói).
4. Xác nhận quyền hạn theo tài khoản Firebase thật.

Kiểm tra byte-level ở trên là kết quả **so sánh tĩnh**, không phải chứng nhận pixel parity.
