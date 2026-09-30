import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/providers.dart';
import '../data/note_models.dart';
import '../data/note_repository.dart';

// ============================================================
// Repository Provider
// ============================================================

final noteRepositoryProvider = Provider<NoteRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  return NoteRepository(api);
});

// ============================================================
// فیلترها
// ============================================================

/// جستجو در عنوان و محتوا
final notesSearchProvider = StateProvider<String>((ref) => '');

/// فیلتر بر اساس رنگ
final notesColorProvider = StateProvider<String>((ref) => 'all');

/// فیلتر بر اساس اولویت
final notesPriorityProvider = StateProvider<String>((ref) => 'all');

/// فیلتر بر اساس برچسب
final notesTagProvider = StateProvider<String>((ref) => 'all');

/// فیلتر بر اساس وضعیت سررسید (overdue, today, upcoming)
final notesDueProvider = StateProvider<String>((ref) => '');

/// نمایش فقط یادداشت‌های پین‌شده
final notesPinnedProvider = StateProvider<bool>((ref) => false);

/// شماره صفحه
final notesPageProvider = StateProvider<int>((ref) => 1);

/// تعداد آیتم در هر صفحه
final notesPerPageProvider = StateProvider<int>((ref) => 10);

// ============================================================
// دریافت لیست یادداشت‌ها با اعمال فیلترها
// ============================================================

final notesProvider = FutureProvider.autoDispose<NotesResponse>((ref) async {
  final repository = ref.watch(noteRepositoryProvider);

  final page = ref.watch(notesPageProvider);
  final perPage = ref.watch(notesPerPageProvider);
  final search = ref.watch(notesSearchProvider);
  final color = ref.watch(notesColorProvider);
  final priority = ref.watch(notesPriorityProvider);
  final tag = ref.watch(notesTagProvider);
  final due = ref.watch(notesDueProvider);
  final pinned = ref.watch(notesPinnedProvider);

  return repository.fetchNotes(
    page: page,
    perPage: perPage,
    search: search,
    priority: priority != 'all' ? priority : null,
    color: color != 'all' ? color : null,
    pinned: pinned,
    tag: tag != 'all' ? tag : null,
    due: due.isNotEmpty ? due : null,
  );
});

// ============================================================
// جزئیات یک یادداشت
// ============================================================

final noteDetailProvider =
    FutureProvider.autoDispose.family<NoteItem, int>((ref, id) async {
  final repository = ref.watch(noteRepositoryProvider);
  return repository.fetchNote(id);
});

// ============================================================
// قالب‌های آماده
// ============================================================

final noteTemplatesProvider = FutureProvider.autoDispose<List<NoteTemplate>>(
  (ref) async {
    final repository = ref.watch(noteRepositoryProvider);
    return repository.fetchTemplates();
  },
);

// ============================================================
// پاسخ‌های (کامنت‌های) یک یادداشت
// ============================================================

final noteRepliesProvider =
    FutureProvider.autoDispose.family<List<NoteReply>, int>((ref, id) async {
  // برای دریافت پاسخ‌ها، از جزئیات یادداشت استفاده می‌کنیم
  // یا می‌توانیم یک endpoint جداگانه اضافه کنیم
  final note = await ref.watch(noteDetailProvider(id).future);
  return note.replies;
});