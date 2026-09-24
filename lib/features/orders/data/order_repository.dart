// lib/features/orders/data/order_repository.dart

import '../../../core/network/api_client.dart';
import 'order_models.dart';

class OrderRepository {
  final ApiClient _api;

  OrderRepository(this._api);

  Future<List<Order>> fetchOrders({
    int page = 1,
    int perPage = 10,
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
      if (paymentMethod != null && paymentMethod.isNotEmpty) 'payment_method': paymentMethod,
    };

    final response = await _api.wcGet('/wp-json/wc/v3/orders', queryParameters: params);
    return (response.data as List).map((e) => Order.fromJson(e)).toList();
  }

  Future<Order> fetchOrder(int id) async {
    final response = await _api.wcGet('/wp-json/wc/v3/orders/$id');
    return Order.fromJson(response.data);
  }

  Future<Order> updateOrderStatus(int id, String status) async {
    final response = await _api.wcPut('/wp-json/wc/v3/orders/$id', data: {'status': status});
    return Order.fromJson(response.data);
  }

  Future<List<OrderNote>> fetchOrderNotes(int orderId) async {
    final response = await _api.wcGet('/wp-json/wc/v3/orders/$orderId/notes');
    return (response.data as List).map((e) => OrderNote.fromJson(e)).toList();
  }

  Future<OrderNote> addOrderNote(int orderId, String note) async {
    final response = await _api.wcPost('/wp-json/wc/v3/orders/$orderId/notes', data: {
      'note': note,
      'customer_note': false,
    });
    return OrderNote.fromJson(response.data);
  }

  // ===== متد جدید: دریافت اطلاعات مشتری =====
  Future<Customer> fetchCustomer(int customerId) async {
    final response = await _api.wcGet('/wp-json/wc/v3/customers/$customerId');
    return Customer.fromJson(response.data);
  }

  // ===== متد جدید: بروزرسانی متادیتای سفارش =====
  Future<Order> updateOrderMetaData(int orderId, Map<String, dynamic> metaData) async {
    final response = await _api.wcPut('/wp-json/wc/v3/orders/$orderId', data: {
      'meta_data': metaData.entries.map((e) => {
        'key': e.key,
        'value': e.value,
      }).toList(),
    });
    return Order.fromJson(response.data);
  }
}