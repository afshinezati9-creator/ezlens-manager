import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/stats_models.dart';
import '../data/stats_repository.dart';

final statsPeriodProvider = StateProvider<String>((ref) => 'week');

/// keepAlive: avoid refetch on every back-navigation
final statsSnapshotProvider = StreamProvider<StatsSnapshot>((ref) {
  final period = ref.watch(statsPeriodProvider);
  return ref.watch(statsRepositoryProvider).watchStats(period: period);
});

final topByViewsProvider = FutureProvider<List<TopProduct>>((ref) {
  return ref.watch(statsRepositoryProvider).topProducts(by: 'views');
});

final topBySalesProvider = FutureProvider<List<TopProduct>>((ref) {
  return ref.watch(statsRepositoryProvider).topProducts(by: 'sales');
});

final latestPostsWithViewsProvider = FutureProvider<List<TopContentItem>>((ref) {
  return ref.watch(statsRepositoryProvider).latestPostsWithViews(limit: 12);
});

final topArticlesByViewsProvider = FutureProvider<List<TopContentItem>>((ref) {
  return ref.watch(statsRepositoryProvider).topArticlesByViews(limit: 10);
});

final articleViewsSumProvider = FutureProvider<int>((ref) async {
  final snap = ref.watch(statsSnapshotProvider).valueOrNull;
  if (snap != null && snap.totalPostViews > 0) {
    return snap.totalPostViews;
  }
  try {
    final posts = await ref.watch(topArticlesByViewsProvider.future);
    var listSum = 0;
    for (final p in posts) {
      listSum += p.views;
    }
    return listSum;
  } catch (_) {
    return 0;
  }
});

final sitePagesViewsProvider = FutureProvider<List<TopContentItem>>((ref) {
  return ref.watch(statsRepositoryProvider).latestPagesWithViews(limit: 10);
});

final gscOverviewProvider = FutureProvider<GscOverview>((ref) {
  final period = ref.watch(statsPeriodProvider);
  return ref.watch(statsRepositoryProvider).fetchGscOverview(period: period);
});

final gscQueriesProvider = FutureProvider<List<GscRow>>((ref) {
  final period = ref.watch(statsPeriodProvider);
  return ref.watch(statsRepositoryProvider).fetchGscRows(kind: 'queries', period: period);
});

final gscPagesProvider = FutureProvider<List<GscRow>>((ref) {
  final period = ref.watch(statsPeriodProvider);
  return ref.watch(statsRepositoryProvider).fetchGscRows(kind: 'pages', period: period);
});

final gscCountriesProvider = FutureProvider<List<GscRow>>((ref) {
  final period = ref.watch(statsPeriodProvider);
  return ref.watch(statsRepositoryProvider).fetchGscRows(kind: 'countries', period: period);
});

final recentVisitorsProvider = FutureProvider<List<RecentVisitor>>((ref) {
  return ref.watch(statsRepositoryProvider).fetchRecentVisitors(limit: 10);
});

final indexStatusProvider = FutureProvider<List<IndexStatusItem>>((ref) {
  return ref.watch(statsRepositoryProvider).fetchIndexStatus(limit: 10);
});
