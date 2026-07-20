import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../services/auth_service.dart';
import '../settings/server_config_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.apiClient,
    required this.onLoggedIn,
    this.errorMessage,
  });

  final ApiClient apiClient;
  final VoidCallback onLoggedIn;
  final String? errorMessage;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await AuthService(
        widget.apiClient,
      ).login(email: _emailController.text, password: _passwordController.text);
      if (mounted) widget.onLoggedIn();
    } catch (error) {
      if (mounted) {
        setState(() => _error = error.toString());
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _openRegister() async {
    final registered = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => RegisterScreen(apiClient: widget.apiClient),
      ),
    );
    if (registered == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đăng ký thành công. Hãy đăng nhập.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final error = _error ?? widget.errorMessage;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            tooltip: 'Cấu hình máy chủ',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ServerConfigScreen(apiClient: widget.apiClient),
              ),
            ),
            icon: const Icon(Icons.settings_ethernet),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Icon(
                          Icons.apartment_rounded,
                          size: 64,
                          color: Color(0xFF2563EB),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Quản lý trọ',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Đăng nhập để tiếp tục',
                          textAlign: TextAlign.center,
                        ),
                        if (error != null) ...[
                          const SizedBox(height: 18),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              error,
                              style: const TextStyle(color: Color(0xFFB91C1C)),
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email],
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email_outlined),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            final email = value?.trim() ?? '';
                            if (email.isEmpty) {
                              return 'Vui lòng nhập email';
                            }
                            if (!email.contains('@')) {
                              return 'Email không hợp lệ';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          autofillHints: const [AutofillHints.password],
                          onFieldSubmitted: (_) =>
                              _submitting ? null : _login(),
                          decoration: InputDecoration(
                            labelText: 'Mật khẩu',
                            prefixIcon: const Icon(Icons.lock_outline),
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                          validator: (value) => (value?.isEmpty ?? true)
                              ? 'Vui lòng nhập mật khẩu'
                              : null,
                        ),
                        const SizedBox(height: 22),
                        FilledButton.icon(
                          onPressed: _submitting ? null : _login,
                          icon: _submitting
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.login_rounded),
                          label: Text(
                            _submitting ? 'Đang đăng nhập...' : 'Đăng nhập',
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextButton(
                          onPressed: _submitting ? null : _openRegister,
                          child: const Text('Chưa có tài khoản? Đăng ký'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
