import '../../../core/network/api_client.dart';
import '../../../core/session/session.dart';

class AuthApi {
  AuthApi(this.api);
  final ApiClient api;

  Future<String> guest(String displayName) async {
    final res = await api.post('/api/v1/auth/guest', {'displayName': displayName});
    final tok = res['accessToken'] as String;
    Session.I.token = tok;
    Session.I.displayName = displayName;
    return tok;
  }
}
