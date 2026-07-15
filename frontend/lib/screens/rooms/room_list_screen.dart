import 'package:flutter/material.dart';

import '../../core/helpers/formatters.dart';
import '../../core/network/api_client.dart';
import '../../models/room.dart';
import '../../services/room_service.dart';
import 'room_detail_screen.dart';
import 'room_form_screen.dart';

class RoomListScreen extends StatefulWidget {
  const RoomListScreen({super.key, required this.apiClient, required this.canManage, this.showAppBar = true});
  final ApiClient apiClient;
  final bool canManage;
  final bool showAppBar;
  @override
  State<RoomListScreen> createState() => _RoomListScreenState();
}

class _RoomListScreenState extends State<RoomListScreen> {
  late final RoomService _service;
  late Future<List<Room>> _future;
  String _status = '';
  @override
  void initState() {
    super.initState();
    _service = RoomService(widget.apiClient);
    _future = _service.list(status: _status);
  }

  void _reload() {
    setState(() {
      _future = _service.list(status: _status);
    });
  }

  Future<void> _refresh() async {
    _reload();
    await _future;
  }

  Future<void> _add() async {
    final result = await Navigator.push<Room>(context, MaterialPageRoute(builder: (_) => RoomFormScreen(service: _service)));
    if (result != null) _reload();
  }

  Future<void> _open(Room room) async {
    await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => RoomDetailScreen(service: _service, roomId: room.id, canManage: widget.canManage)));
    if (mounted) _reload();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: widget.showAppBar ? AppBar(title: const Text('Quản lý phòng')) : null,
    floatingActionButton: widget.canManage ? FloatingActionButton.extended(onPressed: _add, icon: const Icon(Icons.add), label: const Text('Thêm phòng')) : null,
    body: Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        child: DropdownButtonFormField<String>(
          initialValue: _status,
          decoration: const InputDecoration(labelText: 'Lọc theo trạng thái', prefixIcon: Icon(Icons.filter_alt_outlined)),
          items: [const DropdownMenuItem(value: '', child: Text('Tất cả')), ...roomStatuses.map((value) => DropdownMenuItem(value: value, child: Text(roomStatusLabel(value))))],
          onChanged: (value) { _status = value ?? ''; _reload(); },
        ),
      ),
      Expanded(child: FutureBuilder<List<Room>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Text('${snapshot.error}', textAlign: TextAlign.center), const SizedBox(height: 12), FilledButton(onPressed: _reload, child: const Text('Thử lại'))]));
          final rooms = snapshot.data ?? [];
          if (rooms.isEmpty) return const Center(child: Text('Không có phòng phù hợp'));
          return RefreshIndicator(onRefresh: _refresh, child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 88),
            itemCount: rooms.length,
            itemBuilder: (_, index) {
              final room = rooms[index];
              return Card(child: ListTile(
                onTap: () => _open(room),
                leading: CircleAvatar(child: Text(room.roomNumber)),
                title: Text('Phòng ${room.roomNumber}', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Tầng ${room.floor} · ${room.area.toStringAsFixed(1)} m²\n${roomStatusLabel(room.status)}'),
                isThreeLine: true,
                trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [Text(formatCurrency(room.price), style: const TextStyle(fontWeight: FontWeight.w600)), const Icon(Icons.chevron_right)]),
              ));
            },
          ));
        },
      )),
    ]),
  );
}
