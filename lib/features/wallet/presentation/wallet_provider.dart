import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/wallet_models.dart';
import '../data/wallet_repository.dart';

class WalletQuery {
  final int page;
  final String status;
  final String method;
  final String search;

  const WalletQuery({
    this.page = 1,
    this.status = 'pending',
    this.method = 'all',
    this.search = '',
  });

  WalletQuery copyWith({
    int? page,
    String? status,
    String? method,
    String? search,
  }) {
    return WalletQuery(
      page: page ?? this.page,
      status: status ?? this.status,
      method: method ?? this.method,
      search: search ?? this.search,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is WalletQuery &&
      other.page == page &&
      other.status == status &&
      other.method == method &&
      other.search == search;

  @override
  int get hashCode => Object.hash(page, status, method, search);
}

final walletQueryProvider =
    StateProvider<WalletQuery>((ref) => const WalletQuery());

final walletDepositsProvider =
    FutureProvider.autoDispose<DepositListResult>((ref) async {
  final q = ref.watch(walletQueryProvider);
  return ref.watch(walletRepositoryProvider).fetchDeposits(
        page: q.page,
        status: q.status,
        method: q.method,
        search: q.search,
      );
});

final walletStatsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) {
  return ref.watch(walletRepositoryProvider).fetchStats();
});

final walletPaymentConfigProvider =
    FutureProvider.autoDispose<WalletPaymentConfig>((ref) {
  return ref.watch(walletRepositoryProvider).fetchPaymentConfig();
});
