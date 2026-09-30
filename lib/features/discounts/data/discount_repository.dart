import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/providers.dart';
import 'discount_models.dart';

final discountRepositoryProvider = Provider<DiscountRepository>((ref) {
  return DiscountRepository(ref.watch(apiClientProvider));
});

class DiscountRepository {
  final ApiClient _api;
  DiscountRepository(this._api);

  static const _base = '/wp-json/ezlens/v1/manager/discounts';

  Future<List<DiscountCoupon>> fetchCoupons({String search = '', int page = 1}) async {
    final response = await _api.wpGet<Map<String, dynamic>>(
      '$_base/coupons',
      queryParameters: {
        'page': page,
        'per_page': 30,
        if (search.trim().isNotEmpty) 'search': search.trim(),
      },
    );
    final data = response.data;
    final items = <DiscountCoupon>[];
    if (data != null && data['items'] is List) {
      for (final e in data['items'] as List) {
        if (e is Map) {
          items.add(DiscountCoupon.fromJson(Map<String, dynamic>.from(e)));
        }
      }
    }
    return items;
  }

  Future<DiscountCoupon> createCoupon({
    required String code,
    required String discountType,
    required double amount,
    String description = '',
    int usageLimit = 0,
    String dateExpires = '',
    bool freeShipping = false,
    bool individualUse = false,
  }) async {
    final response = await _api.wpPost<Map<String, dynamic>>(
      '$_base/coupons',
      data: {
        'code': code,
        'discount_type': discountType,
        'amount': amount,
        if (description.isNotEmpty) 'description': description,
        if (usageLimit > 0) 'usage_limit': usageLimit,
        if (dateExpires.isNotEmpty) 'date_expires': dateExpires,
        if (freeShipping) 'free_shipping': true,
        if (individualUse) 'individual_use': true,
      },
    );
    final data = response.data;
    if (data != null && data['coupon'] is Map) {
      return DiscountCoupon.fromJson(Map<String, dynamic>.from(data['coupon'] as Map));
    }
    throw Exception(data != null ? (data['message'] ?? 'خطا') : 'خطا در ایجاد');
  }

  Future<void> deleteCoupon(int id) async {
    await _api.wpDelete('$_base/coupons/$id');
  }

  Future<List<GiftCardItem>> fetchGifts({String status = 'all', String search = '', int page = 1}) async {
    final response = await _api.wpGet<Map<String, dynamic>>(
      '$_base/gifts',
      queryParameters: {
        'page': page,
        'per_page': 30,
        'status': status,
        if (search.trim().isNotEmpty) 'search': search.trim(),
      },
    );
    final data = response.data;
    final items = <GiftCardItem>[];
    if (data != null && data['items'] is List) {
      for (final e in data['items'] as List) {
        if (e is Map) {
          items.add(GiftCardItem.fromJson(Map<String, dynamic>.from(e)));
        }
      }
    }
    return items;
  }

  Future<GiftCardItem> createGift({
    required int amount,
    String code = '',
    String recipientName = '',
    String message = '',
  }) async {
    final response = await _api.wpPost<Map<String, dynamic>>(
      '$_base/gifts',
      data: {
        'amount': amount,
        if (code.isNotEmpty) 'code': code,
        if (recipientName.isNotEmpty) 'recipient_name': recipientName,
        if (message.isNotEmpty) 'message': message,
      },
    );
    final data = response.data;
    if (data != null && data['gift'] is Map) {
      return GiftCardItem.fromJson(Map<String, dynamic>.from(data['gift'] as Map));
    }
    throw Exception(data != null ? (data['message'] ?? 'خطا') : 'خطا در صدور');
  }

  Future<void> cancelGift(int id) async {
    await _api.wpPost('$_base/gifts/$id/cancel', data: {});
  }

  Future<Map<String, dynamic>> fetchStats() async {
    final response = await _api.wpGet<Map<String, dynamic>>('$_base/stats');
    final data = response.data;
    if (data is Map<String, dynamic>) return data;
    return {};
  }
}
