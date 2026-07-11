import 'package:flutter/material.dart';

import '../models/room.dart';
import '../services/room_api_service.dart';
import 'room_form_screen.dart';

class EditRoomScreen extends StatelessWidget {
  const EditRoomScreen({
    super.key,
    required this.roomService,
    required this.room,
  });

  final RoomApiService roomService;
  final Room room;

  @override
  Widget build(BuildContext context) {
    return RoomFormScreen(roomService: roomService, room: room);
  }
}

