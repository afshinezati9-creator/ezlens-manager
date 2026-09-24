import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/campaign_models.dart';
import '../data/campaign_repository.dart';

final booksProvider = FutureProvider.autoDispose<List<ContactBook>>((ref) {
  return ref.watch(campaignRepositoryProvider).fetchBooks();
});

final campaignsProvider = FutureProvider.autoDispose<List<CampaignItem>>((ref) {
  return ref.watch(campaignRepositoryProvider).fetchCampaigns();
});
