import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/purchase_models.dart';
import '../data/purchase_repository.dart';

final purchaseListProvider =
    FutureProvider.autoDispose<List<PurchaseScript>>((ref) {
  return ref.watch(purchaseRepositoryProvider).fetchList();
});

final purchaseStatsProvider =
    FutureProvider.autoDispose<Map<String, int>>((ref) {
  return ref.watch(purchaseRepositoryProvider).stats();
});

final purchaseDetailProvider =
    FutureProvider.autoDispose.family<PurchaseScript, int>((ref, id) {
  return ref.watch(purchaseRepositoryProvider).fetchOne(id);
});
