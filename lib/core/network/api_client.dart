import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/api_config.dart';
import '../storage/secure_storage_service.dart';
import '../debug/debug_log_service.dart';
import 'api_exception.dart';

class ApiClient {
  late final Dio _dio;
  final SecureStorageService _storage;
  final DebugLogService _log = DebugLogService.instance;

  // Keep the per-device bearer token in memory after the first secure-storage
  // read. Dashboard screens can issue several requests at once, so reading
  // encrypted storage for every request adds avoidable local I/O.
  String? _cachedAccessToken;
  bool _accessTokenLoaded = false;

  final Map<String, Future<Response>> _inFlightGets = {};

  ApiClient(this._storage) {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.wpBaseUrl,
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: _onRequest,
        onResponse: _onResponse,
        onError: _onError,
      ),
    );

    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          requestHeader: false,
          requestBody: false,
          responseHeader: false,
          responseBody: false,
          error: true,
        ),
      );
    }

    // Remote debug center (plugin module)
    _log.remoteUploader = _uploadDebugBatch;
    _log.startRemoteFlush();
    unawaited(_log.ensureDeviceId());
  }

  Future<bool> _uploadDebugBatch(Map<String, dynamic> payload) async {
    try {
      // Use a bare request path; token interceptor still applies.
      final res = await _dio.post(
        '/wp-json/ezlens/v1/manager/debug/ingest',
        data: payload,
        options: Options(
          extra: {'ezlens_skip_debug_log': true},
          sendTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 20),
        ),
      );
      return res.statusCode != null &&
          res.statusCode! >= 200 &&
          res.statusCode! < 300;
    } catch (_) {
      return false;
    }
  }

  /// Update the in-memory authentication token after login without forcing
  /// the next API request to hit secure storage again.
  void setAccessToken(String token) {
    _cachedAccessToken = token.trim().isEmpty ? null : token.trim();
    _accessTokenLoaded = true;
  }

  /// Clear the in-memory authentication token after logout.
  void clearAccessToken() {
    _cachedAccessToken = null;
    _accessTokenLoaded = true;
  }

  Future<String?> _getAccessToken() async {
    if (_accessTokenLoaded) return _cachedAccessToken;
    _cachedAccessToken = await _storage.getAccessToken();
    _accessTokenLoaded = true;
    return _cachedAccessToken;
  }

  // ============================================================
  // Request Interceptor
  // ============================================================

  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    options.extra['ezlens_started_at'] = DateTime.now().microsecondsSinceEpoch;

    final token = await _getAccessToken();
    final hasExistingAuth = options.headers.containsKey('Authorization');

    if (!hasExistingAuth) {
      final u = await _storage.getWpUsername();
      final p = await _storage.getWpAppPassword();
      final user = (u != null && u.isNotEmpty) ? u : ApiConfig.wpUsername;
      final pass = (p != null && p.isNotEmpty) ? p : ApiConfig.wpAppPassword;

      if (token != null &&
          token.isNotEmpty &&
          !token.startsWith('dev_session_')) {
        options.headers['Authorization'] = 'Bearer $token';
        options.headers['X-EzLens-Token'] = token;
      } else if (user.isNotEmpty && pass.isNotEmpty) {
        options.headers['Authorization'] =
            'Basic ' + base64Encode(utf8.encode('$user:$pass'));
      }
    } else if (token != null &&
        token.isNotEmpty &&
        !token.startsWith('dev_session_')) {
      // Ensure custom header even when Authorization already set (e.g. by wcGet).
      options.headers['X-EzLens-Token'] = token;
    }

    // Query fallback when host strips Authorization (LiteSpeed etc.).
    if (token != null &&
        token.isNotEmpty &&
        !token.startsWith('dev_session_')) {
      options.queryParameters = {
        ...options.queryParameters,
        'ezlens_token': token,
      };
    }

    // WooCommerce: always attach API keys in query (most reliable auth).
    final path = options.path;
    if (path.contains('/wc/') || path.contains('/wp-json/wc/')) {
      final key = ApiConfig.wcConsumerKey.trim();
      final secret = ApiConfig.wcConsumerSecret.trim();
      if (key.isNotEmpty && secret.isNotEmpty) {
        options.queryParameters = {
          ...options.queryParameters,
          'consumer_key': key,
          'consumer_secret': secret,
        };
      }
    }

    handler.next(options);
  }

  // ============================================================
  // Response Interceptor
  // ============================================================

  void _onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) async {
    final started = response.requestOptions.extra['ezlens_started_at'];
    int ms = 0;
    if (started is int) {
      ms = ((DateTime.now().microsecondsSinceEpoch - started) / 1000).round();
    }
    int? bytes;
    try {
      final d = response.data;
      if (d is String) {
        bytes = d.length;
      } else if (d != null) {
        bytes = d.toString().length;
      }
    } catch (_) {}
    final screen = response.requestOptions.extra['ezlens_screen']?.toString();
    unawaited(_log.logApi(
      method: response.requestOptions.method,
      path: response.requestOptions.path,
      durationMs: ms,
      status: response.statusCode,
      screen: screen,
      bytes: bytes,
    ));
    handler.next(response);
  }

  // ============================================================
  // Error Interceptor
  // ============================================================

  Future<void> _onError(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    final started = error.requestOptions.extra['ezlens_started_at'];
    int ms = 0;
    if (started is int) {
      ms = ((DateTime.now().microsecondsSinceEpoch - started) / 1000).round();
    }
    final detail = error.message ??
        (error.error?.toString() ?? error.type.name);
    final screen = error.requestOptions.extra['ezlens_screen']?.toString();
    String? bodyHint;
    final data = error.response?.data;
    if (data is Map && data['message'] != null) {
      bodyHint = data['message'].toString();
    } else if (data is String && data.isNotEmpty) {
      bodyHint = data.length > 200 ? '${data.substring(0, 200)}…' : data;
    }
    unawaited(_log.logApi(
      method: error.requestOptions.method,
      path: error.requestOptions.path,
      durationMs: ms,
      status: error.response?.statusCode,
      screen: screen,
      error: bodyHint ?? detail,
    ));
    final exception = _mapDioError(error);

    handler.reject(
      DioException(
        requestOptions: error.requestOptions,
        error: exception,
        type: error.type,
        response: error.response,
      ),
    );
  }

  ApiException _mapDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkException(
          message: 'زمان اتصال به سرور به پایان رسید',
        );

      case DioExceptionType.connectionError:
        return NetworkException(
          message: kIsWeb
              ? 'ارتباط وب با API برقرار نشد؛ CORS، SSL یا شبکه را بررسی کنید.'
              : 'خطا در اتصال به شبکه',
        );

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final data = error.response?.data;

        String message = 'خطای ناشناخته';

        if (data is Map && data['message'] != null) {
          message = data['message'].toString();
        } else if (data is Map && data['error'] != null) {
          message = data['error'].toString();
        }

        if (statusCode == 401) {
          return UnauthorizedException(
            message: message,
          );
        }

        return ApiException(
          message: message,
          statusCode: statusCode,
        );

      default:
        return ApiException(
          message: error.message ?? 'خطای ناشناخته',
        );
    }
  }

  // ============================================================
  // API عمومی با Token
  // ============================================================

  String _getDedupeKey(String path, Map<String, dynamic>? queryParameters) {
    final q = Map<String, dynamic>.from(queryParameters ?? const {});
    q.remove('ezlens_token');
    q.remove('consumer_key');
    q.remove('consumer_secret');
    final keys = q.keys.map((k) => k.toString()).toList()..sort();
    final parts = <String>[];
    for (final k in keys) {
      parts.add('$k=${q[k]}');
    }
    return 'GET|$path|${parts.join('&')}';
  }

  Future<Response<T>> _dedupedGet<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    final key = _getDedupeKey(path, queryParameters);
    final existing = _inFlightGets[key];
    if (existing != null) {
      return existing.then((r) => r as Response<T>);
    }
    final future = _dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
    );
    _inFlightGets[key] = future.then((r) => r as Response);
    future.whenComplete(() => _inFlightGets.remove(key));
    return future;
  }


  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dedupedGet<T>(
      path,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.put<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response<T>> delete<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.delete<T>(
      path,
      queryParameters: queryParameters,
      options: options,
    );
  }

  // ============================================================
  // احراز هویت WordPress Application Password
  // ============================================================

  /// WordPress REST / media: Application Password (Basic) only.
  /// Manager Bearer is NOT valid for /wp/v2 or media upload.
  Future<String> _wpAuth() async {
    final storedUser = await _storage.getWpUsername();
    final storedPass = await _storage.getWpAppPassword();
    final u = (storedUser != null && storedUser.isNotEmpty)
        ? storedUser
        : ApiConfig.wpUsername;
    final p = (storedPass != null && storedPass.isNotEmpty)
        ? storedPass
        : ApiConfig.wpAppPassword;
    final raw = '$u:$p';
    return 'Basic ' + base64Encode(utf8.encode(raw));
  }


  Future<Map<String, String>> _authHeaders({required bool wooCommerce}) async {
    final token = await _getAccessToken();
    // Manager Bearer authenticates the WP admin for both WP and WC REST.
    if (token != null &&
        token.isNotEmpty &&
        !token.startsWith('dev_session_')) {
      return {
        'Authorization': 'Bearer $token',
        'X-EzLens-Token': token,
      };
    }

    if (wooCommerce) {
      final key = ApiConfig.wcConsumerKey.trim();
      final secret = ApiConfig.wcConsumerSecret.trim();
      if (key.isNotEmpty && secret.isNotEmpty) {
        return {
          'Authorization':
              'Basic ' + base64Encode(utf8.encode('$key:$secret')),
        };
      }
    }

    final auth = await _wpAuth();
    return {'Authorization': auth};
  }

  // ============================================================
  // WooCommerce GET
  // ============================================================

  Future<Response<T>> wcGet<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final q = <String, dynamic>{...?queryParameters};
    final key = ApiConfig.wcConsumerKey.trim();
    final secret = ApiConfig.wcConsumerSecret.trim();
    if (key.isNotEmpty && secret.isNotEmpty) {
      q.putIfAbsent('consumer_key', () => key);
      q.putIfAbsent('consumer_secret', () => secret);
    }
    final token = await _getAccessToken();
    if (token != null &&
        token.isNotEmpty &&
        !token.startsWith('dev_session_')) {
      q.putIfAbsent('ezlens_token', () => token);
    }
    return _dedupedGet<T>(
      path,
      queryParameters: q,
      options: Options(
        headers: {
          ...await _authHeaders(wooCommerce: true),
        },
      ),
    );
  }

  // ============================================================
  // WooCommerce POST
  // ============================================================

  Future<Response<T>> wcPost<T>(
    String path, {
    dynamic data,
  }) async {
    return _dio.post<T>(
      path,
      data: data,
      options: Options(
        headers: {
          ...await _authHeaders(wooCommerce: true),
        },
      ),
    );
  }

  // ============================================================
  // WooCommerce PUT
  // ============================================================

  Future<Response<T>> wcPut<T>(
    String path, {
    dynamic data,
  }) async {
    return _dio.put<T>(
      path,
      data: data,
      options: Options(
        headers: {
          ...await _authHeaders(wooCommerce: true),
        },
      ),
    );
  }

  // ============================================================
  // WooCommerce DELETE
  // ============================================================

  Future<Response<T>> wcDelete<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    return _dio.delete<T>(
      path,
      queryParameters: queryParameters,
      options: Options(
        headers: {
          ...await _authHeaders(wooCommerce: true),
        },
      ),
    );
  }

  // ============================================================
  // WordPress GET (با Application Password)
  // ============================================================

  Future<Response<T>> wpGet<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    return _dedupedGet<T>(
      path,
      queryParameters: queryParameters,
      options: Options(
        headers: {
          ...await _authHeaders(wooCommerce: false),
        },
      ),
    );
  }

  // ============================================================
  // WordPress POST (با Application Password)
  // ============================================================

  Future<Response<T>> wpPost<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    return _dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: Options(
        headers: {
          ...await _authHeaders(wooCommerce: false),
        },
      ),
    );
  }

  // ============================================================
  // WordPress PUT (با Application Password)
  // ============================================================

  Future<Response<T>> wpPut<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    return _dio.put<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: Options(
        headers: {
          ...await _authHeaders(wooCommerce: false),
        },
      ),
    );
  }

  // ============================================================
  // WordPress DELETE (با Application Password)
  // ============================================================

  Future<Response<T>> wpDelete<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    return _dio.delete<T>(
      path,
      queryParameters: queryParameters,
      options: Options(
        headers: {
          ...await _authHeaders(wooCommerce: false),
        },
      ),
    );
  }

  // ============================================================
  // آپلود فایل
  // ============================================================

  Future<Response<T>> uploadMedia<T>(
    String path, {
    required FormData formData,
    void Function(int sent, int total)? onSendProgress,
  }) async {
    final auth = await _wpAuth();

    return _dio.post<T>(
      path,
      data: formData,
      onSendProgress: onSendProgress,
      options: Options(
        headers: {
          'Authorization': auth,
        },
      ),
    );
  }
}