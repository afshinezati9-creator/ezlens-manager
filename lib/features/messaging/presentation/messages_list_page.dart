import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../data/message_models.dart';
import '../data/message_repository.dart';
import 'message_provider.dart';

String _fa(String s) {
  const en = '0123456789';
  const fa = '۰۱۲۳۴۵۶۷۸۹';
  var o = s;
  for (var i = 0; i < 10; i++) {
    o = o.replaceAll(en[i], fa[i]);
  }
  return o;
}

class MessagesListPage extends ConsumerStatefulWidget {
  const MessagesListPage({super.key});

  @override
  ConsumerState<MessagesListPage> createState() => _MessagesListPageState();
}

class _MessagesListPageState extends ConsumerState<MessagesListPage> {
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
      final q = ref.read(messageQueryProvider);
      ref.read(messageQueryProvider.notifier).state =
          q.copyWith(search: v.trim(), page: 1);
    });
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final now = Jalali.now();
    final picked = await showPersianDatePicker(
      context: context,
      initialDate: now,
      firstDate: Jalali(1398, 1, 1),
      lastDate: now,
    );
    if (picked == null) return;
    final g = picked.toDateTime();
    final iso =
        '${g.year.toString().padLeft(4, '0')}-${g.month.toString().padLeft(2, '0')}-${g.day.toString().padLeft(2, '0')}';
    final q = ref.read(messageQueryProvider);
    ref.read(messageQueryProvider.notifier).state = isFrom
        ? q.copyWith(from: iso, page: 1)
        : q.copyWith(to: iso, page: 1);
  }

  Future<void> _delete(SentMessage m) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف پیام'),
        content: const Text('این رکورد از تاریخچه حذف شود؟'),
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
      await ref.read(messageRepositoryProvider).delete(m.id);
      ref.invalidate(messageListProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('حذف شد'),
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
    final asyncList = ref.watch(messageListProvider);
    final query = ref.watch(messageQueryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('پیام تکی'),
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
            onPressed: () => ref.invalidate(messageListProvider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/messages/compose'),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.send_outlined, color: Colors.white),
        label: const Text('ارسال جدید', style: TextStyle(color: Colors.white)),
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
                    hintText: 'جستجو گیرنده، موضوع، متن...',
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
                        ('email', 'ایمیل'),
                        ('sms', 'پیامک'),
                      ])
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: FilterChip(
                            label: Text(e.$2),
                            selected: query.channel == e.$1,
                            onSelected: (_) {
                              ref.read(messageQueryProvider.notifier).state =
                                  query.copyWith(channel: e.$1, page: 1);
                            },
                            selectedColor: AppColors.primary.withOpacity(0.12),
                            checkmarkColor: AppColors.primary,
                            labelStyle: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: query.channel == e.$1
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      const SizedBox(width: 8),
                      ActionChip(
                        avatar: const Icon(Icons.date_range, size: 16),
                        label: Text(query.from.isEmpty
                            ? 'از تاریخ'
                            : _fa(query.from)),
                        onPressed: () => _pickDate(isFrom: true),
                      ),
                      const SizedBox(width: 6),
                      ActionChip(
                        avatar: const Icon(Icons.date_range, size: 16),
                        label:
                            Text(query.to.isEmpty ? 'تا تاریخ' : _fa(query.to)),
                        onPressed: () => _pickDate(isFrom: false),
                      ),
                      if (query.from.isNotEmpty || query.to.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            ref.read(messageQueryProvider.notifier).state =
                                query.copyWith(from: '', to: '', page: 1);
                          },
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
                            ref.invalidate(messageListProvider),
                        child: const Text('تلاش مجدد'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (res) {
                if (res.items.isEmpty) {
                  return const Center(
                    child: Text('پیامی ثبت نشده',
                        style: TextStyle(color: AppColors.textMuted)),
                  );
                }
                return Column(
                  children: [
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () async =>
                            ref.invalidate(messageListProvider),
                        child: ListView.separated(
                          padding:
                              const EdgeInsets.fromLTRB(16, 12, 16, 96),
                          itemCount: res.items.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, i) {
                            final m = res.items[i];
                            return Material(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              child: InkWell(
                                onTap: () => _showDetail(m),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: m.isFailed
                                          ? AppColors.danger
                                              .withOpacity(0.4)
                                          : AppColors.border,
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: AppColors.primary
                                              .withOpacity(0.08),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Icon(
                                          m.channel == 'sms'
                                              ? Icons.sms_outlined
                                              : Icons.email_outlined,
                                          color: AppColors.primary,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              m.recipientName.isNotEmpty
                                                  ? m.recipientName
                                                  : m.recipient,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 14,
                                              ),
                                            ),
                                            Text(
                                              m.recipient,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color:
                                                    AppColors.textSecondary,
                                              ),
                                              textDirection:
                                                  TextDirection.ltr,
                                              textAlign: TextAlign.right,
                                            ),
                                            if (m.subject.isNotEmpty)
                                              Text(
                                                m.subject,
                                                maxLines: 1,
                                                overflow:
                                                    TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                    fontSize: 12),
                                              ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${m.channelLabel} · ${m.createdFa.isNotEmpty ? m.createdFa : m.createdAt} · ${m.isFailed ? 'ناموفق' : 'ارسال‌شده'}',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: m.isFailed
                                                    ? AppColors.danger
                                                    : AppColors.textMuted,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                            Icons.delete_outline,
                                            color: AppColors.danger),
                                        onPressed: () => _delete(m),
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
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              onPressed: query.page > 1
                                  ? () => ref
                                      .read(messageQueryProvider.notifier)
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
                                      .read(messageQueryProvider.notifier)
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

  void _showDetail(SentMessage m) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
          ),
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text('جزئیات پیام',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(),
              Text('کانال: ${m.channelLabel}'),
              Text('گیرنده: ${m.recipient}'),
              if (m.subject.isNotEmpty) Text('موضوع: ${m.subject}'),
              Text(
                  'زمان: ${m.createdFa.isNotEmpty ? m.createdFa : m.createdAt}'),
              Text('وضعیت: ${m.isFailed ? 'ناموفق' : 'ارسال‌شده'}'),
              if (m.errorMessage.isNotEmpty)
                Text('خطا: ${m.errorMessage}',
                    style: const TextStyle(color: AppColors.danger)),
              const SizedBox(height: 12),
              const Text('متن', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              SelectableText(m.body, style: const TextStyle(height: 1.5)),
              if (m.attachmentUrl.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('پیوست: ${m.attachmentUrl}',
                    style: const TextStyle(fontSize: 12)),
              ],
            ],
          ),
        );
      },
    );
  }
}
