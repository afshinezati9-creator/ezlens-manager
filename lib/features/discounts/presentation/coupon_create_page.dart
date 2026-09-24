import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../data/discount_repository.dart';
import 'discount_provider.dart';

class CouponCreatePage extends ConsumerStatefulWidget {
  const CouponCreatePage({super.key});

  @override
  ConsumerState<CouponCreatePage> createState() => _CouponCreatePageState();
}

class _CouponCreatePageState extends ConsumerState<CouponCreatePage> {
  final _codeCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _limitCtrl = TextEditingController();
  String _type = 'percent';
  bool _freeShipping = false;
  bool _individual = false;
  bool _saving = false;

  @override
  void dispose() {
    _codeCtrl.dispose();
    _amountCtrl.dispose();
    _descCtrl.dispose();
    _limitCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final code = _codeCtrl.text.trim();
    final amount = double.tryParse(_amountCtrl.text.trim()) ?? 0;
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('کد تخفیف را وارد کنید')),
      );
      return;
    }
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('مبلغ/درصد معتبر وارد کنید')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(discountRepositoryProvider).createCoupon(
            code: code,
            discountType: _type,
            amount: amount,
            description: _descCtrl.text.trim(),
            usageLimit: int.tryParse(_limitCtrl.text.trim()) ?? 0,
            freeShipping: _freeShipping,
            individualUse: _individual,
          );
      if (!mounted) return;
      ref.invalidate(couponsProvider);
      ref.invalidate(discountStatsProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('کد تخفیف ایجاد شد'),
          backgroundColor: AppColors.success,
        ),
      );
      context.go('/discounts');
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
        title: const Text('کد تخفیف جدید'),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/discounts'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _codeCtrl,
            textDirection: TextDirection.ltr,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              labelText: 'کد تخفیف',
              hintText: 'SUMMER20',
              filled: true,
              fillColor: AppColors.surface,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _type,
            decoration: InputDecoration(
              labelText: 'نوع تخفیف',
              filled: true,
              fillColor: AppColors.surface,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            items: const [
              DropdownMenuItem(value: 'percent', child: Text('درصدی')),
              DropdownMenuItem(value: 'fixed_cart', child: Text('مبلغ ثابت سبد')),
              DropdownMenuItem(
                  value: 'fixed_product', child: Text('مبلغ ثابت محصول')),
            ],
            onChanged: (v) {
              if (v != null) setState(() => _type = v);
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amountCtrl,
            keyboardType: TextInputType.number,
            textDirection: TextDirection.ltr,
            decoration: InputDecoration(
              labelText: _type == 'percent' ? 'درصد' : 'مبلغ (تومان)',
              filled: true,
              fillColor: AppColors.surface,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _limitCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'سقف تعداد استفاده (۰ = نامحدود)',
              filled: true,
              fillColor: AppColors.surface,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descCtrl,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'توضیح',
              filled: true,
              fillColor: AppColors.surface,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('ارسال رایگان'),
            value: _freeShipping,
            activeColor: AppColors.primary,
            onChanged: (v) => setState(() => _freeShipping = v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('استفاده انحصاری (با کد دیگر ترکیب نشود)'),
            value: _individual,
            activeColor: AppColors.primary,
            onChanged: (v) => setState(() => _individual = v),
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
                  : const Text('ایجاد کد تخفیف'),
            ),
          ),
        ],
      ),
    );
  }
}
