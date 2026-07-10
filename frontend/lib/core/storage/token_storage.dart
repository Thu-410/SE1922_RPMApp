import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  TokenStorage._();

  static const _storage = FlutterSecureStorage();
  static const _accessTokenKey = 'access_token';

  static Future<String?> readAccessToken() => _storage.read(key: _accessTokenKey);

  static Future<void> saveAccessToken(String token) =>
      _storage.write(key: _accessTokenKey, value: token.trim());

  static Future<void> clear() => _storage.delete(key: _accessTokenKey);
}
