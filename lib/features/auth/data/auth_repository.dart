import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../core/config/api_config.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/storage/secure_storage_service.dart';

class AuthRepository {
  final ApiClient _api;
  final SecureStorageService _storage;

  AuthRepository(this._api, this._storage);

  /// WordPress Application Password login (REST Basic auth).
  /// Use WP Admin → Users → Profile → Application Passwords — NOT the account password.
  Future<void> login({
    required String username,
    required String password,
  }) async {
    final u = username.trim();
    // Keep internal spaces in Application Password (xxxx xxxx xxxx xxxx)
    final p = password.trim();
    if (u.isEmpty || p.isEmpty) {
      throw ApiException(message: 'نام کاربری و رمز عبور را وارد کنید');
    }

    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.wpBaseUrl,
        connectTimeout: const Duration(seconds: 25),
        receiveTimeout: const Duration(seconds: 25),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Basic ${base64Encode(utf8.encode('$u:$p'))}',
        },
      ),
    );

    try {
      final res = await dio.get('/wp-json/wp/v2/users/me');
      if (res.statusCode != 200) {
        throw ApiException(message: 'ورود ناموفق بود');
      }
      final data = res.data;
      if (data is Map) {
        await _storage.saveUserData(jsonEncode(data));
      } else {
        await _storage.saveUserData('{"username":"$u"}');
      }
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (code == 401 || code == 403) {
        throw ApiException(
          message:
              'نام کاربری یا Application Password نادرست است.\n'
              'رمز حساب وردپرس را وارد نکنید؛ از مسیر:\n'
              'پیشخوان ← کاربران ← شناسنامه ← Application Passwords\n'
              'یک رمز بسازید و همان را وارد کنید.',
        );
      }
      throw ApiException(
        message: e.message?.isNotEmpty == true
            ? 'ارتباط با سرور: ${e.message}'
            : 'ارتباط با سرور برقرار نشد',
      );
    }

    await _storage.saveWpCredentials(username: u, appPassword: p);
    await _storage.saveAccessToken(
      'session_${DateTime.now().millisecondsSinceEpoch}',
    );
    // keep analyzer happy
    assert(_api.hashCode >= 0);
  }

  /// Send OTP via EzLens plugin (admin-ajax ezlens_otp_send).
  Future<void> sendOtp(String mobile) async {
    final m = _normalizeMobile(mobile);
    if (m.length < 10) {
      throw ApiException(message: 'شماره موبایل معتبر وارد کنید');
    }
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.wpBaseUrl,
        connectTimeout: const Duration(seconds: 25),
        receiveTimeout: const Duration(seconds: 25),
        headers: {'Accept': 'application/json'},
      ),
    );
    try {
      final res = await dio.post(
        '/wp-admin/admin-ajax.php',
        data: FormData.fromMap({
          'action': 'ezlens_otp_send',
          'mobile': m,
        }),
      );
      final body = res.data;
      if (body is Map && body['success'] == false) {
        final msg = body['data'] is Map
            ? (body['data']['message']?.toString() ?? 'ارسال کد ناموفق')
            : (body['data']?.toString() ?? 'ارسال کد ناموفق');
        throw ApiException(message: msg);
      }
    } on DioException catch (e) {
      throw ApiException(
        message: e.message ?? 'ارسال کد تأیید ناموفق بود',
      );
    }
  }

  /// Verify OTP via EzLens plugin. Manager REST still needs Application Password;
  /// after verify we require the user to complete App Password login if no stored creds.
  Future<OtpVerifyResult> verifyOtp({
    required String mobile,
    required String code,
  }) async {
    final m = _normalizeMobile(mobile);
    final c = code.trim();
    if (c.length < 4) {
      throw ApiException(message: 'کد تأیید را کامل وارد کنید');
    }
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.wpBaseUrl,
        connectTimeout: const Duration(seconds: 25),
        receiveTimeout: const Duration(seconds: 25),
        headers: {'Accept': 'application/json'},
      ),
    );
    try {
      final res = await dio.post(
        '/wp-admin/admin-ajax.php',
        data: FormData.fromMap({
          'action': 'ezlens_otp_verify',
          'mobile': m,
          'code': c,
        }),
      );
      final body = res.data;
      if (body is Map && body['success'] == false) {
        final msg = body['data'] is Map
            ? (body['data']['message']?.toString() ?? 'کد نامعتبر است')
            : (body['data']?.toString() ?? 'کد نامعتبر است');
        throw ApiException(message: msg);
      }
      // OTP proves identity for site session, but manager API needs Application Password.
      final hasAppPass = await _storage.getWpAppPassword();
      final hasUser = await _storage.getWpUsername();
      if (hasAppPass != null &&
          hasAppPass.isNotEmpty &&
          hasUser != null &&
          hasUser.isNotEmpty) {
        await _storage.saveAccessToken(
          'session_${DateTime.now().millisecondsSinceEpoch}',
        );
        return OtpVerifyResult(loggedIn: true, mobile: m);
      }
      return OtpVerifyResult(loggedIn: false, mobile: m);
    } on DioException catch (e) {
      throw ApiException(message: e.message ?? 'تأیید کد ناموفق بود');
    }
  }

  String _normalizeMobile(String raw) {
    var m = raw.trim().replaceAll(RegExp(r'[\s\-]'), '');
    m = m.replaceAll(RegExp(r'[^\d+]'), '');
    if (m.startsWith('+98')) m = '0${m.substring(3)}';
    if (m.startsWith('98') && m.length >= 12) m = '0${m.substring(2)}';
    return m;
  }

  Future<void> logout() async {
    await _storage.clearSession();
  }

  Future<bool> isLoggedIn() => _storage.hasValidSession();
}

class OtpVerifyResult {
  final bool loggedIn;
  final String mobile;
  OtpVerifyResult({required this.loggedIn, required this.mobile});
}
