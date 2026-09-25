import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../data/wallet_payment_models.dart';
import '../data/wallet_payment_repository.dart';

final walletPaymentSettingsProvider =
    FutureProvider.autoDispose<WalletPaymentSettings>((ref) {
  return ref.watch(walletPaymentSettingsRepositoryProvider).fetch();
});

class WalletPaymentAccountsPage extends ConsumerWidget {
  const WalletPaymentAccountsPage({super.key});

  Future<void> _copy(BuildContext context, String value, String label) async {
    if (value.trim().isEmpty) return;
    await Clipboard.setData(ClipboardData(text: value));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label کپی شد'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(walletPaymentSettingsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('روش‌های پرداخت کیف پول'),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/wallet'),
        ),
        actions: [
          IconButton(
            tooltip: 'به‌روزرسانی',
            onPressed: () => ref.invalidate(walletPaymentSettingsProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.account_balance_wallet_outlined, size: 48),
                const SizedBox(height: 12),
                const Text('دریافت تنظیمات کیف پول انجام نشد',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text('$e', textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => ref.invalidate(walletPaymentSettingsProvider),
                  child: const Text('تلاش مجدد'),
                ),
              ],
            ),
          ),
        ),
        data: (settings) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(walletPaymentSettingsProvider);
            await ref.read(walletPaymentSettingsProvider.future);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            children: [
              _MethodsCard(settings: settings),
              const SizedBox(height: 14),
              if (!settings.account.isEmpty)
                _AccountCard(
                  account: settings.account,
                  onCopy: (value, label) => _copy(context, value, label),
                )
              else
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Text(
                    'اطلاعات حساب بانکی هنوز در تنظیمات پلاگین ثبت نشده است.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              if (settings.account.note.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  settings.account.note,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    height: 1.6,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MethodsCard extends StatelessWidget {
  final WalletPaymentSettings settings;

  const _MethodsCard({required this.settings});

  @override
  Widget build(BuildContext context) {
    final items = <({String title, String subtitle, IconData icon, bool enabled})>[
      (
        title: 'درگاه پرداخت',
        subtitle: 'شارژ آنلاین کیف پول',
        icon: Icons.credit_card_outlined,
        enabled: settings.onlineEnabled,
      ),
      (
        title: 'کارت به کارت',
        subtitle: 'واریز با فیش',
        icon: Icons.receipt_long_outlined,
        enabled: settings.cardEnabled,
      ),
      (
        title: 'اینترنت‌بانک',
        subtitle: 'واریز و ثبت شناسه پرداخت',
        icon: Icons.account_balance_outlined,
        enabled: settings.bankEnabled,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('روش‌های فعال',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: (item.enabled
                              ? AppColors.success
                              : AppColors.textMuted)
                          .withOpacity(.10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      item.icon,
                      size: 20,
                      color: item.enabled
                          ? AppColors.success
                          : AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.title,
                            style: const TextStyle(fontWeight: FontWeight.w700)),
                        Text(item.subtitle,
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                  Text(
                    item.enabled ? 'فعال' : 'غیرفعال',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: item.enabled
                          ? AppColors.success
                          : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  final WalletBankAccount account;
  final void Function(String value, String label) onCopy;

  const _AccountCard({required this.account, required this.onCopy});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            blurRadius: 24,
            offset: const Offset(0, 10),
            color: Colors.black.withOpacity(.04),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(.09),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.account_balance_outlined,
                    color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.bankName.isEmpty ? 'حساب بانکی' : account.bankName,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                    if (account.accountName.isNotEmpty)
                      Text(account.accountName,
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textMuted)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (account.owner.isNotEmpty)
            _AccountRow('صاحب حساب', account.owner, false, onCopy),
          if (account.cardNumber.isNotEmpty)
            _AccountRow('شماره کارت', account.cardNumber, true, onCopy),
          if (account.accountNumber.isNotEmpty)
            _AccountRow('شماره حساب', account.accountNumber, true, onCopy),
          if (account.iban.isNotEmpty)
            _AccountRow('شماره شبا', account.iban, true, onCopy),
        ],
      ),
    );
  }
}

class _AccountRow extends StatelessWidget {
  final String label;
  final String value;
  final bool ltr;
  final void Function(String value, String label) onCopy;

  const _AccountRow(this.label, this.value, this.ltr, this.onCopy);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.textMuted)),
                const SizedBox(height: 3),
                Text(
                  value,
                  textDirection: ltr ? TextDirection.ltr : TextDirection.rtl,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: ltr ? .4 : 0,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'کپی',
            onPressed: () => onCopy(value, label),
            icon: const Icon(Icons.copy_outlined, size: 18),
          ),
        ],
      ),
    );
  }
}
