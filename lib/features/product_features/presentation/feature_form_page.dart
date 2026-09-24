import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../data/feature_models.dart';
import '../data/feature_repository.dart';
import 'features_provider.dart';
import 'widgets/unified_code_editor.dart';

class FeatureFormPage extends ConsumerStatefulWidget {
  final int? featureId;
  const FeatureFormPage({super.key, this.featureId});

  @override
  ConsumerState<FeatureFormPage> createState() => _FeatureFormPageState();
}

class _FeatureFormPageState extends ConsumerState<FeatureFormPage> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _code = '<!-- HTML -->\n<div class="ez-po-wrap" dir="rtl">\n\n</div>\n\n/**CSS**/\n/* styles */\n\n/**JS**/\n// scripts\n';
  String _status = 'active';
  bool _loading = false;
  bool _saving = false;
  String? _error;
  String? _message;

  bool get isEdit => widget.featureId != null && widget.featureId! > 0;

  @override
  void initState() {
    super.initState();
    if (isEdit) _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final item = await ref.read(productFeatureRepositoryProvider).fetchOne(widget.featureId!);
      if (!mounted) return;
      setState(() {
        _titleCtrl.text = item.title;
        _descCtrl.text = item.description;
        _code = item.code.isNotEmpty ? item.code : _code;
        _status = item.status;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      setState(() => _error = 'نام ویژگی اجباری است');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
      _message = null;
    });
    try {
      final feature = ProductFeature(
        id: widget.featureId ?? 0,
        title: title,
        description: _descCtrl.text.trim(),
        status: _status,
        code: _code,
      );
      final saved = await ref.read(productFeatureRepositoryProvider).save(feature);
      if (!mounted) return;
      setState(() {
        _saving = false;
        _message = 'ویژگی با موفقیت ذخیره شد';
      });
      ref.invalidate(featuresListProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ویژگی با موفقیت ذخیره شد'), backgroundColor: AppColors.success),
      );
      if (!isEdit && saved.id > 0) {
        context.go('/product-features/${saved.id}/edit');
      }
    } catch (e) {
      final msg = '$e';
      setState(() {
        _saving = false;
        _error = msg.contains('duplicate') || msg.contains('تکراری')
            ? 'نام ویژگی تکراری است'
            : (msg.contains('required') ? 'نام ویژگی اجباری است' : 'خطا در ارتباط با سرور');
      });
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isEdit ? 'ویرایش ویژگی' : 'افزودن ویژگی'),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/product-features'),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('ذخیره', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_error != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.dangerBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(_error!, style: const TextStyle(color: AppColors.danger)),
                  ),
                if (_message != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.successBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(_message!, style: const TextStyle(color: AppColors.success)),
                  ),
                const Text('نام ویژگی', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(
                  controller: _titleCtrl,
                  textDirection: TextDirection.rtl,
                  decoration: InputDecoration(
                    hintText: 'مثلاً نسخه عینک طبی',
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 14),
                const Text('توضیحات', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(
                  controller: _descCtrl,
                  maxLines: 3,
                  textDirection: TextDirection.rtl,
                  decoration: InputDecoration(
                    hintText: 'شرح کاربرد این ویژگی',
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 14),
                const Text('وضعیت', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'active', label: Text('فعال')),
                    ButtonSegment(value: 'inactive', label: Text('غیرفعال')),
                  ],
                  selected: {_status},
                  onSelectionChanged: (s) => setState(() => _status = s.first),
                ),
                const SizedBox(height: 18),
                Row(
                  children: const [
                    Icon(Icons.code, size: 18, color: AppColors.primary),
                    SizedBox(width: 6),
                    Text('ویرایشگر کد', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: AppColors.infoBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'پیشوند کلاس‌ها: ez- یا ezlens-\nجداکننده CSS/JS: /**CSS**/ و /**JS**/\nاز ID تکراری بین ویژگی‌ها پرهیز کنید.',
                    style: TextStyle(fontSize: 12, height: 1.5, color: AppColors.textPrimary),
                  ),
                ),
                UnifiedCodeEditor(
                  initialValue: _code,
                  onChanged: (v) => _code = v,
                  minHeight: 320,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 50,
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('ذخیره ویژگی', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
    );
  }
}
