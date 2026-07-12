import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import 'package:orderfood/core/network/api_client.dart';
import 'package:orderfood/core/storage/token_storage.dart';
import 'package:orderfood/providers/auth_provider.dart';
import 'package:orderfood/screens/auth/login_screen.dart';
import 'package:orderfood/screens/auth/register_screen.dart';
import 'package:orderfood/screens/profile/change_password_screen.dart';
import 'package:orderfood/screens/profile/profile_screen.dart';
import 'package:orderfood/screens/users/user_management_screen.dart';
import 'package:orderfood/services/auth_service.dart';
import 'package:orderfood/services/user_service.dart';

class MockApiClient extends Mock implements ApiClient {}
class MockTokenStorage extends Mock implements TokenStorage {}

const tenantJson = <String, dynamic>{
  'id': 1, 'full_name': 'Test User', 'email': 'test@example.com',
  'phone': '0912345678', 'role': 'tenant', 'status': 'active',
};
const managerJson = <String, dynamic>{
  'id': 1, 'full_name': 'Manager', 'email': 'manager@example.com',
  'phone': '0912345678', 'role': 'manager', 'status': 'active',
};

void main() {
  late MockApiClient api;
  late MockTokenStorage storage;
  late AuthService authService;
  late UserService userService;

  setUp(() {
    api = MockApiClient(); storage = MockTokenStorage();
    authService = AuthService(apiClient: api, tokenStorage: storage);
    userService = UserService(apiClient: api);
  });

  group('AuthService success and parsing', () {
    test('login parses user/token and stores token', () async {
      when(() => api.post('/auth/login', data: any(named: 'data'))).thenAnswer((_) async => {'data': {'token': 'jwt', 'user': tenantJson}});
      when(() => storage.saveToken('jwt')).thenAnswer((_) async {});
      final result = await authService.login(email: 'test@example.com', password: 'abc123');
      expect(result.token, 'jwt'); expect(result.user.role, 'tenant'); verify(() => storage.saveToken('jwt')).called(1);
    });
    test('register parses response', () async {
      when(() => api.post('/auth/register', data: any(named: 'data'))).thenAnswer((_) async => {'data': tenantJson});
      expect((await authService.register(fullName: 'Test', email: 'test@example.com', password: 'abc123', phone: '0912345678')).email, 'test@example.com');
    });
    test('getProfile parses response', () async {
      when(() => api.get('/auth/profile')).thenAnswer((_) async => {'data': tenantJson});
      expect((await authService.getProfile()).fullName, 'Test User');
    });
    test('updateProfile parses response and sends only allowed fields', () async {
      when(() => api.put('/auth/profile', data: any(named: 'data'))).thenAnswer((_) async => {'data': {...tenantJson, 'full_name': 'New'}});
      expect((await authService.updateProfile(fullName: 'New', phone: '0987654321')).fullName, 'New');
      verify(() => api.put('/auth/profile', data: {'full_name': 'New', 'phone': '0987654321'})).called(1);
    });
    test('changePassword sends correct payload', () async {
      when(() => api.put('/auth/change-password', data: any(named: 'data'))).thenAnswer((_) async => {'data': null});
      await authService.changePassword(oldPassword: 'old123', newPassword: 'new123');
      verify(() => api.put('/auth/change-password', data: {'old_password': 'old123', 'new_password': 'new123'})).called(1);
    });
    test('invalid login response throws ApiException and does not store token', () async {
      when(() => api.post('/auth/login', data: any(named: 'data'))).thenAnswer((_) async => {'data': {'user': tenantJson}});
      await expectLater(authService.login(email: 'a@b.com', password: 'abc123'), throwsA(isA<ApiException>()));
      verifyNever(() => storage.saveToken(any()));
    });
  });

  group('AuthService propagates common API failures', () {
    final failures = <String, ApiException>{
      '401': ApiException('Unauthorized', statusCode: 401),
      '400': ApiException('Invalid input', statusCode: 400),
      '409': ApiException('Email exists', statusCode: 409),
      'network': ApiException('Không có kết nối mạng'),
      'timeout': ApiException('Kết nối quá thời gian'),
    };
    for (final entry in failures.entries) {
      test('${entry.key} is preserved by login/register/profile/update/password', () async {
        when(() => api.post(any(), data: any(named: 'data'))).thenThrow(entry.value);
        when(() => api.get(any())).thenThrow(entry.value);
        when(() => api.put(any(), data: any(named: 'data'))).thenThrow(entry.value);
        final calls = <Future<dynamic> Function()>[
          () => authService.login(email: 'a@b.com', password: 'abc123'),
          () => authService.register(fullName: 'A', email: 'a@b.com', password: 'abc123', phone: '0912345678'),
          authService.getProfile,
          () => authService.updateProfile(fullName: 'A', phone: '0912345678'),
          () => authService.changePassword(oldPassword: 'old123', newPassword: 'new123'),
        ];
        for (final call in calls) {
          try { await call(); fail('must throw'); } on ApiException catch (e) { expect(e.message, entry.value.message); expect(e.statusCode, entry.value.statusCode); }
        }
      });
    }
  });

  group('UserService parsing', () {
    test('getUsers parses pagination and filters', () async {
      when(() => api.get('/users', queryParameters: any(named: 'queryParameters'))).thenAnswer((_) async => {'data': {'users': [managerJson], 'pagination': {'page': 2, 'limit': 5, 'total': 6, 'totalPages': 2}}});
      final result = await userService.getUsers(role: 'manager', status: 'active', search: 'man', page: 2, limit: 5);
      expect(result.users.single.role, 'manager'); expect(result.totalPages, 2);
    });
    test('CRUD parses get/create/update/delete', () async {
      when(() => api.get('/users/1')).thenAnswer((_) async => {'data': managerJson});
      when(() => api.post('/users', data: any(named: 'data'))).thenAnswer((_) async => {'data': {'user': tenantJson, 'temporaryPassword': 'temp123'}});
      when(() => api.put('/users/1', data: any(named: 'data'))).thenAnswer((_) async => {'data': managerJson});
      when(() => api.delete('/users/1')).thenAnswer((_) async => {'data': {...managerJson, 'status': 'inactive'}});
      expect((await userService.getUserById(1)).role, 'manager');
      expect((await userService.createUser(fullName: 'T', email: 't@e.com', role: 'tenant', status: 'active')).temporaryPassword, 'temp123');
      expect((await userService.updateUser(id: 1, fullName: 'M', role: 'manager', status: 'active')).role, 'manager');
      expect((await userService.deleteUser(1)).status, 'inactive');
    });
    test('malformed list/create responses throw ApiException', () async {
      when(() => api.get('/users', queryParameters: any(named: 'queryParameters'))).thenAnswer((_) async => {'data': {'users': 'bad'}});
      await expectLater(userService.getUsers(), throwsA(isA<ApiException>()));
      when(() => api.post('/users', data: any(named: 'data'))).thenAnswer((_) async => {'data': {'user': 'bad'}});
      await expectLater(userService.createUser(fullName: 'A', email: 'a@b.com', role: 'tenant', status: 'active'), throwsA(isA<ApiException>()));
    });
  });

  Widget wrap(Widget child, AuthProvider provider, {UserService? users}) => MultiProvider(
    providers: [ChangeNotifierProvider.value(value: provider), Provider<UserService>.value(value: users ?? userService)],
    child: MaterialApp(home: child, routes: {'/dashboard': (_) => const Scaffold(body: Text('dashboard')), '/tenant': (_) => const Scaffold(body: Text('tenant'))}),
  );

  group('Widget forms', () {
    testWidgets('login validates empty fields without API call', (tester) async {
      final provider = AuthProvider(authService: authService); await tester.pumpWidget(wrap(const LoginScreen(), provider));
      await tester.tap(find.byType(FilledButton)); await tester.pump();
      expect(find.textContaining('email'), findsWidgets); verifyNever(() => api.post(any(), data: any(named: 'data')));
    });
    testWidgets('login calls service, shows loading, then error and stops loading', (tester) async {
      final completer = Completer<dynamic>(); when(() => api.post('/auth/login', data: any(named: 'data'))).thenAnswer((_) => completer.future);
      final provider = AuthProvider(authService: authService); await tester.pumpWidget(wrap(const LoginScreen(), provider));
      final fields = find.byType(TextFormField); await tester.enterText(fields.at(0), 'a@b.com'); await tester.enterText(fields.at(1), 'abc123'); await tester.tap(find.byType(FilledButton)); await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      completer.completeError(ApiException('Mất mạng')); await tester.pump(); await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Mất mạng'), findsOneWidget); expect(provider.isLoading, false);
    });
    testWidgets('register validates fields and calls service with valid form', (tester) async {
      when(() => api.post('/auth/register', data: any(named: 'data'))).thenAnswer((_) async => {'data': tenantJson});
      final provider = AuthProvider(authService: authService); await tester.pumpWidget(wrap(const RegisterScreen(), provider));
      await tester.tap(find.byType(FilledButton)); await tester.pump(); expect(find.textContaining('email'), findsWidgets);
      final fields = find.byType(TextFormField); await tester.enterText(fields.at(0), 'Test'); await tester.enterText(fields.at(1), 'a@b.com'); await tester.enterText(fields.at(2), '0912345678'); await tester.enterText(fields.at(3), 'abc123'); await tester.tap(find.byType(FilledButton)); await tester.pumpAndSettle();
      verify(() => api.post('/auth/register', data: any(named: 'data'))).called(1);
    });
    testWidgets('change password rejects mismatch and calls API when valid', (tester) async {
      when(() => api.put('/auth/change-password', data: any(named: 'data'))).thenAnswer((_) async => {});
      final provider = AuthProvider(authService: authService); await tester.pumpWidget(wrap(const ChangePasswordScreen(), provider));
      final fields = find.byType(TextFormField); await tester.enterText(fields.at(0), 'old123'); await tester.enterText(fields.at(1), 'new123'); await tester.enterText(fields.at(2), 'different'); await tester.tap(find.byType(FilledButton)); await tester.pump(); expect(find.textContaining('khớp'), findsOneWidget);
      await tester.enterText(fields.at(2), 'new123'); await tester.tap(find.byType(FilledButton)); await tester.pumpAndSettle(); verify(() => api.put('/auth/change-password', data: any(named: 'data'))).called(1);
    });
    testWidgets('profile load network error does not leave infinite loading', (tester) async {
      when(() => api.get('/auth/profile')).thenThrow(ApiException('Mất mạng'));
      final provider = AuthProvider(authService: authService); await tester.pumpWidget(wrap(const ProfileScreen(), provider)); await tester.pump(); await tester.pump();
      expect(provider.isLoading, false); expect(provider.errorMessage, 'Mất mạng'); expect(find.byType(CircularProgressIndicator), findsNothing);
    });
    testWidgets('user management denies tenant and permits manager UI', (tester) async {
      when(() => storage.saveToken(any())).thenAnswer((_) async {});
      when(() => api.post('/auth/login', data: any(named: 'data'))).thenAnswer((_) async => {'data': {'token': 't', 'user': tenantJson}});
      when(() => api.get('/users', queryParameters: any(named: 'queryParameters'))).thenAnswer((_) async => {'data': {'users': [], 'pagination': {'page': 1, 'limit': 10, 'total': 0, 'totalPages': 1}}});
      final tenantProvider = AuthProvider(authService: authService); await tenantProvider.login(email: 'a@b.com', password: 'abc123');
      await tester.pumpWidget(wrap(const UserManagementScreen(), tenantProvider)); await tester.pump(); expect(find.textContaining('Manager'), findsOneWidget); verifyNever(() => api.get('/users', queryParameters: any(named: 'queryParameters')));
      when(() => api.post('/auth/login', data: any(named: 'data'))).thenAnswer((_) async => {'data': {'token': 't', 'user': managerJson}});
      when(() => api.get('/users', queryParameters: any(named: 'queryParameters'))).thenAnswer((_) async => {'data': {'users': [], 'pagination': {'page': 1, 'limit': 10, 'total': 0, 'totalPages': 1}}});
      final managerProvider = AuthProvider(authService: authService); await managerProvider.login(email: 'm@e.com', password: 'abc123'); await tester.pumpWidget(wrap(const UserManagementScreen(), managerProvider)); await tester.pumpAndSettle(); expect(find.byType(FloatingActionButton), findsOneWidget);
    });
  });
}
