import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../core/network/api_client.dart';
import '../storage/secure_storage_service.dart';
import 'notification_service.dart';

class NotificationPoller {
  NotificationPoller(this._api, this._storage);
  final ApiClient _api;
  final SecureStorageService _storage;
  Timer? _timer;
  bool _running = false;

  void start({Duration interval = const Duration(seconds: 45)}) {
    stop();
    _tick();
    _timer = Timer.periodic(interval, (_) => _tick());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _tick() async {
    if (_running) return;
    _running = true;
    try {
      if (!await _storage.hasValidSession()) return;
      if (await _storage.notifOrders()) await _checkOrders();
      if (await _storage.notifComments()) await _checkComments();
      if (await _storage.notifTickets()) await _checkTickets();
    } catch (e) {
      debugPrint('NotificationPoller: $e');
    } finally {
      _running = false;
    }
  }

  Future<void> _checkOrders() async {
    try {
      final res = await _api.wcGet<List<dynamic>>(
        '/wp-json/wc/v3/orders',
        queryParameters: {
          'per_page': 5,
          'orderby': 'date',
          'order': 'desc',
          'status': 'any',
        },
      );
      final list = res.data;
      if (list is! List || list.isEmpty) return;
      final last = await _storage.getLastOrderId();
      var maxId = last;
      for (final e in list) {
        if (e is! Map) continue;
        final id = int.tryParse('${e['id']}') ?? 0;
        if (id <= 0) continue;
        if (id > maxId) maxId = id;
        if (last > 0 && id > last) {
          await NotificationService.instance.show(
            id: 100000 + id,
            title: 'سفارش جدید #${e['number'] ?? id}',
            body: 'وضعیت: ${e['status'] ?? ''} · مبلغ: ${e['total'] ?? ''}',
            payload: 'order:$id',
          );
        }
      }
      if (maxId > last) await _storage.setLastOrderId(maxId);
      if (last == 0 && maxId > 0) await _storage.setLastOrderId(maxId);
    } catch (e) {
      debugPrint('poll orders: $e');
    }
  }

  Future<void> _checkComments() async {
    try {
      final res = await _api.wpGet<List<dynamic>>(
        '/wp-json/wp/v2/comments',
        queryParameters: {
          'per_page': 5,
          'orderby': 'date',
          'order': 'desc',
        },
      );
      final list = res.data;
      if (list is! List || list.isEmpty) return;
      final last = await _storage.getLastCommentId();
      var maxId = last;
      for (final e in list) {
        if (e is! Map) continue;
        final id = int.tryParse('${e['id']}') ?? 0;
        if (id <= 0) continue;
        if (id > maxId) maxId = id;
        if (last > 0 && id > last) {
          final author = '${e['author_name'] ?? 'کاربر'}';
          var excerpt = '';
          final content = e['content'];
          if (content is Map) {
            excerpt = '${content['rendered'] ?? ''}';
          }
          excerpt = excerpt
              .replaceAll(RegExp(r'<[^>]*>'), ' ')
              .replaceAll(RegExp(r'\s+'), ' ')
              .trim();
          if (excerpt.length > 80) excerpt = '${excerpt.substring(0, 80)}…';
          await NotificationService.instance.show(
            id: 200000 + id,
            title: 'نظر جدید از $author',
            body: excerpt.isEmpty ? 'یک نظر جدید ثبت شد' : excerpt,
            payload: 'comment:$id',
          );
        }
      }
      if (maxId > last) await _storage.setLastCommentId(maxId);
      if (last == 0 && maxId > 0) await _storage.setLastCommentId(maxId);
    } catch (e) {
      debugPrint('poll comments: $e');
    }
  }

  Future<void> _checkTickets() async {
    try {
      final res = await _api.wpGet<Map<String, dynamic>>(
        '/wp-json/ezlens/v1/manager/support/tickets',
        queryParameters: {'page': 1, 'per_page': 5, 'status': 'all'},
      );
      final data = res.data;
      List items = const [];
      if (data is Map && data['items'] is List) {
        items = data['items'] as List;
      }
      final last = await _storage.getLastTicketId();
      var maxId = last;
      for (final e in items) {
        if (e is! Map) continue;
        final id = int.tryParse('${e['id'] ?? e['ticket_id']}') ?? 0;
        if (id <= 0) continue;
        if (id > maxId) maxId = id;
        if (last > 0 && id > last) {
          final subject = '${e['subject'] ?? e['title'] ?? 'تیکت پشتیبانی'}';
          await NotificationService.instance.show(
            id: 300000 + id,
            title: 'تیکت جدید',
            body: subject,
            payload: 'ticket:$id',
          );
        }
      }
      if (maxId > last) await _storage.setLastTicketId(maxId);
      if (last == 0 && maxId > 0) await _storage.setLastTicketId(maxId);
    } catch (e) {
      debugPrint('poll tickets: $e');
    }
  }
}
