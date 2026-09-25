import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../core/config/api_config.dart';
import '../../../core/debug/debug_log_service.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/storage/secure_storage_service.dart';

/// Auth against EzLens plugin manager REST (ezlens/v1/manager/*).
class AuthRepository {
  final ApiClient _api;
  final SecureStorageService _storage;
  final _log = DebugLogService.instance;

  AuthRepository(this._api, this._storage);

  Dio _dio() => Dio(
        BaseOptions(
          baseUrl: ApiConfig.wpBaseUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
          validateStatus: (s) => s != null && s < 500,
        ),
      );

  /// Normal WP username + account password.
  Future<void> login({
    required String username,
    required String password,
  }) async {
    final u = username.trim();
    final p = password;
    if (u.isEmpty || p.isEmpty) {
      throw ApiException(message: 'نام کاربری و رمز عبور را وارد کنید');
    }

    await _log.log('SERVER LOGIN: ارسال درخواست به endpoint ورود.');
    try {
      final res = await _dio().post(
        '/wp-json/ezlens/v1/manager/login',
        data: {'username': u, 'password': p},
      );
      await _log.log('SERVER LOGIN: پاسخ HTTP ' + (res.statusCode?.toString() ?? 'unknown') + ' دریافت شد.');
      await _persistLoginResponse(res);
      await _log.log('SERVER LOGIN: پاسخ معتبر بود و اطلاعات نشست ذخیره شد.', level: 'SUCCESS');
    } on ApiException catch (e) {
      await _log.log('SERVER LOGIN FAILED: ' + e.message, level: 'ERROR');
      rethrow;
    } on DioException catch (e) {
      await _log.log(
        'SERVER LOGIN NETWORK ERROR: ' + (e.message ?? 'unknown'),
        level: 'ERROR',
      );
      throw ApiException(
        message: e.message ?? 'ارتباط با سرور برقرار نشد',
      );
    }
    assert(_api.hashCode >= 0);
  }

  /// Temporary development access-code login.
  ///
  /// This skips the server master-login endpoint only when
  /// EZLENS_DEMO_LOGIN=true was supplied at build time.
  Future<void> loginWithMasterCode(String code) async {
    final c = code.trim();
    if (c.isEmpty) {
      throw ApiException(message: 'یک مقدار برای ورود وارد کنید');
    }

    if (ApiConfig.demoLoginEnabled) {
      final username = ApiConfig.wpUsername.trim().isNotEmpty
          ? ApiConfig.wpUsername.trim()
          : 'demo-admin';
      final appPassword = ApiConfig.wpAppPassword;

      await _storage.saveWpCredentials(
        username: username,
        appPassword: appPassword,
      );
      await _storage.saveAccessToken(
        'dev_session_' + DateTime.now().millisecondsSinceEpoch.toString(),
      );
      await _storage.saveUserData(jsonEncode({
        'username': username,
        'email': '',
        'display_name': 'EzLens Manager',
        'id': 0,
        'login_mode': 'development',
      }));
      return;
    }

    try {
      final res = await _dio().post(
        '/wp-json/ezlens/v1/manager/master-login',
        data: {'code': c},
      );
      await _persistLoginResponse(res);
    } on ApiException {
      rethrow;
    } on DioException catch (e) {
      throw ApiException(
        message: e.message ?? 'ارتباط با سرور برقرار نشد',
      );
    }
  }

  Future<void> sendOtp(String mobile) async {
    final m = _normalizeMobile(mobile);
    if (m.length < 10) {
      throw ApiException(message: 'شماره موبایل معتبر وارد کنید');
    }
    try {
      final res = await _dio().post(
        '/wp-json/ezlens/v1/manager/otp/send',
        data: {'mobile': m},
      );
      if (res.statusCode == 404) {
        throw ApiException(
          message: 'endpoint OTP مدیریت یافت نشد. پلاگین را به‌روز کنید.',
        );
      }
      final data = res.data;
      if (res.statusCode != null && res.statusCode! >= 400) {
        throw ApiException(message: _err(data) ?? 'ارسال کد ناموفق');
      }
      if (data is Map && data['success'] == false) {
        throw ApiException(message: _err(data) ?? 'ارسال کد ناموفق');
      }
    } on ApiException {
      rethrow;
    } on DioException catch (e) {
      throw ApiException(message: e.message ?? 'ارسال کد تأیید ناموفق بود');
    }
  }

