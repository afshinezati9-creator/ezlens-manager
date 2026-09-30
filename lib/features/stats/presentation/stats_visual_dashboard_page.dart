import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../data/stats_models.dart';
import 'stats_provider.dart';

String _fa(String s) {
  const en = '0123456789';
  const fa = '۰۱۲۳۴۵۶۷۸۹';
  var out = s;
  for (var i = 0; i < 10; i++) {
    out = out.replaceAll(en[i], fa[i]);
  }
  return out;
}

String _num(num value) => _fa(
      value.round().toString().replaceAllMapped(
            RegExp(r'(\\d)(?=(\\d{3})+(?!\\d))'),
            (m) => '${m[1]},',
          ),
    );

/// Visual analytics dashboard for the existing Stats module.
/// Uses live providers only; no sample/demo values are rendered here.
class StatsVisualDashboardPage extends ConsumerWidget {
  const StatsVisualDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(statsSnapshotProvider);
    final products = ref.watch(topByViewsProvider);
    final posts = ref.watch(latestPostsWithViewsProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('آمار بصری'),
          centerTitle: true,
          backgroundColor: AppColors.surface,
          elevation: 0,
          actions: [
            IconButton(
              tooltip: 'بروزرسانی',
              onPressed: () {
                ref.invalidate(statsSnapshotProvider);
                ref.invalidate(topByViewsProvider);
                ref.invalidate(latestPostsWithViewsProvider);
              },
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        body: snapshot.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _ErrorState(
            error: error,
            onRetry: () => ref.invalidate(statsSnapshotProvider),
          ),
          data: (s) => RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(statsSnapshotProvider);
              ref.invalidate(topByViewsProvider);
              ref.invalidate(latestPostsWithViewsProvider);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
              children: [
                _HeaderCard(snapshot: s),
                const SizedBox(height: 14),
                _KpiGrid(snapshot: s),
                const SizedBox(height: 16),
                _StatusChart(statuses: s.byStatus),
                const SizedBox(height: 16),
                _ContentComparison(
                  products: products,
                  posts: posts,
                  totalProductViews: s.totalProductViews,
                ),
                const SizedBox(height: 16),
                _TopContentSection(
                  title: 'پربازدیدترین محصولات',
                  icon: Icons.inventory_2_outlined,
                  color: const Color(0xFF2563EB),
                  provider: products,
                  suffix: 'بازدید',
                ),
                const SizedBox(height: 14),
                _TopContentSection(
                  title: 'آخرین مقالات و بازدید آن‌ها',
                  icon: Icons.article_outlined,
                  color: const Color(0xFF7C3AED),
                  provider: posts,
                  suffix: 'بازدید',
                  showNote: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.snapshot});
  final StatsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFF071B7A), Color(0xFF1D4ED8)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .14),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.insights_rounded,
              color: Colors.white,
              size: 27,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'تصویر کلی آمار سایت',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  snapshot.rangeFa.isNotEmpty
                      ? 'بازه: ${snapshot.rangeFa}'
                      : 'بازه: ${snapshot.periodLabel}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
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

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.snapshot});
  final StatsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final items = [
      ('سفارش‌ها', _num(snapshot.ordersCount), Icons.shopping_bag_outlined),
      ('فروش', '${_num(snapshot.revenue)} تومان', Icons.payments_outlined),
      ('مشتری جدید', _num(snapshot.newCustomers), Icons.person_add_alt_1_outlined),
      ('بازدید محصولات', _num(snapshot.totalProductViews), Icons.visibility_outlined),
      ('محصولات منتشرشده', _num(snapshot.productsPublished), Icons.inventory_2_outlined),
      ('مقالات', _num(snapshot.postsTotal), Icons.article_outlined),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.75,
      ),
      itemBuilder: (_, i) {
        final item = items[i];
        return Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(item.$3, size: 20, color: AppColors.primary),
              const Spacer(),
              Text(
                item.$1,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                item.$2,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatusChart extends StatelessWidget {
  const _StatusChart({required this.statuses});
  final List<StatusCount> statuses;

  @override
  Widget build(BuildContext context) {
    if (statuses.isEmpty) {
      return const SizedBox.shrink();
    }

    final visible = statuses.where((e) => e.count > 0).take(6).toList();
    if (visible.isEmpty) return const SizedBox.shrink();

    return _Card(
      title: 'توزیع وضعیت سفارش‌ها',
      icon: Icons.donut_large_rounded,
      child: SizedBox(
        height: 220,
        child: Row(
          children: [
            Expanded(
              flex: 5,
              child: PieChart(
                PieChartData(
                  centerSpaceRadius: 48,
                  sectionsSpace: 3,
                  sections: [
                    for (var i = 0; i < visible.length; i++)
                      PieChartSectionData(
                        value: visible[i].count.toDouble(),
                        title: _fa('${visible[i].count}'),
                        radius: 62,
                        titleStyle: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 4,
              child: ListView.separated(
                itemCount: visible.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) => Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _chartColor(i),
                      ),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        visible[i].label.isEmpty
                            ? visible[i].status
                            : visible[i].label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                    Text(
                      _fa('${visible[i].count}'),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContentComparison extends StatelessWidget {
  const _ContentComparison({
    required this.products,
    required this.posts,
    required this.totalProductViews,
  });

  final AsyncValue<List<TopProduct>> products;
  final AsyncValue<List<TopContentItem>> posts;
  final int totalProductViews;

  @override
  Widget build(BuildContext context) {
    final productItems = products.valueOrNull ?? const <TopProduct>[];
    final postItems = posts.valueOrNull ?? const <TopContentItem>[];

    final productVisible = productItems.take(5).toList();
    final postVisible = postItems.take(5).toList();

    final productTotal = productVisible.fold<int>(
      0,
      (sum, item) => sum + item.score,
    );
    final postTotal = postVisible.fold<int>(
      0,
      (sum, item) => sum + item.views,
    );

    return _Card(
      title: 'مقایسه بازدید محتوا',
      icon: Icons.bar_chart_rounded,
      trailing: Text(
        'محصول: ${_num(totalProductViews)}',
        style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
      ),
      child: Column(
        children: [
          _ComparisonRow(
            label: 'محصولات',
            value: productTotal,
            maxValue: productTotal > postTotal ? productTotal : postTotal,
            icon: Icons.inventory_2_outlined,
          ),
          const SizedBox(height: 13),
          _ComparisonRow(
            label: 'مقالات',
            value: postTotal,
            maxValue: productTotal > postTotal ? productTotal : postTotal,
            icon: Icons.article_outlined,
          ),
          if (products.isLoading || posts.isLoading) ...[
            const SizedBox(height: 14),
            const LinearProgressIndicator(minHeight: 2),
          ],
          if (posts.hasError) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'بازدید مقالات موقتاً در دسترس نیست (اتصال یا سرور).',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ),
          ],
          if (products.hasError || posts.hasError) ...[
            const SizedBox(height: 9),
            const Align(
              alignment: Alignment.centerRight,
              child: Text(
                'برخی داده‌های محتوا از سرور دریافت نشد.',
                style: TextStyle(fontSize: 10, color: AppColors.textMuted),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ComparisonRow extends StatelessWidget {
  const _ComparisonRow({
    required this.label,
    required this.value,
    required this.maxValue,
    required this.icon,
  });

  final String label;
  final int value;
  final int maxValue;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final ratio = maxValue <= 0 ? 0.0 : (value / maxValue).clamp(0.0, 1.0);
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(child: Text(label)),
            Text(
              _num(value),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            minHeight: 9,
            value: ratio,
            backgroundColor: AppColors.border.withValues(alpha: .55),
          ),
        ),
      ],
    );
  }
}

class _TopContentSection extends StatelessWidget {
  const _TopContentSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.provider,
    required this.suffix,
    this.showNote = false,
  });

  final String title;
  final IconData icon;
  final Color color;
  final AsyncValue<List<dynamic>> provider;
  final String suffix;
  final bool showNote;

  @override
  Widget build(BuildContext context) {
    return _Card(
      title: title,
      icon: icon,
      child: provider.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: LinearProgressIndicator(minHeight: 2),
        ),
        error: (_, __) => const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'اطلاعات این بخش در دسترس نیست.',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'داده‌ای برای نمایش وجود ندارد.',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            );
          }

          return Column(
            children: [
              for (var i = 0; i < items.length && i < 6; i++)
                _ContentRow(
                  index: i,
                  item: items[i],
                  color: color,
                  suffix: suffix,
                ),
              if (showNote)
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'بازدید مقاله بر اساس داده‌ای است که API فعلی برای هر مقاله برمی‌گرداند.',
                      style: TextStyle(
                        fontSize: 9.5,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ContentRow extends StatelessWidget {
  const _ContentRow({
    required this.index,
    required this.item,
    required this.color,
    required this.suffix,
  });

  final int index;
  final dynamic item;
  final Color color;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    final String title;
    final int views;

    if (item is TopProduct) {
      title = item.title;
      views = item.score;
    } else {
      final content = item as TopContentItem;
      title = content.title;
      views = content.views;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        children: [
          Container(
            width: 27,
            height: 27,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .10),
              shape: BoxShape.circle,
            ),
            child: Text(
              _fa('${index + 1}'),
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              title.isEmpty ? 'بدون عنوان' : title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${_num(views)} $suffix',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.title,
    required this.icon,
    required this.child,
    this.trailing,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 13),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .025),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 19, color: AppColors.primary),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 13),
          child,
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error, required this.onRetry});
  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.analytics_outlined, size: 42, color: AppColors.textMuted),
            const SizedBox(height: 12),
            const Text(
              'اطلاعات آمار در دسترس نیست.',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              '$error',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('تلاش دوباره'),
            ),
          ],
        ),
      ),
    );
  }
}

Color _chartColor(int index) {
  const colors = [
    Color(0xFF2563EB),
    Color(0xFF7C3AED),
    Color(0xFF059669),
    Color(0xFFF59E0B),
    Color(0xFFDC2626),
    Color(0xFF0891B2),
  ];
  return colors[index % colors.length];
}
