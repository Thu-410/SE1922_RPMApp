import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:orderfood/main.dart';
import 'package:orderfood/models/room.dart';
import 'package:orderfood/screens/room_detail_screen.dart';
import 'package:orderfood/screens/room_form_screen.dart';
import 'package:orderfood/screens/room_status_screen.dart';
import 'package:orderfood/services/room_api_service.dart';

class _FakeRoomApiService extends RoomApiService {
  _FakeRoomApiService({this.rooms = const [], this.detailError});

  final List<Room> rooms;
  final ApiException? detailError;
  RoomStatus? lastFilter;
  RoomStatus? updatedStatus;
  RoomInput? createdInput;
  int? deletedId;

  @override
  Future<List<Room>> getRooms({RoomStatus? status}) async {
    lastFilter = status;
    return status == null
        ? rooms
        : rooms.where((room) => room.status == status).toList();
  }

  @override
  Future<Room> getRoom(int id) async {
    if (detailError != null) throw detailError!;
    return rooms.firstWhere((room) => room.id == id);
  }

  @override
  Future<Room> updateStatus(
    int id,
    RoomStatus status, {
    required int expectedVersion,
  }) async {
    updatedStatus = status;
    return rooms.firstWhere((room) => room.id == id).copyWith(status: status);
  }

  @override
  Future<Room> createRoom(RoomInput input) async {
    createdInput = input;
    return Room(
      id: 99,
      roomNumber: input.roomNumber,
      roomName: input.roomName,
      floor: input.floor,
      area: input.area,
      price: input.price,
      deposit: input.deposit,
      status: input.status,
      version: 1,
      description: input.description,
      images: input.images,
    );
  }

  @override
  Future<void> deleteRoom(int id) async {
    deletedId = id;
  }
}

final _room = Room.fromJson({
  'id': 1,
  'room_number': 'A101',
  'room_name': 'Phòng ban công A101',
  'floor': 1,
  'area': 25.5,
  'price': 3500000,
  'deposit': 3500000,
  'status': 'available',
  'version': 1,
  'description': 'Phòng thoáng',
  'images': const <String>[],
  'created_at': '2026-07-13T08:00:00.000Z',
  'updated_at': '2026-07-13T08:00:00.000Z',
});

Map<String, dynamic> _roomJson({
  String status = 'available',
  int version = 1,
}) => {
  'id': 1,
  'room_number': 'A101',
  'room_name': 'Phòng ban công A101',
  'floor': 1,
  'area': 25.5,
  'price': 3500000,
  'deposit': 3500000,
  'status': status,
  'version': version,
  'description': 'Phòng thoáng',
  'images': <String>[],
};

