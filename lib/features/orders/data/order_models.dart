// lib/features/orders/data/order_models.dart

// ============================================================
// مدل Order (با فیلدهای جدید)
// ============================================================

class Order {
  final int id;
  final String orderNumber;
  final String customerName;
  final String total;
  final String status;
  final DateTime dateCreated;
  final String paymentMethodTitle;
  final List<OrderItem> lineItems;
  final OrderAddress billing;
  final OrderAddress shipping;
  final List<OrderMetaData>? metaData;
  final String? customerNote;

  // فیلدهای مالی
  final String subtotal;
  final String shippingTotal;
  final String totalTax;
  final String discountTotal;

  // ===== فیلدهای جدید =====
  final int? customerId;    // شناسه مشتری برای دریافت سابقه
  final String? orderKey;   // کلید سفارش برای لینک پرداخت

  Order({
    required this.id,
    required this.orderNumber,
    required this.customerName,
    required this.total,
    required this.status,
    required this.dateCreated,
    required this.paymentMethodTitle,
    required this.lineItems,
    required this.billing,
    required this.shipping,
    this.metaData,
    this.customerNote,
    this.subtotal = '0',
    this.shippingTotal = '0',
    this.totalTax = '0',
    this.discountTotal = '0',
    this.customerId,
    this.orderKey,
  });



  /// شارژ کیف پول از داشبورد مشتری
  bool get isWalletTopup {
    if (metaData == null) return false;
    for (final m in metaData!) {
      if (m.key == '_ezcd_wallet_topup') {
        final v = '${m.value}'.toLowerCase();
        if (v == '1' || v == 'true' || v == 'yes') return true;
      }
    }
    return false;
  }

  String? get walletTopupAmount {
    if (metaData == null) return null;
    for (final m in metaData!) {
      if (m.key == '_ezcd_wallet_amount') {
        return m.value?.toString();
      }
    }
    return null;
  }

String? getMeta(String key) {
    if (metaData == null) return null;
    for (final m in metaData!) {
      if (m.key == key) return m.value?.toString();
    }
    return null;
  }

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] ?? 0,
      orderNumber: json['number']?.toString() ?? '#' + (json['id'] ?? 0).toString(),
      customerName: (json['billing']['first_name'] ?? '') + ' ' + (json['billing']['last_name'] ?? ''),
      total: json['total']?.toString() ?? '0',
      status: json['status'] ?? 'pending',
      dateCreated: DateTime.tryParse(json['date_created'] ?? '') ?? DateTime.now(),
      paymentMethodTitle: json['payment_method_title'] ?? '—',
      lineItems: (json['line_items'] as List?)?.map((e) => OrderItem.fromJson(e)).toList() ?? [],
      billing: OrderAddress.fromJson(json['billing'] ?? {}),
      shipping: OrderAddress.fromJson(json['shipping'] ?? {}),
      metaData: (json['meta_data'] as List?)?.map((e) => OrderMetaData.fromJson(e)).toList(),
      customerNote: json['customer_note'],
      subtotal: json['subtotal']?.toString() ?? '0',
      shippingTotal: json['shipping_total']?.toString() ?? '0',
      totalTax: json['total_tax']?.toString() ?? '0',
      discountTotal: json['discount_total']?.toString() ?? '0',
      customerId: json['customer_id'] as int?,
      orderKey: json['order_key'] as String?,
    );
  }
}

class OrderItem {
  final int id;
  final String name;
  final int productId;
  final int quantity;
  final String total;
  final String price;
  final String? sku;
  final String? imageUrl;

  OrderItem({
    required this.id,
    required this.name,
    required this.productId,
    required this.quantity,
    required this.total,
    required this.price,
    this.sku,
    this.imageUrl,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'محصول',
      productId: json['product_id'] ?? 0,
      quantity: json['quantity'] ?? 0,
      total: json['total']?.toString() ?? '0',
      price: json['price']?.toString() ?? '0',
      sku: json['sku'],
      imageUrl: json['image']?['src'],
    );
  }
}

class OrderAddress {
  final String firstName;
  final String lastName;
  final String address1;
  final String address2;
  final String city;
  final String state;
  final String postcode;
  final String country;
  final String email;
  final String phone;

  OrderAddress({
    this.firstName = '',
    this.lastName = '',
    this.address1 = '',
    this.address2 = '',
    this.city = '',
    this.state = '',
    this.postcode = '',
    this.country = '',
    this.email = '',
    this.phone = '',
  });

  factory OrderAddress.fromJson(Map<String, dynamic> json) {
    return OrderAddress(
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      address1: json['address_1'] ?? '',
      address2: json['address_2'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      postcode: json['postcode'] ?? '',
      country: json['country'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
    );
  }

  String get fullName => '$firstName $lastName';
  String get fullAddress => '$address1${address2.isNotEmpty ? '، $address2' : ''}، $city، $state، $postcode';
}

class OrderMetaData {
  final String key;
  final dynamic value;

  OrderMetaData({required this.key, this.value});

  factory OrderMetaData.fromJson(Map<String, dynamic> json) {
    return OrderMetaData(
      key: json['key'] ?? '',
      value: json['value'],
    );
  }
}

class OrderNote {
  final int id;
  final String author;
  final DateTime dateCreated;
  final String note;
  final bool customerNote;

  OrderNote({
    required this.id,
    required this.author,
    required this.dateCreated,
    required this.note,
    required this.customerNote,
  });

  factory OrderNote.fromJson(Map<String, dynamic> json) {
    return OrderNote(
      id: json['id'] ?? 0,
      author: json['author'] ?? 'سیستم',
      dateCreated: DateTime.tryParse(json['date_created'] ?? '') ?? DateTime.now(),
      note: json['note'] ?? '',
      customerNote: json['customer_note'] ?? false,
    );
  }
}

// ============================================================
// مدل Customer (جدید)
// ============================================================

class Customer {
  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final int totalOrders;
  final String totalSpend;
  final String averageOrderValue;

  Customer({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.totalOrders,
    required this.totalSpend,
    required this.averageOrderValue,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    final totalSpend = json['total_spend']?.toString() ?? '0';
    final totalOrders = json['orders_count'] ?? 0;
    final avgOrderValue = totalOrders > 0 ? (double.tryParse(totalSpend) ?? 0) / totalOrders : 0;

    return Customer(
      id: json['id'] ?? 0,
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      totalOrders: totalOrders is int ? totalOrders : int.tryParse(totalOrders.toString()) ?? 0,
      totalSpend: totalSpend,
      averageOrderValue: avgOrderValue.toStringAsFixed(0),
    );
  }
}