import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../core/network/token_storage.dart';
import '../models/admin_user.dart';

class AuthService {
  AuthService(this._client);
  final ApiClient _client;

  Future<LoginResult> login(String email, String password) async {
    final data = await _client.post(
      ApiConstants.login,
      body: {'email': email, 'password': password},
    );
    final result = LoginResult.fromJson(data as Map<String, dynamic>);
    await TokenStorage.instance.saveToken(result.accessToken);
    return result;
  }

  Future<void> logout() => TokenStorage.instance.clearToken();

  Future<bool> isLoggedIn() async {
    final token = await TokenStorage.instance.readToken();
    return token != null && token.isNotEmpty;
  }
}
