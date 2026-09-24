import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/providers.dart';
import 'wallet_models.dart';

final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  return WalletRepository(ref.watch(apiClientProvider));
});

class WalletRepository {
  final ApiClient _api;
  WalletRepository(this._api);

  static const _base = '/wp-json/ezlens/v1/manager/wallet';

  Future<DepositListResult> fetchDeposits({
    int page = 1,
    int perPage = 20,
    String status = 'all',
    String method = 'all',
    String search = '',
  }) async {
    final response = await _api.wpGet<Map<String, dynamic>>(
      '$_base/deposits',
      queryParameters: {
        'page': page,
        'per_page': perPage,
        'status': status,
        'method': method,
        if (search.trim().isNotEmpty) 'search': search.trim(),
      },
    );
    final data = response.data;
    if (data is Map<String, dynamic>) {
      return DepositListResult.fromJson(data);
    }
    throw Exception('پاسخ نامعتبر');
  }

  Future<WalletDeposit> fetchDeposit(int id) async {
    final response = await _api.wpGet<Map<String, dynamic>>('$_base/deposits/$id');
    final data = response.data;
    if (data != null && data['deposit'] is Map) {
      return WalletDeposit.fromJson(
          Map<String, dynamic>.from(data['deposit'] as Map));
    }
    throw Exception('درخواست یافت نشد');
  }

  Future<WalletDeposit> approve(int id, {String note = ''}) async {
    final response = await _api.wpPost<Map<String, dynamic>>(
      '$_base/deposits/$id/approve',
      data: {if (note.isNotEmpty) 'admin_note': note},
    );
    final data = response.data;
    if (data != null && data['deposit'] is Map) {
      return WalletDeposit.fromJson(
          Map<String, dynamic>.from(data['deposit'] as Map));
    }
    throw Exception(data != null ? (data['message'] ?? 'خطا') : 'خطا در تأیید');
  }

  Future<WalletDeposit> reject(int id, {String note = ''}) async {
    final response = await _api.wpPost<Map<String, dynamic>>(
      '$_base/deposits/$id/reject',
      data: {if (note.isNotEmpty) 'admin_note': note},
    );
    final data = response.data;
    if (data != null && data['deposit'] is Map) {
      return WalletDeposit.fromJson(
          Map<String, dynamic>.from(data['deposit'] as Map));
    }
    throw Exception(data != null ? (data['message'] ?? 'خطا') : 'خطا در رد');
  }

  Future<Map<String, dynamic>> adjust({
    required int userId,
    required int amount,
    required String type, // credit | debit
    String note = '',
  }) async {
    final response = await _api.wpPost<Map<String, dynamic>>(
      '$_base/adjust',
      data: {
        'user_id': userId,
        'amount': amount,
        'type': type,
        if (note.isNotEmpty) 'note': note,
      },
    );
    final data = response.data;
    if (data is Map<String, dynamic>) return data;
    throw Exception('تعدیل ناموفق');
  }

  Future<Map<String, dynamic>> fetchUserWallet(int userId) async {
    final response =
        await _api.wpGet<Map<String, dynamic>>('$_base/user/$userId');
    final data = response.data;
    if (data is Map<String, dynamic>) return data;
    throw Exception('کاربر یافت نشد');
  }

  Future<Map<String, dynamic>> fetchStats() async {
    final response = await _api.wpGet<Map<String, dynamic>>('$_base/stats');
    final data = response.data;
    if (data is Map<String, dynamic>) return data;
    return {'pending_count': 0, 'approved_sum': 0};
  }

  Future<List<WalletUser>> searchUsers(String q) async {
    final response = await _api.wpGet<Map<String, dynamic>>(
      '$_base/search-users',
      queryParameters: {
        if (q.trim().isNotEmpty) 'search': q.trim(),
        'per_page': 20,
      },
    );
    final data = response.data;
    final items = <WalletUser>[];
    if (data != null && data['items'] is List) {
      for (final e in data['items'] as List) {
        if (e is Map) {
          items.add(WalletUser.fromJson(Map<String, dynamic>.from(e)));
        }
      }
    }
    return items;
  }
}
