import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/providers.dart';
import 'support_models.dart';

final supportRepositoryProvider = Provider<SupportRepository>((ref) {
  return SupportRepository(ref.watch(apiClientProvider));
});

class SupportRepository {
  final ApiClient _api;
  SupportRepository(this._api);

  static const _base = '/wp-json/ezlens/v1/manager/support/tickets';

  Future<SupportListResult> fetchTickets({
    int page = 1,
    int perPage = 20,
    String search = '',
    String status = 'all',
  }) async {
    final response = await _api.wpGet<Map<String, dynamic>>(
      _base,
      queryParameters: {
        'page': page,
        'per_page': perPage,
        'status': status,
        if (search.trim().isNotEmpty) 'search': search.trim(),
      },
    );
    final data = response.data;
    if (data is Map<String, dynamic>) {
      return SupportListResult.fromJson(data);
    }
    throw Exception('پاسخ نامعتبر');
  }

  Future<SupportTicketDetail> fetchTicket(int id) async {
    final response = await _api.wpGet<Map<String, dynamic>>('$_base/$id');
    final data = response.data;
    if (data is Map<String, dynamic>) {
      return SupportTicketDetail.fromJson(data);
    }
    throw Exception('تیکت یافت نشد');
  }

  Future<void> reply({
    required int ticketId,
    required String message,
    String status = 'replied',
    String? fileBase64,
    String? fileName,
  }) async {
    await _api.wpPost(
      '$_base/$ticketId/reply',
      data: {
        'message': message,
        'status': status,
        if (fileBase64 != null && fileBase64.isNotEmpty) 'file_base64': fileBase64,
        if (fileName != null && fileName.isNotEmpty) 'file_name': fileName,
      },
    );
  }

  Future<void> updateStatus(int ticketId, String status) async {
    await _api.wpPost(
      '$_base/$ticketId/status',
      data: {'status': status},
    );
  }

  Future<Map<String, dynamic>> notify({
    required int ticketId,
    required String channel, // email | sms | both
    String message = '',
  }) async {
    final response = await _api.wpPost<Map<String, dynamic>>(
      '$_base/$ticketId/notify',
      data: {
        'channel': channel,
        if (message.isNotEmpty) 'message': message,
      },
    );
    final data = response.data;
    if (data is Map<String, dynamic>) return data;
    return {'ok': true};
  }
}
