import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/providers.dart';
import 'mass_models.dart';

final massRepositoryProvider = Provider<MassRepository>((ref) {
  return MassRepository(ref.watch(apiClientProvider));
});

class MassRepository {
  final ApiClient _api;
  MassRepository(this._api);

  static const _base = '/wp-json/ezlens/v1/manager/mass';

  Future<({List<MassPreset> items, Map<String, int> counts})> fetchPresets() async {
    final response = await _api.wpGet<Map<String, dynamic>>('$_base/presets');
    final data = response.data;
    final counts = <String, int>{};
    if (data != null && data['counts'] is Map) {
      (data['counts'] as Map).forEach((k, v) {
        counts['$k'] = int.tryParse('$v') ?? 0;
      });
    }
    final items = <MassPreset>[];
    if (data != null && data['items'] is List) {
      for (final e in data['items'] as List) {
        if (e is Map) {
          final key = '${e['key']}';
          items.add(MassPreset(
            key: key,
            label: '${e['label'] ?? ''}',
            description: '${e['description'] ?? ''}',
            count: counts[key] ?? 0,
          ));
        }
      }
    }
    return (items: items, counts: counts);
  }

  Future<({int count, List<int> userIds, List<MassUserHit> sample})> preview({
    required String preset,
    List<int> userIds = const [],
  }) async {
    final response = await _api.wpPost<Map<String, dynamic>>(
      '$_base/preview',
      data: {
        'preset': preset,
        if (userIds.isNotEmpty) 'user_ids': userIds,
      },
    );
    final data = response.data;
    final sample = <MassUserHit>[];
    final ids = <int>[];
    int count = 0;
    if (data != null) {
      count = int.tryParse('${data['count']}') ?? 0;
      if (data['user_ids'] is List) {
        for (final e in data['user_ids'] as List) {
          final id = int.tryParse('$e');
          if (id != null) ids.add(id);
        }
      }
      if (data['sample'] is List) {
        for (final e in data['sample'] as List) {
          if (e is Map) {
            sample.add(MassUserHit.fromJson(Map<String, dynamic>.from(e)));
          }
        }
      }
    }
    return (count: count, userIds: ids, sample: sample);
  }

  Future<Map<String, dynamic>> send({
    required String preset,
    required String channel,
    required String message,
    String subject = '',
    List<int> userIds = const [],
  }) async {
    final response = await _api.wpPost<Map<String, dynamic>>(
      '$_base/send',
      data: {
        'preset': preset,
        'channel': channel,
        'message': message,
        if (subject.isNotEmpty) 'subject': subject,
        if (userIds.isNotEmpty) 'user_ids': userIds,
      },
    );
    final data = response.data;
    if (data is Map<String, dynamic>) return data;
    return {};
  }

  Future<List<MassLogItem>> fetchLogs() async {
    final response = await _api.wpGet<Map<String, dynamic>>(
      '$_base/logs',
      queryParameters: {'limit': 25},
    );
    final data = response.data;
    final items = <MassLogItem>[];
    if (data != null && data['items'] is List) {
      for (final e in data['items'] as List) {
        if (e is Map) {
          items.add(MassLogItem.fromJson(Map<String, dynamic>.from(e)));
        }
      }
    }
    return items;
  }

  Future<List<MassQueueItem>> fetchQueue() async {
    final response = await _api.wpGet<Map<String, dynamic>>(
      '$_base/queue',
      queryParameters: {'limit': 25},
    );
    final data = response.data;
    final items = <MassQueueItem>[];
    if (data != null && data['items'] is List) {
      for (final e in data['items'] as List) {
        if (e is Map) {
          items.add(MassQueueItem.fromJson(Map<String, dynamic>.from(e)));
        }
      }
    }
    return items;
  }

  Future<List<MassUserHit>> searchUsers(String q) async {
    final response = await _api.wpGet<Map<String, dynamic>>(
      '$_base/search-users',
      queryParameters: {'q': q},
    );
    final data = response.data;
    final items = <MassUserHit>[];
    if (data != null && data['items'] is List) {
      for (final e in data['items'] as List) {
        if (e is Map) {
          items.add(MassUserHit.fromJson(Map<String, dynamic>.from(e)));
        }
      }
    }
    return items;
  }
}
