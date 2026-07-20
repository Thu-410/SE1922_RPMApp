import 'package:flutter/material.dart';
import '../../core/helpers/formatters.dart';
import '../../core/network/api_client.dart';
import '../../models/dashboard_summary.dart';
import '../../models/maintenance_request.dart';
import '../../services/dashboard_service.dart';
import '../reports/report_screens.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, required this.apiClient});
  final ApiClient apiClient;
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final DashboardService _service;
  late Future<_Data> _future;
  @override
  void initState() {
    super.initState();
    _service = DashboardService(widget.apiClient);
    _reload();
  }

  void _reload() => _future =
      Future.wait([
        _service.summary(),
        _service.revenueOverview(year: DateTime.now().year),
        _service.recentMaintenance(),
      ]).then(
        (v) => _Data(
          v[0] as DashboardSummary,
          v[1] as List<MonthlyRevenue>,
          v[2] as List<MaintenanceRequest>,
        ),
      );
  @override
  Widget build(BuildContext context) => FutureBuilder<_Data>(
    future: _future,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError) {
        return Center(child: Text(snapshot.error.toString()));
      }
      final data = snapshot.data!;
      final maxRevenue = data.revenue.fold<double>(
        1,
        (max, item) => item.totalRevenue > max ? item.totalRevenue : max,
      );
      return RefreshIndicator(
        onRefresh: () async {
          setState(_reload);
          await _future;
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
          children: [
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _card(
                  'Doanh thu tháng',
                  formatCurrency(data.summary.currentMonthRevenue),
                  Icons.payments,
                  Colors.green,
                ),
                _card(
                  'Phòng đang thuê',
                  '${data.summary.occupiedRooms}/${data.summary.totalRooms}',
                  Icons.home_work,
                  Colors.blue,
                ),
                _card(
                  'Phòng trống',
                  '${data.summary.availableRooms}',
                  Icons.meeting_room,
                  Colors.teal,
                ),
                _card(
                  'Công nợ',
                  formatCurrency(data.summary.totalDebtAmount),
                  Icons.warning_amber,
                  Colors.orange,
                ),
                _card(
                  'Hóa đơn nợ',
                  '${data.summary.unpaidInvoices + data.summary.overdueInvoices}',
                  Icons.receipt_long,
                  Colors.red,
                ),
                _card(
                  'Sự cố chờ',
                  '${data.summary.pendingRequests}',
                  Icons.build,
                  Colors.deepPurple,
                ),
              ],
            ),
            const SizedBox(height: 22),
            Text(
              'Doanh thu theo tháng',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ...data.revenue
                .where((e) => e.totalRevenue > 0)
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 9),
                    child: Row(
                      children: [
                        SizedBox(width: 58, child: Text('T${item.month}')),
                        Expanded(
                          child: LinearProgressIndicator(
                            value: item.totalRevenue / maxRevenue,
                            minHeight: 12,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 112,
                          child: Text(
                            formatCurrency(item.totalRevenue),
                            textAlign: TextAlign.end,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            const SizedBox(height: 18),
            Text(
              'Báo cáo',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.bar_chart, size: 18),
                  label: const Text('Doanh thu'),
                  onPressed: () => _open(ReportType.revenue),
                ),
                ActionChip(
                  avatar: const Icon(Icons.account_balance_wallet, size: 18),
                  label: const Text('Công nợ'),
                  onPressed: () => _open(ReportType.debt),
                ),
                ActionChip(
                  avatar: const Icon(Icons.home_work, size: 18),
                  label: const Text('Phòng'),
                  onPressed: () => _open(ReportType.occupancy),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              'Sự cố gần đây',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            ...data.recent.map(
              (item) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.build_circle_outlined),
                title: Text(item.title),
                subtitle: Text(
                  '${item.roomNumber ?? ''} · ${item.tenantName ?? ''}',
                ),
                trailing: Text(item.status),
              ),
            ),
          ],
        ),
      );
    },
  );
  Widget _card(String title, String value, IconData icon, Color color) =>
      SizedBox(
        width: (MediaQuery.sizeOf(context).width - 42) / 2,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: color),
                const SizedBox(height: 10),
                Text(title),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ),
      );
  void _open(ReportType type) => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => ReportScreen(apiClient: widget.apiClient, type: type),
    ),
  );
}

class _Data {
  const _Data(this.summary, this.revenue, this.recent);
  final DashboardSummary summary;
  final List<MonthlyRevenue> revenue;
  final List<MaintenanceRequest> recent;
}
