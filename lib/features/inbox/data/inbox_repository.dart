import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/providers.dart';
import 'inbox_models.dart';

final inboxRepositoryProvider = Provider<InboxRepository>((ref) {
  return InboxRepository(ref.watch(apiClientProvider));
});

class InboxRepository {
  final ApiClient _api;
  InboxRepository(this._api);

  static const _base = '/wp-json/ezlens/v1/manager/inbox';

  Future<InboxListResult> fetchList({
    int page = 1,
    int perPage = 20,
    String search = '',
    String filter = 'all',
    String folder = 'inbox',
  }) async {
    final response = await _api.wpGet<Map<String, dynamic>>(
      _base,
      queryParameters: {
        'page': page,
        'per_page': perPage,
        'folder': folder,
        'filter': filter,
        if (search.trim().isNotEmpty) 'search': search.trim(),
      },
    );
    final data = response.data;
    if (data is Map<String, dynamic>) {
      if (data['ok'] == false) {
        throw Exception(data['message']?.toString() ?? 'خطا در صندوق');
      }
      return InboxListResult.fromJson(data);
    }
    throw Exception('پاسخ نامعتبر');
  }

  Future<InboxMessageDetail> fetchMessage(int uid, {String folder = 'inbox'}) async {
    final response = await _api.wpGet<Map<String, dynamic>>(
      '$_base/$uid',
      queryParameters: {'folder': folder},
    );
    final data = response.data;
    if (data is Map<String, dynamic>) {
      if (data['ok'] == false) {
        throw Exception(data['message']?.toString() ?? 'پیام یافت نشد');
      }
      return InboxMessageDetail.fromJson(data);
    }
    throw Exception('پاسخ نامعتبر');
  }

  Future<void> deleteMessage(int uid, {String folder = 'inbox'}) async {
    await _api.wpDelete(
      '$_base/$uid',
      queryParameters: {'folder': folder},
    );
  }

  Future<void> reply({
    required int uid,
    required String to,
    required String subject,
    required String body,
  }) async {
    final response = await _api.wpPost<Map<String, dynamic>>(
      '$_base/$uid/reply',
      data: {
        'to': to,
        'subject': subject,
        'body': body,
      },
    );
    final data = response.data;
    if (data != null && data['ok'] == false) {
      throw Exception(data['message']?.toString() ?? 'ارسال ناموفق');
    }
  }

  /// Absolute URL for attachment download (opens in browser / external).
  String attachmentUrl(int uid, String part, {String folder = 'inbox'}) {
    // Consumer must prepend site base; ApiClient holds baseUrl.
    return '$_base/$uid/attachment/$part?folder=$folder';
  }
}
