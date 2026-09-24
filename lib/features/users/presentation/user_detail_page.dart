import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../data/user_models.dart';
import '../data/user_repository.dart';
import 'users_provider.dart';

String _fa(String input) {
  const en = '0123456789';
  const fa = '۰۱۲۳۴۵۶۷۸۹';
  var out = input;
  for (var i = 0; i < 10; i++) {
    out = out.replaceAll(en[i], fa[i]);
  }
  return out;
}

String _jalali(DateTime? d) {
  if (d == null) return '—';
  final j = Jalali.fromDateTime(d.toLocal());
  return _fa(
      '${j.year}/${j.month.toString().padLeft(2, '0')}/${j.day.toString().padLeft(2, '0')}');
}

String _jalaliTime(DateTime? d) {
  if (d == null) return '—';
  final local = d.toLocal();
  final j = Jalali.fromDateTime(local);
  final t =
      '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  return _fa(
      '${j.year}/${j.month.toString().padLeft(2, '0')}/${j.day.toString().padLeft(2, '0')}  $t');
}

String _money(String price) {
  final n = double.tryParse(price) ?? 0;
  final f = n.toInt().toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );
  return '${_fa(f)} تومان';
}

DateTime? _parseDate(String s) {
  if (s.isEmpty) return null;
  final asInt = int.tryParse(s);
  if (asInt != null && asInt > 100000) {
    return DateTime.fromMillisecondsSinceEpoch(
      asInt > 9999999999 ? asInt : asInt * 1000,
    );
  }
  return DateTime.tryParse(s);
}

class UserDetailPage extends ConsumerWidget {
  final int userId;
  const UserDetailPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncUser = ref.watch(userDetailProvider(userId));
    final asyncDossier = ref.watch(userDossierProvider(userId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('پرونده مشتری'),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/users'),
        ),
        actions: [
          IconButton(
            tooltip: 'ویرایش',
            icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
            onPressed: () => context.go('/users/$userId/edit'),
          ),
        ],
      ),
      body: asyncUser.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('خطا: $e')),
        data: (u) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 1) مشخصات
              _Card(
                title: 'مشخصات مشتری',
                child: Column(
                  children: [
                    _kv('نام', u.displayName),
                    _kv('نام کاربری', u.username, ltr: true),
                    _kv(
                      'موبایل',
                      u.primaryPhone.isEmpty
                          ? '—'
                          : _fa(u.primaryPhone),
                      ltr: true,
                    ),
                    _kv('ایمیل', u.email.isEmpty ? '—' : u.email, ltr: true),
                    _kv(
                      'رمز عبور',
                      u.hasPassword
                          ? 'تنظیم شده'
                          : 'تنظیم نشده (ورود با کد یکبارمصرف)',
                    ),
                    _kv('تاریخ عضویت', _jalali(u.dateCreated)),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 2) آخرین ورود
              asyncDossier.when(
                loading: () => const _Card(
                  title: 'آخرین ورود',
                  child: LinearProgressIndicator(minHeight: 2),
                ),
                error: (_, __) => _Card(
                  title: 'آخرین ورود',
                  child: Text(_jalaliTime(u.lastLogin)),
                ),
                data: (d) => _Card(
                  title: 'آخرین ورود',
                  child: Text(
                    _jalaliTime(d.lastLogin ?? u.lastLogin),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 3) کیف پول + خریدها
              asyncDossier.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => _WalletCard(
                  balance: u.walletBalance,
                  ordersCount: u.ordersCount,
                  totalSpent: u.totalSpent,
                  recent: const [],
                ),
                data: (d) => _WalletCard(
                  balance: d.walletBalance > 0 ? d.walletBalance : u.walletBalance,
                  ordersCount:
                      d.ordersCount > 0 ? d.ordersCount : u.ordersCount,
                  totalSpent: d.totalSpent != '0' ? d.totalSpent : u.totalSpent,
                  recent: d.recentOrders,
                ),
              ),
              const SizedBox(height: 12),

              // 4) نسخه‌های آپلود شده
              asyncDossier.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const _Card(
                  title: 'نسخه‌های بیمار',
                  child: Text('در دسترس نیست',
                      style: TextStyle(color: AppColors.textMuted)),
                ),
                data: (d) => _PrescriptionsCard(items: d.prescriptions),
              ),
              const SizedBox(height: 12),

              // 5) سبد خرید
              asyncDossier.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (d) => _CartCard(items: d.cartItems),
              ),
              const SizedBox(height: 12),

              // 6) مرجوعی / لغو / تحویل
              asyncDossier.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (d) => _StatusOrdersCard(
                  cancelled: d.cancelled,
                  refunded: d.refunded,
                  completed: d.completed,
                ),
              ),

              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: () => context.go('/users/$userId/edit'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  foregroundColor: AppColors.primary,
                ),
                child: const Text('ویرایش مشخصات'),
              ),
              TextButton(
                onPressed: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('حذف مشتری'),
                      content:
                          const Text('حذف کامل این مشتری انجام شود؟'),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('انصراف')),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: TextButton.styleFrom(
                              foregroundColor: AppColors.danger),
                          child: const Text('حذف'),
                        ),
                      ],
                    ),
                  );
                  if (ok != true) return;
                  try {
                    await ref.read(userRepositoryProvider).deleteUser(u.id);
                    if (context.mounted) {
                      context.go('/users');
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('خطا: $e')),
                      );
                    }
                  }
                },
                style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                child: const Text('حذف کامل مشتری'),
              ),
              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }
}

// ---------- shared UI ----------

