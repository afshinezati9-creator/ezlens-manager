import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/secure_storage_service.dart';
import '../storage/local_storage_service.dart';
import 'api_client.dart';

/// Provider برای SecureStorage
final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

/// Provider برای LocalStorage (باید بعد از initialize شدن استفاده شود)
final localStorageProvider = Provider<LocalStorageService>((ref) {
  throw UnimplementedError(
    'LocalStorageService باید در main.dart با override مقداردهی شود',
  );
});

/// Provider برای ApiClient
final apiClientProvider = Provider<ApiClient>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return ApiClient(storage);
});
