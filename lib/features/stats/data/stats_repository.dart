import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/providers.dart';
import 'stats_models.dart';

final statsRepositoryProvider = Provider<StatsRepository>((ref) {
  return StatsRepository(ref.watch(apiClientProvider));
});

class StatsRepository {
  final ApiClient _api;
  StatsRepository(this._api);

  static const _base = '/wp-json/ezlens/v1/manager/stats';

  Future<StatsSnapshot> fetch({String period = 'week'}) async {
    final response = await _api.wpGet<Map<String, dynamic>>(
      _base,
      queryParameters: {'period': period},
    );
    final data = response.data;
    if (data is Map<String, dynamic>) {
      return StatsSnapshot.fromJson(data);
    }
    return const StatsSnapshot();
  }

  Future<List<TopProduct>> topProducts({String by = 'views', int limit = 8}) async {
    final response = await _api.wpGet<Map<String, dynamic>>(
      '$_base/top-products',
      queryParameters: {'by': by, 'limit': limit},
    );
    final data = response.data;
    final items = <TopProduct>[];
    if (data != null && data['items'] is List) {
      for (final e in data['items'] as List) {
        if (e is Map) {
          items.add(TopProduct.fromJson(Map<String, dynamic>.from(e)));
        }
      }
    }
    return items;
  }

  /// Latest products with view counts (newest first; views from meta/score).
  Future<List<TopContentItem>> latestProductsWithViews({int limit = 6}) async {
    // Prefer manager top-products by views
    try {
      final tops = await topProducts(by: 'views', limit: limit);
      if (tops.isNotEmpty) {
        return tops.map(TopContentItem.fromTopProduct).toList();
      }
    } catch (_) {}

    // Fallback: WC products ordered by date
    try {
      final res = await _api.wcGet<List<dynamic>>(
        '/wp-json/wc/v3/products',
        queryParameters: {
          'per_page': limit,
          'orderby': 'date',
          'order': 'desc',
          'status': 'publish',
        },
      );
      final list = res.data;
      final out = <TopContentItem>[];
      if (list is List) {
        for (final e in list) {
          if (e is! Map) continue;
          final m = Map<String, dynamic>.from(e);
          String image = '';
          if (m['images'] is List && (m['images'] as List).isNotEmpty) {
            final img0 = (m['images'] as List).first;
            if (img0 is Map) image = '${img0['src'] ?? ''}';
          }
          int views = 0;
          if (m['meta_data'] is List) {
            for (final meta in m['meta_data'] as List) {
              if (meta is Map &&
                  (meta['key'] == 'post_views_count' || meta['key'] == 'views')) {
                views = int.tryParse('${meta['value']}') ?? 0;
              }
            }
          }
          out.add(TopContentItem(
            id: int.tryParse('${m['id']}') ?? 0,
            title: '${m['name'] ?? ''}',
            views: views,
            image: image,
            type: 'product',
            date: DateTime.tryParse('${m['date_created'] ?? ''}'),
          ));
        }
      }
      return out;
    } catch (_) {
      return const [];
    }
  }

  /// Latest posts/articles with view counts.
  Future<List<TopContentItem>> latestPostsWithViews({int limit = 6}) async {
    try {
      final res = await _api.wpGet<List<dynamic>>(
        '/wp-json/wp/v2/posts',
        queryParameters: {
          'per_page': limit,
          'orderby': 'date',
          'order': 'desc',
          'status': 'publish',
          '_embed': '1',
        },
      );
      final list = res.data;
      final out = <TopContentItem>[];
      if (list is List) {
        for (final e in list) {
          if (e is! Map) continue;
          final m = Map<String, dynamic>.from(e);
          String title = '';
          final t = m['title'];
          if (t is Map) {
            title = '${t['rendered'] ?? ''}'.replaceAll(RegExp(r'<[^>]*>'), '');
          } else {
            title = '${t ?? ''}';
          }
          String image = '';
          final emb = m['_embedded'];
          if (emb is Map && emb['wp:featuredmedia'] is List) {
            final media = emb['wp:featuredmedia'] as List;
            if (media.isNotEmpty && media.first is Map) {
              image = '${(media.first as Map)['source_url'] ?? ''}';
            }
          }
          int views = 0;
          // common keys from EzLens view counter / Rank Math / custom
          if (m['post_views_count'] != null) {
            views = int.tryParse('${m['post_views_count']}') ?? 0;
          }
          if (views == 0 && m['meta'] is Map) {
            final meta = m['meta'] as Map;
            views = int.tryParse(
                    '${meta['post_views_count'] ?? meta['views'] ?? 0}') ??
                0;
          }
          if (views == 0 && m['yoast_head_json'] is Map) {
            // no reliable views here
          }
          out.add(TopContentItem(
            id: int.tryParse('${m['id']}') ?? 0,
            title: title,
            views: views,
            image: image,
            type: 'post',
            date: DateTime.tryParse('${m['date'] ?? ''}'),
          ));
        }
      }
      return out;
    } catch (_) {
      return const [];
    }
  }
}
