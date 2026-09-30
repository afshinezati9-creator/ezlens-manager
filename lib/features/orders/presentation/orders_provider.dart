// lib/features/orders/presentation/orders_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/providers.dart';
import '../data/order_models.dart';
import '../data/order_repository.dart';

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  return OrderRepository(api);
});

// ===== Stateهای لیست سفارشات =====
final ordersPageProvider = StateProvider<int>((ref) => 1);
final ordersPerPageProvider = StateProvider<int>((ref) => 10);
final ordersSearchProvider = StateProvider<String>((ref) => '');
final ordersStatusProvider = StateProvider<String?>((ref) => null);
final ordersDateStartProvider = StateProvider<DateTime?>((ref) => null);
final ordersDateEndProvider = StateProvider<DateTime?>((ref) => null);
final ordersPaymentMethodProvider = StateProvider<String?>((ref) => null);

final ordersProvider = FutureProvider.autoDispose((ref) async {
  final repo = ref.watch(orderRepositoryProvider);
  final page = ref.watch(ordersPageProvider);
  final perPage = ref.watch(ordersPerPageProvider);
  final search = ref.watch(ordersSearchProvider);
  final status = ref.watch(ordersStatusProvider);
  final dateStart = ref.watch(ordersDateStartProvider);
  final dateEnd = ref.watch(ordersDateEndProvider);
  final paymentMethod = ref.watch(ordersPaymentMethodProvider);

  return repo.fetchOrders(
    page: page,
    perPage: perPage,
    search: search.isNotEmpty ? search : null,
    status: status,
    dateStart: dateStart,
    dateEnd: dateEnd,
    paymentMethod: paymentMethod,
  );
});

// ===== Providerهای جزئیات سفارش =====
final orderDetailProvider = FutureProvider.autoDispose.family<Order, int>((ref, id) async {
  final repo = ref.watch(orderRepositoryProvider);
  return repo.fetchOrder(id);
});

final orderNotesProvider = FutureProvider.autoDispose.family<List<OrderNote>, int>((ref, orderId) async {
  final repo = ref.watch(orderRepositoryProvider);
  final allNotes = await repo.fetchOrderNotes(orderId);
  return allNotes.where((n) => !n.customerNote).toList();
});

// ===== Provider جدید: سابقه مشتری =====
final customerProvider = FutureProvider.autoDispose.family<Customer, int>((ref, customerId) async {
  final repo = ref.watch(orderRepositoryProvider);
  return repo.fetchCustomer(customerId);
});

// ===== Provider جدید: بروزرسانی متادیتا =====
final orderMetaUpdateProvider = FutureProvider.family<Order, ({int orderId, Map<String, dynamic> metaData})>((ref, params) async {
  final repo = ref.watch(orderRepositoryProvider);
  return repo.updateOrderMetaData(params.orderId, params.metaData);
});