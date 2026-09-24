import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/charity_models.dart';
import '../data/charity_repository.dart';

final charityStatsProvider =
    FutureProvider.autoDispose<CharityStats>((ref) {
  return ref.watch(charityRepositoryProvider).fetchStats();
});

final charityCasesProvider =
    FutureProvider.autoDispose<List<CharityCase>>((ref) {
  return ref.watch(charityRepositoryProvider).fetchCases();
});

final charityDonationsProvider =
    FutureProvider.autoDispose<List<CharityDonation>>((ref) {
  return ref.watch(charityRepositoryProvider).fetchDonations();
});
