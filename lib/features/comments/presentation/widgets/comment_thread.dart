// lib/features/comments/presentation/widgets/comment_thread.dart

import 'package:flutter/material.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import 'package:ezlens_manager/core/theme/app_theme.dart';
import '../../data/comment_models.dart';
import 'comment_status_badge.dart';

class CommentThread extends StatelessWidget {
  final Comment comment;
  final int depth;
  // ===== تغییر: onReply با پارامتر Comment =====
  final void Function(Comment) onReply;
  final VoidCallback onProfileTap;

  const CommentThread({
    super.key,
    required this.comment,
    this.depth = 0,
    required this.onReply,
    required this.onProfileTap,
  });

  String _toPersianDate(DateTime date) {
    final jalali = Jalali.fromDateTime(date);
    return '${jalali.year}/${jalali.month.toString().padLeft(2, '0')}/${jalali.day.toString().padLeft(2, '0')} - ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _getRoleLabel(String? role) {
    switch (role) {
      case 'administrator':
        return 'مدیر';
      case 'customer':
        return 'مشتری';
      case 'subscriber':
        return 'کاربر';
      default:
        return 'مهمان';
    }
  }

  Color _getRoleColor(String? role) {
    switch (role) {
      case 'administrator':
        return AppTheme.primary;
      case 'customer':
        return AppTheme.success;
      case 'subscriber':
        return AppTheme.info;
      default:
        return AppTheme.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final indent = depth * 16.0;
    final isRoot = depth == 0;

    return Padding(
      padding: EdgeInsets.only(
        right: isRoot ? 0 : indent,
        top: isRoot ? 0 : 8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isRoot)
            Container(
              width: 2,
              height: 20,
              color: AppTheme.border,
              margin: const EdgeInsets.only(right: 8),
            ),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isRoot ? AppTheme.surface : AppTheme.surfaceHover,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.border.withOpacity(isRoot ? 0.5 : 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ===== هدر با نقش کاربر =====
                Row(
                  children: [
                    GestureDetector(
                      onTap: onProfileTap,
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: AppTheme.primary.withOpacity(0.1),
                        foregroundColor: AppTheme.primary,
                        child: comment.authorAvatar != null && comment.authorAvatar!.isNotEmpty
                            ? ClipOval(
                                child: Image.network(
                                  comment.authorAvatar!,
                                  width: 36,
                                  height: 36,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Text(
                                    comment.authorName.substring(0, 1).toUpperCase(),
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              )
                            : Text(
                                comment.authorName.substring(0, 1).toUpperCase(),
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              GestureDetector(
                                onTap: onProfileTap,
                                child: Text(
                                  comment.authorName,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: _getRoleColor(comment.authorRole).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  _getRoleLabel(comment.authorRole),
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: _getRoleColor(comment.authorRole),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Text(
                                comment.authorEmail,
                                style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _toPersianDate(comment.date),
                                style: TextStyle(fontSize: 10, color: AppTheme.textMuted),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (isRoot) CommentStatusBadge(status: comment.status, compact: true),
                  ],
                ),
                const SizedBox(height: 8),

                // ===== محتوا =====
                Text(
                  comment.content.replaceAll(RegExp(r'<[^>]*>'), ''),
                  style: TextStyle(fontSize: 13, color: AppTheme.textPrimary, height: 1.5),
                ),
                const SizedBox(height: 8),

                // ===== دکمه پاسخ (ارسال خود comment) =====
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: TextButton.icon(
                    onPressed: () => onReply(comment), // ← ارسال comment به onReply
                    icon: const Icon(Icons.reply_outlined, size: 14),
                    label: const Text('پاسخ', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ===== فرزندان =====
          if (comment.hasChildren)
            ...comment.children!.map((child) => CommentThread(
                  comment: child,
                  depth: depth + 1,
                  onReply: onReply,
                  onProfileTap: onProfileTap,
                )),
        ],
      ),
    );
  }
}