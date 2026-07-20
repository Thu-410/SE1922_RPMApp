import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  TokenStorage._();

  static const _storage = FlutterSecureStorage();
  static const _accessTokenKey = 'access_token';
  static const _apiBaseUrlKey = 'api_base_url';

  static Future<String?> readAccessToken() => _read(_accessTokenKey);

  static Future<void> saveAccessToken(String token) =>
      _storage.write(key: _accessTokenKey, value: token.trim());

  static Future<void> clear() => _storage.delete(key: _accessTokenKey);

  static Future<String?> readApiBaseUrl() => _read(_apiBaseUrlKey);

  static Future<void> saveApiBaseUrl(String url) =>
      _storage.write(key: _apiBaseUrlKey, value: url.trim());

  static Future<void> clearApiBaseUrl() => _storage.delete(key: _apiBaseUrlKey);

  static Future<String?> _read(String key) async {
    try {
      return await _storage.read(key: key);
    } on PlatformException catch (error) {
      if (!_isDecryptionError(error)) rethrow;

      // Android can restore encrypted preferences without restoring the
      // device-bound key. Discard that unusable local session and let the
      // user sign in again instead of surfacing a BadPaddingException.
      try {
        await _storage.deleteAll();
      } on PlatformException {
        // A subsequent successful write replaces the affected values. The
        // current read must still recover so the app can reach the login UI.
      }
      return null;
    }
  }

  static bool _isDecryptionError(PlatformException error) {
    final details = '${error.code} ${error.message} ${error.details}'
        .toLowerCase();
    return details.contains('badpaddingexception') ||
        details.contains('bad_decrypt') ||
        details.contains('failed to unwrap key') ||
        details.contains('invalidkeyexception');
  }
}
