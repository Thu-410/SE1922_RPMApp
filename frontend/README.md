# Flutter quản lý phòng

Ứng dụng Flutter mở thẳng danh sách phòng, gồm danh sách, chi tiết, thêm, sửa,
xóa, lọc và cập nhật trạng thái phòng. Module này không chứa chức năng đăng nhập.

## Chạy project

Khởi động backend tại cổng `3000`, sau đó chạy:

```powershell
flutter pub get
flutter run
```

Form phòng cho phép chọn nhiều ảnh từ máy hoặc tiếp tục dán URL ảnh mạng. Mỗi phòng
có tối đa 10 ảnh và mỗi file tải lên không quá 5 MB. Backend phải đang chạy để upload.
Tính năng chọn ảnh hỗ trợ Android 7.0 (API 24) trở lên.

Trên Windows, nếu Flutter báo plugin cần quyền tạo symbolic link, bật **Developer Mode**
trong Windows Settings rồi chạy lại `flutter pub get`.

Địa chỉ API mặc định:

- Android emulator: `http://10.0.2.2:3000`
- Web, Windows, macOS, Linux và iOS simulator: `http://localhost:3000`

Khi chạy trên thiết bị thật hoặc backend ở máy khác, truyền địa chỉ bằng `API_BASE_URL`:

```powershell
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:3000
```

HTTP chỉ được bật trong bản Android debug. Bản release phải dùng backend HTTPS.

Kiểm tra code bằng:

```powershell
flutter analyze
flutter test
```

Trạng thái `Đang thuê` được backend tự xác định từ người thuê/hợp đồng nên không thể
chọn thủ công. Các lần sửa phòng và đổi trạng thái dùng `version` để phát hiện dữ
liệu đã được người khác sửa.

Khi phát hành Android, cấu hình ký release bằng các biến
`ANDROID_KEYSTORE_PATH`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS` và
`ANDROID_KEY_PASSWORD`. Nếu thiếu, Gradle chỉ tạo bản release chưa ký.
