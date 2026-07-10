import 'package:flutter/material.dart';
import '../../core/constants/api_constants.dart';
import '../../core/storage/token_storage.dart';

class TokenSetupScreen extends StatefulWidget {
  const TokenSetupScreen({super.key, required this.onSaved});
  final VoidCallback onSaved;

  @override
  State<TokenSetupScreen> createState() => _TokenSetupScreenState();
}

class _TokenSetupScreenState extends State<TokenSetupScreen> {
  final _controller = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final token = _controller.text.trim();
    if (token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập JWT')));
      return;
    }
    setState(() => _saving = true);
    await TokenStorage.saveAccessToken(token);
    if (mounted) widget.onSaved();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(Icons.apartment_rounded, size: 56, color: Color(0xFF2563EB)),
                      const SizedBox(height: 16),
                      Text('Quản lý trọ', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      const Text('Nhập JWT tạm thời để kiểm thử các module quản trị. Màn hình này sẽ được thay bằng đăng nhập sau.', textAlign: TextAlign.center),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _controller,
                        minLines: 3,
                        maxLines: 6,
                        decoration: const InputDecoration(labelText: 'JWT access token', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 12),
                      Text('Backend: ${ApiConstants.baseUrl}', style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        onPressed: _saving ? null : _save,
                        icon: const Icon(Icons.login_rounded),
                        label: Text(_saving ? 'Đang lưu...' : 'Tiếp tục'),
                      ),
                    ],
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
