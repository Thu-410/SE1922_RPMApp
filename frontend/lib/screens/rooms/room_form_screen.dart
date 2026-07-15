import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/room.dart';
import '../../services/room_service.dart';

class RoomFormScreen extends StatefulWidget {
  const RoomFormScreen({super.key, required this.service, this.room});
  final RoomService service;
  final Room? room;

  @override
  State<RoomFormScreen> createState() => _RoomFormScreenState();
}

class _RoomFormScreenState extends State<RoomFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _controllers;
  late String _status;
  bool _saving = false;
  Uint8List? _selectedImage;
  String? _selectedMimeType;

  @override
  void initState() {
    super.initState();
    final room = widget.room;
    _status = room?.status ?? 'available';
    _controllers = {
      'room_number': TextEditingController(text: room?.roomNumber),
      'floor': TextEditingController(text: room?.floor.toString() ?? '1'),
      'area': TextEditingController(text: room?.area.toString() ?? ''),
      'price': TextEditingController(text: room?.price.toString() ?? ''),
      'deposit': TextEditingController(text: room?.deposit.toString() ?? '0'),
      'description': TextEditingController(text: room?.description),
      'image_url': TextEditingController(text: room?.imageUrl),
    };
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) { controller.dispose(); }
    super.dispose();
  }

  String? _required(String? value) => value == null || value.trim().isEmpty ? 'Không được để trống' : null;
  String? _number(String? value) {
    final number = double.tryParse(value?.trim() ?? '');
    return number == null || number < 0 ? 'Nhập số không âm hợp lệ' : null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      var imageUrl = _controllers['image_url']!.text.trim();
      if (_selectedImage != null && _selectedMimeType != null) {
        imageUrl = await widget.service.uploadImage(
          _selectedImage!,
          _selectedMimeType!,
        );
      }
      final body = <String, dynamic>{
        'room_number': _controllers['room_number']!.text.trim(),
        'floor': int.parse(_controllers['floor']!.text.trim()),
        'area': double.parse(_controllers['area']!.text.trim()),
        'price': double.parse(_controllers['price']!.text.trim()),
        'deposit': double.parse(_controllers['deposit']!.text.trim()),
        'status': _status,
        'description': _controllers['description']!.text.trim(),
        'image_url': imageUrl,
      };
      final result = widget.room == null
          ? await widget.service.create(body)
          : await widget.service.update(widget.room!.id, body);
      if (mounted) Navigator.pop(context, result);
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickImage() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      imageQuality: 85,
    );
    if (file == null) return;
    final extension = file.path.split('.').last.toLowerCase();
    final mimeType = switch (extension) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => null,
    };
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    if (mimeType == null) {
      _showMessage('Chỉ hỗ trợ ảnh JPEG, PNG hoặc WebP');
      return;
    }
    if (bytes.length > 5 * 1024 * 1024) {
      _showMessage('Ảnh sau khi xử lý vẫn lớn hơn 5 MB');
      return;
    }
    setState(() {
      _selectedImage = bytes;
      _selectedMimeType = mimeType;
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.room == null ? 'Thêm phòng' : 'Sửa phòng ${widget.room!.roomNumber}')),
    body: Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _field('room_number', 'Số phòng', validator: _required),
          Row(children: [
            Expanded(child: _field('floor', 'Tầng', number: true, validator: (value) {
              final number = int.tryParse(value ?? '');
              return number == null || number < 0 ? 'Tầng không hợp lệ' : null;
            })),
            const SizedBox(width: 12),
            Expanded(child: _field('area', 'Diện tích (m²)', number: true, validator: _number)),
          ]),
          _field('price', 'Giá phòng', number: true, validator: _number),
          _field('deposit', 'Tiền cọc', number: true, validator: _number),
          DropdownButtonFormField<String>(
            initialValue: _status,
            decoration: const InputDecoration(labelText: 'Trạng thái'),
            items: roomStatuses.map((value) => DropdownMenuItem(value: value, child: Text(roomStatusLabel(value)))).toList(),
            onChanged: (value) => _status = value!,
          ),
          const SizedBox(height: 12),
          _field('description', 'Mô tả', lines: 3),
          _imagePreview(),
          OutlinedButton.icon(
            onPressed: _saving ? null : _pickImage,
            icon: const Icon(Icons.photo_library_outlined),
            label: Text(
              _selectedImage == null
                  ? 'Chọn ảnh từ thiết bị'
                  : 'Chọn ảnh khác',
            ),
          ),
          const SizedBox(height: 12),
          _field('image_url', 'Đường dẫn ảnh'),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save_outlined),
            label: Text(_saving ? 'Đang lưu...' : 'Lưu phòng'),
          ),
        ],
      ),
    ),
  );

  Widget _imagePreview() {
    final imageUrl = _controllers['image_url']!.text.trim();
    if (_selectedImage == null && imageUrl.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: _selectedImage != null
            ? Image.memory(
                _selectedImage!,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
              )
            : Image.network(
                imageUrl,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox(
                  height: 120,
                  child: Card(
                    child: Center(child: Text('Không tải được ảnh hiện tại')),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _field(String key, String label, {bool number = false, int lines = 1, String? Function(String?)? validator}) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: _controllers[key],
      decoration: InputDecoration(labelText: label),
      keyboardType: number ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      maxLines: lines,
      validator: validator,
    ),
  );
}
