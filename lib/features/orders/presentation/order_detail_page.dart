// lib/features/orders/presentation/order_detail_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../core/widgets/app_error_state.dart';
import '../data/order_models.dart';
import 'orders_provider.dart';
import 'widgets/order_detail_widgets.dart';

// ============================================================
// Helpers
// ============================================================

String _toPersianDate(DateTime date) {
  final jalali = Jalali.fromDateTime(date);
  return '${jalali.year}/${jalali.month.toString().padLeft(2, '0')}/${jalali.day.toString().padLeft(2, '0')}';
}

String _formatPrice(String price) {
  final n = double.tryParse(price) ?? 0;
  return n.toInt().toString().replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]},',
  ) + ' تومان';
}

// ============================================================
// Main Page
// ============================================================

class OrderDetailPage extends ConsumerStatefulWidget {
  final int orderId;
  const OrderDetailPage({super.key, required this.orderId});

  @override
  ConsumerState<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends ConsumerState<OrderDetailPage> {
  final TextEditingController _noteController = TextEditingController();
  bool _updatingStatus = false;
  bool _submittingNote = false;

  Future<void> _updateStatus(Order order, String newStatus) async {
    if (newStatus == order.status) return;
    setState(() => _updatingStatus = true);
    try {
      final repo = ref.read(orderRepositoryProvider);
      await repo.updateOrderStatus(order.id, newStatus);
      ref.invalidate(orderDetailProvider(order.id));
      ref.invalidate(orderNotesProvider(order.id));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('وضعیت سفارش به‌روز شد')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا: $e')),
      );
    } finally {
      if (mounted) setState(() => _updatingStatus = false);
    }
  }

