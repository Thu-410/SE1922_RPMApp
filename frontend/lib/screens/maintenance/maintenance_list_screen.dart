import 'package:flutter/material.dart';
import '../../core/helpers/formatters.dart';
import '../../core/network/api_client.dart';
import '../../models/maintenance_request.dart';
import '../../services/maintenance_service.dart';

class MaintenanceListScreen extends StatefulWidget {
  const MaintenanceListScreen({
    super.key,
    required this.apiClient,
    required this.isTenant,
  });
  final ApiClient apiClient;
  final bool isTenant;
  @override
  State<MaintenanceListScreen> createState() => _MaintenanceListScreenState();
}

class _MaintenanceListScreenState extends State<MaintenanceListScreen> {
  late final MaintenanceService _service;
  late Future<List<MaintenanceRequest>> _future;
  String? _status;
  @override
  void initState() {
    super.initState();
    _service = MaintenanceService(widget.apiClient);
    _reload();
  }

  void _reload() => _future = _service.list(status: _status);

  Future<void> _create() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => MaintenanceCreateScreen(apiClient: widget.apiClient),
      ),
    );
    if (changed == true && mounted) setState(_reload);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    floatingActionButton: widget.isTenant
        ? FloatingActionButton(onPressed: _create, child: const Icon(Icons.add))
        : null,
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: DropdownButtonFormField<String?>(
            initialValue: _status,
            decoration: const InputDecoration(
              labelText: 'Lọc trạng thái',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: null, child: Text('Tất cả')),
              DropdownMenuItem(value: 'pending', child: Text('Chờ xử lý')),
              DropdownMenuItem(value: 'processing', child: Text('Đang xử lý')),
              DropdownMenuItem(value: 'completed', child: Text('Hoàn thành')),
              DropdownMenuItem(value: 'cancelled', child: Text('Đã hủy')),
            ],
            onChanged: (value) {
              _status = value;
              setState(_reload);
            },
          ),
        ),
        Expanded(
          child: FutureBuilder<List<MaintenanceRequest>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text(snapshot.error.toString()));
              }
              final items = snapshot.data!;
              if (items.isEmpty) {
                return const Center(child: Text('Chưa có yêu cầu sửa chữa'));
              }
              return RefreshIndicator(
                onRefresh: () async {
                  setState(_reload);
                  await _future;
                },
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (_, index) {
                    final item = items[index];
                    return Card(
                      child: ListTile(
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MaintenanceDetailScreen(
                                apiClient: widget.apiClient,
                                id: item.id,
                                canUpdate: !widget.isTenant,
                              ),
                            ),
                          );
                          if (mounted) setState(_reload);
                        },
                        leading: Icon(_issueIcon(item.issueType)),
                        title: Text(
                          item.title,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          '${item.roomNumber ?? ''} · ${item.tenantName ?? ''}\n${_statusText(item.status)}',
                        ),
                        isThreeLine: true,
                        trailing: const Icon(Icons.chevron_right),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    ),
  );

  IconData _issueIcon(String type) => switch (type) {
    'electric' => Icons.electrical_services,
    'water' => Icons.water_drop,
    'internet' => Icons.wifi,
    'lock' => Icons.lock,
    'cleaning' => Icons.cleaning_services,
    _ => Icons.build,
  };
}

String _statusText(String status) => switch (status) {
  'pending' => 'Chờ xử lý',
  'processing' => 'Đang xử lý',
  'completed' => 'Hoàn thành',
  'cancelled' => 'Đã hủy',
  _ => status,
};

class MaintenanceCreateScreen extends StatefulWidget {
  const MaintenanceCreateScreen({super.key, required this.apiClient});
  final ApiClient apiClient;
  @override
  State<MaintenanceCreateScreen> createState() =>
      _MaintenanceCreateScreenState();
}

