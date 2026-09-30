import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/providers.dart';
import 'stats_models.dart';

final statsRepositoryProvider = Provider<StatsRepository>((ref) {
  return StatsRepository(ref.watch(apiClientProvider));
});

class StatsRepository {
  final ApiClient _api;

  // Share identical in-flight requests so concurrent dashboard widgets do not
  // hit the same endpoint more than once.
  final Map<String, Future<StatsSnapshot>> _inFlightStats = {};
  final Map<String, Future<List<TopProduct>>> _inFlightTopProducts = {};
  final Map<String, Future<List<TopProduct>>> _inFlightTopPosts = {};
  final Map<String, Future<List<TopContentItem>>> _inFlightPages = {};

  // Lightweight in-memory cache for content lists. The main stats snapshot
  // uses persistent cache + background refresh.
  static const _dashboardCacheTtl = Duration(minutes: 3);
  static const _statsCacheKeyPrefix = 'ezlens_manager_stats_snapshot_v1:';
  List<TopContentItem>? _latestProductsCache;
  DateTime? _latestProductsCachedAt;
  List<TopContentItem>? _latestPostsCache;
  DateTime? _latestPostsCachedAt;

  StatsRepository(this._api);

  String _statsCacheKey(String period) => '$_statsCacheKeyPrefix$period';

