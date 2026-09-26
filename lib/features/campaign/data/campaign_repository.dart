import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/providers.dart';
import 'campaign_models.dart';

final campaignRepositoryProvider = Provider<CampaignRepository>((ref) {
  return CampaignRepository(ref.watch(apiClientProvider));
});

class CampaignRepository {
  final ApiClient _api;
  CampaignRepository(this._api);

  static const _base = '/wp-json/ezlens/v1/manager/campaign';

  Future<List<ContactBook>> fetchBooks({String search = ''}) async {
    final response = await _api.wpGet<Map<String, dynamic>>(
      '$_base/books',
      queryParameters: {
        if (search.trim().isNotEmpty) 'search': search.trim(),
      },
    );
    final data = response.data;
    final items = <ContactBook>[];
    if (data != null && data['items'] is List) {
      for (final e in data['items'] as List) {
        if (e is Map) {
          items.add(ContactBook.fromJson(Map<String, dynamic>.from(e)));
        }
      }
    }
    return items;
  }

  Future<Map<String, dynamic>> fetchBook(int id) async {
    final response = await _api.wpGet<Map<String, dynamic>>('$_base/books/$id');
    final data = response.data;
    if (data is Map<String, dynamic>) return data;
    throw Exception('دفترچه یافت نشد');
  }

  Future<ContactBook> createBook({
    required String name,
    required List<ContactDraft> contacts,
    required List<int> userIds,
    String description = '',
  }) async {
    final response = await _api.wpPost<Map<String, dynamic>>(
      '$_base/books',
      data: {
        'name': name,
        'description': description,
        'contacts': contacts.map((c) => c.toJson()).toList(),
        'user_ids': userIds,
      },
    );
    final data = response.data;
    if (data != null && data['book'] is Map) {
      return ContactBook.fromJson(Map<String, dynamic>.from(data['book'] as Map));
    }
    throw Exception(data != null ? (data['message'] ?? 'خطا') : 'خطا در ذخیره دفترچه');
  }

  Future<ContactBook> updateBook(
    int id, {
    String? name,
    String? description,
    List<int>? contactIds,
  }) async {
    final response = await _api.wpPut<Map<String, dynamic>>(
      '$_base/books/$id',
      data: {
        if (name != null) 'name': name,
        if (description != null) 'description': description,
        if (contactIds != null) 'contact_ids': contactIds,
      },
    );
    final data = response.data;
    if (data != null && data['book'] is Map) {
      return ContactBook.fromJson(Map<String, dynamic>.from(data['book'] as Map));
    }
    throw Exception(data != null ? (data['message'] ?? 'خطا در ویرایش دفترچه') : 'خطا در ویرایش دفترچه');
  }

  Future<void> deleteBook(int id) async {
    await _api.wpDelete('$_base/books/$id');
  }

  Future<List<SiteCustomer>> fetchCustomers({String search = ''}) async {
    final response = await _api.wpGet<Map<String, dynamic>>(
      '$_base/customers',
      queryParameters: {
        if (search.trim().isNotEmpty) 'search': search.trim(),
        'per_page': 50,
      },
    );
    final data = response.data;
    final items = <SiteCustomer>[];
    if (data != null && data['items'] is List) {
      for (final e in data['items'] as List) {
        if (e is Map) {
          items.add(SiteCustomer.fromJson(Map<String, dynamic>.from(e)));
        }
      }
    }
    return items;
  }

  Future<List<CampaignItem>> fetchCampaigns({
    int page = 1,
    String search = '',
    String status = 'all',
  }) async {
    final response = await _api.wpGet<Map<String, dynamic>>(
      '$_base/campaigns',
      queryParameters: {
        'page': page,
        'per_page': 20,
        'status': status,
        if (search.trim().isNotEmpty) 'search': search.trim(),
      },
    );
    final data = response.data;
    final items = <CampaignItem>[];
    if (data != null && data['items'] is List) {
      for (final e in data['items'] as List) {
        if (e is Map) {
          items.add(CampaignItem.fromJson(Map<String, dynamic>.from(e)));
        }
      }
    }
    return items;
  }

  Future<Map<String, dynamic>> createAndSend({
    required int bookId,
    required String name,
    String subject = '',
    String emailBody = '',
    String smsBody = '',
    String? fileBase64,
    String? fileName,
    bool send = true,
  }) async {
    final response = await _api.wpPost<Map<String, dynamic>>(
      '$_base/campaigns',
      data: {
        'book_id': bookId,
        'name': name,
        'subject': subject,
        'email_body': emailBody,
        'sms_body': smsBody,
        'send': send,
        if (fileBase64 != null && fileBase64.isNotEmpty) 'file_base64': fileBase64,
        if (fileName != null && fileName.isNotEmpty) 'file_name': fileName,
      },
    );
    final data = response.data;
    if (data is Map<String, dynamic>) return data;
    throw Exception('خطا در ایجاد کمپین');
  }

  Future<Map<String, dynamic>> updateCampaign(
    int id, {
    String? name,
    String? subject,
    String? message,
    String? status,
    int? bookId,
  }) async {
    final response = await _api.wpPut<Map<String, dynamic>>(
      '$_base/campaigns/$id',
      data: {
        if (name != null) 'name': name,
        if (subject != null) 'subject': subject,
        if (message != null) 'message': message,
        if (status != null) 'status': status,
        if (bookId != null) 'book_id': bookId,
      },
    );
    final data = response.data;
    if (data is Map<String, dynamic>) return data;
    throw Exception('خطا در ویرایش کمپین');
  }

  Future<void> deleteCampaign(int id) async {
    await _api.wpDelete('$_base/campaigns/$id');
  }
}
