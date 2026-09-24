import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../data/user_repository.dart';
import 'users_provider.dart';

class UserFormPage extends ConsumerStatefulWidget {
  final int? userId;
  const UserFormPage({super.key, this.userId});

  @override
  ConsumerState<UserFormPage> createState() => _UserFormPageState();
}

class _UserFormPageState extends ConsumerState<UserFormPage> {
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _firstCtrl = TextEditingController();
  final _lastCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  bool _saving = false;
  bool _obscure = true;
  String? _error;

  bool get isEdit => widget.userId != null && widget.userId! > 0;

  @override
  void initState() {
    super.initState();
    if (isEdit) _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final u =
          await ref.read(userRepositoryProvider).fetchUser(widget.userId!);
      if (!mounted) return;
      _phoneCtrl.text = u.primaryPhone;
      _emailCtrl.text = u.email;
      _firstCtrl.text = u.firstName;
      _lastCtrl.text = u.lastName;
      setState(() => _loading = false);
    } catch (e) {
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    final phone = _phoneCtrl.text.trim();
    if (!isEdit) {
      final digits = phone.replaceAll(RegExp(r'\D'), '');
      final norm = (digits.startsWith('9') && digits.length == 10)
          ? '0$digits'
          : digits;
      if (!RegExp(r'^09\d{9}$').hasMatch(norm)) {
        setState(() => _error = 'شماره موبایل معتبر وارد کنید (09xxxxxxxxx)');
        return;
      }
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final repo = ref.read(userRepositoryProvider);
      if (isEdit) {
        await repo.updateUser(
          widget.userId!,
          email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
          firstName: _firstCtrl.text.trim(),
          lastName: _lastCtrl.text.trim(),
          phone: phone.isEmpty ? null : phone,
          password: _passCtrl.text.trim().isEmpty ? null : _passCtrl.text.trim(),
        );
      } else {
        final created = await repo.createUser(
          phone: phone,
          email: _emailCtrl.text.trim(),
          firstName: _firstCtrl.text.trim(),
          lastName: _lastCtrl.text.trim(),
          password: _passCtrl.text.trim(),
        );
        if (!mounted) return;
        ref.invalidate(usersListProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('مشتری با موفقیت ایجاد شد'),
            backgroundColor: AppColors.success,
          ),
        );
        context.go('/users/${created.id}');
        return;
      }
      if (!mounted) return;
      ref.invalidate(usersListProvider);
      ref.invalidate(userDetailProvider(widget.userId!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ذخیره شد'),
          backgroundColor: AppColors.success,
        ),
      );
      context.go('/users/${widget.userId}');
    } catch (e) {
      setState(() {
        _saving = false;
        _error = e.toString().contains('username')
            ? 'این شماره قبلاً ثبت شده است'
            : 'خطا در ذخیره: $e';
      });
    }
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _firstCtrl.dispose();
    _lastCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isEdit ? 'ویرایش مشتری' : 'افزودن مشتری'),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(isEdit ? '/users/${widget.userId}' : '/users'),
        ),
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
                    child: Text(_error!,
                        style: const TextStyle(color: AppColors.danger)),
                  ),
                _field('نام', _firstCtrl),
                _field('نام خانوادگی', _lastCtrl),
                _field(
                  'موبایل (نام کاربری)',
                  _phoneCtrl,
                  enabled: !isEdit,
                  hint: '0912xxxxxxx',
                  ltr: true,
                  keyboard: TextInputType.phone,
                ),
                if (isEdit)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Text(
                      'نام کاربری (موبایل) قابل تغییر نیست.',
                      style: TextStyle(
                          fontSize: 11, color: AppColors.textMuted),
                    ),
                  ),
                _field('ایمیل', _emailCtrl,
                    ltr: true, keyboard: TextInputType.emailAddress),
                const SizedBox(height: 4),
                Text(
                  isEdit ? 'رمز عبور جدید (اختیاری)' : 'رمز عبور (اختیاری)',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _passCtrl,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    hintText: isEdit
                        ? 'خالی بگذارید اگر نمی‌خواهید عوض شود'
                        : 'در صورت خالی بودن فقط ورود با OTP',
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    suffixIcon: IconButton(
                      icon: Icon(
                          _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                      onPressed: () =>
                          setState(() => _obscure = !_obscure),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
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
                        : Text(isEdit ? 'ذخیره تغییرات' : 'ایجاد مشتری'),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _field(
    String label,
    TextEditingController c, {
    bool enabled = true,
    String? hint,
    bool ltr = false,
    TextInputType? keyboard,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          TextField(
            controller: c,
            enabled: enabled,
            keyboardType: keyboard,
            textDirection: ltr ? TextDirection.ltr : TextDirection.rtl,
            decoration: InputDecoration(
              hintText: hint,
              filled: true,
              fillColor: enabled ? AppColors.surface : AppColors.background,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}
