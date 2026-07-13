import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/api_config.dart';
import '../models/room.dart';

typedef RoomApiHeadersProvider = FutureOr<Map<String, String>> Function();

class AuthUser {
  const AuthUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.roleName,
  });

  final int id;
  final String fullName;
  final String email;
  final String roleName;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final fullName = json['full_name'];
    final email = json['email'];
    final roleName = json['role_name'];
    if (id is! num ||
        fullName is! String ||
        email is! String ||
        roleName is! String) {
      throw const ApiException('Thông tin tài khoản không hợp lệ.');
    }
    return AuthUser(
      id: id.toInt(),
      fullName: fullName,
      email: email,
      roleName: roleName,
    );
  }
}

class AuthSession {
  const AuthSession({required this.token, required this.user});

  final String token;
  final AuthUser user;
}

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class RoomApiService {
  RoomApiService({http.Client? client, String? baseUrl, this.headersProvider})
    : _client = client ?? http.Client(),
      _baseUrl = (baseUrl ?? ApiConfig.baseUrl).replaceFirst(RegExp(r'/$'), '');

  final http.Client _client;
  final String _baseUrl;
  final RoomApiHeadersProvider? headersProvider;

  Future<Map<String, String>> _headers() async => {
    'Content-Type': 'application/json',
    ...?await headersProvider?.call(),
  };

  Uri _uri([String path = '', Map<String, String>? query]) {
    final uri = Uri.parse('$_baseUrl/api/rooms$path');
    return query == null ? uri : uri.replace(queryParameters: query);
  }

  Future<List<Room>> getRooms({RoomStatus? status}) async {
    final headers = await _headers();
    final response = await _request(
      () => _client.get(
        _uri('', status == null ? null : {'status': status.value}),
        headers: headers,
      ),
    );
    final data = response['data'];
    if (data is! List) {
      throw const ApiException('Dữ liệu danh sách phòng không hợp lệ.');
    }
    final rooms = <Room>[];
    try {
      for (final item in data) {
        if (item is! Map) {
          throw const ApiException('Dữ liệu danh sách phòng không hợp lệ.');
        }
        rooms.add(Room.fromJson(Map<String, dynamic>.from(item)));
      }
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException('Dữ liệu danh sách phòng không hợp lệ.');
    }
    return rooms;
  }

  Future<Room> getRoom(int id) async {
    final headers = await _headers();
    final response = await _request(
      () => _client.get(_uri('/$id'), headers: headers),
    );
    return _roomFromResponse(response);
  }

  Future<Room> createRoom(RoomInput input) async {
    final headers = await _headers();
    final response = await _request(
      () => _client.post(
        _uri(),
        headers: headers,
        body: jsonEncode(input.toJson()),
      ),
    );
    return _roomFromResponse(response);
  }

  Future<Room> updateRoom(int id, RoomInput input) async {
    final headers = await _headers();
    final response = await _request(
      () => _client.put(
        _uri('/$id'),
        headers: headers,
        body: jsonEncode(input.toJson()),
      ),
    );
    return _roomFromResponse(response);
  }

  Future<Room> updateStatus(int id, RoomStatus status) async {
    final headers = await _headers();
    final response = await _request(
      () => _client.put(
        _uri('/$id/status'),
        headers: headers,
        body: jsonEncode({'status': status.value}),
      ),
    );
    return _roomFromResponse(response);
  }

  Future<void> deleteRoom(int id) async {
    final headers = await _headers();
    await _request(() => _client.delete(_uri('/$id'), headers: headers));
  }

  Room _roomFromResponse(Map<String, dynamic> response) {
    final data = response['data'];
    if (data is! Map) throw const ApiException('Dữ liệu phòng không hợp lệ.');
    try {
      return Room.fromJson(Map<String, dynamic>.from(data));
    } catch (_) {
      throw const ApiException('Dữ liệu phòng không hợp lệ.');
    }
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

class AuthApiService {
  AuthApiService({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _baseUrl = (baseUrl ?? ApiConfig.baseUrl).replaceFirst(RegExp(r'/$'), '');

  final http.Client _client;
  final String _baseUrl;

  Future<AuthSession> login(String email, String password) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$_baseUrl/api/auth/login'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email.trim(), 'password': password}),
          )
          .timeout(const Duration(seconds: 15));
      final decoded = response.bodyBytes.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(utf8.decode(response.bodyBytes));
      final body = decoded is Map
          ? Map<String, dynamic>.from(decoded)
          : <String, dynamic>{};
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(
          body['message'] as String? ?? 'Đăng nhập không thành công.',
          statusCode: response.statusCode,
        );
      }
      final data = body['data'];
      if (data is! Map) {
        throw const ApiException('Phiên đăng nhập không hợp lệ.');
      }
      final session = Map<String, dynamic>.from(data);
      final token = session['token'];
      final user = session['user'];
      if (token is! String || token.isEmpty || user is! Map) {
        throw const ApiException('Phiên đăng nhập không hợp lệ.');
      }
      return AuthSession(
        token: token,
        user: AuthUser.fromJson(Map<String, dynamic>.from(user)),
      );
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
