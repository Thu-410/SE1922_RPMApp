import 'package:flutter_test/flutter_test.dart';
import 'package:orderfood/main.dart';
import 'package:orderfood/models/room.dart';
import 'package:orderfood/models/room_permissions.dart';
import 'package:orderfood/services/room_api_service.dart';

class _FakeRoomApiService extends RoomApiService {
  @override
  Future<List<Room>> getRooms({RoomStatus? status}) async => const [];
}

void main() {
  testWidgets('hiển thị danh sách phòng rỗng', (tester) async {
    await tester.pumpWidget(
      RoomManagementApp(roomService: _FakeRoomApiService()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Quản lý phòng'), findsOneWidget);
    expect(find.text('Chưa có phòng nào'), findsOneWidget);
    expect(find.text('Tất cả phòng'), findsOneWidget);
  });

  test('đọc dữ liệu phòng trả về từ API', () {
    final room = Room.fromJson({
      'id': 1,
      'room_number': 'A101',
      'room_name': 'Phòng ban công A101',
      'floor': 1,
      'area': '25.5',
      'price': '3500000',
      'deposit': 3500000,
      'status': 'available',
      'images': [
        'https://example.com/room-1.jpg',
        'https://example.com/room-2.jpg',
      ],
    });

    expect(room.roomNumber, 'A101');
    expect(room.roomName, 'Phòng ban công A101');
    expect(room.area, 25.5);
    expect(room.status, RoomStatus.available);
    expect(room.images.length, 2);
    expect(room.imageUrl, 'https://example.com/room-1.jpg');
  });

  test('phân quyền giao diện phòng theo role', () {
    final manager = RoomPermissions.fromRole('manager');
    final staff = RoomPermissions.fromRole('staff');
    final tenant = RoomPermissions.fromRole('tenant');

    expect(manager.canCreate, isTrue);
    expect(manager.canDelete, isTrue);
    expect(staff.canView, isTrue);
    expect(staff.canUpdateStatus, isTrue);
    expect(staff.canEdit, isFalse);
    expect(tenant.canView, isTrue);
    expect(tenant.canUpdateStatus, isFalse);
    expect(RoomPermissions.fromRole(null).canView, isFalse);
  });

  testWidgets('ẩn module phòng khi role không có quyền xem', (tester) async {
    await tester.pumpWidget(
      const RoomManagementApp(permissions: RoomPermissions.denied),
    );

    expect(
      find.text('Bạn không có quyền xem danh sách phòng.'),
      findsOneWidget,
    );
    expect(find.text('Quản lý phòng'), findsNothing);
  });
}
