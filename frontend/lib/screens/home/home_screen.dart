import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../models/session_user.dart';
import '../dashboard/dashboard_screen.dart';
import '../invoices/invoice_list_screen.dart';
import '../maintenance/maintenance_list_screen.dart';
import '../payments/payment_list_screen.dart';
import '../rooms/room_list_screen.dart';
import '../utilities/utility_reading_list_screen.dart';
import '../tenants/tenant_contract_management_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.apiClient,
    required this.user,
    required this.onLogout,
  });

  final ApiClient apiClient;
  final SessionUser user;
  final Future<void> Function() onLogout;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  void _openMaintenance() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Yêu cầu sửa chữa')),
          body: MaintenanceListScreen(
            apiClient: widget.apiClient,
            isTenant: false,
            isManager: widget.user.role == 'manager',
          ),
        ),
      ),
    );
  }

  void _openTenantContracts() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TenantContractManagementScreen(
          apiClient: widget.apiClient,
          canManage: widget.user.role == 'manager',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.user.role == 'tenant') return _buildTenantHome();
    return _buildManagementHome();
  }

  Widget _buildTenantHome() {
    final pages = [
      InvoiceListScreen(apiClient: widget.apiClient, tenantMode: true),
      MaintenanceListScreen(apiClient: widget.apiClient, isTenant: true),
    ];
    const titles = ['Hóa đơn của tôi', 'Yêu cầu sửa chữa'];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          titles[_index],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: widget.onLogout,
            tooltip: 'Đăng xuất',
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Hóa đơn',
          ),
          NavigationDestination(
            icon: Icon(Icons.build_outlined),
            selectedIcon: Icon(Icons.build),
            label: 'Sửa chữa',
          ),
        ],
      ),
    );
  }

  Widget _buildManagementHome() {
    final isManager = widget.user.role == 'manager';
    final pages = [
      DashboardScreen(apiClient: widget.apiClient),
      RoomListScreen(
        apiClient: widget.apiClient,
        canManage: isManager,
        showAppBar: false,
      ),
      UtilityReadingListScreen(
        apiClient: widget.apiClient,
        isManager: isManager,
      ),
      InvoiceListScreen(apiClient: widget.apiClient, canCancel: isManager),
      PaymentListScreen(apiClient: widget.apiClient),
    ];
    const titles = [
      'Tổng quan',
      'Quản lý phòng',
      'Điện nước',
      'Hóa đơn',
      'Thanh toán',
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          titles[_index],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: _openTenantContracts,
            tooltip: 'Người thuê và hợp đồng',
            icon: const Icon(Icons.people_alt_outlined),
          ),
          IconButton(
            onPressed: _openMaintenance,
            tooltip: 'Yêu cầu sửa chữa',
            icon: const Icon(Icons.build_outlined),
          ),
          IconButton(
            onPressed: widget.onLogout,
            tooltip: 'Đăng xuất',
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Tổng quan',
          ),
          NavigationDestination(
            icon: Icon(Icons.meeting_room_outlined),
            selectedIcon: Icon(Icons.meeting_room),
            label: 'Phòng',
          ),
          NavigationDestination(
            icon: Icon(Icons.electric_meter_outlined),
            selectedIcon: Icon(Icons.electric_meter),
            label: 'Điện nước',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Hóa đơn',
          ),
          NavigationDestination(
            icon: Icon(Icons.payments_outlined),
            selectedIcon: Icon(Icons.payments),
            label: 'Thanh toán',
          ),
        ],
      ),
    );
  }
}
