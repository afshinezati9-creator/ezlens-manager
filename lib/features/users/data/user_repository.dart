import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/providers.dart';
import 'user_models.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(ref.watch(apiClientProvider));
});

class UserRepository {
  final ApiClient _api;
  UserRepository(this._api);

  // Coalesce identical list requests triggered by rebuilds/navigation.
  final Map<String, Future<UsersListResult>> _inFlightLists = {};

  String _listKey({
    required int page,
    required int perPage,
    required String search,
    required String role,
    required String orderby,
    required String order,
    required bool summary,
  }) =>
      '${page}|${perPage}|${search.trim()}|${role}|${orderby}|${order}|${summary ? 1 : 0}';


  static const _wc = '/wp-json/wc/v3/customers';
  static const _mgr = '/wp-json/ezlens/v1/manager/customers';
  static const _wpUsers = '/wp-json/wp/v2/users';

  /// Prefer Manager list (WP users). WC /customers is often empty for OTP users.
  Future<UsersListResult> fetchUsers({
    int page = 1,
    int perPage = 15,
    String search = '',
    String role = '',
    String orderby = 'registered_date',
    String order = 'desc',
    bool summary = false,
  }) {
    final key = _listKey(
      page: page,
      perPage: perPage,
      search: search,
      role: role,
      orderby: orderby,
      order: order,
      summary: summary,
    );
    final existing = _inFlightLists[key];
    if (existing != null) return existing;

    final request = _fetchUsersInternal(
      page: page,
      perPage: perPage,
      search: search,
      role: role,
      orderby: orderby,
      order: order,
      summary: summary,
    );
    _inFlightLists[key] = request;
    request.whenComplete(() {
      if (identical(_inFlightLists[key], request)) {
        _inFlightLists.remove(key);
      }
    });
    return request;
  }

  Future<UsersListResult> _fetchUsersInternal({
    required int page,
    required int perPage,
    required String search,
    required String role,
    required String orderby,
    required String order,
    required bool summary,
  }) async {
    String ob = 'registered';
    if (orderby == 'name' || orderby == 'display_name') ob = 'display_name';
    if (orderby == 'email') ob = 'email';
    if (orderby == 'id' || orderby == 'ID') ob = 'ID';

    // 1) Manager API
    try {
      final params = <String, dynamic>{
        'page': page,
        'per_page': perPage,
        'orderby': ob,
        'order': order,
        if (search.trim().isNotEmpty) 'search': search.trim(),
        'role': (role.isEmpty || role == 'all') ? 'all' : role,
        if (summary) 'summary': 1,
      };
      final response = await _api.wpGet<Map<String, dynamic>>(
        _mgr,
        queryParameters: params,
      );
      final data = response.data;
      if (data != null && data['items'] is List) {
        final items = <ManagerUser>[];
        for (final e in data['items'] as List) {
          if (e is Map) {
            items.add(_fromManagerJson(Map<String, dynamic>.from(e)));
          }
        }
        final total = int.tryParse('${data['total']}') ?? items.length;
        final totalPages = int.tryParse('${data['total_pages']}') ?? 1;
        if (items.isNotEmpty || total > 0) {
          return UsersListResult(
            items: items,
            total: total,
            totalPages: totalPages,
          );
        }
      }
    } catch (_) {}

    // 2) WP users
    try {
      final params = <String, dynamic>{
        'page': page,
        'per_page': perPage,
        'orderby': 'registered',
        'order': order,
        if (search.trim().isNotEmpty) 'search': search.trim(),
        'context': 'edit',
      };
      final response = await _api.wpGet<List<dynamic>>(
        _wpUsers,
        queryParameters: params,
      );
      final raw = response.data ?? [];
      final items = <ManagerUser>[];
      for (final e in raw) {
        if (e is Map) {
          final m = Map<String, dynamic>.from(e);
          items.add(
            ManagerUser(
              id: int.tryParse('${m['id']}') ?? 0,
              username: (m['slug'] ?? m['username'] ?? '').toString(),
              email: (m['email'] ?? '').toString(),
              firstName: (m['first_name'] ?? '').toString(),
              lastName: (m['last_name'] ?? '').toString(),
              role: 'customer',
              dateCreated:
                  DateTime.tryParse((m['registered_date'] ?? '').toString()),
            ),
          );
        }
      }
      int total = items.length;
      int totalPages = 1;
      try {
        final t = response.headers.map['x-wp-total']?.first;
        final p = response.headers.map['x-wp-totalpages']?.first;
        if (t != null) total = int.tryParse(t) ?? total;
        if (p != null) totalPages = int.tryParse(p) ?? totalPages;
      } catch (_) {}
      if (items.isNotEmpty) {
        return UsersListResult(
            items: items, total: total, totalPages: totalPages);
      }
    } catch (_) {}

    // 3) WC customers fallback
    final params = <String, dynamic>{
      'page': page,
      'per_page': perPage,
      'orderby': orderby,
      'order': order,
      if (search.trim().isNotEmpty) 'search': search.trim(),
      if (role.isNotEmpty && role != 'all') 'role': role,
    };
    final response = await _api.wcGet(_wc, queryParameters: params);
    final raw = response.data;
    final items = <ManagerUser>[];
    if (raw is List) {
      for (final e in raw) {
        if (e is Map) {
          items.add(ManagerUser.fromWcJson(Map<String, dynamic>.from(e)));
        }
      }
    }
    int total = items.length;
    int totalPages = 1;
    try {
      final t = response.headers.map['x-wp-total']?.first;
      final p = response.headers.map['x-wp-totalpages']?.first;
      if (t != null) total = int.tryParse(t) ?? total;
      if (p != null) totalPages = int.tryParse(p) ?? totalPages;
    } catch (_) {}
    return UsersListResult(items: items, total: total, totalPages: totalPages);
  }


