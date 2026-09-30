import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../data/wallet_models.dart';
import '../data/wallet_repository.dart';
import 'wallet_provider.dart';

String _fa(String s) {
  const en = '0123456789';
  const fa = '۰۱۲۳۴۵۶۷۸۹';
  var o = s;
  for (var i = 0; i < 10; i++) {
    o = o.replaceAll(en[i], fa[i]);
  }
  return o;
}

String _money(int n) {
  final f = n.toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );
  return '${_fa(f)} تومان';
}

class WalletAdjustPage extends ConsumerStatefulWidget {
  const WalletAdjustPage({super.key});

  @override
  ConsumerState<WalletAdjustPage> createState() => _WalletAdjustPageState();
}

class _WalletAdjustPageState extends ConsumerState<WalletAdjustPage> {
  final _searchCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  String _type = 'credit';
  bool _saving = false;
  bool _searching = false;
  WalletUser? _selected;
  List<WalletUser> _suggestions = [];

  @override
  void dispose() {
    _searchCtrl.dispose();
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _search(String q) async {
    if (q.trim().length < 2) {
      setState(() => _suggestions = []);
      return;
    }
    setState(() => _searching = true);
    try {
      final list =
          await ref.read(walletRepositoryProvider).searchUsers(q.trim());
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

  int _parseAmount() {
    final digits = _amountCtrl.text.replaceAll(RegExp(r'[^\d۰-۹]'), '');
    const fa = '۰۱۲۳۴۵۶۷۸۹';
    var en = digits;
    for (var i = 0; i < 10; i++) {
      en = en.replaceAll(fa[i], '$i');
    }
    return int.tryParse(en) ?? 0;
  }

  Future<void> _submit() async {
    if (_selected == null || _selected!.id <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('یک مشتری انتخاب کنید')),
      );
      return;
    }
    final amount = _parseAmount();
    if (amount < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('مبلغ معتبر وارد کنید')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final r = await ref.read(walletRepositoryProvider).adjust(
            userId: _selected!.id,
            amount: amount,
            type: _type,
            note: _noteCtrl.text.trim(),
          );
      if (!mounted) return;
      ref.invalidate(walletDepositsProvider);
      final bal = int.tryParse('${r['balance']}') ?? 0;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '${r['message'] ?? 'انجام شد'} · موجودی: ${_money(bal)}'),
          backgroundColor: AppColors.success,
        ),
      );
      context.go('/wallet');
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
        title: const Text('شارژ / کسر دستی'),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/wallet'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _searchCtrl,
            onChanged: _search,
            decoration: InputDecoration(
              hintText: 'جستجوی مشتری (نام، موبایل، ایمیل)',
              prefixIcon: const Icon(Icons.person_search_outlined),
              filled: true,
              fillColor: AppColors.surface,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                children: _suggestions.map((u) {
                  return ListTile(
                    title: Text(u.title),
                    subtitle: Text(
                      '${u.phone.isNotEmpty ? u.phone : u.email} · موجودی ${_money(u.balance)}',
                    ),
                    onTap: () {
                      setState(() {
                        _selected = u;
                        _suggestions = [];
                        _searchCtrl.text = u.title;
                      });
                    },
                  );
                }).toList(),
              ),
            ),
          if (_selected != null)
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: AppColors.primary.withOpacity(0.25)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline,
                      color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${_selected!.title} · موجودی ${_money(_selected!.balance)}',
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => setState(() => _selected = null),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Text('شارژ (افزایش)'),
                  selected: _type == 'credit',
                  onSelected: (_) => setState(() => _type = 'credit'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ChoiceChip(
                  label: const Text('کسر'),
                  selected: _type == 'debit',
                  onSelected: (_) => setState(() => _type = 'debit'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
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
            controller: _noteCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'یادداشت',
              filled: true,
              fillColor: AppColors.surface,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _saving ? null : _submit,
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
                  : Text(_type == 'credit' ? 'شارژ کیف پول' : 'کسر از کیف پول'),
            ),
          ),
        ],
      ),
    );
  }
}
