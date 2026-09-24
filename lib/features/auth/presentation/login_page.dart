import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import 'auth_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _captchaController = TextEditingController();

  bool _obscurePassword = true;
  int _num1 = 0;
  int _num2 = 0;
  String? _captchaError;

  @override
  void initState() {
    super.initState();
    _generateCaptcha();
  }

  void _generateCaptcha() {
    final random = Random();
    setState(() {
      _num1 = random.nextInt(10) + 1;
      _num2 = random.nextInt(10) + 1;
      _captchaController.clear();
      _captchaError = null;
    });
  }

  Future<void> _handleLogin() async {
    // بررسی کپچا
    final answer = int.tryParse(_captchaController.text.trim());
    if (answer != _num1 + _num2) {
      setState(() {
        _captchaError = 'پاسخ کپچا اشتباه است';
      });
      _generateCaptcha();
      return;
    }

    final success = await ref.read(authProvider.notifier).login(
          username: _usernameController.text.trim(),
          password: _passwordController.text,
        );

    if (success && mounted) {
      context.go('/dashboard');
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _captchaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState.status == AuthStatus.loading;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // لوگو کوچک
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      'https://ezlens.ir/wp-content/uploads/2026/07/logo-500x500-1.webp',
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) {
                        return Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Center(
                            child: Text(
                              'Ez',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const Text(
                    'ورود به پنل مدیریت',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const Text(
                    'ایزی‌لنز منیجر',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxxl),

                  // فرم
                  AppTextField(
                    controller: _usernameController,
                    label: 'نام کاربری',
                    hint: 'نام کاربری یا ایمیل',
                    prefixIcon: const Icon(Icons.person_outline, size: 20),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppTextField(
                    controller: _passwordController,
                    label: 'رمز عبور',
                    hint: 'رمز عبور خود را وارد کنید',
                    obscureText: _obscurePassword,
                    prefixIcon: const Icon(Icons.lock_outline, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // کپچا
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          controller: _captchaController,
                          label: 'کپچا',
                          hint: '$_num1 + $_num2 = ?',
                          keyboardType: TextInputType.number,
                          errorText: _captchaError,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Padding(
                        padding: const EdgeInsets.only(top: 22),
                        child: IconButton(
                          onPressed: _generateCaptcha,
                          icon: const Icon(Icons.refresh_rounded),
                          tooltip: 'کپچای جدید',
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.surfaceHover,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // پیام خطا
                  if (authState.errorMessage != null) ...[
                    const SizedBox(height: AppSpacing.lg),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.dangerBg,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                      child: Text(
                        authState.errorMessage!,
                        style: const TextStyle(
                          color: AppColors.danger,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: AppSpacing.xxl),
                  AppButton(
                    label: 'ورود',
                    onPressed: isLoading ? null : _handleLogin,
                    isLoading: isLoading,
                    isExpanded: true,
                    size: AppButtonSize.lg,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
