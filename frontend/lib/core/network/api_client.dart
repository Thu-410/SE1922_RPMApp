import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  final http.Client _client;

  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  Future<dynamic> get(String url) async {
    final response = await _client.get(Uri.parse(url), headers: _headers());
    return _handleResponse(response);
  }

  Future<dynamic> post(String url, Map<String, dynamic> body) async {
    final response = await _client.post(
      Uri.parse(url),
      headers: _headers(),
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  Future<dynamic> put(String url, Map<String, dynamic> body) async {
    final response = await _client.put(
      Uri.parse(url),
      headers: _headers(),
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  Future<dynamic> delete(String url) async {
    final response = await _client.delete(Uri.parse(url), headers: _headers());
    return _handleResponse(response);
  }

  Map<String, String> _headers() {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      // Khi ghép với Người 1, thêm token thật vào đây:
      // 'Authorization': 'Bearer $token',
    };
  }

  dynamic _handleResponse(http.Response response) {
    final decoded = response.body.isEmpty ? null : jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }

    final message = decoded is Map<String, dynamic>
        ? decoded['message']?.toString() ?? 'Có lỗi xảy ra'
        : 'Có lỗi xảy ra';

    throw Exception(message);
  }
}
