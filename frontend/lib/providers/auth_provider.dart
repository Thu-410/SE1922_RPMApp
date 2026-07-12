import 'package:flutter/foundation.dart';

import '../core/network/api_client.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({required AuthService authService}) : _authService = authService;

  final AuthService _authService;

  UserModel? user;
  bool isLoading = false;
  String? errorMessage;

  bool get isLoggedIn => user != null;

  Future<void> login({
    required String email,
    required String password,
  }) async {
    await _runAction(() async {
      final result = await _authService.login(email: email, password: password);
      user = result.user;
    });
  }

  Future<void> register({
    required String fullName,
    required String email,
    required String password,
    required String phone,
  }) async {
    await _runAction(() async {
      await _authService.register(
        fullName: fullName,
        email: email,
        password: password,
        phone: phone,
      );
    });
  }

  Future<void> loadProfile() async {
    await _runAction(() async {
      user = await _authService.getProfile();
    });
  }

  Future<void> updateProfile({
    required String fullName,
    required String phone,
  }) async {
    await _runAction(() async {
      user = await _authService.updateProfile(
        fullName: fullName,
        phone: phone,
      );
    });
  }

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    await _runAction(() async {
      await _authService.changePassword(
        oldPassword: oldPassword,
        newPassword: newPassword,
      );
    });
  }

  Future<void> logout() async {
    await _authService.logout();
    user = null;
    notifyListeners();
  }

  Future<void> handleUnauthorized() async {
    user = null;
    notifyListeners();
  }

  Future<void> _runAction(Future<void> Function() action) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await action();
    } on ApiException catch (error) {
      errorMessage = error.message;
      rethrow;
    } catch (_) {
      errorMessage = 'Có lỗi xảy ra, vui lòng thử lại';
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
