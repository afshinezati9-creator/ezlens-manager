// lib/features/products/presentation/products_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/providers.dart';
import '../data/product_repository.dart';

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ProductRepository(apiClient);
});

// ===== Stateهای موجود =====
final productsPageProvider = StateProvider<int>((ref) => 1);
final productsPerPageProvider = StateProvider<int>((ref) => 5);
final productsSearchProvider = StateProvider<String>((ref) => '');
final productsCategoryProvider = StateProvider<int?>((ref) => null);
final productsTagProvider = StateProvider<int?>((ref) => null);
final productsBrandProvider = StateProvider<int?>((ref) => null);
final productsStatusProvider = StateProvider<String?>((ref) => null);

// ===== Stateهای جدید برای مرتب‌سازی =====
final productsOrderByProvider = StateProvider<String>((ref) => 'date');
final productsOrderProvider = StateProvider<String>((ref) => 'desc');

// ===== Provider اصلی که از پارامترهای جدید استفاده می‌کند =====
final productsProvider = FutureProvider.autoDispose((ref) async {
  final repo = ref.watch(productRepositoryProvider);
  final page = ref.watch(productsPageProvider);
  final perPage = ref.watch(productsPerPageProvider);
  final search = ref.watch(productsSearchProvider);
  final category = ref.watch(productsCategoryProvider);
  final tag = ref.watch(productsTagProvider);
  final brand = ref.watch(productsBrandProvider);
  final status = ref.watch(productsStatusProvider);
  final orderby = ref.watch(productsOrderByProvider);
  final order = ref.watch(productsOrderProvider);

  return repo.fetchProducts(
    page: page,
    perPage: perPage,
    search: search,
    categoryId: category,
    tagId: tag,
    brandId: brand,
    status: status,
    orderby: orderby,
    order: order,
  );
});

// ===== بقیه Providerها بدون تغییر =====
final categoriesProvider = FutureProvider.autoDispose((ref) async {
  final repo = ref.watch(productRepositoryProvider);
  return repo.fetchCategories();
});

final tagsProvider = FutureProvider.autoDispose((ref) async {
  final repo = ref.watch(productRepositoryProvider);
  return repo.fetchTags();
});

final brandsProvider = FutureProvider.autoDispose((ref) async {
  final repo = ref.watch(productRepositoryProvider);
  return repo.fetchBrands();
});