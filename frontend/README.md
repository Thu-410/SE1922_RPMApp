# Flutter quản lý phòng

Ứng dụng Flutter gồm đăng nhập, danh sách phòng, chi tiết phòng, thêm phòng và chỉnh sửa phòng. Ứng dụng hỗ trợ tìm kiếm, lọc trạng thái, xóa phòng và cập nhật nhanh trạng thái từ trang chi tiết.

## Chạy project

Khởi động backend tại cổng `3000`, sau đó chạy:

```powershell
flutter pub get
flutter run
```

Địa chỉ API mặc định:

- Android emulator: `http://10.0.2.2:3000`
- Web, Windows, macOS, Linux và iOS simulator: `http://localhost:3000`

Khi chạy trên thiết bị thật hoặc backend ở máy khác, truyền địa chỉ bằng `API_BASE_URL`:

```powershell
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:3000
```

HTTP chỉ được bật trong bản Android debug. Bản release phải dùng backend HTTPS.
Tài khoản demo quản lý: `manager@gmail.com` / `123456`.

Kiểm tra code bằng:

```powershell
flutter analyze
flutter test
```

## Đăng nhập và phân quyền

Ứng dụng gọi `/api/auth/login`, giữ token trong phiên chạy và tự truyền Bearer
token cho API phòng. Giao diện lấy quyền từ role; nếu không có role hợp lệ thì
mặc định từ chối toàn bộ thay vì cấp toàn quyền.

Khi phát hành Android, cấu hình ký release bằng các biến
`ANDROID_KEYSTORE_PATH`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS` và
`ANDROID_KEY_PASSWORD`. Nếu thiếu, Gradle chỉ tạo bản release chưa ký.
