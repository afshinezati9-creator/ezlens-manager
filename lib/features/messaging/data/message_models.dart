library;

class SentMessage {
  final int id;
  final String channel; // email | sms
  final String recipient;
  final String recipientName;
  final int userId;
  final String subject;
  final String body;
  final String attachmentUrl;
  final String status;
  final String errorMessage;
  final String createdAt;
  final String createdFa;

  const SentMessage({
    required this.id,
    this.channel = 'email',
    this.recipient = '',
    this.recipientName = '',
    this.userId = 0,
    this.subject = '',
    this.body = '',
    this.attachmentUrl = '',
    this.status = 'sent',
    this.errorMessage = '',
    this.createdAt = '',
    this.createdFa = '',
  });

  String get channelLabel => channel == 'sms' ? 'پیامک' : 'ایمیل';
  bool get isFailed => status == 'failed';

  factory SentMessage.fromJson(Map<String, dynamic> json) {
    return SentMessage(
      id: int.tryParse('${json['id']}') ?? 0,
      channel: (json['channel'] ?? 'email').toString(),
      recipient: (json['recipient'] ?? '').toString(),
      recipientName: (json['recipient_name'] ?? '').toString(),
      userId: int.tryParse('${json['user_id']}') ?? 0,
      subject: (json['subject'] ?? '').toString(),
      body: (json['body'] ?? '').toString(),
      attachmentUrl: (json['attachment_url'] ?? '').toString(),
      status: (json['status'] ?? 'sent').toString(),
      errorMessage: (json['error_message'] ?? '').toString(),
      createdAt: (json['created_at'] ?? '').toString(),
      createdFa: (json['created_fa'] ?? '').toString(),
    );
  }
}

class MessageListResult {
  final List<SentMessage> items;
  final int total;
  final int page;
  final int pages;

  const MessageListResult({
    required this.items,
    this.total = 0,
    this.page = 1,
    this.pages = 1,
  });

  factory MessageListResult.fromJson(Map<String, dynamic> json) {
    final items = <SentMessage>[];
    final raw = json['items'];
    if (raw is List) {
      for (final e in raw) {
        if (e is Map) {
          items.add(SentMessage.fromJson(Map<String, dynamic>.from(e)));
        }
      }
    }
    return MessageListResult(
      items: items,
      total: int.tryParse('${json['total']}') ?? items.length,
      page: int.tryParse('${json['page']}') ?? 1,
      pages: int.tryParse('${json['pages']}') ?? 1,
    );
  }
}

class MessageCustomer {
  final int id;
  final String name;
  final String email;
  final String login;
  final String phone;

  const MessageCustomer({
    required this.id,
    this.name = '',
    this.email = '',
    this.login = '',
    this.phone = '',
  });

  factory MessageCustomer.fromJson(Map<String, dynamic> json) {
    return MessageCustomer(
      id: int.tryParse('${json['id']}') ?? 0,
      name: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      login: (json['login'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
    );
  }
}
