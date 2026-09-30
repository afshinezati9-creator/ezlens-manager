// lib/features/comments/presentation/widgets/comment_reply_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ezlens_manager/core/theme/app_theme.dart';
import '../../data/comment_models.dart';
import '../comment_provider.dart';

class CommentReplyDialog extends ConsumerStatefulWidget {
  final int postId;
  final Comment? parentComment;

  const CommentReplyDialog({
    super.key,
    required this.postId,
    this.parentComment,
  });

  @override
  ConsumerState<CommentReplyDialog> createState() => _CommentReplyDialogState();
}

class _CommentReplyDialogState extends ConsumerState<CommentReplyDialog> {
  final TextEditingController _contentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _submitReply() async {
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لطفاً متن پاسخ را وارد کنید')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final notifier = ref.read(replyNotifierProvider.notifier);
      await notifier.reply(
        post: widget.postId,
        content: _contentController.text.trim(),
        parent: widget.parentComment?.id,
        authorName: 'مدیر سایت',
        authorEmail: 'info@ezlens.ir',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('پاسخ با موفقیت ارسال شد')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(Icons.reply_outlined, color: AppTheme.primary),
          const SizedBox(width: 8),
          Text(widget.parentComment != null ? 'پاسخ به نظر' : 'نظر جدید'),
        ],
      ),
      content: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.parentComment != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceHover,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'پاسخ به: ${widget.parentComment!.authorName}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.parentComment!.content.replaceAll(RegExp(r'<[^>]*>'), ''),
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _contentController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'متن پاسخ خود را بنویسید...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.border),
                ),
                filled: true,
                fillColor: AppTheme.surface,
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context, false),
          child: const Text('لغو'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submitReply,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
          ),
          child: _isSubmitting
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('ارسال پاسخ'),
        ),
      ],
    );
  }
}