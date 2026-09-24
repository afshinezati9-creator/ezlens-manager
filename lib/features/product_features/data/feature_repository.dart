import '../../../core/network/api_client.dart';
import '../../../core/network/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'feature_models.dart';

final productFeatureRepositoryProvider =
    Provider<ProductFeatureRepository>((ref) {
  return ProductFeatureRepository(ref.watch(apiClientProvider));
});

class ProductFeatureRepository {
  final ApiClient _api;

  ProductFeatureRepository(this._api);

  static const _base = '/wp-json/ezlens/v1/product-options';

  Future<ProductFeatureListResponse> fetchList({
    int page = 1,
    int perPage = 20,
    String search = '',
    String status = 'all',
  }) async {
    final response = await _api.wpGet<Map<String, dynamic>>(
      _base,
      queryParameters: {
        'page': page,
        'per_page': perPage,
        if (search.trim().isNotEmpty) 'search': search.trim(),
        if (status.isNotEmpty) 'status': status,
      },
    );
    final data = response.data;
    if (data is Map<String, dynamic>) {
      return ProductFeatureListResponse.fromJson(data);
    }
    throw Exception('پاسخ نامعتبر از API ویژگی‌ها');
  }

  Future<ProductFeature> fetchOne(int id) async {
    final response = await _api.wpGet<Map<String, dynamic>>('$_base/$id');
    final data = response.data;
    if (data is Map<String, dynamic>) {
      return ProductFeature.fromJson(data);
    }
    throw Exception('ویژگی یافت نشد');
  }

  Future<ProductFeature> save(ProductFeature feature) async {
    final body = feature.toJson();
    final Map<String, dynamic>? data;

    if (feature.id > 0) {
      final res = await _api.wpPut<Map<String, dynamic>>(
        '$_base/${feature.id}',
        data: body,
      );
      data = res.data is Map<String, dynamic>
          ? res.data as Map<String, dynamic>
          : null;
    } else {
      final res = await _api.wpPost<Map<String, dynamic>>(_base, data: body);
      data = res.data is Map<String, dynamic>
          ? res.data as Map<String, dynamic>
          : null;
    }

    if (data == null) throw Exception('خطا در ذخیره ویژگی');

    if (data['item'] is Map) {
      return ProductFeature.fromJson(
        Map<String, dynamic>.from(data['item'] as Map),
      );
    }
    return ProductFeature.fromJson(data);
  }

  Future<void> delete(int id) async {
    await _api.wpDelete('$_base/$id');
  }

  Future<List<ProductFeatureSlot>> fetchProductSlots(int productId) async {
    final response = await _api.wpGet<Map<String, dynamic>>(
      '/wp-json/ezlens/v1/products/$productId/option-slots',
    );

    final dynamic data = response.data;
    final slots = <ProductFeatureSlot>[];

    // ✅ Fix: چک nullable + type-safe
    if (data is Map<String, dynamic>) {
      final rawSlots = data['slots'];
      if (rawSlots is List) {
        for (final e in rawSlots) {
          if (e is Map) {
            slots.add(
              ProductFeatureSlot.fromJson(Map<String, dynamic>.from(e)),
            );
          }
        }
      }
    }
    return slots;
  }

  Future<void> saveProductSlots(
    int productId,
    List<ProductFeatureSlot> slots,
  ) async {
    await _api.wpPost(
      '/wp-json/ezlens/v1/products/$productId/option-slots',
      data: {
        'slots': slots.map((s) => s.toJson()).toList(),
      },
    );
  }
}