class _MaintenanceCreateScreenState extends State<MaintenanceCreateScreen> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _imageUrl = TextEditingController();
  String _issueType = 'other';
  bool _saving = false;
  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _imageUrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await MaintenanceService(widget.apiClient).create(
        title: _title.text.trim(),
        description: _description.text.trim(),
        issueType: _issueType,
        imageUrl: _imageUrl.text.trim(),
      );
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Gửi yêu cầu sửa chữa')),
    body: Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<String>(
            initialValue: _issueType,
            decoration: const InputDecoration(
              labelText: 'Loại sự cố',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'electric', child: Text('Điện')),
              DropdownMenuItem(value: 'water', child: Text('Nước')),
              DropdownMenuItem(value: 'internet', child: Text('Internet')),
              DropdownMenuItem(value: 'furniture', child: Text('Nội thất')),
              DropdownMenuItem(value: 'lock', child: Text('Khóa')),
              DropdownMenuItem(value: 'cleaning', child: Text('Vệ sinh')),
              DropdownMenuItem(value: 'other', child: Text('Khác')),
            ],
            onChanged: (value) => setState(() => _issueType = value!),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _title,
            decoration: const InputDecoration(
              labelText: 'Tiêu đề',
              border: OutlineInputBorder(),
            ),
            validator: (v) =>
                v?.trim().isEmpty == true ? 'Vui lòng nhập tiêu đề' : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _description,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Mô tả chi tiết',
              border: OutlineInputBorder(),
            ),
            validator: (v) =>
                v?.trim().isEmpty == true ? 'Vui lòng nhập mô tả' : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _imageUrl,
            decoration: const InputDecoration(
              labelText: 'URL ảnh (không bắt buộc)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: const Icon(Icons.send),
            label: Text(_saving ? 'Đang gửi...' : 'Gửi yêu cầu'),
          ),
        ],
      ),
    ),
  );
}

class MaintenanceDetailScreen extends StatefulWidget {
  const MaintenanceDetailScreen({
    super.key,
    required this.apiClient,
    required this.id,
    required this.canUpdate,
  });
  final ApiClient apiClient;
  final int id;
  final bool canUpdate;
  @override
  State<MaintenanceDetailScreen> createState() =>
      _MaintenanceDetailScreenState();
}

class _MaintenanceDetailScreenState extends State<MaintenanceDetailScreen> {
  late final MaintenanceService _service;
  late Future<MaintenanceRequest> _future;
  @override
  void initState() {
    super.initState();
    _service = MaintenanceService(widget.apiClient);
    _reload();
  }

  void _reload() => _future = _service.getById(widget.id);
  Future<void> _update(MaintenanceRequest item) async {
    final note = TextEditingController(text: item.managerNote);
    var status = item.status;
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Cập nhật xử lý'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: status,
                items: ['pending', 'processing', 'completed', 'cancelled']
                    .map(
                      (v) => DropdownMenuItem(
                        value: v,
                        child: Text(_statusText(v)),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setDialogState(() => status = v!),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: note,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Ghi chú xử lý',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Đóng'),
            ),
            FilledButton(
              onPressed: () async {
                try {
                  await _service.updateStatus(
                    item.id,
                    status,
                    note.text.trim(),
                  );
                  if (context.mounted) {
                    Navigator.pop(context, true);
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(e.toString())));
                  }
                }
              },
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
    note.dispose();
    if (saved == true && mounted) {
      setState(_reload);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Chi tiết sự cố')),
    body: FutureBuilder<MaintenanceRequest>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text(snapshot.error.toString()));
        }
        final item = snapshot.data!;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              item.title,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text('${item.roomNumber ?? ''} · ${item.tenantName ?? ''}'),
            Text('Trạng thái: ${_statusText(item.status)}'),
            if (item.createdAt != null)
              Text('Ngày gửi: ${formatDate(item.createdAt!)}'),
            const Divider(height: 32),
            const Text('Mô tả', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(item.description),
            if (item.imageUrl?.isNotEmpty == true) ...[
              const SizedBox(height: 16),
              Image.network(
                item.imageUrl!,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const Text('Không tải được ảnh'),
              ),
            ],
            const SizedBox(height: 20),
            const Text(
              'Ghi chú xử lý',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              item.managerNote?.isNotEmpty == true
                  ? item.managerNote!
                  : 'Chưa có',
            ),
            if (widget.canUpdate) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => _update(item),
                icon: const Icon(Icons.edit),
                label: const Text('Cập nhật trạng thái'),
              ),
            ],
          ],
        );
      },
    ),
  );
}
