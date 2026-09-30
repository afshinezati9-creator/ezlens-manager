library;

class SupportTicket {
  final int id;
  final int userId;
  final String status;
  final String subject;
  final String createdAt;
  final String updatedAt;
  final String createdFa;
  final String updatedFa;
  final String displayName;
  final String userEmail;
  final String userLogin;
  final String phone;

  const SupportTicket({
    required this.id,
    this.userId = 0,
    this.status = 'open',
    this.subject = '',
    this.createdAt = '',
    this.updatedAt = '',
    this.createdFa = '',
    this.updatedFa = '',
    this.displayName = '',
    this.userEmail = '',
    this.userLogin = '',
    this.phone = '',
  });

  String get statusLabel {
    switch (status) {
      case 'open':
        return 'باز';
      case 'replied':
        return 'پاسخ‌داده‌شده';
      case 'closed':
        return 'بسته';
      default:
        return status;
    }
  }

  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    return SupportTicket(
      id: int.tryParse('${json['id']}') ?? 0,
      userId: int.tryParse('${json['user_id']}') ?? 0,
      status: (json['status'] ?? 'open').toString(),
      subject: (json['subject'] ?? '').toString(),
      createdAt: (json['created_at'] ?? '').toString(),
      updatedAt: (json['updated_at'] ?? '').toString(),
      createdFa: (json['created_fa'] ?? '').toString(),
      updatedFa: (json['updated_fa'] ?? '').toString(),
      displayName: (json['display_name'] ?? '').toString(),
      userEmail: (json['user_email'] ?? '').toString(),
      userLogin: (json['user_login'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
    );
  }
}

class SupportMessage {
  final int id;
  final int ticketId;
  final int senderId;
  final String senderType; // user | admin
  final String message;
  final String fileUrl;
  final bool hasFile;
  final String createdAt;
  final String createdFa;

  const SupportMessage({
    required this.id,
    this.ticketId = 0,
    this.senderId = 0,
    this.senderType = 'user',
    this.message = '',
    this.fileUrl = '',
    this.hasFile = false,
    this.createdAt = '',
    this.createdFa = '',
  });

  bool get isAdmin => senderType == 'admin' || senderType == 'staff';

  factory SupportMessage.fromJson(Map<String, dynamic> json) {
    final file = (json['file_url'] ?? json['file_attachment'] ?? '').toString();
    return SupportMessage(
      id: int.tryParse('${json['id']}') ?? 0,
      ticketId: int.tryParse('${json['ticket_id']}') ?? 0,
      senderId: int.tryParse('${json['sender_id']}') ?? 0,
      senderType: (json['sender_type'] ?? 'user').toString(),
      message: (json['message'] ?? '').toString(),
      fileUrl: file,
      hasFile: json['has_file'] == true || file.isNotEmpty,
      createdAt: (json['created_at'] ?? '').toString(),
      createdFa: (json['created_fa'] ?? '').toString(),
    );
  }
}

class SupportCustomer {
  final int id;
  final String displayName;
  final String email;
  final String login;
  final String phone;
  final int wallet;
  final int ordersCount;
  final String totalSpent;
  final List<Map<String, dynamic>> recentOrders;
  final List<Map<String, dynamic>> cart;

  const SupportCustomer({
    required this.id,
    this.displayName = '',
    this.email = '',
    this.login = '',
    this.phone = '',
    this.wallet = 0,
    this.ordersCount = 0,
    this.totalSpent = '0',
    this.recentOrders = const [],
    this.cart = const [],
  });

  factory SupportCustomer.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const SupportCustomer(id: 0);
    }
    final orders = <Map<String, dynamic>>[];
    final rawO = json['recent_orders'];
    if (rawO is List) {
      for (final e in rawO) {
        if (e is Map) orders.add(Map<String, dynamic>.from(e));
      }
    }
    final cart = <Map<String, dynamic>>[];
    final rawC = json['cart'];
    if (rawC is List) {
      for (final e in rawC) {
        if (e is Map) cart.add(Map<String, dynamic>.from(e));
      }
    }
    return SupportCustomer(
      id: int.tryParse('${json['id']}') ?? 0,
      displayName: (json['display_name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      login: (json['login'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      wallet: int.tryParse('${json['wallet']}') ?? 0,
      ordersCount: int.tryParse('${json['orders_count']}') ?? 0,
      totalSpent: (json['total_spent'] ?? '0').toString(),
      recentOrders: orders,
      cart: cart,
    );
  }
}

class SupportTicketDetail {
  final SupportTicket ticket;
  final List<SupportMessage> messages;
  final SupportCustomer? customer;

  const SupportTicketDetail({
    required this.ticket,
    this.messages = const [],
    this.customer,
  });

  factory SupportTicketDetail.fromJson(Map<String, dynamic> json) {
    final t = SupportTicket.fromJson(
      Map<String, dynamic>.from(json['ticket'] as Map? ?? json),
    );
    final msgs = <SupportMessage>[];
    final raw = json['messages'];
    if (raw is List) {
      for (final e in raw) {
        if (e is Map) {
          msgs.add(SupportMessage.fromJson(Map<String, dynamic>.from(e)));
        }
      }
    }
    SupportCustomer? c;
    if (json['customer'] is Map) {
      c = SupportCustomer.fromJson(
          Map<String, dynamic>.from(json['customer'] as Map));
    }
    return SupportTicketDetail(ticket: t, messages: msgs, customer: c);
  }
}

class SupportListResult {
  final List<SupportTicket> items;
  final int total;
  final int page;
  final int pages;

  const SupportListResult({
    required this.items,
    this.total = 0,
    this.page = 1,
    this.pages = 1,
  });

  factory SupportListResult.fromJson(Map<String, dynamic> json) {
    final items = <SupportTicket>[];
    final raw = json['items'];
    if (raw is List) {
      for (final e in raw) {
        if (e is Map) {
          items.add(SupportTicket.fromJson(Map<String, dynamic>.from(e)));
        }
      }
    }
    return SupportListResult(
      items: items,
      total: int.tryParse('${json['total']}') ?? items.length,
      page: int.tryParse('${json['page']}') ?? 1,
      pages: int.tryParse('${json['pages']}') ?? 1,
    );
  }
}
