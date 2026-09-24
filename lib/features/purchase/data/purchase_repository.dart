import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/providers.dart';
import 'purchase_models.dart';

final purchaseRepositoryProvider = Provider<PurchaseRepository>((ref) {
  return PurchaseRepository(ref.watch(apiClientProvider));
});

class PurchaseRepository {
  final ApiClient _api;
  PurchaseRepository(this._api);

  static const _base = '/wp-json/ezlens/v1/manager/purchase';

  Future<List<PurchaseScript>> fetchList({String search = '', String status = 'all'}) async {
    final response = await _api.wpGet<Map<String, dynamic>>(
      '$_base/scripts',
      queryParameters: {
        'per_page': 50,
        if (search.trim().isNotEmpty) 'search': search.trim(),
        if (status != 'all') 'status': status,
      },
    );
    final data = response.data;
    final items = <PurchaseScript>[];
    if (data != null && data['items'] is List) {
      for (final e in data['items'] as List) {
        if (e is Map) {
          items.add(PurchaseScript.fromJson(Map<String, dynamic>.from(e)));
        }
      }
    }
    return items;
  }

  Future<PurchaseScript> fetchOne(int id) async {
    final response = await _api.wpGet<Map<String, dynamic>>('$_base/scripts/$id');
    final data = response.data;
    if (data != null && data['script'] is Map) {
      return PurchaseScript.fromJson(Map<String, dynamic>.from(data['script'] as Map));
    }
    throw Exception('اسکریپت یافت نشد');
  }

  Future<PurchaseScript> create({
    required String title,
    required String filename,
    required String code,
    String description = '',
    bool activate = false,
  }) async {
    final response = await _api.wpPost<Map<String, dynamic>>(
      '$_base/scripts',
      data: {
        'title': title,
        'filename': filename,
        'code': code,
        'description': description,
        'activate': activate,
      },
    );
    final data = response.data;
    if (data != null && data['script'] is Map) {
      return PurchaseScript.fromJson(Map<String, dynamic>.from(data['script'] as Map));
    }
    throw Exception(data != null ? (data['message'] ?? 'خطا') : 'خطا در ذخیره');
  }

  Future<PurchaseScript> update({
    required int id,
    String? title,
    String? description,
    String? code,
    bool? activate,
  }) async {
    final body = <String, dynamic>{};
    if (title != null) body['title'] = title;
    if (description != null) body['description'] = description;
    if (code != null) body['code'] = code;
    if (activate != null) body['status'] = activate ? 1 : 0;

    final response = await _api.wpPost<Map<String, dynamic>>(
      '$_base/scripts/$id',
      data: body,
    );
    final data = response.data;
    if (data != null && data['script'] is Map) {
      return PurchaseScript.fromJson(Map<String, dynamic>.from(data['script'] as Map));
    }
    throw Exception(data != null ? (data['message'] ?? 'خطا') : 'خطا در به‌روزرسانی');
  }

  Future<PurchaseScript> toggle(int id) async {
    final response = await _api.wpPost<Map<String, dynamic>>(
      '$_base/scripts/$id/toggle',
      data: {},
    );
    final data = response.data;
    if (data != null && data['script'] is Map) {
      return PurchaseScript.fromJson(Map<String, dynamic>.from(data['script'] as Map));
    }
    throw Exception(data != null ? (data['message'] ?? 'خطا') : 'خطا');
  }

  Future<void> delete(int id) async {
    await _api.wpDelete('$_base/scripts/$id');
  }

  Future<Map<String, int>> stats() async {
    final response = await _api.wpGet<Map<String, dynamic>>('$_base/stats');
    final data = response.data;
    if (data != null) {
      return {
        'total': int.tryParse('${data['total']}') ?? 0,
        'active': int.tryParse('${data['active']}') ?? 0,
        'inactive': int.tryParse('${data['inactive']}') ?? 0,
      };
    }
    return {'total': 0, 'active': 0, 'inactive': 0};
  }
}
