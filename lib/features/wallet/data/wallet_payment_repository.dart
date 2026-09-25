import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/providers.dart';
import 'wallet_payment_models.dart';

final walletPaymentSettingsRepositoryProvider =
    Provider<WalletPaymentSettingsRepository>((ref) {
  return WalletPaymentSettingsRepository(ref.watch(apiClientProvider));
});

class WalletPaymentSettingsRepository {
  final ApiClient _api;

  WalletPaymentSettingsRepository(this._api);

  static const _endpoint = '/wp-json/ezlens/v1/manager/wallet/settings';

  Future<WalletPaymentSettings> fetch() async {
    final response = await _api.wpGet<Map<String, dynamic>>(_endpoint);
    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw Exception('پاسخ تنظیمات کیف پول نامعتبر است');
    }
    return WalletPaymentSettings.fromJson(data);
  }
}
