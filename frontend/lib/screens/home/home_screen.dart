import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';
import '../invoices/invoice_list_screen.dart';
import '../payments/payment_list_screen.dart';
import '../utilities/utility_reading_list_screen.dart';
import '../../models/session_user.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.apiClient, required this.user, required this.onLogout});
  final ApiClient apiClient;
  final SessionUser user;
  final Future<void> Function() onLogout;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.user.role == 'tenant') {
      return Scaffold(
        appBar: AppBar(title: const Text('Hóa đơn của tôi', style: TextStyle(fontWeight: FontWeight.bold)), actions: [IconButton(onPressed: widget.onLogout, icon: const Icon(Icons.logout))]),
        body: InvoiceListScreen(apiClient: widget.apiClient, tenantMode: true),
      );
    }
    final pages = [
      UtilityReadingListScreen(apiClient: widget.apiClient, isManager: widget.user.role == 'manager'),
      InvoiceListScreen(apiClient: widget.apiClient, canCancel: widget.user.role == 'manager'),
      PaymentListScreen(apiClient: widget.apiClient),
    ];
    const titles = ['Điện nước', 'Hóa đơn', 'Thanh toán'];
    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_index], style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(onPressed: widget.onLogout, tooltip: 'Xóa token', icon: const Icon(Icons.logout_rounded)),
        ],
      ),
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.electric_meter_outlined), selectedIcon: Icon(Icons.electric_meter), label: 'Điện nước'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Hóa đơn'),
          NavigationDestination(icon: Icon(Icons.payments_outlined), selectedIcon: Icon(Icons.payments), label: 'Thanh toán'),
        ],
      ),
    );
  }
}
