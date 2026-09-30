import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProductSummary {
  final int id;
  final String name;
  final int sales;
  const ProductSummary({required this.id, required this.name, required this.sales});
}

class OrderSummary {
  final int id;
  final String customer;
  final double amount;
  const OrderSummary({required this.id, required this.customer, required this.amount});
}

class DashboardData {
  final int totalProducts;
  final int totalOrders;
  final int totalUsers;
  final int totalMedia;
  final int totalComments;
  final int totalRequests;
  final int totalNotes;
  final double totalRevenue;
  final double dailyRevenue;
  final double monthlyRevenue;
  final int visitsToday;
  final int visitsMonth;
  final int visitsAll;
  final List<ProductSummary> latestProducts;
  final List<ProductSummary> topProducts;
  final List<OrderSummary> recentOrders;

  const DashboardData({
    required this.totalProducts,
    required this.totalOrders,
    required this.totalUsers,
    required this.totalMedia,
    required this.totalComments,
    required this.totalRequests,
    required this.totalNotes,
    required this.totalRevenue,
    required this.dailyRevenue,
    required this.monthlyRevenue,
    required this.visitsToday,
    required this.visitsMonth,
    required this.visitsAll,
    required this.latestProducts,
    required this.topProducts,
    required this.recentOrders,
  });
}

final dashboardProvider = FutureProvider<DashboardData>((ref) async {
  await Future.delayed(const Duration(milliseconds: 700));
  
  return const DashboardData(
    totalProducts: 56,
    totalOrders: 142,
    totalUsers: 89,
    totalMedia: 210,
    totalComments: 34,
    totalRequests: 12,
    totalNotes: 7,
    totalRevenue: 12500000,
    dailyRevenue: 850000,
    monthlyRevenue: 4200000,
    visitsToday: 320,
    visitsMonth: 9800,
    visitsAll: 45000,
    latestProducts: [
      ProductSummary(id: 1, name: 'لنز طبی 1.5', sales: 45),
      ProductSummary(id: 2, name: 'محلول لنز 500ml', sales: 32),
      ProductSummary(id: 3, name: 'عینک آفتابی RayBan', sales: 18),
    ],
    topProducts: [
      ProductSummary(id: 4, name: 'لنز هارد RGP', sales: 60),
      ProductSummary(id: 5, name: 'قطره اشک مصنوعی', sales: 40),
      ProductSummary(id: 6, name: 'دستگاه شستشوی لنز', sales: 25),
    ],
    recentOrders: [
      OrderSummary(id: 1042, customer: 'علی رضایی', amount: 450000),
      OrderSummary(id: 1041, customer: 'مریم احمدی', amount: 1200000),
      OrderSummary(id: 1040, customer: 'حسین کریمی', amount: 850000),
    ],
  );
});