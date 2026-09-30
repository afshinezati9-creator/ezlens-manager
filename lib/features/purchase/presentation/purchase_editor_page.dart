import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../product_features/presentation/widgets/unified_code_editor.dart';
import '../data/purchase_repository.dart';
import 'purchase_provider.dart';

class PurchaseEditorPage extends ConsumerStatefulWidget {
  final int? scriptId; // null = new

  const PurchaseEditorPage({super.key, this.scriptId});

  @override
  ConsumerState<PurchaseEditorPage> createState() =>
      _PurchaseEditorPageState();
}

class _PurchaseEditorPageState extends ConsumerState<PurchaseEditorPage> {
  final _titleCtrl = TextEditingController();
  final _filenameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _code = _defaultCode;
  bool _activate = false;
  bool _loading = false;
  bool _saving = false;
  bool _filenameLocked = false;
  int _editorKey = 0; // force rebuild UnifiedCodeEditor after load

  bool get isEdit => widget.scriptId != null && widget.scriptId! > 0;

  static const _defaultCode = r"""<?php
if ( ! defined( 'ABSPATH' ) ) {
    exit;
}

if ( ! function_exists( 'ezp_my_feature' ) ) {
    function ezp_my_feature() {
        // your logic
    }
}

// add_action( 'init', 'ezp_my_feature' );
""";

  @override
  void initState() {
    super.initState();
    if (isEdit) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final s =
          await ref.read(purchaseRepositoryProvider).fetchOne(widget.scriptId!);
      if (!mounted) return;
      _titleCtrl.text = s.title;
      _filenameCtrl.text = s.filename
          .replaceAll(RegExp(r'\.php$', caseSensitive: false), '');
      _descCtrl.text = s.description;
      if (s.code.isNotEmpty) {
        _code = s.code;
      }
      _activate = s.active;
      _filenameLocked = true;
      _editorKey++;
      setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا: $e'), backgroundColor: AppColors.danger),
      );
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _filenameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    // Keep pure PHP: if user pasted CSS/JS markers by mistake, strip to first segment
    final parts = UnifiedCodeEditor.split(_code);
    final code = (parts[0].trim().isNotEmpty ? parts[0] : _code).trim();
    final filename = _filenameCtrl.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('عنوان الزامی است')),
      );
      return;
    }
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('کد اسکریپت خالی است')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final repo = ref.read(purchaseRepositoryProvider);
      if (isEdit) {
        await repo.update(
          id: widget.scriptId!,
          title: title,
          description: _descCtrl.text.trim(),
          code: code,
          activate: _activate,
        );
      } else {
        final fn = filename.isEmpty
            ? title.replaceAll(RegExp(r'[^a-zA-Z0-9_-]+'), '_').toLowerCase()
            : filename;
        await repo.create(
          title: title,
          filename: fn,
          description: _descCtrl.text.trim(),
          code: code,
          activate: _activate,
        );
      }
      if (!mounted) return;
      ref.invalidate(purchaseListProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ذخیره شد')),
      );
      context.go('/purchase');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا: $e'), backgroundColor: AppColors.danger),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isEdit ? 'ویرایش اسکریپت' : 'اسکریپت جدید'),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/purchase'),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextField(
                  controller: _titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'عنوان',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _filenameCtrl,
                  enabled: !_filenameLocked,
                  textDirection: TextDirection.ltr,
                  decoration: InputDecoration(
                    labelText: 'نام فایل (بدون .php)',
                    border: const OutlineInputBorder(),
                    helperText: _filenameLocked
                        ? 'نام فایل پس از ایجاد قابل تغییر نیست'
                        : null,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _descCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'توضیح',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('فعال پس از ذخیره'),
                  value: _activate,
                  activeColor: AppColors.primary,
                  onChanged: (v) => setState(() => _activate = v),
                ),
                const SizedBox(height: 8),
                const Text(
                  'کد PHP',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
                const SizedBox(height: 8),
                // Same editor as articles / product options (dark, LTR, copy/clear/test)
                UnifiedCodeEditor(
                  key: ValueKey('purchase-editor-$_editorKey'),
                  initialValue: _code,
                  minHeight: 420,
                  hint: '<?php ...',
                  onChanged: (v) => _code = v,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'قوانین: پیشوند تابع ezp_ · function_exists · یک مسئولیت در هر فایل · قبل از فعال‌سازی تست کنید',
                    style: TextStyle(fontSize: 11, height: 1.5),
                  ),
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
                    child: Text(_saving ? 'در حال ذخیره…' : 'ذخیره اسکریپت'),
                  ),
                ),
              ],
            ),
    );
  }
}
