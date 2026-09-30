// lib/features/orders/presentation/widgets/order_detail_widgets.dart

import 'package:flutter/material.dart';
import 'package:ezlens_manager/core/theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/order_models.dart';

// ============================================================
// ویجت‌های موجود
// ============================================================

class OrderStatusBadgeLarge extends StatelessWidget {
  final String status;
  const OrderStatusBadgeLarge({super.key, required this.status});

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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: data.$2,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        data.$1,
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: data.$3),
      ),
    );
  }
}

// ============================================================
// ✅ اصلاح: CustomerInfoCard (رفع const SizedBox)
// ============================================================

class CustomerInfoCard extends StatelessWidget {
  final OrderAddress address;
  final String title;
  const CustomerInfoCard({super.key, required this.address, required this.title});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    final paddingValue = isMobile ? 20.0 : 16.0;
    final titleFontSize = isMobile ? 16.0 : 13.0;
    final nameFontSize = isMobile ? 18.0 : 15.0;
    final infoFontSize = isMobile ? 15.0 : 13.0;
    final addressFontSize = isMobile ? 14.0 : 13.0;

    return Container(
      padding: EdgeInsets.all(paddingValue),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
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
          Row(
            children: [
              Icon(
                title.contains('صورتحساب') ? Icons.receipt_outlined : Icons.local_shipping_outlined,
                size: isMobile ? 22 : 18,
                color: AppTheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: titleFontSize,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          // ===== حذف const از SizedBoxهای دارای مقدار متغیر =====
          SizedBox(height: isMobile ? 12 : 8),
          Text(
            address.fullName,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: nameFontSize,
              color: AppTheme.textPrimary,
            ),
          ),
          SizedBox(height: isMobile ? 6 : 4),
          if (address.phone.isNotEmpty)
            Row(
              children: [
                Icon(Icons.phone_outlined, size: isMobile ? 18 : 14, color: AppTheme.textSecondary),
                const SizedBox(width: 6),
                Text(
                  address.phone,
                  style: TextStyle(fontSize: infoFontSize, color: AppTheme.textPrimary),
                ),
              ],
            ),
          if (address.email.isNotEmpty)
            Row(
              children: [
                Icon(Icons.email_outlined, size: isMobile ? 18 : 14, color: AppTheme.textSecondary),
                const SizedBox(width: 6),
                Text(
                  address.email,
                  style: TextStyle(fontSize: infoFontSize, color: AppTheme.textPrimary),
                ),
              ],
            ),
          if (address.fullAddress.isNotEmpty) ...[
            SizedBox(height: isMobile ? 8 : 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.location_on_outlined, size: isMobile ? 18 : 14, color: AppTheme.textSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    address.fullAddress,
                    style: TextStyle(fontSize: addressFontSize, color: AppTheme.textSecondary),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================
// بقیه ویجت‌ها (با رفع const در SizedBoxهای متغیر)
// ============================================================

class OrderTotalsCard extends StatelessWidget {
  final String subtotal;
  final String shippingTotal;
  final String totalTax;
  final String discountTotal;
  final String total;

  const OrderTotalsCard({
    super.key,
    required this.subtotal,
    required this.shippingTotal,
    required this.totalTax,
    required this.discountTotal,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final paddingValue = isMobile ? 20.0 : 16.0;
    final fontSize = isMobile ? 15.0 : 13.0;
    final totalFontSize = isMobile ? 18.0 : 16.0;

    return Container(
      padding: EdgeInsets.all(paddingValue),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _totalRow('جمع جزء', subtotal, fontSize: fontSize),
          _totalRow('هزینه ارسال', shippingTotal, fontSize: fontSize),
          _totalRow('مالیات', totalTax, fontSize: fontSize),
          if (double.tryParse(discountTotal) != null && double.parse(discountTotal) > 0)
            _totalRow('تخفیف', '-$discountTotal', isDiscount: true, fontSize: fontSize),
          const Divider(thickness: 1.5),
          _totalRow('مبلغ نهایی', total, isTotal: true, fontSize: totalFontSize),
        ],
      ),
    );
  }

  Widget _totalRow(
    String label,
    String value, {
    bool isTotal = false,
    bool isDiscount = false,
    double fontSize = 13,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            _formatPrice(value),
            style: TextStyle(
              fontSize: isTotal ? fontSize + 2 : fontSize,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isDiscount ? AppTheme.success : (isTotal ? AppTheme.primary : AppTheme.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  String _formatPrice(String price) {
    final n = double.tryParse(price) ?? 0;
    return n.toInt().toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    ) + ' تومان';
  }
}

// ============================================================
// ویجت: دکمه‌های سریع تغییر وضعیت
// ============================================================

class StatusQuickActions extends StatelessWidget {
  final String currentStatus;
  final Function(String) onStatusChange;
  const StatusQuickActions({
    super.key,
    required this.currentStatus,
    required this.onStatusChange,
  });

  @override
  Widget build(BuildContext context) {
    final actions = [
      if (currentStatus != 'completed')
        _ActionButton(
          label: 'تکمیل',
          icon: Icons.check_circle_outline,
          color: AppTheme.success,
          onTap: () => _confirmChange(context, 'completed'),
        ),
      if (currentStatus != 'cancelled')
        _ActionButton(
          label: 'لغو',
          icon: Icons.cancel_outlined,
          color: AppTheme.danger,
          onTap: () => _confirmChange(context, 'cancelled'),
        ),
      if (currentStatus != 'processing')
        _ActionButton(
          label: 'در حال پردازش',
          icon: Icons.sync_outlined,
          color: AppTheme.info,
          onTap: () => _confirmChange(context, 'processing'),
        ),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: actions,
    );
  }

  void _confirmChange(BuildContext context, String newStatus) {
    final statusMap = {
      'completed': 'تکمیل شده',
      'cancelled': 'لغو شده',
      'processing': 'در حال پردازش',
    };
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تغییر وضعیت'),
        content: Text('آیا از تغییر وضعیت به "${statusMap[newStatus]}" مطمئن هستید؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('انصراف'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onStatusChange(newStatus);
            },
            child: Text('تأیید', style: TextStyle(color: AppTheme.primary)),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// ویجت: سابقه مشتری
// ============================================================

class CustomerHistoryCard extends StatelessWidget {
  final Customer? customer;
  final bool isLoading;
  final String? error;

  const CustomerHistoryCard({
    super.key,
    this.customer,
    this.isLoading = false,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final paddingValue = isMobile ? 20.0 : 16.0;
    final valueFontSize = isMobile ? 18.0 : 15.0;

    return Container(
      padding: EdgeInsets.all(paddingValue),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
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
          Row(
            children: [
              Icon(Icons.history, size: isMobile ? 22 : 18, color: AppTheme.primary),
              const SizedBox(width: 8),
              Text(
                'سابقه مشتری',
                style: TextStyle(fontSize: isMobile ? 17 : 15, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isLoading)
            const Center(child: CircularProgressIndicator(strokeWidth: 2))
          else if (error != null)
            Text(
              'خطا: $error',
              style: TextStyle(fontSize: 13, color: AppTheme.danger),
            )
          else if (customer == null)
            const Text(
              'اطلاعات مشتری در دسترس نیست',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            )
          else
            Row(
              children: [
                Expanded(
                  child: _statItem(
                    icon: Icons.receipt_outlined,
                    label: 'تعداد سفارشات',
                    value: customer!.totalOrders.toString(),
                    valueFontSize: valueFontSize,
                  ),
                ),
                Expanded(
                  child: _statItem(
                    icon: Icons.money_outlined,
                    label: 'مجموع خرید',
                    value: _formatPrice(customer!.totalSpend),
                    valueFontSize: valueFontSize,
                  ),
                ),
                Expanded(
                  child: _statItem(
                    icon: Icons.trending_up_outlined,
                    label: 'میانگین مبلغ',
                    value: _formatPrice(customer!.averageOrderValue),
                    valueFontSize: valueFontSize,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _statItem({
    required IconData icon,
    required String label,
    required String value,
    double valueFontSize = 15,
  }) {
    return Column(
      children: [
        Icon(icon, size: 22, color: AppTheme.textSecondary),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: valueFontSize,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  String _formatPrice(String price) {
    final n = double.tryParse(price) ?? 0;
    return n.toInt().toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    ) + ' تومان';
  }
}

// ============================================================
// ویجت: کد رهگیری
// ============================================================

class TrackingCodeCard extends StatefulWidget {
  final int orderId;
  final Map<String, dynamic>? metaData;
  final Function(String) onTrackingCodeUpdated;

  const TrackingCodeCard({
    super.key,
    required this.orderId,
    required this.metaData,
    required this.onTrackingCodeUpdated,
  });

  @override
  State<TrackingCodeCard> createState() => _TrackingCodeCardState();
}

class _TrackingCodeCardState extends State<TrackingCodeCard> {
  final TextEditingController _controller = TextEditingController();
  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller.text = _getTrackingCode() ?? '';
  }

  String? _getTrackingCode() {
    if (widget.metaData == null) return null;
    const keys = ['smsir_tracking_code', '_tracking_code', 'tracking_number', '_shipping_tracking_number'];
    for (final key in keys) {
      if (widget.metaData!.containsKey(key) && widget.metaData![key] != null) {
        return widget.metaData![key].toString();
      }
    }
    return null;
  }

  Future<void> _saveTrackingCode() async {
    final code = _controller.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لطفاً کد رهگیری را وارد کنید')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await widget.onTrackingCodeUpdated(code);
      setState(() => _isEditing = false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final existingCode = _getTrackingCode();
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final paddingValue = isMobile ? 20.0 : 16.0;

    return Container(
      padding: EdgeInsets.all(paddingValue),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
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
          Row(
            children: [
              Icon(Icons.local_shipping_outlined, size: isMobile ? 22 : 18, color: AppTheme.primary),
              const SizedBox(width: 8),
              Text(
                'کد رهگیری',
                style: TextStyle(fontSize: isMobile ? 17 : 15, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              if (!_isEditing && existingCode != null)
                TextButton.icon(
                  onPressed: () => setState(() => _isEditing = true),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('ویرایش'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isEditing || existingCode == null)
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'کد رهگیری را وارد کنید...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (_isEditing)
                  TextButton(
                    onPressed: _isLoading ? null : _saveTrackingCode,
                    child: _isLoading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('ذخیره'),
                  ),
                if (!_isEditing && existingCode == null)
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveTrackingCode,
                    child: _isLoading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('ثبت'),
                  ),
              ],
            )
          else
            Row(
              children: [
                Icon(Icons.check_circle, size: 18, color: AppTheme.success),
                const SizedBox(width: 8),
                Text(
                  existingCode,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// ============================================================
// ویجت: فایل پیوست (نسخه)
// ============================================================

class AttachmentCard extends StatelessWidget {
  final Map<String, dynamic>? metaData;

  const AttachmentCard({super.key, required this.metaData});

  String? _getAttachment() {
    if (metaData == null) return null;
    const keys = ['_ez_prescription', '_attachment', '_file_attachment', '_prescription_file'];
    for (final key in keys) {
      if (metaData!.containsKey(key) && metaData![key] != null) {
        final value = metaData![key].toString();
        if (value.isNotEmpty) return value;
      }
    }
    return null;
  }

  String _getFileName(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.pathSegments.last;
    } catch (_) {
      return url;
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final attachment = _getAttachment();
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final paddingValue = isMobile ? 20.0 : 16.0;

    return Container(
      padding: EdgeInsets.all(paddingValue),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
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
          Row(
            children: [
              Icon(Icons.attach_file_outlined, size: isMobile ? 22 : 18, color: AppTheme.primary),
              const SizedBox(width: 8),
              Text(
                'نسخه / فایل پیوست',
                style: TextStyle(fontSize: isMobile ? 17 : 15, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (attachment != null && attachment.isNotEmpty)
            InkWell(
              onTap: () => _openUrl(attachment),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceHover,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border.withOpacity(0.5)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.insert_drive_file, size: 24, color: AppTheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _getFileName(attachment),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.open_in_new, size: 18, color: AppTheme.textSecondary),
                  ],
                ),
              ),
            )
          else
            const Text(
              'فایلی پیوست نشده است.',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
        ],
      ),
    );
  }
}