import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/debug/debug_log_service.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/providers.dart';
import 'feature_models.dart';

final productFeatureRepositoryProvider =
    Provider<ProductFeatureRepository>((ref) {
  return ProductFeatureRepository(ref.watch(apiClientProvider));
});

class ProductFeatureRepository {
  final ApiClient _api;
  final _log = DebugLogService.instance;

  ProductFeatureRepository(this._api);

  static const _base = '/wp-json/ezlens/v1/product-options';

  Map<String, dynamic>? _asMap(dynamic data) {
    if (data == null) return null;
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return null;
  }

  String _friendlyError(Object e, {required String action}) {
    if (e is DioException) {
      final status = e.response?.statusCode;
      final data = e.response?.data;
      String serverMsg = '';
      if (data is Map && data['message'] != null) {
        serverMsg = data['message'].toString();
      } else if (e.error is ApiException) {
        serverMsg = (e.error as ApiException).message;
      } else if (e.message != null) {
        serverMsg = e.message!;
      }
      if (status == 404 || serverMsg.contains('منطبق با URL')) {
        return 'مسیر ویژگی‌های محصول روی سرور پیدا نشد (HTTP 404).\n'
            'پلاگین EzLens را به نسخه ۵.۴.۲۵ یا بالاتر به‌روز کنید، '
            'سپس در وردپرس: تنظیمات → پیوندهای یکتا → ذخیره.\n'
            'جزئیات: $action | $serverMsg';
      }
      if (status == 401 || status == 403) {
        return 'دسترسی به ویژگی محصول مجاز نیست (HTTP $status).\n'
            'با همان حساب مدیر وارد شوید یا دوباره لاگین کنید.\n'
            'جزئیات: $action | $serverMsg';
      }
      if (status != null) {
        return 'خطای سرور در $action (HTTP $status): $serverMsg';
      }
      return 'خطای شبکه در $action: $serverMsg';
    }
    if (e is ApiException) {
      return '${e.message}\nعملیات: $action';
    }
    return 'خطا در $action: $e';
  }

  Future<ProductFeatureListResponse> fetchList({
    int page = 1,
    int perPage = 20,
    String search = '',
    String status = 'all',
  }) async {
    try {
      final response = await _api.wpGet<dynamic>(
        _base,
        queryParameters: {
          'page': page,
          'per_page': perPage,
          if (search.trim().isNotEmpty) 'search': search.trim(),
          if (status.isNotEmpty) 'status': status,
        },
      );

      final data = response.data;

      if (data is List) {
        final items = <ProductFeature>[];
        for (final e in data) {
          if (e is Map) {
            items.add(
              ProductFeature.fromJson(Map<String, dynamic>.from(e)),
            );
          }
        }
        return ProductFeatureListResponse(
          items: items,
          total: items.length,
          page: page,
          perPage: perPage,
        );
      }

      final map = _asMap(data);
      if (map == null) {
        await _log.log(
          'product-options list: empty body → empty list',
          level: 'WARN',
        );
        return ProductFeatureListResponse(
          items: const [],
          total: 0,
          page: page,
          perPage: perPage,
        );
      }

      final root = map.containsKey('items')
          ? map
          : (_asMap(map['data']) ?? _asMap(map['result']) ?? map);

      final parsed = ProductFeatureListResponse.fromJson(root);
      await _log.log(
        'product-options list OK: ${parsed.items.length} items (total=${parsed.total})',
      );
      return parsed;
    } catch (e, st) {
      final msg = _friendlyError(e, action: 'fetchList product-options');
      await _log.logError(msg, stack: st, screen: 'product_features');
      // Re-throw with friendly text so UI can show it (not silent empty).
      throw ApiException(message: msg);
    }
  }

  Future<ProductFeature> fetchOne(int id) async {
    try {
      final response = await _api.wpGet<dynamic>('$_base/$id');
      final map = _asMap(response.data);
      if (map == null) {
        throw ApiException(message: 'ویژگی #$id یافت نشد (پاسخ خالی)');
      }
      final item = _asMap(map['item']) ?? map;
      return ProductFeature.fromJson(item);
    } catch (e, st) {
      final msg = _friendlyError(e, action: 'fetchOne #$id');
      await _log.logError(msg, stack: st, screen: 'product_features');
      throw ApiException(message: msg);
    }
  }

  Future<ProductFeature> save(ProductFeature feature) async {
    final body = feature.toJson();
    try {
      dynamic raw;
      if (feature.id > 0) {
        final res = await _api.wpPut<dynamic>(
          '$_base/${feature.id}',
          data: body,
        );
        raw = res.data;
      } else {
        final res = await _api.wpPost<dynamic>(_base, data: body);
        raw = res.data;
      }

      final map = _asMap(raw);
      if (map == null) {
        throw ApiException(message: 'ذخیره ویژگی پاسخ خالی برگرداند');
      }
      final item = _asMap(map['item']) ?? map;
      return ProductFeature.fromJson(item);
    } catch (e, st) {
      final msg = _friendlyError(e, action: 'save feature');
      await _log.logError(msg, stack: st, screen: 'product_features');
      throw ApiException(message: msg);
    }
  }

  Future<void> delete(int id) async {
    try {
      await _api.wpDelete('$_base/$id');
    } catch (e, st) {
      final msg = _friendlyError(e, action: 'delete #$id');
      await _log.logError(msg, stack: st, screen: 'product_features');
      throw ApiException(message: msg);
    }
  }

  Future<List<ProductFeatureSlot>> fetchProductSlots(int productId) async {
    try {
      final response = await _api.wpGet<dynamic>(
        '/wp-json/ezlens/v1/products/$productId/option-slots',
      );
      final map = _asMap(response.data);
      final slots = <ProductFeatureSlot>[];
      if (map == null) return slots;

      final rawSlots = map['slots'] ?? map['items'] ?? map['data'];
      if (rawSlots is List) {
        for (final e in rawSlots) {
          if (e is Map) {
            slots.add(
              ProductFeatureSlot.fromJson(Map<String, dynamic>.from(e)),
            );
          }
        }
      }
      return slots;
    } catch (e, st) {
      final msg = _friendlyError(
        e,
        action: 'fetchProductSlots product#$productId',
      );
      await _log.logError(msg, stack: st, screen: 'product_form');
      // Soft: product form can continue without slots
      return const [];
    }
  }

  Future<void> saveProductSlots(
    int productId,
    List<ProductFeatureSlot> slots,
  ) async {
    try {
      await _api.wpPost(
        '/wp-json/ezlens/v1/products/$productId/option-slots',
        data: {
          'slots': slots.map((s) => s.toJson()).toList(),
        },
      );
    } catch (e, st) {
      final msg = _friendlyError(
        e,
        action: 'saveProductSlots product#$productId',
      );
      await _log.logError(msg, stack: st, screen: 'product_form');
      throw ApiException(message: msg);
    }
  }
}
