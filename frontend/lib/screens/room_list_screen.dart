import 'package:flutter/material.dart';

import '../core/formatters.dart';
import '../models/room.dart';
import '../models/room_permissions.dart';
import '../services/room_api_service.dart';
import '../widgets/room_image.dart';
import '../widgets/room_status_chip.dart';
import 'add_room_screen.dart';
import 'room_detail_screen.dart';

class RoomListScreen extends StatefulWidget {
  const RoomListScreen({
    super.key,
    required this.roomService,
    this.permissions = RoomPermissions.denied,
    this.onLogout,
  });

  final RoomApiService roomService;
  final RoomPermissions permissions;
  final VoidCallback? onLogout;

  @override
  State<RoomListScreen> createState() => _RoomListScreenState();
}

class _RoomListScreenState extends State<RoomListScreen> {
  final _searchController = TextEditingController();
  List<Room> _rooms = const [];
  RoomStatus? _selectedStatus;
  String _query = '';
  String? _error;
  bool _loading = true;
  int _loadRequestId = 0;

  List<Room> get _visibleRooms {
    if (_query.isEmpty) return _rooms;
    final query = _query.toLowerCase();
    return _rooms.where((room) {
      return room.roomNumber.toLowerCase().contains(query) ||
          room.roomName.toLowerCase().contains(query) ||
          '${room.floor}'.contains(query) ||
          (room.description?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRooms() async {
    final requestId = ++_loadRequestId;
    final requestedStatus = _selectedStatus;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rooms = await widget.roomService.getRooms(status: requestedStatus);
      if (mounted && requestId == _loadRequestId) {
        setState(() => _rooms = rooms);
      }
    } on ApiException catch (error) {
      if (mounted && requestId == _loadRequestId) {
        setState(() => _error = error.message);
      }
    } finally {
      if (mounted && requestId == _loadRequestId) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _setStatus(RoomStatus? status) async {
    if (_selectedStatus == status) return;
    setState(() => _selectedStatus = status);
    await _loadRooms();
  }

  Future<void> _addRoom() async {
    if (!widget.permissions.canCreate) return;
    final created = await Navigator.push<Room>(
      context,
      MaterialPageRoute(
        builder: (_) => AddRoomScreen(roomService: widget.roomService),
      ),
    );
    if (created == null || !mounted) return;
    _showMessage('Đã thêm phòng ${created.roomNumber}.');
    await _loadRooms();
  }

  Future<void> _openDetail(Room room) async {
    final deleted = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => RoomDetailScreen(
          roomId: room.id,
          roomService: widget.roomService,
          initialRoom: room,
          permissions: widget.permissions,
        ),
      ),
    );
    if (!mounted) return;
    if (deleted == true) _showMessage('Đã xóa phòng ${room.roomNumber}.');
    await _loadRooms();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 74,
        titleSpacing: 20,
        title: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.apartment_rounded, color: Colors.white),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quản lý phòng',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
                Text(
                  'Danh sách và trạng thái phòng',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF667085),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Tải lại',
            onPressed: _loading ? null : _loadRooms,
            icon: const Icon(Icons.refresh_rounded),
          ),
          if (widget.onLogout != null)
            IconButton(
              tooltip: 'Đăng xuất',
              onPressed: widget.onLogout,
              icon: const Icon(Icons.logout),
            ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: widget.permissions.canCreate
          ? FloatingActionButton.extended(
              onPressed: _addRoom,
              icon: const Icon(Icons.add),
              label: const Text('Thêm phòng'),
            )
          : null,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadRooms,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _buildHeader(context)),
              if (_loading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _ListError(message: _error!, onRetry: _loadRooms),
                )
              else if (_visibleRooms.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyRooms(
                    hasFilter: _selectedStatus != null || _query.isNotEmpty,
                    onClear: () {
                      _searchController.clear();
                      setState(() => _query = '');
                      _setStatus(null);
                    },
                    onAdd: widget.permissions.canCreate ? _addRoom : null,
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
                  sliver: SliverLayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.crossAxisExtent;
                      final count = width >= 1100 ? 3 : (width >= 700 ? 2 : 1);
                      return SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: count,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: count == 1 ? 1.65 : 1.34,
                        ),
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final room = _visibleRooms[index];
                          return _RoomCard(
                            room: room,
                            onTap: () => _openDetail(room),
                          );
                        }, childCount: _visibleRooms.length),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final search = TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _query = value.trim()),
                    decoration: InputDecoration(
                      hintText: 'Tìm theo mã, tên phòng, tầng hoặc mô tả...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Xóa tìm kiếm',
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _query = '');
                              },
                              icon: const Icon(Icons.close),
                            ),
                    ),
                  );
                  if (constraints.maxWidth < 660) return search;
                  return Row(
                    children: [
                      Expanded(child: search),
                      if (widget.permissions.canCreate) ...[
                        const SizedBox(width: 14),
                        FilledButton.icon(
                          onPressed: _addRoom,
                          icon: const Icon(Icons.add),
                          label: const Text('Thêm phòng'),
                        ),
                      ],
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'Tất cả',
                      selected: _selectedStatus == null,
                      onTap: () => _setStatus(null),
                    ),
                    ...RoomStatus.values.map(
                      (status) => Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: _FilterChip(
                          label: status.label,
                          selected: _selectedStatus == status,
                          color: RoomStatusChip.colorOf(status),
                          onTap: () => _setStatus(status),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Text(
                    _selectedStatus == null
                        ? 'Tất cả phòng'
                        : _selectedStatus!.label,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Spacer(),
                  if (!_loading && _error == null)
                    Text(
                      '${_visibleRooms.length} phòng',
                      style: const TextStyle(
                        color: Color(0xFF667085),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoomCard extends StatelessWidget {
  const _RoomCard({required this.room, required this.onTap});

  final Room room;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 4,
                child: RoomImage(
                  imageUrl: room.imageUrl,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                flex: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Phòng ${room.roomNumber}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          size: 22,
                          color: Color(0xFF98A2B3),
                        ),
                      ],
                    ),
                    Text(
                      room.roomName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF667085),
                      ),
                    ),
                    const SizedBox(height: 8),
                    RoomStatusChip(status: room.status, compact: true),
                    const Spacer(),
                    Wrap(
                      spacing: 12,
                      runSpacing: 6,
                      children: [
                        _TinyInfo(
                          icon: Icons.layers_outlined,
                          text: 'Tầng ${room.floor}',
                        ),
                        _TinyInfo(
                          icon: Icons.square_foot_outlined,
                          text: formatArea(room.area),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      formatCurrency(room.price),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Text(
                      '/ tháng',
                      style: TextStyle(fontSize: 12, color: Color(0xFF667085)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TinyInfo extends StatelessWidget {
  const _TinyInfo({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: const Color(0xFF667085)),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(fontSize: 12, color: Color(0xFF667085)),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? Theme.of(context).colorScheme.primary;
    return Material(
      color: selected ? activeColor.withValues(alpha: 0.1) : Colors.white,
      shape: StadiumBorder(
        side: BorderSide(
          color: selected ? activeColor : const Color(0xFFDDE0EA),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? activeColor : const Color(0xFF475467),
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyRooms extends StatelessWidget {
  const _EmptyRooms({
    required this.hasFilter,
    required this.onClear,
    this.onAdd,
  });

  final bool hasFilter;
  final VoidCallback onClear;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 0, 32, 100),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: const BoxDecoration(
                color: Color(0xFFEFF1FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.meeting_room_outlined,
                size: 44,
                color: Color(0xFF445BE7),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              hasFilter ? 'Không tìm thấy phòng phù hợp' : 'Chưa có phòng nào',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              hasFilter
                  ? 'Thử thay đổi từ khóa hoặc bộ lọc trạng thái.'
                  : onAdd == null
                  ? 'Hiện chưa có phòng nào để hiển thị.'
                  : 'Hãy thêm phòng đầu tiên để bắt đầu quản lý.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF667085)),
            ),
            if (hasFilter || onAdd != null) ...[
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: hasFilter ? onClear : onAdd,
                icon: Icon(
                  hasFilter ? Icons.filter_alt_off_outlined : Icons.add,
                ),
                label: Text(hasFilter ? 'Xóa bộ lọc' : 'Thêm phòng'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ListError extends StatelessWidget {
  const _ListError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 0, 32, 100),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 58,
              color: Color(0xFF98A2B3),
            ),
            const SizedBox(height: 16),
            Text(
              'Không tải được danh sách phòng',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
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
