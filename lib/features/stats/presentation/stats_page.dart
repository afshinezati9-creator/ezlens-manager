import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_skeleton.dart';
import '../data/stats_models.dart';
import 'stats_provider.dart';
import 'stats_visual_dashboard_page.dart';

String _fa(String s) {
  const en = '0123456789';
  const fa = '۰۱۲۳۴۵۶۷۸۹';
  var o = s;
  for (var i = 0; i < 10; i++) {
    o = o.replaceAll(en[i], fa[i]);
  }
  return o;
}

String _money(int n) {
  final f = n.toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );
  return '${_fa(f)} تومان';
}

class StatsPage extends ConsumerWidget {
  const StatsPage({super.key});

  static const _periods = [
    ('day', 'امروز'),
    ('week', '۷ روز'),
    ('month', '۳۰ روز'),
    ('all', 'کل'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(statsPeriodProvider);
    final snapAsync = ref.watch(statsSnapshotProvider);
    final topViews = ref.watch(topByViewsProvider);
    final topSales = ref.watch(topBySalesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('آمار'),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
        ),
        actions: [
          IconButton(
            tooltip: 'آمار بصری',
            icon: const Icon(Icons.insights_rounded),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const StatsVisualDashboardPage(),
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'بازدیدکنندگان و ایندکس',
            icon: const Icon(Icons.travel_explore_rounded),
            onPressed: () {
              showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                backgroundColor: AppColors.surface,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                ),
                builder: (_) => const _VisitorsIndexSheet(),
              );
            },
          ),
          IconButton(
            tooltip: 'بروزرسانی',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              ref.invalidate(statsSnapshotProvider);
              ref.invalidate(topByViewsProvider);
              ref.invalidate(topBySalesProvider);
              ref.invalidate(latestPostsWithViewsProvider);
              ref.invalidate(topArticlesByViewsProvider);
              ref.invalidate(articleViewsSumProvider);
              ref.invalidate(recentVisitorsProvider);
                            ref.invalidate(articleViewsSumProvider);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _PeriodPalette(
            period: period,
            onSelect: (id) {
              ref.read(statsPeriodProvider.notifier).state = id;
            },
          ),
          Expanded(
            child: snapAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(16),
                child: AppSkeletonList(itemCount: 6),
              ),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'خطا در بارگذاری آمار:\n$e\n\nREST را لود کنید و پیوندهای یکتا را ذخیره کنید.',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              data: (s) => RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(statsSnapshotProvider);
                  ref.invalidate(topByViewsProvider);
                  ref.invalidate(topBySalesProvider);
                  ref.invalidate(latestPostsWithViewsProvider);
              ref.invalidate(topArticlesByViewsProvider);
              ref.invalidate(articleViewsSumProvider);
                },
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                  children: [
                    if (s.rangeFa.isNotEmpty)
                      _InfoChip(text: 'بازه: ${s.rangeFa}'),
                    const SizedBox(height: 12),

                    _AnimatedSection(
                      delayMs: 0,
                      child: _PaletteCard(
                        title: 'فروش و سفارش',
                        icon: Icons.shopping_bag_outlined,
                        gradient: const [Color(0xFF0F172A), Color(0xFF1E3A5F)],
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _KpiTile(
                                    label: 'سفارش‌ها',
                                    value: _fa('${s.ordersCount}'),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _KpiTile(
                                    label: 'فروش',
                                    value: _money(s.revenue),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: _KpiTile(
                                    label: 'میانگین سبد',
                                    value: _money(s.avgOrder),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _KpiTile(
                                    label: 'مشتریان جدید',
                                    value: _fa('${s.newCustomers}'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    _AnimatedSection(
                      delayMs: 60,
                      child: _PaletteCard(
                        title: 'وضعیت سفارش‌ها',
                        icon: Icons.pie_chart_outline_rounded,
                        gradient: const [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                        child: s.byStatus.isEmpty
                            ? const Text(
                                'وضعیتی ثبت نشده',
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 12,
                                ),
                              )
                            : Column(
                                children: [
                                  for (final st in s.byStatus)
                                    _StatusRow(
                                      label: st.label.isNotEmpty
                                          ? st.label
                                          : st.status,
                                      count: st.count,
                                    ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    _AnimatedSection(
                      delayMs: 120,
                      child: _PaletteCard(
                        title: 'محتوا و بازدید',
                        icon: Icons.visibility_outlined,
                        gradient: const [Color(0xFF4C1D95), Color(0xFF7C3AED)],
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _KpiTile(
                                    label: 'مقالات',
                                    value: _fa('${s.postsTotal}'),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _KpiTile(
                                    label: 'مقالات جدید',
                                    value: _fa('${s.postsNew}'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: _KpiTile(
                                    label: 'بازدید محصولات',
                                    value: _fa('${s.totalProductViews}'),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _KpiTile(
                                    label: 'بازدید مقالات',
                                    value: _fa(
                                      '${ref.watch(articleViewsSumProvider).valueOrNull ?? (s.totalPostViews > 0 ? s.totalPostViews : 0)}',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: _KpiTile(
                                    label: 'بازدید صفحات',
                                    value: _fa('${s.totalPageViews}'),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _KpiTile(
                                    label: 'نظرات',
                                    value: _fa('${s.comments}'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    _AnimatedSection(
                      delayMs: 180,
                      child: _PaletteCard(
                        title: 'پرفروش‌ترین محصولات',
                        icon: Icons.local_fire_department_outlined,
                        gradient: const [Color(0xFF9A3412), Color(0xFFEA580C)],
                        child: topSales.when(
                          loading: () => const AppSkeletonList(
                            itemCount: 3,
                            padding: EdgeInsets.zero,
                          ),
                          error: (_, __) => const Text(
                            'در دسترس نیست',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                          data: (items) => _TopList(items: items, suffix: 'فروش'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    _AnimatedSection(
                      delayMs: 220,
                      child: _PaletteCard(
                        title: 'پربازدیدترین محصولات',
                        icon: Icons.trending_up_rounded,
                        gradient: const [Color(0xFF0F766E), Color(0xFF14B8A6)],
                        child: topViews.when(
                          loading: () => const AppSkeletonList(
                            itemCount: 3,
                            padding: EdgeInsets.zero,
                          ),
                          error: (_, __) => const Text(
                            'در دسترس نیست',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                          data: (items) =>
                              _TopList(items: items, suffix: 'بازدید'),
                        ),
                      ),
                    ),

                    _AnimatedSection(
                      delayMs: 240,
                      child: _PaletteCard(
                        title: 'پربازدیدترین مقالات',
                        icon: Icons.article_outlined,
                        gradient: const [Color(0xFF5B21B6), Color(0xFF8B5CF6)],
                        child: ref.watch(topArticlesByViewsProvider).when(
                          loading: () => const AppSkeletonList(
                            itemCount: 3,
                            padding: EdgeInsets.zero,
                          ),
                          error: (_, __) => const Text(
                            'در دسترس نیست',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                          data: (items) {
                            final posts = items
                                .where((e) => e.type != 'product')
                                .toList();
                            if (posts.isEmpty) {
                              return const Text(
                                'مقاله‌ای نیست',
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 12,
                                ),
                              );
                            }
                            return _TopContentList(
                              items: posts,
                              suffix: 'بازدید',
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    _AnimatedSection(
                      delayMs: 260,
                      child: _PaletteCard(
                        title: 'بازدید صفحات سایت',
                        icon: Icons.web_asset_rounded,
                        gradient: const [Color(0xFF0E7490), Color(0xFF06B6D4)],
                        child: ref.watch(sitePagesViewsProvider).when(
                          loading: () => const AppSkeletonList(
                            itemCount: 3,
                            padding: EdgeInsets.zero,
                          ),
                          error: (_, __) => const Text(
                            'در دسترس نیست',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                          data: (items) {
                            if (items.isEmpty) {
                              return const Text(
                                'صفحه‌ای نیست یا شمارنده ثبت نشده',
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 12,
                                ),
                              );
                            }
                            return _TopContentList(
                              items: items,
                              suffix: 'بازدید',
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    if (s.noteGa4.isNotEmpty || s.noteProductViews.isNotEmpty) ...[

                      const SizedBox(height: 14),
                      _AnimatedSection(
                        delayMs: 260,
                        child: _PaletteCard(
                          title: 'یادداشت‌ها',
                          icon: Icons.info_outline_rounded,
                          gradient: const [Color(0xFF334155), Color(0xFF64748B)],
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (s.noteProductViews.isNotEmpty)
                                Text(
                                  s.noteProductViews,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    height: 1.45,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              if (s.noteGa4.isNotEmpty) ...[
                                if (s.noteProductViews.isNotEmpty)
                                  const SizedBox(height: 8),
                                Text(
                                  'GA4: ${s.noteGa4}',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    height: 1.45,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodPalette extends StatelessWidget {
  final String period;
  final ValueChanged<String> onSelect;

  const _PeriodPalette({required this.period, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          for (final p in StatsPage._periods) ...[
            Expanded(
              child: GestureDetector(
                onTap: () => onSelect(p.$1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: period == p.$1
                        ? const LinearGradient(
                            colors: [Color(0xFF071B7A), Color(0xFF1D4ED8)],
                          )
                        : null,
                    color: period == p.$1 ? null : Colors.transparent,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    p.$2,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight:
                          period == p.$1 ? FontWeight.w800 : FontWeight.w600,
                      color: period == p.$1
                          ? Colors.white
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PaletteCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Color> gradient;
  final Widget child;

  const _PaletteCard({
    required this.title,
    required this.icon,
    required this.gradient,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: gradient.last.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerRight,
                end: Alignment.centerLeft,
                colors: gradient,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(icon, size: 17, color: Colors.white),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _KpiTile extends StatelessWidget {
  final String label;
  final String value;

  const _KpiTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final String label;
  final int count;

  const _StatusRow({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _fa('$count'),
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopList extends StatelessWidget {
  final List<TopProduct> items;
  final String suffix;

  const _TopList({required this.items, required this.suffix});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Text(
        'داده‌ای نیست',
        style: TextStyle(color: AppColors.textMuted, fontSize: 12),
      );
    }
    return Column(
      children: [
        for (var i = 0; i < items.length; i++)
          Container(
            margin: EdgeInsets.only(bottom: i == items.length - 1 ? 0 : 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _fa('${i + 1}'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    items[i].title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${_fa('${items[i].score}')} $suffix',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String text;
  const _InfoChip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.textMuted,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _AnimatedSection extends StatelessWidget {
  final int delayMs;
  final Widget child;

  const _AnimatedSection({required this.delayMs, required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 420 + delayMs),
      curve: Curves.easeOutCubic,
      builder: (context, t, c) {
        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 14),
            child: c,
          ),
        );
      },
      child: child,
    );
  }
}

class _TopContentList extends StatelessWidget {
  final List<TopContentItem> items;
  final String suffix;

  const _TopContentList({required this.items, required this.suffix});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < items.length; i++)
          Container(
            margin: EdgeInsets.only(bottom: i == items.length - 1 ? 0 : 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _fa('${i + 1}'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    items[i].title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${_fa('${items[i].views}')} $suffix',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}




class _VisitorsIndexSheet extends ConsumerWidget {
  const _VisitorsIndexSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visitors = ref.watch(recentVisitorsProvider);
    final height = MediaQuery.of(context).size.height * 0.82;

    return SafeArea(
      child: SizedBox(
        height: height,
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'بازدیدکنندگان و خلاصه ترافیک',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'آخرین بازدیدها · صفحات پرترافیک · منبع ورود · نوع دستگاه',
                          style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w400),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: visitors.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('خطا: $e', textAlign: TextAlign.center),
                  ),
                ),
                data: (list) {
                  bool isJunkPath(String p) {
                    final s = p.toLowerCase();
                    if (s.isEmpty || s == '/' || s == '—') return true;
                    // bots / security / cache noise
                    if (s.contains('wordfence') ||
                        s.contains('lscwp') ||
                        s.contains('wp-cron') ||
                        s.contains('xmlrpc') ||
                        s.contains('wp-json') ||
                        s.contains('admin-ajax') ||
                        s.contains('favicon') ||
                        s.contains('.map') ||
                        s.contains('robots.txt')) {
                      return true;
                    }
                    return false;
                  }

                  String cleanPath(String raw) {
                    var p = raw.trim();
                    // drop query string for ranking
                    final q = p.indexOf('?');
                    if (q >= 0) p = p.substring(0, q);
                    // collapse repeated slashes
                    p = p.replaceAll(RegExp(r'/+'), '/');
                    if (p.isEmpty) p = '/';
                    return p;
                  }

                  String friendlySource(String raw) {
                    final s = raw.trim().toLowerCase();
                    if (s.isEmpty || s == 'نامشخص') return 'ورود مستقیم';
                    if (s == 'php' || s == 'direct' || s == 'none') {
                      return 'ورود مستقیم';
                    }
                    if (s.contains('google')) return 'گوگل';
                    if (s.contains('bing')) return 'بینگ';
                    if (s.contains('yahoo')) return 'یاهو';
                    if (s.contains('instagram') || s == 'ig') return 'اینستاگرام';
                    if (s.contains('telegram') || s == 'tg') return 'تلگرام';
                    if (s.contains('twitter') || s.contains('x.com')) {
                      return 'توییتر / X';
                    }
                    if (s.contains('facebook') || s == 'fb') return 'فیسبوک';
                    return raw.trim();
                  }

                  String friendlyDevice(String raw) {
                    final s = raw.trim().toLowerCase();
                    if (s.isEmpty) return 'نامشخص';
                    if (s.contains('mobile') ||
                        s.contains('android') ||
                        s.contains('iphone') ||
                        s == 'phone') {
                      return 'موبایل';
                    }
                    if (s.contains('tablet') || s.contains('ipad')) {
                      return 'تبلت';
                    }
                    if (s.contains('desktop') ||
                        s.contains('computer') ||
                        s.contains('pc') ||
                        s.contains('windows') ||
                        s.contains('mac')) {
                      return 'کامپیوتر';
                    }
                    return raw.trim();
                  }

                  final pathCount = <String, int>{};
                  final sourceCount = <String, int>{};
                  final deviceCount = <String, int>{};
                  for (final v in list) {
                    final path = cleanPath(
                        v.path.isNotEmpty ? v.path : v.title);
                    if (!isJunkPath(path)) {
                      pathCount[path] = (pathCount[path] ?? 0) + 1;
                    }
                    final src = friendlySource(v.source);
                    sourceCount[src] = (sourceCount[src] ?? 0) + 1;
                    final dev = friendlyDevice(v.device);
                    deviceCount[dev] = (deviceCount[dev] ?? 0) + 1;
                  }
                  final topPaths = pathCount.entries.toList()
                    ..sort((a, b) => b.value.compareTo(a.value));
                  final topSources = sourceCount.entries.toList()
                    ..sort((a, b) => b.value.compareTo(a.value));
                  final topDevices = deviceCount.entries.toList()
                    ..sort((a, b) => b.value.compareTo(a.value));

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    children: [
                      _SheetSection(
                        title: 'آخرین بازدیدکنندگان',
                        subtitle: '۱۰ بازدید اخیر سایت',
                        color: const Color(0xFF059669),
                        child: list.isEmpty
                            ? const Text('هنوز بازدیدی ثبت نشده', style: TextStyle(color: AppColors.textMuted, fontSize: 12))
                            : Column(children: [for (final v in list) _VisitorRow(item: v)]),
                      ),
                      const SizedBox(height: 12),
                      _SheetSection(
                        title: 'صفحات پرترافیک سایت',
                        subtitle: 'آدرس صفحاتی که بیشترین بازدید را داشته‌اند',
                        color: const Color(0xFF0EA5E9),
                        child: topPaths.isEmpty
                            ? const Text('داده‌ای نیست', style: TextStyle(color: AppColors.textMuted, fontSize: 12))
                            : Column(children: [for (final e in topPaths.take(8)) _MiniStatRow(label: e.key, value: '${e.value} بازدید')]),
                      ),
                      const SizedBox(height: 12),
                      _SheetSection(
                        title: 'منابع ورود',
                        subtitle: 'از کجا به سایت آمده‌اند (گوگل، مستقیم، ...)',
                        color: const Color(0xFF7C3AED),
                        child: topSources.isEmpty
                            ? const Text('داده‌ای نیست', style: TextStyle(color: AppColors.textMuted, fontSize: 12))
                            : Column(children: [for (final e in topSources.take(6)) _MiniStatRow(label: e.key, value: '${e.value}')]),
                      ),
                      const SizedBox(height: 12),
                      _SheetSection(
                        title: 'نوع دستگاه',
                        subtitle: 'موبایل، تبلت یا دسکتاپ',
                        color: const Color(0xFFD97706),
                        child: topDevices.isEmpty
                            ? const Text('داده‌ای نیست', style: TextStyle(color: AppColors.textMuted, fontSize: 12))
                            : Column(children: [for (final e in topDevices.take(6)) _MiniStatRow(label: e.key, value: '${e.value}')]),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetSection extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Color color;
  final Widget child;
  const _SheetSection({
    required this.title,
    this.subtitle,
    required this.color,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.25)),
        boxShadow: [BoxShadow(color: color.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                  if (subtitle != null && subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ]),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _MiniStatRow extends StatelessWidget {
  final String label;
  final String value;
  const _MiniStatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Expanded(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF071B7A))),
      ]),
    );
  }
}

class _VisitorRow extends StatelessWidget {
  final RecentVisitor item;
  const _VisitorRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF0F766E).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            item.typeLabel,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF0F766E)),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title.isNotEmpty ? item.title : item.path,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
              const SizedBox(height: 2),
              Text(
                'از: ${item.fromLabel}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
              ),
              if (item.ip.isNotEmpty || item.country.isNotEmpty || item.device.isNotEmpty || item.os.isNotEmpty || item.browser.isNotEmpty) ...[
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    if (item.ip.isNotEmpty) _visitorMeta(Icons.public, 'IP: ${item.ip}'),
                    if (item.country.isNotEmpty) _visitorMeta(Icons.flag_outlined, item.country),
                    if (item.device.isNotEmpty) _visitorMeta(Icons.devices_outlined, item.device),
                    if (item.os.isNotEmpty) _visitorMeta(Icons.computer_outlined, item.os),
                    if (item.browser.isNotEmpty) _visitorMeta(Icons.language_outlined, item.browser),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          item.timeFa.isNotEmpty ? item.timeFa : '—',
          style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
  Widget _visitorMeta(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 3),
        Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B))),
      ],
    );
  }
}

class _GscSection extends ConsumerWidget {
  final String period;
  const _GscSection({required this.period});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overview = ref.watch(gscOverviewProvider);
    final queries = ref.watch(gscQueriesProvider);
    final pages = ref.watch(gscPagesProvider);

    return overview.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (g) {
        // Hide entire card when GSC is not configured / unavailable.
        if (!g.ok && g.clicks == 0 && g.impressions == 0) {
          return const SizedBox.shrink();
        }
        return _PaletteCard(
          title: 'Search Console (گوگل)',
          icon: Icons.travel_explore_rounded,
          gradient: const [Color(0xFF071B7A), Color(0xFF0EA5E9)],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${g.startDate} → ${g.endDate}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _GscKpi(label: 'کلیک', value: '${g.clicks}', color: const Color(0xFF071B7A))),
                  const SizedBox(width: 8),
                  Expanded(child: _GscKpi(label: 'نمایش', value: '${g.impressions}', color: const Color(0xFF0EA5E9))),
                  const SizedBox(width: 8),
                  Expanded(child: _GscKpi(label: 'CTR', value: '${g.ctr}%', color: const Color(0xFF059669))),
                  const SizedBox(width: 8),
                  Expanded(child: _GscKpi(label: 'رتبه', value: g.position.toStringAsFixed(1), color: const Color(0xFFD97706))),
                ],
              ),
              if (g.series.length >= 2) ...[
                const SizedBox(height: 14),
                SizedBox(height: 120, child: _GscMiniChart(series: g.series)),
              ],
              const SizedBox(height: 14),
              const Text('پرجستجوترین عبارات', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
              const SizedBox(height: 6),
              queries.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (rows) => _GscRowsList(rows: rows, empty: 'عبارتی نیست'),
              ),
              const SizedBox(height: 12),
              const Text('صفحات برتر در گوگل', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
              const SizedBox(height: 6),
              pages.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (rows) => _GscRowsList(rows: rows, empty: 'صفحه‌ای نیست'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GscKpi extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _GscKpi({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [color.withOpacity(0.12), color.withOpacity(0.04)],
        ),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Column(
        children: [
          Text(value, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: color)),
          const SizedBox(height: 2),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
        ],
      ),
    );
  }
}

class _GscRowsList extends StatelessWidget {
  final List<GscRow> rows;
  final String empty;
  const _GscRowsList({required this.rows, required this.empty});

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return Text(empty, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12));
    }
    return Column(
      children: [
        for (var i = 0; i < rows.length && i < 8; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFF071B7A).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('${i + 1}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF071B7A))),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    rows[i].key,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.right,
                  ),
                ),
                const SizedBox(width: 8),
                Text('${rows[i].clicks}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF071B7A))),
                const SizedBox(width: 6),
                Text('${rows[i].impressions}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
              ],
            ),
          ),
      ],
    );
  }
}

class _GscMiniChart extends StatelessWidget {
  final List<GscSeriesPoint> series;
  const _GscMiniChart({required this.series});

  @override
  Widget build(BuildContext context) {
    final maxC = series.map((e) => e.clicks).fold<int>(1, (a, b) => a > b ? a : b);
    return CustomPaint(
      painter: _GscChartPainter(series: series, maxClicks: maxC.toDouble()),
      child: const SizedBox.expand(),
    );
  }
}

class _GscChartPainter extends CustomPainter {
  final List<GscSeriesPoint> series;
  final double maxClicks;
  _GscChartPainter({required this.series, required this.maxClicks});

  @override
  void paint(Canvas canvas, Size size) {
    if (series.isEmpty) return;
    final paint = Paint()
      ..color = const Color(0xFF071B7A)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final fill = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF071B7A).withOpacity(0.25),
          const Color(0xFF071B7A).withOpacity(0.02),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    final path = Path();
    final fillPath = Path();
    final n = series.length;
    for (var i = 0; i < n; i++) {
      final x = n == 1 ? size.width / 2 : size.width * (i / (n - 1));
      final y = size.height - (series[i].clicks / maxClicks) * (size.height * 0.85) - 4;
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }
    fillPath.lineTo(size.width, size.height);
    fillPath.close();
    canvas.drawPath(fillPath, fill);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _GscChartPainter oldDelegate) => true;
}
