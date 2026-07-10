import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/network/api_client.dart';
import '../../models/room_option.dart';
import '../../models/utility_reading.dart';
import '../../services/utility_service.dart';

class UtilityReadingFormScreen extends StatefulWidget {
  const UtilityReadingFormScreen({super.key, required this.apiClient, this.reading});
  final ApiClient apiClient;
  final UtilityReading? reading;

  @override
  State<UtilityReadingFormScreen> createState() => _UtilityReadingFormScreenState();
}

class _UtilityReadingFormScreenState extends State<UtilityReadingFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final UtilityService _service;
  late final TextEditingController _oldElectric;
  late final TextEditingController _newElectric;
  late final TextEditingController _oldWater;
  late final TextEditingController _newWater;
  late final TextEditingController _note;
  List<RoomOption> _rooms = [];
  int? _roomId;
  late int _month;
  late int _year;
  bool _loading = true;
  bool _saving = false;

  bool get _editing => widget.reading != null;

  @override
  void initState() {
    super.initState();
    _service = UtilityService(widget.apiClient);
    final reading = widget.reading;
    final now = DateTime.now();
    _roomId = reading?.roomId;
    _month = reading?.month ?? now.month;
    _year = reading?.year ?? now.year;
    _oldElectric = TextEditingController(text: reading?.oldElectric.toString() ?? '');
    _newElectric = TextEditingController(text: reading?.newElectric.toString() ?? '');
    _oldWater = TextEditingController(text: reading?.oldWater.toString() ?? '');
    _newWater = TextEditingController(text: reading?.newWater.toString() ?? '');
    _note = TextEditingController(text: reading?.note ?? '');
    _loadRooms();
  }

  Future<void> _loadRooms() async {
    try {
      _rooms = await _service.getRoomOptions();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    for (final controller in [_oldElectric, _newElectric, _oldWater, _newWater, _note]) {
      controller.dispose();
    }
    super.dispose();
  }

  int? _optionalInt(TextEditingController controller) =>
      controller.text.trim().isEmpty ? null : int.tryParse(controller.text.trim());

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _roomId == null) return;
    setState(() => _saving = true);
    final body = <String, dynamic>{
      if (!_editing) ...{'roomId': _roomId, 'month': _month, 'year': _year},
      if (_optionalInt(_oldElectric) != null) 'oldElectric': _optionalInt(_oldElectric),
      'newElectric': int.parse(_newElectric.text),
      if (_optionalInt(_oldWater) != null) 'oldWater': _optionalInt(_oldWater),
      'newWater': int.parse(_newWater.text),
      'note': _note.text.trim(),
    };
    try {
      if (_editing) {
        await _service.updateReading(widget.reading!.id, body);
      } else {
        await _service.createReading(body);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _requiredNumber(String? value) {
    final number = int.tryParse(value ?? '');
    return number == null || number < 0 ? 'Nhập số nguyên không âm' : null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_editing ? 'Sửa chỉ số' : 'Ghi chỉ số mới')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  DropdownButtonFormField<int>(
                    initialValue: _roomId,
                    decoration: const InputDecoration(labelText: 'Phòng', border: OutlineInputBorder()),
                    items: _rooms.map((room) => DropdownMenuItem(value: room.id, child: Text('${room.roomNumber} · ${room.status}'))).toList(),
                    onChanged: _editing ? null : (value) => setState(() => _roomId = value),
                    validator: (value) => value == null ? 'Chọn phòng' : null,
                  ),
                  const SizedBox(height: 14),
                  Row(children: [
                    Expanded(child: DropdownButtonFormField<int>(initialValue: _month, decoration: const InputDecoration(labelText: 'Tháng', border: OutlineInputBorder()), items: List.generate(12, (i) => DropdownMenuItem(value: i + 1, child: Text('${i + 1}'))), onChanged: _editing ? null : (value) => setState(() => _month = value!))),
                    const SizedBox(width: 12),
                    Expanded(child: DropdownButtonFormField<int>(initialValue: _year, decoration: const InputDecoration(labelText: 'Năm', border: OutlineInputBorder()), items: List.generate(6, (i) => DropdownMenuItem(value: DateTime.now().year - 2 + i, child: Text('${DateTime.now().year - 2 + i}'))), onChanged: _editing ? null : (value) => setState(() => _year = value!))),
                  ]),
                  const SizedBox(height: 20),
                  Text('Điện', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: TextFormField(controller: _oldElectric, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], decoration: const InputDecoration(labelText: 'Chỉ số cũ', helperText: 'Để trống: lấy kỳ trước', border: OutlineInputBorder()))),
                    const SizedBox(width: 12),
                    Expanded(child: TextFormField(controller: _newElectric, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], validator: _requiredNumber, decoration: const InputDecoration(labelText: 'Chỉ số mới', border: OutlineInputBorder()))),
                  ]),
                  const SizedBox(height: 20),
                  Text('Nước', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: TextFormField(controller: _oldWater, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], decoration: const InputDecoration(labelText: 'Chỉ số cũ', helperText: 'Để trống: lấy kỳ trước', border: OutlineInputBorder()))),
                    const SizedBox(width: 12),
                    Expanded(child: TextFormField(controller: _newWater, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], validator: _requiredNumber, decoration: const InputDecoration(labelText: 'Chỉ số mới', border: OutlineInputBorder()))),
                  ]),
                  const SizedBox(height: 16),
                  TextFormField(controller: _note, maxLines: 3, decoration: const InputDecoration(labelText: 'Ghi chú', border: OutlineInputBorder())),
                  const SizedBox(height: 24),
                  FilledButton.icon(onPressed: _saving ? null : _save, icon: const Icon(Icons.save), label: Text(_saving ? 'Đang lưu...' : 'Lưu chỉ số')),
                ],
              ),
            ),
    );
  }
}
