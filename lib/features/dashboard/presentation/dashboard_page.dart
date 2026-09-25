import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../stats/data/stats_models.dart';
import '../../stats/data/stats_repository.dart';
import '../../users/data/user_models.dart';
import '../../users/data/user_repository.dart';

/// Overview stats for dashboard (week period).
final dashboardStatsProvider =
    FutureProvider.autoDispose<StatsSnapshot>((ref) {
  return ref.watch(statsRepositoryProvider).fetch(period: 'week');
});

/// Recent users sorted by last login (client-side).
final dashboardRecentLoginsProvider =
    FutureProvider.autoDispose<List<ManagerUser>>((ref) async {
  final repo = ref.watch(userRepositoryProvider);
  final result = await repo.fetchUsers(
    page: 1,
    perPage: 20,
    orderby: 'registered_date',
    order: 'desc',
  );
  final list = List<ManagerUser>.from(result.items);
  list.sort((a, b) {
    final aa = a.lastLogin ??
        a.dateCreated ??
        DateTime.fromMillisecondsSinceEpoch(0);
    final bb = b.lastLogin ??
        b.dateCreated ??
        DateTime.fromMillisecondsSinceEpoch(0);
    return bb.compareTo(aa);
  });
  return list.take(8).toList();
});

/// Latest products with views.
final dashboardLatestProductsProvider =
    FutureProvider.autoDispose<List<TopContentItem>>((ref) {
  return ref.watch(statsRepositoryProvider).latestProductsWithViews(limit: 6);
});

/// Latest posts/articles with views.
final dashboardLatestPostsProvider =
    FutureProvider.autoDispose<List<TopContentItem>>((ref) {
  return ref.watch(statsRepositoryProvider).latestPostsWithViews(limit: 6);
});

/// نام‌های مستعار (alias) برای استفاده در UI.
/// توجه: این‌ها Provider هستند — نه AsyncValue.
/// برای دسترسی به داده، از `ref.watch(productsViewsAsync)` استفاده کن.
final productsViewsAsync = dashboardLatestProductsProvider;
final postsViewsAsync = dashboardLatestPostsProvider;

String _fmtNum(int n) {
  final s = n.abs().toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    final idx = s.length - i;
    buf.write(s[i]);
    if (idx > 1 && idx % 3 == 1) buf.write(',');
  }
  final out = buf.toString();
  return n < 0 ? '-$out' : out;
}

String _pad2(int n) => n < 10 ? '0$n' : '$n';

String _jalaliWithTime(DateTime? d) {
  if (d == null) return '—';
  final local = d.toLocal();
  final date = '${local.year}/${_pad2(local.month)}/${_pad2(local.day)}';
  final time = '${_pad2(local.hour)}:${_pad2(local.minute)}';
  return '$date  ·  $time';
}

String _displayName(ManagerUser u) {
  final n = '${u.firstName} ${u.lastName}'.trim();
  if (n.isNotEmpty) return n;
  if (u.displayName.isNotEmpty) return u.displayName;
  if (u.email.isNotEmpty) return u.email;
  if (u.username.isNotEmpty) return u.username;
  return 'کاربر #${u.id}';
}

