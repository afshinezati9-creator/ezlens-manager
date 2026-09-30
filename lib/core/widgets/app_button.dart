import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

enum AppButtonVariant { primary, secondary, cta, outline, ghost }
enum AppButtonSize { sm, md, lg }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final bool isLoading;
  final bool isExpanded;
  final IconData? icon;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.md,
    this.isLoading = false,
    this.isExpanded = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final height = switch (size) {
      AppButtonSize.sm => 36.0,
      AppButtonSize.md => 44.0,
      AppButtonSize.lg => 52.0,
    };

    final fontSize = switch (size) {
      AppButtonSize.sm => 13.0,
      AppButtonSize.md => 14.0,
      AppButtonSize.lg => 16.0,
    };

    final (bg, fg, border) = switch (variant) {
      AppButtonVariant.primary => (AppColors.primary, Colors.white, null),
      AppButtonVariant.secondary => (AppColors.secondary, Colors.white, null),
      AppButtonVariant.cta => (AppColors.cta, Colors.white, null),
      AppButtonVariant.outline => (Colors.transparent, AppColors.primary, AppColors.primary),
      AppButtonVariant.ghost => (Colors.transparent, AppColors.textPrimary, null),
    };

    return SizedBox(
      width: isExpanded ? double.infinity : null,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            side: border != null ? BorderSide(color: border) : BorderSide.none,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20),
        ),
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: fg,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: fontSize + 2),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}