import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../data/inbox_models.dart';
import '../data/inbox_repository.dart';
import 'inbox_provider.dart';

class InboxDetailPage extends ConsumerStatefulWidget {
  final int uid;
  const InboxDetailPage({super.key, required this.uid});

  @override
  ConsumerState<InboxDetailPage> createState() => _InboxDetailPageState();
}

class _InboxDetailPageState extends ConsumerState<InboxDetailPage> {
  final _replyCtrl = TextEditingController();
  bool _replying = false;
  bool _sending = false;

  @override
  void dispose() {
    _replyCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendReply(InboxMessageDetail m) async {
    final body = _replyCtrl.text.trim();
    if (body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('متن پاسخ را وارد کنید')),
      );
      return;
    }
    setState(() => _sending = true);
    try {
      await ref.read(inboxRepositoryProvider).reply(
            uid: m.uid,
            to: m.from,
            subject: m.subject,
            body: body,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('پاسخ ارسال شد'),
          backgroundColor: AppColors.success,
        ),
      );
      setState(() {
        _sending = false;
        _replying = false;
        _replyCtrl.clear();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطا در ارسال: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  Future<void> _delete(InboxMessageDetail m) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف پیام'),
        content: const Text('این پیام حذف شود؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('انصراف')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(inboxRepositoryProvider).deleteMessage(m.uid);
      if (!mounted) return;
      ref.invalidate(inboxListProvider);
      context.go('/inbox');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا: $e')),
      );
    }
  }

  Future<void> _download(InboxMessageDetail m, InboxAttachment a) async {
    try {
      final path = ref.read(inboxRepositoryProvider).attachmentUrl(m.uid, a.part);
      // Prefer relative open via site origin stored in SharedPreferences / config:
      // wpGet uses full path from site; for external open we need absolute URL.
      final uri = Uri.parse(
        path.startsWith('http')
            ? path
            : 'https://ezlens.ir$path',
      );
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('باز کردن لینک ممکن نیست');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('دانلود: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncMsg = ref.watch(inboxMessageProvider(widget.uid));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('پیام'),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/inbox'),
        ),
        actions: [
          asyncMsg.maybeWhen(
            data: (m) => IconButton(
              tooltip: 'حذف',
              icon: const Icon(Icons.delete_outline, color: AppColors.danger),
              onPressed: () => _delete(m),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: asyncMsg.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$e', textAlign: TextAlign.center),
                TextButton(
                  onPressed: () =>
                      ref.invalidate(inboxMessageProvider(widget.uid)),
                  child: const Text('تلاش مجدد'),
                ),
              ],
            ),
          ),
        ),
        data: (m) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
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
                      m.subject,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _meta('از', m.fromName.isNotEmpty
                        ? '${m.fromName} <${m.from}>'
                        : m.from),
                    _meta('به', m.to.isEmpty ? '—' : m.to),
                    _meta(
                      'تاریخ',
                      m.dateFa.isNotEmpty ? m.dateFa : m.dateRaw,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: SelectableText(
                  m.bodyPreview.isEmpty ? '(بدون متن)' : m.bodyPreview,
                  style: const TextStyle(height: 1.6, fontSize: 14),
                ),
              ),
              if (m.attachments.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
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
                      const Text(
                        'پیوست‌ها',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 10),
                      ...m.attachments.map((a) {
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.attach_file,
                              color: AppColors.primary),
                          title: Text(
                            a.filename.isEmpty ? 'فایل' : a.filename,
                            style: const TextStyle(fontSize: 13),
                          ),
                          subtitle: a.mime.isNotEmpty
                              ? Text(a.mime,
                                  style: const TextStyle(fontSize: 11))
                              : null,
                          trailing: IconButton(
                            tooltip: 'دانلود',
                            icon: const Icon(Icons.download_outlined),
                            onPressed: () => _download(m, a),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              if (!_replying)
                ElevatedButton.icon(
                  onPressed: () => setState(() => _replying = true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.reply),
                  label: const Text('پاسخ'),
                )
              else ...[
                TextField(
                  controller: _replyCtrl,
                  maxLines: 6,
                  decoration: InputDecoration(
                    hintText: 'متن پاسخ...',
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _sending
                            ? null
                            : () => setState(() {
                                  _replying = false;
                                  _replyCtrl.clear();
                                }),
                        child: const Text('انصراف'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _sending ? null : () => _sendReply(m),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                        child: _sending
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('ارسال پاسخ'),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }

  Widget _meta(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 48,
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
            child: Text(v, style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