/// Dashboard = overview cards + navigation hub.
class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  static const _sections = <_DashItem>[
    _DashItem(
      title: 'محصولات',
      route: '/products',
      icon: Icons.inventory_2_outlined,
      group: 'فروشگاه',
    ),
    _DashItem(
      title: 'سفارش‌ها',
      route: '/orders',
      icon: Icons.receipt_long_outlined,
      group: 'فروشگاه',
    ),
    _DashItem(
      title: 'مقالات',
      route: '/articles',
      icon: Icons.article_outlined,
      group: 'محتوا',
    ),
    _DashItem(
      title: 'نظرات',
      route: '/comments',
      icon: Icons.chat_bubble_outline,
      group: 'محتوا',
    ),
    _DashItem(
      title: 'مشتریان',
      route: '/users',
      icon: Icons.people_outline,
      group: 'کاربران',
    ),
    _DashItem(
      title: 'پشتیبانی',
      route: '/support',
      icon: Icons.support_agent_outlined,
      group: 'ارتباطات',
    ),
    _DashItem(
      title: 'پیام تکی',
      route: '/messages',
      icon: Icons.send_outlined,
      group: 'ارتباطات',
    ),
    _DashItem(
      title: 'پیام گروهی',
      route: '/mass',
      icon: Icons.campaign_outlined,
      group: 'ارتباطات',
    ),
    _DashItem(
      title: 'کمپین',
      route: '/campaign',
      icon: Icons.hub_outlined,
      group: 'ارتباطات',
    ),
    _DashItem(
      title: 'صندوق ایمیل',
      route: '/inbox',
      icon: Icons.inbox_outlined,
      group: 'ارتباطات',
    ),
    _DashItem(
      title: 'شارژ کیف پول',
      route: '/wallet',
      icon: Icons.account_balance_wallet_outlined,
      group: 'مالی',
    ),
    _DashItem(
      title: 'تخفیف و هدیه',
      route: '/discounts',
      icon: Icons.local_offer_outlined,
      group: 'مالی',
    ),
    _DashItem(
      title: 'همیاری بینایی',
      route: '/charity',
      icon: Icons.volunteer_activism_outlined,
      group: 'مالی',
    ),
    _DashItem(
      title: 'آمار',
      route: '/stats',
      icon: Icons.insights_outlined,
      group: 'سیستم',
    ),
    _DashItem(
      title: 'فرآیند خرید',
      route: '/purchase',
      icon: Icons.shopping_bag_outlined,
      group: 'سیستم',
    ),
    _DashItem(
      title: 'تنظیمات',
      route: '/settings',
      icon: Icons.settings_outlined,
      group: 'سیستم',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = <String, List<_DashItem>>{};
    for (final item in _sections) {
      groups.putIfAbsent(item.group, () => []).add(item);
    }

    final statsAsync = ref.watch(dashboardStatsProvider);
    final loginsAsync = ref.watch(dashboardRecentLoginsProvider);

    // 🔴 اصلاح شد: به جای فراخوانی مستقیم .when() روی Provider،
    // از ref.watch(provider) استفاده می‌کنیم تا AsyncValue بگیریم.
    final productsAsync = ref.watch(productsViewsAsync);
    final postsAsync = ref.watch(postsViewsAsync);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('داشبورد'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'بروزرسانی',
            onPressed: () {
              ref.invalidate(dashboardStatsProvider);
              ref.invalidate(dashboardRecentLoginsProvider);
              ref.invalidate(dashboardLatestProductsProvider);
              ref.invalidate(dashboardLatestPostsProvider);
            },
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // همه‌ی بخش‌های داشبورد باید در refresh واقعاً دوباره از سرور خوانده شوند.
          ref.invalidate(dashboardStatsProvider);
          ref.invalidate(dashboardRecentLoginsProvider);
          ref.invalidate(dashboardLatestProductsProvider);
          ref.invalidate(dashboardLatestPostsProvider);
          await Future.wait([
            ref.read(dashboardStatsProvider.future),
            ref.read(dashboardRecentLoginsProvider.future),
            ref.read(dashboardLatestProductsProvider.future),
            ref.read(dashboardLatestPostsProvider.future),
          ]);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            // —— Overview ——
            const _SectionLabel(title: 'وضعیت کلی'),
            const SizedBox(height: 10),
            statsAsync.when(
              loading: () => const _StatsSkeleton(),
              error: (e, _) => _ErrorSoft(
                message: 'آمار در دسترس نیست',
                detail: e.toString(),
                onRetry: () => ref.invalidate(dashboardStatsProvider),
              ),
              data: (s) => _StatsGrid(snapshot: s),
            ),
            const SizedBox(height: 22),

            // —— Recent logins ——
            const _SectionLabel(title: 'آخرین ورودها'),
            const SizedBox(height: 10),
            loginsAsync.when(
              loading: () => const _LoginsSkeleton(),
              error: (e, _) => _ErrorSoft(
                message: 'لیست ورودها در دسترس نیست',
                detail: e.toString(),
                onRetry: () => ref.invalidate(dashboardRecentLoginsProvider),
              ),
              data: (users) => _RecentLoginsCard(users: users),
            ),
            const SizedBox(height: 22),

            // —— Latest products views ——
            const _SectionLabel(title: 'بازدید محصولات جدید'),
            const SizedBox(height: 10),
            productsAsync.when(
              loading: () => const _LoginsSkeleton(),
              error: (e, _) => _ErrorSoft(
                message: 'بازدید محصولات در دسترس نیست',
                detail: e.toString(),
                onRetry: () =>
                    ref.invalidate(dashboardLatestProductsProvider),
              ),
              data: (items) => _ViewsListCard(
                items: items,
                emptyText: 'محصولی یافت نشد',
                onTap: (id) => context.go('/products/$id'),
              ),
            ),
            const SizedBox(height: 22),

            // —— Latest posts views ——
            const _SectionLabel(title: 'بازدید مقالات جدید'),
            const SizedBox(height: 10),
            postsAsync.when(
              loading: () => const _LoginsSkeleton(),
              error: (e, _) => _ErrorSoft(
                message: 'بازدید مقالات در دسترس نیست',
                detail: e.toString(),
                onRetry: () => ref.invalidate(dashboardLatestPostsProvider),
              ),
              data: (items) => _ViewsListCard(
                items: items,
                emptyText: 'مقاله‌ای یافت نشد',
                onTap: (id) => context.go('/articles/$id/edit'),
              ),
            ),
            const SizedBox(height: 22),

            // —— Navigation ——
            const _SectionLabel(title: 'دسترسی سریع'),
            const SizedBox(height: 8),
            for (final entry in groups.entries) ...[
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 8),
                child: Text(
                  entry.key,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary.withOpacity(0.9),
                  ),
                ),
              ),
              LayoutBuilder(
                builder: (context, c) {
                  final w = c.maxWidth;
                  final cross = w >= 900
                      ? 6
                      : w >= 700
                          ? 5
                          : w >= 500
                              ? 4
                              : 3;
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: entry.value.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: cross,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 1.05,
                    ),
                    itemBuilder: (context, i) {
                      return _DashTile(item: entry.value[i]);
                    },
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String title;
  const _SectionLabel({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final StatsSnapshot snapshot;
  const _StatsGrid({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final cards = [
      _StatCardData(
        label: 'بازدید محصولات',
        value: snapshot.totalProductViews,
        icon: Icons.visibility_outlined,
        gradient: const [Color(0xFF0B1F6B), Color(0xFF1E3A8A)],
      ),
      _StatCardData(
        label: 'فروش (تومان)',
        value: snapshot.revenue,
        icon: Icons.payments_outlined,
        gradient: const [Color(0xFF065F46), Color(0xFF047857)],
      ),
      _StatCardData(
        label: 'محصولات',
        value: snapshot.productsPublished,
        icon: Icons.inventory_2_outlined,
        gradient: const [Color(0xFF1E3A5F), Color(0xFF334155)],
      ),
      _StatCardData(
        label: 'مقالات',
        value: snapshot.postsTotal,
        icon: Icons.article_outlined,
        gradient: const [Color(0xFF4C1D95), Color(0xFF6D28D9)],
      ),
    ];

    return LayoutBuilder(
      builder: (context, c) {
        final cross = c.maxWidth >= 720 ? 4 : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cards.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cross,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: cross == 4 ? 1.55 : 1.45,
          ),
          itemBuilder: (_, i) =>
              _AnimatedStatCard(data: cards[i], delayMs: i * 80),
        );
      },
    );
  }
}

class _StatCardData {
  final String label;
  final int value;
  final IconData icon;
  final List<Color> gradient;
  const _StatCardData({
    required this.label,
    required this.value,
    required this.icon,
    required this.gradient,
  });
}

class _AnimatedStatCard extends StatelessWidget {
  final _StatCardData data;
  final int delayMs;
  const _AnimatedStatCard({required this.data, this.delayMs = 0});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 520 + delayMs),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) {
        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 12),
            child: child,
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: data.gradient,
          ),
          boxShadow: [
            BoxShadow(
              color: data.gradient.last.withOpacity(0.25),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(data.icon, color: Colors.white, size: 18),
                ),
                const Spacer(),
              ],
            ),
            const Spacer(),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: data.value.toDouble()),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutExpo,
              builder: (context, v, _) {
                return Text(
                  _fmtNum(v.round()),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                );
              },
            ),
            const SizedBox(height: 4),
            Text(
              data.label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.85),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentLoginsCard extends StatelessWidget {
  final List<ManagerUser> users;
  const _RecentLoginsCard({required this.users});

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          'هنوز ورودی ثبت نشده است',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < users.length; i++) ...[
            if (i > 0)
              Divider(height: 1, color: AppColors.border.withOpacity(0.7)),
            _LoginRow(user: users[i], index: i),
          ],
        ],
      ),
    );
  }
}

