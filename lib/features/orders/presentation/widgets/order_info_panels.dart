import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/order_models.dart';

/// Read-only modal for prescriptions or product options.
Future<void> showOrderInfoPanel(
  BuildContext context, {
  required String title,
  required Widget body,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (_, scrollCtrl) {
          return Container(
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'بستن',
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.all(16),
                    child: body,
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

class PrescriptionsPanelBody extends StatelessWidget {
  final List<OrderPrescriptionRecord> records;
  const PrescriptionsPanelBody({super.key, required this.records});

  @override
  Widget build(BuildContext context) {
    final usable = records.where((r) => r.fields.isNotEmpty).toList();
    if (usable.isEmpty) {
      return const _EmptyHint(
        text: 'نسخه یا پرونده‌ای برای این مشتری ثبت نشده است.',
      );
    }
    return Column(
      children: usable.map((rec) {
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                rec.title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
              if (rec.createdAt.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  rec.createdAt,
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
              const SizedBox(height: 10),
              ...rec.fields.map((f) => _FieldRow(label: f.label, value: f.value)),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class ProductOptionsPanelBody extends StatelessWidget {
  final List<OrderProductOptionsBlock> blocks;
  /// Fallback from line item meta when API empty.
  final List<OrderItem> lineItems;

  const ProductOptionsPanelBody({
    super.key,
    required this.blocks,
    this.lineItems = const [],
  });

  @override
  Widget build(BuildContext context) {
    final fromApi = blocks.where((b) => b.options.isNotEmpty).toList();
    if (fromApi.isNotEmpty) {
      return Column(
        children: fromApi.map((b) {
          return Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  b.name,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                Text(
                  'تعداد: ${b.quantity}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
                const SizedBox(height: 10),
                ...b.options.map((f) => _FieldRow(label: f.label, value: f.value)),
              ],
            ),
          );
        }).toList(),
      );
    }

    // Fallback: WC line item meta
    final withMeta = lineItems.where((i) => i.visibleOptions.isNotEmpty).toList();
    if (withMeta.isEmpty) {
      return const _EmptyHint(
        text: 'ویژگی انتخاب‌شده‌ای برای اقلام این سفارش یافت نشد.',
      );
    }
    return Column(
      children: withMeta.map((item) {
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              const SizedBox(height: 10),
              ...item.visibleOptions.map(
                (m) => _FieldRow(
                  label: m.key.replaceAll('_', ' '),
                  value: '${m.value}',
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _FieldRow extends StatelessWidget {
  final String label;
  final String value;
  const _FieldRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
              textAlign: TextAlign.left,
              textDirection: TextDirection.ltr,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final String text;
  const _EmptyHint({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
      ),
    );
  }
}

/// Action buttons row: prescriptions / product options / notify.
class OrderContextActions extends StatelessWidget {
  final bool loading;
  final VoidCallback onPrescriptions;
  final VoidCallback onProductOptions;
  final VoidCallback onNotify;

  const OrderContextActions({
    super.key,
    required this.loading,
    required this.onPrescriptions,
    required this.onProductOptions,
    required this.onNotify,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'اطلاعات تخصصی سفارش',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ActionChip(
                icon: Icons.visibility_outlined,
                label: 'نسخه‌های بیمار',
                onTap: onPrescriptions,
              ),
              _ActionChip(
                icon: Icons.layers_outlined,
                label: 'ویژگی‌های محصول',
                onTap: onProductOptions,
              ),
              _ActionChip(
                icon: Icons.notifications_outlined,
                label: 'اطلاع‌رسانی به مشتری',
                onTap: onNotify,
                emphasized: true,
              ),
            ],
          ),
      ],
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool emphasized;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = emphasized ? AppColors.primary.withOpacity(0.1) : AppColors.surface;
    final border = emphasized ? AppColors.primary : AppColors.border;
    final fg = emphasized ? AppColors.primary : AppColors.textPrimary;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: fg),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: fg),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dialog after status change / manual notify.
Future<void> showNotifyCustomerDialog(
  BuildContext context, {
  required Future<void> Function(List<String> channels, String? message) onSend,
  String? statusLabel,
}) async {
  var email = true;
  var sms = true;
  final msgCtrl = TextEditingController(
    text: statusLabel != null && statusLabel.isNotEmpty
        ? 'وضعیت سفارش شما به «$statusLabel» تغییر کرد.'
        : '',
  );
  var sending = false;

  await showDialog<void>(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setLocal) {
          return AlertDialog(
            title: const Text('اطلاع‌رسانی به مشتری'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'کانال‌های ارسال:',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('ایمیل'),
                    value: email,
                    onChanged: sending
                        ? null
                        : (v) => setLocal(() => email = v ?? false),
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('پیامک'),
                    value: sms,
                    onChanged: sending
                        ? null
                        : (v) => setLocal(() => sms = v ?? false),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: msgCtrl,
                    maxLines: 3,
                    enabled: !sending,
                    decoration: const InputDecoration(
                      labelText: 'متن پیام (اختیاری)',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: sending ? null : () => Navigator.pop(ctx),
                child: const Text('انصراف'),
              ),
              ElevatedButton(
                onPressed: sending || (!email && !sms)
                    ? null
                    : () async {
                        setLocal(() => sending = true);
                        final channels = <String>[
                          if (email) 'email',
                          if (sms) 'sms',
                        ];
                        try {
                          await onSend(channels, msgCtrl.text.trim());
                          if (ctx.mounted) Navigator.pop(ctx);
                        } catch (_) {
                          setLocal(() => sending = false);
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: sending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('ارسال'),
              ),
            ],
          );
        },
      );
    },
  );
  msgCtrl.dispose();
}
