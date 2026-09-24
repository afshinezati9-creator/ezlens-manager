import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../data/support_models.dart';
import '../data/support_repository.dart';
import 'support_provider.dart';

String _fa(String s) {
  const en = '0123456789';
  const fa = '۰۱۲۳۴۵۶۷۸۹';
  var o = s;
  for (var i = 0; i < 10; i++) {
    o = o.replaceAll(en[i], fa[i]);
  }
  return o;
}

String _money(String v) {
  final n = double.tryParse(v) ?? 0;
  final f = n.toInt().toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );
  return '${_fa(f)} تومان';
}

class SupportDetailPage extends ConsumerStatefulWidget {
  final int ticketId;
  const SupportDetailPage({super.key, required this.ticketId});

  @override
  ConsumerState<SupportDetailPage> createState() => _SupportDetailPageState();
}

class _SupportDetailPageState extends ConsumerState<SupportDetailPage> {
  final _replyCtrl = TextEditingController();
  String _status = 'replied';
  bool _sending = false;
  String? _fileName;
  String? _fileB64;

  @override
  void dispose() {
    _replyCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(withData: true);
    if (result == null || result.files.isEmpty) return;
    final f = result.files.first;
    final bytes = f.bytes;
    if (bytes == null) return;
    setState(() {
      _fileName = f.name;
      _fileB64 = base64Encode(bytes);
    });
  }

