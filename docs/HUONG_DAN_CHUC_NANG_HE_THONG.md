# Ghi chú chức năng hệ thống Soléure

Tài liệu mô tả công dụng các chức năng theo mã nguồn và giao diện hiện có, để nhân viên và quản lý tra cứu. Tên nút hoặc quyền xử lý có thể thay đổi khi hệ thống được nâng cấp. Một số nghiệp vụ hiện chỉ chạy trong môi trường thử nghiệm: xem phần **Giới hạn hiện tại** trước khi sử dụng thực tế.

## 1. Tài khoản và phân quyền

- **Đăng nhập:** vào hệ thống bằng tài khoản được cấp; vai trò và trạng thái hoạt động lấy từ hồ sơ tài khoản.
- **Quên mật khẩu:** gửi yêu cầu đặt lại mật khẩu qua email đã đăng ký.
- **Đăng xuất:** kết thúc phiên sử dụng trên thiết bị.
- **Staff (nhân viên):** truy cập tổng quan, bán hàng, khách hàng, giữ hàng, đổi/trả, ca làm, chấm công và thu nhập cá nhân.
- **Manager (quản lý):** có các màn hình của Staff và thêm kho, nhân sự, bảng lương, khuyến mãi; quyền đối với từng thao tác còn phụ thuộc quy tắc của chức năng.
- **Admin (quản trị):** có thêm tài chính, báo cáo và cài đặt hệ thống; thực hiện các thao tác quản trị được phân quyền.

Việc nhìn thấy một màn hình không có nghĩa mọi nút trên màn hình đó đều được phép sử dụng. Hệ thống còn kiểm tra quyền khi xử lý dữ liệu.

## 2. Thanh công cụ chung

- **Menu:** di chuyển giữa các phân hệ được phép truy cập.
- **Tìm nhanh:** tìm sản phẩm theo SKU, tên, hãng hoặc tìm khách theo tên, số điện thoại.
- **Thông báo:** xem các thông báo và đánh dấu đã đọc.
- **Tên người dùng:** nhận biết tài khoản đang đăng nhập.

## 3. Tổng quan

- Xem nhanh các chỉ số và công việc cần xử lý theo vai trò, dựa trên dữ liệu cửa hàng.
- Dùng các lối tắt trên màn hình để chuyển đến phân hệ liên quan, chẳng hạn mở POS.
- Các số liệu có tính tổng hợp; để kiểm tra chi tiết cần mở màn hình nghiệp vụ tương ứng.

## 4. POS — bán hàng tại quầy

- **Tìm / nhập / quét SKU:** tìm sản phẩm để thêm vào đơn hàng; ô nhập hỗ trợ dữ liệu từ bàn phím hoặc máy quét hoạt động như bàn phím.
- **Giỏ hàng:** xem sản phẩm, điều chỉnh số lượng và kiểm tra giá trị đơn trước khi xử lý.
- **Chọn khách hàng:** gắn đơn hàng với hồ sơ khách; có thể phục vụ theo dõi lịch sử mua.
- **Chọn mã xe:** chọn đơn vị hàng cụ thể khi sản phẩm được quản lý theo từng xe.
- **Thanh toán tiền mặt:** xác nhận đã nhận tiền để xử lý đơn, cập nhật tồn kho và dữ liệu liên quan theo luồng hiện có.
- **Thanh toán QR:** tạo giao dịch chờ và theo dõi bill QR; màn hình có bước đối chiếu mã giao dịch và số tiền trên sao kê.
- **Hold:** tạo phiếu giữ hàng từ giỏ hàng để tạm giữ sản phẩm cho khách.
- **Khuyến mãi và KPI:** các chương trình hợp lệ, sản phẩm đủ điều kiện và giao dịch bán ảnh hưởng đến mức giảm hoặc ghi nhận KPI theo nghiệp vụ của hệ thống.

## 5. Kho & sản phẩm

- **Danh sách sản phẩm và tồn kho:** xem SKU, tên, hãng/series, giá bán, số lượng, vị trí và trạng thái.
- **Thêm sản phẩm:** tạo mã hàng và thông tin cơ bản. Sản phẩm mới bắt đầu với tồn và giá vốn bằng 0; sử dụng phiếu nhập để tăng tồn.
- **Sửa sản phẩm:** cập nhật tên, hãng, series, vị trí, giá bán và thiết lập sản phẩm có được tính KPI hay không.
- **Ảnh sản phẩm:** xem hoặc chọn ảnh gắn với SKU.
- **Hao hụt / hư hỏng:** lập biên bản ghi sản phẩm, nguyên nhân, số lượng, giá trị thiệt hại và ảnh chứng từ; người có quyền có thể duyệt hoặc từ chối. Duyệt theo luồng thử nghiệm sẽ điều chỉnh tồn.
- **Nhà cung cấp:** tạo, xem và ngưng sử dụng hồ sơ nhà cung cấp; lịch sử phiếu nhập vẫn được giữ.
- **Phiếu nhập:** lập phiếu gồm nhà cung cấp, SKU, số lượng, đơn giá vốn và ghi chú; gửi duyệt, sau đó người có quyền duyệt hoặc từ chối.
- **Kiểm kê:** nhập số lượng đếm thực tế, bao gồm hàng đang giữ; xem chênh lệch so với tồn hệ thống và gửi duyệt hoặc từ chối.
- **Từng xe:** ghi nhận mã định danh từng xe, SKU, tình trạng, vị trí và ghi chú để theo dõi từng đơn vị hàng.

