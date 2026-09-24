import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

enum AppBadgeType { success, warning, danger, info, neutral }

class AppBadge extends StatelessWidget {
  final String label;
  final AppBadgeType type;

  const AppBadge({
    super.key,
    required this.label,
    this.type = AppBadgeType.neutral,
  });

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (type) {
      AppBadgeType.success => (AppColors.successBg, AppColors.success),
      AppBadgeType.warning => (AppColors.warningBg, AppColors.warning),
      AppBadgeType.danger => (AppColors.dangerBg, AppColors.danger),
      AppBadgeType.info => (AppColors.infoBg, AppColors.info),
      AppBadgeType.neutral => (AppColors.surfaceHover, AppColors.textSecondary),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}