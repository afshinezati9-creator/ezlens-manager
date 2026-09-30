// lib/features/comments/presentation/widgets/user_profile_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import 'package:ezlens_manager/core/theme/app_theme.dart';
import '../../data/comment_models.dart';
import '../comment_provider.dart';

class UserProfileDialog extends ConsumerWidget {
  final int userId;

  const UserProfileDialog({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider(userId));

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(Icons.person_outline, color: AppTheme.primary),
          const SizedBox(width: 8),
          const Text('مشخصات کاربر'),
        ],
      ),
      content: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 400),
        child: profileAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          error: (err, _) => Center(
            child: Text(
              'خطا در دریافت اطلاعات: $err',
              style: TextStyle(color: AppTheme.danger),
            ),
          ),
          data: (profile) => _buildContent(context, profile),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('بستن'),
        ),
        if (userId > 0)
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // در صورت نیاز به صفحه کاربر
            },
            child: const Text('مشاهده کامل', style: TextStyle(color: AppTheme.primary)),
          ),
      ],
    );
  }

  Widget _buildContent(BuildContext context, UserProfile profile) {
    final isGuest = profile.id == 0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ===== هدر با آواتار =====
        Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: AppTheme.primary.withOpacity(0.1),
              foregroundColor: AppTheme.primary,
              child: Text(
                (profile.firstName.isNotEmpty ? profile.firstName[0] : profile.email[0]).toUpperCase(),
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.fullName.isNotEmpty ? profile.fullName : 'کاربر مهمان',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      Icon(Icons.email_outlined, size: 14, color: AppTheme.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        profile.email,
                        style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      profile.roleLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Divider(),

        // ===== اطلاعات =====
        if (!isGuest) ...[
          _infoRow('تلفن', profile.phone ?? 'ندارد'),
          _infoRow('شهر', profile.city ?? 'ندارد'),
          _infoRow('آدرس', profile.address ?? 'ندارد'),
          _infoRow('مجموع خرید', _formatPrice(profile.totalSpent)),
          _infoRow('تاریخ عضویت', profile.dateCreated != null ? _toPersianDate(profile.dateCreated!) : '—'),
        ] else ...[
          const Center(
            child: Text(
              'کاربر مهمان (حذف شده یا ثبت‌نام نکرده)',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
          ),
        ],
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  String _formatPrice(String? price) {
    if (price == null || price.isEmpty) return '—';
    final n = double.tryParse(price) ?? 0;
    return n.toInt().toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    ) + ' تومان';
  }

  String _toPersianDate(DateTime date) {
    final jalali = Jalali.fromDateTime(date);
    return '${jalali.year}/${jalali.month.toString().padLeft(2, '0')}/${jalali.day.toString().padLeft(2, '0')}';
  }
}