import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../models/tenant.dart';
import '../../services/tenant_service.dart';
import 'tenant_detail_screen.dart';
import 'tenant_form_screen.dart';

class TenantListScreen extends StatefulWidget {
  const TenantListScreen({
    super.key,
    required this.apiClient,
    required this.canManage,
  });
  final ApiClient apiClient;
  final bool canManage;
  @override
  State<TenantListScreen> createState() => _TenantListScreenState();
}

class _TenantListScreenState extends State<TenantListScreen> {
  late final TenantService _service;
  late Future<List<Tenant>> _future;
  String _status = '';
  @override
  void initState() {
    super.initState();
    _service = TenantService(widget.apiClient);
    _future = _service.list();
  }

  void _reload() {
    setState(() {
      _future = _service.list(status: _status);
    });
  }

  Future<void> _add() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TenantFormScreen(apiClient: widget.apiClient),
      ),
    );
    if (result != null) _reload();
  }

  Future<void> _open(Tenant tenant) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TenantDetailScreen(
          apiClient: widget.apiClient,
          tenantId: tenant.id,
          canManage: widget.canManage,
        ),
      ),
    );
    if (mounted) _reload();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    floatingActionButton: widget.canManage
        ? FloatingActionButton(
            onPressed: _add,
            child: const Icon(Icons.person_add_outlined),
          )
        : null,
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: DropdownButtonFormField<String>(
            initialValue: _status,
            decoration: const InputDecoration(labelText: 'Lọc người thuê'),
            items: const [
              DropdownMenuItem(value: '', child: Text('Tất cả')),
              DropdownMenuItem(value: 'active', child: Text('Đang thuê')),
              DropdownMenuItem(value: 'left', child: Text('Đã rời đi')),
            ],
            onChanged: (value) {
              _status = value ?? '';
              _reload();
            },
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Tenant>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done)
                return const Center(child: CircularProgressIndicator());
              if (snapshot.hasError)
                return Center(child: Text('${snapshot.error}'));
              final items = snapshot.data!;
              if (items.isEmpty)
                return const Center(child: Text('Chưa có người thuê'));
              return RefreshIndicator(
                onRefresh: () async {
                  _reload();
                  await _future;
                },
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 90),
                  itemCount: items.length,
                  itemBuilder: (_, index) {
                    final tenant = items[index];
                    return Card(
                      child: ListTile(
                        onTap: () => _open(tenant),
                        leading: CircleAvatar(
                          child: Text(
                            tenant.fullName.isEmpty
                                ? '?'
                                : tenant.fullName[0].toUpperCase(),
                          ),
                        ),
                        title: Text(
                          tenant.fullName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${tenant.phone}\n${tenant.roomNumber == null ? 'Chưa gán phòng' : 'Phòng ${tenant.roomNumber}'}',
                        ),
                        isThreeLine: true,
                        trailing: Text(
                          tenant.status == 'active' ? 'Đang thuê' : 'Đã rời',
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    ),
  );
}
