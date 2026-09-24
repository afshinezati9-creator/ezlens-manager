import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';

import '../../../core/debug/debug_log_service.dart';
import '../../../core/theme/app_colors.dart';
import 'auth_provider.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  final _log = DebugLogService.instance;
  bool _showLog = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _log.log('SPLASH: صفحه شروع برنامه ساخته شد.');
  }

  Future<void> _downloadLog() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final path = await _log.export();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            path == null
                ? 'هنوز گزارشی برای ذخیره وجود ندارد.'
                : 'گزارش ذخیره شد.',
          ),
        ),
      );
    } catch (e) {
      await _log.log('LOG EXPORT ERROR: ' + e.toString(), level: 'ERROR');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ذخیره گزارش انجام نشد.')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _clearLog() async {
    await _log.clear();
    await _log.log('LOG: گزارش توسط کاربر پاک شد.');
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final lines = _log.lines;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.network(
                        'https://ezlens.ir/wp-content/uploads/2026/07/logo-500x500-1.webp',
                        width: 110,
                        height: 110,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.remove_red_eye_outlined,
                          size: 72,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'EzLens Manager',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        auth.status == AuthStatus.initial
                            ? 'در حال آماده‌سازی...'
                            : auth.status == AuthStatus.loading
                                ? 'در حال بررسی...'
                                : 'در حال انتقال به صفحه ورود...',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 22),
                      SizedBox(
                        width: 260,
                        child: LinearProgressIndicator(
                          minHeight: 3,
                          backgroundColor: Colors.black12,
                          value: auth.status == AuthStatus.initial ? null : 1,
                        ),
                      ),
                      const SizedBox(height: 28),
                      OutlinedButton.icon(
                        onPressed: () => setState(() => _showLog = !_showLog),
                        icon: Icon(
                          _showLog ? Icons.keyboard_arrow_down : Icons.bug_report_outlined,
                        ),
                        label: Text(_showLog ? 'بستن گزارش' : 'مشاهده گزارش راه‌اندازی'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (_showLog)
              Container(
                height: MediaQuery.sizeOf(context).height * .46,
                margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF111827),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Startup / Login Log',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'ذخیره گزارش',
                            onPressed: _busy ? null : _downloadLog,
                            icon: const Icon(Icons.download_outlined, color: Colors.white),
                          ),
                          IconButton(
                            tooltip: 'پاک کردن',
                            onPressed: _busy ? null : _clearLog,
                            icon: const Icon(Icons.delete_outline, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: Colors.white24),
                    Expanded(
                      child: lines.isEmpty
                          ? const Center(
                              child: Text(
                                'در حال ثبت گزارش...',
                                style: TextStyle(color: Colors.white70),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(12),
                              itemCount: lines.length,
                              itemBuilder: (context, index) {
                                final line = lines[index];
                                final isError = line.contains('[ERROR]');
                                final isSuccess = line.contains('[SUCCESS]');
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Text(
                                    line,
                                    textDirection: TextDirection.ltr,
                                    style: TextStyle(
                                      color: isError
                                          ? Colors.redAccent
                                          : isSuccess
                                              ? Colors.greenAccent
                                              : Colors.white70,
                                      fontSize: 11,
                                      height: 1.35,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
