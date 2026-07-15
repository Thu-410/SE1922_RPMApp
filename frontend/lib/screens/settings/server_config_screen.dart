import 'package:flutter/material.dart';

import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/token_storage.dart';

class ServerConfigScreen extends StatefulWidget {
  const ServerConfigScreen({super.key, required this.apiClient});
  final ApiClient apiClient;

  @override
  State<ServerConfigScreen> createState() => _ServerConfigScreenState();
}

class _ServerConfigScreenState extends State<ServerConfigScreen> {
  final _controller = TextEditingController();
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _controller.text =
        await TokenStorage.readApiBaseUrl() ?? ApiConstants.defaultBaseUrl;
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String? _normalize(String value) {
    var text = value.trim();
    if (text.endsWith('/')) text = text.substring(0, text.length - 1);
    final uri = Uri.tryParse(text);
    if (uri == null ||
        !['http', 'https'].contains(uri.scheme) ||
        uri.host.isEmpty) {
      return null;
    }
    if (uri.path.isEmpty) text = '$text/api';
    return text;
  }

  Future<void> _save() async {
    final normalized = _normalize(_controller.text);
    if (normalized == null) {
      _message('Địa chỉ phải bắt đầu bằng http:// hoặc https://');
      return;
    }
    setState(() => _saving = true);
    final previous = await TokenStorage.readApiBaseUrl();
    try {
      await TokenStorage.saveApiBaseUrl(normalized);
      await widget.apiClient.get('/health');
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (previous == null) {
        await TokenStorage.clearApiBaseUrl();
      } else {
        await TokenStorage.saveApiBaseUrl(previous);
      }
      if (mounted) _message('Không kết nối được tới máy chủ vừa nhập.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Cấu hình máy chủ')),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                'Nhập địa chỉ backend trong mạng hiện tại. Nếu bỏ phần /api, ứng dụng sẽ tự bổ sung.',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                keyboardType: TextInputType.url,
                autocorrect: false,
                decoration: const InputDecoration(
                  labelText: 'Địa chỉ backend',
                  hintText: 'http://IP-MAY-CHU:3000/api',
                  prefixIcon: Icon(Icons.dns_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Android Emulator dùng 10.0.2.2 để truy cập máy tính. Điện thoại thật phải dùng IP LAN hoặc domain của máy chạy backend.',
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: const Icon(Icons.wifi_find),
                label: Text(_saving ? 'Đang kiểm tra...' : 'Kiểm tra và lưu'),
              ),
            ],
          ),
  );
}