  ManagerUser _fromManagerJson(Map<String, dynamic> json) {
    if (json['billing'] is Map || json.containsKey('meta_data')) {
      final base = ManagerUser.fromWcJson(json);
      return base.mergeEnrichment(json);
    }
    final roles = json['roles'];
    final role = (roles is List && roles.isNotEmpty)
        ? roles.first.toString()
        : (json['role']?.toString() ?? 'customer');
    DateTime? reg;
    final r = json['registered']?.toString();
    if (r != null && r.isNotEmpty) reg = DateTime.tryParse(r);
    DateTime? last;
    final l = json['last_login']?.toString();
    if (l != null && l.isNotEmpty) last = DateTime.tryParse(l);

    return ManagerUser(
      id: int.tryParse('${json['id']}') ?? 0,
      username: (json['username'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      firstName: (json['first_name'] ?? '').toString(),
      lastName: (json['last_name'] ?? '').toString(),
      role: role,
      phone: (json['phone'] ?? '').toString(),
      dateCreated: reg,
      lastLogin: last,
      ordersCount: int.tryParse('${json['orders_count']}') ?? 0,
      totalSpent: (json['total_spent'] ?? '0').toString(),
      walletBalance: int.tryParse('${json['wallet_balance']}') ?? 0,
      hasPassword: json['has_password'] == true,
    );
  }

  Future<ManagerUser> fetchUser(int id) async {
    try {
      final enr = await _api.wpGet<Map<String, dynamic>>('$_mgr/$id');
      final data = enr.data;
      if (data is Map) {
        return _fromManagerJson(Map<String, dynamic>.from(data as Map));
      }
    } catch (_) {}

    final response = await _api.wcGet('$_wc/$id');
    final data = response.data;
    if (data is! Map) {
      throw Exception('مشتری یافت نشد');
    }
    var user = ManagerUser.fromWcJson(Map<String, dynamic>.from(data as Map));
    return user;

  }

  Future<ManagerUser> createUser({
    required String phone,
    String email = '',
    String firstName = '',
    String lastName = '',
    String password = '',
  }) async {
    final mobile = phone.replaceAll(RegExp(r'\D'), '');
    final login = mobile.startsWith('9') && mobile.length == 10
        ? '0$mobile'
        : mobile;

    final body = <String, dynamic>{
      'email': email.isNotEmpty ? email : '$login@ezlens.ir',
      'username': login,
      'first_name': firstName,
      'last_name': lastName,
      'billing': {
        'first_name': firstName,
        'last_name': lastName,
        'phone': login,
        'email': email.isNotEmpty ? email : '$login@ezlens.ir',
      },
      if (password.isNotEmpty) 'password': password,
      'meta_data': [
        {'key': 'user_phone', 'value': login},
        {'key': 'billing_phone', 'value': login},
      ],
    };

    final response = await _api.wcPost(_wc, data: body);
    final data = response.data;
    if (data is Map) {
      return ManagerUser.fromWcJson(Map<String, dynamic>.from(data as Map));
    }
    throw Exception('خطا در ایجاد مشتری');
  }

  Future<ManagerUser> updateUser(
    int id, {
    String? email,
    String? firstName,
    String? lastName,
    String? phone,
    String? password,
  }) async {
    final body = <String, dynamic>{
      if (email != null) 'email': email,
      if (firstName != null) 'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
      if (password != null && password.isNotEmpty) 'password': password,
    };
    if (phone != null && phone.isNotEmpty) {
      final p = phone.replaceAll(RegExp(r'\D'), '');
      final normalized = (p.startsWith('9') && p.length == 10) ? '0$p' : p;
      body['billing'] = {'phone': normalized};
      body['meta_data'] = [
        {'key': 'user_phone', 'value': normalized},
        {'key': 'billing_phone', 'value': normalized},
      ];
    }

    final response = await _api.wcPut('$_wc/$id', data: body);
    final data = response.data;
    if (data is Map) {
      return ManagerUser.fromWcJson(Map<String, dynamic>.from(data as Map));
    }
    throw Exception('خطا در به‌روزرسانی');
  }

  Future<void> deleteUser(int id, {bool force = true}) async {
    await _api.wcDelete('$_wc/$id', queryParameters: {
      'force': force,
      'reassign': 0,
    });
  }

  Future<UserDossier> fetchDossier(int id) async {
    try {
      final response = await _api.wpGet<Map<String, dynamic>>(
        '$_mgr/$id/dossier',
      );
      final data = response.data;
      if (data is Map) {
        return UserDossier.fromJson(Map<String, dynamic>.from(data as Map));
      }
    } catch (_) {}
    return UserDossier(customerId: id);
  }
}
