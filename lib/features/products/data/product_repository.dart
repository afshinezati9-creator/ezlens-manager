// lib/features/products/data/product_repository.dart

import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';
import 'product_models.dart';

class ProductRepository {
  final ApiClient _api;

  ProductRepository(this._api);

  // ===== دریافت لیست محصولات =====
  Future<List<Product>> fetchProducts({
    int page = 1,
    int perPage = 5,
    String? search,
    int? categoryId,
    int? tagId,
    int? brandId,
    String? status,
    String? orderby = 'date',
    String? order = 'desc',
  }) async {
    final params = {
      'page': page,
      'per_page': perPage,
      if (search != null && search.isNotEmpty) 'search': search,
      if (categoryId != null) 'category': categoryId,
      if (tagId != null) 'tag': tagId,
      if (brandId != null) 'product_brand': brandId,
      if (status != null && status.isNotEmpty) 'status': status,
      'orderby': orderby ?? 'date',
      'order': order ?? 'desc',
    };

    final response = await _api.wcGet<List<dynamic>>(
      '/wp-json/wc/v3/products',
      queryParameters: params,
    );
    return (response.data ?? [])
        .map((e) => Product.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ===== دریافت یک محصول =====
  Future<Product> fetchProduct(int id) async {
    final response = await _api.wcGet<Map<String, dynamic>>(
      '/wp-json/wc/v3/products/$id',
    );
    return Product.fromJson(response.data as Map<String, dynamic>);
  }

  // ===== ایجاد محصول =====
  Future<Product> createProduct(Map<String, dynamic> data) async {
    if (kDebugMode) {
      debugPrint('📦 CREATE PRODUCT — keys: ${data.keys.toList()}');
      debugPrint('   name: ${data['name']}');
      debugPrint(
          '   description length: ${(data['description'] ?? '').toString().length}');
      debugPrint('   meta_data: ${data['meta_data']}');
    }

    final response = await _api.wcPost<Map<String, dynamic>>(
      '/wp-json/wc/v3/products',
      data: data,
    );

    if (kDebugMode) {
      debugPrint('✅ PRODUCT CREATED — id: ${response.data?['id']}');
    }

    return Product.fromJson(response.data as Map<String, dynamic>);
  }

  // ===== ویرایش محصول =====
  Future<Product> updateProduct(int id, Map<String, dynamic> data) async {
    if (kDebugMode) {
      debugPrint('📦 UPDATE PRODUCT #$id — keys: ${data.keys.toList()}');
      debugPrint('   name: ${data['name']}');
      debugPrint(
          '   description length: ${(data['description'] ?? '').toString().length}');
      debugPrint('   meta_data: ${data['meta_data']}');
    }

    final response = await _api.wcPut<Map<String, dynamic>>(
      '/wp-json/wc/v3/products/$id',
      data: data,
    );

    if (kDebugMode) {
      debugPrint('✅ PRODUCT UPDATED — id: ${response.data?['id']}');
    }

    return Product.fromJson(response.data as Map<String, dynamic>);
  }

  // ===== حذف محصول =====
  Future<void> deleteProduct(int id) async {
    await _api.wcDelete(
      '/wp-json/wc/v3/products/$id',
      queryParameters: {'force': true},
    );
  }

  // ===== دسته‌بندی‌ها =====
  Future<List<ProductCategory>> fetchCategories() async {
    List<ProductCategory> allCategories = [];
    int page = 1;
    bool hasMore = true;

    while (hasMore) {
      try {
        final response = await _api.wcGet<List<dynamic>>(
          '/wp-json/wc/v3/products/categories',
          queryParameters: {'per_page': 100, 'page': page},
        );
        final data = response.data ?? [];
        if (data.isEmpty) {
          hasMore = false;
        } else {
          allCategories.addAll(
            data.map(
              (e) => ProductCategory.fromJson(e as Map<String, dynamic>),
            ),
          );
          if (data.length < 100) {
            hasMore = false;
          } else {
            page++;
          }
        }
      } catch (e) {
        if (allCategories.isEmpty) rethrow;
        break;
      }
    }
    return allCategories;
  }

  // ===== تگ‌ها =====
  Future<List<ProductTag>> fetchTags() async {
    List<ProductTag> allTags = [];
    int page = 1;
    bool hasMore = true;

    while (hasMore) {
      try {
        final response = await _api.wcGet<List<dynamic>>(
          '/wp-json/wc/v3/products/tags',
          queryParameters: {'per_page': 100, 'page': page},
        );
        final data = response.data ?? [];
        if (data.isEmpty) {
          hasMore = false;
        } else {
          allTags.addAll(
            data.map(
              (e) => ProductTag.fromJson(e as Map<String, dynamic>),
            ),
          );
          if (data.length < 100) {
            hasMore = false;
          } else {
            page++;
          }
        }
      } catch (e) {
        if (allTags.isEmpty) rethrow;
        break;
      }
    }
    return allTags;
  }

  // ===== برندها =====
  Future<List<ProductTag>> fetchBrands() async {
    try {
      final response = await _api.wcGet<List<dynamic>>(
        '/wp-json/wc/v3/products/brands',
        queryParameters: {'per_page': 100},
      );
      return (response.data ?? [])
          .map((e) => ProductTag.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      final response = await _api.wcGet<List<dynamic>>(
        '/wp-json/wp/v2/product_brand',
        queryParameters: {'per_page': 100},
      );
      return (response.data ?? [])
          .map((e) => ProductTag.fromJson(e as Map<String, dynamic>))
          .toList();
    }
  }

  // ===== ایجاد دسته‌بندی =====
  Future<ProductCategory> createCategory(Map<String, dynamic> data) async {
    final response = await _api.wcPost<Map<String, dynamic>>(
      '/wp-json/wc/v3/products/categories',
      data: data,
    );
    return ProductCategory.fromJson(response.data as Map<String, dynamic>);
  }

  // ===== ایجاد برند =====
  Future<ProductTag> createBrand(Map<String, dynamic> data) async {
    try {
      final response = await _api.wcPost<Map<String, dynamic>>(
        '/wp-json/wc/v3/products/brands',
        data: data,
      );
      return ProductTag.fromJson(response.data as Map<String, dynamic>);
    } catch (_) {
      final response = await _api.wcPost<Map<String, dynamic>>(
        '/wp-json/wp/v2/product_brand',
        data: data,
      );
      return ProductTag.fromJson(response.data as Map<String, dynamic>);
    }
  }

  // ===== ایجاد تگ =====
  Future<ProductTag> createTag(Map<String, dynamic> data) async {
    final response = await _api.wcPost<Map<String, dynamic>>(
      '/wp-json/wc/v3/products/tags',
      data: data,
    );
    return ProductTag.fromJson(response.data as Map<String, dynamic>);
  }
}