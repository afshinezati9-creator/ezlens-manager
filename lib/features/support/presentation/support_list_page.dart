import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../data/support_models.dart';
import 'support_provider.dart';

String _fa(String s) {
  const en = '0123456789';
  const fa = '۰۱۲۳۴۵۶۷۸۹';
  var o = s;
  for (var i = 0; i < 10; i++) {
    o = o.replaceAll(en[i], fa[i]);
  }
  return o;
}

class SupportListPage extends ConsumerStatefulWidget {
  const SupportListPage({super.key});

  @override
  ConsumerState<SupportListPage> createState() => _SupportListPageState();
}

class _SupportListPageState extends ConsumerState<SupportListPage> {
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
    _debounce = Timer(const Duration(milliseconds: 400), () {
      final q = ref.read(supportQueryProvider);
      ref.read(supportQueryProvider.notifier).state =
          q.copyWith(search: v.trim(), page: 1);
    });
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'open':
        return AppColors.warning;
      case 'replied':
        return AppColors.info;
      case 'closed':
        return AppColors.textMuted;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncList = ref.watch(supportListProvider);
    final query = ref.watch(supportQueryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('پشتیبانی'),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/more'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            onPressed: () => ref.invalidate(supportListProvider),
          ),
        ],
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
                  decoration: InputDecoration(
                    hintText: 'جستجو نام، موبایل، ایمیل...',
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
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final e in [
                        ('all', 'همه'),
                        ('open', 'باز'),
                        ('replied', 'پاسخ‌داده‌شده'),
                        ('closed', 'بسته'),
                      ])
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: FilterChip(
                            label: Text(e.$2),
                            selected: query.status == e.$1,
                            onSelected: (_) {
                              ref.read(supportQueryProvider.notifier).state =
                                  query.copyWith(status: e.$1, page: 1);
                            },
                            selectedColor:
                                AppColors.primary.withOpacity(0.12),
                            checkmarkColor: AppColors.primary,
                            labelStyle: TextStyle(
                              color: query.status == e.$1
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: asyncList.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('$e', textAlign: TextAlign.center),
                      TextButton(
                        onPressed: () =>
                            ref.invalidate(supportListProvider),
                        child: const Text('تلاش مجدد'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (res) {
                if (res.items.isEmpty) {
                  return const Center(
                    child: Text('تیکتی یافت نشد',
                        style: TextStyle(color: AppColors.textMuted)),
                  );
                }
                return Column(
                  children: [
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () async =>
                            ref.invalidate(supportListProvider),
                        child: ListView.separated(
                          padding:
                              const EdgeInsets.fromLTRB(16, 12, 16, 24),
                          itemCount: res.items.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, i) {
                            final t = res.items[i];
                            return Material(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              child: InkWell(
                                onTap: () =>
                                    context.go('/support/${t.id}'),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: AppColors.border),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              t.subject.isEmpty
                                                  ? 'تیکت #${t.id}'
                                                  : t.subject,
                                              maxLines: 1,
                                              overflow:
                                                  TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 3),
                                            decoration: BoxDecoration(
                                              color: _statusColor(t.status)
                                                  .withOpacity(0.12),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              t.statusLabel,
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color:
                                                    _statusColor(t.status),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        t.displayName.isNotEmpty
                                            ? t.displayName
                                            : (t.userLogin.isNotEmpty
                                                ? t.userLogin
                                                : 'کاربر #${t.userId}'),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      if (t.phone.isNotEmpty)
                                        Text(
                                          _fa(t.phone),
                                          textDirection: TextDirection.ltr,
                                          textAlign: TextAlign.right,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.textMuted,
                                          ),
                                        ),
                                      const SizedBox(height: 6),
                                      Text(
                                        t.updatedFa.isNotEmpty
                                            ? t.updatedFa
                                            : t.createdFa,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    if (res.pages > 1)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              onPressed: query.page > 1
                                  ? () => ref
                                      .read(supportQueryProvider.notifier)
                                      .state = query.copyWith(
                                      page: query.page - 1)
                                  : null,
                              icon: const Icon(Icons.chevron_right),
                            ),
                            Text(
                              _fa(
                                  '${query.page} / ${res.pages}  (${res.total})'),
                              style: const TextStyle(
                                  color: AppColors.textSecondary),
                            ),
                            IconButton(
                              onPressed: query.page < res.pages
                                  ? () => ref
                                      .read(supportQueryProvider.notifier)
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
