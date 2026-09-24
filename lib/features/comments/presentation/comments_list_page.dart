// lib/features/comments/presentation/comments_list_page.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ezlens_manager/core/theme/app_colors.dart';
import 'package:ezlens_manager/core/widgets/app_empty_state.dart';
import 'package:ezlens_manager/core/widgets/app_error_state.dart';
import 'package:ezlens_manager/core/widgets/app_loading.dart';
import '../data/comment_models.dart';
import '../data/comment_repository.dart';
import 'comment_provider.dart';
import 'widgets/comment_card.dart';
import 'widgets/comment_filter_widget.dart';
import 'widgets/comment_thread.dart';
import 'widgets/comment_reply_dialog.dart';
import 'widgets/user_profile_dialog.dart';

class CommentsListPage extends ConsumerStatefulWidget {
  const CommentsListPage({super.key});

  @override
  ConsumerState<CommentsListPage> createState() => _CommentsListPageState();
}

class _CommentsListPageState extends ConsumerState<CommentsListPage> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  int? _conversationPostId;
  String _conversationPostTitle = '';
  List<Comment> _conversationComments = [];
  bool _conversationLoading = false;
  String _conversationError = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      ref.read(commentsSearchProvider.notifier).state = _searchController.text;
      ref.read(commentsPageProvider.notifier).state = 1;
      ref.invalidate(commentsProvider);
      ref.invalidate(commentsTotalCountProvider);
    });
  }

  String _toFa(num value) {
    const fa = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
    return value.toString().split('').map((d) => fa[int.parse(d)]).join();
  }

  // ============================================================
  // ساخت درخت نظرات (ریشه و فرزندان)
  // ============================================================
  List<Comment> _buildCommentTree(List<Comment> comments) {
    final Map<int, Comment> commentMap = {};
    final List<Comment> roots = [];

    for (final comment in comments) {
      commentMap[comment.id] = comment;
    }

    for (final comment in comments) {
      if (comment.parent == 0) {
        roots.add(comment);
      } else {
        final parent = commentMap[comment.parent];
        if (parent != null) {
          parent.children ??= [];
          parent.children!.add(comment);
        } else {
          roots.add(comment);
        }
      }
    }

    return roots;
  }

  // ============================================================
  // باز کردن مکالمه (با عنوان واقعی پست)
  // ============================================================
  Future<void> _openConversation(Comment comment) async {
    setState(() {
      _conversationPostId = comment.post;
      _conversationPostTitle = comment.postTitle;
      _conversationComments = [];
      _conversationLoading = true;
      _conversationError = '';
    });

    try {
      final repo = ref.read(commentRepositoryProvider);
      final comments = await repo.fetchConversation(comment.post);
      final tree = _buildCommentTree(comments);
      setState(() {
        _conversationComments = tree;
        _conversationLoading = false;
      });
      _showConversationDialog();
    } catch (e) {
      setState(() {
        _conversationError = 'خطا در دریافت مکالمه: $e';
        _conversationLoading = false;
      });
      _showConversationDialog();
    }
  }

  // ============================================================
  // نمایش مودال مکالمه
  // ============================================================
  void _showConversationDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                const Icon(Icons.forum_outlined, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _conversationPostTitle.isNotEmpty
                        ? 'مکالمه: $_conversationPostTitle'
                        : 'مکالمه',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            content: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              constraints: const BoxConstraints(maxWidth: 600, maxHeight: 500),
              child: _conversationLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _conversationError.isNotEmpty
                      ? Center(
                          child: Text(
                            _conversationError,
                            style: const TextStyle(color: AppColors.danger),
                          ),
                        )
                      : _conversationComments.isEmpty
                          ? const Center(
                              child: Text('هیچ نظری در این مکالمه وجود ندارد.'),
                            )
                          : ListView(
                              children: _conversationComments.map((root) {
                                return CommentThread(
                                  comment: root,
                                  depth: 0,
                                  onReply: (parentComment) {
                                    Navigator.pop(ctx);
                                    _openReplyDialog(
                                      _conversationPostId!,
                                      parentComment: parentComment,
                                    );
                                  },
                                  onProfileTap: () => _openProfile(root.author),
                                );
                              }).toList(),
                            ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('بستن'),
              ),
              if (_conversationPostId != null)
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _openReplyDialog(_conversationPostId!);
                  },
                  icon: const Icon(Icons.reply_outlined, size: 16),
                  label: const Text('نظر جدید'),
                ),
            ],
          );
        },
      ),
    );
  }

  // ============================================================
  // باز کردن دیالوگ پاسخ
  // ============================================================
  void _openReplyDialog(int postId, {Comment? parentComment}) {
    showDialog(
      context: context,
      builder: (ctx) => CommentReplyDialog(
        postId: postId,
        parentComment: parentComment,
      ),
    ).then((result) {
      if (result == true) {
        ref.invalidate(commentsProvider);
        ref.invalidate(commentsTotalCountProvider);
        if (_conversationPostId != null) {
          _openConversation(Comment(
            id: 0,
            author: 0,
            authorName: '',
            authorEmail: '',
            content: '',
            date: DateTime.now(),
            status: CommentStatus.pending,
            link: '',
            post: _conversationPostId!,
            postTitle: _conversationPostTitle,
            postLink: '',
            postType: '',
            postTypeLabel: '',
            parent: 0,
            ip: null,
            userAgent: null,
            children: null,
          ));
        }
      }
    });
  }

  // ============================================================
  // باز کردن پروفایل کاربر
  // ============================================================
  void _openProfile(int userId) {
    showDialog(
      context: context,
      builder: (ctx) => UserProfileDialog(userId: userId),
    );
  }

  // ============================================================
  // تغییر وضعیت نظر
  // ============================================================
  Future<void> _updateStatus(Comment comment, CommentStatus newStatus) async {
    try {
      final repo = ref.read(commentRepositoryProvider);
      await repo.updateCommentStatus(comment.id, newStatus.apiValue);
      ref.invalidate(commentsProvider);
      ref.invalidate(commentsTotalCountProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('وضعیت نظر به "${newStatus.label}" تغییر کرد')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا: $e')),
        );
      }
    }
  }

  // ============================================================
  // حذف نظر
  // ============================================================
  Future<void> _deleteComment(Comment comment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف نظر'),
        content: Text('آیا از حذف نظر "${comment.authorName}" مطمئن هستید؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('انصراف'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final repo = ref.read(commentRepositoryProvider);
      await repo.deleteComment(comment.id);
      ref.invalidate(commentsProvider);
      ref.invalidate(commentsTotalCountProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('نظر حذف شد')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا: $e')),
        );
      }
    }
  }

  // ============================================================
  // build
  // ============================================================
  @override
  Widget build(BuildContext context) {
    final commentsAsync = ref.watch(commentsProvider);
    final currentPage = ref.watch(commentsPageProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('نظرات'),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(commentsProvider);
              ref.invalidate(commentsTotalCountProvider);
            },
            tooltip: 'به‌روزرسانی',
          ),
        ],
      ),
      body: Column(
        children: [
          CommentFilterWidget(
            searchController: _searchController,
            onSearchChanged: _onSearchChanged,
          ),
          const SizedBox(height: 8),

          Expanded(
            child: commentsAsync.when(
              loading: () => const AppLoading(),
              error: (err, _) => Center(
                child: AppErrorState(
                  title: 'خطا در دریافت نظرات',
                  subtitle: err.toString(),
                  onRetry: () {
                    ref.invalidate(commentsProvider);
                    ref.invalidate(commentsTotalCountProvider);
                  },
                ),
              ),
              data: (result) {
                final comments = result.items;
                if (comments.isEmpty) {
                  return AppEmptyState(
                    icon: Icons.forum_outlined,
                    title: 'نظری یافت نشد',
                    subtitle: 'با تغییر فیلترها یا جستجو مجدد امتحان کنید.',
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: CommentCard(
                        comment: comment,
                        onProfileTap: () => _openProfile(comment.author),
                        onConversationTap: () => _openConversation(comment),
                        onStatusChange: (status) => _updateStatus(comment, status),
                        onDelete: () => _deleteComment(comment),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // صفحه‌بندی
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            color: AppColors.surface,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () {
                    ref.read(commentsPageProvider.notifier).state++;
                    ref.invalidate(commentsProvider);
                    ref.invalidate(commentsTotalCountProvider);
                  },
                  icon: const Icon(Icons.chevron_left),
                  splashRadius: 20,
                ),
                Text(
                  'صفحه ${_toFa(currentPage)}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: currentPage > 1
                      ? () {
                          ref.read(commentsPageProvider.notifier).state--;
                          ref.invalidate(commentsProvider);
                          ref.invalidate(commentsTotalCountProvider);
                        }
                      : null,
                  icon: const Icon(Icons.chevron_right),
                  splashRadius: 20,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}