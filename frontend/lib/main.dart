import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/network/api_client.dart';
import 'core/storage/token_storage.dart';
import 'core/theme/app_theme.dart';
import 'models/user_model.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/profile/change_password_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/tenant/tenant_home_screen.dart';
import 'screens/users/add_user_screen.dart';
import 'screens/users/edit_user_screen.dart';
import 'screens/users/user_management_screen.dart';
import 'services/auth_service.dart';
import 'services/user_service.dart';

void main() {
  final navigatorKey = GlobalKey<NavigatorState>();
  final tokenStorage = TokenStorage();

  late final AuthProvider authProvider;

  final apiClient = ApiClient(
    tokenStorage: tokenStorage,
    onUnauthorized: () async {
      // Khi token hết hạn, xóa state và đưa user về màn login.
      await authProvider.handleUnauthorized();
      navigatorKey.currentState?.pushNamedAndRemoveUntil(
        LoginScreen.routeName,
        (_) => false,
      );
    },
  );

  final authService = AuthService(
    apiClient: apiClient,
    tokenStorage: tokenStorage,
  );
  final userService = UserService(apiClient: apiClient);

  authProvider = AuthProvider(authService: authService);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        Provider<UserService>.value(value: userService),
      ],
      child: MyApp(navigatorKey: navigatorKey),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.navigatorKey});

  final GlobalKey<NavigatorState> navigatorKey;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Quản lý nhà trọ',
      theme: buildAppTheme(),
      initialRoute: LoginScreen.routeName,
      routes: {
        LoginScreen.routeName: (_) => const LoginScreen(),
        RegisterScreen.routeName: (_) => const RegisterScreen(),
        DashboardScreen.routeName: (_) => const DashboardScreen(),
        TenantHomeScreen.routeName: (_) => const TenantHomeScreen(),
        ProfileScreen.routeName: (_) => const ProfileScreen(),
        ChangePasswordScreen.routeName: (_) => const ChangePasswordScreen(),
        UserManagementScreen.routeName: (_) => const UserManagementScreen(),
        AddUserScreen.routeName: (_) => const AddUserScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == EditUserScreen.routeName) {
          final user = settings.arguments;
          if (user is! UserModel) {
            return null;
          }

          return MaterialPageRoute(builder: (_) => EditUserScreen(user: user));
        }

        return null;
      },
    );
  }
}
