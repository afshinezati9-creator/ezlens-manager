// lib/features/comments/presentation/widgets/comment_card.dart

import 'package:flutter/material.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import 'package:ezlens_manager/core/theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/comment_models.dart';
import 'comment_status_badge.dart';

class CommentCard extends StatelessWidget {
  final Comment comment;
  final VoidCallback onProfileTap;
  final VoidCallback onConversationTap;
  final void Function(CommentStatus) onStatusChange;
  final VoidCallback onDelete;

  const CommentCard({
    super.key,
    required this.comment,
    required this.onProfileTap,
    required this.onConversationTap,
    required this.onStatusChange,
    required this.onDelete,
  });

  String _toPersianDate(DateTime date) {
    final jalali = Jalali.fromDateTime(date);
    return '${jalali.year}/${jalali.month.toString().padLeft(2, '0')}/${jalali.day.toString().padLeft(2, '0')} - ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  IconData _getPostTypeIcon(String type) {
    switch (type) {
      case 'product':
        return Icons.shopping_bag_outlined;
      case 'post':
        return Icons.article_outlined;
      case 'page':
        return Icons.description_outlined;
      default:
        return Icons.comment_outlined;
    }
  }

  String _getPostTypeLabel(String type) {
    switch (type) {
      case 'product':
        return 'محصول';
      case 'post':
        return 'نوشته';
      case 'page':
        return 'برگه';
      default:
        return type;
    }
  }

  Future<void> _openLink(String? url) async {
    if (url == null || url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ===== هدر: آواتار + نام + نقش + وضعیت =====
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: onProfileTap,
                child: CircleAvatar(
                  radius: 22,
                  backgroundColor: AppTheme.primary.withOpacity(0.1),
                  foregroundColor: AppTheme.primary,
                  child: comment.authorAvatar != null && comment.authorAvatar!.isNotEmpty
                      ? ClipOval(
                          child: Image.network(
                            comment.authorAvatar!,
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Text(
                              comment.authorName.substring(0, 1).toUpperCase(),
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                        )
                      : Text(
                          comment.authorName.substring(0, 1).toUpperCase(),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(width: 12),
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
                              fontSize: isMobile ? 16 : 14,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        // ===== برچسب نقش کاربر =====
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getRoleColor(comment.authorRole).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _getRoleLabel(comment.authorRole),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: _getRoleColor(comment.authorRole),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.email_outlined, size: 14, color: AppTheme.textMuted),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            comment.authorEmail,
                            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (comment.authorPhone != null && comment.authorPhone!.isNotEmpty)
                      Row(
                        children: [
                          Icon(Icons.phone_outlined, size: 14, color: AppTheme.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            comment.authorPhone!,
                            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.calendar_today_outlined, size: 12, color: AppTheme.textMuted),
                        const SizedBox(width: 4),
                        Text(
                          _toPersianDate(comment.date),
                          style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              CommentStatusBadge(status: comment.status),
            ],
          ),
          const SizedBox(height: 12),

          // ============================================================
          // 🆕 بخش "از کجا آمده" با عنوان قابل کلیک (اصلاح شده)
          // ============================================================
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.surfaceHover,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.border.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () => _openLink(comment.postLink),
                  child: Row(
                    children: [
                      Icon(
                        _getPostTypeIcon(comment.postType),
                        size: 16,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          // ===== اگر postTitle خالی بود، از ID استفاده کن =====
                          comment.postTitle.isNotEmpty
                              ? comment.postTitle
                              : 'پست شماره ${comment.post}',
                          style: TextStyle(
                            fontSize: isMobile ? 15 : 13,
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(
                        Icons.open_in_new,
                        size: 18,
                        color: AppTheme.primary,
                      ),
                    ],
                  ),
                ),
                if (comment.postLink.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    comment.postLink,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textMuted,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 14, color: AppTheme.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      'نوع: ${_getPostTypeLabel(comment.postType)}',
                      style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ===== محتوا =====
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceHover.withOpacity(0.4),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              comment.content.replaceAll(RegExp(r'<[^>]*>'), ''),
              style: TextStyle(
                fontSize: isMobile ? 14 : 13,
                color: AppTheme.textPrimary,
                height: 1.6,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ===== دکمه‌های عملیات =====
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _actionButton(
                label: 'مکالمه',
                icon: Icons.forum_outlined,
                color: AppTheme.info,
                onTap: onConversationTap,
              ),
              if (comment.status != CommentStatus.approved)
                _actionButton(
                  label: 'تأیید',
                  icon: Icons.check_circle_outline,
                  color: AppTheme.success,
                  onTap: () => onStatusChange(CommentStatus.approved),
                ),
              if (comment.status == CommentStatus.approved)
                _actionButton(
                  label: 'معلق',
                  icon: Icons.hourglass_top_outlined,
                  color: AppTheme.warning,
                  onTap: () => onStatusChange(CommentStatus.pending),
                ),
              _actionButton(
                label: 'اسپم',
                icon: Icons.warning_amber_outlined,
                color: AppTheme.danger,
                onTap: () => onStatusChange(CommentStatus.spam),
              ),
              _actionButton(
                label: 'حذف',
                icon: Icons.delete_outline,
                color: AppTheme.textMuted,
                onTap: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        minimumSize: const Size(60, 36),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        side: BorderSide(color: color.withOpacity(0.3)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        foregroundColor: color,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  // ===== توابع نقش کاربر =====
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
}