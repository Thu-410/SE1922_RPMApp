import 'package:flutter/material.dart';
import '../../models/contract_model.dart';
import '../../models/tenant_model.dart';
import '../../services/contract_service.dart';
import '../../services/tenant_service.dart';

class CreateContractScreen extends StatefulWidget {
  const CreateContractScreen({super.key});

  @override
  State<CreateContractScreen> createState() => _CreateContractScreenState();
}

class _CreateContractScreenState extends State<CreateContractScreen> {
  final _formKey = GlobalKey<FormState>();
  final ContractService _contractService = ContractService();
  final TenantService _tenantService = TenantService();

  final _roomIdController = TextEditingController(); // TODO: thay bằng dropdown khi có API rooms
  final _monthlyPriceController = TextEditingController();
  final _depositController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  int? _selectedTenantId;
  List<Tenant> _tenants = [];
  bool _isLoading = false;
  bool _isLoadingTenants = true;

  @override
  void initState() {
    super.initState();
    _loadTenants();
  }

  Future<void> _loadTenants() async {
    try {
      final tenants = await _tenantService.getAllTenants();
      setState(() {
        _tenants = tenants;
        _isLoadingTenants = false;
      });
    } catch (e) {
      setState(() => _isLoadingTenants = false);
    }
  }

  Future<void> _pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTenantId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui long chon nguoi thue')),
      );
      return;
    }
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui long chon ngay bat dau va ket thuc')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final contract = Contract(
        id: 0,
        roomId: int.parse(_roomIdController.text.trim()),
        tenantId: _selectedTenantId!,
        startDate: _formatDate(_startDate!),
        endDate: _formatDate(_endDate!),
        monthlyPrice: double.parse(_monthlyPriceController.text.trim()),
        depositAmount: double.tryParse(_depositController.text.trim()) ?? 0,
      );

      await _contractService.createContract(contract);

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tao hop dong')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // TODO: thay bằng dropdown chọn phòng khi Người 2 xong API rooms
              TextFormField(
                controller: _roomIdController,
                decoration: const InputDecoration(
                  labelText: 'Ma phong (nhap ID, se doi thanh dropdown sau) *',
                ),
                keyboardType: TextInputType.number,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Bat buoc' : null,
              ),
              const SizedBox(height: 12),

              _isLoadingTenants
                  ? const Center(child: CircularProgressIndicator())
                  : DropdownButtonFormField<int>(
                      initialValue: _selectedTenantId,
                      decoration: const InputDecoration(labelText: 'Nguoi thue *'),
                      items: _tenants
                          .map((t) => DropdownMenuItem(
                                value: t.id,
                                child: Text('${t.fullName} - ${t.phone}'),
                              ))
                          .toList(),
                      onChanged: (value) => setState(() => _selectedTenantId = value),
                    ),
              const SizedBox(height: 12),

              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(_startDate == null
                    ? 'Chon ngay bat dau *'
                    : 'Bat dau: ${_formatDate(_startDate!)}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _pickDate(isStart: true),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(_endDate == null
                    ? 'Chon ngay ket thuc *'
                    : 'Ket thuc: ${_formatDate(_endDate!)}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _pickDate(isStart: false),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _monthlyPriceController,
                decoration: const InputDecoration(labelText: 'Gia thue / thang *'),
                keyboardType: TextInputType.number,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Bat buoc' : null,
              ),
              TextFormField(
                controller: _depositController,
                decoration: const InputDecoration(labelText: 'Tien coc'),
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Tao hop dong'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}