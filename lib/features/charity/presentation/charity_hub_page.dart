import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../data/charity_models.dart';
import '../data/charity_repository.dart';
import 'charity_provider.dart';

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

class CharityHubPage extends ConsumerStatefulWidget {
  const CharityHubPage({super.key});

  @override
  ConsumerState<CharityHubPage> createState() => _CharityHubPageState();
}

class _CharityHubPageState extends ConsumerState<CharityHubPage>
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

  Future<void> _deleteCase(CharityCase c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف مورد'),
        content: Text('«${c.title}» حذف شود؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('انصراف')),
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
      await ref.read(charityRepositoryProvider).deleteCase(c.id);
      ref.invalidate(charityCasesProvider);
      ref.invalidate(charityStatsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('حذف شد'), backgroundColor: AppColors.success),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا: $e'), backgroundColor: AppColors.danger),
      );
    }
  }

  Future<void> _impact(CharityDonation d) async {
    final beneficiary = TextEditingController();
    final purpose = TextEditingController();
    final thank = TextEditingController();
    final spent = TextEditingController(text: '${d.amount}');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('گزارش اثر'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: spent,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'مبلغ هزینه‌شده', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: beneficiary,
                decoration: const InputDecoration(
                    labelText: 'دریافت‌کننده (مثلاً بیمار)',
                    border: OutlineInputBorder()),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: purpose,
                maxLines: 2,
                decoration: const InputDecoration(
                    labelText: 'صرف شده برای', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: thank,
                maxLines: 3,
                decoration: const InputDecoration(
                    labelText: 'پیام سپاس به اهداکننده',
                    border: OutlineInputBorder()),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('انصراف')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('ثبت'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final spentN = int.tryParse(spent.text.replaceAll(RegExp(r'\D'), '')) ?? 0;
      await ref.read(charityRepositoryProvider).addImpact(
            donationId: d.id,
            spentAmount: spentN,
            beneficiary: beneficiary.text.trim(),
            purpose: purpose.text.trim(),
            thankYou: thank.text.trim(),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('گزارش اثر ثبت شد'),
          backgroundColor: AppColors.success,
        ),
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
    final statsAsync = ref.watch(charityStatsProvider);
    final casesAsync = ref.watch(charityCasesProvider);
    final donationsAsync = ref.watch(charityDonationsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('هم‌یاری بینایی'),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/more'),
        ),
        actions: [
          IconButton(
            tooltip: 'مورد جدید',
            icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
            onPressed: () => context.go('/charity/case/new'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(charityStatsProvider);
              ref.invalidate(charityCasesProvider);
              ref.invalidate(charityDonationsProvider);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'موارد'),
            Tab(text: 'کمک‌ها'),
          ],
        ),
      ),
      body: Column(
        children: [
          statsAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (s) => Container(
              width: double.infinity,
              color: AppColors.surface,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  Expanded(child: _stat('موارد', _fa('${s.cases}'))),
                  const SizedBox(width: 8),
                  Expanded(child: _stat('باز', _fa('${s.openCases}'))),
                  const SizedBox(width: 8),
                  Expanded(child: _stat('کمک‌ها', _fa('${s.donations}'))),
                  const SizedBox(width: 8),
                  Expanded(child: _stat('جمع', _money(s.totalRaised))),
                ],
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                // Cases
                casesAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('$e')),
                  data: (items) {
                    if (items.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('موردی ثبت نشده',
                                style: TextStyle(color: AppColors.textMuted)),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: () =>
                                  context.go('/charity/case/new'),
                              child: const Text('ایجاد مورد'),
                            ),
                          ],
                        ),
                      );
                    }
                    return RefreshIndicator(
                      onRefresh: () async =>
                          ref.invalidate(charityCasesProvider),
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: items.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 10),
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
                                      child: Text(
                                        c.title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      c.statusLabel,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline,
                                          color: AppColors.danger, size: 20),
                                      onPressed: () => _deleteCase(c),
                                    ),
                                  ],
                                ),
                                Text(
                                  c.needLabel.isEmpty
                                      ? c.needType
                                      : c.needLabel,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                LinearProgressIndicator(
                                  value: (c.percent.clamp(0, 100)) / 100,
                                  backgroundColor: AppColors.border,
                                  color: AppColors.primary,
                                  minHeight: 6,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${_money(c.raisedAmount)} از ${_money(c.goalAmount)} · ${_fa('${c.percent}')}٪',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                if (c.createdFa.isNotEmpty)
                                  Text(
                                    c.createdFa,
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
                // Donations
                donationsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('$e')),
                  data: (items) {
                    if (items.isEmpty) {
                      return const Center(
                        child: Text('کمکی ثبت نشده',
                            style: TextStyle(color: AppColors.textMuted)),
                      );
                    }
                    return RefreshIndicator(
                      onRefresh: () async =>
                          ref.invalidate(charityDonationsProvider),
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: items.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final d = items[i];
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
                                      child: Text(
                                        d.donorName.isEmpty
                                            ? 'کاربر #${d.userId}'
                                            : d.donorName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      _money(d.amount),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                                if (d.caseTitle.isNotEmpty)
                                  Text(
                                    d.caseTitle,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                Text(
                                  d.createdFa.isNotEmpty
                                      ? d.createdFa
                                      : d.createdAt,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: OutlinedButton.icon(
                                    onPressed: () => _impact(d),
                                    icon: const Icon(Icons.volunteer_activism,
                                        size: 16),
                                    label: const Text('گزارش اثر'),
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
