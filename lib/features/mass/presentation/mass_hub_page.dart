import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../data/mass_models.dart';
import '../data/mass_repository.dart';
import 'mass_provider.dart';

String _fa(String s) {
  const en = '0123456789';
  const fa = '۰۱۲۳۴۵۶۷۸۹';
  var o = s;
  for (var i = 0; i < 10; i++) {
    o = o.replaceAll(en[i], fa[i]);
  }
  return o;
}

class MassHubPage extends ConsumerStatefulWidget {
  const MassHubPage({super.key});

  @override
  ConsumerState<MassHubPage> createState() => _MassHubPageState();
}

class _MassHubPageState extends ConsumerState<MassHubPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  // Compose state
  List<MassPreset> _presets = const [];
  String _preset = 'all_customers';
  String _channel = 'sms';
  final _subjectCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();
  final Set<int> _selectedUsers = {};
  List<MassUserHit> _searchHits = [];
  int _previewCount = 0;
  List<MassUserHit> _sample = [];
  bool _loadingPresets = true;
  bool _sending = false;
  bool _previewing = false;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _loadPresets();
  }

  @override
  void dispose() {
    _tabs.dispose();
    _subjectCtrl.dispose();
    _messageCtrl.dispose();
    _searchCtrl.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> _loadPresets() async {
    setState(() => _loadingPresets = true);
    try {
      final r = await ref.read(massRepositoryProvider).fetchPresets();
      if (!mounted) return;
      setState(() {
        _presets = r.items;
        _loadingPresets = false;
      });
      _runPreview();
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingPresets = false);
    }
  }

  Future<void> _runPreview() async {
    setState(() => _previewing = true);
    try {
      final r = await ref.read(massRepositoryProvider).preview(
            preset: _preset,
            userIds: _selectedUsers.toList(),
          );
      if (!mounted) return;
      setState(() {
        _previewCount = r.count;
        _sample = r.sample;
        _previewing = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _previewing = false);
    }
  }

  void _onSearchChanged(String q) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () async {
      if (q.trim().length < 2) {
        setState(() => _searchHits = []);
        return;
      }
      try {
        final hits =
            await ref.read(massRepositoryProvider).searchUsers(q.trim());
        if (!mounted) return;
        setState(() => _searchHits = hits);
      } catch (_) {}
    });
  }

  Future<void> _send() async {
    final msg = _messageCtrl.text.trim();
    if (msg.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('متن پیام را وارد کنید')),
      );
      return;
    }
    if (_preset == 'manual' && _selectedUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('حداقل یک کاربر انتخاب کنید')),
      );
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأیید ارسال جمعی'),
        content: Text(
          'ارسال برای حدود ${_fa('$_previewCount')} نفر از کانال '
          '${_channel == 'sms' ? 'پیامک' : _channel == 'email' ? 'ایمیل' : 'پیامک و ایمیل'}؟',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('انصراف')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('ارسال'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _sending = true);
    try {
      final res = await ref.read(massRepositoryProvider).send(
            preset: _preset,
            channel: _channel,
            message: msg,
            subject: _subjectCtrl.text.trim(),
            userIds: _selectedUsers.toList(),
          );
      if (!mounted) return;
      setState(() => _sending = false);
      ref.invalidate(massLogsProvider);
      ref.invalidate(massQueueProvider);
      final success = res['success'] ?? 0;
      final fail = res['fail'] ?? 0;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message']?.toString() ??
              'موفق: $success | ناموفق: $fail'),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 4),
        ),
      );
      _tabs.animateTo(1);
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا: $e'), backgroundColor: AppColors.danger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final logsAsync = ref.watch(massLogsProvider);
    final queueAsync = ref.watch(massQueueProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('پیام جمعی'),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/more'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadPresets();
              ref.invalidate(massLogsProvider);
              ref.invalidate(massQueueProvider);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'ارسال'),
            Tab(text: 'تاریخچه'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          // Compose
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'مخاطبان سایت',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              const SizedBox(height: 8),
              if (_loadingPresets)
                const Center(
                    child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ))
              else
                ..._presets.map((p) {
                  final selected = _preset == p.key;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      onTap: () {
                        setState(() => _preset = p.key);
                        _runPreview();
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected
                                ? AppColors.primary
                                : AppColors.border,
                            width: selected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              selected
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_off,
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.textMuted,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p.label,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600),
                                  ),
                                  Text(
                                    p.description,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (p.count > 0)
                              Text(
                                _fa('${p.count}'),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),

              if (_preset == 'manual') ...[
                const SizedBox(height: 8),
                TextField(
                  controller: _searchCtrl,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    labelText: 'جستجوی کاربر',
                    hintText: 'نام، ایمیل یا موبایل',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                if (_searchHits.isNotEmpty)
                  ..._searchHits.map((u) {
                    final on = _selectedUsers.contains(u.id);
                    return CheckboxListTile(
                      value: on,
                      dense: true,
                      title: Text(u.displayName),
                      subtitle: Text(
                        [u.phone, u.email]
                            .where((e) => e.isNotEmpty)
                            .join(' · '),
                        style: const TextStyle(fontSize: 11),
                      ),
                      onChanged: (v) {
                        setState(() {
                          if (v == true) {
                            _selectedUsers.add(u.id);
                          } else {
                            _selectedUsers.remove(u.id);
                          }
                        });
                        _runPreview();
                      },
                    );
                  }),
                if (_selectedUsers.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      '${_fa('${_selectedUsers.length}')} نفر انتخاب شده',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],

              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: AppColors.primary.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.groups_outlined,
                        color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _previewing
                            ? 'در حال شمارش…'
                            : 'تعداد مخاطب: ${_fa('$_previewCount')}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              if (_sample.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  'نمونه: ${_sample.map((e) => e.displayName).join('، ')}',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textMuted),
                ),
              ],

              const SizedBox(height: 16),
              const Text('کانال ارسال',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'sms', label: Text('پیامک')),
                  ButtonSegment(value: 'email', label: Text('ایمیل')),
                  ButtonSegment(value: 'both', label: Text('هر دو')),
                ],
                selected: {_channel},
                onSelectionChanged: (s) {
                  setState(() => _channel = s.first);
                },
              ),

              if (_channel != 'sms') ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _subjectCtrl,
                  decoration: InputDecoration(
                    labelText: 'موضوع ایمیل',
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              TextField(
                controller: _messageCtrl,
                maxLines: 6,
                decoration: InputDecoration(
                  labelText: 'متن پیام',
                  alignLabelWithHint: true,
                  hintText: 'متن کوتاه، محترمانه و شفاف…',
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _sending ? null : _send,
                  icon: _sending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.send_outlined),
                  label: Text(_sending ? 'در حال ارسال…' : 'ارسال پیام جمعی'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'برای مخاطبان خارجی (CSV) از بخش کمپین استفاده کنید.',
                style: TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
            ],
          ),

          // History
          RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(massLogsProvider);
              ref.invalidate(massQueueProvider);
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text('آخرین ارسال‌ها',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                logsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('$e'),
                  data: (items) {
                    if (items.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text('هنوز ارسالی ثبت نشده',
                              style: TextStyle(color: AppColors.textMuted)),
                        ),
                      );
                    }
                    return Column(
                      children: items.map((log) {
                        final ch = log.channel == 'sms'
                            ? 'پیامک'
                            : log.channel == 'email'
                                ? 'ایمیل'
                                : log.channel;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(ch,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700)),
                                  const Spacer(),
                                  Text(
                                    log.createdFa,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                'هدف ${_fa('${log.targetCount}')} · موفق ${_fa('${log.successCount}')} · ناموفق ${_fa('${log.failCount}')}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              if (log.preview.isNotEmpty)
                                Text(
                                  log.preview,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
                const SizedBox(height: 16),
                const Text('صف ناموفق / در انتظار',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                queueAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (items) {
                    if (items.isEmpty) {
                      return const Text('صف خالی است',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.textMuted));
                    }
                    return Column(
                      children: items.map((q) {
                        return ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text('${q.channel} · ${q.recipient}'),
                          subtitle: Text(
                            q.errorText.isEmpty ? q.status : q.errorText,
                            style: const TextStyle(fontSize: 11),
                          ),
                          trailing: Text(
                            q.createdFa,
                            style: const TextStyle(
                                fontSize: 10, color: AppColors.textMuted),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
