import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/user_models.dart';
import '../data/user_repository.dart';

class UsersQuery {
  final int page;
  final String search;
  final String role;
  final String orderby;
  final String order;

  const UsersQuery({
    this.page = 1,
    this.search = '',
    this.role = 'all',
    this.orderby = 'registered_date',
    this.order = 'desc',
  });

  UsersQuery copyWith({
    int? page,
    String? search,
    String? role,
    String? orderby,
    String? order,
  }) {
    return UsersQuery(
      page: page ?? this.page,
      search: search ?? this.search,
      role: role ?? this.role,
      orderby: orderby ?? this.orderby,
      order: order ?? this.order,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is UsersQuery &&
      other.page == page &&
      other.search == search &&
      other.role == role &&
      other.orderby == orderby &&
      other.order == order;

  @override
  int get hashCode => Object.hash(page, search, role, orderby, order);
}

final usersQueryProvider = StateProvider<UsersQuery>((ref) => const UsersQuery());

final usersListProvider =
    FutureProvider.autoDispose<UsersListResult>((ref) async {
  final q = ref.watch(usersQueryProvider);
  final repo = ref.watch(userRepositoryProvider);
  return repo.fetchUsers(
    page: q.page,
    search: q.search,
    role: q.role,
    orderby: q.orderby,
    order: q.order,
  );
});

final userDetailProvider =
    FutureProvider.autoDispose.family<ManagerUser, int>((ref, id) async {
  final repo = ref.watch(userRepositoryProvider);
  return repo.fetchUser(id);
});


final userDossierProvider =
    FutureProvider.autoDispose.family<UserDossier, int>((ref, id) async {
  final repo = ref.watch(userRepositoryProvider);
  return repo.fetchDossier(id);
});
