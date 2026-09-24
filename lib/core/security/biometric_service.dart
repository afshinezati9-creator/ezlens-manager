import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import '../storage/secure_storage_service.dart';

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();
  final SecureStorageService _storage;

  BiometricService(this._storage);

  Future<bool> isSupported() async {
    if (kIsWeb) return false;
    try {
      final can = await _auth.canCheckBiometrics;
      final supported = await _auth.isDeviceSupported();
      return can || supported;
    } catch (_) {
      return false;
    }
  }

  Future<bool> isEnabled() => _storage.isBiometricEnabled();

  Future<void> setEnabled(bool enabled) async {
    await _storage.setBiometricEnabled(enabled);
  }

  Future<bool> authenticate({
    String reason = 'ورود به EzLens Manager با اثرانگشت',
  }) async {
    if (kIsWeb) return true;
    try {
      if (!await isSupported()) return false;
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
    } catch (e) {
      debugPrint('Biometric error: $e');
      return false;
    }
  }
}
