import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../data/campaign_models.dart';
import '../data/campaign_repository.dart';
import 'campaign_provider.dart';

class CampaignCreatePage extends ConsumerStatefulWidget {
  final int? initialBookId;
  const CampaignCreatePage({super.key, this.initialBookId});

  @override
  ConsumerState<CampaignCreatePage> createState() => _CampaignCreatePageState();
}

class _CampaignCreatePageState extends ConsumerState<CampaignCreatePage> {
  final _nameCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _smsCtrl = TextEditingController();

  int? _bookId;
  bool _sending = false;
  String? _fileName;
  String? _fileB64;

  @override
  void initState() {
    super.initState();
    _bookId = widget.initialBookId;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _subjectCtrl.dispose();
    _emailCtrl.dispose();
    _smsCtrl.dispose();
    super.dispose();
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

  Future<void> _submit({required bool send}) async {
    if (_bookId == null || _bookId! <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('دفترچه مخاطبان را انتخاب کنید')),
      );
      return;
    }
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('عنوان کمپین را وارد کنید')),
      );
      return;
    }
    if (_emailCtrl.text.trim().isEmpty && _smsCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('محتوای ایمیل یا پیامک لازم است')),
      );
      return;
    }
    setState(() => _sending = true);
    try {
      final r = await ref.read(campaignRepositoryProvider).createAndSend(
            bookId: _bookId!,
            name: _nameCtrl.text.trim(),
            subject: _subjectCtrl.text.trim(),
            emailBody: _emailCtrl.text.trim(),
            smsBody: _smsCtrl.text.trim(),
            fileBase64: _fileB64,
            fileName: _fileName,
            send: send,
          );
      if (!mounted) return;
      ref.invalidate(campaignsProvider);
      final msg = (r['message'] ?? 'انجام شد').toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppColors.success),
      );
      context.go('/campaign');
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
    final booksAsync = ref.watch(booksProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('ایجاد کمپین'),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/campaign'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          booksAsync.when(
            loading: () => const LinearProgressIndicator(minHeight: 2),
            error: (e, _) => Text('$e'),
            data: (books) {
              return DropdownButtonFormField<int>(
                value: books.any((b) => b.id == _bookId) ? _bookId : null,
                decoration: InputDecoration(
                  labelText: 'دفترچه مخاطبان',
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                items: books
                    .map((b) => DropdownMenuItem(
                          value: b.id,
                          child: Text('${b.name} (${b.contactCount})'),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _bookId = v),
              );
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _nameCtrl,
            decoration: InputDecoration(
              labelText: 'عنوان کمپین',
              filled: true,
              fillColor: AppColors.surface,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _subjectCtrl,
            decoration: InputDecoration(
              labelText: 'موضوع ایمیل',
              filled: true,
              fillColor: AppColors.surface,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _emailCtrl,
            maxLines: 6,
            decoration: InputDecoration(
              labelText: 'محتوای ایمیل',
              alignLabelWithHint: true,
              filled: true,
              fillColor: AppColors.surface,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _smsCtrl,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: 'محتوای پیامک (متفاوت از ایمیل)',
              alignLabelWithHint: true,
              filled: true,
              fillColor: AppColors.surface,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: _pickFile,
                icon: const Icon(Icons.attach_file, size: 18),
                label: Text(_fileName ?? 'پیوست ایمیل'),
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
          const SizedBox(height: 24),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _sending ? null : () => _submit(send: true),
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
                  : const Text('ذخیره و ارسال کمپین'),
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: _sending ? null : () => _submit(send: false),
            child: const Text('فقط ذخیره به‌عنوان پیش‌نویس'),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
