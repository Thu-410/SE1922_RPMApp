import 'package:flutter/material.dart';

import 'core/app_theme.dart';
import 'models/room_permissions.dart';
import 'screens/room_list_screen.dart';
import 'services/room_api_service.dart';

void main() {
  runApp(const AuthenticatedRoomApp());
}

class AuthenticatedRoomApp extends StatefulWidget {
  const AuthenticatedRoomApp({super.key, this.authService});

  final AuthApiService? authService;

  @override
  State<AuthenticatedRoomApp> createState() => _AuthenticatedRoomAppState();
}

class _AuthenticatedRoomAppState extends State<AuthenticatedRoomApp> {
  late final AuthApiService _authService =
      widget.authService ?? AuthApiService();
  AuthSession? _session;

  @override
  Widget build(BuildContext context) {
    final session = _session;
    if (session == null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Đăng nhập RPMApp',
        theme: AppTheme.light,
        home: _LoginScreen(
          authService: _authService,
          onAuthenticated: (value) => setState(() => _session = value),
        ),
      );
    }

    return RoomManagementApp(
      roomService: RoomApiService(
        headersProvider: () => {'Authorization': 'Bearer ${session.token}'},
      ),
      permissions: RoomPermissions.fromRole(session.user.roleName),
      onLogout: () => setState(() => _session = null),
    );
  }
}

class RoomManagementApp extends StatelessWidget {
  const RoomManagementApp({
    super.key,
    this.roomService,
    this.permissions = RoomPermissions.denied,
    this.onLogout,
  });

  final RoomApiService? roomService;
  final RoomPermissions permissions;
  final VoidCallback? onLogout;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Quản lý phòng',
      theme: AppTheme.light,
      home: permissions.canView
          ? RoomListScreen(
              roomService: roomService ?? RoomApiService(),
              permissions: permissions,
              onLogout: onLogout,
            )
          : _RoomAccessDeniedScreen(onLogout: onLogout),
    );
  }
}

// Giữ tên cũ để các nơi đang dùng MyApp không bị ảnh hưởng.
class MyApp extends RoomManagementApp {
  const MyApp({
    super.key,
    super.roomService,
    super.permissions,
    super.onLogout,
  });
}

class _LoginScreen extends StatefulWidget {
  const _LoginScreen({
    required this.authService,
    required this.onAuthenticated,
  });

  final AuthApiService authService;
  final ValueChanged<AuthSession> onAuthenticated;

  @override
  State<_LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<_LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _saving = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    try {
      final session = await widget.authService.login(
        _emailController.text,
        _passwordController.text,
      );
      if (mounted) widget.onAuthenticated(session);
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Icon(
                          Icons.apartment_rounded,
                          size: 54,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Đăng nhập RPMApp',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Dùng tài khoản được cấp để quản lý phòng.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Color(0xFF667085)),
                        ),
                        const SizedBox(height: 28),
                        TextFormField(
                          controller: _emailController,
                          enabled: !_saving,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.username],
                          validator: (value) =>
                              value == null ||
                                  value.trim().isEmpty ||
                                  !value.contains('@')
                              ? 'Vui lòng nhập email hợp lệ'
                              : null,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          enabled: !_saving,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.password],
                          onFieldSubmitted: (_) => _submit(),
                          validator: (value) => value == null || value.isEmpty
                              ? 'Vui lòng nhập mật khẩu'
                              : null,
                          decoration: InputDecoration(
                            labelText: 'Mật khẩu',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              onPressed: _saving
                                  ? null
                                  : () => setState(
                                      () =>
                                          _obscurePassword = !_obscurePassword,
                                    ),
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: _saving ? null : _submit,
                          icon: _saving
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.login),
                          label: const Text('Đăng nhập'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoomAccessDeniedScreen extends StatelessWidget {
  const _RoomAccessDeniedScreen({this.onLogout});

  final VoidCallback? onLogout;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.lock_outline,
                  size: 58,
                  color: Color(0xFF98A2B3),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Bạn không có quyền xem danh sách phòng.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                if (onLogout != null) ...[
                  const SizedBox(height: 20),
                  OutlinedButton.icon(
                    onPressed: onLogout,
                    icon: const Icon(Icons.logout),
                    label: const Text('Đăng xuất'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
