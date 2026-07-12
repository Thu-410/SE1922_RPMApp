import 'package:flutter/material.dart';
import '../../models/tenant_model.dart';
import '../../services/tenant_service.dart';
import 'edit_tenant_screen.dart';

class TenantDetailScreen extends StatefulWidget {
  final int tenantId;

  const TenantDetailScreen({super.key, required this.tenantId});

  @override
  State<TenantDetailScreen> createState() => _TenantDetailScreenState();
}

class _TenantDetailScreenState extends State<TenantDetailScreen> {
  final TenantService _tenantService = TenantService();
  late Future<Tenant> _futureTenant;

  @override
  void initState() {
    super.initState();
    _loadTenant();
  }

  void _loadTenant() {
    setState(() {
      _futureTenant = _tenantService.getTenantById(widget.tenantId);
    });
  }

  Future<void> _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xoa nguoi thue'),
        content: const Text('Ban co chac muon xoa nguoi thue nay khong?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Huy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xoa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _tenantService.deleteTenant(widget.tenantId);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Widget _infoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(child: Text(value?.isNotEmpty == true ? value! : '—')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiet nguoi thue'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final tenant = await _futureTenant;
              if (!mounted) return;
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditTenantScreen(tenant: tenant),
                ),
              );
              if (result == true) _loadTenant();
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _confirmDelete,
          ),
        ],
      ),
      body: FutureBuilder<Tenant>(
        future: _futureTenant,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Loi: ${snapshot.error}'));
          }

          final tenant = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 40,
                    child: Text(
                      tenant.fullName.isNotEmpty ? tenant.fullName[0] : '?',
                      style: const TextStyle(fontSize: 32),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    tenant.fullName,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                Center(
                  child: Chip(
                    label: Text(tenant.status == 'active' ? 'Dang thue' : 'Da roi di'),
                    backgroundColor: tenant.status == 'active'
                        ? Colors.green[100]
                        : Colors.grey[300],
                  ),
                ),
                const Divider(height: 32),
                _infoRow('So dien thoai', tenant.phone),
                _infoRow('Email', tenant.email),
                _infoRow('So CCCD', tenant.citizenId),
                _infoRow('Ngay sinh', tenant.dateOfBirth),
                _infoRow('Que quan', tenant.hometown),
                _infoRow('Dia chi', tenant.address),
                _infoRow('Phong dang thue', tenant.roomNumber),
                _infoRow('Nguoi dai dien', tenant.isRepresentative ? 'Co' : 'Khong'),
              ],
            ),
          );
        },
      ),
    );
  }
}