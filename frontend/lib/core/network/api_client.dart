import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../storage/token_storage.dart';
import 'api_exception.dart';

class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? query,
  }) => _send('GET', path, query: query);

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
  }) => _send('POST', path, body: body);

  Future<Map<String, dynamic>> put(String path, {Map<String, dynamic>? body}) =>
      _send('PUT', path, body: body);

  Future<Map<String, dynamic>> delete(String path) => _send('DELETE', path);

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, dynamic>? query,
    Map<String, dynamic>? body,
  }) async {
    final token = await TokenStorage.readAccessToken();
    final uri = Uri.parse('${ApiConstants.baseUrl}$path').replace(
      queryParameters: query?.map(
        (key, value) => MapEntry(key, value.toString()),
      ),
    );
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };

    try {
      late http.Response response;
      switch (method) {
        case 'POST':
          response = await _client.post(
            uri,
            headers: headers,
            body: jsonEncode(body ?? {}),
          );
        case 'PUT':
          response = await _client.put(
            uri,
            headers: headers,
            body: jsonEncode(body ?? {}),
          );
        case 'DELETE':
          response = await _client.delete(uri, headers: headers);
        default:
          response = await _client.get(uri, headers: headers);
      }
      response = await Future.value(response).timeout(ApiConstants.timeout);
      final decoded = response.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(
          decoded['message']?.toString() ?? 'Yêu cầu không thành công',
          statusCode: response.statusCode,
          errors: decoded['errors'],
        );
      }
      return decoded;
    } on ApiException {
      rethrow;
    } on FormatException {
      throw const ApiException('Phản hồi từ máy chủ không đúng định dạng');
    } catch (_) {
      throw const ApiException(
        'Không thể kết nối máy chủ. Kiểm tra backend và địa chỉ 10.33.59.217.',
      );
    }
  }

  void close() => _client.close();
}
