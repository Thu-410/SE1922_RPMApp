import 'package:flutter/material.dart';

import '../../core/helpers/formatters.dart';
import '../../models/room.dart';
import '../../services/room_service.dart';
import 'room_form_screen.dart';

class RoomDetailScreen extends StatefulWidget {
  const RoomDetailScreen({super.key, required this.service, required this.roomId, required this.canManage});
  final RoomService service;
  final int roomId;
  final bool canManage;

  @override
  State<RoomDetailScreen> createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends State<RoomDetailScreen> {
  late Future<Room> _future;
  @override
  void initState() {
    super.initState();
    _future = widget.service.detail(widget.roomId);
  }

  void _reload() {
    setState(() {
      _future = widget.service.detail(widget.roomId);
    });
  }

  Future<void> _edit(Room room) async {
    final result = await Navigator.push<Room>(context, MaterialPageRoute(builder: (_) => RoomFormScreen(service: widget.service, room: room)));
    if (result != null) _reload();
  }

  Future<void> _changeStatus(Room room) async {
    var selected = room.status;
    final confirmed = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: const Text('Cập nhật trạng thái'),
      content: StatefulBuilder(builder: (_, setDialogState) => DropdownButtonFormField<String>(
        initialValue: selected,
        items: roomStatuses.map((value) => DropdownMenuItem(value: value, child: Text(roomStatusLabel(value)))).toList(),
        onChanged: (value) => setDialogState(() => selected = value!),
      )),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Cập nhật'))],
    ));
    if (confirmed != true) return;
    try { await widget.service.updateStatus(room.id, selected); _reload(); }
    catch (error) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error'))); }
  }

  Future<void> _delete(Room room) async {
    final confirmed = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: Text('Đưa phòng ${room.roomNumber} vào lịch sử?'),
      content: const Text('Phòng sẽ được ẩn khỏi danh sách quản lý nhưng vẫn được giữ trong database để tra cứu hợp đồng, hóa đơn và dữ liệu cũ.'),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Không')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Đưa vào lịch sử'))],
    ));
    if (confirmed != true) return;
    try { await widget.service.delete(room.id); if (mounted) Navigator.pop(context, true); }
    catch (error) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error'))); }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Room>(
    future: _future,
    builder: (context, snapshot) {
      final room = snapshot.data;
      return Scaffold(
        appBar: AppBar(
          title: Text(room == null ? 'Chi tiết phòng' : 'Phòng ${room.roomNumber}'),
          actions: room != null && widget.canManage ? [
            IconButton(onPressed: () => _edit(room), tooltip: 'Sửa phòng', icon: const Icon(Icons.edit_outlined)),
            PopupMenuButton<String>(onSelected: (value) { if (value == 'status') _changeStatus(room); if (value == 'delete') _delete(room); }, itemBuilder: (_) => const [
              PopupMenuItem(value: 'status', child: Text('Đổi trạng thái')),
              PopupMenuItem(value: 'delete', child: Text('Đưa vào lịch sử')),
            ]),
          ] : null,
        ),
        body: snapshot.connectionState == ConnectionState.waiting
            ? const Center(child: CircularProgressIndicator())
            : snapshot.hasError
                ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Text('${snapshot.error}', textAlign: TextAlign.center), const SizedBox(height: 12), FilledButton(onPressed: _reload, child: const Text('Thử lại'))]))
                : _content(room!),
      );
    },
  );

  Widget _content(Room room) => ListView(padding: const EdgeInsets.all(16), children: [
    if (room.imageUrl != null && room.imageUrl!.isNotEmpty)
      ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.network(room.imageUrl!, height: 200, fit: BoxFit.cover, errorBuilder: (_, _, _) => const SizedBox(height: 140, child: Card(child: Icon(Icons.broken_image_outlined, size: 48))))),
    Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Phòng ${room.roomNumber}', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      _row('Trạng thái', roomStatusLabel(room.status)),
      _row('Tầng', '${room.floor}'),
      _row('Diện tích', '${room.area.toStringAsFixed(1)} m²'),
      _row('Giá phòng', formatCurrency(room.price)),
      _row('Tiền cọc', formatCurrency(room.deposit)),
      _row('Người thuê đang ở', '${room.activeTenantCount}'),
      if (room.description?.isNotEmpty == true) ...[const Divider(), Text(room.description!)],
    ]))),
  ]);

  Widget _row(String label, String value) => Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label), Flexible(child: Text(value, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w600)))]));
}
