import 'package:flutter/material.dart';

import 'core/app_theme.dart';
import 'models/room_permissions.dart';
import 'screens/room_list_screen.dart';
import 'services/room_api_service.dart';

void main() {
  runApp(const RoomManagementApp());
}

class RoomManagementApp extends StatelessWidget {
  const RoomManagementApp({
    super.key,
    this.roomService,
    this.permissions = RoomPermissions.unrestricted,
  });

  final RoomApiService? roomService;
  final RoomPermissions permissions;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Quản lý phòng',
      theme: AppTheme.light,
      home: permissions.canView
          ? RoomListScreen(
              roomService: roomService ?? RoomApiService(),
              permissions: permissions,
            )
          : const _RoomAccessDeniedScreen(),
    );
  }
}

// Giữ tên cũ để các nơi đang dùng MyApp không bị ảnh hưởng.
class MyApp extends RoomManagementApp {
  const MyApp({super.key, super.roomService, super.permissions});
}

class _RoomAccessDeniedScreen extends StatelessWidget {
  const _RoomAccessDeniedScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline, size: 58, color: Color(0xFF98A2B3)),
                SizedBox(height: 16),
                Text(
                  'Bạn không có quyền xem danh sách phòng.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
