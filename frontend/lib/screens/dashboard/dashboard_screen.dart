import 'package:flutter/material.dart';
import '../../core/helpers/format_helper.dart';
import '../../models/dashboard_summary_model.dart';
import '../../models/maintenance_model.dart';
import '../../models/report_model.dart';
import '../../services/dashboard_service.dart';
import '../../widgets/dashboard_card.dart';
import '../../widgets/maintenance_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DashboardService _service = DashboardService();
  late Future<_DashboardData> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadData();
  }

  Future<_DashboardData> _loadData() async {
    final summary = await _service.getSummary();
    final revenue = await _service.getRevenueOverview(year: DateTime.now().year);
    final recent = await _service.getRecentMaintenance(limit: 5);
    return _DashboardData(summary: summary, revenue: revenue, recent: recent);
  }

  Future<void> _refresh() async {
    setState(() => _future = _loadData());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: FutureBuilder<_DashboardData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          }

          final data = snapshot.data!;
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                DashboardCard(
                  title: 'Doanh thu tháng này',
                  value: FormatHelper.currency(data.summary.currentMonthRevenue),
                  icon: Icons.payments,
                ),
                DashboardCard(
                  title: 'Tổng số phòng',
                  value: '${data.summary.totalRooms}',
                  icon: Icons.home_work,
                ),
                DashboardCard(
                  title: 'Phòng đang thuê',
                  value: '${data.summary.occupiedRooms}',
                  icon: Icons.meeting_room,
                ),
                DashboardCard(
                  title: 'Phòng trống',
                  value: '${data.summary.availableRooms}',
                  icon: Icons.sensor_door,
                ),
                DashboardCard(
                  title: 'Hóa đơn chưa thanh toán',
                  value: '${data.summary.unpaidInvoices + data.summary.overdueInvoices}',
                  icon: Icons.receipt_long,
                ),
                DashboardCard(
                  title: 'Sự cố đang chờ',
                  value: '${data.summary.pendingRequests}',
                  icon: Icons.build,
                ),
                const SizedBox(height: 16),
                const Text('Doanh thu theo tháng', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...data.revenue.map((e) => _RevenueBar(item: e)).toList(),
                const SizedBox(height: 16),
                const Text('Yêu cầu sửa chữa gần đây', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...data.recent.map((e) => MaintenanceCard(item: e)).toList(),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _RevenueBar extends StatelessWidget {
  final MonthlyRevenueModel item;

  const _RevenueBar({required this.item});

  @override
  Widget build(BuildContext context) {
    final value = item.revenue > 0 ? item.revenue : item.totalRevenue;
    final widthFactor = (value / 10000000).clamp(0.05, 1.0).toDouble();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tháng ${item.month}: ${FormatHelper.currency(value)}'),
          const SizedBox(height: 4),
          FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: widthFactor,
            child: Container(height: 10, decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: Theme.of(context).colorScheme.primary)),
          ),
        ],
      ),
    );
  }
}

class _DashboardData {
  final DashboardSummaryModel summary;
  final List<MonthlyRevenueModel> revenue;
  final List<MaintenanceRequestModel> recent;

  _DashboardData({required this.summary, required this.revenue, required this.recent});
}
