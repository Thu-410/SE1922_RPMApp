# Backend quản lý phòng

Backend Node.js/Express cung cấp CRUD phòng, lọc theo trạng thái, xem chi tiết và cập nhật trạng thái phòng.

## Chạy project

1. Chạy file `src/config/script.sql` trên MySQL để tạo database `quan_ly_tro` và dữ liệu mẫu. File này xóa database cũ nên chỉ dùng khi khởi tạo lại dữ liệu.
2. Cấu hình kết nối và khóa ký token bằng biến môi trường:

```powershell
$env:DB_HOST = "127.0.0.1"
$env:DB_PORT = "3306"
$env:DB_USER = "root"
$env:DB_PASSWORD = "mat_khau_mysql"
$env:DB_NAME = "quan_ly_tro"
$env:JWT_SECRET = "mot_chuoi_bi_mat_dai_va_ngau_nhien"
$env:CORS_ORIGINS = "https://ten-mien-frontend.example"
```

3. Cài package và chạy server:

```powershell
npm install
npm start
```

Server mặc định chạy tại `http://localhost:3000`.

## Đăng nhập

Gửi `POST /api/auth/login` với `email` và `password`, sau đó gắn token nhận được
vào các API bảo vệ bằng header `Authorization: Bearer <token>`.

Tài khoản demo quản lý là `manager@gmail.com`, mật khẩu `123456`. Mật khẩu mẫu
trong SQL đã được băm bằng bcrypt; dữ liệu legacy dạng text sẽ được nâng cấp sau
lần đăng nhập hợp lệ đầu tiên.

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

Phòng chỉ được chuyển sang `occupied` khi có người thuê hoặc hợp đồng hoạt động;
không thể chuyển sang `available`/`inactive` khi các quan hệ này vẫn còn hiệu lực.

Payload tạo/sửa phòng hỗ trợ `room_number`, `room_name`, `floor`, `area`,
`price`, `deposit`, `status`, `description` và `images` (mảng tối đa 10 URL).

Khi `room_number` thay đổi, backend chỉ đồng bộ mã đứng độc lập trong tên/mô tả
phòng. Ghi chú lịch sử của hợp đồng, hóa đơn, thanh toán và bảo trì được giữ nguyên;
các quan hệ dữ liệu tiếp tục dùng `room_id`.

Database tạo mới bằng `src/config/script.sql` đã gồm cấu trúc phòng và thư viện ảnh mẫu.
Nếu nâng cấp database cũ, chạy lần lượt các file migration cần thiết trong
`src/config` trực tiếp trên MySQL trước khi khởi động backend.

Chạy test bằng `npm test`.

## Phân quyền

Middleware JWT xác thực mọi API phòng. Policy tập trung tại
`src/modules/rooms/room.authorization.js`:

- `manager`: xem, lọc, thêm, sửa, xóa và cập nhật trạng thái.
- `staff`: xem, lọc, xem chi tiết và cập nhật trạng thái.
- `tenant`: xem, lọc và xem chi tiết.

`GET /api/users/me` trả hồ sơ hiện tại; `GET /api/users` chỉ dành cho manager và
không bao giờ trả trường mật khẩu.
