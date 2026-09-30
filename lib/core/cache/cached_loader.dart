import 'package:flutter/foundation.dart';

import 'local_cache_service.dart';

typedef FromJson<T> = T Function(dynamic json);
typedef Fetcher<T> = Future<T> Function();
typedef ToJson<T> = dynamic Function(T value);

/// Result of a cache-first load.
class CacheLoadResult<T> {
  const CacheLoadResult({
    required this.data,
    required this.fromCache,
    this.error,
  });

  final T? data;
  final bool fromCache;
  final Object? error;

  bool get hasData => data != null;
}

/// Cache-first then network.
///
/// Usage in a repository:
/// ```dart
/// final r = await CachedLoader.load(
///   key: CacheKeys.list(CacheKeys.orders, suffix: 'p1'),
///   fetcher: () => api.getOrders(page: 1),
///   fromJson: (j) => OrderList.fromJson(j as Map),
///   toJson: (v) => v.toJson(),
/// );
/// ```
class CachedLoader {
  CachedLoader._();

  /// Returns cache immediately via [onCache] if present, then network via [onNetwork].
  ///
  /// Call from a Riverpod notifier:
  /// ```dart
  /// await CachedLoader.stream(
  ///   key: key,
  ///   fetcher: fetch,
  ///   fromJson: parse,
  ///   toJson: encode,
  ///   onCache: (data) => state = AsyncData(data),
  ///   onNetwork: (data) => state = AsyncData(data),
  ///   onError: (e, st) { if (state is! AsyncData) state = AsyncError(e, st); },
  /// );
  /// ```
  static Future<void> stream<T>({
    required String key,
    required Fetcher<T> fetcher,
    required FromJson<T> fromJson,
    required ToJson<T> toJson,
    required void Function(T data) onCache,
    required void Function(T data) onNetwork,
    void Function(Object error, StackTrace st)? onError,
  }) async {
    final cache = LocalCacheService.instance;

    // 1) Cache first
    try {
      final raw = await cache.read(key);
      if (raw != null) {
        final parsed = fromJson(raw);
        onCache(parsed);
      }
    } catch (e, st) {
      debugPrint('CachedLoader cache parse: $e\n$st');
    }

    // 2) Network
    try {
      final fresh = await fetcher();
      await cache.write(key, toJson(fresh));
      onNetwork(fresh);
    } catch (e, st) {
      debugPrint('CachedLoader network: $e');
      onError?.call(e, st);
    }
  }

  /// One-shot: cache if any, else network; always tries network to refresh store.
  static Future<CacheLoadResult<T>> load<T>({
    required String key,
    required Fetcher<T> fetcher,
    required FromJson<T> fromJson,
    required ToJson<T> toJson,
  }) async {
    final cache = LocalCacheService.instance;
    T? cached;
    try {
      final raw = await cache.read(key);
      if (raw != null) cached = fromJson(raw);
    } catch (_) {}

    try {
      final fresh = await fetcher();
      await cache.write(key, toJson(fresh));
      return CacheLoadResult(data: fresh, fromCache: false);
    } catch (e) {
      if (cached != null) {
        return CacheLoadResult(data: cached, fromCache: true, error: e);
      }
      return CacheLoadResult(data: null, fromCache: false, error: e);
    }
  }
}
