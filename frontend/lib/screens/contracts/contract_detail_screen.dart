import 'package:flutter/material.dart';
import '../../models/contract_model.dart';
import '../../services/contract_service.dart';

class ContractDetailScreen extends StatefulWidget {
  final int contractId;

  const ContractDetailScreen({super.key, required this.contractId});

  @override
  State<ContractDetailScreen> createState() => _ContractDetailScreenState();
}

class _ContractDetailScreenState extends State<ContractDetailScreen> {
  final ContractService _contractService = ContractService();
  late Future<Contract> _futureContract;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadContract();
  }

  void _loadContract() {
    setState(() {
      _futureContract = _contractService.getContractById(widget.contractId);
    });
  }

  Future<void> _handleExtend() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2035),
    );
    if (picked == null) return;

    final newEndDate =
        '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';

    setState(() => _isProcessing = true);
    try {
      await _contractService.extendContract(widget.contractId, newEndDate);
      _loadContract();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleTerminate() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ket thuc hop dong'),
        content: const Text(
          'Phong se chuyen ve trang thai trong, nguoi thue se chuyen sang da roi di. Ban co chac chan?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Huy')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xac nhan', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _isProcessing = true);
    try {
      await _contractService.terminateContract(widget.contractId);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 130, child: Text(label, style: const TextStyle(color: Colors.grey))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiet hop dong')),
      body: FutureBuilder<Contract>(
        future: _futureContract,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Loi: ${snapshot.error}'));
          }

          final c = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: [
                _infoRow('Phong', c.roomNumber ?? c.roomId.toString()),
                _infoRow('Nguoi thue', c.tenantName ?? c.tenantId.toString()),
                _infoRow('SDT', c.tenantPhone ?? '—'),
                _infoRow('Ngay bat dau', c.startDate),
                _infoRow('Ngay ket thuc', c.endDate),
                _infoRow('Gia thue', '${c.monthlyPrice.toStringAsFixed(0)} d/thang'),
                _infoRow('Tien coc', c.depositAmount.toStringAsFixed(0)),
                _infoRow('Trang thai', c.status),
                if (c.note != null) _infoRow('Ghi chu', c.note!),
                if (c.terminatedAt != null) _infoRow('Ngay ket thuc thuc te', c.terminatedAt!),

                const SizedBox(height: 24),
                if (c.status == 'active') ...[
                  ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _handleExtend,
                    icon: const Icon(Icons.calendar_today),
                    label: const Text('Gia han hop dong'),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _handleTerminate,
                    icon: const Icon(Icons.cancel),
                    label: const Text('Ket thuc hop dong'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}