import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/presentation/lock_page.dart';

class SecuritySettingsSection extends ConsumerStatefulWidget {
  const SecuritySettingsSection({super.key});
  @override
  ConsumerState<SecuritySettingsSection> createState() =>
      _SecuritySettingsSectionState();
}

class _SecuritySettingsSectionState
    extends ConsumerState<SecuritySettingsSection> {
  bool _bio = false;
  bool _bioSupported = false;
  bool _orders = true;
  bool _comments = true;
  bool _tickets = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final storage = ref.read(secureStorageProvider);
    final bio = ref.read(biometricServiceProvider);
    final enabled = await storage.isBiometricEnabled();
    final supported = kIsWeb ? false : await bio.isSupported();
    final o = await storage.notifOrders();
    final c = await storage.notifComments();
    final t = await storage.notifTickets();
    if (!mounted) return;
    setState(() {
      _bio = enabled;
      _bioSupported = supported;
      _orders = o;
      _comments = c;
      _tickets = t;
      _loading = false;
    });
  }

  Widget _card(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Column(children: children),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('امنیت',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        _card([
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary:
                const Icon(Icons.fingerprint, color: AppColors.primary),
            title: const Text('باز کردن با اثرانگشت'),
            subtitle: Text(
              _bioSupported
                  ? 'بعد از یک‌بار ورود، تا خروج فقط با اثرانگشت باز می‌شود'
                  : (kIsWeb
                      ? 'در نسخه وب در دسترس نیست'
                      : 'دستگاه پشتیبانی نمی‌کند'),
              style: const TextStyle(fontSize: 12),
            ),
            value: _bio && _bioSupported,
            onChanged: !_bioSupported
                ? null
                : (v) async {
                    final bio = ref.read(biometricServiceProvider);
                    if (v) {
                      final ok = await bio.authenticate(
                        reason: 'تأیید برای فعال‌سازی قفل اثرانگشت',
                      );
                      if (!ok) return;
                    }
                    await bio.setEnabled(v);
                    setState(() => _bio = v);
                  },
          ),
        ]),
        const SizedBox(height: 18),
        const Text('اعلان‌ها',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        _card([
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(Icons.receipt_long_outlined),
            title: const Text('سفارش جدید'),
            value: _orders,
            onChanged: (v) async {
              await ref.read(secureStorageProvider).setNotifOrders(v);
              setState(() => _orders = v);
            },
          ),
          const Divider(height: 1),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(Icons.chat_bubble_outline),
            title: const Text('نظر جدید'),
            value: _comments,
            onChanged: (v) async {
              await ref.read(secureStorageProvider).setNotifComments(v);
              setState(() => _comments = v);
            },
          ),
          const Divider(height: 1),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(Icons.support_agent_outlined),
            title: const Text('تیکت پشتیبانی'),
            value: _tickets,
            onChanged: (v) async {
              await ref.read(secureStorageProvider).setNotifTickets(v);
              setState(() => _tickets = v);
            },
          ),
        ]),
        const SizedBox(height: 8),
        Text(
          'اعلان‌ها هنگام باز بودن برنامه حدود هر ۴۵ ثانیه بررسی می‌شوند.',
          style:
              TextStyle(fontSize: 11, color: AppColors.textMuted, height: 1.4),
        ),
      ],
    );
  }
}
