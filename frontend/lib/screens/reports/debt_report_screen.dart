import 'package:flutter/material.dart';
import '../../core/helpers/format_helper.dart';
import '../../models/report_model.dart';
import '../../services/report_service.dart';

class DebtReportScreen extends StatefulWidget {
  const DebtReportScreen({super.key});

  @override
  State<DebtReportScreen> createState() => _DebtReportScreenState();
}

class _DebtReportScreenState extends State<DebtReportScreen> {
  final ReportService _service = ReportService();
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.getDebtReport();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Báo cáo công nợ')),
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
          final rawRows = snapshot.data?['rows'];
          final rows = (rawRows is List)
              ? rawRows.whereType<DebtModel>().toList()
              : <DebtModel>[];

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Số hóa đơn còn nợ: ${summary['debt_invoice_count'] ?? 0}'),
                      const SizedBox(height: 8),
                      Text(
                        'Tổng tiền nợ: ${FormatHelper.currency(summary['total_debt_amount'] ?? 0)}',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ...rows.map((item) {
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.warning_amber),
                    title: Text('Phòng ${item.roomNumber ?? ''} - ${item.tenantName ?? ''}'),
                    subtitle: Text('Hóa đơn ${item.month}/${item.year} • Hạn: ${FormatHelper.date(item.dueDate)} • ${item.status}'),
                    trailing: Text(FormatHelper.currency(item.totalAmount)),
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
