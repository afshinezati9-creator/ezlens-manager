# Example: Orders list provider (Riverpod)

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ezlens_manager/core/cache/cache_keys.dart';
import 'package:ezlens_manager/core/cache/cached_loader.dart';

class OrdersNotifier extends AsyncNotifier<List<OrderSummary>> {
  @override
  Future<List<OrderSummary>> build() async {
    // Start empty; stream() will push cache then network.
    return const [];
  }

  Future<void> load({int page = 1}) async {
    final repo = ref.read(orderRepositoryProvider);
    final key = CacheKeys.list(CacheKeys.orders, suffix: 'p$page');

    await CachedLoader.stream<List<OrderSummary>>(
      key: key,
      fetcher: () => repo.fetchOrders(page: page),
      fromJson: (j) {
        final list = (j as List).map((e) => OrderSummary.fromJson(
          Map<String, dynamic>.from(e as Map),
        )).toList();
        return list;
      },
      toJson: (list) => list.map((e) => e.toJson()).toList(),
      onCache: (data) {
        state = AsyncData(data);
      },
      onNetwork: (data) {
        state = AsyncData(data);
      },
      onError: (e, st) {
        // Keep showing cache if we already have data
        if (!state.hasValue || state.value == null || state.value!.isEmpty) {
          state = AsyncError(e, st);
        }
      },
    );
  }
}
```

UI tip: show a small "در حال به‌روزرسانی…" banner only when `state.isLoading` is false but a refresh flag is true — optional.