## 6. Khách hàng

- **Tạo khách hàng:** lưu họ tên, số điện thoại và sở thích.
- **Sửa hồ sơ:** cập nhật thông tin khách.
- **Danh sách khách:** xem thông tin liên hệ, tổng chi tiêu, sở thích và lần mua gần nhất.
- **Lịch sử mua:** xem các bill được phép truy cập của khách; quyền Staff có thể giới hạn phạm vi lịch sử.

## 7. Hold Item — giữ hàng

- **Tạo Hold:** giữ SKU và số lượng cho khách, có thể gắn mã khách hàng; thời gian giữ chịu ảnh hưởng của cấu hình hệ thống.
- **Theo dõi phiếu:** xem khách, sản phẩm, người tạo, thời gian còn lại và trạng thái.
- **Thu tiền mặt cho Hold:** xác nhận đã nhận tiền để hoàn tất bán hàng theo phiếu giữ.
- **Hủy Hold:** giải phóng hàng giữ theo điều kiện xử lý của hệ thống.
- Hold hết hạn được xử lý khi có lần đọc hoặc thao tác liên quan; không mặc định có tác vụ nền tự động chạy đúng thời điểm hết hạn.

## 8. Đổi / trả hàng

- **Tạo yêu cầu:** chọn bill gốc, sản phẩm, số lượng, loại đổi hoặc trả, lý do và các mã xe liên quan nếu có.
- **Đổi hàng:** ghi nhận sản phẩm đổi theo các điều kiện áp dụng trong hệ thống, bao gồm trường SKU đổi ngang giá.
- **Theo dõi yêu cầu:** xem bill, sản phẩm, lý do, trạng thái và các khoản điều chỉnh doanh thu/KPI.
- **Hoàn tất phiếu:** người có quyền xác nhận các thông tin xử lý, tình trạng hàng có đủ điều kiện nhập lại kho và thông tin hoàn tiền khi được yêu cầu.
- Đổi/trả có thể tạo điều chỉnh doanh thu, tồn kho và KPI liên quan đến giao dịch gốc.

## 9. Nhân sự

- **Danh sách:** xem nhân viên, vai trò, số điện thoại, lương giờ, doanh số tháng và trạng thái tài khoản theo phạm vi được phép.
- **Tạo Staff / đề xuất Staff:** Admin có giao diện tạo; Manager có luồng gửi đề xuất để Admin xem xét.
- **Tạo Manager:** giao diện dành cho Admin.
- **Duyệt đề xuất:** Admin xem và duyệt hoặc từ chối đề xuất tài khoản Staff.
- **Chỉnh sửa / khóa:** giao diện quản trị thông tin, vai trò, lương giờ và trạng thái tài khoản theo quyền.
- Các thao tác tạo, thay đổi quyền hoặc khóa tài khoản cần môi trường quản trị phù hợp; xem giới hạn hiện tại ở cuối tài liệu.

## 10. Ca làm & đổi ca

- **Lịch làm:** xem ngày, giờ, nhân viên và trạng thái từng ca.
- **Đăng ký ca / tạo ca:** nhân viên đăng ký giờ làm; quản lý có thể tạo hoặc phân ca theo quyền.
- **Duyệt ca:** quản lý hoặc Admin xử lý đăng ký đang chờ. Các điều kiện như trùng ca, độ dài ca và giới hạn giờ tuần được kiểm tra theo nghiệp vụ.
- **Tạo phiếu đổi ca:** nhân viên chọn ca, người thay và nêu lý do.
- **Đồng ý thay:** người được chỉ định xác nhận đồng ý nhận ca.
- **Duyệt / từ chối đổi ca:** quản lý xử lý phiếu theo trạng thái; lịch thay đổi khi đáp ứng điều kiện xử lý.
- **Hủy phiếu:** người yêu cầu có thể hủy phiếu khi còn đủ điều kiện.

## 11. Check-in / Check-out

- **Check-in:** ghi nhận thời điểm bắt đầu làm cho ca được duyệt và đang trong khoảng thời gian cho phép.
- **Check-out:** ghi nhận thời điểm kết thúc ca đang mở.
- **Lịch sử chấm công:** xem tên nhân viên, ngày làm, ngày giờ check-in, ngày giờ check-out, tổng giờ và trạng thái ghi nhận.
- **Xin chỉnh công:** nhân viên gửi yêu cầu điều chỉnh giờ vào/ra và lý do đối với bản ghi phù hợp.
- **Duyệt chỉnh công:** quản lý xem và duyệt hoặc từ chối yêu cầu.
- **Duyệt / từ chối giờ công:** quản lý xử lý bản ghi chờ duyệt để làm căn cứ cho nghiệp vụ lương.
- **Đóng ca lỗi:** quản lý xử lý ca mở quá hạn theo quy định hiện có; ca bị từ chối không tự động được cộng lương.

