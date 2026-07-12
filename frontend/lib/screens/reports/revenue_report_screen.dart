import 'package:flutter/material.dart';
import '../../core/helpers/format_helper.dart';
import '../../models/report_model.dart';
import '../../services/report_service.dart';

class RevenueReportScreen extends StatefulWidget {
  const RevenueReportScreen({super.key});

  @override
  State<RevenueReportScreen> createState() => _RevenueReportScreenState();
}

class _RevenueReportScreenState extends State<RevenueReportScreen> {
  final ReportService _service = ReportService();
  late Future<Map<String, dynamic>> _future;
  final int _year = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _future = _service.getRevenueReport(year: _year);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Báo cáo doanh thu')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          }

          final total = snapshot.data?['total_revenue'] ?? 0;
          final rawRows = snapshot.data?['rows'];
          final rows = (rawRows is List)
              ? rawRows.whereType<MonthlyRevenueModel>().toList()
              : <MonthlyRevenueModel>[];

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tổng doanh thu năm $_year'),
                      const SizedBox(height: 8),
                      Text(
                        FormatHelper.currency(total),
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ...rows.map((item) {
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.bar_chart),
                    title: Text('Tháng ${item.month}/${item.year ?? _year}'),
                    subtitle: Text('Số hóa đơn đã thanh toán: ${item.totalPaidInvoices}'),
                    trailing: Text(FormatHelper.currency(item.totalRevenue)),
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
