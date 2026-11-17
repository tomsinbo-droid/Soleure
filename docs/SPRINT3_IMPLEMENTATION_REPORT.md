# SOLÉURE — Sprint 3: Inventory & Procurement

**Nền source:** `Soleure_Original_UI_MVVM_Basic_Firebase_Full_Integration_Sprint2.zip`.
**UI chuẩn:** `app_Project (1).zip`.
**Trạng thái:** IMPLEMENTED IN SOURCE / DEV DEPLOY & E2E PENDING / NOT PRODUCTION READY.

## 1. Phạm vi đã viết code

| Phần | View/UI | Firebase/backend | Ghi chú |
|---|---|---|---|
| Supplier master | Tab `Nhà cung cấp` trong `Kho & sản phẩm` | `suppliers` + `saveSupplier`/`deactivateSupplier` | Manager thêm; Admin ngưng sử dụng; dữ liệu lịch sử giữ nguyên |
| Phiếu nhập mua hàng | Tab `Phiếu nhập` | `purchase_receipts`, `createPurchaseReceipt`, `reviewPurchaseReceipt` | Manager lập; Admin duyệt/từ chối; hỗ trợ 1–20 SKU/phiếu |
| Giá vốn nhập kho | Giữ cột SKU / Tồn hiện có | Giao dịch tính **giá vốn bình quân gia quyền** trên tồn hiện hành khi duyệt phiếu | Phương pháp tính là giả định triển khai; cần chủ cửa hàng xác nhận |
| Kiểm kê | Tab `Kiểm kê` | `stocktakes`, `createStocktake`, `reviewStocktake` | Đếm thực tế gồm hàng Hold; cấm duyệt nếu stock/heldStock đổi |
| Tình trạng từng xe | Tab `Từng xe` | `inventory_units`, `inventory_unit_codes`, `registerInventoryUnit` | Chỉ ghi nhận observation metadata, chưa phân bổ unit vào POS |
| Ảnh SKU | Icon ảnh trong cột SKU gốc | Firebase Storage `product_images/{sku}/cover` | Chỉ 1 cover / SKU; JPEG/PNG/WEBP tối đa 5 MB |
| Tạo SKU / tồn đầu kỳ | Giữ dialog thêm SKU gốc | `createProduct` và ledger `stock_movements` loại `OPENING` | Manager tạo SKU tồn 0; Admin được nhập opening balance có audit |
| Bảo vệ quyền | Không cho Staff mở tab quản lý | Firestore/Storage Rules + callable auth | Direct writes suppliers, receipts, stocktakes, units, products bị chặn |

## 2. Luồng chính

### Nhập kho

1. Manager mở **Kho & sản phẩm → Nhà cung cấp → Thêm nhà cung cấp**.
2. Manager mở **Phiếu nhập**, chọn NCC và thêm các dòng SKU/SL/giá nhập.
3. Submit tạo `purchase_receipts/{id}` trạng thái `Pending`; **chưa cộng tồn**.
4. Admin duyệt, Cloud Function transaction đọc sản phẩm và phiếu, cộng `products.stock`, cập nhật `products.cost` bằng **bình quân gia quyền**, tạo `stock_movements` loại `PURCHASE_IN`, rồi đánh dấu `Approved`.
5. Retry với phiếu đã duyệt không cộng tồn thêm. Từ chối không đổi tồn.

### Kiểm kê

1. Manager chọn SKU, nhập số đếm vật lý *bao gồm cả hàng đang Hold*.
2. Backend snapshot `stock` + `heldStock`, ghi `stocktakes/{id}` trạng thái `Pending`.
3. Admin duyệt: giao dịch phải thấy `stock` và `heldStock` **trùng snapshot**. Nếu khác, trả `aborted` và phải lập phiếu mới.
4. Sau duyệt: `products.stock = counted`, tạo `stock_movements` loại `STOCKTAKE` cho dòng có chênh lệch, giữ nguyên `heldStock`.
5. Không cho counted nhỏ hơn số đang Hold; staff không tự duyệt/sửa số liệu.

### Hồ sơ tình trạng từng xe

