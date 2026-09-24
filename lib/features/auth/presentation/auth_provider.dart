import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/providers.dart';
import '../data/auth_repository.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

class AuthState {
  final AuthStatus status;
  final String? errorMessage;
  final bool biometricUnlocked;

  const AuthState({
    this.status = AuthStatus.initial,
    this.errorMessage,
    this.biometricUnlocked = false,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? errorMessage,
    bool? biometricUnlocked,
  }) {
    return AuthState(
      status: status ?? this.status,
      errorMessage: errorMessage,
      biometricUnlocked: biometricUnlocked ?? this.biometricUnlocked,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(const AuthState()) {
    _checkSession();
  }

  Future<void> _checkSession() async {
    final loggedIn = await _repository.isLoggedIn();
    state = AuthState(
      status:
          loggedIn ? AuthStatus.authenticated : AuthStatus.unauthenticated,
      biometricUnlocked: false,
    );
  }

  Future<bool> login({
    required String username,
    required String password,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      await _repository.login(username: username, password: password);
      state = const AuthState(
        status: AuthStatus.authenticated,
        biometricUnlocked: true,
      );
      return true;
    } on ApiException catch (e) {
      state = AuthState(status: AuthStatus.error, errorMessage: e.message);
      return false;
    } catch (_) {
      state = const AuthState(
        status: AuthStatus.error,
        errorMessage: 'خطای غیرمنتظره رخ داد',
      );
      return false;
    }
  }

  void markBiometricUnlocked() {
    state = state.copyWith(
      status: AuthStatus.authenticated,
      biometricUnlocked: true,
    );
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.watch(apiClientProvider),
    ref.watch(secureStorageProvider),
  );
});

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});
