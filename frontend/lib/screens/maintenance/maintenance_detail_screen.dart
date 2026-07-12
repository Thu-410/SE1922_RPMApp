import 'package:flutter/material.dart';
import '../../core/helpers/format_helper.dart';
import '../../models/maintenance_model.dart';
import '../../services/maintenance_service.dart';
import 'update_maintenance_status_screen.dart';

class MaintenanceDetailScreen extends StatefulWidget {
  final int id;

  const MaintenanceDetailScreen({super.key, required this.id});

  @override
  State<MaintenanceDetailScreen> createState() => _MaintenanceDetailScreenState();
}

class _MaintenanceDetailScreenState extends State<MaintenanceDetailScreen> {
  final MaintenanceService _service = MaintenanceService();
  late Future<MaintenanceRequestModel> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.getById(widget.id);
  }

  void _reload() {
    setState(() => _future = _service.getById(widget.id));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết sự cố')),
      body: FutureBuilder<MaintenanceRequestModel>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          }

          final item = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(item.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _InfoRow(label: 'Trạng thái', value: item.status),
              _InfoRow(label: 'Phòng', value: item.roomNumber ?? '${item.roomId ?? ''}'),
              _InfoRow(label: 'Người thuê', value: item.tenantName ?? ''),
              _InfoRow(label: 'SĐT', value: item.tenantPhone ?? ''),
              _InfoRow(label: 'Ngày gửi', value: FormatHelper.dateTime(item.createdAt)),
              const Divider(height: 32),
              const Text('Mô tả', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(item.description),
              if (item.imageUrl != null && item.imageUrl!.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Ảnh sự cố', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Image.network(item.imageUrl!, height: 180, fit: BoxFit.cover),
              ],
              const SizedBox(height: 16),
              const Text('Ghi chú xử lý', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(item.managerNote ?? 'Chưa có ghi chú'),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.edit),
                label: const Text('Cập nhật trạng thái'),
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => UpdateMaintenanceStatusScreen(item: item)),
                  );
                  if (result == true) {
                    _reload();
                    if (mounted) Navigator.pop(context, true);
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
