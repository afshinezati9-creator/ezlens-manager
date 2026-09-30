import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/providers.dart';
import 'comment_models.dart';

final commentRepositoryProvider = Provider<CommentRepository>((ref) {
  return CommentRepository(ref.watch(apiClientProvider));
});

class CommentRepository {
  final ApiClient _api;
  CommentRepository(this._api);

  static const _wp = '/wp-json/wp/v2/comments';
  static const _mgr = '/wp-json/ezlens/v1/manager/comments';

  Future<CommentsPageResult> fetchComments({
    int page = 1,
    int perPage = 20,
    String? search,
    String? status,
    int? postId,
    int? authorId,
    DateTime? dateFrom,
    DateTime? dateTo,
    String type = 'comment', // comment | review
  }) async {
    // Prefer manager API (enriched); fallback to core WP
    try {
      final response = await _api.wpGet<Map<String, dynamic>>(
        _mgr,
        queryParameters: {
          'page': page,
          'per_page': perPage,
          'type': type,
          if (search != null && search.isNotEmpty) 'search': search,
          if (status != null && status != 'any') 'status': status,
          if (postId != null) 'post': postId,
          if (authorId != null) 'author': authorId,
          if (dateFrom != null) 'after': dateFrom.toIso8601String(),
          if (dateTo != null) 'before': dateTo.toIso8601String(),
        },
      );
      final data = response.data;
      if (data is Map<String, dynamic> && data['items'] is List) {
        final items = (data['items'] as List)
            .whereType<Map>()
            .map((e) => Comment.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        return CommentsPageResult(
          items: items,
          total: int.tryParse('${data['total']}') ?? items.length,
          pages: int.tryParse('${data['pages']}') ?? 1,
          page: int.tryParse('${data['page']}') ?? page,
        );
      }
    } catch (_) {
      // fallback below
    }

    final response = await _api.wpGet(
      _wp,
      queryParameters: {
        'page': page,
        'per_page': perPage,
        'context': 'edit',
        if (search != null && search.isNotEmpty) 'search': search,
        if (status != null && status != 'any') 'status': status,
        if (postId != null) 'post': postId,
        if (authorId != null) 'author': authorId,
        if (dateFrom != null) 'after': dateFrom.toIso8601String(),
        if (dateTo != null) 'before': dateTo.toIso8601String(),
      },
    );
    final raw = response.data;
    final items = <Comment>[];
    if (raw is List) {
      for (final e in raw) {
        if (e is Map) {
          items.add(Comment.fromJson(Map<String, dynamic>.from(e)));
        }
      }
    }
    int total = items.length;
    int pages = 1;
    try {
      final h = response.headers.map;
      total = int.tryParse(h['x-wp-total']?.first ?? '') ?? total;
      pages = int.tryParse(h['x-wp-totalpages']?.first ?? '') ?? pages;
    } catch (_) {}
    return CommentsPageResult(
      items: items,
      total: total,
      pages: pages,
      page: page,
    );
  }

  Future<int> fetchTotalCount({
    String? search,
    String? status,
    int? postId,
    int? authorId,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    final r = await fetchComments(
      page: 1,
      perPage: 1,
      search: search,
      status: status,
      postId: postId,
      authorId: authorId,
      dateFrom: dateFrom,
      dateTo: dateTo,
    );
    return r.total;
  }

  Future<List<Comment>> fetchConversation(int postId) async {
    final r = await fetchComments(
      page: 1,
      perPage: 100,
      postId: postId,
      status: 'any',
    );
    return r.items;
  }

  Future<Comment> postComment({
    required int post,
    required String content,
    int? parent,
    String? authorName,
    String? authorEmail,
  }) async {
    final response = await _api.wpPost(
      _wp,
      data: {
        'post': post,
        'content': content,
        if (parent != null) 'parent': parent,
        if (authorName != null && authorName.isNotEmpty) 'author_name': authorName,
        if (authorEmail != null && authorEmail.isNotEmpty) 'author_email': authorEmail,
      },
    );
    return Comment.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<Comment> updateCommentStatus(int id, String status) async {
    // Try manager first
    try {
      final response = await _api.wpPost(
        '$_mgr/$id/status',
        data: {'status': status},
      );
      final data = response.data;
      if (data != null && data['comment'] is Map) {
        return Comment.fromJson(Map<String, dynamic>.from(data['comment'] as Map));
      }
    } catch (_) {}

    final response = await _api.wpPost(
      '$_wp/$id',
      data: {'status': status},
    );
    return Comment.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<void> deleteComment(int id) async {
    try {
      await _api.wpDelete('$_mgr/$id', queryParameters: {'force': true});
      return;
    } catch (_) {}
    await _api.wpDelete('$_wp/$id', queryParameters: {'force': true});
  }

  Future<UserProfile> fetchUserProfile(int userId) async {
    // Prefer WC customer for phone/spend
    try {
      final response = await _api.wcGet('/wp-json/wc/v3/customers/$userId');
      final data = response.data;
      if (data != null) {
        return UserProfile.fromJson(Map<String, dynamic>.from(data));
      }
    } catch (_) {}
    final response = await _api.wpGet('/wp-json/wp/v2/users/$userId', queryParameters: {
      'context': 'edit',
    });
    return UserProfile.fromJson(Map<String, dynamic>.from(response.data as Map));
  }
}

class CommentsPageResult {
  final List<Comment> items;
  final int total;
  final int pages;
  final int page;

  const CommentsPageResult({
    required this.items,
    this.total = 0,
    this.pages = 1,
    this.page = 1,
  });
}
