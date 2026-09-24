// lib/features/orders/presentation/orders_list_page.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_error_state.dart';
import '../data/order_models.dart';
import 'orders_provider.dart';

// ============================================================
// Helpers
// ============================================================

String _toFa(num value) {
  const fa = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
  return value.toString().split('').map((d) => fa[int.parse(d)]).join();
}

String _formatPrice(String price) {
  final n = double.tryParse(price) ?? 0;
  return n.toInt().toString().replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]},',
  ) + ' تومان';
}

/// تبدیل تاریخ میلادی به شمسی با استفاده از Jalali
String _toPersianDate(DateTime date) {
  final jalali = Jalali.fromDateTime(date);
  return '${jalali.year}/${jalali.month.toString().padLeft(2, '0')}/${jalali.day.toString().padLeft(2, '0')}';
}


Widget _walletBadge() {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: const Color(0xFF031F8A).withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: const Color(0xFF031F8A).withOpacity(0.35)),
    ),
    child: const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.account_balance_wallet_outlined, size: 14, color: Color(0xFF031F8A)),
        SizedBox(width: 4),
        Text(
          'شارژ کیف پول',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xFF031F8A),
          ),
        ),
      ],
    ),
  );
}


class OrderStatusBadge extends StatelessWidget {
  final String status;
  const OrderStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final map = {
      'pending': ('در انتظار', AppTheme.warningBg, AppTheme.warning),
      'processing': ('در حال پردازش', AppTheme.infoBg, AppTheme.info),
      'completed': ('تکمیل شده', AppTheme.successBg, AppTheme.success),
      'cancelled': ('لغو شده', AppTheme.dangerBg, AppTheme.danger),
      'refunded': ('بازگشت وجه', Colors.purple.shade50, Colors.purple.shade700),
      'failed': ('ناموفق', AppTheme.dangerBg, AppTheme.danger),
      'on-hold': ('در انتظار', AppTheme.warningBg, AppTheme.warning),
    };
    final data = map[status] ?? ('ناشناخته', AppTheme.surfaceHover, AppTheme.textSecondary);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: data.$2,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        data.$1,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: data.$3),
      ),
    );
  }
}

// ============================================================
// Main Page
// ============================================================

class OrdersListPage extends ConsumerStatefulWidget {
  const OrdersListPage({super.key});

  @override
  ConsumerState<OrdersListPage> createState() => _OrdersListPageState();
}

