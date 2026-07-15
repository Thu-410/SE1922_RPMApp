import 'package:flutter/material.dart';
import '../../core/helpers/formatters.dart';
import '../../core/network/api_client.dart';
import '../../models/contract.dart';
import '../../services/contract_service.dart';

class ContractDetailScreen extends StatefulWidget {
  const ContractDetailScreen({
    super.key,
    required this.apiClient,
    required this.contractId,
    required this.canManage,
  });
  final ApiClient apiClient;
  final int contractId;
  final bool canManage;
  @override
  State<ContractDetailScreen> createState() => _ContractDetailScreenState();
}

class _ContractDetailScreenState extends State<ContractDetailScreen> {
  late final ContractService _service;
  late Future<RentalContract> _future;
  @override
  void initState() {
    super.initState();
    _service = ContractService(widget.apiClient);
    _future = _service.detail(widget.contractId);
  }

  void _reload() {
    setState(() {
      _future = _service.detail(widget.contractId);
    });
  }

  Future<void> _extend(RentalContract c) async {
    final initial =
        DateTime.tryParse(c.endDate)?.add(const Duration(days: 1)) ??
        DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: initial,
      lastDate: DateTime(2045),
    );
    if (d == null) return;
    try {
      await _service.extend(
        c.id,
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}',
      );
      _reload();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _terminate(RentalContract c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (x) => AlertDialog(
        title: const Text('Kết thúc hợp đồng?'),
        content: const Text('Phòng và người thuê sẽ được cập nhật tự động.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(x, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(x, true),
            child: const Text('Kết thúc'),
          ),
        ],
      ),
    );
    if (ok == true) {
      try {
        await _service.terminate(c.id);
        _reload();
      } catch (e) {
        if (mounted)
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _activate(RentalContract contract) async {
    try {
      await _service.activate(contract.id);
      _reload();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<RentalContract>(
    future: _future,
    builder: (context, s) {
      final c = s.data;
      return Scaffold(
        appBar: AppBar(
          title: Text(c == null ? 'Chi tiết hợp đồng' : 'Hợp đồng #${c.id}'),
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
                          _row('Người thuê', c!.tenantName ?? '#${c.tenantId}'),
                          _row('Điện thoại', c.tenantPhone ?? '—'),
                          _row('Phòng', c.roomNumber ?? '#${c.roomId}'),
                          _row('Từ ngày', c.startDate),
                          _row('Đến ngày', c.endDate),
                          _row('Giá tháng', formatCurrency(c.monthlyPrice)),
                          _row('Tiền cọc', formatCurrency(c.depositAmount)),
                          _row('Trạng thái', contractStatusLabel(c.status)),
                          if (c.note?.isNotEmpty == true)
                            _row('Ghi chú', c.note!),
                        ],
                      ),
                    ),
                  ),
            if (widget.canManage && c.status == 'pending') ...[
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => _activate(c),
                icon: const Icon(Icons.play_circle_outline),
                label: const Text('Kích hoạt hợp đồng'),
              ),
            ],
            if (widget.canManage && c.status == 'active') ...[
                    const SizedBox(height: 12),
                    FilledButton.tonalIcon(
                      onPressed: () => _extend(c),
                      icon: const Icon(Icons.event_repeat),
                      label: const Text('Gia hạn hợp đồng'),
                    ),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      onPressed: () => _terminate(c),
                      icon: const Icon(Icons.stop_circle_outlined),
                      label: const Text('Kết thúc hợp đồng'),
                    ),
                  ],
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
