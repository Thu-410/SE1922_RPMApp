import 'package:flutter/material.dart';
import '../../models/tenant_model.dart';
import '../../services/tenant_service.dart';
import 'add_tenant_screen.dart';
import 'tenant_detail_screen.dart';

class TenantListScreen extends StatefulWidget {
  const TenantListScreen({super.key});

  @override
  State<TenantListScreen> createState() => _TenantListScreenState();
}

class _TenantListScreenState extends State<TenantListScreen> {
  final TenantService _tenantService = TenantService();
  late Future<List<Tenant>> _futureTenants;

  @override
  void initState() {
    super.initState();
    _loadTenants();
  }

  void _loadTenants() {
    setState(() {
      _futureTenants = _tenantService.getAllTenants();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Danh sach nguoi thue')),
      body: FutureBuilder<List<Tenant>>(
        future: _futureTenants,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Loi: ${snapshot.error}'));
          }
          final tenants = snapshot.data ?? [];
          if (tenants.isEmpty) {
            return const Center(child: Text('Chua co nguoi thue nao'));
          }
          return RefreshIndicator(
            onRefresh: () async => _loadTenants(),
            child: ListView.builder(
              itemCount: tenants.length,
              itemBuilder: (context, index) {
                final tenant = tenants[index];
                return ListTile(
                  leading: CircleAvatar(child: Text(tenant.fullName[0])),
                  title: Text(tenant.fullName),
                  subtitle: Text(
                    '${tenant.phone} • ${tenant.roomNumber ?? "Chua co phong"}',
                  ),
                  trailing: Chip(
                    label: Text(
                      tenant.status == 'active' ? 'Dang thue' : 'Da roi',
                    ),
                    backgroundColor: tenant.status == 'active'
                        ? Colors.green[100]
                        : Colors.grey[300],
                  ),

                  // TODO: điều hướng sang TenantDetailScreen
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            TenantDetailScreen(tenantId: tenant.id),
                      ),
                    );
                    if (result == true) {
                      _loadTenants(); //? reload list nếu có sửa/xóa
                    }
                  },
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddTenantScreen()),
          );
          if (result == true) _loadTenants();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
