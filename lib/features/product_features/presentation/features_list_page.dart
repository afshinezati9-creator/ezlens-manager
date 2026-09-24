import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../data/feature_models.dart';
import '../data/feature_repository.dart';
import 'features_provider.dart';

String _toFa(String input) {
  const en = '0123456789';
  const fa = '۰۱۲۳۴۵۶۷۸۹';
  var out = input;
  for (var i = 0; i < en.length; i++) {
    out = out.replaceAll(en[i], fa[i]);
  }
  return out;
}

class FeaturesListPage extends ConsumerStatefulWidget {
  const FeaturesListPage({super.key});

  @override
  ConsumerState<FeaturesListPage> createState() => _FeaturesListPageState();
}

class _FeaturesListPageState extends ConsumerState<FeaturesListPage> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      final q = ref.read(featuresQueryProvider);
      ref.read(featuresQueryProvider.notifier).state =
          q.copyWith(search: v.trim(), page: 1);
    });
  }

  Future<void> _delete(ProductFeature item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف ویژگی'),
        content: Text('«${item.title}» حذف شود؟'),
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
      await ref.read(productFeatureRepositoryProvider).delete(item.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('ویژگی حذف شد'),
            backgroundColor: AppColors.success),
      );
      ref.invalidate(featuresListProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا: $e'), backgroundColor: AppColors.danger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncList = ref.watch(featuresListProvider);
    final query = ref.watch(featuresQueryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('ویژگی‌های محصول'),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/products'),
        ),
        actions: [
          IconButton(
            tooltip: 'افزودن ویژگی',
            icon: const Icon(Icons.add, color: AppColors.primary),
            onPressed: () => context.go('/product-features/new'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/product-features/new'),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('ویژگی جدید', style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  onChanged: _onSearch,
                  textDirection: TextDirection.rtl,
                  decoration: InputDecoration(
                    hintText: 'جستجوی ویژگی...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _FilterChip(
                      label: 'همه',
                      selected: query.status == 'all',
                      onTap: () =>
                          ref.read(featuresQueryProvider.notifier).state =
                              query.copyWith(status: 'all', page: 1),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'فعال',
                      selected: query.status == 'active',
                      onTap: () =>
                          ref.read(featuresQueryProvider.notifier).state =
                              query.copyWith(status: 'active', page: 1),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'غیرفعال',
                      selected: query.status == 'inactive',
                      onTap: () =>
                          ref.read(featuresQueryProvider.notifier).state =
                              query.copyWith(status: 'inactive', page: 1),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: asyncList.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline,
                          color: AppColors.danger, size: 40),
                      const SizedBox(height: 12),
                      Text('خطا در دریافت لیست:\n$e',
                          textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () => ref.invalidate(featuresListProvider),
                        child: const Text('تلاش مجدد'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (res) {
                if (res.items.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.layers_outlined,
                            size: 48, color: AppColors.textMuted),
                        const SizedBox(height: 12),
                        const Text('هنوز ویژگی‌ای ثبت نشده',
                            style:
                                TextStyle(color: AppColors.textSecondary)),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () =>
                              context.go('/product-features/new'),
                          icon: const Icon(Icons.add),
                          label: const Text('افزودن اولین ویژگی'),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white),
                        ),
                      ],
                    ),
                  );
                }
                final totalPages =
                    (res.total / res.perPage).ceil().clamp(1, 9999);
                return Column(
                  children: [
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () async =>
                            ref.invalidate(featuresListProvider),
                        child: ListView.separated(
                          padding:
                              const EdgeInsets.fromLTRB(16, 12, 16, 88),
                          itemCount: res.items.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, i) {
                            final item = res.items[i];
                            return _FeatureCard(
                              item: item,
                              onEdit: () =>
                                  context.go('/product-features/${item.id}/edit'),
                              onDelete: () => _delete(item),
                            );
                          },
                        ),
                      ),
                    ),
                    if (totalPages > 1)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              onPressed: query.page > 1
                                  ? () => ref
                                      .read(
                                          featuresQueryProvider.notifier)
                                      .state = query.copyWith(
                                          page: query.page - 1)
                                  : null,
                              icon: const Icon(Icons.chevron_right),
                            ),
                            Text(_toFa('${query.page} / $totalPages')),
                            IconButton(
                              onPressed: query.page < totalPages
                                  ? () => ref
                                      .read(
                                          featuresQueryProvider.notifier)
                                      .state = query.copyWith(
                                          page: query.page + 1)
                                  : null,
                              icon: const Icon(Icons.chevron_left),
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Filter Chip
// ============================================================
class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withOpacity(0.1)
              : AppColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? AppColors.primary : AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color:
                selected ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ============================================================
// Feature Card — با دکمه‌های ویرایش و حذف مستقیم
// ============================================================
class _FeatureCard extends StatelessWidget {
  final ProductFeature item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _FeatureCard({
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===== سطر بالا: آیکون + عنوان + ID + وضعیت =====
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.layers_outlined,
                        color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 15),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'شناسه ${_toFa('${item.id}')}',
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  // ===== برچسب وضعیت =====
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: item.status == 'active'
                          ? AppColors.successBg
                          : AppColors.borderLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item.status == 'active' ? 'فعال' : 'غیرفعال',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: item.status == 'active'
                            ? AppColors.success
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),

              // ===== توضیحات =====
              if (item.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  item.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary),
                ),
              ],

              const SizedBox(height: 10),

              // ===== سطر پایین: متادیتا + دکمه‌های ویرایش و حذف =====
              Row(
                children: [
                  _MetaPill(
                    icon: Icons.link,
                    text: '${_toFa('${item.connectedCount}')} محصول',
                  ),
                  const SizedBox(width: 8),
                  if (item.createdAt.isNotEmpty)
                    _MetaPill(
                      icon: Icons.schedule,
                      text: item.createdAt.length >= 16
                          ? item.createdAt.substring(0, 16)
                          : item.createdAt,
                    ),
                  const Spacer(),

                  // ===== دکمه ویرایش =====
                  _InlineActionBtn(
                    icon: Icons.edit_outlined,
                    label: 'ویرایش',
                    color: AppColors.primary,
                    onTap: onEdit,
                  ),
                  const SizedBox(width: 6),

                  // ===== دکمه حذف =====
                  _InlineActionBtn(
                    icon: Icons.delete_outline,
                    label: 'حذف',
                    color: AppColors.danger,
                    onTap: onDelete,
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

// ============================================================
// دکمه اکشن داخل کارت
// ============================================================
class _InlineActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _InlineActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// Meta Pill — نمایش اطلاعات کوچک
// ============================================================
class _MetaPill extends StatelessWidget {
  final IconData icon;
  final String text;
  const _MetaPill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textMuted),
          const SizedBox(width: 4),
          Text(text,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}