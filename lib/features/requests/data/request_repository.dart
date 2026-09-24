import '../../../core/network/api_client.dart';
import 'request_models.dart';

/// Requests via Manager bridge → EI Form Builder tables (ei_requests).
class RequestRepository {
  final ApiClient _api;

  RequestRepository(this._api);

  static const _base = '/wp-json/ezlens/v1/manager/requests';

  Future<RequestsResponse> fetchRequests({
    int page = 1,
    int perPage = 10,
    String search = '',
    String? status,
    String? dateFrom,
    String? dateTo,
    String? formTitle,
    String? orderby,
    String? order,
  }) async {
    try {
      final params = <String, dynamic>{
        'page': page,
        'per_page': perPage,
        if (search.trim().isNotEmpty) 'search': search.trim(),
        if (status != null && status.isNotEmpty && status != 'all')
          'status': status,
        if (dateFrom != null && dateFrom.isNotEmpty) 'date_from': dateFrom,
        if (dateTo != null && dateTo.isNotEmpty) 'date_to': dateTo,
        if (formTitle != null && formTitle.isNotEmpty) 'form_title': formTitle,
        if (orderby != null && orderby.isNotEmpty) 'orderby': orderby,
        if (order != null && order.isNotEmpty) 'order': order,
      };

      final response = await _api.wpGet<Map<String, dynamic>>(
        _base,
        queryParameters: params,
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        // Ensure required fields for RequestsResponse
        final normalized = Map<String, dynamic>.from(data);
        normalized['page'] = normalized['page'] ?? page;
        normalized['per_page'] = normalized['per_page'] ?? perPage;
        if (normalized['perPage'] != null && normalized['per_page'] == null) {
          normalized['per_page'] = normalized['perPage'];
        }
        return RequestsResponse.fromJson(normalized);
      }

      throw Exception('پاسخ نامعتبر از API درخواست‌ها');
    } catch (e) {
      throw Exception('خطا در دریافت درخواست‌ها: $e');
    }
  }

  Future<RequestItem> fetchRequest(int id) async {
    try {
      final response = await _api.wpGet<dynamic>('$_base/$id');
      final data = response.data;

      if (data is Map && data['item'] is Map) {
        return RequestItem.fromJson(
            Map<String, dynamic>.from(data['item'] as Map));
      }
      if (data is Map && data['data'] is Map) {
        return RequestItem.fromJson(
            Map<String, dynamic>.from(data['data'] as Map));
      }
      if (data is Map && data.containsKey('id')) {
        return RequestItem.fromJson(Map<String, dynamic>.from(data));
      }

      throw Exception('پاسخ نامعتبر برای جزئیات درخواست');
    } catch (e) {
      throw Exception('خطا در دریافت جزئیات درخواست: $e');
    }
  }

  Future<void> updateStatus(int id, String status) async {
    try {
      await _api.wpPost<dynamic>(
        '$_base/$id/status',
        data: {'status': status},
      );
    } catch (e) {
      throw Exception('خطا در تغییر وضعیت: $e');
    }
  }

  Future<void> deleteRequest(int id) async {
    try {
      await _api.wpDelete<dynamic>('$_base/$id');
    } catch (e) {
      throw Exception('خطا در حذف درخواست: $e');
    }
  }

  Future<List<RequestNote>> fetchNotes(int id) async {
    try {
      final response = await _api.wpGet<dynamic>('$_base/$id/notes');
      final data = response.data;
      if (data is Map && data['items'] is List) {
        return (data['items'] as List)
            .whereType<Map>()
            .map((e) => RequestNote.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
      if (data is List) {
        return data
            .whereType<Map>()
            .map((e) => RequestNote.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
      return const [];
    } catch (_) {
      return const [];
    }
  }

  Future<RequestNote> addNote(int id, String text) async {
    try {
      final response = await _api.wpPost<dynamic>(
        '$_base/$id/notes',
        data: {'text': text},
      );
      final data = response.data;
      if (data is Map && data['note'] is Map) {
        return RequestNote.fromJson(
            Map<String, dynamic>.from(data['note'] as Map));
      }
      if (data is Map && data['item'] is Map) {
        return RequestNote.fromJson(
            Map<String, dynamic>.from(data['item'] as Map));
      }
      if (data is Map) {
        return RequestNote.fromJson(Map<String, dynamic>.from(data));
      }
      throw Exception('ثبت یادداشت ناموفق بود');
    } catch (e) {
      throw Exception('خطا در ثبت یادداشت: $e');
    }
  }
}