  Future<void> _sendReply() async {
    final text = _replyCtrl.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('متن پاسخ را وارد کنید')),
      );
      return;
    }
    setState(() => _sending = true);
    try {
      await ref.read(supportRepositoryProvider).reply(
            ticketId: widget.ticketId,
            message: text,
            status: _status,
            fileBase64: _fileB64,
            fileName: _fileName,
          );
      if (!mounted) return;
      _replyCtrl.clear();
      setState(() {
        _fileB64 = null;
        _fileName = null;
        _sending = false;
      });
      ref.invalidate(supportDetailProvider(widget.ticketId));
      ref.invalidate(supportListProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('پاسخ ثبت شد'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا: $e'), backgroundColor: AppColors.danger),
      );
    }
  }

  Future<void> _changeStatus(String status) async {
    try {
      await ref
          .read(supportRepositoryProvider)
          .updateStatus(widget.ticketId, status);
      ref.invalidate(supportDetailProvider(widget.ticketId));
      ref.invalidate(supportListProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('وضعیت به‌روز شد')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا: $e')),
      );
    }
  }

  Future<void> _notify(String channel) async {
    try {
      final r = await ref.read(supportRepositoryProvider).notify(
            ticketId: widget.ticketId,
            channel: channel,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('اطلاع‌رسانی: $r')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا: $e')),
      );
    }
  }

  Future<void> _openFile(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(supportDetailProvider(widget.ticketId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('تیکت #${widget.ticketId}'),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/support'),
        ),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (d) {
          final t = d.ticket;
          final c = d.customer;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Ticket header
              _card(
                title: 'مشخصات تیکت',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.subject.isEmpty ? 'بدون موضوع' : t.subject,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    const SizedBox(height: 8),
                    _row('وضعیت', t.statusLabel),
                    _row('ایجاد', t.createdFa.isEmpty ? t.createdAt : t.createdFa),
                    _row('به‌روزرسانی',
                        t.updatedFa.isEmpty ? t.updatedAt : t.updatedFa),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final s in ['open', 'replied', 'closed'])
                          ChoiceChip(
                            label: Text(s == 'open'
                                ? 'باز'
                                : s == 'replied'
                                    ? 'پاسخ‌داده‌شده'
                                    : 'بسته'),
                            selected: t.status == s,
                            onSelected: (_) => _changeStatus(s),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Customer
              if (c != null && c.id > 0)
                _card(
                  title: 'مشتری',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _row('نام', c.displayName.isEmpty ? c.login : c.displayName),
                      _row('موبایل', c.phone.isEmpty ? '—' : _fa(c.phone)),
                      _row('ایمیل', c.email.isEmpty ? '—' : c.email),
                      _row('کیف پول', _money('${c.wallet}')),
                      _row('تعداد خرید', _fa('${c.ordersCount}')),
                      _row('جمع خرید', _money(c.totalSpent)),
                      if (c.recentOrders.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        const Text('آخرین خریدها',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        ...c.recentOrders.map((o) {
                          return ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: Text('#${o['number'] ?? o['id']}',
                                style: const TextStyle(fontSize: 13)),
                            subtitle: Text('${o['status']}',
                                style: const TextStyle(fontSize: 11)),
                            trailing: Text(_money('${o['total'] ?? 0}'),
                                style: const TextStyle(fontSize: 12)),
                            onTap: () {
                              final id = int.tryParse('${o['id']}') ?? 0;
                              if (id > 0) context.go('/orders/$id');
                            },
                          );
                        }),
                      ],
                      if (c.cart.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        const Text('سبد خرید',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        ...c.cart.map((line) {
                          return Text(
                            '${line['name'] ?? 'محصول'} × ${_fa('${line['quantity'] ?? 0}')}',
                            style: const TextStyle(fontSize: 12),
                          );
                        }),
                      ],
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => context.go('/users/${c.id}'),
                        child: const Text('پرونده کامل مشتری'),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),

              // Messages
              _card(
                title: 'گفتگو',
                child: d.messages.isEmpty
                    ? const Text('پیامی نیست',
                        style: TextStyle(color: AppColors.textMuted))
                    : Column(
                        children: d.messages.map((m) {
                          final mine = m.isAdmin;
                          return Align(
                            alignment: mine
                                ? Alignment.centerLeft
                                : Alignment.centerRight,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.of(context).size.width * 0.85,
                              ),
                              decoration: BoxDecoration(
                                color: mine
                                    ? AppColors.primary.withOpacity(0.08)
                                    : AppColors.background,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    mine ? 'پشتیبان' : 'مشتری',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  SelectableText(
                                    m.message,
                                    style: const TextStyle(fontSize: 13, height: 1.5),
                                  ),
                                  if (m.hasFile && m.fileUrl.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    TextButton.icon(
                                      onPressed: () => _openFile(m.fileUrl),
                                      icon: const Icon(Icons.attach_file, size: 16),
                                      label: const Text('مشاهده / دانلود فایل'),
                                    ),
                                  ],
                                  const SizedBox(height: 4),
                                  Text(
                                    m.createdFa.isEmpty
                                        ? m.createdAt
                                        : m.createdFa,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
              ),
              const SizedBox(height: 12),

              // Reply box
              _card(
                title: 'پاسخ',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _replyCtrl,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText: 'متن پاسخ...',
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: _pickFile,
                          icon: const Icon(Icons.attach_file, size: 18),
                          label: Text(_fileName ?? 'پیوست فایل'),
                        ),
                        if (_fileName != null)
                          IconButton(
                            onPressed: () => setState(() {
                              _fileName = null;
                              _fileB64 = null;
                            }),
                            icon: const Icon(Icons.close, size: 18),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _status,
                      decoration: const InputDecoration(
                        labelText: 'وضعیت پس از پاسخ',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'replied', child: Text('پاسخ‌داده‌شده')),
                        DropdownMenuItem(value: 'open', child: Text('باز')),
                        DropdownMenuItem(value: 'closed', child: Text('بسته')),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => _status = v);
                      },
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _sending ? null : _sendReply,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _sending
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('ارسال پاسخ'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text('اطلاع‌رسانی به مشتری',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        OutlinedButton(
                          onPressed: () => _notify('email'),
                          child: const Text('ایمیل'),
                        ),
                        OutlinedButton(
                          onPressed: () => _notify('sms'),
                          child: const Text('پیامک'),
                        ),
                        OutlinedButton(
                          onPressed: () => _notify('both'),
                          child: const Text('هر دو'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }

  Widget _card({required String title, required Widget child}) {
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
          Text(title,
              style:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _row(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(k,
                style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600)),
          ),
          Expanded(child: Text(v, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}
