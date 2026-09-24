import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/api_config.dart';
import '../storage/secure_storage_service.dart';
import 'api_exception.dart';

class ApiClient {
  late final Dio _dio;
  final SecureStorageService _storage;

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
          requestBody: true,
          responseBody: true,
          error: true,
        ),
      );
    }
  }

  // ============================================================
  // Request Interceptor
  // ============================================================

  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final isWooCommerce = options.path.contains('/wp-json/wc/');

    final hasExistingAuth =
        options.headers.containsKey('Authorization');

    if (!isWooCommerce && !hasExistingAuth) {
      final token = await _storage.getAccessToken();

      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
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
  ) {
    handler.next(response);
  }

  // ============================================================
  // Error Interceptor
  // ============================================================

  Future<void> _onError(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
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

  String _wpAuth() {
    final raw =
        '${ApiConfig.wpUsername}:${ApiConfig.wpAppPassword}';

    return 'Basic ${base64Encode(
      utf8.encode(raw),
    )}';
  }

  // ============================================================
  // WooCommerce GET
  // ============================================================

  Future<Response<T>> wcGet<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) {
    return _dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: Options(
        headers: {
          'Authorization': _wpAuth(),
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
  }) {
    return _dio.post<T>(
      path,
      data: data,
      options: Options(
        headers: {
          'Authorization': _wpAuth(),
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
  }) {
    return _dio.put<T>(
      path,
      data: data,
      options: Options(
        headers: {
          'Authorization': _wpAuth(),
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
  }) {
    return _dio.delete<T>(
      path,
      queryParameters: queryParameters,
      options: Options(
        headers: {
          'Authorization': _wpAuth(),
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
  }) {
    return _dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: Options(
        headers: {
          'Authorization': _wpAuth(),
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
  }) {
    return _dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: Options(
        headers: {
          'Authorization': _wpAuth(),
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
  }) {
    return _dio.put<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: Options(
        headers: {
          'Authorization': _wpAuth(),
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
  }) {
    return _dio.delete<T>(
      path,
      queryParameters: queryParameters,
      options: Options(
        headers: {
          'Authorization': _wpAuth(),
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
  }) {
    final raw =
        '${ApiConfig.wpUsername}:${ApiConfig.wpAppPassword}';

    final auth = 'Basic ${base64Encode(
      utf8.encode(raw),
    )}';

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