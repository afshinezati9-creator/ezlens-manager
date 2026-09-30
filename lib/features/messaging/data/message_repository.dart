import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/providers.dart';
import 'message_models.dart';

final messageRepositoryProvider = Provider<MessageRepository>((ref) {
  return MessageRepository(ref.watch(apiClientProvider));
});

class MessageRepository {
  final ApiClient _api;
  MessageRepository(this._api);

  static const _base = '/wp-json/ezlens/v1/manager/messages';

  Future<MessageListResult> fetchList({
    int page = 1,
    int perPage = 20,
    String search = '',
    String channel = 'all',
    String from = '',
    String to = '',
  }) async {
    final response = await _api.wpGet<Map<String, dynamic>>(
      _base,
      queryParameters: {
        'page': page,
        'per_page': perPage,
        'channel': channel,
        if (search.trim().isNotEmpty) 'search': search.trim(),
        if (from.isNotEmpty) 'from': from,
        if (to.isNotEmpty) 'to': to,
      },
    );
    final data = response.data;
    if (data is Map<String, dynamic>) {
      return MessageListResult.fromJson(data);
    }
    throw Exception('پاسخ نامعتبر');
  }

  Future<void> send({
    required String channel,
    required String body,
    String recipient = '',
    String recipientName = '',
    int userId = 0,
    String subject = '',
    String? fileBase64,
    String? fileName,
  }) async {
    final response = await _api.wpPost<Map<String, dynamic>>(
      _base,
      data: {
        'channel': channel,
        'body': body,
        if (recipient.isNotEmpty) 'recipient': recipient,
        if (recipientName.isNotEmpty) 'recipient_name': recipientName,
        if (userId > 0) 'user_id': userId,
        if (subject.isNotEmpty) 'subject': subject,
        if (fileBase64 != null && fileBase64.isNotEmpty) 'file_base64': fileBase64,
        if (fileName != null && fileName.isNotEmpty) 'file_name': fileName,
      },
    );
    final data = response.data;
    if (data != null && data['ok'] == false) {
      throw Exception(data['message']?.toString() ?? 'ارسال ناموفق');
    }
  }

  Future<void> delete(int id) async {
    await _api.wpDelete('$_base/$id');
  }

  Future<List<MessageCustomer>> searchCustomers(String q) async {
    final response = await _api.wpGet<Map<String, dynamic>>(
      '$_base/customers',
      queryParameters: {
        if (q.trim().isNotEmpty) 'search': q.trim(),
        'per_page': 20,
      },
    );
    final data = response.data;
    final items = <MessageCustomer>[];
    if (data != null && data['items'] is List) {
      for (final e in data['items'] as List) {
        if (e is Map) {
          items.add(MessageCustomer.fromJson(Map<String, dynamic>.from(e)));
        }
      }
    }
    return items;
  }
}
