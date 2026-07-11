import 'package:flutter/material.dart';

import '../models/room.dart';
import '../services/room_api_service.dart';
import 'room_form_screen.dart';

class AddRoomScreen extends StatelessWidget {
  const AddRoomScreen({super.key, required this.roomService});

  final RoomApiService roomService;

  @override
  Widget build(BuildContext context) {
    return RoomFormScreen(roomService: roomService);
  }
}

