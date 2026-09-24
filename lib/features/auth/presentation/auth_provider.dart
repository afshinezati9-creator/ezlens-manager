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
  final bool otpSent;
  final String? otpMobile;

  const AuthState({
    this.status = AuthStatus.initial,
    this.errorMessage,
    this.biometricUnlocked = false,
    this.otpSent = false,
    this.otpMobile,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? errorMessage,
    bool clearError = false,
    bool? biometricUnlocked,
    bool? otpSent,
    String? otpMobile,
  }) {
    return AuthState(
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      biometricUnlocked: biometricUnlocked ?? this.biometricUnlocked,
      otpSent: otpSent ?? this.otpSent,
      otpMobile: otpMobile ?? this.otpMobile,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._repository) : super(const AuthState()) {
    _checkSession();
  }

  final AuthRepository _repository;

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
    state = state.copyWith(status: AuthStatus.loading, clearError: true);
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

  Future<bool> sendOtp(String mobile) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);
    try {
      await _repository.sendOtp(mobile);
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        otpSent: true,
        otpMobile: mobile.trim(),
        biometricUnlocked: false,
      );
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.message,
        otpSent: false,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
        otpSent: false,
      );
      return false;
    }
  }

  Future<bool> verifyOtp({
    required String mobile,
    required String code,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);
    try {
      final result = await _repository.verifyOtp(mobile: mobile, code: code);
      if (result.loggedIn) {
        state = const AuthState(
          status: AuthStatus.authenticated,
          biometricUnlocked: true,
        );
        return true;
      }
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage:
            'کد تأیید درست بود. برای ورود به پنل مدیریت، از تب «رمز برنامه» '
            'با Application Password وارد شوید (API مدیریت به آن نیاز دارد).',
        otpSent: true,
        otpMobile: result.mobile,
      );
      return false;
    } on ApiException catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.message,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
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
