import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../data/wallet_models.dart';

class WalletPaymentInfoCard extends StatelessWidget {
  final WalletPaymentConfig config;
  final VoidCallback? onEdit;

  const WalletPaymentInfoCard({
    super.key,
    required this.config,
    this.onEdit,
  });

  Future<void> _copy(BuildContext context, String value, String label) async {
    if (value.trim().isEmpty) return;
    await Clipboard.setData(ClipboardData(text: value));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label کپی شد'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _valueRow(
    BuildContext context, {
    required String label,
    required String value,
    bool ltr = false,
  }) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  textDirection: ltr ? TextDirection.ltr : TextDirection.rtl,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'کپی $label',
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.copy_rounded, size: 18),
            onPressed: () => _copy(context, value, label),
          ),
        ],
      ),
    );
  }

  Widget _method(String title, bool enabled) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: enabled
            ? AppColors.success.withOpacity(.08)
            : AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: enabled
              ? AppColors.success.withOpacity(.2)
              : AppColors.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            enabled ? Icons.check_circle_outline : Icons.remove_circle_outline,
            size: 16,
            color: enabled ? AppColors.success : AppColors.textMuted,
          ),
          const SizedBox(width: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: enabled ? AppColors.textPrimary : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.035),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(.09),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.account_balance_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 11),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'حساب‌های کیف پول',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'اطلاعات پرداخت کیف پول مستقیماً با پلاگین همگام است',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (onEdit != null)
                IconButton(
                  tooltip: 'ویرایش اطلاعات حساب',
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              _method('درگاه پرداخت', config.onlineEnabled),
              _method('کارت به کارت', config.cardEnabled),
              _method('اینترنت‌بانک', config.bankEnabled),
            ],
          ),
          if (config.hasAccountData) ...[
            const Divider(height: 24),
            if (config.bankName.isNotEmpty || config.accountOwner.isNotEmpty)
              Row(
                children: [
                  Expanded(
                    child: Text(
                      config.bankName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (config.accountOwner.isNotEmpty)
                    Text(
                      config.accountOwner,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            if (config.accountName.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  config.accountName,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            _valueRow(
              context,
              label: 'شماره کارت',
              value: config.cardNumber,
              ltr: true,
            ),
            _valueRow(
              context,
              label: 'شماره حساب',
              value: config.accountNumber,
              ltr: true,
            ),
            _valueRow(
              context,
              label: 'شماره شبا',
              value: config.iban,
              ltr: true,
            ),
            if (config.note.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  config.note,
                  style: const TextStyle(
                    fontSize: 11,
                    height: 1.7,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
          ] else
            const Padding(
              padding: EdgeInsets.only(top: 14),
              child: Text(
                'هنوز اطلاعات حساب مقصد در تنظیمات پلاگین ثبت نشده است.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
