import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../data/charity_repository.dart';
import 'charity_provider.dart';

class CharityCaseFormPage extends ConsumerStatefulWidget {
  const CharityCaseFormPage({super.key});

  @override
  ConsumerState<CharityCaseFormPage> createState() =>
      _CharityCaseFormPageState();
}

class _CharityCaseFormPageState extends ConsumerState<CharityCaseFormPage> {
  final _titleCtrl = TextEditingController();
  final _summaryCtrl = TextEditingController();
  final _goalCtrl = TextEditingController();
  String _needType = 'glasses';
  String _status = 'open';
  bool _isPublic = true;
  bool _saving = false;

  final _needOptions = const [
    ('glasses', 'عینک طبی'),
    ('lenses', 'لنز تماسی'),
    ('surgery', 'جراحی چشم'),
    ('exam', 'معاینه و تشخیص'),
    ('medicine', 'دارو و درمان'),
    ('other', 'سایر'),
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _summaryCtrl.dispose();
    _goalCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('عنوان لازم است')),
      );
      return;
    }
    final goal =
        int.tryParse(_goalCtrl.text.replaceAll(RegExp(r'\D'), '')) ?? 0;
    setState(() => _saving = true);
    try {
      await ref.read(charityRepositoryProvider).saveCase(
            title: title,
            summary: _summaryCtrl.text.trim(),
            needType: _needType,
            goalAmount: goal,
            status: _status,
            isPublic: _isPublic,
          );
      if (!mounted) return;
      ref.invalidate(charityCasesProvider);
      ref.invalidate(charityStatsProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('مورد ذخیره شد'),
          backgroundColor: AppColors.success,
        ),
      );
      context.go('/charity');
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
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
        title: const Text('مورد جدید'),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/charity'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _titleCtrl,
            decoration: InputDecoration(
              labelText: 'عنوان',
              filled: true,
              fillColor: AppColors.surface,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _summaryCtrl,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: 'توضیح کوتاه',
              alignLabelWithHint: true,
              filled: true,
              fillColor: AppColors.surface,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _needType,
            decoration: InputDecoration(
              labelText: 'نوع نیاز',
              filled: true,
              fillColor: AppColors.surface,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            items: _needOptions
                .map((e) => DropdownMenuItem(value: e.$1, child: Text(e.$2)))
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => _needType = v);
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _goalCtrl,
            keyboardType: TextInputType.number,
            textDirection: TextDirection.ltr,
            decoration: InputDecoration(
              labelText: 'هدف مالی (تومان)',
              filled: true,
              fillColor: AppColors.surface,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _status,
            decoration: InputDecoration(
              labelText: 'وضعیت',
              filled: true,
              fillColor: AppColors.surface,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            items: const [
              DropdownMenuItem(value: 'open', child: Text('باز')),
              DropdownMenuItem(value: 'funded', child: Text('تأمین‌شده')),
              DropdownMenuItem(value: 'closed', child: Text('بسته')),
            ],
            onChanged: (v) {
              if (v != null) setState(() => _status = v);
            },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('نمایش عمومی در داشبورد مشتری'),
            value: _isPublic,
            activeColor: AppColors.primary,
            onChanged: (v) => setState(() => _isPublic = v),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('ذخیره مورد'),
            ),
          ),
        ],
      ),
    );
  }
}
