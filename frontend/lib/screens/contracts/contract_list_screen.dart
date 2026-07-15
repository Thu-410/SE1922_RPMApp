import 'package:flutter/material.dart';

import '../../core/helpers/formatters.dart';
import '../../core/network/api_client.dart';
import '../../models/contract.dart';
import '../../services/contract_service.dart';
import 'contract_detail_screen.dart';
import 'create_contract_screen.dart';

class ContractListScreen extends StatefulWidget {
  const ContractListScreen({
    super.key,
    required this.apiClient,
    required this.canManage,
    this.tenantId,
    this.showAppBar = false,
  });
  final ApiClient apiClient;
  final bool canManage, showAppBar;
  final int? tenantId;
  @override
  State<ContractListScreen> createState() => _ContractListScreenState();
}

class _ContractListScreenState extends State<ContractListScreen> {
  late final ContractService _service;
  late Future<List<RentalContract>> _future;
  String _status = '';
  @override
  void initState() {
    super.initState();
    _service = ContractService(widget.apiClient);
    _future = _service.list(tenantId: widget.tenantId);
  }

  void _reload() {
    setState(() {
      _future = _service.list(status: _status, tenantId: widget.tenantId);
    });
  }

  Future<void> _add() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateContractScreen(
          apiClient: widget.apiClient,
          initialTenantId: widget.tenantId,
        ),
      ),
    );
    if (result != null) _reload();
  }

  Future<void> _open(RentalContract contract) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ContractDetailScreen(
          apiClient: widget.apiClient,
          contractId: contract.id,
          canManage: widget.canManage,
        ),
      ),
    );
    if (mounted) _reload();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: widget.showAppBar ? AppBar(title: const Text('Hợp đồng')) : null,
    floatingActionButton: widget.canManage
        ? FloatingActionButton(
            onPressed: _add,
            child: const Icon(Icons.note_add_outlined),
          )
        : null,
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: DropdownButtonFormField<String>(
            initialValue: _status,
            decoration: const InputDecoration(labelText: 'Lọc hợp đồng'),
            items: const [
              DropdownMenuItem(value: '', child: Text('Tất cả')),
              DropdownMenuItem(value: 'active', child: Text('Đang hoạt động')),
              DropdownMenuItem(value: 'pending', child: Text('Chờ hiệu lực')),
              DropdownMenuItem(value: 'expired', child: Text('Hết hạn')),
              DropdownMenuItem(value: 'terminated', child: Text('Đã kết thúc')),
            ],
            onChanged: (value) {
              _status = value ?? '';
              _reload();
            },
          ),
        ),
        Expanded(
          child: FutureBuilder<List<RentalContract>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done)
                return const Center(child: CircularProgressIndicator());
              if (snapshot.hasError)
                return Center(child: Text('${snapshot.error}'));
              final items = snapshot.data!;
              if (items.isEmpty)
                return const Center(child: Text('Chưa có hợp đồng'));
              return RefreshIndicator(
                onRefresh: () async {
                  _reload();
                  await _future;
                },
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 90),
                  itemCount: items.length,
                  itemBuilder: (_, index) {
                    final contract = items[index];
                    return Card(
                      child: ListTile(
                        onTap: () => _open(contract),
                        leading: const CircleAvatar(
                          child: Icon(Icons.description_outlined),
                        ),
                        title: Text(
                          '${contract.tenantName ?? 'Người thuê'} · Phòng ${contract.roomNumber ?? contract.roomId}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${contract.startDate} → ${contract.endDate}\n${contractStatusLabel(contract.status)}',
                        ),
                        isThreeLine: true,
                        trailing: Text(formatCurrency(contract.monthlyPrice)),
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
