import 'package:flutter/material.dart';
import 'core/network/api_client.dart';
import 'core/storage/token_storage.dart';
import 'screens/home/home_screen.dart';
import 'screens/token/token_setup_screen.dart';
import 'models/session_user.dart';
import 'services/session_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const RentalManagementApp());
}

class RentalManagementApp extends StatefulWidget {
  const RentalManagementApp({super.key});

  @override
  State<RentalManagementApp> createState() => _RentalManagementAppState();
}

class _RentalManagementAppState extends State<RentalManagementApp> {
  final ApiClient _apiClient = ApiClient();
  late Future<SessionUser?> _sessionFuture;

  @override
  void initState() {
    super.initState();
    _sessionFuture = _loadSession();
  }

  Future<SessionUser?> _loadSession() async {
    final token = await TokenStorage.readAccessToken();
    if (token == null || token.isEmpty) return null;
    try { return await SessionService(_apiClient).getSession(); }
    catch (_) { await TokenStorage.clear(); return null; }
  }

  void _reloadToken() {
    setState(() {
      _sessionFuture = _loadSession();
    });
  }

  @override
  void dispose() {
    _apiClient.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Quản lý trọ',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF6F8FC),
        cardTheme: const CardThemeData(
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
        ),
      ),
      home: FutureBuilder<SessionUser?>(
        future: _sessionFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          if (snapshot.data == null) {
            return TokenSetupScreen(onSaved: _reloadToken);
          }
          return HomeScreen(
            apiClient: _apiClient,
            user: snapshot.data!,
            onLogout: () async {
              await TokenStorage.clear();
              _reloadToken();
            },
          );
        },
      ),
    );
  }
}
