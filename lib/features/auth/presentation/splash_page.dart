import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/api_config.dart';
import '../../../core/theme/app_colors.dart';
import 'auth_provider.dart';
import 'lock_page.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    if (ApiConfig.demoLoginEnabled) {
      await Future.delayed(const Duration(milliseconds: 250));
      if (!mounted || _navigated) return;

      _navigated = true;
      ref.read(authProvider.notifier).markBiometricUnlocked();
      await Future<void>.delayed(Duration.zero);

      if (!mounted) return;
      context.go('/dashboard');
      return;
    }

    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted || _navigated) return;

    try {
      var status = ref.read(authProvider).status;

      if (status == AuthStatus.initial) {
        await Future.delayed(const Duration(milliseconds: 600));
        if (!mounted || _navigated) return;
        status = ref.read(authProvider).status;
      }

      if (status != AuthStatus.authenticated) {
        _navigated = true;
        context.go('/login');
        return;
      }

      final bio = ref.read(biometricServiceProvider);
      if (await bio.isEnabled() && await bio.isSupported()) {
        if (!mounted || _navigated) return;
        _navigated = true;
        context.go('/lock');
        return;
      }

      ref.read(authProvider.notifier).markBiometricUnlocked();

      if (!mounted || _navigated) return;
      _navigated = true;
      context.go('/dashboard');
    } catch (_) {
      if (!mounted || _navigated) return;
      _navigated = true;
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.network(
              'https://ezlens.ir/wp-content/uploads/2026/07/logo-500x500-1.webp',
              width: 120,
              height: 120,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.remove_red_eye_outlined,
                size: 72,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'EzLens Manager',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'در حال آماده‌سازی...',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
