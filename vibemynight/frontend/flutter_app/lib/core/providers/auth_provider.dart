import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'service_providers.dart';

/// Tracks whether an admin is currently logged in (JWT present in secure
/// storage), so GoRouter can redirect /admin/** routes to /admin/login.
class AuthState {
  final bool isLoggedIn;
  final bool isLoading;

  const AuthState({required this.isLoggedIn, required this.isLoading});

  static const initial = AuthState(isLoggedIn: false, isLoading: true);
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._ref) : super(AuthState.initial) {
    _restore();
  }

  final Ref _ref;

  Future<void> _restore() async {
    final loggedIn = await _ref.read(authServiceProvider).isLoggedIn();
    state = AuthState(isLoggedIn: loggedIn, isLoading: false);
  }

  Future<void> login(String email, String password) async {
    await _ref.read(authServiceProvider).login(email, password);
    state = const AuthState(isLoggedIn: true, isLoading: false);
  }

  Future<void> logout() async {
    await _ref.read(authServiceProvider).logout();
    state = const AuthState(isLoggedIn: false, isLoading: false);
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref);
});
