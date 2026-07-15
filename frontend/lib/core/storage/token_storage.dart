import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  TokenStorage._();

  static const _storage = FlutterSecureStorage();
  static const _accessTokenKey = 'access_token';
  static const _apiBaseUrlKey = 'api_base_url';

  static Future<String?> readAccessToken() =>
      _storage.read(key: _accessTokenKey);

  static Future<void> saveAccessToken(String token) =>
      _storage.write(key: _accessTokenKey, value: token.trim());

  static Future<void> clear() => _storage.delete(key: _accessTokenKey);

  static Future<String?> readApiBaseUrl() => _storage.read(key: _apiBaseUrlKey);

  static Future<void> saveApiBaseUrl(String url) =>
      _storage.write(key: _apiBaseUrlKey, value: url.trim());

  static Future<void> clearApiBaseUrl() => _storage.delete(key: _apiBaseUrlKey);
}
