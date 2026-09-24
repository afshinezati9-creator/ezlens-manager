/// Customer / user models for EzLens Manager.
library;

class ManagerUser {
  final int id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String role;
  final String phone;
  final DateTime? dateCreated;
  final DateTime? dateModified;
  final DateTime? lastLogin;
  final int ordersCount;
  final String totalSpent;
  final int walletBalance;
  final bool hasPassword;
  final String avatarUrl;
  final bool isPayingCustomer;
  final ManagerUserAddress? billing;
  final ManagerUserAddress? shipping;

  const ManagerUser({
    required this.id,
    this.username = '',
    this.email = '',
    this.firstName = '',
    this.lastName = '',
    this.role = 'customer',
    this.phone = '',
    this.dateCreated,
    this.dateModified,
    this.lastLogin,
    this.ordersCount = 0,
    this.totalSpent = '0',
    this.walletBalance = 0,
    this.hasPassword = false,
    this.avatarUrl = '',
    this.isPayingCustomer = false,
    this.billing,
    this.shipping,
  });

  String get displayName {
    final n = '$firstName $lastName'.trim();
    if (n.isNotEmpty) return n;
    if (username.isNotEmpty) return username;
    return email.isNotEmpty ? email : '#$id';
  }

  String get primaryPhone {
    if (phone.isNotEmpty) return phone;
    final b = billing?.phone ?? '';
    if (b.isNotEmpty) return b;
    // username is often the mobile
    if (RegExp(r'^09\d{9}$').hasMatch(username)) return username;
    return '';
  }

  factory ManagerUser.fromWcJson(Map<String, dynamic> json) {
    final billing = json['billing'] is Map
        ? ManagerUserAddress.fromJson(Map<String, dynamic>.from(json['billing'] as Map))
        : null;
    final shipping = json['shipping'] is Map
        ? ManagerUserAddress.fromJson(Map<String, dynamic>.from(json['shipping'] as Map))
        : null;

    final meta = <String, String>{};
    final rawMeta = json['meta_data'];
    if (rawMeta is List) {
      for (final e in rawMeta) {
        if (e is Map) {
          final k = '${e['key'] ?? ''}';
          final v = e['value'];
          if (k.isNotEmpty) meta[k] = v?.toString() ?? '';
        }
      }
    }

    DateTime? lastLogin;
    for (final key in ['ezlens_last_login', 'last_login', 'wfls-last-login']) {
      final raw = meta[key];
      if (raw == null || raw.isEmpty) continue;
      final asInt = int.tryParse(raw);
      if (asInt != null && asInt > 100000) {
        // unix seconds
        lastLogin = DateTime.fromMillisecondsSinceEpoch(
          asInt > 9999999999 ? asInt : asInt * 1000,
        );
        break;
      }
      lastLogin = DateTime.tryParse(raw);
      if (lastLogin != null) break;
    }

    final phone = (json['billing'] is Map
            ? (json['billing']['phone']?.toString() ?? '')
            : '')
        .trim();
    final userPhone = meta['user_phone'] ?? meta['billing_phone'] ?? phone;

    return ManagerUser(
      id: _asInt(json['id']),
      username: (json['username'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      firstName: (json['first_name'] ?? '').toString(),
      lastName: (json['last_name'] ?? '').toString(),
      role: (json['role'] ?? 'customer').toString(),
      phone: userPhone,
      dateCreated: DateTime.tryParse('${json['date_created'] ?? ''}'),
      dateModified: DateTime.tryParse('${json['date_modified'] ?? ''}'),
      lastLogin: lastLogin,
      ordersCount: _asInt(json['orders_count']),
      totalSpent: (json['total_spent'] ?? '0').toString(),
      walletBalance: _asInt(meta['ezcd_wallet_balance'] ?? json['wallet_balance']),
      hasPassword: json['has_password'] == true || meta['ezlens_has_password'] == '1',
      avatarUrl: (json['avatar_url'] ?? '').toString(),
      isPayingCustomer: json['is_paying_customer'] == true,
      billing: billing,
      shipping: shipping,
    );
  }

  /// Merge enriched fields from manager API.
  ManagerUser mergeEnrichment(Map<String, dynamic> e) {
    DateTime? ll = lastLogin;
    if (e['last_login'] != null) {
      final raw = e['last_login'].toString();
      final asInt = int.tryParse(raw);
      if (asInt != null && asInt > 100000) {
        ll = DateTime.fromMillisecondsSinceEpoch(
          asInt > 9999999999 ? asInt : asInt * 1000,
        );
      } else {
        ll = DateTime.tryParse(raw) ?? ll;
      }
    }
    return ManagerUser(
      id: id,
      username: username,
      email: email,
      firstName: firstName,
      lastName: lastName,
      role: role,
      phone: (e['phone']?.toString().isNotEmpty == true) ? e['phone'].toString() : phone,
      dateCreated: dateCreated,
      dateModified: dateModified,
      lastLogin: ll,
      ordersCount: e['orders_count'] != null ? _asInt(e['orders_count']) : ordersCount,
      totalSpent: e['total_spent']?.toString() ?? totalSpent,
      walletBalance: e['wallet_balance'] != null ? _asInt(e['wallet_balance']) : walletBalance,
      hasPassword: e['has_password'] == true ? true : hasPassword,
      avatarUrl: avatarUrl,
      isPayingCustomer: isPayingCustomer,
      billing: billing,
      shipping: shipping,
    );
  }

  static int _asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('$v') ?? 0;
  }
}

class ManagerUserAddress {
  final String firstName;
  final String lastName;
  final String address1;
  final String city;
  final String state;
  final String postcode;
  final String country;
  final String email;
  final String phone;

