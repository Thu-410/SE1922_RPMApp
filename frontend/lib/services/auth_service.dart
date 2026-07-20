import '../core/network/api_client.dart';
import '../core/storage/token_storage.dart';

class AuthService {
  AuthService(this._apiClient);

  final ApiClient _apiClient;

  Future<void> login({required String email, required String password}) async {
    final response = await _apiClient.post(
      '/auth/login',
      body: {'email': email.trim(), 'password': password},
    );
    final data = response['data'];
    if (data is! Map<String, dynamic> || data['token'] == null) {
      throw const FormatException('Phản hồi đăng nhập không có JWT');
    }
    await TokenStorage.saveAccessToken(data['token'].toString());
  }

  Future<void> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async {
    await _apiClient.post(
      '/auth/register',
      body: {
        'full_name': fullName.trim(),
        'email': email.trim(),
        'phone': phone.trim(),
        'password': password,
      },
    );
  }

  Future<void> logout() => TokenStorage.clear();
}
