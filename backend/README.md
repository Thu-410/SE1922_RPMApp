# Backend quản lý phòng

Backend Node.js/Express cung cấp CRUD phòng, lọc theo trạng thái, xem chi tiết và cập nhật trạng thái phòng.

## Chạy project

1. Chạy file `src/config/script.sql` trên MySQL để tạo database `quan_ly_tro` và dữ liệu mẫu.
2. Cấu hình kết nối bằng biến môi trường nếu thông tin MySQL khác giá trị mặc định:

```powershell
$env:DB_HOST = "127.0.0.1"
$env:DB_PORT = "3306"
$env:DB_USER = "root"
$env:DB_PASSWORD = "mat_khau_mysql"
$env:DB_NAME = "quan_ly_tro"
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
| `DELETE` | `/api/rooms/:id` | Xóa phòng |

Trạng thái hợp lệ: `available`, `occupied`, `maintenance`, `inactive`.

Payload tạo/sửa phòng hỗ trợ `room_number`, `room_name`, `floor`, `area`,
`price`, `deposit`, `status`, `description` và `images` (mảng tối đa 10 URL).

Nếu database đã được tạo từ phiên bản cũ, chạy một lần file
`npm run migrate:rooms` trước khi khởi động backend mới.

Có thể chạy `npm run seed:room-gallery` để thêm nhiều ảnh mẫu cho 5 phòng
trong dữ liệu demo mà không ghi đè những phòng đã có ảnh.

Chạy test bằng `npm test`.