  const ManagerUserAddress({
    this.firstName = '',
    this.lastName = '',
    this.address1 = '',
    this.city = '',
    this.state = '',
    this.postcode = '',
    this.country = '',
    this.email = '',
    this.phone = '',
  });

  factory ManagerUserAddress.fromJson(Map<String, dynamic> json) {
    return ManagerUserAddress(
      firstName: (json['first_name'] ?? '').toString(),
      lastName: (json['last_name'] ?? '').toString(),
      address1: (json['address_1'] ?? '').toString(),
      city: (json['city'] ?? '').toString(),
      state: (json['state'] ?? '').toString(),
      postcode: (json['postcode'] ?? '').toString(),
      country: (json['country'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
    );
  }

  String get fullAddress {
    final parts = [address1, city, state, postcode]
        .where((e) => e.trim().isNotEmpty)
        .toList();
    return parts.join('، ');
  }
}

class UsersListResult {
  final List<ManagerUser> items;
  final int total;
  final int totalPages;

  const UsersListResult({
    required this.items,
    required this.total,
    required this.totalPages,
  });
}


// ============================================================
// Dossier panels (prescriptions, wallet, cart, orders)
// ============================================================

class RxFileInfo {
  final int attachmentId;
  final String url;
  final String filename;
  final String mime;
  final bool isImage;

  const RxFileInfo({
    this.attachmentId = 0,
    this.url = '',
    this.filename = '',
    this.mime = '',
    this.isImage = false,
  });

  factory RxFileInfo.fromJson(Map<String, dynamic> json) {
    return RxFileInfo(
      attachmentId: int.tryParse('${json['attachment_id']}') ?? 0,
      url: (json['url'] ?? '').toString(),
      filename: (json['filename'] ?? '').toString(),
      mime: (json['mime'] ?? '').toString(),
      isImage: json['is_image'] == true,
    );
  }
}

class UserPrescription {
  final int id;
  final String doctorName;
  final String issuedAt;
  final String visitedAt;
  final String rxType;
  final String rxTypeLabel;
  final String odSph;
  final String odCyl;
  final String odAxis;
  final String osSph;
  final String osCyl;
  final String osAxis;
  final String pd;
  final String notes;
  final String createdAt;
  final RxFileInfo? file;

  const UserPrescription({
    required this.id,
    this.doctorName = '',
    this.issuedAt = '',
    this.visitedAt = '',
    this.rxType = '',
    this.rxTypeLabel = '',
    this.odSph = '',
    this.odCyl = '',
    this.odAxis = '',
    this.osSph = '',
    this.osCyl = '',
    this.osAxis = '',
    this.pd = '',
    this.notes = '',
    this.createdAt = '',
    this.file,
  });

  factory UserPrescription.fromJson(Map<String, dynamic> json) {
    RxFileInfo? file;
    if (json['file'] is Map) {
      file = RxFileInfo.fromJson(Map<String, dynamic>.from(json['file'] as Map));
    }
    return UserPrescription(
      id: int.tryParse('${json['id']}') ?? 0,
      doctorName: (json['doctor_name'] ?? '').toString(),
      issuedAt: (json['issued_at'] ?? '').toString(),
      visitedAt: (json['visited_at'] ?? '').toString(),
      rxType: (json['rx_type'] ?? '').toString(),
      rxTypeLabel: (json['rx_type_label'] ?? json['rx_type'] ?? '').toString(),
      odSph: (json['od_sph'] ?? '').toString(),
      odCyl: (json['od_cyl'] ?? '').toString(),
      odAxis: (json['od_axis'] ?? '').toString(),
      osSph: (json['os_sph'] ?? '').toString(),
      osCyl: (json['os_cyl'] ?? '').toString(),
      osAxis: (json['os_axis'] ?? '').toString(),
      pd: (json['pd'] ?? '').toString(),
      notes: (json['notes'] ?? '').toString(),
      createdAt: (json['created_at'] ?? '').toString(),
      file: file,
    );
  }
}

class DossierOrder {
  final int id;
  final String number;
  final String status;
  final String statusLabel;
  final String total;
  final String dateCreated;
  final bool isWallet;
  final List<String> itemNames;

  const DossierOrder({
    required this.id,
    this.number = '',
    this.status = '',
    this.statusLabel = '',
    this.total = '0',
    this.dateCreated = '',
    this.isWallet = false,
    this.itemNames = const [],
  });

  factory DossierOrder.fromJson(Map<String, dynamic> json) {
    final names = <String>[];
    final items = json['items'];
    if (items is List) {
      for (final e in items) {
        if (e is Map && e['name'] != null) {
          names.add('${e['name']} × ${e['quantity'] ?? 1}');
        }
      }
    }
    return DossierOrder(
      id: int.tryParse('${json['id']}') ?? 0,
      number: (json['number'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      statusLabel: (json['status_label'] ?? '').toString(),
      total: (json['total'] ?? '0').toString(),
      dateCreated: (json['date_created'] ?? '').toString(),
      isWallet: json['is_wallet'] == true,
      itemNames: names,
    );
  }
}

class CartLine {
  final int productId;
  final String name;
  final int quantity;
  final String price;

  const CartLine({
    this.productId = 0,
    this.name = '',
    this.quantity = 0,
    this.price = '',
  });

  factory CartLine.fromJson(Map<String, dynamic> json) {
    return CartLine(
      productId: int.tryParse('${json['product_id']}') ?? 0,
      name: (json['name'] ?? '').toString(),
      quantity: int.tryParse('${json['quantity']}') ?? 0,
      price: (json['price'] ?? '').toString(),
    );
  }
}

class UserDossier {
  final int customerId;
  final DateTime? lastLogin;
  final int walletBalance;
  final int ordersCount;
  final String totalSpent;
  final List<UserPrescription> prescriptions;
  final List<CartLine> cartItems;
  final List<DossierOrder> recentOrders;
  final List<DossierOrder> cancelled;
  final List<DossierOrder> refunded;
  final List<DossierOrder> completed;

  const UserDossier({
    required this.customerId,
    this.lastLogin,
    this.walletBalance = 0,
    this.ordersCount = 0,
    this.totalSpent = '0',
    this.prescriptions = const [],
    this.cartItems = const [],
    this.recentOrders = const [],
    this.cancelled = const [],
    this.refunded = const [],
    this.completed = const [],
  });

  factory UserDossier.fromJson(Map<String, dynamic> json) {
    DateTime? ll;
    final rawLl = json['last_login'];
    if (rawLl != null) {
      final s = rawLl.toString();
      final asInt = int.tryParse(s);
      if (asInt != null && asInt > 100000) {
        ll = DateTime.fromMillisecondsSinceEpoch(
          asInt > 9999999999 ? asInt : asInt * 1000,
        );
      } else {
        ll = DateTime.tryParse(s);
      }
    }

    final wallet = json['wallet'] is Map
        ? Map<String, dynamic>.from(json['wallet'] as Map)
        : <String, dynamic>{};

    List<UserPrescription> rx = [];
    final rawRx = json['prescriptions'];
    if (rawRx is List) {
      for (final e in rawRx) {
        if (e is Map) {
          rx.add(UserPrescription.fromJson(Map<String, dynamic>.from(e)));
        }
      }
    }

    List<CartLine> cart = [];
    final rawCart = json['cart'];
    if (rawCart is Map && rawCart['items'] is List) {
      for (final e in rawCart['items'] as List) {
        if (e is Map) {
          cart.add(CartLine.fromJson(Map<String, dynamic>.from(e)));
        }
      }
    }

    List<DossierOrder> parseOrders(dynamic raw) {
      final out = <DossierOrder>[];
      if (raw is List) {
        for (final e in raw) {
          if (e is Map) {
            out.add(DossierOrder.fromJson(Map<String, dynamic>.from(e)));
          }
        }
      }
      return out;
    }

    final byStatus = json['orders_by_status'] is Map
        ? Map<String, dynamic>.from(json['orders_by_status'] as Map)
        : <String, dynamic>{};

    return UserDossier(
      customerId: int.tryParse('${json['customer_id']}') ?? 0,
      lastLogin: ll,
      walletBalance: int.tryParse('${wallet['balance']}') ?? 0,
      ordersCount: int.tryParse('${wallet['orders_count']}') ?? 0,
      totalSpent: (wallet['total_spent'] ?? '0').toString(),
      prescriptions: rx,
      cartItems: cart,
      recentOrders: parseOrders(json['recent_orders']),
      cancelled: parseOrders(byStatus['cancelled']),
      refunded: parseOrders(byStatus['refunded']),
      completed: parseOrders(byStatus['completed']),
    );
  }
}
