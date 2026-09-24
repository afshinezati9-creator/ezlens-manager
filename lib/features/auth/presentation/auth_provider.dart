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
  final bool otpSent;
  final String? otpMobile;

  const AuthState({
    this.status = AuthStatus.initial,
    this.errorMessage,
    this.otpSent = false,
    this.otpMobile,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? errorMessage,
    bool clearError = false,
    bool? otpSent,
    String? otpMobile,
  }) {
    return AuthState(
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      otpSent: otpSent ?? this.otpSent,
      otpMobile: otpMobile ?? this.otpMobile,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._repo) : super(const AuthState());

  final AuthRepository _repo;

  Future<bool> login({
    required String username,
    required String password,
  }) async {
    state = state.copyWith(
      status: AuthStatus.loading,
      clearError: true,
    );
    try {
      await _repo.login(username: username, password: password);
      state = state.copyWith(status: AuthStatus.authenticated);
      return true;
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

  Future<bool> sendOtp(String mobile) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);
    try {
      await _repo.sendOtp(mobile);
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        otpSent: true,
        otpMobile: mobile.trim(),
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

  /// Returns true if fully logged into the app (has Application Password stored).
  /// If OTP ok but no App Password yet, returns false and sets message.
  Future<bool> verifyOtp({
    required String mobile,
    required String code,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);
    try {
      final result = await _repo.verifyOtp(mobile: mobile, code: code);
      if (result.loggedIn) {
        state = state.copyWith(status: AuthStatus.authenticated);
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

  Future<void> logout() async {
    await _repo.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  final storage = ref.watch(secureStorageProvider);
  return AuthRepository(api, storage);
});

final authProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});
