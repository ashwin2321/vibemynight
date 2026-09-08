import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists the admin JWT between app launches (admin login only - there is
/// no customer login in v1).
class TokenStorage {
  TokenStorage._();
  static final TokenStorage instance = TokenStorage._();

  static const _tokenKey = 'vmn_admin_access_token';
  final _storage = const FlutterSecureStorage();

  Future<void> saveToken(String token) => _storage.write(key: _tokenKey, value: token);

  Future<String?> readToken() => _storage.read(key: _tokenKey);

  Future<void> clearToken() => _storage.delete(key: _tokenKey);
}
