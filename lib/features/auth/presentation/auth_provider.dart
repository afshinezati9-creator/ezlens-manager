import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/api_config.dart';
import '../../../core/debug/debug_log_service.dart';
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
  final _log = DebugLogService.instance;

  Future<void> _checkSession() async {
    await _log.log('AUTH START: بررسی وضعیت نشست آغاز شد.');
    try {
      if (ApiConfig.demoLoginEnabled) {
        await _log.log('AUTH MODE: حالت توسعه فعال است؛ صفحه ورود نمایش داده می‌شود.');
        state = const AuthState(status: AuthStatus.unauthenticated);
        await _log.log('AUTH READY: کاربر هنوز وارد نشده است.');
        return;
      }

      final loggedIn = await _repository.isLoggedIn();
      await _log.log(
        'AUTH SESSION: ' +
            (loggedIn
                ? 'نشست معتبر پیدا شد.'
                : 'نشست معتبری پیدا نشد؛ ورود لازم است.'),
      );
      state = AuthState(
        status:
            loggedIn ? AuthStatus.authenticated : AuthStatus.unauthenticated,
        biometricUnlocked: false,
      );
    } catch (e, st) {
      await _log.log('AUTH SESSION ERROR: ' + e.toString(), level: 'ERROR');
      await _log.log('AUTH STACK: ' + st.toString(), level: 'ERROR');
      state = const AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: 'بررسی نشست انجام نشد؛ لطفاً دوباره وارد شوید.',
      );
    }
  }

  Future<bool> login({
    required String username,
    required String password,
  }) async {
    await _log.log('LOGIN: تلاش ورود با نام کاربری شروع شد.');
    state = state.copyWith(status: AuthStatus.loading, clearError: true);
    try {
      await _repository.login(username: username, password: password);
      state = const AuthState(
        status: AuthStatus.authenticated,
        biometricUnlocked: true,
      );
      await _log.log('LOGIN SUCCESS: ورود با نام کاربری و رمز عبور موفق بود.', level: 'SUCCESS');
      return true;
    } on ApiException catch (e) {
      await _log.log('LOGIN FAILED: ' + e.message, level: 'ERROR');
      state = AuthState(status: AuthStatus.error, errorMessage: e.message);
      return false;
    } catch (e, st) {
      await _log.log('LOGIN EXCEPTION: ' + e.toString(), level: 'ERROR');
      await _log.log('LOGIN STACK: ' + st.toString(), level: 'ERROR');
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
      await _repository.verifyOtp(mobile: mobile, code: code);
      state = const AuthState(
        status: AuthStatus.authenticated,
        biometricUnlocked: true,
      );
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


  Future<bool> loginWithMasterCode(String code) async {
    await _log.log('ACCESS CODE: تلاش ورود با کد دسترسی شروع شد.');
    state = state.copyWith(status: AuthStatus.loading, clearError: true);
    try {
      await _repository.loginWithMasterCode(code);
      state = const AuthState(
        status: AuthStatus.authenticated,
        biometricUnlocked: true,
      );
      await _log.log('ACCESS CODE SUCCESS: ورود با کد دسترسی موفق بود.', level: 'SUCCESS');
      return true;
    } on ApiException catch (e) {
      await _log.log('ACCESS CODE FAILED: ' + e.message, level: 'ERROR');
      state = AuthState(status: AuthStatus.error, errorMessage: e.message);
      return false;
    } catch (e, st) {
      await _log.log('ACCESS CODE EXCEPTION: ' + e.toString(), level: 'ERROR');
      await _log.log('ACCESS CODE STACK: ' + st.toString(), level: 'ERROR');
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
