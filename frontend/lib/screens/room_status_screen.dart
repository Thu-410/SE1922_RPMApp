import 'package:flutter/material.dart';

import '../models/room.dart';
import '../services/room_api_service.dart';
import '../widgets/room_status_chip.dart';

class RoomStatusScreen extends StatefulWidget {
  const RoomStatusScreen({
    super.key,
    required this.room,
    required this.roomService,
  });

  final Room room;
  final RoomApiService roomService;

  @override
  State<RoomStatusScreen> createState() => _RoomStatusScreenState();
}

class _RoomStatusScreenState extends State<RoomStatusScreen> {
  late RoomStatus _selectedStatus = widget.room.status;
  bool _saving = false;

  Future<void> _save() async {
    if (_selectedStatus == widget.room.status || _saving) return;
    setState(() => _saving = true);
    try {
      final room = await widget.roomService.updateStatus(
        widget.room.id,
        _selectedStatus,
      );
      if (!mounted) return;
      Navigator.pop(context, room);
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trạng thái phòng')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                Text(
                  widget.room.roomName,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Mã phòng: ${widget.room.roomNumber}',
                  style: const TextStyle(color: Color(0xFF667085)),
                ),
                const SizedBox(height: 24),
                RadioGroup<RoomStatus>(
                  groupValue: _selectedStatus,
                  onChanged: (value) {
                    if (!_saving && value != null) {
                      setState(() => _selectedStatus = value);
                    }
                  },
                  child: Column(
                    children: RoomStatus.values
                        .map(
                          (status) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Card(
                              child: RadioListTile<RoomStatus>(
                                value: status,
                                enabled: !_saving,
                                title: RoomStatusChip(status: status),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(_descriptionOf(status)),
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _selectedStatus == widget.room.status || _saving
                      ? null
                      : _save,
                  icon: _saving
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_outlined),
                  label: const Text('Lưu trạng thái'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _descriptionOf(RoomStatus status) => switch (status) {
    RoomStatus.available => 'Phòng đang trống và có thể cho thuê.',
    RoomStatus.occupied => 'Phòng hiện đang có người thuê.',
    RoomStatus.maintenance => 'Phòng đang sửa chữa hoặc bảo trì.',
    RoomStatus.inactive => 'Phòng tạm ngừng sử dụng.',
  };
}
