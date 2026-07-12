import 'package:flutter/material.dart';
import '../../models/maintenance_model.dart';
import '../../services/maintenance_service.dart';
import '../../widgets/maintenance_card.dart';
import 'create_maintenance_request_screen.dart';
import 'maintenance_detail_screen.dart';

class MaintenanceRequestListScreen extends StatefulWidget {
  const MaintenanceRequestListScreen({super.key});

  @override
  State<MaintenanceRequestListScreen> createState() => _MaintenanceRequestListScreenState();
}

class _MaintenanceRequestListScreenState extends State<MaintenanceRequestListScreen> {
  final MaintenanceService _service = MaintenanceService();
  String? _status;
  late Future<List<MaintenanceRequestModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadData();
  }

  Future<List<MaintenanceRequestModel>> _loadData() {
    return _service.getMaintenanceRequests(status: _status);
  }

  void _reload() {
    setState(() => _future = _loadData());
  }

  Future<void> _goToCreate() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateMaintenanceRequestScreen()),
    );
    if (result == true) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Yêu cầu sửa chữa')),
      floatingActionButton: FloatingActionButton(
        onPressed: _goToCreate,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: DropdownButtonFormField<String?>(
              value: _status,
              decoration: const InputDecoration(labelText: 'Lọc trạng thái', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: null, child: Text('Tất cả')),
                DropdownMenuItem(value: 'pending', child: Text('Chờ xử lý')),
                DropdownMenuItem(value: 'processing', child: Text('Đang xử lý')),
                DropdownMenuItem(value: 'completed', child: Text('Hoàn thành')),
                DropdownMenuItem(value: 'cancelled', child: Text('Đã hủy')),
              ],
              onChanged: (value) {
                _status = value;
                _reload();
              },
            ),
          ),
          Expanded(
            child: FutureBuilder<List<MaintenanceRequestModel>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Lỗi: ${snapshot.error}'));
                }

                final items = snapshot.data ?? [];
                if (items.isEmpty) {
                  return const Center(child: Text('Chưa có yêu cầu sửa chữa'));
                }

                return RefreshIndicator(
                  onRefresh: () async => _reload(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return MaintenanceCard(
                        item: item,
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => MaintenanceDetailScreen(id: item.id)),
                          );
                          if (result == true) _reload();
                        },
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
  }
}