  Future<OtpVerifyResult> verifyOtp({
    required String mobile,
    required String code,
  }) async {
    final m = _normalizeMobile(mobile);
    final c = code.trim();
    if (c.length < 4) {
      throw ApiException(message: 'کد تأیید را کامل وارد کنید');
    }
    try {
      final res = await _dio().post(
        '/wp-json/ezlens/v1/manager/otp/verify',
        data: {'mobile': m, 'code': c},
      );
      if (res.statusCode == 404) {
        throw ApiException(message: 'endpoint تأیید OTP یافت نشد');
      }
      if (res.statusCode != null && res.statusCode! >= 400) {
        throw ApiException(message: _err(res.data) ?? 'کد نامعتبر است');
      }
      await _persistLoginResponse(res);
      return OtpVerifyResult(loggedIn: true, mobile: m);
    } on ApiException {
      rethrow;
    } on DioException catch (e) {
      throw ApiException(message: e.message ?? 'تأیید کد ناموفق بود');
    }
  }

  Future<void> _persistLoginResponse(Response res) async {
    final data = res.data;
    if (res.statusCode == 404) {
      throw ApiException(
        message:
            'مسیر ورود مدیریت یافت نشد. پلاگین EzLens را به‌روز کنید و پیوند یکتا را ذخیره کنید.',
      );
    }
    if (res.statusCode == 401 || res.statusCode == 403) {
      throw ApiException(
          message: _err(data) ?? 'نام کاربری یا رمز عبور نادرست است');
    }
    if (res.statusCode != 200 || data is! Map) {
      throw ApiException(message: _err(data) ?? 'ورود ناموفق بود');
    }
    final map = Map<String, dynamic>.from(data);
    if (map['success'] == false) {
      throw ApiException(message: _err(map) ?? 'ورود ناموفق بود');
    }
    final loginName = (map['username'] ?? '').toString();
    final token = (map['token'] ?? '').toString().trim();
    if (loginName.isEmpty || token.isEmpty) {
      throw ApiException(message: 'پاسخ سرور ناقص بود');
    }
    // Manager authentication is token-based and per-device.
    // Never persist a server-generated application password here.
    await _storage.saveAccessToken(token);
    await _storage.saveUserData(jsonEncode({
      'username': loginName,
      'email': map['user_email'],
      'display_name': map['display_name'],
      'id': map['user_id'],
    }));
  }

  String? _err(dynamic data) {
    if (data is Map) {
      if (data['message'] != null) {
        final m = data['message'].toString();
        return m.replaceAll(RegExp(r'<[^>]*>'), '');
      }
      final d = data['data'];
      if (d is Map && d['message'] != null) return d['message'].toString();
      if (data['error'] != null) return data['error'].toString();
    }
    return null;
  }

  String _normalizeMobile(String raw) {
    var m = raw.trim().replaceAll(RegExp(r'[\s\-]'), '');
    m = m.replaceAll(RegExp(r'[^\d+]'), '');
    if (m.startsWith('+98')) m = '0${m.substring(3)}';
    if (m.startsWith('98') && m.length >= 12) m = '0${m.substring(2)}';
    return m;
  }

  Future<void> logout() async {
    final token = await _storage.getAccessToken();
    if (token != null && token.isNotEmpty && !token.startsWith('dev_session_')) {
      try {
        await _dio().post(
          '/wp-json/ezlens-app/v1/auth/logout',
          options: Options(headers: {'Authorization': 'Bearer $token'}),
        );
      } catch (_) {
        // Local logout must still work if the server is temporarily unreachable.
      }
    }
    await _storage.clearSession();
  }

  Future<bool> isLoggedIn() => _storage.hasValidSession();
}

class OtpVerifyResult {
  final bool loggedIn;
  final String mobile;
  OtpVerifyResult({required this.loggedIn, required this.mobile});
}
