# Soléure — Firestore đơn giản cho intern

## Nguyên tắc

- **Một đối tượng = một document chứa các thuộc tính của nó.** Không tạo collection `user_names`, `user_roles`, `user_profiles`, `product_prices` chỉ để lưu vài thuộc tính của cùng một record.
- **Một phát sinh nhiều lần = một collection giao dịch.** Một Staff có nhiều ca, một SKU có nhiều phiếu nhập, một khách có nhiều hóa đơn. Không nhét hàng nghìn dòng lịch sử vào một document: có giới hạn kích thước và dễ xung đột cập nhật.
- `users/{uid}` là **hồ sơ nghiệp vụ**; Firebase Authentication quản lý tài khoản đăng nhập (email/mật khẩu) theo cùng `uid`. `role` chỉ do Admin SDK / Firebase Console cấp, không ghi trực tiếp từ Flutter.
- Trường ID của document (`uid`, `sku`, `receiptId`) dùng làm khóa. Không tạo collection riêng để giữ tên hoặc role.

## Các document dễ hiểu

**`users/{uid}`** — một document chứa các thông tin nhân viên:

```json
{
  "displayName": "Nguyễn Văn A",
  "email": "staff@example.com",
  "phone": "0900000000",
  "role": "staff",
  "hourlyRate": 30000,
  "active": true
}
```

`role`: `admin`, `manager`, `staff`. Không tạo bảng quyền riêng. `email` trong document nhằm hiển thị; dữ liệu đăng nhập do Firebase Auth sở hữu. Tài khoản cũ thiếu `email` vẫn đọc được; khi cần hiển thị email đầy đủ, Admin cập nhật hồ sơ bằng quy trình tin cậy.

**`products/{sku}`** — một document chứa tên, hãng, series, giá, giá vốn, tồn, tồn Hold, vị trí:

```json
{
  "name": "Mini GT Porsche",
  "brand": "Mini GT",
  "series": "Porsche",
  "price": 560000,
  "cost": 395000,
  "stock": 4,
  "heldStock": 1,
  "location": "T01 / B04",
  "kpiEligible": true,
  "promoPercent": 0
}
```

**`suppliers/{id}`** — một document gồm `name`, `phone`, `email`, `note`, `active`.

**`purchase_receipts/{id}`** — một phiếu với *danh sách dòng nhúng trong chính document*, không có bảng `receipt_lines` riêng:

```json
{
  "supplierId": "SUP-001",
  "supplierName": "Nhà cung cấp A",
  "status": "Pending",
  "note": "Nhập đợt đầu",
  "lines": [
    {"sku": "MGT-00125", "quantity": 2, "unitCost": 380000},
    {"sku": "KH-00218", "quantity": 1, "unitCost": 470000}
  ]
}
```

Backend bổ sung `createdBy`, `createdAt`, và các trường duyệt khi xử lý. Một phiếu tối đa 20 SKU theo rule hiện có.

**`stocktakes/{id}`** — một phiếu kiểm kê có `status`, `lines: [{sku, counted, expected, heldAtCount, difference, note}]`, thời gian/người tạo. Không tạo bảng con riêng cho từng dòng.

**`inventory_units/{id}`** — ghi nhận từng chiếc xe (`sku`, `unitCode`, `condition`, `location`, `note`). Đây là hồ sơ nhiều bản ghi trên một SKU, **chưa** phải serial gắn xuyên suốt POS. `inventory_unit_codes` chỉ là khóa chống trùng do server quản lý, không phải bảng dữ liệu người dùng cần nhập.

## Vì sao một số collection vẫn tách riêng?

- `staff_requests`: **phiếu xin tạo tài khoản**, không phải bảng thông tin nhân viên. Sau Admin duyệt, hồ sơ chính nằm trong `users/{uid}`; phiếu giữ lại làm lịch sử.
- `orders`, `holds`, `shifts`, `attendance`: giao dịch vận hành phát sinh nhiều lần, mỗi giao dịch có trạng thái riêng.
- `stock_movements`, `commission_events`, `product_changes`: lịch sử bất biến phục vụ kiểm tra tồn kho / hoa hồng; không được gộp rồi ghi đè.
- `system_settings/store`: một document chứa các cấu hình cửa hàng.

**Không đổi tên collection hoặc field ở Sprint 3.1**, để không làm hỏng dữ liệu và các Cloud Functions của Sprint 2–3. Các ví dụ trên là dạng document dễ đọc, không phải dữ liệu Firebase thật đã được seed.
