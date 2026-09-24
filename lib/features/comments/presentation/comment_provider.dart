import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/comment_models.dart';
import '../data/comment_repository.dart';
export '../data/comment_repository.dart' show commentRepositoryProvider, CommentRepository;

// repository is defined in comment_repository.dart

final commentsPageProvider = StateProvider<int>((ref) => 1);
final commentsPerPageProvider = StateProvider<int>((ref) => 20);
final commentsSearchProvider = StateProvider<String>((ref) => '');
final commentsStatusProvider = StateProvider<String?>((ref) => 'any');
final commentsPostTypeProvider = StateProvider<String?>((ref) => null);
final commentsAuthorIdProvider = StateProvider<int?>((ref) => null);
final commentsDateFromProvider = StateProvider<DateTime?>((ref) => null);
final commentsDateToProvider = StateProvider<DateTime?>((ref) => null);

final commentsProvider =
    FutureProvider.autoDispose<CommentsPageResult>((ref) async {
  final repo = ref.watch(commentRepositoryProvider);
  final page = ref.watch(commentsPageProvider);
  final perPage = ref.watch(commentsPerPageProvider);
  final search = ref.watch(commentsSearchProvider);
  final status = ref.watch(commentsStatusProvider);
  final authorId = ref.watch(commentsAuthorIdProvider);
  final dateFrom = ref.watch(commentsDateFromProvider);
  final dateTo = ref.watch(commentsDateToProvider);

  final result = await repo.fetchComments(
    page: page,
    perPage: perPage,
    search: search.isNotEmpty ? search : null,
    status: status,
    authorId: authorId,
    dateFrom: dateFrom,
    dateTo: dateTo,
  );

  final postType = ref.watch(commentsPostTypeProvider);
  if (postType != null && postType.isNotEmpty) {
    final filtered =
        result.items.where((c) => c.postType == postType).toList();
    return CommentsPageResult(
      items: filtered,
      total: filtered.length,
      pages: result.pages,
      page: result.page,
    );
  }
  return result;
});

final commentsTotalCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final data = await ref.watch(commentsProvider.future);
  return data.total;
});

final conversationProvider =
    FutureProvider.autoDispose.family<List<Comment>, int>((ref, postId) async {
  final repo = ref.watch(commentRepositoryProvider);
  return repo.fetchConversation(postId);
});

final userProfileProvider =
    FutureProvider.autoDispose.family<UserProfile, int>((ref, userId) async {
  final repo = ref.watch(commentRepositoryProvider);
  return repo.fetchUserProfile(userId);
});

final replyNotifierProvider =
    StateNotifierProvider<ReplyNotifier, AsyncValue<Comment?>>((ref) {
  return ReplyNotifier(ref);
});

class ReplyNotifier extends StateNotifier<AsyncValue<Comment?>> {
  final Ref ref;
  ReplyNotifier(this.ref) : super(const AsyncValue.data(null));

  Future<void> reply({
    required int post,
    required String content,
    int? parent,
    String? authorName,
    String? authorEmail,
  }) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(commentRepositoryProvider);
      final result = await repo.postComment(
        post: post,
        content: content,
        parent: parent,
        authorName: authorName,
        authorEmail: authorEmail,
      );
      state = AsyncValue.data(result);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}
