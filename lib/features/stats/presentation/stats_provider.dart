import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/stats_models.dart';
import '../data/stats_repository.dart';

final statsPeriodProvider = StateProvider<String>((ref) => 'week');

final statsSnapshotProvider =
    FutureProvider.autoDispose<StatsSnapshot>((ref) {
  final period = ref.watch(statsPeriodProvider);
  return ref.watch(statsRepositoryProvider).fetch(period: period);
});

final topByViewsProvider =
    FutureProvider.autoDispose<List<TopProduct>>((ref) {
  return ref.watch(statsRepositoryProvider).topProducts(by: 'views');
});

final topBySalesProvider =
    FutureProvider.autoDispose<List<TopProduct>>((ref) {
  return ref.watch(statsRepositoryProvider).topProducts(by: 'sales');
});
