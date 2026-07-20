import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';
import '../../models/room.dart';
import '../../models/tenant.dart';
import '../../services/room_service.dart';
import '../../services/tenant_service.dart';

class TenantFormScreen extends StatefulWidget {
  const TenantFormScreen({super.key, required this.apiClient, this.tenant});
  final ApiClient apiClient;
  final Tenant? tenant;
  @override
  State<TenantFormScreen> createState() => _TenantFormScreenState();
}

class _TenantFormScreenState extends State<TenantFormScreen> {
  final _key = GlobalKey<FormState>();
  late final TenantService _service;
  late final Map<String, TextEditingController> _c;
  late Future<List<Room>> _rooms;
  int? _roomId;
  bool _representative = false, _saving = false;
  String _status = 'active';
  @override
  void initState() {
    super.initState();
    final t = widget.tenant;
    _service = TenantService(widget.apiClient);
    _roomId = t?.roomId;
    _representative = t?.isRepresentative ?? false;
    _status = t?.status ?? 'active';
    _c = {
      'full_name': TextEditingController(text: t?.fullName),
      'phone': TextEditingController(text: t?.phone),
      'email': TextEditingController(text: t?.email),
      'citizen_id': TextEditingController(text: t?.citizenId),
      'date_of_birth': TextEditingController(text: t?.dateOfBirth),
      'hometown': TextEditingController(text: t?.hometown),
      'address': TextEditingController(text: t?.address),
    };
    _rooms = RoomService(widget.apiClient).list();
  }

  @override
  void dispose() {
    for (final x in _c.values) {
      x.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate() async {
    final initial =
        DateTime.tryParse(_c['date_of_birth']!.text) ?? DateTime(2000);
    final value = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
    );
    if (value != null) {
      _c['date_of_birth']!.text = _date(value);
    }
  }

  String _date(DateTime value) =>
      '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
  Future<void> _save() async {
    if (!_key.currentState!.validate()) return;
    setState(() => _saving = true);
    final body = {
      for (final e in _c.entries) e.key: e.value.text.trim(),
      'room_id': _roomId,
      'is_representative': _representative,
      'status': _status,
    };
    try {
      final result = widget.tenant == null
          ? await _service.create(body)
          : await _service.update(widget.tenant!.id, body);
      if (mounted) Navigator.pop(context, result);
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
    appBar: AppBar(
      title: Text(widget.tenant == null ? 'Thêm người thuê' : 'Sửa người thuê'),
    ),
    body: Form(
      key: _key,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _field('full_name', 'Họ và tên *', required: true),
          _field(
            'phone',
            'Số điện thoại *',
            required: true,
            type: TextInputType.phone,
          ),
          _field('email', 'Email', type: TextInputType.emailAddress),
          _field('citizen_id', 'Số CCCD'),
          TextFormField(
            controller: _c['date_of_birth'],
            readOnly: true,
            onTap: _pickDate,
            decoration: const InputDecoration(
              labelText: 'Ngày sinh',
              suffixIcon: Icon(Icons.calendar_today_outlined),
            ),
          ),
          const SizedBox(height: 12),
          _field('hometown', 'Quê quán'),
          _field('address', 'Địa chỉ'),
          FutureBuilder<List<Room>>(
            future: _rooms,
            builder: (context, s) {
              if (!s.hasData) return const LinearProgressIndicator();
              final rooms = s.data!
                  .where(
                    (r) =>
                        !['maintenance', 'inactive'].contains(r.status) ||
                        r.id == _roomId,
                  )
                  .toList();
              return DropdownButtonFormField<int?>(
                initialValue: _roomId,
                decoration: const InputDecoration(labelText: 'Gán vào phòng'),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('Chưa gán phòng'),
                  ),
                  ...rooms.map(
                    (r) => DropdownMenuItem(
                      value: r.id,
                      child: Text('Phòng ${r.roomNumber}'),
                    ),
                  ),
                ],
                onChanged: (v) => _roomId = v,
              );
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _status,
            decoration: const InputDecoration(labelText: 'Trạng thái'),
            items: const [
              DropdownMenuItem(value: 'active', child: Text('Đang thuê')),
              DropdownMenuItem(value: 'left', child: Text('Đã rời đi')),
            ],
            onChanged: (v) => _status = v!,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Người đại diện phòng'),
            value: _representative,
            onChanged: (v) => setState(() => _representative = v),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: const Icon(Icons.save_outlined),
            label: Text(_saving ? 'Đang lưu...' : 'Lưu người thuê'),
          ),
        ],
      ),
    ),
  );
  Widget _field(
    String key,
    String label, {
    bool required = false,
    TextInputType? type,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: _c[key],
      keyboardType: type,
      decoration: InputDecoration(labelText: label),
      validator: required
          ? (v) => v == null || v.trim().isEmpty ? 'Không được để trống' : null
          : null,
    ),
  );
}
