import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:orderfood/core/network/api_client.dart';
import 'package:orderfood/core/storage/token_storage.dart';
import 'package:orderfood/main.dart';
import 'package:orderfood/providers/auth_provider.dart';
import 'package:orderfood/services/auth_service.dart';

void main() {
  testWidgets('Login screen smoke test', (WidgetTester tester) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    final tokenStorage = TokenStorage();
    final apiClient = ApiClient(tokenStorage: tokenStorage);
    final authService = AuthService(
      apiClient: apiClient,
      tokenStorage: tokenStorage,
    );

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthProvider(authService: authService),
        child: MyApp(navigatorKey: navigatorKey),
      ),
    );

    expect(find.text('Đăng nhập'), findsWidgets);
  });
}
