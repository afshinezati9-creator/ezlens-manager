import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/discount_models.dart';
import '../data/discount_repository.dart';

final couponsProvider = FutureProvider.autoDispose<List<DiscountCoupon>>((ref) {
  return ref.watch(discountRepositoryProvider).fetchCoupons();
});

final giftsProvider = FutureProvider.autoDispose<List<GiftCardItem>>((ref) {
  return ref.watch(discountRepositoryProvider).fetchGifts();
});

final discountStatsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) {
  return ref.watch(discountRepositoryProvider).fetchStats();
});
