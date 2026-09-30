library;

class DiscountCoupon {
  final int id;
  final String code;
  final String discountType;
  final String typeLabel;
  final double amount;
  final String description;
  final int usageCount;
  final int usageLimit;
  final String status;
  final String dateCreatedFa;
  final String dateExpiresFa;

  const DiscountCoupon({
    required this.id,
    this.code = '',
    this.discountType = 'percent',
    this.typeLabel = '',
    this.amount = 0,
    this.description = '',
    this.usageCount = 0,
    this.usageLimit = 0,
    this.status = 'publish',
    this.dateCreatedFa = '',
    this.dateExpiresFa = '',
  });

  String get amountLabel {
    if (discountType == 'percent') {
      return '${amount.toStringAsFixed(amount.truncateToDouble() == amount ? 0 : 1)}٪';
    }
    final n = amount.toInt();
    final f = n.toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
    return '$f تومان';
  }

  factory DiscountCoupon.fromJson(Map<String, dynamic> json) {
    return DiscountCoupon(
      id: int.tryParse('${json['id']}') ?? 0,
      code: (json['code'] ?? '').toString(),
      discountType: (json['discount_type'] ?? 'percent').toString(),
      typeLabel: (json['type_label'] ?? '').toString(),
      amount: double.tryParse('${json['amount']}') ?? 0,
      description: (json['description'] ?? '').toString(),
      usageCount: int.tryParse('${json['usage_count']}') ?? 0,
      usageLimit: int.tryParse('${json['usage_limit']}') ?? 0,
      status: (json['status'] ?? 'publish').toString(),
      dateCreatedFa: (json['date_created_fa'] ?? '').toString(),
      dateExpiresFa: (json['date_expires_fa'] ?? '').toString(),
    );
  }
}

class GiftCardItem {
  final int id;
  final String code;
  final int amount;
  final String status;
  final String purchaserName;
  final String redeemerName;
  final String recipientName;
  final String message;
  final String createdFa;
  final String redeemedFa;

  const GiftCardItem({
    required this.id,
    this.code = '',
    this.amount = 0,
    this.status = 'active',
    this.purchaserName = '',
    this.redeemerName = '',
    this.recipientName = '',
    this.message = '',
    this.createdFa = '',
    this.redeemedFa = '',
  });

  String get statusLabel {
    switch (status) {
      case 'active':
        return 'فعال';
      case 'redeemed':
        return 'استفاده‌شده';
      case 'cancelled':
        return 'لغو شده';
      default:
        return status;
    }
  }

  factory GiftCardItem.fromJson(Map<String, dynamic> json) {
    return GiftCardItem(
      id: int.tryParse('${json['id']}') ?? 0,
      code: (json['code'] ?? '').toString(),
      amount: int.tryParse('${json['amount']}') ?? 0,
      status: (json['status'] ?? 'active').toString(),
      purchaserName: (json['purchaser_name'] ?? '').toString(),
      redeemerName: (json['redeemer_name'] ?? '').toString(),
      recipientName: (json['recipient_name'] ?? '').toString(),
      message: (json['message'] ?? '').toString(),
      createdFa: (json['created_fa'] ?? '').toString(),
      redeemedFa: (json['redeemed_fa'] ?? '').toString(),
    );
  }
}
