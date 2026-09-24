import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../auth/presentation/auth_provider.dart';

class MorePage extends ConsumerWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = const [
      _MoreItem(
        icon: Icons.people_outline_rounded,
        title: 'کاربران',
        subtitle: 'مدیریت مشتریان و کاربران',
        route: '/users',
      ),
      _MoreItem(
        icon: Icons.support_agent_outlined,
        title: 'پشتیبانی',
        subtitle: 'تیکت‌ها و گفتگو با مشتریان',
        route: '/support',
      ),
      _MoreItem(
        icon: Icons.send_outlined,
        title: 'پیام تکی',
        subtitle: 'ارسال ایمیل و پیامک به مشتری',
        route: '/messages',
      ),
      _MoreItem(
        icon: Icons.hub_outlined,
        title: 'کمپین',
        subtitle: 'دفترچه مخاطبان و ارسال گروهی',
        route: '/campaign',
      ),
      _MoreItem(
        icon: Icons.campaign_outlined,
        title: 'پیام جمعی',
        subtitle: 'ارسال گروهی به مشتریان سایت',
        route: '/mass',
      ),
      _MoreItem(
        icon: Icons.account_balance_wallet_outlined,
        title: 'شارژ کیف پول',
        subtitle: 'تأیید واریز و تعدیل موجودی',
        route: '/wallet',
      ),
      _MoreItem(
        icon: Icons.visibility_outlined,
        title: 'هم‌یاری بینایی',
        subtitle: 'موارد، کمک‌ها و گزارش اثر',
        route: '/charity',
      ),
      _MoreItem(
        icon: Icons.local_offer_outlined,
        title: 'تخفیف و هدیه',
        subtitle: 'کد تخفیف و کارت هدیه',
        route: '/discounts',
      ),
      _MoreItem(
        icon: Icons.integration_instructions_outlined,
        title: 'فرآیند خرید',
        subtitle: 'اسکریپت‌های PHP فروشگاه',
        route: '/purchase',
      ),
      _MoreItem(
        icon: Icons.inbox_outlined,
        title: 'صندوق ایمیل',
        subtitle: 'پیام‌های دریافتی info@',
        route: '/inbox',
      ),
      _MoreItem(
        icon: Icons.image_outlined,
        title: 'رسانه‌ها',
        subtitle: 'گالری و فایل‌ها',
        route: '/media',
      ),
      _MoreItem(
        icon: Icons.chat_bubble_outline_rounded,
        title: 'نظرات',
        subtitle: 'مدیریت نظرات سایت',
        route: '/comments',
      ),
      _MoreItem(
        icon: Icons.assignment_outlined,
        title: 'درخواست‌ها',
        subtitle: 'مدیریت درخواست‌های فرم‌های سایت',
        route: '/requests',
      ),
      _MoreItem(
        icon: Icons.sticky_note_2_outlined,
        title: 'یادداشت‌ها',
        subtitle: 'یادداشت‌های داخلی تیم',
        route: '/notes',
      ),
      _MoreItem(
        icon: Icons.article_outlined,
        title: 'مقالات',
        subtitle: 'محتوای وبلاگ',
        route: '/articles',
      ),
            _MoreItem(
        icon: Icons.bar_chart_outlined,
        title: 'آمار',
        subtitle: 'فروش، بازدید محصول، مشتریان',
        route: '/stats',
      ),
_MoreItem(
        icon: Icons.settings_outlined,
        title: 'تنظیمات',
        subtitle: 'پیکربندی اپلیکیشن',
        route: '/settings',
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('بیشتر'),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          ...items.map(
            (item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: AppCard(
                  onTap: () {
                    const placeholderRoutes = <String>[];
                    if (placeholderRoutes.contains(item.route)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'صفحه «${item.title}» در فازهای بعدی ساخته می‌شود',
                          ),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      return;
                    }
                    context.go(item.route);
                  },
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(item.icon,
                            color: AppColors.primary, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.subtitle,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_left,
                        color: AppColors.textMuted,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.logout, color: AppColors.danger, size: 20),
                SizedBox(width: 8),
                Text(
                  'خروج از حساب',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.danger,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MoreItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final String route;

  const _MoreItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
  });
}