class _LoginRow extends StatelessWidget {
  final ManagerUser user;
  final int index;
  const _LoginRow({required this.user, required this.index});

  @override
  Widget build(BuildContext context) {
    final when = user.lastLogin ?? user.dateCreated;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 400 + index * 60),
      curve: Curves.easeOut,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset((1 - t) * 10, 0),
          child: child,
        ),
      ),
      child: InkWell(
        onTap: () => context.go('/users/${user.id}'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  () {
                    final n = _displayName(user);
                    return n.isNotEmpty ? n[0] : '?';
                  }(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _displayName(user),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.username.isNotEmpty
                          ? user.username
                          : (user.email.isNotEmpty ? user.email : '—'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Icon(
                    Icons.schedule_outlined,
                    size: 14,
                    color: AppColors.textSecondary.withOpacity(0.8),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _jalaliWithTime(when),
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatsSkeleton extends StatelessWidget {
  const _StatsSkeleton();
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final cross = c.maxWidth >= 720 ? 4 : 2;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: cross,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.5,
          children: List.generate(
            4,
            (_) => Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LoginsSkeleton extends StatelessWidget {
  const _LoginsSkeleton();
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
    );
  }
}

class _ErrorSoft extends StatelessWidget {
  final String message;
  final String detail;
  final VoidCallback onRetry;
  const _ErrorSoft({
    required this.message,
    required this.detail,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 13),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('تلاش مجدد')),
        ],
      ),
    );
  }
}

class _ViewsListCard extends StatelessWidget {
  final List<TopContentItem> items;
  final String emptyText;
  final void Function(int id) onTap;

  const _ViewsListCard({
    required this.items,
    required this.emptyText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child:
            Text(emptyText, style: TextStyle(color: AppColors.textSecondary)),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0)
              Divider(height: 1, color: AppColors.border.withOpacity(0.7)),
            InkWell(
              onTap: () => onTap(items[i].id),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                        image: items[i].image.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(items[i].image),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: items[i].image.isEmpty
                          ? Icon(
                              items[i].type == 'product'
                                  ? Icons.inventory_2_outlined
                                  : Icons.article_outlined,
                              color: AppColors.primary,
                              size: 20,
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        items[i].title.isEmpty ? '—' : items[i].title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          height: 1.3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.visibility_outlined,
                              size: 14,
                              color: AppColors.primary.withOpacity(0.9)),
                          const SizedBox(width: 4),
                          Text(
                            _fmtNum(items[i].views),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DashItem {
  final String title;
  final String route;
  final IconData icon;
  final String group;

  const _DashItem({
    required this.title,
    required this.route,
    required this.icon,
    required this.group,
  });
}

class _DashTile extends StatelessWidget {
  final _DashItem item;
  const _DashTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.go(item.route),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.icon, color: AppColors.primary, size: 24),
              ),
              const SizedBox(height: 10),
              Text(
                item.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}