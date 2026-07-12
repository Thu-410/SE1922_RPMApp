import 'package:flutter/material.dart';
import '../../models/contract_model.dart';
import '../../services/contract_service.dart';
import 'create_contract_screen.dart';
import 'contract_detail_screen.dart';

class ContractListScreen extends StatefulWidget {
  const ContractListScreen({super.key});

  @override
  State<ContractListScreen> createState() => _ContractListScreenState();
}

class _ContractListScreenState extends State<ContractListScreen> {
  final ContractService _contractService = ContractService();
  late Future<List<Contract>> _futureContracts;

  @override
  void initState() {
    super.initState();
    _loadContracts();
  }

  void _loadContracts() {
    setState(() {
      _futureContracts = _contractService.getAllContracts();
    });
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'expired':
        return Colors.grey;
      case 'terminated':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'active':
        return 'Dang hieu luc';
      case 'pending':
        return 'Cho bat dau';
      case 'expired':
        return 'Het han';
      case 'terminated':
        return 'Da ket thuc';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Danh sach hop dong')),
      body: FutureBuilder<List<Contract>>(
        future: _futureContracts,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Loi: ${snapshot.error}'));
          }
          final contracts = snapshot.data ?? [];
          if (contracts.isEmpty) {
            return const Center(child: Text('Chua co hop dong nao'));
          }
          return RefreshIndicator(
            onRefresh: () async => _loadContracts(),
            child: ListView.builder(
              itemCount: contracts.length,
              itemBuilder: (context, index) {
                final c = contracts[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    title: Text('Phong ${c.roomNumber ?? c.roomId} - ${c.tenantName ?? ""}'),
                    subtitle: Text('${c.startDate} → ${c.endDate}'),
                    trailing: Chip(
                      label: Text(
                        _statusLabel(c.status),
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                      backgroundColor: _statusColor(c.status),
                    ),
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ContractDetailScreen(contractId: c.id),
                        ),
                      );
                      if (result == true) _loadContracts();
                    },
                  ),
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
            MaterialPageRoute(builder: (context) => const CreateContractScreen()),
          );
          if (result == true) _loadContracts();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}