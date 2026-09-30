import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/stats_models.dart';
import 'visits_chart_page.dart';
import 'widgets/stat_metric_card.dart';
import 'widgets/stats_period_chips.dart';
import 'widgets/visits_hero_banner.dart';

/// Professional stats home — replace/wire your existing stats screen body with this.
class StatsOverviewPage extends ConsumerStatefulWidget {
  const StatsOverviewPage({
    super.key,
    this.overview,
    this.loading = false,
    this.error,
    this.period = 'week',
    this.onPeriodChanged,
    this.onRefresh,
  });

  final StatsOverview? overview;
  final bool loading;
  final String? error;
  final String period;
  final ValueChanged<String>? onPeriodChanged;
  final Future<void> Function()? onRefresh;

  @override
  ConsumerState<StatsOverviewPage> createState() => _StatsOverviewPageState();
}

class _StatsOverviewPageState extends ConsumerState<StatsOverviewPage> {
  String _period = 'week';

  @override
  void initState() {
    super.initState();
    _period = widget.period;
  }

  @override
  void didUpdateWidget(covariant StatsOverviewPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.period != widget.period) _period = widget.period;
  }

  void _openCharts() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const VisitsChartPage(),
      ),
    );
  }

  String _n(num v) {
    final s = v is double ? v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 0) : v.toString();
    final buf = StringBuffer();
    final parts = s.split('.');
    final intPart = parts[0];
    for (var i = 0; i < intPart.length; i++) {
      final rev = intPart.length - i;
      buf.write(intPart[i]);
      if (rev > 1 && rev % 3 == 1) buf.write(',');
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.overview ?? const StatsOverview();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const Text('آمار'),
          backgroundColor: const Color(0xFF071B7A),
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              tooltip: 'نمودار بازدید',
              onPressed: _openCharts,
              icon: const Icon(Icons.show_chart_rounded),
            ),
          ],
        ),
        body: RefreshIndicator(
          color: const Color(0xFF071B7A),
          onRefresh: () async {
            if (widget.onRefresh != null) await widget.onRefresh!();
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            children: [
              VisitsHeroBanner(
                onOpenCharts: _openCharts,
                visitorsLabel: _n(o.visitorsWeek > 0 ? o.visitorsWeek : o.visitorsTotal),
              ),
              const SizedBox(height: 16),
              StatsPeriodChips(
                value: _period,
                onChanged: (v) {
                  setState(() => _period = v);
                  widget.onPeriodChanged?.call(v);
                },
              ),
              const SizedBox(height: 12),
              if (widget.loading) const LinearProgressIndicator(minHeight: 2),
              if (widget.error != null && widget.error!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    widget.error!,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                'بازدید',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                    ),
              ),
              const SizedBox(height: 10),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.35,
                children: [
                  StatMetricCard(
                    title: 'امروز',
                    value: _n(o.visitorsToday),
                    icon: Icons.today_outlined,
                    accent: const Color(0xFF071B7A),
                    onTap: _openCharts,
                  ),
                  StatMetricCard(
                    title: 'این هفته',
                    value: _n(o.visitorsWeek),
                    icon: Icons.date_range_outlined,
                    accent: const Color(0xFF1D4ED8),
                    onTap: _openCharts,
                  ),
                  StatMetricCard(
                    title: 'این ماه',
                    value: _n(o.visitorsMonth),
                    icon: Icons.calendar_month_outlined,
                    accent: const Color(0xFF0369A1),
                  ),
                  StatMetricCard(
                    title: 'کل بازدید',
                    value: _n(o.visitorsTotal),
                    icon: Icons.public_outlined,
                    accent: const Color(0xFF0F766E),
                    onTap: _openCharts,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'فروش و سفارش',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                    ),
              ),
              const SizedBox(height: 10),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.35,
                children: [
                  StatMetricCard(
                    title: 'سفارش امروز',
                    value: _n(o.ordersToday),
                    icon: Icons.shopping_bag_outlined,
                    accent: const Color(0xFFB45309),
                  ),
                  StatMetricCard(
                    title: 'سفارش هفته',
                    value: _n(o.ordersWeek),
                    icon: Icons.receipt_long_outlined,
                    accent: const Color(0xFFC2410C),
                  ),
                  StatMetricCard(
                    title: 'فروش امروز',
                    value: _n(o.salesToday),
                    subtitle: 'تومان',
                    icon: Icons.payments_outlined,
                    accent: const Color(0xFF15803D),
                  ),
                  StatMetricCard(
                    title: 'فروش هفته',
                    value: _n(o.salesWeek),
                    subtitle: 'تومان',
                    icon: Icons.trending_up_rounded,
                    accent: const Color(0xFF166534),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'محتوا و مشتری',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                    ),
              ),
              const SizedBox(height: 10),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.45,
                children: [
                  StatMetricCard(
                    title: 'محصولات',
                    value: _n(o.productsCount),
                    icon: Icons.inventory_2_outlined,
                    accent: const Color(0xFF4C1D95),
                  ),
                  StatMetricCard(
                    title: 'مقالات',
                    value: _n(o.articlesCount),
                    icon: Icons.article_outlined,
                    accent: const Color(0xFF6D28D9),
                  ),
                  StatMetricCard(
                    title: 'مشتریان',
                    value: _n(o.customersCount),
                    icon: Icons.people_outline_rounded,
                    accent: const Color(0xFF9D174D),
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
