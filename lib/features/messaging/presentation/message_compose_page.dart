import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../data/message_models.dart';
import '../data/message_repository.dart';
import 'message_provider.dart';

class MessageComposePage extends ConsumerStatefulWidget {
  const MessageComposePage({super.key});

  @override
  ConsumerState<MessageComposePage> createState() => _MessageComposePageState();
}

class _MessageComposePageState extends ConsumerState<MessageComposePage> {
  String _channel = 'email';
  bool _manual = false;
  bool _sending = false;

  MessageCustomer? _selected;
  List<MessageCustomer> _suggestions = [];
  bool _searching = false;

  final _searchCtrl = TextEditingController();
  final _recipientCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();

  String? _fileName;
  String? _fileB64;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _recipientCtrl.dispose();
    _nameCtrl.dispose();
    _subjectCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _searchUsers(String q) async {
    if (q.trim().length < 2) {
      setState(() => _suggestions = []);
      return;
    }
    setState(() => _searching = true);
    try {
      final list =
          await ref.read(messageRepositoryProvider).searchCustomers(q);
      if (!mounted) return;
      setState(() {
        _suggestions = list;
        _searching = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _searching = false);
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(withData: true);
    if (result == null || result.files.isEmpty) return;
    final f = result.files.first;
    if (f.bytes == null) return;
    setState(() {
      _fileName = f.name;
      _fileB64 = base64Encode(f.bytes!);
    });
  }

  Future<void> _send() async {
    final body = _bodyCtrl.text.trim();
    if (body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('متن پیام را وارد کنید')),
      );
      return;
    }
    if (!_manual && _selected == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('یک مشتری انتخاب کنید یا حالت دستی را فعال کنید')),
      );
      return;
    }
    if (_manual && _recipientCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('گیرنده را وارد کنید')),
      );
      return;
    }

    setState(() => _sending = true);
    try {
      await ref.read(messageRepositoryProvider).send(
            channel: _channel,
            body: body,
            subject: _subjectCtrl.text.trim(),
            userId: _manual ? 0 : (_selected?.id ?? 0),
            recipient: _manual
                ? _recipientCtrl.text.trim()
                : (_channel == 'sms'
                    ? (_selected?.phone ?? '')
                    : (_selected?.email ?? '')),
            recipientName: _manual
                ? _nameCtrl.text.trim()
                : (_selected?.name ?? ''),
            fileBase64: _channel == 'email' ? _fileB64 : null,
            fileName: _channel == 'email' ? _fileName : null,
          );
      if (!mounted) return;
      ref.invalidate(messageListProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('پیام ارسال شد'),
          backgroundColor: AppColors.success,
        ),
      );
      context.go('/messages');
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('ارسال پیام'),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/messages'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Channel
          const Text('نوع ارسال', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Text('ایمیل'),
                  selected: _channel == 'email',
                  onSelected: (_) => setState(() => _channel = 'email'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ChoiceChip(
                  label: const Text('پیامک'),
                  selected: _channel == 'sms',
                  onSelected: (_) => setState(() {
                    _channel = 'sms';
                    _fileB64 = null;
                    _fileName = null;
                  }),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('ورود دستی گیرنده'),
            subtitle: const Text('بدون انتخاب از لیست مشتریان'),
            value: _manual,
            activeColor: AppColors.primary,
            onChanged: (v) => setState(() {
              _manual = v;
              if (v) _selected = null;
            }),
          ),
          const SizedBox(height: 8),

          if (!_manual) ...[
            TextField(
              controller: _searchCtrl,
              onChanged: _searchUsers,
              decoration: InputDecoration(
                hintText: 'جستجوی مشتری (نام، موبایل، ایمیل)',
                prefixIcon: const Icon(Icons.person_search_outlined),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            if (_searching)
              const Padding(
                padding: EdgeInsets.all(8),
                child: LinearProgressIndicator(minHeight: 2),
              ),
            if (_suggestions.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: _suggestions.map((c) {
                    return ListTile(
                      title: Text(c.name.isEmpty ? c.login : c.name),
                      subtitle: Text(
                        _channel == 'sms'
                            ? (c.phone.isEmpty ? 'بدون موبایل' : c.phone)
                            : c.email,
                      ),
                      onTap: () {
                        setState(() {
                          _selected = c;
                          _suggestions = [];
                          _searchCtrl.text =
                              c.name.isEmpty ? c.login : c.name;
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
            if (_selected != null)
              Container(
                margin: const EdgeInsets.only(top: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.primary.withOpacity(0.25)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline,
                        color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${_selected!.name} · ${_channel == 'sms' ? _selected!.phone : _selected!.email}',
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => setState(() => _selected = null),
                    ),
                  ],
                ),
              ),
          ] else ...[
            TextField(
              controller: _recipientCtrl,
              textDirection: TextDirection.ltr,
              keyboardType: _channel == 'sms'
                  ? TextInputType.phone
                  : TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: _channel == 'sms' ? 'شماره موبایل' : 'ایمیل',
                hintText: _channel == 'sms' ? '0912xxxxxxx' : 'name@example.com',
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: 'نام گیرنده (اختیاری)',
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],

          if (_channel == 'email') ...[
            const SizedBox(height: 14),
            TextField(
              controller: _subjectCtrl,
              decoration: InputDecoration(
                labelText: 'موضوع',
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
          const SizedBox(height: 14),
          TextField(
            controller: _bodyCtrl,
            maxLines: 8,
            decoration: InputDecoration(
              labelText: 'متن پیام',
              alignLabelWithHint: true,
              filled: true,
              fillColor: AppColors.surface,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          if (_channel == 'email') ...[
            const SizedBox(height: 12),
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
          ],
          const SizedBox(height: 24),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _sending ? null : _send,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _sending
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('ارسال'),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
