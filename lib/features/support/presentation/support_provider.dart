import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/support_models.dart';
import '../data/support_repository.dart';

class SupportQuery {
  final int page;
  final String search;
  final String status;

  const SupportQuery({
    this.page = 1,
    this.search = '',
    this.status = 'all',
  });

  SupportQuery copyWith({int? page, String? search, String? status}) {
    return SupportQuery(
      page: page ?? this.page,
      search: search ?? this.search,
      status: status ?? this.status,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is SupportQuery &&
      other.page == page &&
      other.search == search &&
      other.status == status;

  @override
  int get hashCode => Object.hash(page, search, status);
}

final supportQueryProvider =
    StateProvider<SupportQuery>((ref) => const SupportQuery());

final supportListProvider =
    FutureProvider.autoDispose<SupportListResult>((ref) async {
  final q = ref.watch(supportQueryProvider);
  return ref.watch(supportRepositoryProvider).fetchTickets(
        page: q.page,
        search: q.search,
        status: q.status,
      );
});

final supportDetailProvider =
    FutureProvider.autoDispose.family<SupportTicketDetail, int>((ref, id) {
  return ref.watch(supportRepositoryProvider).fetchTicket(id);
});
