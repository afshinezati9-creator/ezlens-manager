import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  Future<void> write(String key, String? value) async {
    if (value == null || value.isEmpty) {
      await _storage.delete(key: key);
    } else {
      await _storage.write(key: key, value: value);
    }
  }

  Future<String?> read(String key) => _storage.read(key: key);

  Future<void> writeBool(String key, bool value) async {
    await _storage.write(key: key, value: value ? '1' : '0');
  }

  Future<bool> readBool(String key, {bool defaultValue = false}) async {
    final v = await _storage.read(key: key);
    if (v == null) return defaultValue;
    return v == '1' || v.toLowerCase() == 'true';
  }

  Future<void> saveAccessToken(String token) async {
    await write(AppConstants.keyAccessToken, token);
  }

  Future<String?> getAccessToken() => read(AppConstants.keyAccessToken);

  Future<void> deleteAccessToken() async {
    await _storage.delete(key: AppConstants.keyAccessToken);
  }

  Future<void> saveUserData(String json) async {
    await write(AppConstants.keyUserData, json);
  }

  Future<String?> getUserData() => read(AppConstants.keyUserData);

  Future<void> saveWpCredentials({
    required String username,
    required String appPassword,
  }) async {
    await write(AppConstants.keyWpUsername, username.trim());
    await write(AppConstants.keyWpAppPassword, appPassword);
  }

  Future<String?> getWpUsername() => read(AppConstants.keyWpUsername);
  Future<String?> getWpAppPassword() => read(AppConstants.keyWpAppPassword);

  Future<void> setBiometricEnabled(bool enabled) =>
      writeBool(AppConstants.keyBiometricEnabled, enabled);
  Future<bool> isBiometricEnabled() =>
      readBool(AppConstants.keyBiometricEnabled, defaultValue: false);

  Future<void> setNotifOrders(bool v) =>
      writeBool(AppConstants.keyNotifOrders, v);
  Future<bool> notifOrders() =>
      readBool(AppConstants.keyNotifOrders, defaultValue: true);

  Future<void> setNotifComments(bool v) =>
      writeBool(AppConstants.keyNotifComments, v);
  Future<bool> notifComments() =>
      readBool(AppConstants.keyNotifComments, defaultValue: true);

  Future<void> setNotifTickets(bool v) =>
      writeBool(AppConstants.keyNotifTickets, v);
  Future<bool> notifTickets() =>
      readBool(AppConstants.keyNotifTickets, defaultValue: true);

  Future<void> setLastOrderId(int id) =>
      write(AppConstants.keyLastOrderId, '$id');
  Future<int> getLastOrderId() async {
    final v = await read(AppConstants.keyLastOrderId);
    return int.tryParse(v ?? '') ?? 0;
  }

  Future<void> setLastCommentId(int id) =>
      write(AppConstants.keyLastCommentId, '$id');
  Future<int> getLastCommentId() async {
    final v = await read(AppConstants.keyLastCommentId);
    return int.tryParse(v ?? '') ?? 0;
  }

  Future<void> setLastTicketId(int id) =>
      write(AppConstants.keyLastTicketId, '$id');
  Future<int> getLastTicketId() async {
    final v = await read(AppConstants.keyLastTicketId);
    return int.tryParse(v ?? '') ?? 0;
  }

  /// Logout only — keeps biometric/notification preferences.
  Future<void> clearSession() async {
    await _storage.delete(key: AppConstants.keyAccessToken);
    await _storage.delete(key: AppConstants.keyUserData);
    await _storage.delete(key: AppConstants.keyWpUsername);
    await _storage.delete(key: AppConstants.keyWpAppPassword);
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  Future<bool> hasValidSession() async {
    final token = await getAccessToken();
    return token != null && token.trim().isNotEmpty;
  }
}
