import 'package:flutter/material.dart';
import '../../core/helpers/formatters.dart';
import '../../core/network/api_client.dart';
import '../../models/invoice.dart';
import '../../services/payment_service.dart';

class PaymentConfirmScreen extends StatefulWidget {
  const PaymentConfirmScreen({super.key, required this.apiClient, required this.invoice});
  final ApiClient apiClient;
  final Invoice invoice;

  @override
  State<PaymentConfirmScreen> createState() => _PaymentConfirmScreenState();
}

class _PaymentConfirmScreenState extends State<PaymentConfirmScreen> {
  late final PaymentService _service;
  final _transactionCode = TextEditingController();
  final _note = TextEditingController();
  String _method = 'cash';
  bool _saving = false;

  @override
  void initState() { super.initState(); _service = PaymentService(widget.apiClient); }

  @override
  void dispose() { _transactionCode.dispose(); _note.dispose(); super.dispose(); }

  Future<void> _confirm() async {
    setState(() => _saving = true);
    try {
      await _service.confirmPayment(widget.invoice.id, {
        'amount': widget.invoice.totalAmount,
        'paymentMethod': _method,
        if (_transactionCode.text.trim().isNotEmpty) 'transactionCode': _transactionCode.text.trim(),
        'note': _note.text.trim(),
      });
      if (mounted) Navigator.pop(context, true);
    } catch (error) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString()))); }
    finally { if (mounted) setState(() => _saving = false); }
  }

  @override
  Widget build(BuildContext context) {
    const methods = {'cash': 'Tiền mặt', 'bank_transfer': 'Chuyển khoản', 'qr_code': 'QR Code', 'momo': 'MoMo', 'other': 'Khác'};
    return Scaffold(
      appBar: AppBar(title: const Text('Xác nhận thanh toán')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Card(color: const Color(0xFFEFF6FF), child: Padding(padding: const EdgeInsets.all(20), child: Column(children: [
          Text('${widget.invoice.roomNumber} · ${widget.invoice.month}/${widget.invoice.year}', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(formatCurrency(widget.invoice.totalAmount), style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: const Color(0xFF2563EB))),
        ]))),
        const SizedBox(height: 18),
        DropdownButtonFormField<String>(initialValue: _method, decoration: const InputDecoration(labelText: 'Phương thức', border: OutlineInputBorder()), items: methods.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(), onChanged: (value) => setState(() => _method = value!)),
        const SizedBox(height: 14),
        TextField(controller: _transactionCode, decoration: const InputDecoration(labelText: 'Mã giao dịch', border: OutlineInputBorder())),
        const SizedBox(height: 14),
        TextField(controller: _note, maxLines: 3, decoration: const InputDecoration(labelText: 'Ghi chú', border: OutlineInputBorder())),
        const SizedBox(height: 24),
        FilledButton.icon(onPressed: _saving ? null : _confirm, icon: const Icon(Icons.verified), label: Text(_saving ? 'Đang xác nhận...' : 'Xác nhận đã thanh toán')),
      ]),
    );
  }
}
