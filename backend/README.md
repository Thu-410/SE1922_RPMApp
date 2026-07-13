# Backend quản lý phòng

Backend Node.js/Express cung cấp CRUD phòng, lọc theo trạng thái, xem chi tiết và cập nhật trạng thái phòng.

## Chạy project

1. Chạy file `src/config/script.sql` trên MySQL để tạo database `quan_ly_tro` và dữ liệu mẫu. File này xóa database cũ nên chỉ dùng khi khởi tạo lại dữ liệu.
2. Cấu hình kết nối bằng biến môi trường:

```powershell
$env:DB_HOST = "localhost"
$env:DB_PORT = "3306"
$env:DB_USER = "root"
$env:DB_PASSWORD = "mat_khau_mysql"
$env:DB_NAME = "quan_ly_tro"
$env:CORS_ORIGINS = "https://ten-mien-frontend.example"
```

3. Cài package và chạy server:

```powershell
npm install
npm start
```

Server mặc định chạy tại `http://localhost:3000`.

## API phòng

| Method | Endpoint | Chức năng |
| --- | --- | --- |
| `GET` | `/api/rooms` | Danh sách phòng |
| `GET` | `/api/rooms?status=available` | Lọc phòng theo trạng thái |
| `GET` | `/api/rooms/:id` | Chi tiết phòng |
| `POST` | `/api/rooms` | Thêm phòng |
| `PUT` | `/api/rooms/:id` | Sửa thông tin phòng |
| `PUT` | `/api/rooms/:id/status` | Cập nhật trạng thái |
| `DELETE` | `/api/rooms/:id` | Xóa mềm phòng (đổi status thành `deleted`) |

Trạng thái hợp lệ: `available`, `occupied`, `maintenance`, `inactive`.
Trạng thái `deleted` chỉ do API xóa mềm thiết lập và không hiển thị trong danh sách phòng.

Lệnh `npm start` dùng chế độ watch, vì vậy backend sẽ tự khởi động lại khi mã nguồn thay đổi.

`occupied` là trạng thái được suy ra từ dữ liệu thuê: phòng có người thuê hoặc hợp đồng
hoạt động luôn được đồng bộ sang `occupied`; khi không còn quan hệ active, trạng thái
`occupied` cũ được trả về `available`. Không thể chuyển phòng đang có quan hệ active
sang `available`, `maintenance` hoặc `inactive`.

Payload tạo/sửa phòng hỗ trợ `room_number`, `room_name`, `floor`, `area`,
`price`, `deposit`, `status`, `description` và `images` (mảng tối đa 10 URL).
Mọi request sửa phòng hoặc đổi trạng thái phải gửi `expected_version` lấy từ lần đọc
phòng gần nhất. Backend trả `409` nếu một người khác đã cập nhật phòng trước đó.

Phòng chỉ được xóa khi chưa từng phát sinh người thuê, hợp đồng, chỉ số điện nước,
hóa đơn hoặc yêu cầu bảo trì. Dữ liệu lịch sử không bị xóa dây chuyền theo phòng.

Khi `room_number` thay đổi, backend chỉ đồng bộ mã đứng độc lập trong tên/mô tả
phòng. Ghi chú lịch sử của hợp đồng, hóa đơn, thanh toán và bảo trì được giữ nguyên;
các quan hệ dữ liệu tiếp tục dùng `room_id`.

Database tạo mới bằng `src/config/script.sql` đã gồm cấu trúc phòng và thư viện ảnh mẫu.
Nếu nâng cấp database cũ, chạy lần lượt các file migration cần thiết trong
`src/config` trực tiếp trên MySQL trước khi khởi động backend.

Module phòng hoạt động độc lập và không yêu cầu đăng nhập hoặc Bearer token.
Chạy test bằng `npm test`.