- Manager khai báo `unitCode`, `sku`, tình trạng `Sealed / Good / BoxDamaged / Defective`, vị trí và ghi chú.
- Unique `(sku, unitCode)` bằng fingerprint doc riêng, chống ghi trùng.
- **Chỉ là hồ sơ kiểm tra vật lý**: chưa phải stock sub-ledger, chưa tự đổi trạng thái khi POS bán hoặc đổi trả. Không dùng số record này để tính tồn.

## 3. Phân quyền

| Hành động | Admin | Manager | Staff |
|---|---:|---:|---:|
| Đọc nhà cung cấp / chứng từ / kiểm kê / hồ sơ xe | Có | Có | Không |
| Tạo nhà cung cấp / phiếu nhập / phiếu kiểm kê / hồ sơ xe | Có | Có | Không |
| Duyệt nhập kho / kiểm kê | Có | Không | Không |
| Ngưng dùng nhà cung cấp | Có | Không | Không |
| Thêm SKU với opening stock > 0 | Có | Không | Không |
| Thêm SKU tồn 0 | Có | Có | Không |
| Upload ảnh SKU | Có | Có | Không |
| Xem ảnh SKU | Có | Có | Có |

## 4. Thay đổi tương thích quan trọng

**BREAKING CHANGE:** callable `receiveInventory` của Sprint 2 **đã vô hiệu hóa** để không bypass quy trình phiếu nhập và Admin duyệt. Nút `Nhập kho` trong UI gốc nay dẫn đến tab `Phiếu nhập`. Nếu client Sprint 2 cũ còn đang chạy, thao tác nhập kho cũ sẽ báo `failed-precondition` sau deploy. Hãy triển khai đồng bộ client và backend trên DEV trước; không deploy nóng lên production.

**BREAKING CHANGE:** `products` không cho tạo trực tiếp từ client Firestore; bắt buộc gọi callable `createProduct` để ghi chứng từ tồn đầu kỳ. App Sprint 3 đã cập nhật hàm tạo SKU.

Không có thao tác xóa hoặc migrate dữ liệu cũ tự động. Source không chứa credentials Firebase và chưa deploy.

## 5. Giới hạn cần làm tiếp

- `inventory_units` là ảnh chụp thông tin tình trạng xe; **chưa** gắn từng unitCode với Hold, bill bán, đổi trả, hao hụt, phiếu nhập. Để track từng serial end-to-end, cần Sprint POS sau và quy tắc chọn xe khi thanh toán.
- Không nhập liệu theo lô file Excel/CSV; chứng từ nhập tối đa 20 SKU/một phiếu. Danh sách Firestore giới hạn 200 bản ghi/màn hình, chưa có pagination.
- Ảnh chỉ cover cấp SKU, chưa có gallery, ảnh riêng từng xe hoặc ảnh chứng từ mua hàng.
- `products.cost` là đơn giá bình quân làm tròn VND, không phải sổ kế toán FIFO/giá vốn đã được doanh nghiệp duyệt. Cần chốt chính sách giá vốn trước release.
- Kiểm kê có chênh lệch tồn chưa tự cập nhật báo cáo chi phí/Finance; luồng báo cáo giá trị chênh lệch phải bổ sung ở Sprint Finance.
- Chưa có kiểm thử Firebase Emulator/DEV thực tế, phân tích Dart bằng Flutter SDK hay screenshot parity.

## 6. Tập tin cần đọc khi giao intern

- `lib/views/inventory/inventory_view.dart` — giao diện gốc + điểm vào tab mới + ảnh.
- `lib/views/inventory/inventory_sprint3_panels.dart` — 4 tab mới với widget Flutter cơ bản.
- `lib/view_models/inventory_view_model.dart` — lớp `InventorySprint3ViewModel` đơn giản.
- `lib/services/firebase_service.dart` — Firebase đọc/ghi và gọi Cloud Functions.
- `functions/index.js` — transaction, quyền, idempotency, phiếu và journal.
- `firestore.rules`, `storage.rules` — ACL dữ liệu/ảnh.
- `functions/test/smoke.js` — smoke tests có Firestore fake.
