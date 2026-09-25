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
    final isWooCommerce = options.path.contains('/wp-json/wc/');

    final hasExistingAuth =
        options.headers.containsKey('Authorization');

    if (!hasExistingAuth) {
      final token = await _getAccessToken();
      if (token != null && token.isNotEmpty && !token.startsWith('dev_session_')) {
        options.headers['Authorization'] = 'Bearer $token';
        options.headers['X-EzLens-Token'] = token;
      } else {
        final u = await _storage.getWpUsername();
        final p = await _storage.getWpAppPassword();
        final user = (u != null && u.isNotEmpty) ? u : ApiConfig.wpUsername;
        final pass = (p != null && p.isNotEmpty) ? p : ApiConfig.wpAppPassword;
        if (user.isNotEmpty && pass.isNotEmpty) {
          options.headers['Authorization'] =
              'Basic ' + base64Encode(utf8.encode(user + ':' + pass));
        }
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
    if (started is int) {
      final ms = (DateTime.now().microsecondsSinceEpoch - started) / 1000;
      unawaited(_log.log('API ${response.requestOptions.method} ${response.requestOptions.path} → ${response.statusCode} in ${ms.toStringAsFixed(0)}ms'));
    }
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
    if (started is int) {
      final ms = (DateTime.now().microsecondsSinceEpoch - started) / 1000;
      unawaited(_log.log('API ERROR ${error.requestOptions.method} ${error.requestOptions.path} → ${error.response?.statusCode ?? error.type.name} in ${ms.toStringAsFixed(0)}ms', level: 'ERROR'));
    }
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
        return NetworkException();

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

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.get<T>(
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

  /// Prefer credentials saved at login; fall back to ApiConfig constants.
  Future<String> _wpAuth() async {
    // Prefer the per-device Manager bearer token. This prevents one device
    // from invalidating another device's session.
    final token = await _getAccessToken();
    if (token != null && token.isNotEmpty && !token.startsWith('dev_session_')) {
      return 'Bearer ' + token;
    }

    // Legacy/demo fallback only.
    final storedUser = await _storage.getWpUsername();
    final storedPass = await _storage.getWpAppPassword();
    final u = (storedUser != null && storedUser.isNotEmpty)
        ? storedUser
        : ApiConfig.wpUsername;
    final p = (storedPass != null && storedPass.isNotEmpty)
        ? storedPass
        : ApiConfig.wpAppPassword;
    final raw = u + ':' + p;
    return 'Basic ' + base64Encode(utf8.encode(raw));
  }


  Future<Map<String, String>> _authHeaders() async {
    final token = await _storage.getAccessToken();
    if (token != null && token.isNotEmpty && !token.startsWith('dev_session_')) {
      return {
        'Authorization': 'Bearer $token',
        'X-EzLens-Token': token,
      };
    }
    return {'Authorization': await _wpAuth()};
  }

  // ============================================================
  // WooCommerce GET
  // ============================================================

  Future<Response<T>> wcGet<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    return _dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: Options(
        headers: {
          ...await _authHeaders(),
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
          ...await _authHeaders(),
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
          ...await _authHeaders(),
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
          ...await _authHeaders(),
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
    return _dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: Options(
        headers: {
          ...await _authHeaders(),
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
          ...await _authHeaders(),
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
          ...await _authHeaders(),
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
          ...await _authHeaders(),
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