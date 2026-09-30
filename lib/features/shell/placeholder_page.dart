import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// صفحه موقت برای ماژول‌هایی که هنوز ساخته نشده‌اند
class PlaceholderPage extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;

  const PlaceholderPage({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = Icons.construction_outlined,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.surfaceHover,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                ),
                child: Icon(icon, size: 36, color: AppColors.textMuted),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                subtitle ?? 'این بخش در فازهای بعدی ساخته می‌شود',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