class _OrdersListPageState extends ConsumerState<OrdersListPage> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  String? _statusFilter;
  String? _paymentMethodFilter;
  DateTime? _dateStart;
  DateTime? _dateEnd;
  int _perPage = 10;

  final List<String> _paymentMethods = [
    'همه',
    'پرداخت امن زرین‌پال',
    'کارت به کارت',
    'پرداخت در محل',
    'دیگر',
  ];

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      ref.read(ordersSearchProvider.notifier).state = value;
      ref.read(ordersPageProvider.notifier).state = 1;
      ref.invalidate(ordersProvider);
    });
  }

  void _onStatusChanged(String? value) {
    setState(() => _statusFilter = value);
    ref.read(ordersStatusProvider.notifier).state = value;
    ref.read(ordersPageProvider.notifier).state = 1;
    ref.invalidate(ordersProvider);
  }

  void _onPaymentMethodChanged(String? value) {
    setState(() => _paymentMethodFilter = value == 'همه' ? null : value);
    ref.read(ordersPaymentMethodProvider.notifier).state = value == 'همه' ? null : value;
    ref.read(ordersPageProvider.notifier).state = 1;
    ref.invalidate(ordersProvider);
  }

  void _onPerPageChanged(int value) {
    setState(() => _perPage = value);
    ref.read(ordersPerPageProvider.notifier).state = value;
    ref.read(ordersPageProvider.notifier).state = 1;
    ref.invalidate(ordersProvider);
  }

  // ===== انتخاب تاریخ شروع =====
  Future<void> _selectStartDate() async {
    final now = DateTime.now();
    final initial = _dateStart ?? now.subtract(const Duration(days: 30));
    final picked = await showPersianDatePicker(
      context: context,
      initialDate: Jalali.fromDateTime(initial),
      firstDate: Jalali(1400, 1, 1),
      lastDate: Jalali(1410, 12, 29),
    );
    if (picked != null) {
      setState(() {
        _dateStart = picked.toDateTime();
        if (_dateEnd != null && _dateEnd!.isBefore(_dateStart!)) {
          _dateEnd = _dateStart;
        }
      });
      _updateDateFilters();
    }
  }

  // ===== انتخاب تاریخ پایان =====
  Future<void> _selectEndDate() async {
    final now = DateTime.now();
    final initial = _dateEnd ?? now;
    final picked = await showPersianDatePicker(
      context: context,
      initialDate: Jalali.fromDateTime(initial),
      firstDate: Jalali(1400, 1, 1),
      lastDate: Jalali(1410, 12, 29),
    );
    if (picked != null) {
      setState(() {
        _dateEnd = picked.toDateTime();
        if (_dateStart != null && _dateStart!.isAfter(_dateEnd!)) {
          _dateStart = _dateEnd;
        }
      });
      _updateDateFilters();
    }
  }

  void _updateDateFilters() {
    ref.read(ordersDateStartProvider.notifier).state = _dateStart;
    ref.read(ordersDateEndProvider.notifier).state = _dateEnd;
    ref.read(ordersPageProvider.notifier).state = 1;
    ref.invalidate(ordersProvider);
  }

  void _clearDateFilter() {
    setState(() {
      _dateStart = null;
      _dateEnd = null;
    });
    ref.read(ordersDateStartProvider.notifier).state = null;
    ref.read(ordersDateEndProvider.notifier).state = null;
    ref.read(ordersPageProvider.notifier).state = 1;
    ref.invalidate(ordersProvider);
  }

  String _getDateRangeLabel() {
    if (_dateStart == null && _dateEnd == null) return 'همه بازه';
    final start = _dateStart != null ? _toPersianDate(_dateStart!) : 'نامشخص';
    final end = _dateEnd != null ? _toPersianDate(_dateEnd!) : 'نامشخص';
    return '$start تا $end';
  }

  void _goToOrder(int id) {
    context.go('/orders/$id');
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(ordersProvider);
    final currentPage = ref.watch(ordersPageProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('سفارشات'),
        centerTitle: true,
        backgroundColor: AppTheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(ordersProvider),
            tooltip: 'به‌روزرسانی',
          ),
        ],
      ),
      body: Column(
        children: [
          // ============================================================
          // پنل فیلترها
          // ============================================================
          Container(
            color: AppTheme.surface,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // جستجو
                TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'جستجوی سفارش (شماره، مشتری، تلفن)...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppTheme.border),
                    ),
                    filled: true,
                    fillColor: AppTheme.background,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(height: 12),

                // ردیف اول فیلترها
                isTablet
                    ? Row(
                        children: [
                          Expanded(child: _buildStatusDropdown()),
                          const SizedBox(width: 12),
                          Expanded(child: _buildPaymentMethodDropdown()),
                        ],
                      )
                    : Column(
                        children: [
                          _buildStatusDropdown(),
                          const SizedBox(height: 10),
                          _buildPaymentMethodDropdown(),
                        ],
                      ),
                const SizedBox(height: 10),

                // ردیف دوم فیلترها (تاریخ و تعداد)
                isTablet
                    ? Row(
                        children: [
                          Expanded(child: _buildDateFilterButton()),
                          const SizedBox(width: 12),
                          Expanded(child: _buildPerPageDropdown()),
                        ],
                      )
                    : Column(
                        children: [
                          _buildDateFilterButton(),
                          const SizedBox(height: 10),
                          _buildPerPageDropdown(),
                        ],
                      ),
              ],
            ),
          ),

          // ============================================================
          // لیست سفارشات
          // ============================================================
          Expanded(
            child: ordersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
              error: (err, _) => Center(
                child: AppErrorState(
                  title: 'خطا در دریافت سفارشات',
                  subtitle: err.toString(),
                  onRetry: () => ref.invalidate(ordersProvider),
                ),
              ),
              data: (orders) {
                if (orders.isEmpty) {
                  return AppEmptyState(
                    icon: Icons.receipt_outlined,
                    title: 'سفارشی یافت نشد',
                    subtitle: 'با تغییر فیلترها یا جستجو مجدد امتحان کنید.',
                  );
                }

                final cardPadding = isTablet ? 20.0 : 16.0;
                final textSize = isTablet ? 18.0 : 15.0;
                final subTextSize = isTablet ? 15.0 : 13.0;

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final o = orders[index];
                    final hasPhone = o.billing.phone.isNotEmpty;

                    return GestureDetector(
                      onTap: () => _goToOrder(o.id),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: EdgeInsets.all(cardPadding),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.border.withOpacity(0.5)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ردیف اول: شماره سفارش، نام مشتری، وضعیت
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '#${o.orderNumber} — ${o.customerName}',
                                        style: TextStyle(
                                          fontSize: textSize,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.textPrimary,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (o.isWalletTopup) ...[
                                        const SizedBox(height: 6),
                                        _walletBadge(),
                                      ],
                                      if (hasPhone) ...[
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            Icon(Icons.call_outlined, size: isTablet ? 16 : 14, color: AppTheme.textSecondary),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                o.billing.phone,
                                                style: TextStyle(
                                                  fontSize: subTextSize,
                                                  color: AppTheme.textSecondary,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                textDirection: TextDirection.ltr,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                OrderStatusBadge(status: o.status),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // ردیف دوم: تاریخ شمسی + روش پرداخت
                            Row(
                              children: [
                                Icon(Icons.calendar_today_outlined, size: isTablet ? 16 : 14, color: AppTheme.textMuted),
                                const SizedBox(width: 4),
                                Text(
                                  _toPersianDate(o.dateCreated),
                                  style: TextStyle(fontSize: subTextSize, color: AppTheme.textSecondary),
                                ),
                                const SizedBox(width: 16),
                                Icon(Icons.payment_outlined, size: isTablet ? 16 : 14, color: AppTheme.textMuted),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    o.paymentMethodTitle,
                                    style: TextStyle(fontSize: subTextSize, color: AppTheme.textSecondary),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // ردیف سوم: تعداد اقلام + مبلغ نهایی
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.surfaceHover,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${_toFa(o.lineItems.length)} قلم',
                                    style: TextStyle(fontSize: subTextSize, color: AppTheme.textSecondary),
                                  ),
                                ),
                                Text(
                                  _formatPrice(o.total),
                                  style: TextStyle(
                                    fontSize: isTablet ? 20 : 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // ============================================================
          // صفحه‌بندی
          // ============================================================
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            color: AppTheme.surface,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () {
                    ref.read(ordersPageProvider.notifier).state++;
                    ref.invalidate(ordersProvider);
                  },
                  icon: const Icon(Icons.chevron_left, size: 28),
                  splashRadius: 24,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'صفحه ${_toFa(currentPage)}',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.primary),
                  ),
                ),
                IconButton(
                  onPressed: currentPage > 1
                      ? () {
                          ref.read(ordersPageProvider.notifier).state--;
                          ref.invalidate(ordersProvider);
                        }
                      : null,
                  icon: const Icon(Icons.chevron_right, size: 28),
                  splashRadius: 24,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ویجت‌های کمکی
  // ============================================================

  Widget _buildStatusDropdown() {
    return DropdownButtonFormField<String?>(
      value: _statusFilter,
      decoration: InputDecoration(
        labelText: 'وضعیت',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppTheme.border),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        filled: true,
        fillColor: AppTheme.background,
      ),
      items: const [
        DropdownMenuItem(value: null, child: Text('همه وضعیت‌ها')),
        DropdownMenuItem(value: 'pending', child: Text('در انتظار')),
        DropdownMenuItem(value: 'processing', child: Text('در حال پردازش')),
        DropdownMenuItem(value: 'completed', child: Text('تکمیل شده')),
        DropdownMenuItem(value: 'cancelled', child: Text('لغو شده')),
        DropdownMenuItem(value: 'refunded', child: Text('بازگشت وجه')),
        DropdownMenuItem(value: 'failed', child: Text('ناموفق')),
        DropdownMenuItem(value: 'on-hold', child: Text('در انتظار بررسی')),
      ],
      onChanged: _onStatusChanged,
      isDense: true,
    );
  }

  Widget _buildPaymentMethodDropdown() {
    return DropdownButtonFormField<String>(
      value: _paymentMethodFilter ?? 'همه',
      decoration: InputDecoration(
        labelText: 'روش پرداخت',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppTheme.border),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        filled: true,
        fillColor: AppTheme.background,
      ),
      items: _paymentMethods.map((method) {
        return DropdownMenuItem(value: method, child: Text(method));
      }).toList(),
      onChanged: _onPaymentMethodChanged,
      isDense: true,
    );
  }

  Widget _buildDateFilterButton() {
    return OutlinedButton(
      onPressed: () async {
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('فیلتر تاریخ شمسی'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: Text('از تاریخ: ${_dateStart != null ? _toPersianDate(_dateStart!) : 'انتخاب نشده'}'),
                  trailing: const Icon(Icons.calendar_today, color: AppTheme.primary),
                  onTap: () {
                    Navigator.pop(ctx);
                    _selectStartDate();
                  },
                ),
                ListTile(
                  title: Text('تا تاریخ: ${_dateEnd != null ? _toPersianDate(_dateEnd!) : 'انتخاب نشده'}'),
                  trailing: const Icon(Icons.calendar_today, color: AppTheme.primary),
                  onTap: () {
                    Navigator.pop(ctx);
                    _selectEndDate();
                  },
                ),
                if (_dateStart != null || _dateEnd != null)
                  TextButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _clearDateFilter();
                    },
                    child: const Text('حذف فیلتر تاریخ', style: TextStyle(color: AppTheme.danger)),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('بستن'),
              ),
            ],
          ),
        );
      },
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        side: const BorderSide(color: AppTheme.border),
        backgroundColor: AppTheme.background,
        foregroundColor: AppTheme.textPrimary,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              _getDateRangeLabel(),
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13),
            ),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.calendar_today_outlined, size: 18, color: AppTheme.primary),
              if (_dateStart != null || _dateEnd != null) ...[
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: _clearDateFilter,
                  child: const Icon(Icons.close, size: 16, color: AppTheme.danger),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPerPageDropdown() {
    return DropdownButtonFormField<int>(
      value: _perPage,
      decoration: InputDecoration(
        labelText: 'تعداد در صفحه',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppTheme.border),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        filled: true,
        fillColor: AppTheme.background,
      ),
      items: const [
        DropdownMenuItem(value: 5, child: Text('۵')),
        DropdownMenuItem(value: 10, child: Text('۱۰')),
        DropdownMenuItem(value: 20, child: Text('۲۰')),
        DropdownMenuItem(value: 50, child: Text('۵۰')),
      ],
      onChanged: (v) => _onPerPageChanged(v!),
      isDense: true,
    );
  }
}