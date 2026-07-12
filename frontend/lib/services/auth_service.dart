import '../core/network/api_client.dart';
import '../core/storage/token_storage.dart';
import '../models/user_model.dart';

class LoginResult {
  const LoginResult({required this.token, required this.user});

  final String token;
  final UserModel user;
}

class AuthService {
  AuthService({
    required this.apiClient,
    required this.tokenStorage,
  });

  final ApiClient apiClient;
  final TokenStorage tokenStorage;

  Map<String, dynamic> _dataFromResponse(dynamic response) {
    if (response is Map<String, dynamic>) {
      final data = response['data'];
      if (data is Map<String, dynamic>) {
        return data;
      }
    }
    throw ApiException('Dữ liệu phản hồi không hợp lệ');
  }

  Future<UserModel> register({
    required String fullName,
    required String email,
    required String password,
    required String phone,
  }) async {
    final response = await apiClient.post(
      '/auth/register',
      data: {
        'full_name': fullName,
        'email': email,
        'password': password,
        'phone': phone,
      },
    );

    return UserModel.fromJson(_dataFromResponse(response));
  }

  Future<LoginResult> login({
    required String email,
    required String password,
  }) async {
    final response = await apiClient.post(
      '/auth/login',
      data: {
        'email': email,
        'password': password,
      },
    );

    final data = _dataFromResponse(response);
    final token = data['token']?.toString();
    final userJson = data['user'];

    if (token == null || userJson is! Map<String, dynamic>) {
      throw ApiException('Dữ liệu đăng nhập không hợp lệ');
    }

    await tokenStorage.saveToken(token);

    return LoginResult(
      token: token,
      user: UserModel.fromJson(userJson),
    );
  }

  Future<UserModel> getProfile() async {
    final response = await apiClient.get('/auth/profile');
    return UserModel.fromJson(_dataFromResponse(response));
  }

  Future<UserModel> updateProfile({
    required String fullName,
    required String phone,
  }) async {
    final response = await apiClient.put(
      '/auth/profile',
      data: {
        'full_name': fullName,
        'phone': phone,
      },
    );

    return UserModel.fromJson(_dataFromResponse(response));
  }

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    await apiClient.put(
      '/auth/change-password',
      data: {
        'old_password': oldPassword,
        'new_password': newPassword,
      },
    );
  }

  Future<void> logout() async {
    await tokenStorage.clearToken();
  }
}
