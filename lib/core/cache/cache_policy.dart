/// How long cached data is considered "fresh" (still show + soft-refresh).
/// Network is always attempted in background; this only affects optional UI badges.
class CachePolicy {
  CachePolicy._();

  /// Default: always show cache first, always refresh in background.
  static const Duration softMaxAge = Duration(hours: 24);

  static bool isStale(int? writtenAtMs, {Duration maxAge = softMaxAge}) {
    if (writtenAtMs == null) return true;
    final age = DateTime.now().millisecondsSinceEpoch - writtenAtMs;
    return age > maxAge.inMilliseconds;
  }
}
