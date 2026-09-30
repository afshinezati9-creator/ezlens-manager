/// Stable cache key helpers for EzLens Manager local store.
class CacheKeys {
  CacheKeys._();

  static const String prefix = 'ezlens_cache_v1_';

  static String list(String module, {String? suffix}) {
    final s = suffix == null || suffix.isEmpty ? '' : '_$suffix';
    return '$prefix${module}_list$s';
  }

  static String item(String module, String id) => '$prefix${module}_item_$id';

  static String meta(String module) => '$prefix${module}_meta';

  // Common modules
  static const products = 'products';
  static const orders = 'orders';
  static const customers = 'customers';
  static const articles = 'articles';
  static const stats = 'stats';
  static const support = 'support';
  static const comments = 'comments';
  static const wallet = 'wallet';
  static const campaign = 'campaign';
  static const dashboard = 'dashboard';
  static const requests = 'requests';
  static const inbox = 'inbox';
}
