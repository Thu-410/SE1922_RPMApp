import 'package:flutter/material.dart';

import '../core/formatters.dart';
import '../models/room.dart';
import '../services/room_api_service.dart';
import '../widgets/room_gallery.dart';
import '../widgets/room_status_chip.dart';
import 'edit_room_screen.dart';
import 'room_status_screen.dart';

class RoomDetailScreen extends StatefulWidget {
  const RoomDetailScreen({
    super.key,
    required this.roomId,
    required this.roomService,
    this.initialRoom,
  });

  final int roomId;
  final RoomApiService roomService;
  final Room? initialRoom;

  @override
  State<RoomDetailScreen> createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends State<RoomDetailScreen> {
  Room? _room;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _room = widget.initialRoom;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = _room == null;
      _error = null;
    });
    try {
      final room = await widget.roomService.getRoom(widget.roomId);
      if (mounted) setState(() => _room = room);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _edit() async {
    final room = _room;
    if (room == null) return;
    final updated = await Navigator.push<Room>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            EditRoomScreen(roomService: widget.roomService, room: room),
      ),
    );
    if (updated == null || !mounted) return;
    setState(() => _room = updated);
    _showMessage('Đã cập nhật phòng ${updated.roomNumber}.');
  }

  Future<void> _chooseStatus() async {
    final room = _room;
    if (room == null) return;
    final updated = await Navigator.push<Room>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            RoomStatusScreen(room: room, roomService: widget.roomService),
      ),
    );
    if (updated == null || !mounted) return;
    setState(() => _room = updated);
    _showMessage('Đã đổi trạng thái thành “${updated.status.label}”.');
  }

  Future<void> _delete() async {
    final room = _room;
    if (room == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.delete_outline, color: Colors.red),
        title: Text('Xóa phòng ${room.roomNumber}?'),
        content: const Text(
          'Phòng sẽ bị xóa khỏi hệ thống. Thao tác này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa phòng'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await widget.roomService.deleteRoom(room.id);
      if (!mounted) return;
      Navigator.pop(context, true);
    } on ApiException catch (error) {
      if (mounted) _showMessage(error.message, isError: true);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết phòng'),
        actions: [
          if (_room != null) ...[
            IconButton(
              tooltip: 'Chỉnh sửa',
              onPressed: _edit,
              icon: const Icon(Icons.edit_outlined),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'delete') _delete();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, color: Colors.red),
                      SizedBox(width: 10),
                      Text('Xóa phòng', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _room == null
          ? _ErrorState(
              message: _error ?? 'Không tìm thấy phòng.',
              onRetry: _load,
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: _DetailContent(
                room: _room!,
                onChangeStatus: _chooseStatus,
              ),
            ),
    );
  }
}

class _DetailContent extends StatelessWidget {
  const _DetailContent({required this.room, required this.onChangeStatus});

  final Room room;
  final VoidCallback onChangeStatus;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 720;
                final image = RoomGallery(
                  imageUrls: room.images,
                  height: wide ? 360 : 230,
                );
                final summary = _RoomSummary(
                  room: room,
                  onChangeStatus: onChangeStatus,
                );
                return Column(
                  children: [
                    if (wide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 6, child: image),
                          const SizedBox(width: 20),
                          Expanded(flex: 5, child: summary),
                        ],
                      )
                    else ...[
                      image,
                      const SizedBox(height: 18),
                      summary,
                    ],
                    const SizedBox(height: 20),
                    _InfoCard(
                      title: 'Thông tin phòng',
                      children: [
                        _InfoRow(
                          icon: Icons.tag_outlined,
                          label: 'Mã phòng',
                          value: room.roomNumber,
                        ),
                        _InfoRow(
                          icon: Icons.meeting_room_outlined,
                          label: 'Tên phòng',
                          value: room.roomName,
                        ),
                        _InfoRow(
                          icon: Icons.layers_outlined,
                          label: 'Tầng',
                          value: '${room.floor}',
                        ),
                        _InfoRow(
                          icon: Icons.square_foot_outlined,
                          label: 'Diện tích',
                          value: formatArea(room.area),
                        ),
                        _InfoRow(
                          icon: Icons.payments_outlined,
                          label: 'Giá phòng',
                          value: '${formatCurrency(room.price)} / tháng',
                        ),
                        _InfoRow(
                          icon: Icons.account_balance_wallet_outlined,
                          label: 'Tiền cọc',
                          value: formatCurrency(room.deposit),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _InfoCard(
                      title: 'Mô tả',
                      children: [
                        Text(
                          room.description?.trim().isNotEmpty == true
                              ? room.description!
                              : 'Chưa có mô tả cho phòng này.',
                          style: const TextStyle(
                            color: Color(0xFF475467),
                            fontSize: 15,
                            height: 1.55,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _InfoCard(
                      title: 'Lịch sử',
                      children: [
                        _InfoRow(
                          icon: Icons.add_circle_outline,
                          label: 'Ngày tạo',
                          value: formatDateTime(room.createdAt),
                        ),
                        _InfoRow(
                          icon: Icons.update_outlined,
                          label: 'Cập nhật gần nhất',
                          value: formatDateTime(room.updatedAt),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _RoomSummary extends StatelessWidget {
  const _RoomSummary({required this.room, required this.onChangeStatus});

  final Room room;
  final VoidCallback onChangeStatus;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PHÒNG',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: const Color(0xFF667085),
                letterSpacing: 1.2,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Phòng ${room.roomNumber}',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: const Color(0xFF17203A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              room.roomName,
              style: const TextStyle(color: Color(0xFF667085)),
            ),
            const SizedBox(height: 12),
            RoomStatusChip(status: room.status),
            const SizedBox(height: 22),
            Text(
              formatCurrency(room.price),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const Text('/ tháng', style: TextStyle(color: Color(0xFF667085))),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onChangeStatus,
                icon: const Icon(Icons.swap_horiz_rounded),
                label: const Text('Cập nhật trạng thái'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 21, color: const Color(0xFF667085)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF667085)),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 56,
              color: Color(0xFF98A2B3),
            ),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}
