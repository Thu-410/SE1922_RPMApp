import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';
import '../contracts/contract_list_screen.dart';
import 'tenant_list_screen.dart';

class TenantContractManagementScreen extends StatelessWidget {
  const TenantContractManagementScreen({
    super.key,
    required this.apiClient,
    required this.canManage,
  });
  final ApiClient apiClient;
  final bool canManage;
  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 2,
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Người thuê và hợp đồng'),
        bottom: const TabBar(
          tabs: [
            Tab(icon: Icon(Icons.people_outline), text: 'Người thuê'),
            Tab(icon: Icon(Icons.description_outlined), text: 'Hợp đồng'),
          ],
        ),
      ),
      body: TabBarView(
        children: [
          TenantListScreen(apiClient: apiClient, canManage: canManage),
          ContractListScreen(apiClient: apiClient, canManage: canManage),
        ],
      ),
    ),
  );
}
