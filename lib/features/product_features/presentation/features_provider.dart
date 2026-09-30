import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/feature_models.dart';
import '../data/feature_repository.dart';

class FeaturesQuery {
  final int page;
  final String search;
  final String status;

  const FeaturesQuery({
    this.page = 1,
    this.search = '',
    this.status = 'all',
  });

  FeaturesQuery copyWith({int? page, String? search, String? status}) {
    return FeaturesQuery(
      page: page ?? this.page,
      search: search ?? this.search,
      status: status ?? this.status,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is FeaturesQuery &&
      other.page == page &&
      other.search == search &&
      other.status == status;

  @override
  int get hashCode => Object.hash(page, search, status);
}

final featuresQueryProvider =
    StateProvider<FeaturesQuery>((ref) => const FeaturesQuery());

final featuresListProvider =
    FutureProvider.autoDispose<ProductFeatureListResponse>((ref) async {
  final q = ref.watch(featuresQueryProvider);
  final repo = ref.watch(productFeatureRepositoryProvider);
  return repo.fetchList(
    page: q.page,
    search: q.search,
    status: q.status,
  );
});

final featureDetailProvider =
    FutureProvider.autoDispose.family<ProductFeature, int>((ref, id) async {
  final repo = ref.watch(productFeatureRepositoryProvider);
  return repo.fetchOne(id);
});

final productSlotsProvider =
    FutureProvider.autoDispose.family<List<ProductFeatureSlot>, int>((ref, productId) async {
  final repo = ref.watch(productFeatureRepositoryProvider);
  return repo.fetchProductSlots(productId);
});