## 12. Bảng lương

- **Xem kỳ lương:** theo dõi nhân viên, giờ làm, lương giờ, KPI, điều chỉnh, số tiền dự kiến và trạng thái.
- **Điều chỉnh:** tạo đề xuất cộng hoặc trừ tiền cùng lý do.
- **Duyệt điều chỉnh:** người có quyền duyệt hoặc từ chối đề xuất.
- **Chốt dữ liệu kỳ:** lưu số liệu nội bộ sau khi các điều kiện duyệt cần thiết được đáp ứng.
- Số tiền thể hiện là số liệu tính toán nội bộ; chốt kỳ không đồng nghĩa đã trả lương cho nhân viên.

## 13. Khuyến mãi

- **Tạo đề xuất:** nhập tên chương trình, phạm vi/sản phẩm, tỷ lệ giảm và thời gian áp dụng.
- **Danh sách:** xem chương trình, phạm vi, mức giảm, thời gian, người đề xuất và trạng thái.
- **Duyệt / từ chối:** Admin xử lý đề xuất theo quyền. Chương trình được duyệt và còn hiệu lực có thể ảnh hưởng giá bán theo quy tắc áp dụng tại POS.

## 14. Thu nhập cá nhân

- Xem tổng quan giờ làm, tiền công, KPI phát sinh và thu nhập dự kiến trong kỳ.
- Theo dõi doanh số đủ điều kiện và các khoản thu hồi hoặc điều chỉnh có liên quan.
- Đây là số liệu dự kiến để theo dõi, không phải xác nhận đã nhận lương.

## 15. Tài chính & báo cáo

- **Chọn khoảng thời gian:** hôm nay, 7 ngày, tháng, quý hoặc khoảng tùy chọn; một báo cáo chọn tối đa 93 ngày.
- **Doanh thu thuần:** theo dõi số bán sau phần hoàn trả được ghi nhận.
- **Chi phí:** ghi nhận khoản chi theo loại định phí, biến phí hoặc thuế.
- **Thuế đã ghi:** xem các chi phí thuế đã nhập, không phải quyết toán thuế.
- **Lợi nhuận tạm tính:** xem số liệu tính từ dữ liệu trong kỳ; giao diện ghi rõ chưa gồm lương của kỳ chưa chốt.
- **Xuất CSV:** lưu báo cáo để mở hoặc xử lý thêm bằng phần mềm bảng tính.

## 16. Cài đặt hệ thống

- **Tỷ lệ hoa hồng mặc định:** cấu hình tỷ lệ KPI mặc định.
- **Lương giờ mặc định:** đặt mức lương giờ tham chiếu mặc định.
- **Hold Item:** cấu hình thời gian giữ hàng.
- **Giới hạn giờ / tuần:** đặt giới hạn dùng trong nghiệp vụ ca làm.
- **Rule hoàn KPI, thuế và màu thương hiệu:** hiển thị thông tin quy tắc hoặc nhận diện đang dùng; không phải tất cả các mục này đều là nút chỉnh sửa.

## 17. Ý nghĩa trạng thái thường gặp

- **Pending:** đang chờ xử lý hoặc chờ duyệt.
- **Approved:** đã được duyệt theo nghiệp vụ tương ứng.
- **Rejected:** bị từ chối hoặc xử lý là không hợp lệ.
- **Đang làm:** bản ghi đã check-in nhưng chưa có check-out.
- **Đã hủy / hết hạn:** phiếu không còn hiệu lực theo trạng thái và điều kiện của phân hệ.

Ý nghĩa và hành động tiếp theo phụ thuộc loại phiếu; ví dụ, duyệt ca khác với duyệt giờ công.

## 18. Giới hạn hiện tại

- Theo tài liệu chuyển đổi Firestore hiện có, dự án là bản demo và chưa nên xem là hệ thống đã nghiệm thu vận hành thực tế. Một số giao dịch nhạy cảm chỉ cho phép chạy với Firebase Emulator; quy tắc Firestore trực tuyến có thể từ chối thao tác.
- Luồng QR chỉ phục vụ mô phỏng/đối chiếu thủ công, chưa kết nối xác thực ngân hàng tự động. Hoàn tiền ngân hàng thực tế chưa được thực hiện; hoàn tiền QR bị chặn trong bản demo.
- Tạo tài khoản, đổi quyền hoặc khóa tài khoản có giao diện nhưng thao tác quản trị đặc quyền cần công cụ Admin SDK riêng; ứng dụng Flutter không tự thực hiện các bước đó.
- Chốt bảng lương là chốt nội bộ; chưa thực hiện chi lương, kê khai hoặc quyết toán thuế.
- Báo cáo và một số danh sách có giới hạn số bản ghi đọc, nên cần kiểm tra lại khi dữ liệu lớn.
- Các mô tả trên phản ánh chức năng trong mã nguồn, không thay thế kiểm thử từng luồng trên môi trường Firebase đang sử dụng.
