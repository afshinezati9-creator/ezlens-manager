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

class WalletPaymentAccountsPage extends ConsumerStatefulWidget {
  const WalletPaymentAccountsPage({super.key});

  @override
  ConsumerState<WalletPaymentAccountsPage> createState() =>
      _WalletPaymentAccountsPageState();
}

class _WalletPaymentAccountsPageState
    extends ConsumerState<WalletPaymentAccountsPage> {
  final _formKey = GlobalKey<FormState>();
  final _bankName = TextEditingController();
  final _owner = TextEditingController();
  final _accountName = TextEditingController();
  final _cardNumber = TextEditingController();
  final _accountNumber = TextEditingController();
  final _iban = TextEditingController();
  final _note = TextEditingController();

  bool _online = false;
  bool _card = false;
  bool _bank = false;
  bool _saving = false;
  bool _initialized = false;

  @override
  void dispose() {
    for (final c in [
      _bankName,
      _owner,
      _accountName,
      _cardNumber,
      _accountNumber,
      _iban,
      _note,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _fill(WalletPaymentSettings s) {
    if (_initialized) return;
    _initialized = true;
    _online = s.onlineEnabled;
    _card = s.cardEnabled;
    _bank = s.bankEnabled;
    final a = s.account;
    _bankName.text = a.bankName;
    _owner.text = a.owner;
    _accountName.text = a.accountName;
    _cardNumber.text = a.cardNumber;
    _accountNumber.text = a.accountNumber;
    _iban.text = a.iban;
    _note.text = a.note;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    // The enabled manual methods must have the account data required to
    // complete that payment flow. Online gateway does not need bank data.
    if (_card && _cardNumber.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('برای کارت به کارت، شماره کارت را وارد کنید')),
      );
      return;
    }
    if (_bank &&
        _accountNumber.text.trim().isEmpty &&
        _iban.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('برای اینترنت‌بانک، شماره حساب یا شبا را وارد کنید')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final repo = ref.read(walletPaymentSettingsRepositoryProvider);
      final saved = await repo.save(
        WalletPaymentSettings(
          onlineEnabled: _online,
          cardEnabled: _card,
          bankEnabled: _bank,
          account: WalletBankAccount(
            bankName: _bankName.text.trim(),
            owner: _owner.text.trim(),
            accountName: _accountName.text.trim(),
            cardNumber: _cardNumber.text.trim(),
            accountNumber: _accountNumber.text.trim(),
            iban: _iban.text.trim(),
            note: _note.text.trim(),
          ),
        ),
      );
      _initialized = false;
      ref.invalidate(walletPaymentSettingsProvider);
      if (!mounted) return;
      _fill(saved);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تنظیمات کیف پول با موفقیت ذخیره شد'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ذخیره تنظیمات انجام نشد: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _copy(String value, String label) async {
    if (value.trim().isEmpty) return;
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label کپی شد'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            onPressed: () {
              _initialized = false;
              ref.invalidate(walletPaymentSettingsProvider);
            },
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
                  onPressed: () {
                    _initialized = false;
                    ref.invalidate(walletPaymentSettingsProvider);
                  },
                  child: const Text('تلاش مجدد'),
                ),
              ],
            ),
          ),
        ),
        data: (settings) {
          _fill(settings);
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                _section(
                  title: 'روش‌های پرداخت',
                  subtitle:
                      'روش‌های غیرفعال از کیف پول مشتری پنهان می‌شوند. درگاه آنلاین به اطلاعات حساب بانکی نیاز ندارد.',
                  child: Column(
                    children: [
                      _toggle('درگاه پرداخت', 'شارژ آنلاین کیف پول', Icons.credit_card_outlined,
                          _online, (v) => setState(() => _online = v)),
                      _toggle('کارت به کارت', 'ثبت فیش و کد پیگیری', Icons.receipt_long_outlined,
                          _card, (v) => setState(() => _card = v)),
                      _toggle('اینترنت‌بانک', 'ثبت شناسه یا تصویر پرداخت',
                          Icons.account_balance_outlined, _bank,
                          (v) => setState(() => _bank = v)),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _section(
                  title: 'اطلاعات حساب',
                  subtitle: 'این اطلاعات در روش‌های دستی کیف پول مشتری نمایش داده می‌شود و از همین‌جا مدیریت می‌گردد.',
                  child: Column(
                    children: [
                      _field(_bankName, 'نام بانک', Icons.account_balance_outlined),
                      _field(_owner, 'صاحب حساب', Icons.person_outline),
                      _field(_accountName, 'عنوان حساب', Icons.badge_outlined),
                      _field(_cardNumber, 'شماره کارت', Icons.credit_card_outlined,
                          ltr: true),
                      _field(_accountNumber, 'شماره حساب', Icons.numbers_outlined,
                          ltr: true),
                      _field(_iban, 'شماره شبا', Icons.account_balance_wallet_outlined,
                          ltr: true),
                      _field(_note, 'توضیحات', Icons.notes_outlined, maxLines: 3),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _preview(),
                const SizedBox(height: 18),
                SizedBox(
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 19,
                            height: 19,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(_saving ? 'در حال ذخیره...' : 'ذخیره تنظیمات'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _section({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
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
          Text(title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 5),
          Text(subtitle,
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _toggle(String title, String subtitle, IconData icon, bool value,
      ValueChanged<bool> onChanged) {
    return SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      value: value,
      onChanged: onChanged,
      secondary: Icon(icon),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle,
          style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
    );
  }

  Widget _field(TextEditingController controller, String label, IconData icon,
      {bool ltr = false, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        textDirection: ltr ? TextDirection.ltr : TextDirection.rtl,
        keyboardType: ltr ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          hintText: ltr ? 'فقط عدد وارد کنید' : null,
          prefixIcon: Icon(icon, size: 20),
          filled: true,
          fillColor: AppColors.background,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _preview() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('پیش‌نمایش اطلاعات مشتری',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          _previewRow('بانک', _bankName.text),
          _previewRow('صاحب حساب', _owner.text),
          _previewRow('کارت', _cardNumber.text, copy: true),
          _previewRow('حساب', _accountNumber.text, copy: true),
          _previewRow('شبا', _iban.text, copy: true),
        ],
      ),
    );
  }

  Widget _previewRow(String label, String value, {bool copy = false}) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.textMuted)),
                const SizedBox(height: 2),
                Text(value,
                    textDirection: copy ? TextDirection.ltr : TextDirection.rtl,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          if (copy)
            IconButton(
              tooltip: 'کپی',
              onPressed: () => _copy(value, label),
              icon: const Icon(Icons.copy_outlined, size: 18),
            ),
        ],
      ),
    );
  }
}
