import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/network/api_client.dart';
import '../../models/service_price.dart';
import '../../services/utility_service.dart';

class ServicePriceScreen extends StatefulWidget {
  const ServicePriceScreen({super.key, required this.apiClient, required this.price});
  final ApiClient apiClient;
  final ServicePrice price;

  @override
  State<ServicePriceScreen> createState() => _ServicePriceScreenState();
}

class _ServicePriceScreenState extends State<ServicePriceScreen> {
  final _key = GlobalKey<FormState>();
  late final UtilityService _service;
  late final Map<String, TextEditingController> _controllers;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _service = UtilityService(widget.apiClient);
    _controllers = {
      'electricPrice': TextEditingController(text: widget.price.electricPrice.toStringAsFixed(0)),
      'waterPrice': TextEditingController(text: widget.price.waterPrice.toStringAsFixed(0)),
      'serviceFee': TextEditingController(text: widget.price.serviceFee.toStringAsFixed(0)),
      'parkingFee': TextEditingController(text: widget.price.parkingFee.toStringAsFixed(0)),
      'internetFee': TextEditingController(text: widget.price.internetFee.toStringAsFixed(0)),
    };
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) { controller.dispose(); }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_key.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await _service.updatePrice(widget.price.id, _controllers.map((key, value) => MapEntry(key, double.parse(value.text))));
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const labels = {'electricPrice': 'Giá điện / kWh', 'waterPrice': 'Giá nước / m³', 'serviceFee': 'Phí dịch vụ', 'parkingFee': 'Phí gửi xe', 'internetFee': 'Phí Internet'};
    return Scaffold(
      appBar: AppBar(title: const Text('Cấu hình giá dịch vụ')),
      body: Form(
        key: _key,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ..._controllers.entries.map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: TextFormField(
                controller: entry.value,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(labelText: labels[entry.key], suffixText: 'đ', border: const OutlineInputBorder()),
                validator: (value) => double.tryParse(value ?? '') == null ? 'Nhập số tiền hợp lệ' : null,
              ),
            )),
            FilledButton.icon(onPressed: _saving ? null : _save, icon: const Icon(Icons.save), label: Text(_saving ? 'Đang lưu...' : 'Lưu bảng giá')),
          ],
        ),
      ),
    );
  }
}
