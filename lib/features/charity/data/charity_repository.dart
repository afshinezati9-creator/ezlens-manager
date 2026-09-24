import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/providers.dart';
import 'charity_models.dart';

final charityRepositoryProvider = Provider<CharityRepository>((ref) {
  return CharityRepository(ref.watch(apiClientProvider));
});

class CharityRepository {
  final ApiClient _api;
  CharityRepository(this._api);

  static const _base = '/wp-json/ezlens/v1/manager/charity';

  Future<CharityStats> fetchStats() async {
    final response = await _api.wpGet<Map<String, dynamic>>('$_base/stats');
    final data = response.data;
    if (data != null && data['stats'] is Map) {
      return CharityStats.fromJson(Map<String, dynamic>.from(data['stats'] as Map));
    }
    return const CharityStats();
  }

  Future<List<CharityCase>> fetchCases({String status = 'all'}) async {
    final response = await _api.wpGet<Map<String, dynamic>>(
      '$_base/cases',
      queryParameters: {'status': status, 'per_page': 50},
    );
    final data = response.data;
    final items = <CharityCase>[];
    if (data != null && data['items'] is List) {
      for (final e in data['items'] as List) {
        if (e is Map) {
          items.add(CharityCase.fromJson(Map<String, dynamic>.from(e)));
        }
      }
    }
    return items;
  }

  Future<CharityCase> saveCase({
    int id = 0,
    required String title,
    String summary = '',
    String needType = 'glasses',
    int goalAmount = 0,
    String status = 'open',
    bool isPublic = true,
  }) async {
    final path = id > 0 ? '$_base/cases/$id' : '$_base/cases';
    final response = id > 0
        ? await _api.wpPost<Map<String, dynamic>>(path, data: {
            'title': title,
            'summary': summary,
            'need_type': needType,
            'goal_amount': goalAmount,
            'status': status,
            'is_public': isPublic,
          })
        : await _api.wpPost<Map<String, dynamic>>(path, data: {
            'title': title,
            'summary': summary,
            'need_type': needType,
            'goal_amount': goalAmount,
            'status': status,
            'is_public': isPublic,
          });
    // For update, some clients use PUT — wpPost is fine if route is EDITABLE accepting POST
    final data = response.data;
    if (data != null && data['case'] is Map) {
      return CharityCase.fromJson(Map<String, dynamic>.from(data['case'] as Map));
    }
    throw Exception(data != null ? (data['message'] ?? 'خطا') : 'خطا در ذخیره');
  }

  Future<void> deleteCase(int id) async {
    await _api.wpDelete('$_base/cases/$id');
  }

  Future<List<CharityDonation>> fetchDonations() async {
    final response = await _api.wpGet<Map<String, dynamic>>(
      '$_base/donations',
      queryParameters: {'per_page': 50},
    );
    final data = response.data;
    final items = <CharityDonation>[];
    if (data != null && data['items'] is List) {
      for (final e in data['items'] as List) {
        if (e is Map) {
          items.add(CharityDonation.fromJson(Map<String, dynamic>.from(e)));
        }
      }
    }
    return items;
  }

  Future<void> addImpact({
    required int donationId,
    int spentAmount = 0,
    String beneficiary = '',
    String purpose = '',
    String thankYou = '',
    String? fileBase64,
    String? fileName,
  }) async {
    final response = await _api.wpPost<Map<String, dynamic>>(
      '$_base/impact',
      data: {
        'donation_id': donationId,
        if (spentAmount > 0) 'spent_amount': spentAmount,
        if (beneficiary.isNotEmpty) 'beneficiary_label': beneficiary,
        if (purpose.isNotEmpty) 'purpose': purpose,
        if (thankYou.isNotEmpty) 'thank_you': thankYou,
        if (fileBase64 != null && fileBase64.isNotEmpty) 'file_base64': fileBase64,
        if (fileName != null && fileName.isNotEmpty) 'file_name': fileName,
      },
    );
    final data = response.data;
    if (data != null && data['ok'] == false) {
      throw Exception(data['message'] ?? 'خطا');
    }
  }

  Future<List<Map<String, String>>> needTypes() async {
    final response = await _api.wpGet<Map<String, dynamic>>('$_base/need-types');
    final data = response.data;
    final items = <Map<String, String>>[];
    if (data != null && data['items'] is List) {
      for (final e in data['items'] as List) {
        if (e is Map) {
          items.add({
            'key': '${e['key']}',
            'label': '${e['label']}',
          });
        }
      }
    }
    return items;
  }
}
