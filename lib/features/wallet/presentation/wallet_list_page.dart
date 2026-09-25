import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../data/wallet_models.dart';
import '../data/wallet_repository.dart';
import 'wallet_provider.dart';
import 'wallet_payment_info_card.dart';

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

class WalletListPage extends ConsumerStatefulWidget {
  const WalletListPage({super.key});

  @override
  ConsumerState<WalletListPage> createState() => _WalletListPageState();
}

class _WalletListPageState extends ConsumerState<WalletListPage> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;
  bool _acting = false;

  Future<void> _editPaymentConfig(WalletPaymentConfig current) async {
    final bank = TextEditingController(text: current.bankName);
    final owner = TextEditingController(text: current.accountOwner);
    final accountName = TextEditingController(text: current.accountName);
    final card = TextEditingController(text: current.cardNumber);
    final account = TextEditingController(text: current.accountNumber);
    final iban = TextEditingController(text: current.iban);
    final note = TextEditingController(text: current.note);
    var online = current.onlineEnabled;
    var cardEnabled = current.cardEnabled;
    var bankEnabled = current.bankEnabled;

    try {
      final result = await showDialog<bool>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            title: const Text('اطلاعات حساب کیف پول'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('درگاه پرداخت'),
                    value: online,
                    onChanged: (v) => setDialogState(() => online = v),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('کارت به کارت'),
                    value: cardEnabled,
                    onChanged: (v) => setDialogState(() => cardEnabled = v),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('اینترنت‌بانک'),
                    value: bankEnabled,
                    onChanged: (v) => setDialogState(() => bankEnabled = v),
                  ),
                  const Divider(),
                  for (final field in [
                    (bank, 'نام بانک'),
                    (owner, 'صاحب حساب'),
                    (accountName, 'عنوان حساب'),
                    (card, 'شماره کارت'),
                    (account, 'شماره حساب'),
                    (iban, 'شماره شبا'),
                  ])
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: TextField(
                        controller: field.$1,
                        decoration: InputDecoration(
                          labelText: field.$2,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                  TextField(
                    controller: note,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'توضیحات پرداخت',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('انصراف'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('ذخیره'),
              ),
            ],
          ),
        ),
      );
      if (result != true) return;
      setState(() => _acting = true);
      await ref.read(walletRepositoryProvider).savePaymentConfig(
            WalletPaymentConfig(
              onlineEnabled: online,
              cardEnabled: cardEnabled,
              bankEnabled: bankEnabled,
              bankName: bank.text.trim(),
              accountOwner: owner.text.trim(),
              accountName: accountName.text.trim(),
              cardNumber: card.text.trim(),
              accountNumber: account.text.trim(),
              iban: iban.text.trim(),
              note: note.text.trim(),
            ),
          );
      ref.invalidate(walletPaymentConfigProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('اطلاعات حساب کیف پول ذخیره شد'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطا در ذخیره اطلاعات حساب: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      bank.dispose();
      owner.dispose();
      accountName.dispose();
      card.dispose();
      account.dispose();
      iban.dispose();
      note.dispose();
      if (mounted) setState(() => _acting = false);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      final q = ref.read(walletQueryProvider);
      ref.read(walletQueryProvider.notifier).state =
          q.copyWith(search: v.trim(), page: 1);
    });
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'pending':
        return AppColors.warning;
      case 'approved':
        return AppColors.success;
      case 'rejected':
        return AppColors.danger;
      default:
        return AppColors.textMuted;
    }
  }

  Future<void> _approve(WalletDeposit d) async {
    final noteCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأیید شارژ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('مبلغ ${_money(d.amount)} به کیف پول ${d.user.title} اضافه شود؟'),
            const SizedBox(height: 12),
            TextField(
              controller: noteCtrl,
              decoration: const InputDecoration(
                labelText: 'یادداشت مدیر (اختیاری)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('انصراف')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('تأیید و شارژ'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _acting = true);
    try {
      await ref
          .read(walletRepositoryProvider)
          .approve(d.id, note: noteCtrl.text.trim());
      ref.invalidate(walletDepositsProvider);
      ref.invalidate(walletStatsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تأیید شد و کیف پول شارژ شد'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا: $e'), backgroundColor: AppColors.danger),
      );
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<void> _reject(WalletDeposit d) async {
    final noteCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('رد درخواست'),
        content: TextField(
          controller: noteCtrl,
          decoration: const InputDecoration(
            labelText: 'علت رد',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('انصراف')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('رد'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _acting = true);
    try {
      await ref
          .read(walletRepositoryProvider)
          .reject(d.id, note: noteCtrl.text.trim());
      ref.invalidate(walletDepositsProvider);
      ref.invalidate(walletStatsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('درخواست رد شد')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا: $e'), backgroundColor: AppColors.danger),
      );
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<void> _openReceipt(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncList = ref.watch(walletDepositsProvider);
    final statsAsync = ref.watch(walletStatsProvider);
    final query = ref.watch(walletQueryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('شارژ کیف پول'),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/more'),
        ),
        actions: [
          IconButton(
            tooltip: 'حساب‌های پرداخت',
            icon: const Icon(Icons.account_balance_outlined, color: AppColors.primary),
            onPressed: () => context.go('/wallet/accounts'),
          ),
          IconButton(
            tooltip: 'شارژ دستی',
            icon: const Icon(Icons.add_card_outlined, color: AppColors.primary),
            onPressed: () => context.go('/wallet/adjust'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(walletDepositsProvider);
              ref.invalidate(walletStatsProvider);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          ref.watch(walletPaymentConfigProvider).when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (config) => WalletPaymentInfoCard(
              config: config,
              onEdit: () => _editPaymentConfig(config),
            ),
          ),
          // Stats
          statsAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (s) {
              final pending = int.tryParse('${s['pending_count']}') ?? 0;
              final sum = int.tryParse('${s['approved_sum']}') ?? 0;
              return Container(
                width: double.infinity,
                color: AppColors.surface,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: _statChip(
                        'در انتظار',
                        _fa('$pending'),
                        AppColors.warning,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _statChip(
                        'مجموع تأییدشده',
                        _money(sum),
                        AppColors.success,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  onChanged: _onSearch,
                  decoration: InputDecoration(
                    hintText: 'جستجو نام، موبایل، کد پیگیری...',
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
                        ('pending', 'در انتظار'),
                        ('approved', 'تأییدشده'),
                        ('rejected', 'ردشده'),
                        ('all', 'همه'),
                      ])
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: FilterChip(
                            label: Text(e.$2),
                            selected: query.status == e.$1,
                            onSelected: (_) {
                              ref.read(walletQueryProvider.notifier).state =
                                  query.copyWith(status: e.$1, page: 1);
                            },
                            selectedColor:
                                AppColors.primary.withOpacity(0.12),
                            checkmarkColor: AppColors.primary,
                            labelStyle: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: query.status == e.$1
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      const SizedBox(width: 8),
                      for (final e in [
                        ('all', 'همه روش‌ها'),
                        ('online', 'درگاه'),
                        ('card', 'کارت به کارت'),
                        ('bank', 'اینترنت‌بانک'),
                      ])
                        Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: FilterChip(
                            label: Text(e.$2),
                            selected: query.method == e.$1,
                            onSelected: (_) {
                              ref.read(walletQueryProvider.notifier).state =
                                  query.copyWith(method: e.$1, page: 1);
                            },
                            selectedColor:
                                AppColors.primary.withOpacity(0.12),
                            checkmarkColor: AppColors.primary,
                            labelStyle: const TextStyle(fontSize: 11),
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
                            ref.invalidate(walletDepositsProvider),
                        child: const Text('تلاش مجدد'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (res) {
                if (res.items.isEmpty) {
                  return const Center(
                    child: Text('درخواستی یافت نشد',
                        style: TextStyle(color: AppColors.textMuted)),
                  );
                }
                return Column(
                  children: [
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () async {
                          ref.invalidate(walletDepositsProvider);
                          ref.invalidate(walletStatsProvider);
                        },
                        child: ListView.separated(
                          padding:
                              const EdgeInsets.fromLTRB(16, 12, 16, 24),
                          itemCount: res.items.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, i) {
                            final d = res.items[i];
                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(12),
                                border:
                                    Border.all(color: AppColors.border),
                              ),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          d.user.title,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: _statusColor(d.status)
                                              .withOpacity(0.12),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          d.statusLabel.isEmpty
                                              ? d.status
                                              : d.statusLabel,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: _statusColor(d.status),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _money(d.amount),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  Text(
                                    '${d.methodLabel.isEmpty ? d.method : d.methodLabel}'
                                    '${d.refCode.isNotEmpty ? ' · کد: ${d.refCode}' : ''}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  if (d.user.phone.isNotEmpty)
                                    Text(
                                      _fa(d.user.phone),
                                      textDirection: TextDirection.ltr,
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textMuted,
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
                                  if (d.receiptUrl.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    TextButton.icon(
                                      onPressed: () =>
                                          _openReceipt(d.receiptUrl),
                                      icon: const Icon(
                                          Icons.attach_file, size: 16),
                                      label: const Text('مشاهده رسید'),
                                    ),
                                  ],
                                  if (d.isPending) ...[
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ElevatedButton(
                                            onPressed: _acting
                                                ? null
                                                : () => _approve(d),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  AppColors.success,
                                              foregroundColor: Colors.white,
                                            ),
                                            child: const Text('تأیید و شارژ'),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: OutlinedButton(
                                            onPressed: _acting
                                                ? null
                                                : () => _reject(d),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor:
                                                  AppColors.danger,
                                            ),
                                            child: const Text('رد'),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
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
                                      .read(walletQueryProvider.notifier)
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
                                      .read(walletQueryProvider.notifier)
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

  Widget _statChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(fontSize: 11, color: color.withOpacity(0.9))),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}
