// lib/features/articles/presentation/articles_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/providers.dart';
import '../data/article_repository.dart';
import '../data/article_models.dart';

// ====================================================
//  ارائه‌دهنده (Provider) برای ریپازیتوری مقالات
// ====================================================
final articleRepositoryProvider = Provider<ArticleRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ArticleRepository(apiClient);
});

// ====================================================
//  وضعیت‌های فیلتر و صفحه‌بندی (StateProvider)
// ====================================================

// شماره صفحه فعلی
final articlesPageProvider = StateProvider<int>((ref) => 1);

// تعداد آیتم در هر صفحه
final articlesPerPageProvider = StateProvider<int>((ref) => 10);

// عبارت جستجو
final articlesSearchProvider = StateProvider<String>((ref) => '');

// فیلتر دسته‌بندی (شناسه دسته یا null برای همه)
final articlesCategoryFilterProvider = StateProvider<int?>((ref) => null);

// فیلتر وضعیت (مثلاً 'publish' یا null برای همه)
final articlesStatusFilterProvider = StateProvider<String?>((ref) => null);

// ====================================================
//  تغییرات جدید برای مرتب‌سازی و فیلتر تاریخ
// ====================================================

// نوع مرتب‌سازی (newest, oldest, views, title)
final articlesSortProvider = StateProvider<String>((ref) => 'newest');

// تاریخ شروع (برای فیلتر بعد از این تاریخ)
final articlesDateFromProvider = StateProvider<String>((ref) => '');

// تاریخ پایان (برای فیلتر قبل از این تاریخ)
final articlesDateToProvider = StateProvider<String>((ref) => '');

// ====================================================
//  دریافت لیست مقالات (FutureProvider)
//  با اعمال فیلترها، مرتب‌سازی و صفحه‌بندی
// ====================================================
final articlesProvider = FutureProvider.autoDispose<List<Article>>((ref) async {
  final repo = ref.watch(articleRepositoryProvider);
  final page = ref.watch(articlesPageProvider);
  final perPage = ref.watch(articlesPerPageProvider);
  final search = ref.watch(articlesSearchProvider);
  final categoryId = ref.watch(articlesCategoryFilterProvider);
  final status = ref.watch(articlesStatusFilterProvider);
  final sort = ref.watch(articlesSortProvider);
  final dateFrom = ref.watch(articlesDateFromProvider);
  final dateTo = ref.watch(articlesDateToProvider);

  // اگر عبارت جستجو خالی بود، null ارسال کن
  final searchTerm = search.trim().isEmpty ? null : search.trim();

  return repo.fetchArticles(
    page: page,
    perPage: perPage,
    search: searchTerm,
    categoryId: categoryId,
    status: status,
    sort: sort,
    dateFrom: dateFrom.isEmpty ? null : dateFrom,
    dateTo: dateTo.isEmpty ? null : dateTo,
  );
});

// ====================================================
//  دریافت تعداد کل مقالات (برای صفحه‌بندی)
//  (با در نظر گرفتن فیلترها)
// ====================================================
final articlesTotalProvider = FutureProvider.autoDispose<int>((ref) async {
  final repo = ref.watch(articleRepositoryProvider);
  final search = ref.watch(articlesSearchProvider);
  final categoryId = ref.watch(articlesCategoryFilterProvider);
  final status = ref.watch(articlesStatusFilterProvider);
  final sort = ref.watch(articlesSortProvider);
  final dateFrom = ref.watch(articlesDateFromProvider);
  final dateTo = ref.watch(articlesDateToProvider);

  final searchTerm = search.trim().isEmpty ? null : search.trim();

  return repo.fetchTotalArticles(
    search: searchTerm,
    categoryId: categoryId,
    status: status,
    sort: sort,
    dateFrom: dateFrom.isEmpty ? null : dateFrom,
    dateTo: dateTo.isEmpty ? null : dateTo,
  );
});

// ====================================================
//  دریافت لیست دسته‌بندی‌ها (برای فیلتر و فرم)
// ====================================================
final articleCategoriesProvider = FutureProvider.autoDispose<List<ArticleCategory>>((ref) async {
  final repo = ref.watch(articleRepositoryProvider);
  return repo.fetchCategories();
});

// ====================================================
//  دریافت لیست تگ‌ها (برای فرم)
// ====================================================
final articleTagsProvider = FutureProvider.autoDispose<List<ArticleTag>>((ref) async {
  final repo = ref.watch(articleRepositoryProvider);
  return repo.fetchTags();
});

// ====================================================
//  دریافت یک مقاله خاص (برای صفحه ویرایش)
// ====================================================
final articleDetailProvider = FutureProvider.autoDispose.family<Article, int>((ref, id) async {
  final repo = ref.watch(articleRepositoryProvider);
  return repo.fetchArticle(id);
});

// ====================================================
//  (اختیاری) نگهداری وضعیت انتخاب دسته‌ها در فرم
// ====================================================
final selectedCategoriesProvider = StateProvider<List<int>>((ref) => []);

// ====================================================
//  (اختیاری) نگهداری وضعیت انتخاب تگ‌ها در فرم
// ====================================================
final selectedTagsProvider = StateProvider<List<int>>((ref) => []);