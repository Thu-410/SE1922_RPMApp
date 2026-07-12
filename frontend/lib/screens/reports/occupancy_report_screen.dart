import 'package:flutter/material.dart';
import '../../core/helpers/format_helper.dart';
import '../../models/report_model.dart';
import '../../services/report_service.dart';

class OccupancyReportScreen extends StatefulWidget {
  const OccupancyReportScreen({super.key});

  @override
  State<OccupancyReportScreen> createState() => _OccupancyReportScreenState();
}

class _OccupancyReportScreenState extends State<OccupancyReportScreen> {
  final ReportService _service = ReportService();
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.getOccupancyReport();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Báo cáo phòng')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          }

          final summary = snapshot.data?['summary'] ?? {};
          final rawRooms = snapshot.data?['rooms'];
          final rooms = (rawRooms is List)
              ? rawRooms.whereType<OccupancyRoomModel>().toList()
              : <OccupancyRoomModel>[];

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      Text('Tổng: ${summary['total_rooms'] ?? 0}'),
                      Text('Đang thuê: ${summary['occupied_rooms'] ?? 0}'),
                      Text('Trống: ${summary['available_rooms'] ?? 0}'),
                      Text('Sửa chữa: ${summary['maintenance_rooms'] ?? 0}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ...rooms.map((room) {
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.home),
                    title: Text('Phòng ${room.roomNumber}'),
                    subtitle: Text('Tầng ${room.floor ?? ''} • ${room.status} • ${room.tenantName ?? 'Chưa có người thuê'}'),
                    trailing: Text(FormatHelper.currency(room.price ?? 0)),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
