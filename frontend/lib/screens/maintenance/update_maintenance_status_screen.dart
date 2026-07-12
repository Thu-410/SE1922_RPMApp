import 'package:flutter/material.dart';
import '../../models/maintenance_model.dart';
import '../../services/maintenance_service.dart';

class UpdateMaintenanceStatusScreen extends StatefulWidget {
  final MaintenanceRequestModel item;

  const UpdateMaintenanceStatusScreen({super.key, required this.item});

  @override
  State<UpdateMaintenanceStatusScreen> createState() => _UpdateMaintenanceStatusScreenState();
}

class _UpdateMaintenanceStatusScreenState extends State<UpdateMaintenanceStatusScreen> {
  final MaintenanceService _service = MaintenanceService();
  final _noteController = TextEditingController();
  late String _status;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _status = widget.item.status;
    _noteController.text = widget.item.managerNote ?? '';
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      await _service.updateStatus(
        id: widget.item.id,
        status: _status,
        managerNote: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cập nhật trạng thái thành công')));
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
      appBar: AppBar(title: const Text('Cập nhật xử lý')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: _status,
              decoration: const InputDecoration(labelText: 'Trạng thái', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'pending', child: Text('Chờ xử lý')),
                DropdownMenuItem(value: 'processing', child: Text('Đang xử lý')),
                DropdownMenuItem(value: 'completed', child: Text('Hoàn thành')),
                DropdownMenuItem(value: 'cancelled', child: Text('Đã hủy')),
              ],
              onChanged: (value) => setState(() => _status = value ?? 'pending'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteController,
              maxLines: 5,
              decoration: const InputDecoration(labelText: 'Ghi chú xử lý', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: Text(_loading ? 'Đang cập nhật...' : 'Cập nhật'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
