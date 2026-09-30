import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../data/discount_models.dart';
import '../data/discount_repository.dart';
import 'discount_provider.dart';

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

class DiscountsHubPage extends ConsumerStatefulWidget {
  const DiscountsHubPage({super.key});

  @override
  ConsumerState<DiscountsHubPage> createState() => _DiscountsHubPageState();
}

class _DiscountsHubPageState extends ConsumerState<DiscountsHubPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _deleteCoupon(DiscountCoupon c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف کد تخفیف'),
        content: Text('کد «${c.code}» حذف شود؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(discountRepositoryProvider).deleteCoupon(c.id);
      ref.invalidate(couponsProvider);
      ref.invalidate(discountStatsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('حذف شد'), backgroundColor: AppColors.success),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا: $e'), backgroundColor: AppColors.danger),
      );
    }
  }

  Future<void> _cancelGift(GiftCardItem g) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('لغو کارت هدیه'),
        content: Text('کد «${g.code}» لغو شود؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('لغو'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(discountRepositoryProvider).cancelGift(g.id);
      ref.invalidate(giftsProvider);
      ref.invalidate(discountStatsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لغو شد'), backgroundColor: AppColors.success),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا: $e'), backgroundColor: AppColors.danger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(discountStatsProvider);
    final couponsAsync = ref.watch(couponsProvider);
    final giftsAsync = ref.watch(giftsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('تخفیف و هدیه'),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/more'),
        ),
        actions: [
          IconButton(
            tooltip: 'کد تخفیف جدید',
            icon: const Icon(Icons.local_offer_outlined, color: AppColors.primary),
            onPressed: () => context.go('/discounts/coupon/new'),
          ),
          IconButton(
            tooltip: 'کارت هدیه جدید',
            icon: const Icon(Icons.card_giftcard_outlined, color: AppColors.primary),
            onPressed: () => context.go('/discounts/gift/new'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(couponsProvider);
              ref.invalidate(giftsProvider);
              ref.invalidate(discountStatsProvider);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'کدهای تخفیف'),
            Tab(text: 'کارت هدیه'),
          ],
        ),
      ),
      body: Column(
        children: [
          statsAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (s) {
              final coupons = int.tryParse('${s['coupons']}') ?? 0;
              final active = int.tryParse('${s['gifts_active']}') ?? 0;
              final redeemed = int.tryParse('${s['gifts_redeemed']}') ?? 0;
              return Container(
                width: double.infinity,
                color: AppColors.surface,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Row(
                  children: [
                    Expanded(child: _stat('کوپن‌ها', _fa('$coupons'))),
                    const SizedBox(width: 8),
                    Expanded(child: _stat('هدیه فعال', _fa('$active'))),
                    const SizedBox(width: 8),
                    Expanded(child: _stat('استفاده‌شده', _fa('$redeemed'))),
                  ],
                ),
              );
            },
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                // Coupons
                couponsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('$e')),
                  data: (items) {
                    if (items.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('کد تخفیفی نیست',
                                style: TextStyle(color: AppColors.textMuted)),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: () => context.go('/discounts/coupon/new'),
                              child: const Text('ایجاد کد تخفیف'),
                            ),
                          ],
                        ),
                      );
                    }
                    return RefreshIndicator(
                      onRefresh: () async => ref.invalidate(couponsProvider),
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final c = items[i];
                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () {
                                          Clipboard.setData(
                                              ClipboardData(text: c.code));
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(const SnackBar(
                                                  content: Text('کد کپی شد')));
                                        },
                                        child: Text(
                                          c.code,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 15,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Text(
                                      c.amountLabel,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline,
                                          color: AppColors.danger, size: 20),
                                      onPressed: () => _deleteCoupon(c),
                                    ),
                                  ],
                                ),
                                Text(
                                  '${c.typeLabel.isEmpty ? c.discountType : c.typeLabel}'
                                  ' · استفاده: ${_fa('${c.usageCount}')}'
                                  '${c.usageLimit > 0 ? ' / ${_fa('${c.usageLimit}')}' : ''}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                if (c.dateExpiresFa.isNotEmpty)
                                  Text(
                                    'انقضا: ${c.dateExpiresFa}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
                // Gifts
                giftsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('$e')),
                  data: (items) {
                    if (items.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('کارت هدیه‌ای نیست',
                                style: TextStyle(color: AppColors.textMuted)),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: () => context.go('/discounts/gift/new'),
                              child: const Text('صدور کارت هدیه'),
                            ),
                          ],
                        ),
                      );
                    }
                    return RefreshIndicator(
                      onRefresh: () async => ref.invalidate(giftsProvider),
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final g = items[i];
                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () {
                                          Clipboard.setData(
                                              ClipboardData(text: g.code));
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(const SnackBar(
                                                  content: Text('کد کپی شد')));
                                        },
                                        child: Text(
                                          g.code,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 15,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Text(
                                      g.statusLabel,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: g.status == 'active'
                                            ? AppColors.success
                                            : AppColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  _money(g.amount),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                                if (g.recipientName.isNotEmpty)
                                  Text('گیرنده: ${g.recipientName}',
                                      style: const TextStyle(fontSize: 12)),
                                if (g.redeemerName.isNotEmpty)
                                  Text('استفاده‌کننده: ${g.redeemerName}',
                                      style: const TextStyle(fontSize: 12)),
                                Text(
                                  g.createdFa,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                                if (g.status == 'active') ...[
                                  const SizedBox(height: 8),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: OutlinedButton(
                                      onPressed: () => _cancelGift(g),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.danger,
                                      ),
                                      child: const Text('لغو کارت'),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 10, color: AppColors.textSecondary)),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
