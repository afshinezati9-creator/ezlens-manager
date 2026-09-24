import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../data/inbox_models.dart';
import '../data/inbox_repository.dart';
import 'inbox_provider.dart';

String _fa(String s) {
  const en = '0123456789';
  const fa = '۰۱۲۳۴۵۶۷۸۹';
  var o = s;
  for (var i = 0; i < 10; i++) {
    o = o.replaceAll(en[i], fa[i]);
  }
  return o;
}

class InboxListPage extends ConsumerStatefulWidget {
  const InboxListPage({super.key});

  @override
  ConsumerState<InboxListPage> createState() => _InboxListPageState();
}

class _InboxListPageState extends ConsumerState<InboxListPage> {
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
    _debounce = Timer(const Duration(milliseconds: 450), () {
      final q = ref.read(inboxQueryProvider);
      ref.read(inboxQueryProvider.notifier).state =
          q.copyWith(search: v.trim(), page: 1);
    });
  }

  Future<void> _delete(InboxMessageSummary m) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف پیام'),
        content: Text('«${m.subject}» حذف شود؟'),
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
      await ref.read(inboxRepositoryProvider).deleteMessage(m.uid);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('پیام حذف شد'),
          backgroundColor: AppColors.success,
        ),
      );
      ref.invalidate(inboxListProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطا: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncList = ref.watch(inboxListProvider);
    final query = ref.watch(inboxQueryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('صندوق ایمیل'),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/more'),
        ),
        actions: [
          IconButton(
            tooltip: 'بروزرسانی',
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            onPressed: () => ref.invalidate(inboxListProvider),
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
                    hintText: 'جستجو در موضوع و متن...',
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
                      _Chip(
                        label: 'همه',
                        selected: query.filter == 'all',
                        onTap: () => ref
                            .read(inboxQueryProvider.notifier)
                            .state = query.copyWith(filter: 'all', page: 1),
                      ),
                      _Chip(
                        label: 'خوانده‌نشده',
                        selected: query.filter == 'unseen',
                        onTap: () => ref
                            .read(inboxQueryProvider.notifier)
                            .state =
                            query.copyWith(filter: 'unseen', page: 1),
                      ),
                      _Chip(
                        label: 'خوانده‌شده',
                        selected: query.filter == 'seen',
                        onTap: () => ref
                            .read(inboxQueryProvider.notifier)
                            .state = query.copyWith(filter: 'seen', page: 1),
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
                      Text(
                        'خطا در دریافت ایمیل‌ها\n$e',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () =>
                            ref.invalidate(inboxListProvider),
                        child: const Text('تلاش مجدد'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (res) {
                if (res.items.isEmpty) {
                  return const Center(
                    child: Text(
                      'پیامی یافت نشد',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  );
                }
                return Column(
                  children: [
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () async =>
                            ref.invalidate(inboxListProvider),
                        child: ListView.separated(
                          padding:
                              const EdgeInsets.fromLTRB(16, 12, 16, 24),
                          itemCount: res.items.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, i) {
                            final m = res.items[i];
                            return _MailTile(
                              message: m,
                              onOpen: () =>
                                  context.go('/inbox/${m.uid}'),
                              onDelete: () => _delete(m),
                            );
                          },
                        ),
                      ),
                    ),
                    if (res.totalPages > 1)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              onPressed: query.page > 1
                                  ? () => ref
                                      .read(inboxQueryProvider.notifier)
                                      .state = query.copyWith(
                                      page: query.page - 1)
                                  : null,
                              icon: const Icon(Icons.chevron_right),
                            ),
                            Text(
                              _fa(
                                  '${query.page} / ${res.totalPages}  (${res.total})'),
                              style: const TextStyle(
                                  color: AppColors.textSecondary),
                            ),
                            IconButton(
                              onPressed: query.page < res.totalPages
                                  ? () => ref
                                      .read(inboxQueryProvider.notifier)
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

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Chip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withOpacity(0.1)
                : AppColors.background,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
            ),
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
      ),
    );
  }
}

class _MailTile extends StatelessWidget {
  final InboxMessageSummary message;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  const _MailTile({
    required this.message,
    required this.onOpen,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final m = message;
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: m.unseen
                  ? AppColors.primary.withOpacity(0.35)
                  : AppColors.border,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  m.unseen
                      ? Icons.mark_email_unread_outlined
                      : Icons.mail_outline,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m.subject,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight:
                            m.unseen ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      m.displayFrom,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          m.dateFa.isNotEmpty ? m.dateFa : m.dateRaw,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                        if (m.hasAttachment) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.attach_file,
                              size: 14, color: AppColors.textMuted),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'open') onOpen();
                  if (v == 'delete') onDelete();
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'open', child: Text('مشاهده')),
                  PopupMenuItem(value: 'delete', child: Text('حذف')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
