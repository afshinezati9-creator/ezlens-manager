// lib/features/comments/presentation/widgets/comment_status_badge.dart

import 'package:flutter/material.dart';
import 'package:ezlens_manager/core/theme/app_theme.dart'; // ← مسیر درست
import '../../data/comment_models.dart';

class CommentStatusBadge extends StatelessWidget {
  final CommentStatus status;
  final bool compact;

  const CommentStatusBadge({
    super.key,
    required this.status,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final (bg, fg, icon) = _getStatusData();

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 10,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 12 : 14, color: fg),
          if (!compact) const SizedBox(width: 4),
          if (!compact)
            Text(
              status.label,
              style: TextStyle(
                fontSize: compact ? 10 : 12,
                fontWeight: FontWeight.w600,
                color: fg,
              ),
            ),
        ],
      ),
    );
  }

  (Color, Color, IconData) _getStatusData() {
    switch (status) {
      case CommentStatus.approved:
        return (AppTheme.successBg, AppTheme.success, Icons.check_circle_outline);
      case CommentStatus.pending:
        return (AppTheme.warningBg, AppTheme.warning, Icons.hourglass_top_outlined);
      case CommentStatus.spam:
        return (AppTheme.dangerBg, AppTheme.danger, Icons.warning_amber_outlined);
      case CommentStatus.trash:
        return (AppTheme.surfaceHover, AppTheme.textMuted, Icons.delete_outline);
    }
  }
}