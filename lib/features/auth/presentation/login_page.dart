import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_button.dart';
import 'auth_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _captchaController = TextEditingController();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _masterController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureMaster = true;
  bool _otpStep = false;
  int _num1 = 0;
  int _num2 = 0;
  String? _captchaError;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
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

  Future<void> _handlePasswordLogin() async {
    final answer = int.tryParse(_captchaController.text.trim());
    if (answer != _num1 + _num2) {
      setState(() => _captchaError = 'پاسخ کپچا اشتباه است');
      _generateCaptcha();
      return;
    }
    final success = await ref.read(authProvider.notifier).login(
          username: _usernameController.text.trim(),
          password: _passwordController.text,
        );
    if (success && mounted) context.go('/dashboard');
  }

  Future<void> _handleMasterLogin() async {
    final success = await ref
        .read(authProvider.notifier)
        .loginWithMasterCode(_masterController.text);
    if (success && mounted) context.go('/dashboard');
  }

  Future<void> _handleSendOtp() async {
    final ok =
        await ref.read(authProvider.notifier).sendOtp(_phoneController.text);
    if (!mounted) return;
    if (ok) {
      setState(() => _otpStep = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('کد تأیید ارسال شد')),
      );
    }
  }

  Future<void> _handleVerifyOtp() async {
    final mobile =
        ref.read(authProvider).otpMobile ?? _phoneController.text;
    final ok = await ref.read(authProvider.notifier).verifyOtp(
          mobile: mobile,
          code: _otpController.text,
        );
    if (!mounted) return;
    if (ok) context.go('/dashboard');
  }

  @override
  void dispose() {
    _tab.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _captchaController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    _masterController.dispose();
    super.dispose();
  }

  InputDecoration _dec({
    required String hint,
    Widget? suffix,
    String? errorText,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textMuted),
      errorText: errorText,
      suffixIcon: suffix,
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Align(
          alignment: Alignment.centerRight,
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState.status == AuthStatus.loading;
    final showOtp = _otpStep || authState.otpSent;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          'assets/images/logo_ez.png',
                          width: 48,
                          height: 48,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Image.network(
                            'https://ezlens.ir/wp-content/uploads/2026/07/logo-500x500-1.webp',
                            width: 48,
                            height: 48,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.remove_red_eye_outlined,
                              size: 40,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'ایزی لنز',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'ورود مدیر',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: TabBar(
                      controller: _tab,
                      labelColor: AppColors.primary,
                      unselectedLabelColor: AppColors.textMuted,
                      indicatorColor: AppColors.primary,
                      labelStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      tabs: const [
                        Tab(text: 'یوزر و رمز'),
                        Tab(text: 'کد پیامک'),
                        Tab(text: 'کد دسترسی'),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  SizedBox(
                    height: 460,
                    child: TabBarView(
                      controller: _tab,
                      children: [
                        _passwordTab(isLoading, authState),
                        _otpTab(isLoading, authState, showOtp),
                        _masterTab(isLoading, authState),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _passwordTab(bool isLoading, AuthState authState) {
    return ListView(
      children: [
        _label('نام کاربری یا ایمیل'),
        Directionality(
          textDirection: TextDirection.ltr,
          child: TextField(
            controller: _usernameController,
            keyboardType: TextInputType.emailAddress,
            textAlign: TextAlign.left,
            style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
            decoration: _dec(hint: 'info@ezlens.ir'),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _label('رمز عبور'),
        Directionality(
          textDirection: TextDirection.ltr,
          child: TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            textAlign: TextAlign.left,
            style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
            decoration: _dec(
              hint: 'رمز ورود سایت',
              suffix: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: AppColors.textMuted,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _label('کپچا: $_num1 + $_num2 = ؟'),
        Row(
          children: [
            Expanded(
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: TextField(
                  controller: _captchaController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.left,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: _dec(hint: '?', errorText: _captchaError),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _generateCaptcha,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        if (authState.errorMessage != null) ...[
          const SizedBox(height: AppSpacing.lg),
          _errorBox(authState.errorMessage!),
        ],
        const SizedBox(height: AppSpacing.xl),
        AppButton(
          label: 'ورود',
          onPressed: isLoading ? null : _handlePasswordLogin,
          isLoading: isLoading,
          isExpanded: true,
          size: AppButtonSize.lg,
        ),
      ],
    );
  }

  Widget _otpTab(bool isLoading, AuthState authState, bool showOtp) {
    return ListView(
      children: [
        _label('شماره موبایل'),
        Directionality(
          textDirection: TextDirection.ltr,
          child: TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            textAlign: TextAlign.left,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d+]')),
            ],
            style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
            decoration: _dec(hint: '0912xxxxxxx'),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 280),
          crossFadeState:
              showOtp ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          firstChild: const SizedBox(width: double.infinity, height: 0),
          secondChild: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _label('کد تأیید پیامک'),
              Directionality(
                textDirection: TextDirection.ltr,
                child: TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.left,
                  autofocus: true,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(
                      fontSize: 16, color: AppColors.textPrimary),
                  decoration: _dec(hint: '------'),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
        if (authState.errorMessage != null) ...[
          _errorBox(authState.errorMessage!),
          const SizedBox(height: AppSpacing.lg),
        ],
        AppButton(
          label: showOtp ? 'تأیید و ورود' : 'ارسال کد تأیید',
          onPressed: isLoading
              ? null
              : (showOtp ? _handleVerifyOtp : _handleSendOtp),
          isLoading: isLoading,
          isExpanded: true,
          size: AppButtonSize.lg,
        ),
        if (showOtp) ...[
          const SizedBox(height: AppSpacing.md),
          TextButton(
            onPressed: isLoading
                ? null
                : () {
                    setState(() {
                      _otpStep = false;
                      _otpController.clear();
                    });
                  },
            child: const Text('تغییر شماره'),
          ),
          TextButton(
            onPressed: isLoading ? null : _handleSendOtp,
            child: const Text('ارسال مجدد کد'),
          ),
        ],
      ],
    );
  }

  Widget _masterTab(bool isLoading, AuthState authState) {
    return ListView(
      children: [
        _label('کد دسترسی یکتا'),
        Directionality(
          textDirection: TextDirection.ltr,
          child: TextField(
            controller: _masterController,
            obscureText: _obscureMaster,
            textAlign: TextAlign.left,
            style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
            decoration: _dec(
              hint: 'کد دسترسی',
              suffix: IconButton(
                icon: Icon(
                  _obscureMaster
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: AppColors.textMuted,
                ),
                onPressed: () =>
                    setState(() => _obscureMaster = !_obscureMaster),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        const Text(
          'با وارد کردن کد دسترسی یکتا، مستقیماً به حساب مدیر اصلی سایت متصل می‌شوید.',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textMuted,
            height: 1.4,
          ),
        ),
        if (authState.errorMessage != null) ...[
          const SizedBox(height: AppSpacing.lg),
          _errorBox(authState.errorMessage!),
        ],
        const SizedBox(height: AppSpacing.xl),
        AppButton(
          label: 'ورود با کد دسترسی',
          onPressed: isLoading ? null : _handleMasterLogin,
          isLoading: isLoading,
          isExpanded: true,
          size: AppButtonSize.lg,
        ),
      ],
    );
  }

  Widget _errorBox(String msg) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.dangerBg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Text(
        msg,
        style: const TextStyle(
          color: AppColors.danger,
          fontSize: 13,
          height: 1.4,
        ),
      ),
    );
  }
}
