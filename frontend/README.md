# Flutter quản lý phòng

Ứng dụng Flutter gồm các màn hình danh sách phòng, chi tiết phòng, thêm phòng và chỉnh sửa phòng. Ứng dụng hỗ trợ tìm kiếm, lọc trạng thái, xóa phòng và cập nhật nhanh trạng thái từ trang chi tiết.

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

Kiểm tra code bằng:

```powershell
flutter analyze
flutter test
```
