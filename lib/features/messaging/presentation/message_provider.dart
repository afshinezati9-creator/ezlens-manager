import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/message_models.dart';
import '../data/message_repository.dart';

class MessageQuery {
  final int page;
  final String search;
  final String channel;
  final String from; // YYYY-MM-DD
  final String to;

  const MessageQuery({
    this.page = 1,
    this.search = '',
    this.channel = 'all',
    this.from = '',
    this.to = '',
  });

  MessageQuery copyWith({
    int? page,
    String? search,
    String? channel,
    String? from,
    String? to,
  }) {
    return MessageQuery(
      page: page ?? this.page,
      search: search ?? this.search,
      channel: channel ?? this.channel,
      from: from ?? this.from,
      to: to ?? this.to,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is MessageQuery &&
      other.page == page &&
      other.search == search &&
      other.channel == channel &&
      other.from == from &&
      other.to == to;

  @override
  int get hashCode => Object.hash(page, search, channel, from, to);
}

final messageQueryProvider =
    StateProvider<MessageQuery>((ref) => const MessageQuery());

final messageListProvider =
    FutureProvider.autoDispose<MessageListResult>((ref) async {
  final q = ref.watch(messageQueryProvider);
  return ref.watch(messageRepositoryProvider).fetchList(
        page: q.page,
        search: q.search,
        channel: q.channel,
        from: q.from,
        to: q.to,
      );
});
