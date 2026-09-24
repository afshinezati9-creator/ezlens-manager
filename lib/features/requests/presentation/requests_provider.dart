import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/providers.dart';
import '../data/request_models.dart';
import '../data/request_repository.dart';

/// ============================================================
/// Repository
/// ============================================================

final requestRepositoryProvider = Provider<RequestRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  return RequestRepository(api);
});

/// ============================================================
/// فیلتر وضعیت
/// ============================================================

final requestsStatusProvider = StateProvider<String>((ref) {
  return 'all';
});

/// ============================================================
/// تعداد آیتم در هر صفحه
/// ============================================================

final requestsPerPageProvider = StateProvider<int>((ref) {
  return 10;
});

/// ============================================================
/// شماره صفحه
/// ============================================================

final requestsPageProvider = StateProvider<int>((ref) {
  return 1;
});

/// ============================================================
/// جستجو
/// ============================================================

final requestsSearchProvider = StateProvider<String>((ref) {
  return '';
});

/// ============================================================
/// تاریخ از
/// ============================================================

final requestsDateFromProvider = StateProvider<String>((ref) {
  return '';
});

/// ============================================================
/// تاریخ تا
/// ============================================================

final requestsDateToProvider = StateProvider<String>((ref) {
  return '';
});

/// ============================================================
/// فیلتر بر اساس نام فرم (NEW)
/// ============================================================

final requestsFormTitleProvider = StateProvider<String>((ref) {
  return '';
});

/// ============================================================
/// مرتب‌سازی (NEW)
/// ============================================================

final requestsOrderProvider = StateProvider<String>((ref) {
  return 'DESC';  // پیش‌فرض: جدیدترین
});

/// ============================================================
/// دریافت لیست درخواست‌ها با همه فیلترها
/// ============================================================

final requestsProvider =
    FutureProvider.autoDispose<RequestsResponse>((ref) async {
  final repository = ref.watch(requestRepositoryProvider);

  final page = ref.watch(requestsPageProvider);
  final perPage = ref.watch(requestsPerPageProvider);
  final search = ref.watch(requestsSearchProvider);
  final status = ref.watch(requestsStatusProvider);
  final dateFrom = ref.watch(requestsDateFromProvider);
  final dateTo = ref.watch(requestsDateToProvider);
  final formTitle = ref.watch(requestsFormTitleProvider);
  final order = ref.watch(requestsOrderProvider);

  return repository.fetchRequests(
    page: page,
    perPage: perPage,
    search: search,
    status: status,
    dateFrom: dateFrom,
    dateTo: dateTo,
    formTitle: formTitle,
    orderby: 'created_at',
    order: order,
  );
});

/// ============================================================
/// جزئیات یک درخواست
/// ============================================================

final requestDetailProvider = FutureProvider.autoDispose
    .family<RequestItem, int>((ref, id) async {
  final repository = ref.watch(requestRepositoryProvider);
  return repository.fetchRequest(id);
});

/// ============================================================
/// یادداشت‌های درخواست
/// ============================================================

final requestNotesProvider = FutureProvider.autoDispose
    .family<List<RequestNote>, int>((ref, id) async {
  final repository = ref.watch(requestRepositoryProvider);
  return repository.fetchNotes(id);
});