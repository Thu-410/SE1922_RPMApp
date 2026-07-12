import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../storage/token_storage.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({
    TokenStorage? tokenStorage,
    Dio? dio,
    this.onUnauthorized,
  })  : tokenStorage = tokenStorage ?? TokenStorage(),
        dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: baseUrl,
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 15),
                headers: {'Content-Type': 'application/json'},
              ),
            ) {
    _setupInterceptors();
  }

  static const String _configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
  );

  /// Android Emulator truy cập máy host qua 10.0.2.2. Có thể ghi đè khi
  /// chạy điện thoại thật bằng `--dart-define=API_BASE_URL=http://IP:3000/api`.
  static String get baseUrl {
    if (_configuredBaseUrl.isNotEmpty) return _configuredBaseUrl;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000/api';
    }
    return 'http://localhost:3000/api';
  }

  final Dio dio;
  final TokenStorage tokenStorage;
  final Future<void> Function()? onUnauthorized;

  void _setupInterceptors() {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await tokenStorage.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            // Token hết hạn/sai thì xóa token để app tự về màn đăng nhập.
            await tokenStorage.clearToken();
            await onUnauthorized?.call();
          }
          handler.next(error);
        },
      ),
    );
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await dio.get(path, queryParameters: queryParameters);
      return response.data;
    } on DioException catch (error) {
      throw _handleDioError(error);
    }
  }

  Future<dynamic> post(String path, {Map<String, dynamic>? data}) async {
    try {
      final response = await dio.post(path, data: data);
      return response.data;
    } on DioException catch (error) {
      throw _handleDioError(error);
    }
  }

  Future<dynamic> put(String path, {Map<String, dynamic>? data}) async {
    try {
      final response = await dio.put(path, data: data);
      return response.data;
    } on DioException catch (error) {
      throw _handleDioError(error);
    }
  }

  Future<dynamic> delete(String path) async {
    try {
      final response = await dio.delete(path);
      return response.data;
    } on DioException catch (error) {
      throw _handleDioError(error);
    }
  }

  ApiException _handleDioError(DioException error) {
    final data = error.response?.data;
    final message = data is Map<String, dynamic>
        ? data['message']?.toString()
        : null;

    final fallbackMessage = switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout =>
        'Kết nối quá thời gian. Vui lòng kiểm tra backend và thử lại.',
      DioExceptionType.connectionError =>
        'Không thể kết nối máy chủ. Hãy kiểm tra backend và kết nối mạng.',
      _ => 'Có lỗi xảy ra, vui lòng thử lại',
    };

    return ApiException(
      message ?? fallbackMessage,
      statusCode: error.response?.statusCode,
    );
  }
}
