import 'package:flutter/material.dart';

import '../../core/helpers/formatters.dart';
import '../../core/network/api_client.dart';
import '../../models/maintenance_request.dart';
import '../../services/report_service.dart';

enum ReportType { revenue, debt, occupancy }

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key, required this.apiClient, required this.type});

  final ApiClient apiClient;
  final ReportType type;

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  late final ReportService _service;
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _service = ReportService(widget.apiClient);
    _future = switch (widget.type) {
      ReportType.revenue => _service.revenue(DateTime.now().year),
      ReportType.debt => _service.debts(),
      ReportType.occupancy => _service.occupancy(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final title = switch (widget.type) {
      ReportType.revenue => 'Báo cáo doanh thu',
      ReportType.debt => 'Báo cáo công nợ',
      ReportType.occupancy => 'Thống kê phòng',
    };
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }
          return switch (widget.type) {
            ReportType.revenue => _revenue(snapshot.data!),
            ReportType.debt => _debt(snapshot.data!),
            ReportType.occupancy => _occupancy(snapshot.data!),
          };
        },
      ),
    );
  }

  Widget _revenue(Map<String, dynamic> data) {
    final rows = _service.revenueRows(data);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: ListTile(
            title: Text('Tổng doanh thu ${DateTime.now().year}'),
            subtitle: Text(
              formatCurrency(NumberParser.decimal(data['total_revenue'])),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        ...rows.map(
          (item) => ListTile(
            leading: CircleAvatar(child: Text('${item.month}')),
            title: Text(formatCurrency(item.totalRevenue)),
            subtitle: Text('${item.paidInvoices} giao dịch'),
          ),
        ),
      ],
    );
  }

  Widget _debt(Map<String, dynamic> data) {
    final summary = data['summary'] as Map<String, dynamic>;
    final rows = _service.debtRows(data);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: ListTile(
            title: Text('${summary['debt_invoice_count']} hóa đơn còn nợ'),
            subtitle: Text(
              formatCurrency(
                NumberParser.decimal(summary['total_debt_amount']),
              ),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        ...rows.map(
          (item) => Card(
            child: ListTile(
              title: Text('${item.roomNumber} · ${item.tenantName}'),
              subtitle: Text(
                'Hóa đơn ${item.month}/${item.year} · ${item.status}',
              ),
              trailing: Text(formatCurrency(item.amount)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _occupancy(Map<String, dynamic> data) {
    final summary = data['summary'] as Map<String, dynamic>;
    final rooms = _service.occupancyRooms(data);
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
                Text('Tổng: ${summary['total_rooms']}'),
                Text('Đang thuê: ${summary['occupied_rooms']}'),
                Text('Trống: ${summary['available_rooms']}'),
                Text('Tỷ lệ: ${summary['occupancy_rate']}%'),
              ],
            ),
          ),
        ),
        ...rooms.map(
          (room) => ListTile(
            leading: const Icon(Icons.home),
            title: Text('Phòng ${room.roomNumber}'),
            subtitle: Text(
              '${room.status} · ${room.tenantName ?? 'Chưa có người thuê'}',
            ),
            trailing: Text(formatCurrency(room.price)),
          ),
        ),
      ],
    );
  }
}
