import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/helpers/formatters.dart';
import '../../core/network/api_client.dart';
import '../../models/invoice.dart';
import '../../services/invoice_service.dart';
import '../../services/payment_service.dart';

class OnlineCheckoutScreen extends StatefulWidget {
  const OnlineCheckoutScreen({
    super.key,
    required this.apiClient,
    required this.invoice,
  });

  final ApiClient apiClient;
  final Invoice invoice;

  @override
  State<OnlineCheckoutScreen> createState() => _OnlineCheckoutScreenState();
}

class _OnlineCheckoutScreenState extends State<OnlineCheckoutScreen>
    with WidgetsBindingObserver {
  String? _openingProvider;
  bool _checking = false;
  bool _openedGateway = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _openedGateway) _checkPayment();
  }

  Future<void> _pay(String provider) async {
    setState(() => _openingProvider = provider);
    try {
      final uri = await PaymentService(
        widget.apiClient,
      ).createOnlineCheckout(widget.invoice.id, provider);
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened) {
        throw Exception('Không thể mở ứng dụng hoặc trình duyệt thanh toán');
      }
      _openedGateway = true;
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) {
        setState(() => _openingProvider = null);
      }
    }
  }

  Future<void> _checkPayment() async {
    if (_checking) return;
    setState(() => _checking = true);
    try {
      final invoice = await InvoiceService(
        widget.apiClient,
      ).getMyInvoice(widget.invoice.id);
      if (!mounted) return;
      if (invoice.status == 'paid') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thanh toán đã được xác nhận thành công'),
          ),
        );
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Giao dịch chưa được cổng thanh toán xác nhận. Hãy thử lại sau.',
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) {
        setState(() => _checking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thanh toán hóa đơn')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: const Color(0xFFEFF6FF),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    '${widget.invoice.roomNumber} · ${widget.invoice.month}/${widget.invoice.year}',
                  ),
                  const SizedBox(height: 8),
                  Text(
                    formatCurrency(widget.invoice.totalAmount),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2563EB),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Chọn cổng thanh toán',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          _providerTile(
            'momo',
            'Ví MoMo',
            Icons.account_balance_wallet_rounded,
            const Color(0xFFA50064),
          ),
          _providerTile(
            'vnpay',
            'VNPay',
            Icons.qr_code_2_rounded,
            const Color(0xFF005BAA),
          ),
          _providerTile(
            'paypal',
            'PayPal',
            Icons.paypal_rounded,
            const Color(0xFF003087),
            subtitle: 'Số tiền được quy đổi từ VND sang USD theo cấu hình',
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: _checking ? null : _checkPayment,
            icon: _checking
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            label: const Text('Kiểm tra trạng thái thanh toán'),
          ),
          const SizedBox(height: 12),
          const Text(
            'Hóa đơn chỉ chuyển sang PAID sau khi backend xác minh phản hồi bảo mật từ cổng thanh toán.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _providerTile(
    String provider,
    String title,
    IconData icon,
    Color color, {
    String? subtitle,
  }) {
    final loading = _openingProvider == provider;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: subtitle == null ? null : Text(subtitle),
        trailing: loading
            ? const SizedBox.square(
                dimension: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.chevron_right),
        onTap: _openingProvider == null ? () => _pay(provider) : null,
      ),
    );
  }
}
