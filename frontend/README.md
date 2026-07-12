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

## Điểm nối đăng nhập và phân quyền

Sau khi có user đăng nhập, tạo quyền giao diện từ tên role và truyền token cho
API phòng:

```dart
final permissions = RoomPermissions.fromRole(authUser.roleName);
final roomService = RoomApiService(
  headersProvider: () async => {
    'Authorization': 'Bearer ${await tokenStorage.read()}',
  },
);

RoomManagementApp(
  roomService: roomService,
  permissions: permissions,
);
```

Nếu chưa truyền `permissions`, module giữ toàn quyền để chạy độc lập. Sau khi
truyền role, các nút Thêm/Sửa/Xóa/Cập nhật trạng thái tự ẩn theo policy; backend
vẫn là lớp kiểm tra quyền bắt buộc cuối cùng.