  Future<void> _addNote(int orderId) async {
    if (_noteController.text.trim().isEmpty) return;
    setState(() => _submittingNote = true);
    try {
      final repo = ref.read(orderRepositoryProvider);
      await repo.addOrderNote(orderId, _noteController.text.trim());
      _noteController.clear();
      ref.invalidate(orderNotesProvider(orderId));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('یادداشت ثبت شد')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا: $e')),
      );
    } finally {
      if (mounted) setState(() => _submittingNote = false);
    }
  }

  Future<void> _updateTrackingCode(int orderId, String code) async {
    try {
      final repo = ref.read(orderRepositoryProvider);
      await repo.updateOrderMetaData(orderId, {'_tracking_code': code});
      ref.invalidate(orderDetailProvider(orderId));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('کد رهگیری ذخیره شد')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا در ذخیره کد رهگیری: $e')),
      );
    }
  }

  Future<void> _openPaymentUrl(String? orderKey) async {
    if (orderKey == null) return;
    final url = 'https://ezlens.ir/checkout/order-pay/${widget.orderId}/?pay_for_order=true&key=$orderKey';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  /// تبدیل List<OrderMetaData> به Map<String, dynamic>
  Map<String, dynamic>? _metaDataToMap(List<OrderMetaData>? metaDataList) {
    if (metaDataList == null) return null;
    return metaDataList.fold<Map<String, dynamic>>({}, (map, item) {
      map[item.key] = item.value;
      return map;
    });
  }

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(orderDetailProvider(widget.orderId));
    final notesAsync = ref.watch(orderNotesProvider(widget.orderId));

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('جزئیات سفارش'),
        centerTitle: true,
        backgroundColor: AppTheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/orders'),
        ),
      ),
      body: orderAsync.when(
        loading: () => const AppLoading(),
        error: (err, _) => Center(
          child: AppErrorState(
            title: 'خطا در دریافت سفارش',
            subtitle: err.toString(),
            onRetry: () => ref.invalidate(orderDetailProvider(widget.orderId)),
          ),
        ),
        data: (order) {
          // ===== دریافت سابقه مشتری =====
          final customerAsync = order.customerId != null && order.customerId! > 0
              ? ref.watch(customerProvider(order.customerId!))
              : null;

          // ===== تبدیل متادیتا به مپ =====
          final metaMap = _metaDataToMap(order.metaData);

          final screenWidth = MediaQuery.of(context).size.width;
          final isTablet = screenWidth > 600;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ============================================================
                // بخش ۱: هدر
                // ============================================================
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '#${order.orderNumber}',
                                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.calendar_today_outlined, size: 14, color: AppTheme.textMuted),
                                    const SizedBox(width: 4),
                                    Text(
                                      _toPersianDate(order.dateCreated),
                                      style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          OrderStatusBadgeLarge(status: order.status),
                        ],
                      ),
                      const SizedBox(height: 12),
                      StatusQuickActions(
                        currentStatus: order.status,
                        onStatusChange: (newStatus) => _updateStatus(order, newStatus),
                      ),
                      if (order.status == 'pending' && order.orderKey != null) ...[
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () => _openPaymentUrl(order.orderKey),
                          icon: const Icon(Icons.payment),
                          label: const Text('لینک پرداخت مستقیم'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.cta,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ============================================================
                // برچسب شارژ کیف پول
                // ============================================================
                if (order.isWalletTopup) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF031F8A).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF031F8A).withOpacity(0.25)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.account_balance_wallet_outlined, color: Color(0xFF031F8A)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'این سفارش از بخش کیف پول است',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF031F8A),
                                ),
                              ),
                              Text(
                                order.walletTopupAmount != null
                                    ? 'درخواست شارژ کیف پول — مبلغ: ${order.walletTopupAmount} تومان'
                                    : 'درخواست شارژ کیف پول (داشبورد مشتری)',
                                style: const TextStyle(fontSize: 12, color: Color(0xFF334155)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // ============================================================
                // بخش ۲: اطلاعات مشتری
                // ============================================================
                const Text(
                  'اطلاعات مشتری',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (isTablet)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: CustomerInfoCard(address: order.billing, title: '🛒 صورتحساب'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomerInfoCard(address: order.shipping, title: '📦 ارسال'),
                      ),
                    ],
                  )
                else
                  Column(
                    children: [
                      CustomerInfoCard(address: order.billing, title: '🛒 صورتحساب'),
                      const SizedBox(height: 8),
                      CustomerInfoCard(address: order.shipping, title: '📦 ارسال'),
                    ],
                  ),
                const SizedBox(height: 16),

                // ============================================================
                // بخش ۳: سابقه مشتری
                // ============================================================
                if (customerAsync != null)
                  customerAsync.when(
                    loading: () => const CustomerHistoryCard(isLoading: true),
                    error: (err, _) => CustomerHistoryCard(error: err.toString()),
                    data: (customer) => CustomerHistoryCard(customer: customer),
                  ),
                const SizedBox(height: 16),

                // ============================================================
                // بخش ۴: اقلام سفارش
                // ============================================================
                const Text(
                  'اقلام سفارش',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      ...order.lineItems.map((item) => Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          border: Border(bottom: BorderSide(color: AppTheme.border.withOpacity(0.3))),
                        ),
                        child: Row(
                          children: [
                            if (item.imageUrl != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(item.imageUrl!, width: 50, height: 50, fit: BoxFit.cover),
                              )
                            else
                              Container(width: 50, height: 50, color: AppTheme.border, child: const Icon(Icons.image, color: Colors.grey)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => context.go('/products/${item.productId}'),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      style: const TextStyle(fontWeight: FontWeight.w500),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 2,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${item.quantity} × ${_formatPrice(item.price)}',
                                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                    ),
                                    if (item.sku != null)
                                      Text('SKU: ${item.sku}', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                                  ],
                                ),
                              ),
                            ),
                            Text(
                              _formatPrice(item.total),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      )),
                      const SizedBox(height: 12),
                      OrderTotalsCard(
                        subtotal: order.subtotal,
                        shippingTotal: order.shippingTotal,
                        totalTax: order.totalTax,
                        discountTotal: order.discountTotal,
                        total: order.total,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ============================================================
                // بخش ۵: کد رهگیری (با متادیتای تبدیل‌شده)
                // ============================================================
                TrackingCodeCard(
                  orderId: order.id,
                  metaData: metaMap,
                  onTrackingCodeUpdated: (code) => _updateTrackingCode(order.id, code),
                ),
                const SizedBox(height: 16),

                // ============================================================
                // بخش ۶: فایل پیوست (با متادیتای تبدیل‌شده)
                // ============================================================
                AttachmentCard(metaData: metaMap),
                const SizedBox(height: 16),

                // ============================================================
                // بخش ۷: یادداشت‌های داخلی
                // ============================================================
                const Text(
                  'یادداشت‌های داخلی',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  'خصوصی - فقط برای تیم مدیریت',
                  style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      notesAsync.when(
                        loading: () => const AppLoading(message: 'بارگذاری یادداشت‌ها...'),
                        error: (err, _) => Text('خطا: $err', style: const TextStyle(color: AppTheme.danger)),
                        data: (notes) {
                          if (notes.isEmpty) {
                            return const Text(
                              'هنوز یادداشتی ثبت نشده است.',
                              style: TextStyle(color: AppTheme.textSecondary),
                            );
                          }
                          return ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: notes.length,
                            separatorBuilder: (_, __) => const Divider(),
                            itemBuilder: (_, i) {
                              final n = notes[i];
                              return ListTile(
                                title: Text(n.note, style: const TextStyle(fontSize: 14)),
                                subtitle: Text(
                                  '${n.author} · ${_toPersianDate(n.dateCreated)}',
                                  style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                                ),
                                contentPadding: EdgeInsets.zero,
                              );
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _noteController,
                              decoration: const InputDecoration(
                                hintText: 'یادداشت جدید...',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _submittingNote ? null : () => _addNote(order.id),
                            child: _submittingNote
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Text('ثبت'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }
}