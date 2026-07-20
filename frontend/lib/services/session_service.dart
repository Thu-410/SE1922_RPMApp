import '../core/network/api_client.dart';
import '../models/session_user.dart';

class SessionService {
  SessionService(this._api);
  final ApiClient _api;

  Future<SessionUser> getSession() async {
    final response = await _api.get('/session');
    return SessionUser.fromJson(response['data'] as Map<String, dynamic>);
  }
}
