import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/debug/debug_log_service.dart';
import '../../../core/theme/app_colors.dart';

class DebugLogPage extends StatefulWidget {
  const DebugLogPage({super.key});

  @override
  State<DebugLogPage> createState() => _DebugLogPageState();
}

class _DebugLogPageState extends State<DebugLogPage> {
  final _log = DebugLogService.instance;
  String _text = '';
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final t = await _log.readAll();
    if (mounted) setState(() => _text = t);
  }

  Future<void> _copy() async {
    setState(() => _busy = true);
    final ok = await _log.copyToClipboard();
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'گزارش در کلیپ‌بورد کپی شد' : 'لاگی برای کپی نبود'),
        backgroundColor: ok ? AppColors.success : AppColors.danger,
      ),
    );
  }

  Future<void> _export() async {
    setState(() => _busy = true);
    try {
      final path = await _log.exportFile();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            path == null ? 'ذخیره لغو شد یا خالی بود' : 'ذخیره شد',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _clear() async {
    await _log.clear();
    await _reload();
  }

  Future<void> _sendServer() async {
    setState(() => _busy = true);
    try {
      await _log.flushRemote();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لاگ‌ها به مرکز دیباگ پلاگین ارسال شد (در صورت لاگین بودن)'),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('گزارش دیباگ'),
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
            onPressed: _busy ? null : _reload,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: _busy ? null : _copy,
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text('کپی کامل'),
                ),
                OutlinedButton.icon(
                  onPressed: _busy ? null : _export,
                  icon: const Icon(Icons.save_alt, size: 18),
                  label: const Text('ذخیره فایل'),
                ),
                FilledButton.tonalIcon(
                  onPressed: _busy ? null : _sendServer,
                  icon: const Icon(Icons.cloud_upload_outlined, size: 18),
                  label: const Text('ارسال به سرور'),
                ),
                TextButton.icon(
                  onPressed: _busy ? null : _clear,
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('پاک کردن'),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Text(
              'لاگ‌ها خودکار به «دیباگ اپ مدیران» در پلاگین ارسال می‌شوند. در صورت نیاز «ارسال به سرور» یا «کپی کامل» را بزنید. '
              'خلاصهٔ کندترین APIها بالای گزارش است.',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  _text.isEmpty ? 'هنوز لاگی ثبت نشده.' : _text,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: Color(0xFFE2E8F0),
                    height: 1.35,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
