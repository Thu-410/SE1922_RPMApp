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

Khi `room_number` thay đổi, backend tự đồng bộ mã xuất hiện trong tên/mô tả
phòng và các ghi chú liên quan của hợp đồng, điện nước, hóa đơn, thanh toán,
bảo trì và thông báo. Các quan hệ dữ liệu dùng `room_id` nên vẫn giữ nguyên.
Lịch sử mã được lưu theo `room_id` để request cũ/đến chậm không thể ghi đè
tên phòng bằng mã trước đó.

Database tạo mới bằng `src/config/script.sql` đã gồm cấu trúc phòng và thư viện ảnh mẫu.
Nếu nâng cấp database cũ, chạy lần lượt các file migration cần thiết trong
`src/config` trực tiếp trên MySQL trước khi khởi động backend.

Chạy test bằng `npm test`.

## Điểm nối phân quyền

Module phòng không tự xử lý đăng nhập. Sau khi middleware auth được merge, chỉ
cần gắn một trong các cấu trúc sau vào `req.user`:

```js
req.user = { id: userId };
req.user = { role_id: roleId };
req.user = { role_name: "manager" };
req.user = { role: { name: "manager" } };
```

Nếu chỉ có `id` hoặc `role_id`, module phòng tự tra tên role từ bảng `users` và
`roles`. Policy tập trung tại `src/modules/rooms/room.authorization.js`:

- `manager`: xem, lọc, thêm, sửa, xóa và cập nhật trạng thái.
- `staff`: xem, lọc, xem chi tiết và cập nhật trạng thái.
- `tenant`: xem, lọc và xem chi tiết.

Khi auth chưa được merge và chưa có `req.user`, API vẫn chạy để phát triển độc
lập. Khi tích hợp hoàn tất, middleware auth chung nên chặn request chưa đăng
nhập; hoặc đặt `AUTH_REQUIRED=true`/`ROOM_AUTH_REQUIRED=true` để module phòng tự
trả `401` nếu thiếu `req.user`.
