import 'package:flutter/material.dart';
import '../../models/tenant_model.dart';
import '../../services/tenant_service.dart';

class EditTenantScreen extends StatefulWidget {
  final Tenant tenant;

  const EditTenantScreen({super.key, required this.tenant});

  @override
  State<EditTenantScreen> createState() => _EditTenantScreenState();
}

class _EditTenantScreenState extends State<EditTenantScreen> {
  final _formKey = GlobalKey<FormState>();
  final TenantService _tenantService = TenantService();

  late final TextEditingController _fullNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _citizenIdController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(text: widget.tenant.fullName);
    _phoneController = TextEditingController(text: widget.tenant.phone);
    _emailController = TextEditingController(text: widget.tenant.email ?? '');
    _citizenIdController = TextEditingController(text: widget.tenant.citizenId ?? '');
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final updatedTenant = Tenant(
        id: widget.tenant.id,
        userId: widget.tenant.userId,
        roomId: widget.tenant.roomId,
        fullName: _fullNameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        citizenId: _citizenIdController.text.trim().isEmpty ? null : _citizenIdController.text.trim(),
        dateOfBirth: widget.tenant.dateOfBirth,
        hometown: widget.tenant.hometown,
        address: widget.tenant.address,
        isRepresentative: widget.tenant.isRepresentative,
        status: widget.tenant.status,
      );

      await _tenantService.updateTenant(widget.tenant.id, updatedTenant);

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
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _citizenIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sua nguoi thue')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(labelText: 'Ho ten *'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Bat buoc' : null,
              ),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'So dien thoai *'),
                keyboardType: TextInputType.phone,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Bat buoc' : null,
              ),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              TextFormField(
                controller: _citizenIdController,
                decoration: const InputDecoration(labelText: 'So CCCD'),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Luu thay doi'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}