import 'package:flutter/material.dart';

import 'core/app_theme.dart';
import 'screens/room_list_screen.dart';
import 'services/room_api_service.dart';

void main() {
  runApp(const RoomManagementApp());
}

class RoomManagementApp extends StatelessWidget {
  const RoomManagementApp({super.key, this.roomService});

  final RoomApiService? roomService;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Quản lý phòng',
      theme: AppTheme.light,
      home: RoomListScreen(roomService: roomService ?? RoomApiService()),
    );
  }
}

// Giữ tên cũ để các nơi đang dùng MyApp không bị ảnh hưởng.
class MyApp extends RoomManagementApp {
  const MyApp({super.key, super.roomService});
}
