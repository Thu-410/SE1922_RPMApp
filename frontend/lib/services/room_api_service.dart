import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/api_config.dart';
import '../models/room.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class RoomApiService {
  RoomApiService({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _baseUrl = (baseUrl ?? ApiConfig.baseUrl).replaceFirst(RegExp(r'/$'), '');

  final http.Client _client;
  final String _baseUrl;

  Uri _uri([String path = '', Map<String, String>? query]) {
    final uri = Uri.parse('$_baseUrl/api/rooms$path');
    return query == null ? uri : uri.replace(queryParameters: query);
  }

  Future<List<Room>> getRooms({RoomStatus? status}) async {
    final response = await _request(
      () => _client.get(
        _uri('', status == null ? null : {'status': status.value}),
      ),
    );
    final data = response['data'];
    if (data is! List) {
      throw const ApiException('Dữ liệu danh sách phòng không hợp lệ.');
    }
    return data
        .map((item) => Room.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Future<Room> getRoom(int id) async {
    final response = await _request(() => _client.get(_uri('/$id')));
    return _roomFromResponse(response);
  }

  Future<Room> createRoom(RoomInput input) async {
    final response = await _request(
      () => _client.post(
        _uri(),
        headers: _headers,
        body: jsonEncode(input.toJson()),
      ),
    );
    return _roomFromResponse(response);
  }

  Future<Room> updateRoom(int id, RoomInput input) async {
    final response = await _request(
      () => _client.put(
        _uri('/$id'),
        headers: _headers,
        body: jsonEncode(input.toJson()),
      ),
    );
    return _roomFromResponse(response);
  }

  Future<Room> updateStatus(int id, RoomStatus status) async {
    final response = await _request(
      () => _client.patch(
        _uri('/$id/status'),
        headers: _headers,
        body: jsonEncode({'status': status.value}),
      ),
    );
    return _roomFromResponse(response);
  }

  Future<void> deleteRoom(int id) async {
    await _request(() => _client.delete(_uri('/$id')));
  }

  static const _headers = {'Content-Type': 'application/json'};

  Room _roomFromResponse(Map<String, dynamic> response) {
    final data = response['data'];
    if (data is! Map) throw const ApiException('Dữ liệu phòng không hợp lệ.');
    return Room.fromJson(Map<String, dynamic>.from(data));
  }

  Future<Map<String, dynamic>> _request(
    Future<http.Response> Function() send,
  ) async {
    try {
      final response = await send().timeout(const Duration(seconds: 15));
      Map<String, dynamic> body = {};
      if (response.body.isNotEmpty) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is Map) body = Map<String, dynamic>.from(decoded);
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(
          body['message'] as String? ?? 'Yêu cầu không thành công.',
          statusCode: response.statusCode,
        );
      }
      return body;
    } on ApiException {
      rethrow;
    } on FormatException {
      throw const ApiException('Phản hồi từ máy chủ không hợp lệ.');
    } catch (_) {
      throw const ApiException(
        'Không thể kết nối máy chủ. Vui lòng kiểm tra backend và thử lại.',
      );
    }
  }
}