class _Card extends StatelessWidget {
  final String title;
  final Widget child;
  const _Card({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

Widget _kv(String k, String v, {bool ltr = false}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            k,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            v,
            textDirection: ltr ? TextDirection.ltr : TextDirection.rtl,
            textAlign: ltr ? TextAlign.left : TextAlign.right,
            style: const TextStyle(fontSize: 13),
          ),
        ),
      ],
    ),
  );
}

class _WalletCard extends StatelessWidget {
  final int balance;
  final int ordersCount;
  final String totalSpent;
  final List<DossierOrder> recent;

  const _WalletCard({
    required this.balance,
    required this.ordersCount,
    required this.totalSpent,
    required this.recent,
  });

  @override
  Widget build(BuildContext context) {
    return _Card(
      title: 'کیف پول و خریدها',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _stat('موجودی کیف پول', _money('$balance')),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _stat('جمع خریدها', _money(totalSpent)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _stat('تعداد خرید', _fa('$ordersCount')),
              ),
            ],
          ),
          if (recent.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Text(
              'آخرین خریدها',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 8),
            ...recent.take(5).map((o) => _orderTile(context, o)),
          ],
        ],
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 12,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

Widget _orderTile(BuildContext context, DossierOrder o) {
  return InkWell(
    onTap: () => context.go('/orders/${o.id}'),
    child: Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '#${o.number}  ${o.isWallet ? '(شارژ کیف پول)' : ''}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 12),
                ),
                Text(
                  o.statusLabel,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Text(
            _money(o.total),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    ),
  );
}

class _PrescriptionsCard extends StatelessWidget {
  final List<UserPrescription> items;
  const _PrescriptionsCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return _Card(
      title: 'نسخه‌های بیمار',
      child: items.isEmpty
          ? const Text(
              'نسخه‌ای ثبت نشده است',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            )
          : Column(
              children: items.map((rx) {
                return InkWell(
                  onTap: () => _openRx(context, rx),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.description_outlined,
                              color: AppColors.primary, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                rx.rxTypeLabel.isNotEmpty
                                    ? rx.rxTypeLabel
                                    : 'نسخه #${rx.id}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 13),
                              ),
                              Text(
                                [
                                  if (rx.doctorName.isNotEmpty) rx.doctorName,
                                  if (rx.issuedAt.isNotEmpty) rx.issuedAt,
                                ].join(' · '),
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary),
                              ),
                              if (rx.file != null)
                                const Text(
                                  'فایل پیوست دارد',
                                  style: TextStyle(
                                      fontSize: 10, color: AppColors.info),
                                ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_left,
                            color: AppColors.textMuted),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
    );
  }

  void _openRx(BuildContext context, UserPrescription rx) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (_, scroll) {
            return Container(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
              ),
              child: ListView(
                controller: scroll,
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'جزئیات نسخه',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const Divider(),
                  _kv('نوع', rx.rxTypeLabel),
                  _kv('پزشک', rx.doctorName.isEmpty ? '—' : rx.doctorName),
                  _kv('تاریخ نسخه', rx.issuedAt.isEmpty ? '—' : rx.issuedAt),
                  _kv('OD SPH/CYL/AXIS',
                      '${rx.odSph} / ${rx.odCyl} / ${rx.odAxis}'),
                  _kv('OS SPH/CYL/AXIS',
                      '${rx.osSph} / ${rx.osCyl} / ${rx.osAxis}'),
                  _kv('PD', rx.pd.isEmpty ? '—' : rx.pd),
                  if (rx.notes.isNotEmpty) _kv('یادداشت', rx.notes),
                  if (rx.file != null && rx.file!.url.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text('فایل پیوست',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    if (rx.file!.isImage)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          rx.file!.url,
                          height: 200,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Text(
                              'پیش‌نمایش در دسترس نیست'),
                        ),
                      ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final uri = Uri.parse(rx.file!.url);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri,
                              mode: LaunchMode.externalApplication);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.download_outlined),
                      label: Text(
                        rx.file!.filename.isNotEmpty
                            ? 'دانلود ${rx.file!.filename}'
                            : 'دانلود فایل',
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 12),
                    const Text(
                      'فایل پیوست ندارد',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _CartCard extends StatelessWidget {
  final List<CartLine> items;
  const _CartCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return _Card(
      title: 'سبد خرید ذخیره‌شده',
      child: items.isEmpty
          ? const Text(
              'سبد خرید خالی است یا ذخیره‌ای وجود ندارد',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            )
          : Column(
              children: items.map((c) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          c.name.isEmpty ? 'محصول #${c.productId}' : c.name,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      Text(
                        '× ${_fa('${c.quantity}')}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 12),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }
}

class _StatusOrdersCard extends StatelessWidget {
  final List<DossierOrder> cancelled;
  final List<DossierOrder> refunded;
  final List<DossierOrder> completed;

  const _StatusOrdersCard({
    required this.cancelled,
    required this.refunded,
    required this.completed,
  });

  @override
  Widget build(BuildContext context) {
    return _Card(
      title: 'وضعیت سفارش‌ها',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _group(context, 'تحویل / تکمیل‌شده', completed),
          const SizedBox(height: 12),
          _group(context, 'لغو شده', cancelled),
          const SizedBox(height: 12),
          _group(context, 'مرجوعی / استرداد', refunded),
        ],
      ),
    );
  }

  Widget _group(BuildContext context, String title, List<DossierOrder> list) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$title (${_fa('${list.length}')})',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 6),
        if (list.isEmpty)
          const Text(
            'موردی نیست',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          )
        else
          ...list.take(8).map((o) => _orderTile(context, o)),
      ],
    );
  }
}
