import 'package:flutter/material.dart';
import '../../core/helpers/formatters.dart';
import '../../core/network/api_client.dart';
import '../../models/payment.dart';
import '../../services/payment_service.dart';
import '../../widgets/error_view.dart';

class PaymentListScreen extends StatefulWidget {
  const PaymentListScreen({super.key, required this.apiClient});
  final ApiClient apiClient;

  @override
  State<PaymentListScreen> createState() => _PaymentListScreenState();
}

class _PaymentListScreenState extends State<PaymentListScreen> {
  late final PaymentService _service;
  late Future<List<Payment>> _future;

  @override
  void initState() {
    super.initState();
    _service = PaymentService(widget.apiClient);
    _future = _service.getPayments();
  }

  void _reload() => _future = _service.getPayments();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Payment>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return ErrorView(message: snapshot.error.toString(), onRetry: () => setState(_reload));
        final payments = snapshot.data!;
        return RefreshIndicator(
          onRefresh: () async { setState(_reload); await _future; },
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            itemCount: payments.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final payment = payments[index];
              return Card(
                child: ListTile(
                  leading: const CircleAvatar(backgroundColor: Color(0xFFDCFCE7), child: Icon(Icons.check_rounded, color: Colors.green)),
                  title: Text('${payment.roomNumber} · ${formatCurrency(payment.amount)}', style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('${payment.tenantName}\n${formatDate(payment.paymentDate)} · ${payment.method}'),
                  isThreeLine: true,
                ),
              );
            },
          ),
        );
      },
    );
  }
}
