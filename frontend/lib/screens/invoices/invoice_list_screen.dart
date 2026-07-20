import 'package:flutter/material.dart';
import '../../core/helpers/formatters.dart';
import '../../core/network/api_client.dart';
import '../../models/invoice.dart';
import '../../services/invoice_service.dart';
import '../../widgets/error_view.dart';
import 'invoice_detail_screen.dart';
import 'invoice_form_screen.dart';

class InvoiceListScreen extends StatefulWidget {
  const InvoiceListScreen({
    super.key,
    required this.apiClient,
    this.tenantMode = false,
    this.canCancel = false,
  });
  final ApiClient apiClient;
  final bool tenantMode;
  final bool canCancel;

  @override
  State<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends State<InvoiceListScreen> {
  late final InvoiceService _service;
  late Future<List<Invoice>> _future;

  @override
  void initState() {
    super.initState();
    _service = InvoiceService(widget.apiClient);
    _future = widget.tenantMode
        ? _service.getMyInvoices()
        : _service.getInvoices();
  }

  void _reload() => _future = widget.tenantMode
      ? _service.getMyInvoices()
      : _service.getInvoices();

  Color _statusColor(String status) => switch (status) {
    'paid' => Colors.green,
    'overdue' => Colors.red,
    'cancelled' => Colors.grey,
    _ => Colors.orange,
  };

  Future<void> _showDetails(Invoice summary) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InvoiceDetailScreen(
          apiClient: widget.apiClient,
          invoiceId: summary.id,
          tenantMode: widget.tenantMode,
          canCancel: widget.canCancel,
        ),
      ),
    );
    if (mounted) setState(_reload);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Invoice>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done)
          return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError)
          return ErrorView(
            message: snapshot.error.toString(),
            onRetry: () => setState(_reload),
          );
        final invoices = snapshot.data!;
        return RefreshIndicator(
          onRefresh: () async {
            setState(_reload);
            await _future;
          },
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            itemCount: invoices.length + (widget.tenantMode ? 0 : 1),
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              if (!widget.tenantMode && index == 0) {
                return FilledButton.icon(
                  onPressed: () async {
                    final changed = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            InvoiceFormScreen(apiClient: widget.apiClient),
                      ),
                    );
                    if (changed == true) setState(_reload);
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Tạo hóa đơn'),
                );
              }
              final invoice = invoices[index - (widget.tenantMode ? 0 : 1)];
              final color = _statusColor(invoice.status);
              return Card(
                child: ListTile(
                  onTap: () => _showDetails(invoice),
                  title: Text(
                    '${invoice.roomNumber} · ${invoice.month.toString().padLeft(2, '0')}/${invoice.year}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    '${invoice.tenantName}\nHạn: ${formatDate(invoice.dueDate)}',
                  ),
                  isThreeLine: true,
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        formatCurrency(invoice.totalAmount),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        invoice.status.toUpperCase(),
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
