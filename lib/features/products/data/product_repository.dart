// lib/features/products/data/product_repository.dart

import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';
import 'product_models.dart';

class ProductRepository {
  final ApiClient _api;

  ProductRepository(this._api);

  // Static product filters are reused across the product screen.
  // Keep a short in-memory cache so opening/filtering the screen does not
  // repeatedly hit WooCommerce for the same categories/tags/brands.
  List<ProductCategory>? _categoriesCache;
  DateTime? _categoriesCachedAt;
  List<ProductTag>? _tagsCache;
  DateTime? _tagsCachedAt;
  List<ProductTag>? _brandsCache;
  DateTime? _brandsCachedAt;

  static const _filterCacheTtl = Duration(minutes: 5);

  bool _fresh(DateTime? at) =>
      at != null && DateTime.now().difference(at) < _filterCacheTtl;

  void clearFilterCaches() {
    _categoriesCache = null;
    _categoriesCachedAt = null;
    _tagsCache = null;
    _tagsCachedAt = null;
    _brandsCache = null;
    _brandsCachedAt = null;
  }

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
    if (_fresh(_categoriesCachedAt) && _categoriesCache != null) {
      return List<ProductCategory>.from(_categoriesCache!);
    }

    final allCategories = <ProductCategory>[];
    var page = 1;
    var hasMore = true;

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
            data.map((e) => ProductCategory.fromJson(e as Map<String, dynamic>)),
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

    _categoriesCache = List<ProductCategory>.from(allCategories);
    _categoriesCachedAt = DateTime.now();
    return allCategories;
  }

  // ===== تگ‌ها =====
  Future<List<ProductTag>> fetchTags() async {
    if (_fresh(_tagsCachedAt) && _tagsCache != null) {
      return List<ProductTag>.from(_tagsCache!);
    }

    final allTags = <ProductTag>[];
    var page = 1;
    var hasMore = true;

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
            data.map((e) => ProductTag.fromJson(e as Map<String, dynamic>)),
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

    _tagsCache = List<ProductTag>.from(allTags);
    _tagsCachedAt = DateTime.now();
    return allTags;
  }

  // ===== برندها =====
  Future<List<ProductTag>> fetchBrands() async {
    if (_fresh(_brandsCachedAt) && _brandsCache != null) {
      return List<ProductTag>.from(_brandsCache!);
    }

    List<ProductTag> result;
    try {
      final response = await _api.wcGet<List<dynamic>>(
        '/wp-json/wc/v3/products/brands',
        queryParameters: {
          'per_page': 100,
          'orderby': 'id',
          'order': 'asc',
        },
      );
      result = (response.data ?? [])
          .map((e) => ProductTag.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      final response = await _api.wcGet<List<dynamic>>(
        '/wp-json/wp/v2/product_brand',
        queryParameters: {'per_page': 100},
      );
      result = (response.data ?? [])
          .map((e) => ProductTag.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    _brandsCache = List<ProductTag>.from(result);
    _brandsCachedAt = DateTime.now();
    return result;
  }

  // ===== ایجاد دسته‌بندی =====
  Future<ProductCategory> createCategory(Map<String, dynamic> data) async {
    final response = await _api.wcPost<Map<String, dynamic>>(
      '/wp-json/wc/v3/products/categories',
      data: data,
    );
    final result = ProductCategory.fromJson(response.data as Map<String, dynamic>);
    clearFilterCaches();
    return result;
  }

  // ===== ایجاد برند =====
  Future<ProductTag> createBrand(Map<String, dynamic> data) async {
    try {
      final response = await _api.wcPost<Map<String, dynamic>>(
        '/wp-json/wc/v3/products/brands',
        data: data,
      );
      final result = ProductTag.fromJson(response.data as Map<String, dynamic>);
      clearFilterCaches();
      return result;
    } catch (_) {
      final response = await _api.wcPost<Map<String, dynamic>>(
        '/wp-json/wp/v2/product_brand',
        data: data,
      );
      final result = ProductTag.fromJson(response.data as Map<String, dynamic>);
      clearFilterCaches();
      return result;
    }
  }

  // ===== ایجاد تگ =====
  Future<ProductTag> createTag(Map<String, dynamic> data) async {
    final response = await _api.wcPost<Map<String, dynamic>>(
      '/wp-json/wc/v3/products/tags',
      data: data,
    );
    final result = ProductTag.fromJson(response.data as Map<String, dynamic>);
    clearFilterCaches();
    return result;
  }
}