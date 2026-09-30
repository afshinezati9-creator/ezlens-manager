import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/presentation/auth_provider.dart';
import '../data/settings_models.dart';
import 'settings_provider.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final auth = ref.watch(authProvider);

    String siteLabel = 'متصل به وردپرس';
    try {
      // Best-effort: many auth states expose siteUrl / username
      final dynamic a = auth;
      final url = a.siteUrl ?? a.baseUrl ?? a.site ?? '';
      final user = a.username ?? a.user ?? a.login ?? '';
      if (url.toString().isNotEmpty || user.toString().isNotEmpty) {
        siteLabel = [
          if (user.toString().isNotEmpty) user.toString(),
          if (url.toString().isNotEmpty) url.toString(),
        ].join(' · ');
      }
    } catch (_) {}

    final byCat = <String, List<AppModuleInfo>>{};
    for (final m in kAppModules) {
      byCat.putIfAbsent(m.category, () => []).add(m);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('تنظیمات'),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/more'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          // —— Connection ——
          _sectionTitle('اتصال'),
          _card(
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.cloud_done_outlined,
                      color: AppColors.primary),
                ),
                title: const Text('حساب مدیر',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(
                  siteLabel,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.api_outlined,
                    color: AppColors.textSecondary),
                title: const Text('API Manager'),
                subtitle: const Text(
                  'مسیر: /wp-json/ezlens/v1/manager/*',
                  style: TextStyle(fontSize: 12),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'پس از افزودن فایل‌های REST جدید، در وردپرس: پیوندهای یکتا → ذخیره',
                style: TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
            ],
          ),

          const SizedBox(height: 18),
          _sectionTitle('ترجیحات برنامه'),
          _card(
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('تأیید قبل از ارسال جمعی'),
                subtitle: const Text('برای پیام جمعی و کمپین'),
                value: settings.confirmBulkSend,
                activeColor: AppColors.primary,
                onChanged: (v) =>
                    ref.read(settingsProvider.notifier).setConfirmBulkSend(v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('تأیید قبل از حذف'),
                subtitle: const Text('حذف اسکریپت، کوپن، مورد و…'),
                value: settings.confirmDelete,
                activeColor: AppColors.primary,
                onChanged: (v) =>
                    ref.read(settingsProvider.notifier).setConfirmDelete(v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('لیست فشرده'),
                subtitle: const Text('فاصله کمتر در لیست‌ها'),
                value: settings.compactLists,
                activeColor: AppColors.primary,
                onChanged: (v) =>
                    ref.read(settingsProvider.notifier).setCompactLists(v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('راهنمای ماژول‌ها'),
                subtitle: const Text('نمایش توضیح کوتاه زیر عنوان'),
                value: settings.showModuleHints,
                activeColor: AppColors.primary,
                onChanged: (v) =>
                    ref.read(settingsProvider.notifier).setShowModuleHints(v),
              ),
              const Divider(height: 20),
              const Text('صفحه شروع پس از ورود',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: settings.defaultHome,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                items: const [
                  DropdownMenuItem(
                      value: 'dashboard', child: Text('داشبورد')),
                  DropdownMenuItem(value: 'orders', child: Text('سفارش‌ها')),
                  DropdownMenuItem(
                      value: 'products', child: Text('محصولات')),
                  DropdownMenuItem(value: 'support', child: Text('پشتیبانی')),
                ],
                onChanged: (v) {
                  if (v != null) {
                    ref.read(settingsProvider.notifier).setDefaultHome(v);
                  }
                },
              ),
            ],
          ),

          const SizedBox(height: 18),
          _sectionTitle('ماژول‌های فعال'),
          Text(
            '${kAppModules.length} بخش متصل به پلاگین EzLens',
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 8),
          for (final entry in byCat.entries) ...[
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 6),
              child: Text(
                entry.key,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            _card(
              children: [
                for (var i = 0; i < entry.value.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  _moduleTile(context, entry.value[i], settings.showModuleHints),
                ],
              ],
            ),
          ],

          const SizedBox(height: 18),
          _sectionTitle('APIهای Manager'),
          _card(
            children: const [
              _ApiLine(path: '/manager/customers', note: 'کاربران'),
              _ApiLine(path: '/manager/orders', note: 'سفارش‌ها'),
              _ApiLine(path: '/manager/support', note: 'پشتیبانی'),
              _ApiLine(path: '/manager/messages', note: 'پیام تکی'),
              _ApiLine(path: '/manager/campaigns', note: 'کمپین'),
              _ApiLine(path: '/manager/mass', note: 'پیام جمعی'),
              _ApiLine(path: '/manager/wallet', note: 'کیف پول'),
              _ApiLine(path: '/manager/charity', note: 'هم‌یاری'),
              _ApiLine(path: '/manager/discounts', note: 'تخفیف و هدیه'),
              _ApiLine(path: '/manager/purchase', note: 'فرآیند خرید'),
              _ApiLine(path: '/manager/inbox', note: 'صندوق ایمیل'),
            ],
          ),

          const SizedBox(height: 18),
          _sectionTitle('درباره'),
          _card(
            children: [
              const ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('EzLens Manager',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(
                  'پنل مدیریت ایزی‌لنز · RTL · تاریخ شمسی · AJAX',
                  style: TextStyle(fontSize: 12),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('بازنشانی ترجیحات'),
                trailing: const Icon(Icons.restart_alt, size: 20),
                onTap: () {
                  ref.read(settingsProvider.notifier).reset();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('ترجیحات به حالت پیش‌فرض برگشت')),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 20),
          SizedBox(
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('خروج'),
                    content: const Text('از حساب خارج می‌شوید؟'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('انصراف')),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: TextButton.styleFrom(
                            foregroundColor: AppColors.danger),
                        child: const Text('خروج'),
                      ),
                    ],
                  ),
                );
                if (ok == true) {
                  await ref.read(authProvider.notifier).logout();
                  if (context.mounted) context.go('/login');
                }
              },
              icon: const Icon(Icons.logout, color: AppColors.danger),
              label: const Text('خروج از حساب',
                  style: TextStyle(
                      color: AppColors.danger, fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.danger),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _sectionTitle(String t) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        t,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  static Widget _card({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  static Widget _moduleTile(
    BuildContext context,
    AppModuleInfo m,
    bool showHint,
  ) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Text(m.title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: showHint
          ? Text(m.subtitle,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary))
          : null,
      trailing: const Icon(Icons.chevron_left, size: 20),
      onTap: () => context.go(m.route),
    );
  }
}

class _ApiLine extends StatelessWidget {
  final String path;
  final String note;

  const _ApiLine({required this.path, required this.note});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              path,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 11.5,
                color: AppColors.primary,
              ),
              textDirection: TextDirection.ltr,
            ),
          ),
          Text(
            note,
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
