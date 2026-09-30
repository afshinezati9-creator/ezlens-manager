import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../data/discount_repository.dart';
import 'discount_provider.dart';

class GiftCreatePage extends ConsumerStatefulWidget {
  const GiftCreatePage({super.key});

  @override
  ConsumerState<GiftCreatePage> createState() => _GiftCreatePageState();
}

class _GiftCreatePageState extends ConsumerState<GiftCreatePage> {
  final _amountCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _recipientCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _codeCtrl.dispose();
    _recipientCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount =
        int.tryParse(_amountCtrl.text.replaceAll(RegExp(r'\D'), '')) ?? 0;
    if (amount < 1000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('حداقل مبلغ ۱٬۰۰۰ تومان')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final g = await ref.read(discountRepositoryProvider).createGift(
            amount: amount,
            code: _codeCtrl.text.trim(),
            recipientName: _recipientCtrl.text.trim(),
            message: _messageCtrl.text.trim(),
          );
      if (!mounted) return;
      ref.invalidate(giftsProvider);
      ref.invalidate(discountStatsProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('کارت صادر شد: ${g.code}'),
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
        title: const Text('صدور کارت هدیه'),
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
            controller: _amountCtrl,
            keyboardType: TextInputType.number,
            textDirection: TextDirection.ltr,
            decoration: InputDecoration(
              labelText: 'مبلغ (تومان)',
              filled: true,
              fillColor: AppColors.surface,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _codeCtrl,
            textDirection: TextDirection.ltr,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              labelText: 'کد سفارشی (اختیاری — خالی = خودکار)',
              filled: true,
              fillColor: AppColors.surface,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _recipientCtrl,
            decoration: InputDecoration(
              labelText: 'نام گیرنده (اختیاری)',
              filled: true,
              fillColor: AppColors.surface,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _messageCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'پیام روی کارت',
              filled: true,
              fillColor: AppColors.surface,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('صدور کارت هدیه'),
            ),
          ),
        ],
      ),
    );
  }
}
