import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mass_models.dart';
import '../data/mass_repository.dart';

final massLogsProvider = FutureProvider.autoDispose<List<MassLogItem>>((ref) {
  return ref.watch(massRepositoryProvider).fetchLogs();
});

final massQueueProvider =
    FutureProvider.autoDispose<List<MassQueueItem>>((ref) {
  return ref.watch(massRepositoryProvider).fetchQueue();
});
