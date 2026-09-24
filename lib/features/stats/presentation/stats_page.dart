import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../data/stats_models.dart';
import 'stats_provider.dart';

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
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(statsSnapshotProvider);
              ref.invalidate(topByViewsProvider);
              ref.invalidate(topBySalesProvider);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: AppColors.surface,
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _periods.map((p) {
                final on = period == p.$1;
                return ChoiceChip(
                  label: Text(p.$2),
                  selected: on,
                  onSelected: (_) {
                    ref.read(statsPeriodProvider.notifier).state = p.$1;
                  },
                  selectedColor: AppColors.primary.withOpacity(0.15),
                  labelStyle: TextStyle(
                    fontWeight: on ? FontWeight.w700 : FontWeight.w500,
                    color: on ? AppColors.primary : AppColors.textSecondary,
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: snapAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
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
                },
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (s.rangeFa.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          'بازه: ${s.rangeFa}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),

                    const Text('فروش و سفارش',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 13)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                            child: _kpi('سفارش‌ها', _fa('${s.ordersCount}'))),
                        const SizedBox(width: 8),
                        Expanded(child: _kpi('فروش', _money(s.revenue))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                            child: _kpi('میانگین سبد', _money(s.avgOrder))),
                        const SizedBox(width: 8),
                        Expanded(
                            child: _kpi(
                                'مشتری جدید', _fa('${s.newCustomers}'))),
                      ],
                    ),

                    if (s.byStatus.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      const Text('وضعیت سفارش‌ها',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 13)),
                      const SizedBox(height: 8),
                      ...s.byStatus.map(
                        (st) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              Expanded(child: Text(st.label)),
                              Text(
                                _fa('${st.count}'),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),
                    const Text('مخاطبان و محتوا',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 13)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                            child: _kpi(
                                'کل کاربران', _fa('${s.totalUsers}'))),
                        const SizedBox(width: 8),
                        Expanded(
                            child: _kpi(
                                'مشتریان', _fa('${s.totalCustomers}'))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                            child:
                                _kpi('محصولات', _fa('${s.productsPublished}'))),
                        const SizedBox(width: 8),
                        Expanded(
                            child: _kpi('مقالات', _fa('${s.postsTotal}'))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                            child: _kpi(
                                'مقاله در بازه', _fa('${s.postsNew}'))),
                        const SizedBox(width: 8),
                        Expanded(
                            child: _kpi('نظرات', _fa('${s.comments}'))),
                      ],
                    ),

                    const SizedBox(height: 16),
                    const Text('بازدید محصولات (تجمعی)',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 13)),
                    const SizedBox(height: 8),
                    _kpi('جمع بازدید محصول',
                        _fa('${s.totalProductViews}'),
                        wide: true),
                    if (s.noteProductViews.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          s.noteProductViews,
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textMuted),
                        ),
                      ),

                    const SizedBox(height: 16),
                    const Text('پربازدیدترین محصولات',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 13)),
                    const SizedBox(height: 8),
                    topViews.when(
                      loading: () => const LinearProgressIndicator(),
                      error: (_, __) => const Text('—'),
                      data: (items) => _topList(items, suffix: 'بازدید'),
                    ),

                    const SizedBox(height: 16),
                    const Text('پرفروش‌ترین محصولات',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 13)),
                    const SizedBox(height: 8),
                    topSales.when(
                      loading: () => const LinearProgressIndicator(),
                      error: (_, __) => const Text('—'),
                      data: (items) => _topList(items, suffix: 'فروش'),
                    ),

                    if (s.noteGa4.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppColors.primary.withOpacity(0.15)),
                        ),
                        child: Text(
                          'بازدید کل سایت (GA4):\n${s.noteGa4}\n\nProperty: 551454196 · Measurement: G-LQ7FCDSGY0',
                          style: const TextStyle(fontSize: 11, height: 1.45),
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

  static Widget _kpi(String label, String value, {bool wide = false}) {
    return Container(
      width: wide ? double.infinity : null,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  static Widget _topList(List<TopProduct> items, {required String suffix}) {
    if (items.isEmpty) {
      return const Text('داده‌ای نیست',
          style: TextStyle(color: AppColors.textMuted, fontSize: 12));
    }
    return Column(
      children: [
        for (var i = 0; i < items.length; i++)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Text(
                  _fa('${i + 1}'),
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, color: AppColors.primary),
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
                Text(
                  '${_fa('${items[i].score}')} $suffix',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
