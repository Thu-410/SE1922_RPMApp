import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';
import '../../models/tenant.dart';
import '../../services/tenant_service.dart';
import '../contracts/contract_list_screen.dart';
import 'tenant_form_screen.dart';

class TenantDetailScreen extends StatefulWidget {
  const TenantDetailScreen({
    super.key,
    required this.apiClient,
    required this.tenantId,
    required this.canManage,
  });
  final ApiClient apiClient;
  final int tenantId;
  final bool canManage;
  @override
  State<TenantDetailScreen> createState() => _TenantDetailScreenState();
}

class _TenantDetailScreenState extends State<TenantDetailScreen> {
  late final TenantService _service;
  late Future<Tenant> _future;
  @override
  void initState() {
    super.initState();
    _service = TenantService(widget.apiClient);
    _future = _service.detail(widget.tenantId);
  }

  void _reload() {
    setState(() {
      _future = _service.detail(widget.tenantId);
    });
  }

  Future<void> _edit(Tenant t) async {
    final x = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            TenantFormScreen(apiClient: widget.apiClient, tenant: t),
      ),
    );
    if (x != null) _reload();
  }

  Future<void> _remove(Tenant t) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Cho người thuê rời đi?'),
        content: const Text(
          'Người thuê sẽ được gỡ khỏi phòng và chuyển sang trạng thái đã rời đi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
    if (ok == true) {
      try {
        await _service.remove(t.id);
        _reload();
      } catch (e) {
        if (mounted)
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Tenant>(
    future: _future,
    builder: (context, s) {
      final t = s.data;
      return Scaffold(
        appBar: AppBar(
          title: Text(t?.fullName ?? 'Chi tiết người thuê'),
          actions: t != null && widget.canManage
              ? [
                  IconButton(
                    onPressed: () => _edit(t),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  IconButton(
                    onPressed: () => _remove(t),
                    icon: const Icon(Icons.person_remove_outlined),
                  ),
                ]
              : null,
        ),
        body: s.connectionState != ConnectionState.done
            ? const Center(child: CircularProgressIndicator())
            : s.hasError
            ? Center(child: Text('${s.error}'))
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _row('Họ tên', t!.fullName),
                          _row('Điện thoại', t.phone),
                          _row('Email', t.email ?? '—'),
                          _row('CCCD', t.citizenId ?? '—'),
                          _row('Ngày sinh', t.dateOfBirth ?? '—'),
                          _row('Phòng', t.roomNumber ?? 'Chưa gán'),
                          _row(
                            'Trạng thái',
                            t.status == 'active' ? 'Đang thuê' : 'Đã rời đi',
                          ),
                          _row('Đại diện', t.isRepresentative ? 'Có' : 'Không'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.tonalIcon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ContractListScreen(
                          apiClient: widget.apiClient,
                          canManage: widget.canManage,
                          tenantId: t.id,
                          showAppBar: true,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.description_outlined),
                    label: const Text('Xem hợp đồng'),
                  ),
                ],
              ),
      );
    },
  );
  Widget _row(String a, String b) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(a),
        Flexible(
          child: Text(
            b,
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}