http.Response _jsonResponse(Map<String, dynamic> body, {int statusCode = 200}) {
  return http.Response.bytes(
    utf8.encode(jsonEncode(body)),
    statusCode,
    headers: const {'content-type': 'application/json; charset=utf-8'},
  );
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

  testWidgets('lọc danh sách phòng theo trạng thái qua API', (tester) async {
    final service = _FakeRoomApiService(rooms: [_room]);
    await tester.pumpWidget(RoomManagementApp(roomService: service));
    await tester.pumpAndSettle();

    expect(find.text('Phòng A101'), findsOneWidget);
    await tester.tap(find.text('Đang sửa chữa'));
    await tester.pumpAndSettle();

    expect(service.lastFilter, RoomStatus.maintenance);
    expect(find.text('Không tìm thấy phòng phù hợp'), findsOneWidget);
  });

  testWidgets('chi tiết phòng không hiển thị dữ liệu cũ khi tải lỗi', (
    tester,
  ) async {
    final service = _FakeRoomApiService(
      rooms: [_room],
      detailError: const ApiException('Không tải được chi tiết phòng.'),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: RoomDetailScreen(
          roomId: _room.id,
          roomService: service,
          initialRoom: _room,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Không tải được chi tiết phòng.'), findsOneWidget);
    expect(find.text('Phòng A101'), findsNothing);
    expect(find.byTooltip('Chỉnh sửa'), findsNothing);
  });

  testWidgets('không cho xóa phòng đang thuê trên giao diện', (tester) async {
    final occupiedRoom = Room.fromJson(_roomJson(status: 'occupied'));
    final service = _FakeRoomApiService(rooms: [occupiedRoom]);
    await tester.pumpWidget(
      MaterialApp(
        home: RoomDetailScreen(
          roomId: occupiedRoom.id,
          roomService: service,
          initialRoom: occupiedRoom,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();

    final deleteItem = tester.widget<PopupMenuItem<String>>(
      find.widgetWithText(PopupMenuItem<String>, 'Không thể xóa khi đang thuê'),
    );
    expect(deleteItem.enabled, isFalse);
    expect(service.deletedId, isNull);
  });

  testWidgets('xóa mềm phòng không thuê từ màn hình chi tiết', (tester) async {
    final service = _FakeRoomApiService(rooms: [_room]);
    await tester.pumpWidget(
      MaterialApp(
        home: RoomDetailScreen(
          roomId: _room.id,
          roomService: service,
          initialRoom: _room,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xóa phòng'));
    await tester.pumpAndSettle();
    expect(find.textContaining('lưu trạng thái “Đã xóa”'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Xóa phòng'));
    await tester.pumpAndSettle();

    expect(service.deletedId, _room.id);
  });

  testWidgets('phòng đang thuê vẫn đổi được sang mọi trạng thái', (
    tester,
  ) async {
    final occupiedRoom = Room.fromJson(_roomJson(status: 'occupied'));
    final service = _FakeRoomApiService(rooms: [occupiedRoom]);
    await tester.pumpWidget(
      MaterialApp(
        home: RoomStatusScreen(room: occupiedRoom, roomService: service),
      ),
    );

    final tiles = tester.widgetList<RadioListTile<RoomStatus>>(
      find.byType(RadioListTile<RoomStatus>),
    );
    expect(tiles.length, RoomStatus.values.length);
    expect(tiles.every((tile) => tile.enabled == true), isTrue);

    await tester.tap(find.text('Phòng trống'));
    await tester.pump();
    await tester.ensureVisible(find.text('Lưu trạng thái'));
    await tester.tap(find.text('Lưu trạng thái'));
    await tester.pumpAndSettle();

    expect(service.updatedStatus, RoomStatus.available);
  });

  testWidgets('form thêm và sửa cho phép chọn đủ bốn trạng thái', (
    tester,
  ) async {
    final service = _FakeRoomApiService(rooms: [_room]);
    for (final room in <Room?>[
      null,
      _room.copyWith(status: RoomStatus.occupied),
    ]) {
      await tester.pumpWidget(
        MaterialApp(
          home: RoomFormScreen(roomService: service, room: room),
        ),
      );
      await tester.pump();

      final dropdownFinder = find.byType(DropdownButtonFormField<RoomStatus>);
      await tester.ensureVisible(dropdownFinder);
      await tester.tap(dropdownFinder);
      await tester.pumpAndSettle();
      for (final status in RoomStatus.values) {
        expect(find.text(status.label), findsWidgets);
      }
      await tester.tap(find.text(RoomStatus.available.label).last);
      await tester.pumpAndSettle();

      final dropdown = tester.widget<DropdownButtonFormField<RoomStatus>>(
        dropdownFinder,
      );
      expect(dropdown.onChanged, isNotNull);
    }
  });

  testWidgets('thêm phòng parse số an toàn và không kẹt loading', (
    tester,
  ) async {
    final service = _FakeRoomApiService();
    await tester.pumpWidget(
      MaterialApp(home: RoomFormScreen(roomService: service)),
    );
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'P999');
    await tester.enterText(fields.at(1), 'Phòng P999');
    await tester.enterText(fields.at(2), '1');
    await tester.enterText(fields.at(3), '25,5');
    await tester.enterText(fields.at(4), '2500000');
    await tester.enterText(fields.at(5), '2500000');

    await tester.fling(
      find.byType(SingleChildScrollView),
      const Offset(0, -2500),
      3000,
    );
    await tester.pumpAndSettle();
    final submit = find.widgetWithText(FilledButton, 'Thêm phòng');
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(service.createdInput, isNotNull);
    expect(service.createdInput!.area, 25.5);
    expect(service.createdInput!.price, 2500000);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('số không hợp lệ không khóa nút thêm phòng', (tester) async {
    final service = _FakeRoomApiService();
    await tester.pumpWidget(
      MaterialApp(home: RoomFormScreen(roomService: service)),
    );
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'P998');
    await tester.enterText(fields.at(1), 'Phòng P998');
    await tester.enterText(fields.at(2), '1');
    await tester.enterText(fields.at(3), ',');
    await tester.enterText(fields.at(4), '2500000');
    await tester.enterText(fields.at(5), '2500000');

    await tester.fling(
      find.byType(SingleChildScrollView),
      const Offset(0, -2500),
      3000,
    );
    await tester.pumpAndSettle();
    final submit = find.widgetWithText(FilledButton, 'Thêm phòng');
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pump();

    expect(service.createdInput, isNull);
    expect(find.text('Giá trị phải là số lớn hơn 0'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tester.widget<FilledButton>(submit).onPressed, isNotNull);
  });

  testWidgets('form giữ cả lựa chọn tải ảnh máy và nhập URL mạng', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: RoomFormScreen(roomService: _FakeRoomApiService())),
    );

    await tester.fling(
      find.byType(SingleChildScrollView),
      const Offset(0, -2500),
      3000,
    );
    await tester.pumpAndSettle();

    expect(find.text('Tải ảnh từ máy'), findsOneWidget);
    expect(find.textContaining('Thêm URL ảnh'), findsOneWidget);
    expect(find.textContaining('dán URL ảnh mạng'), findsOneWidget);
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
      'version': 1,
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

  test('từ chối dữ liệu phòng sai thay vì tự đổi thành giá trị mặc định', () {
    expect(
      () => Room.fromJson({
        'id': 1,
        'room_number': 'A101',
        'room_name': 'Phòng A101',
        'floor': 1,
        'area': 25,
        'price': 3500000,
        'deposit': 3500000,
        'status': 'unknown',
        'version': 1,
      }),
      throwsFormatException,
    );
  });

  test(
    'RoomApiService gọi đúng API CRUD, chi tiết, lọc và trạng thái',
    () async {
      final requests = <String>[];
      final client = MockClient((request) async {
        requests.add('${request.method} ${request.url}');
        final path = request.url.path;

        if (request.method == 'GET' && path == '/api/rooms') {
          expect(request.url.queryParameters['status'], 'maintenance');
          return _jsonResponse({
            'success': true,
            'data': [_roomJson(status: 'maintenance')],
          });
        }
        if (request.method == 'GET' && path == '/api/rooms/1') {
          return _jsonResponse({'success': true, 'data': _roomJson()});
        }
        if (request.method == 'POST' && path == '/api/rooms') {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['status'], 'occupied');
          return _jsonResponse({
            'success': true,
            'data': _roomJson(status: 'occupied'),
          }, statusCode: 201);
        }
        if (request.method == 'PUT' && path == '/api/rooms/1') {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['expected_version'], 1);
          return _jsonResponse({
            'success': true,
            'data': _roomJson(status: body['status'] as String, version: 2),
          });
        }
        if (request.method == 'PUT' && path == '/api/rooms/1/status') {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body, {'status': 'inactive', 'expected_version': 2});
          return _jsonResponse({
            'success': true,
            'data': _roomJson(status: 'inactive', version: 3),
          });
        }
        if (request.method == 'DELETE' && path == '/api/rooms/1') {
          return _jsonResponse({'success': true});
        }
        return _jsonResponse({'success': false}, statusCode: 404);
      });
      final service = RoomApiService(
        client: client,
        baseUrl: 'http://localhost:3000',
      );
      final input = RoomInput(
        roomNumber: 'A101',
        roomName: 'Phòng ban công A101',
        floor: 1,
        area: 25.5,
        price: 3500000,
        deposit: 3500000,
        status: RoomStatus.occupied,
        images: const [],
      );

      final filtered = await service.getRooms(status: RoomStatus.maintenance);
      final detail = await service.getRoom(1);
      final created = await service.createRoom(input);
      final updated = await service.updateRoom(
        1,
        RoomInput(
          roomNumber: input.roomNumber,
          roomName: input.roomName,
          floor: input.floor,
          area: input.area,
          price: input.price,
          deposit: input.deposit,
          status: input.status,
          images: input.images,
          expectedVersion: 1,
        ),
      );
      final statusUpdated = await service.updateStatus(
        1,
        RoomStatus.inactive,
        expectedVersion: 2,
      );
      await service.deleteRoom(1);

      expect(filtered.single.status, RoomStatus.maintenance);
      expect(detail.id, 1);
      expect(created.status, RoomStatus.occupied);
      expect(updated.version, 2);
      expect(statusUpdated.status, RoomStatus.inactive);
      expect(requests.length, 6);
    },
  );

  test(
    'RoomApiService upload multipart và đổi đường dẫn ảnh thành URL',
    () async {
      final client = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/rooms/images');
        expect(
          request.headers['content-type'],
          startsWith('multipart/form-data; boundary='),
        );
        return _jsonResponse({
          'success': true,
          'data': {'image_url': '/uploads/rooms/test.png'},
        }, statusCode: 201);
      });
      final service = RoomApiService(
        client: client,
        baseUrl: 'http://localhost:3000',
      );

      final imageUrl = await service.uploadRoomImage(
        filename: 'test.png',
        bytes: const [0x89, 0x50, 0x4e, 0x47],
      );

      expect(imageUrl, 'http://localhost:3000/uploads/rooms/test.png');
    },
  );

  test(
    'RoomApiService lưu ảnh backend dạng đường dẫn dùng chung thiết bị',
    () async {
      final client = MockClient((request) async {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['images'], [
          '/uploads/rooms/local.png',
          'https://example.com/remote.jpg',
        ]);
        return _jsonResponse({
          'success': true,
          'data': {
            ..._roomJson(),
            'images': ['/uploads/rooms/local.png'],
          },
        }, statusCode: 201);
      });
      final service = RoomApiService(
        client: client,
        baseUrl: 'http://localhost:3000',
      );

      final room = await service.createRoom(
        RoomInput(
          roomNumber: 'A101',
          roomName: 'Phòng A101',
          floor: 1,
          area: 25,
          price: 3000000,
          deposit: 3000000,
          status: RoomStatus.available,
          images: const [
            'http://localhost:3000/uploads/rooms/local.png',
            'https://example.com/remote.jpg',
          ],
        ),
      );

      expect(room.images, ['http://localhost:3000/uploads/rooms/local.png']);
    },
  );
}
