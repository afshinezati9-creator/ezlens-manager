import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../data/purchase_models.dart';
import '../data/purchase_repository.dart';
import 'purchase_provider.dart';

String _fa(String s) {
  const en = '0123456789';
  const fa = '۰۱۲۳۴۵۶۷۸۹';
  var o = s;
  for (var i = 0; i < 10; i++) {
    o = o.replaceAll(en[i], fa[i]);
  }
  return o;
}

class PurchaseListPage extends ConsumerStatefulWidget {
  const PurchaseListPage({super.key});

  @override
  ConsumerState<PurchaseListPage> createState() => _PurchaseListPageState();
}

class _PurchaseListPageState extends ConsumerState<PurchaseListPage> {
  final _searchCtrl = TextEditingController();
  String _filter = 'all'; // all|1|0

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _toggle(PurchaseScript s) async {
    try {
      final updated = await ref.read(purchaseRepositoryProvider).toggle(s.id);
      ref.invalidate(purchaseListProvider);
      ref.invalidate(purchaseStatsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(updated.active ? 'فعال شد' : 'غیرفعال شد'),
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

  Future<void> _delete(PurchaseScript s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف اسکریپت'),
        content: Text('«${s.title}» و فایل ${s.filename} حذف شود؟'),
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
      await ref.read(purchaseRepositoryProvider).delete(s.id);
      ref.invalidate(purchaseListProvider);
      ref.invalidate(purchaseStatsProvider);
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

  @override
  Widget build(BuildContext context) {
    final listAsync = ref.watch(purchaseListProvider);
    final statsAsync = ref.watch(purchaseStatsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('فرآیند خرید'),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/more'),
        ),
        actions: [
          IconButton(
            tooltip: 'اسکریپت جدید',
            icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
            onPressed: () => context.go('/purchase/new'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(purchaseListProvider);
              ref.invalidate(purchaseStatsProvider);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          statsAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (s) => Container(
              width: double.infinity,
              color: AppColors.surface,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Expanded(child: _stat('کل', _fa('${s['total'] ?? 0}'))),
                  const SizedBox(width: 8),
                  Expanded(child: _stat('فعال', _fa('${s['active'] ?? 0}'))),
                  const SizedBox(width: 8),
                  Expanded(
                      child: _stat('غیرفعال', _fa('${s['inactive'] ?? 0}'))),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _searchCtrl,
              onSubmitted: (_) async {
                final q = _searchCtrl.text.trim();
                final items = await ref
                    .read(purchaseRepositoryProvider)
                    .fetchList(search: q, status: _filter);
                // force local display via invalidate + temporary: just invalidate and use provider with search would need family
                ref.invalidate(purchaseListProvider);
                if (!mounted) return;
                // simple: store nothing; user can use filter chips below for status
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${items.length} نتیجه')),
                );
              },
              decoration: InputDecoration(
                hintText: 'جستجو عنوان یا نام فایل…',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: AppColors.surface,
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                _chip('همه', 'all'),
                const SizedBox(width: 6),
                _chip('فعال', '1'),
                const SizedBox(width: 6),
                _chip('غیرفعال', '0'),
              ],
            ),
          ),
          Expanded(
            child: listAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e')),
              data: (items) {
                var shown = items;
                if (_filter == '1') {
                  shown = items.where((e) => e.active).toList();
                } else if (_filter == '0') {
                  shown = items.where((e) => !e.active).toList();
                }
                final q = _searchCtrl.text.trim().toLowerCase();
                if (q.isNotEmpty) {
                  shown = shown
                      .where((e) =>
                          e.title.toLowerCase().contains(q) ||
                          e.filename.toLowerCase().contains(q) ||
                          e.description.toLowerCase().contains(q))
                      .toList();
                }
                if (shown.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('اسکریپتی نیست',
                            style: TextStyle(color: AppColors.textMuted)),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () => context.go('/purchase/new'),
                          child: const Text('افزودن اسکریپت'),
                        ),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(purchaseListProvider);
                    ref.invalidate(purchaseStatsProvider);
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: shown.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final s = shown[i];
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: s.active
                                ? AppColors.primary.withOpacity(0.35)
                                : AppColors.border,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    s.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                Switch(
                                  value: s.active,
                                  activeColor: AppColors.primary,
                                  onChanged: (_) => _toggle(s),
                                ),
                              ],
                            ),
                            Text(
                              s.filename,
                              style: const TextStyle(
                                fontSize: 12,
                                fontFamily: 'monospace',
                                color: AppColors.textSecondary,
                              ),
                            ),
                            if (s.description.isNotEmpty)
                              Text(
                                s.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            if (s.updatedFa.isNotEmpty)
                              Text(
                                'آخرین ویرایش: ${s.updatedFa}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () =>
                                      context.go('/purchase/${s.id}'),
                                  icon: const Icon(Icons.edit_outlined, size: 16),
                                  label: const Text('ویرایش'),
                                ),
                                const SizedBox(width: 8),
                                TextButton(
                                  onPressed: () => _delete(s),
                                  style: TextButton.styleFrom(
                                      foregroundColor: AppColors.danger),
                                  child: const Text('حذف'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, String value) {
    final on = _filter == value;
    return ChoiceChip(
      label: Text(label),
      selected: on,
      onSelected: (_) => setState(() => _filter = value),
      selectedColor: AppColors.primary.withOpacity(0.15),
      labelStyle: TextStyle(
        color: on ? AppColors.primary : AppColors.textSecondary,
        fontWeight: on ? FontWeight.w700 : FontWeight.w500,
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
          Text(value,
              style:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
