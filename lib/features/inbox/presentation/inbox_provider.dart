import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/inbox_models.dart';
import '../data/inbox_repository.dart';

class InboxQuery {
  final int page;
  final String search;
  final String filter; // all | unseen | seen
  final String folder; // inbox | sent

  const InboxQuery({
    this.page = 1,
    this.search = '',
    this.filter = 'all',
    this.folder = 'inbox',
  });

  InboxQuery copyWith({
    int? page,
    String? search,
    String? filter,
    String? folder,
  }) {
    return InboxQuery(
      page: page ?? this.page,
      search: search ?? this.search,
      filter: filter ?? this.filter,
      folder: folder ?? this.folder,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is InboxQuery &&
      other.page == page &&
      other.search == search &&
      other.filter == filter &&
      other.folder == folder;

  @override
  int get hashCode => Object.hash(page, search, filter, folder);
}

final inboxQueryProvider = StateProvider<InboxQuery>((ref) => const InboxQuery());

final inboxListProvider =
    FutureProvider.autoDispose<InboxListResult>((ref) async {
  final q = ref.watch(inboxQueryProvider);
  final repo = ref.watch(inboxRepositoryProvider);
  return repo.fetchList(
    page: q.page,
    search: q.search,
    filter: q.filter,
    folder: q.folder,
  );
});

final inboxMessageProvider =
    FutureProvider.autoDispose.family<InboxMessageDetail, int>((ref, uid) async {
  final repo = ref.watch(inboxRepositoryProvider);
  return repo.fetchMessage(uid);
});