  Future<StatsSnapshot?> readCachedSnapshot({String period = 'week'}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_statsCacheKey(period));
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return StatsSnapshot.fromJson(Map<String, dynamic>.from(decoded as Map));
    } catch (_) {
      // A broken/old cache must never block the live request.
      return null;
    }
  }

  Future<void> _saveSnapshotCache(
    String period,
    Map<String, dynamic> payload,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_statsCacheKey(period), jsonEncode(payload));
    } catch (_) {
      // Cache is an optimization; storage failure must not break stats.
    }
  }

  /// Emits cached data immediately, then emits fresh server data.
  /// If refresh fails, the cached value remains the visible state.
  Stream<StatsSnapshot> watchStats({String period = 'week'}) async* {
    final cached = await readCachedSnapshot(period: period);
    if (cached != null) yield cached;

    try {
      final fresh = await fetch(period: period);
      yield fresh;
    } catch (_) {
      // Never crash the dashboard when manager/stats is missing (404).
      if (cached == null) {
        yield const StatsSnapshot();
      }
    }
  }

  Future<void> clearStatsCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where(
            (key) => key.startsWith(_statsCacheKeyPrefix),
          );
      for (final key in keys) {
        await prefs.remove(key);
      }
    } catch (_) {}

    clearDashboardMemoryCache();
  }

  void clearDashboardMemoryCache() {
    _latestProductsCache = null;
    _latestProductsCachedAt = null;
    _latestPostsCache = null;
    _latestPostsCachedAt = null;
  }

  void clearDashboardCache() {
    _latestProductsCache = null;
    _latestProductsCachedAt = null;
    _latestPostsCache = null;
    _latestPostsCachedAt = null;
  }

  Stream<List<TopContentItem>> watchLatestProducts({int limit = 6}) async* {
    await _loadListCache('products', limit);
    if (_latestProductsCache != null && _latestProductsCache!.isNotEmpty) {
      yield List<TopContentItem>.from(_latestProductsCache!);
    }
    try {
      final fresh =
          await latestProductsWithViews(limit: limit, forceNetwork: true);
      yield fresh;
    } catch (e, st) {
      if (_latestProductsCache != null && _latestProductsCache!.isNotEmpty) {
        yield List<TopContentItem>.from(_latestProductsCache!);
      } else {
        yield* Stream<List<TopContentItem>>.error(e, st);
      }
    }
  }

  Stream<List<TopContentItem>> watchLatestPosts({int limit = 6}) async* {
    await _loadListCache('posts', limit);
    if (_latestPostsCache != null && _latestPostsCache!.isNotEmpty) {
      yield List<TopContentItem>.from(_latestPostsCache!);
    }
    try {
      final fresh =
          await latestPostsWithViews(limit: limit, forceNetwork: true);
      yield fresh;
    } catch (e, st) {
      if (_latestPostsCache != null && _latestPostsCache!.isNotEmpty) {
        yield List<TopContentItem>.from(_latestPostsCache!);
      } else {
        yield* Stream<List<TopContentItem>>.error(e, st);
      }
    }
  }

  Future<void> _loadListCache(String kind, int limit) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('ezlens_dash_${kind}_v2');
      if (raw == null || raw.isEmpty) return;
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;
      final items = <TopContentItem>[];
      for (final e in decoded) {
        if (e is Map) {
          items.add(TopContentItem.fromJson(Map<String, dynamic>.from(e)));
        }
      }
      if (kind == 'products') {
        _latestProductsCache = items;
        _latestProductsCachedAt = DateTime.now();
      } else {
        _latestPostsCache = items;
        _latestPostsCachedAt = DateTime.now();
      }
    } catch (_) {}
  }

  Future<void> _saveListCache(String kind, List<TopContentItem> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'ezlens_dash_${kind}_v2',
        jsonEncode(items.map((e) => e.toJson()).toList()),
      );
    } catch (_) {}
  }

  static const _base = ApiEndpoints.managerStats;

  Future<StatsSnapshot> fetch({String period = 'week'}) {
    final existing = _inFlightStats[period];
    if (existing != null) return existing;

    final future = _fetchStats(period);
    _inFlightStats[period] = future;
    future.whenComplete(() => _inFlightStats.remove(period));
    return future;
  }

  Future<StatsSnapshot> _fetchStats(String period) async {
    try {
      final response = await _api.wpGet<Map<String, dynamic>>(
        _base,
        queryParameters: {'period': period},
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final snapshot = StatsSnapshot.fromJson(data);
        await _saveSnapshotCache(period, data);
        return snapshot;
      }
    } catch (_) {
      // Keep UI alive when route is missing or server error.
      final cached = await readCachedSnapshot(period: period);
      if (cached != null) return cached;
    }
    return const StatsSnapshot();
  }

  Future<List<TopProduct>> topProducts({String by = 'views', int limit = 8}) {
    final key = '$by:$limit';
    final existing = _inFlightTopProducts[key];
    if (existing != null) return existing;

    final future = _fetchTopProducts(by: by, limit: limit);
    _inFlightTopProducts[key] = future;
    future.whenComplete(() => _inFlightTopProducts.remove(key));
    return future;
  }

  Future<List<TopProduct>> topPosts({String by = 'views', int limit = 8}) {
    final key = '$by:$limit';
    final existing = _inFlightTopPosts[key];
    if (existing != null) return existing;
    final future = _fetchTopPosts(by: by, limit: limit);
    _inFlightTopPosts[key] = future;
    future.whenComplete(() => _inFlightTopPosts.remove(key));
    return future;
  }

  Future<List<TopProduct>> _fetchTopPosts({String by = 'views', int limit = 8}) async {
    List<TopProduct> primary = const [];
    // Primary: dedicated manager ranking for posts/articles
    try {
      final response = await _api.wpGet<Map<String, dynamic>>(
        ApiEndpoints.managerTopPosts,
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
      primary = items;
      if (items.any((e) => e.score > 0)) {
        items.sort((a, b) => b.score.compareTo(a.score));
        return items;
      }
    } catch (_) {}

    // Fallback: build from wp/v2 posts + post_views_count field
    try {
      final res = await _api.wpGet<dynamic>(
        ApiEndpoints.posts,
        queryParameters: {
          'per_page': limit > 20 ? 20 : limit,
          'orderby': 'date',
          'order': 'desc',
          'status': 'publish',
          '_fields': 'id,title,post_views_count,meta,date',
        },
      );
      final raw = res.data;
      final items = <TopProduct>[];
      if (raw is List) {
        for (final e in raw) {
          if (e is! Map) continue;
          final m = Map<String, dynamic>.from(e);
          final id = int.tryParse('${m['id']}') ?? 0;
          String title = '';
          final tRaw = m['title'];
          if (tRaw is Map) {
            title = '${tRaw['rendered'] ?? ''}'.replaceAll(RegExp(r'<[^>]*>'), '');
          } else {
            title = '${tRaw ?? ''}';
          }
          var views = int.tryParse('${m['post_views_count'] ?? 0}') ?? 0;
          final meta = m['meta'];
          if (meta is Map) {
            final v2 = int.tryParse('${meta['post_views_count'] ?? meta['views'] ?? 0}') ?? 0;
            if (v2 > views) views = v2;
          }
          items.add(TopProduct(id: id, title: title, score: views, image: ''));
        }
      }
      if (items.any((e) => e.score > 0)) {
        items.sort((a, b) => b.score.compareTo(a.score));
        return items;
      }
      if (items.isNotEmpty) return items;
    } catch (_) {}

    return primary;
  }

  /// Articles ranked by views (for stats UI — not "latest by date").
  Future<List<TopContentItem>> topArticlesByViews({int limit = 8}) async {
    final ranked = await topPosts(by: 'views', limit: limit);
    final out = ranked
        .map(
          (p) => TopContentItem(
            id: p.id,
            title: p.title,
            views: p.score,
            image: p.image,
            type: 'post',
          ),
        )
        .toList();
    out.sort((a, b) => b.views.compareTo(a.views));
    return out;
  }

  /// Map post_id -> views from manager ranking (preferred source).
  Future<Map<int, int>> postViewsMap({int limit = 200}) async {
    final map = <int, int>{};
    try {
      final items = await topPosts(by: 'views', limit: limit);
      for (final p in items) {
        if (p.id > 0) map[p.id] = p.score;
      }
    } catch (_) {}
    return map;
  }

  Future<List<TopProduct>> _fetchTopProducts({
    required String by,
    required int limit,
  }) async {
    try {
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
    } catch (_) {
      return const [];
    }
  }

  /// Latest products with view counts (newest first; views from meta/score).
  Future<List<TopContentItem>> latestProductsWithViews({
    int limit = 6,
    bool forceNetwork = false,
  }) async {
    final cachedAt = _latestProductsCachedAt;
    if (!forceNetwork &&
        _latestProductsCache != null &&
        cachedAt != null &&
        DateTime.now().difference(cachedAt) < _dashboardCacheTtl) {
      return List<TopContentItem>.from(_latestProductsCache!);
    }

    // Prefer manager top-products by views
    try {
      final tops = await topProducts(by: 'latest', limit: limit);
      if (tops.isNotEmpty) {
        final result = tops.map(TopContentItem.fromTopProduct).toList();
        _latestProductsCache = result;
        _latestProductsCachedAt = DateTime.now();
        return List<TopContentItem>.from(result);
      }
    } catch (_) {}

    // Fallback: WC products ordered by date
    try {
      final res = await _api.wcGet<List<dynamic>>(
        ApiEndpoints.products,
        queryParameters: {
          'per_page': limit,
          'orderby': 'date',
          'order': 'desc',
          'status': 'publish',
          '_fields': 'id,name,images,date_created,meta_data',
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
                  (meta['key'] == 'post_views_count' ||
                      meta['key'] == 'views')) {
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
      _latestProductsCache = out;
      _latestProductsCachedAt = DateTime.now();
      await _saveListCache('products', out);
      return List<TopContentItem>.from(out);
    } catch (_) {
      return const [];
    }
  }

  /// Latest posts/articles with view counts.
  /// Prefer manager stats ranking; fallback to WP list + meta.
  /// Latest posts/articles with view counts from WP meta + manager map.
  Future<List<TopContentItem>> latestPostsWithViews({
    int limit = 6,
    bool forceNetwork = false,
  }) async {
    final cachedAt = _latestPostsCachedAt;
    if (!forceNetwork &&
        _latestPostsCache != null &&
        cachedAt != null &&
        DateTime.now().difference(cachedAt) < _dashboardCacheTtl) {
      return List<TopContentItem>.from(_latestPostsCache!);
    }

    try {
      Map<int, int> viewsMap = {};
      try {
        viewsMap = await postViewsMap(limit: 200);
      } catch (_) {}

      List<dynamic>? list;
      try {
        final res = await _api.wpGet<List<dynamic>>(
          ApiEndpoints.posts,
          queryParameters: {
            'per_page': limit,
            'orderby': 'date',
            'order': 'desc',
            'status': 'publish',
            '_embed': 'wp:featuredmedia',
            '_fields': 'id,title,date,modified,link,post_views_count,views,view_count,views_count,pageviews,meta,_embedded',
          },
        );
        list = res.data;
      } catch (_) {
        list = null;
      }

      final out = <TopContentItem>[];
      if (list is List) {
        for (final e in list) {
          if (e is! Map) continue;
          final m = Map<String, dynamic>.from(e);
          final id = int.tryParse('${m['id']}') ?? 0;
          if (id <= 0) continue;

          String title = '';
          final tRaw = m['title'];
          if (tRaw is Map) {
            title =
                '${tRaw['rendered'] ?? ''}'.replaceAll(RegExp(r'<[^>]*>'), '');
          } else {
            title = '${tRaw ?? ''}';
          }

          String image = '';
          final emb = m['_embedded'];
          if (emb is Map && emb['wp:featuredmedia'] is List) {
            final media = emb['wp:featuredmedia'] as List;
            if (media.isNotEmpty && media.first is Map) {
              final fm = Map<String, dynamic>.from(media.first as Map);
              image = '${fm['source_url'] ?? ''}';
            }
          }

          int views = viewsMap[id] ?? 0;
          views = _extractViews(m, fallback: views);

          out.add(TopContentItem(
            id: id,
            title: title,
            views: views,
            image: image,
            type: 'post',
            date: DateTime.tryParse('${m['date'] ?? ''}'),
          ));
        }
      }

      if (out.any((e) => e.views > 0)) {
        out.sort((a, b) => b.views.compareTo(a.views));
      }

      if (out.any((e) => e.views > 0)) {
        _latestPostsCache = out;
        _latestPostsCachedAt = DateTime.now();
        await _saveListCache('posts', out);
      } else {
        // Do not persist empty/zero view caches — next open refetches.
        _latestPostsCache = out;
        _latestPostsCachedAt = DateTime.now().subtract(const Duration(hours: 1));
      }
      return List<TopContentItem>.from(out);
    } catch (_) {
      if (_latestPostsCache != null) {
        return List<TopContentItem>.from(_latestPostsCache!);
      }
      return const [];
    }
  }

  int _extractViews(Map<String, dynamic> m, {int fallback = 0}) {
    int views = fallback;
    void consider(dynamic v) {
      final n = int.tryParse('${v ?? ''}') ?? 0;
      if (n > views) views = n;
    }

    consider(m['post_views_count']);
    consider(m['views']);
    consider(m['view_count']);

    final meta = m['meta'];
    if (meta is Map) {
      for (final k in [
        'post_views_count',
        'views',
        'view_count',
        'views_count',
        'pageviews',
        'total_views',
        'rank_math_og_views',
      ]) {
        consider(meta[k]);
      }
    } else if (meta is List) {
      for (final e in meta) {
        if (e is! Map) continue;
        final key = '${e['key'] ?? ''}';
        if (key == 'post_views_count' ||
            key == 'views' ||
            key == 'view_count' ||
            key == 'pageviews') {
          consider(e['value']);
        }
      }
    }
    return views;
  }

  /// Sum of article views from a larger sample.
  Future<int> sumArticleViews({int limit = 50}) async {
    final items = await latestPostsWithViews(limit: limit, forceNetwork: true);
    var sum = 0;
    for (final e in items) {
      sum += e.views;
    }
    return sum;
  }

  /// Site pages with view counts (wp/v2/pages).
  Future<List<TopContentItem>> latestPagesWithViews({int limit = 8}) async {
    try {
      final res = await _api.wpGet<List<dynamic>>(
        '/wp-json/wp/v2/pages',
        queryParameters: {
          'per_page': limit,
          'orderby': 'date',
          'order': 'desc',
          'status': 'publish',
          '_fields': 'id,title,date,post_views_count,meta,link',
        },
      );
      final list = res.data;
      final out = <TopContentItem>[];
      if (list is List) {
        for (final e in list) {
          if (e is! Map) continue;
          final m = Map<String, dynamic>.from(e);
          final id = int.tryParse('${m['id']}') ?? 0;
          String title = '';
          final tRaw = m['title'];
          if (tRaw is Map) {
            title =
                '${tRaw['rendered'] ?? ''}'.replaceAll(RegExp(r'<[^>]*>'), '');
          } else {
            title = '${tRaw ?? ''}';
          }
          final views = _extractViews(m);
          out.add(TopContentItem(
            id: id,
            title: title,
            views: views,
            type: 'page',
            date: DateTime.tryParse('${m['date'] ?? ''}'),
          ));
        }
      }
      if (out.any((e) => e.views > 0)) {
        out.sort((a, b) => b.views.compareTo(a.views));
      }
      return out;
    } catch (_) {
      return const [];
    }
  }


  Future<GscOverview> fetchGscOverview({String period = 'week'}) async {
    try {
      final response = await _api.wpGet<Map<String, dynamic>>(
        ApiEndpoints.managerGsc,
        queryParameters: {'period': period},
      );
      final data = response.data;
      if (data != null) {
        return GscOverview.fromJson(Map<String, dynamic>.from(data));
      }
    } catch (_) {}
    return const GscOverview(
      ok: false,
      configured: false,
      message: 'unavailable',
    );
  }

  Future<List<GscRow>> fetchGscRows({
    required String kind, // queries | pages | countries
    String period = 'week',
    int limit = 15,
  }) async {
    try {
      final path = kind == 'pages'
          ? ApiEndpoints.managerGscPages
          : kind == 'countries'
              ? ApiEndpoints.managerGscCountries
              : ApiEndpoints.managerGscQueries;
      final response = await _api.wpGet<Map<String, dynamic>>(
        path,
        queryParameters: {'period': period, 'limit': limit},
      );
      final data = response.data;
      final items = <GscRow>[];
      if (data != null) {
        final raw = data['items'];
        if (raw is List) {
          for (final e in raw) {
            if (e is Map) {
              items.add(GscRow.fromJson(Map<String, dynamic>.from(e)));
            }
          }
        }
      }
      return items;
    } catch (_) {
      return const [];
    }
  }

  Future<List<RecentVisitor>> fetchRecentVisitors({int limit = 10}) async {
    try {
      final response = await _api.wpGet<Map<String, dynamic>>(
        ApiEndpoints.managerRecentVisitors,
        queryParameters: {'limit': limit},
      );
      final data = response.data;
      final items = <RecentVisitor>[];
      if (data != null && data['items'] is List) {
        for (final e in data['items'] as List) {
          if (e is Map) {
            items.add(RecentVisitor.fromJson(Map<String, dynamic>.from(e)));
          }
        }
      }
      return items;
    } catch (_) {
      return const [];
    }
  }

  Future<List<IndexStatusItem>> fetchIndexStatus({int limit = 8}) async {
    try {
      final response = await _api.wpGet<Map<String, dynamic>>(
        ApiEndpoints.managerIndexStatus,
        queryParameters: {'limit': limit},
      );
      final data = response.data;
      final items = <IndexStatusItem>[];
      if (data != null && data['items'] is List) {
        for (final e in data['items'] as List) {
          if (e is Map) {
            items.add(IndexStatusItem.fromJson(Map<String, dynamic>.from(e)));
          }
        }
      }
      return items;
    } catch (_) {
      return const [];
    }
  }

}
