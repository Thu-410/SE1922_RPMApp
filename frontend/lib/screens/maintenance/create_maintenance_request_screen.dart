import 'package:flutter/material.dart';
import '../../services/maintenance_service.dart';

class CreateMaintenanceRequestScreen extends StatefulWidget {
  const CreateMaintenanceRequestScreen({super.key});

  @override
  State<CreateMaintenanceRequestScreen> createState() => _CreateMaintenanceRequestScreenState();
}

class _CreateMaintenanceRequestScreenState extends State<CreateMaintenanceRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _roomIdController = TextEditingController();
  final _tenantIdController = TextEditingController();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final MaintenanceService _service = MaintenanceService();
  bool _loading = false;

  @override
  void dispose() {
    _roomIdController.dispose();
    _tenantIdController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      await _service.create(
        roomId: int.parse(_roomIdController.text.trim()),
        tenantId: int.parse(_tenantIdController.text.trim()),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        imageUrl: _imageUrlController.text.trim().isEmpty ? null : _imageUrlController.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tạo yêu cầu sửa chữa thành công')));
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tạo yêu cầu sửa chữa')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _roomIdController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'ID phòng', border: OutlineInputBorder()),
                validator: (value) => value == null || value.isEmpty ? 'Nhập ID phòng' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _tenantIdController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'ID người thuê', border: OutlineInputBorder()),
                validator: (value) => value == null || value.isEmpty ? 'Nhập ID người thuê' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Tiêu đề sự cố', border: OutlineInputBorder()),
                validator: (value) => value == null || value.isEmpty ? 'Nhập tiêu đề' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Mô tả', border: OutlineInputBorder()),
                validator: (value) => value == null || value.isEmpty ? 'Nhập mô tả' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _imageUrlController,
                decoration: const InputDecoration(labelText: 'Link ảnh sự cố nếu có', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: Text(_loading ? 'Đang lưu...' : 'Tạo yêu cầu'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
