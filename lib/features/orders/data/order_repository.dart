// lib/features/orders/data/order_repository.dart

import '../../../core/network/api_client.dart';
import 'order_models.dart';

class OrderRepository {
  final ApiClient _api;

  // جلوگیری از ارسال هم‌زمان درخواست‌های کاملاً یکسان.
  // این cache داده نیست؛ فقط تا پایان همان درخواست زنده است.
  final Map<String, Future<List<Order>>> _inFlightLists =
      <String, Future<List<Order>>>{};
  final Map<int, Future<Order>> _inFlightOrders = <int, Future<Order>>{};
  final Map<int, Future<List<OrderNote>>> _inFlightNotes =
      <int, Future<List<OrderNote>>>{};
  final Map<int, Future<Customer>> _inFlightCustomers =
      <int, Future<Customer>>{};

  OrderRepository(this._api);

  String _listKey({
    required int page,
    required int perPage,
    String? search,
    String? status,
    DateTime? dateStart,
    DateTime? dateEnd,
    String? paymentMethod,
  }) {
    return [
      page,
      perPage,
      search ?? '',
      status ?? '',
      dateStart?.toIso8601String() ?? '',
      dateEnd?.toIso8601String() ?? '',
      paymentMethod ?? '',
    ].join('|');
  }

  Future<List<Order>> fetchOrders({
    int page = 1,
    int perPage = 10,
    String? search,
    String? status,
    DateTime? dateStart,
    DateTime? dateEnd,
    String? paymentMethod,
  }) {
    final key = _listKey(
      page: page,
      perPage: perPage,
      search: search,
      status: status,
      dateStart: dateStart,
      dateEnd: dateEnd,
      paymentMethod: paymentMethod,
    );

    final existing = _inFlightLists[key];
    if (existing != null) {
      return existing;
    }

    final future = _fetchOrders(
      page: page,
      perPage: perPage,
      search: search,
      status: status,
      dateStart: dateStart,
      dateEnd: dateEnd,
      paymentMethod: paymentMethod,
    );

    _inFlightLists[key] = future;
    future.whenComplete(() => _inFlightLists.remove(key));
    return future;
  }

  Future<List<Order>> _fetchOrders({
    required int page,
    required int perPage,
    String? search,
    String? status,
    DateTime? dateStart,
    DateTime? dateEnd,
    String? paymentMethod,
  }) async {
    final params = {
      'page': page,
      'per_page': perPage,
      if (search != null && search.isNotEmpty) 'search': search,
      if (status != null && status.isNotEmpty) 'status': status,
      if (dateStart != null) 'after': dateStart.toIso8601String(),
      if (dateEnd != null) 'before': dateEnd.toIso8601String(),
      if (paymentMethod != null && paymentMethod.isNotEmpty)
        'payment_method': paymentMethod,
    };

    final response = await _api.wcGet(
      '/wp-json/wc/v3/orders',
      queryParameters: params,
    );
    return (response.data as List).map((e) => Order.fromJson(e)).toList();
  }

  Future<Order> fetchOrder(int id) {
    final existing = _inFlightOrders[id];
    if (existing != null) {
      return existing;
    }

    final future = _fetchOrder(id);
    _inFlightOrders[id] = future;
    future.whenComplete(() => _inFlightOrders.remove(id));
    return future;
  }

  Future<Order> _fetchOrder(int id) async {
    final response = await _api.wcGet('/wp-json/wc/v3/orders/$id');
    return Order.fromJson(response.data);
  }

  Future<Order> updateOrderStatus(int id, String status) async {
    final response = await _api.wcPut(
      '/wp-json/wc/v3/orders/$id',
      data: {'status': status},
    );
    return Order.fromJson(response.data);
  }

  Future<List<OrderNote>> fetchOrderNotes(int orderId) {
    final existing = _inFlightNotes[orderId];
    if (existing != null) {
      return existing;
    }

    final future = _fetchOrderNotes(orderId);
    _inFlightNotes[orderId] = future;
    future.whenComplete(() => _inFlightNotes.remove(orderId));
    return future;
  }

  Future<List<OrderNote>> _fetchOrderNotes(int orderId) async {
    final response =
        await _api.wcGet('/wp-json/wc/v3/orders/$orderId/notes');
    return (response.data as List)
        .map((e) => OrderNote.fromJson(e))
        .toList();
  }

  Future<OrderNote> addOrderNote(int orderId, String note) async {
    final response = await _api.wcPost(
      '/wp-json/wc/v3/orders/$orderId/notes',
      data: {
        'note': note,
        'customer_note': false,
      },
    );
    return OrderNote.fromJson(response.data);
  }

  Future<Customer> fetchCustomer(int customerId) {
    final existing = _inFlightCustomers[customerId];
    if (existing != null) {
      return existing;
    }

    final future = _fetchCustomer(customerId);
    _inFlightCustomers[customerId] = future;
    future.whenComplete(() => _inFlightCustomers.remove(customerId));
    return future;
  }

  Future<Customer> _fetchCustomer(int customerId) async {
    final response =
        await _api.wcGet('/wp-json/wc/v3/customers/$customerId');
    return Customer.fromJson(response.data);
  }

  Future<Order> updateOrderMetaData(
    int orderId,
    Map<String, dynamic> metaData,
  ) async {
    final response = await _api.wcPut(
      '/wp-json/wc/v3/orders/$orderId',
      data: {
        'meta_data': metaData.entries
            .map((e) => {
                  'key': e.key,
                  'value': e.value,
                })
            .toList(),
      },
    );
    return Order.fromJson(response.data);
  }
}
