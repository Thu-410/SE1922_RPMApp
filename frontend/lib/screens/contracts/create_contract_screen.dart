import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';
import '../../models/room.dart';
import '../../models/tenant.dart';
import '../../services/contract_service.dart';
import '../../services/room_service.dart';
import '../../services/tenant_service.dart';

class CreateContractScreen extends StatefulWidget {
  const CreateContractScreen({
    super.key,
    required this.apiClient,
    this.initialTenantId,
  });
  final ApiClient apiClient;
  final int? initialTenantId;
  @override
  State<CreateContractScreen> createState() => _CreateContractScreenState();
}

class _CreateContractScreenState extends State<CreateContractScreen> {
  final _key = GlobalKey<FormState>();
  final _price = TextEditingController(),
      _deposit = TextEditingController(text: '0'),
      _note = TextEditingController();
  late Future<List<dynamic>> _options;
  int? _roomId, _tenantId;
  DateTime? _start, _end;
  String _status = 'active';
  bool _saving = false;
  @override
  void initState() {
    super.initState();
    _tenantId = widget.initialTenantId;
    _options = Future.wait([
      RoomService(widget.apiClient).list(),
      TenantService(widget.apiClient).list(),
    ]);
  }

  @override
  void dispose() {
    _price.dispose();
    _deposit.dispose();
    _note.dispose();
    super.dispose();
  }

  String _date(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  Future<void> _pick(bool start) async {
    final v = await showDatePicker(
      context: context,
      initialDate: start
          ? (_start ?? DateTime.now())
          : (_end ?? DateTime.now().add(const Duration(days: 365))),
      firstDate: DateTime(2020),
      lastDate: DateTime(2045),
    );
    if (v != null)
      setState(() {
        if (start) {
          _start = v;
        } else {
          _end = v;
        }
      });
  }

  Future<void> _save() async {
    if (!_key.currentState!.validate() ||
        _roomId == null ||
        _tenantId == null ||
        _start == null ||
        _end == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn đủ phòng, người thuê và thời hạn'),
        ),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final x = await ContractService(widget.apiClient).create({
        'room_id': _roomId,
        'tenant_id': _tenantId,
        'start_date': _date(_start!),
        'end_date': _date(_end!),
        'monthly_price': double.parse(_price.text),
        'deposit_amount': double.tryParse(_deposit.text) ?? 0,
        'status': _status,
        'note': _note.text.trim(),
      });
      if (mounted) Navigator.pop(context, x);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Tạo hợp đồng')),
    body: Form(
      key: _key,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          FutureBuilder<List<dynamic>>(
            future: _options,
            builder: (context, s) {
              if (!s.hasData) return const LinearProgressIndicator();
              final rooms = (s.data![0] as List<Room>).where(
                (r) => !['maintenance', 'inactive'].contains(r.status),
              );
              final tenants = s.data![1] as List<Tenant>;
              return Column(
                children: [
                  DropdownButtonFormField<int>(
                    initialValue: _roomId,
                    decoration: const InputDecoration(labelText: 'Phòng *'),
                    items: rooms
                        .map(
                          (r) => DropdownMenuItem(
                            value: r.id,
                            child: Text(
                              'Phòng ${r.roomNumber} · ${r.price.toStringAsFixed(0)}đ',
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _roomId = v),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    initialValue: _tenantId,
                    decoration: const InputDecoration(
                      labelText: 'Người thuê *',
                    ),
                    items: tenants
                        .map(
                          (t) => DropdownMenuItem(
                            value: t.id,
                            child: Text('${t.fullName} · ${t.phone}'),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _tenantId = v),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    _start == null ? 'Ngày bắt đầu *' : _date(_start!),
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () => _pick(true),
                ),
              ),
              Expanded(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(_end == null ? 'Ngày kết thúc *' : _date(_end!)),
                  trailing: const Icon(Icons.event),
                  onTap: () => _pick(false),
                ),
              ),
            ],
          ),
          TextFormField(
            controller: _price,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Giá thuê/tháng *'),
            validator: _number,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _deposit,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Tiền cọc'),
            validator: _number,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _status,
            decoration: const InputDecoration(labelText: 'Trạng thái'),
            items: const [
              DropdownMenuItem(
                value: 'active',
                child: Text('Có hiệu lực ngay'),
              ),
              DropdownMenuItem(value: 'pending', child: Text('Chờ hiệu lực')),
            ],
            onChanged: (v) => _status = v!,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _note,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Ghi chú'),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: const Icon(Icons.description_outlined),
            label: Text(_saving ? 'Đang tạo...' : 'Tạo hợp đồng'),
          ),
        ],
      ),
    ),
  );
  String? _number(String? v) {
    final n = double.tryParse(v ?? '');
    return n == null || n < 0 ? 'Nhập số không âm hợp lệ' : null;
  }
}
