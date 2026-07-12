import '../core/network/api_client.dart';
import '../models/user_model.dart';

class UsersPageResult {
  const UsersPageResult({
    required this.users,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  final List<UserModel> users;
  final int page;
  final int limit;
  final int total;
  final int totalPages;
}

class CreatedUserResult {
  const CreatedUserResult({
    required this.user,
    this.temporaryPassword,
  });

  final UserModel user;
  final String? temporaryPassword;
}

class UserService {
  UserService({required this.apiClient});

  final ApiClient apiClient;

  Map<String, dynamic> _dataFromResponse(dynamic response) {
    if (response is Map<String, dynamic>) {
      final data = response['data'];
      if (data is Map<String, dynamic>) {
        return data;
      }
    }
    throw ApiException('Dữ liệu phản hồi không hợp lệ');
  }

  Future<UsersPageResult> getUsers({
    String? role,
    String? status,
    String? search,
    int page = 1,
    int limit = 10,
  }) async {
    final response = await apiClient.get(
      '/users',
      queryParameters: {
        if (role != null && role.isNotEmpty) 'role': role,
        if (status != null && status.isNotEmpty) 'status': status,
        if (search != null && search.isNotEmpty) 'search': search,
        'page': page,
        'limit': limit,
      },
    );

    final data = _dataFromResponse(response);
    final rawUsers = data['users'];
    final rawPagination = data['pagination'];

    if (rawUsers is! List || rawPagination is! Map<String, dynamic>) {
      throw ApiException('Dữ liệu danh sách user không hợp lệ');
    }

    return UsersPageResult(
      users: rawUsers
          .whereType<Map<String, dynamic>>()
          .map(UserModel.fromJson)
          .toList(),
      page: rawPagination['page'] as int? ?? page,
      limit: rawPagination['limit'] as int? ?? limit,
      total: rawPagination['total'] as int? ?? 0,
      totalPages: rawPagination['totalPages'] as int? ?? 1,
    );
  }

  Future<UserModel> getUserById(int id) async {
    final response = await apiClient.get('/users/$id');
    return UserModel.fromJson(_dataFromResponse(response));
  }

  Future<CreatedUserResult> createUser({
    required String fullName,
    required String email,
    String? password,
    String? phone,
    required String role,
    required String status,
  }) async {
    final response = await apiClient.post(
      '/users',
      data: {
        'full_name': fullName,
        'email': email,
        if (password != null && password.isNotEmpty) 'password': password,
        'phone': phone,
        'role': role,
        'status': status,
      },
    );

    final data = _dataFromResponse(response);
    final rawUser = data['user'];

    if (rawUser is! Map<String, dynamic>) {
      throw ApiException('Dữ liệu user không hợp lệ');
    }

    return CreatedUserResult(
      user: UserModel.fromJson(rawUser),
      temporaryPassword: data['temporaryPassword']?.toString(),
    );
  }

  Future<UserModel> updateUser({
    required int id,
    required String fullName,
    String? phone,
    required String role,
    required String status,
  }) async {
    final response = await apiClient.put(
      '/users/$id',
      data: {
        'full_name': fullName,
        'phone': phone,
        'role': role,
        'status': status,
      },
    );

    return UserModel.fromJson(_dataFromResponse(response));
  }

  Future<UserModel> deleteUser(int id) async {
    final response = await apiClient.delete('/users/$id');
    return UserModel.fromJson(_dataFromResponse(response));
  }
}
