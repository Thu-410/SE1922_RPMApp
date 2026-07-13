import 'package:flutter/material.dart';
import '../../core/helpers/formatters.dart';
import '../../core/network/api_client.dart';
import '../../models/invoice.dart';
import '../../services/invoice_service.dart';
import '../../widgets/error_view.dart';
import '../payments/payment_confirm_screen.dart';
import '../payments/online_checkout_screen.dart';
import 'invoice_form_screen.dart';

class InvoiceDetailScreen extends StatefulWidget {
  const InvoiceDetailScreen({
    super.key,
    required this.apiClient,
    required this.invoiceId,
    this.tenantMode = false,
    this.canCancel = false,
  });
  final ApiClient apiClient;
  final int invoiceId;
  final bool tenantMode;
  final bool canCancel;

  @override
  State<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen> {
  late final InvoiceService _service;
  late Future<Invoice> _future;

  @override
  void initState() {
    super.initState();
    _service = InvoiceService(widget.apiClient);
    _reload();
  }

  void _reload() => _future = widget.tenantMode
      ? _service.getMyInvoice(widget.invoiceId)
      : _service.getInvoice(widget.invoiceId);

  Future<void> _cancel() async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hủy hóa đơn'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Lý do',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Hủy hóa đơn'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (reason == null || reason.isEmpty) return;
    try {
      await _service.cancelInvoice(widget.invoiceId, reason);
      if (mounted) setState(_reload);
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết hóa đơn')),
      body: FutureBuilder<Invoice>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done)
            return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError)
            return ErrorView(
              message: snapshot.error.toString(),
              onRetry: () => setState(_reload),
            );
          final invoice = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                color: const Color(0xFFEFF6FF),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${invoice.roomNumber} · ${invoice.month.toString().padLeft(2, '0')}/${invoice.year}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(invoice.tenantName),
                      const SizedBox(height: 12),
                      Text(
                        formatCurrency(invoice.totalAmount),
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF2563EB),
                            ),
                      ),
                      Text(
                        'Trạng thái: ${invoice.status.toUpperCase()} · Hạn ${formatDate(invoice.dueDate)}',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Chi tiết các khoản',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              ...invoice.details.map(
                (item) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(item.name),
                  trailing: Text(formatCurrency(item.amount)),
                ),
              ),
              if (invoice.note?.isNotEmpty == true)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Text(invoice.note!),
                  ),
                ),
              if (!widget.tenantMode) ...[
                const SizedBox(height: 16),
                if (invoice.status == 'unpaid')
                  OutlinedButton.icon(
                    onPressed: () async {
                      final changed = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => InvoiceFormScreen(
                            apiClient: widget.apiClient,
                            invoice: invoice,
                          ),
                        ),
                      );
                      if (changed == true) setState(_reload);
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Sửa hóa đơn'),
                  ),
                if (invoice.status == 'unpaid' ||
                    invoice.status == 'overdue') ...[
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: () async {
                      final changed = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PaymentConfirmScreen(
                            apiClient: widget.apiClient,
                            invoice: invoice,
                          ),
                        ),
                      );
                      if (changed == true) setState(_reload);
                    },
                    icon: const Icon(Icons.payments),
                    label: const Text('Xác nhận thanh toán'),
                  ),
                  const SizedBox(height: 8),
                  if (widget.canCancel)
                    TextButton.icon(
                      onPressed: _cancel,
                      icon: const Icon(Icons.cancel_outlined),
                      label: const Text('Hủy hóa đơn'),
                    ),
                ],
              ] else if (invoice.status == 'unpaid' ||
                  invoice.status == 'overdue') ...[
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () async {
                    final changed = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => OnlineCheckoutScreen(
                          apiClient: widget.apiClient,
                          invoice: invoice,
                        ),
                      ),
                    );
                    if (changed == true) setState(_reload);
                  },
                  icon: const Icon(Icons.payment_rounded),
                  label: const Text('Thanh toán ngay'),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
