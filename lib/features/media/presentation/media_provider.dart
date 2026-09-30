// lib/features/media/presentation/media_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/providers.dart';
import '../data/media_models.dart';
import '../data/media_repository.dart';

// ===== ریپازیتوری =====
final mediaRepositoryProvider = Provider<MediaRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  return MediaRepository(api);
});

// ===== Stateهای فیلتر و صفحه‌بندی =====
final mediaPageProvider = StateProvider<int>((ref) => 1);
final mediaPerPageProvider = StateProvider<int>((ref) => 24);
final mediaSearchProvider = StateProvider<String>((ref) => '');
final mediaTypeProvider = StateProvider<String?>((ref) => null);

// ===== Stateهای فیلتر سمت کلاینت =====
final mediaSizeFilterProvider = StateProvider<String>((ref) => 'all'); // all, small, medium, large
final mediaDateFromProvider = StateProvider<DateTime?>((ref) => null);
final mediaDateToProvider = StateProvider<DateTime?>((ref) => null);

// ===== View Mode (list / grid) =====
final mediaViewModeProvider = StateProvider<String>((ref) => 'list');

// ===== Provider اصلی لیست رسانه‌ها =====
final mediaProvider = FutureProvider.autoDispose((ref) async {
  final repo = ref.watch(mediaRepositoryProvider);
  final page = ref.watch(mediaPageProvider);
  final perPage = ref.watch(mediaPerPageProvider);
  final search = ref.watch(mediaSearchProvider);
  final type = ref.watch(mediaTypeProvider);

  return repo.fetchMedia(
    page: page,
    perPage: perPage,
    search: search.isNotEmpty ? search : null,
    mediaType: type,
  );
});

// ===== Provider جزئیات یک رسانه =====
final mediaDetailProvider = FutureProvider.autoDispose.family<MediaItem, int>((ref, id) async {
  final repo = ref.watch(mediaRepositoryProvider);
  return repo.fetchMediaItem(id);
});

// ===== Provider تعداد کل =====
final mediaTotalCountProvider = FutureProvider.autoDispose((ref) async {
  final repo = ref.watch(mediaRepositoryProvider);
  final search = ref.watch(mediaSearchProvider);
  final type = ref.watch(mediaTypeProvider);
  return repo.fetchTotalCount(
    search: search.isNotEmpty ? search : null,
    mediaType: type,
  );
});