library;

class ContactDraft {
  final String name;
  final String email;
  final String phone;
  final String source; // file | site | manual
  final int? userId;

  const ContactDraft({
    this.name = '',
    this.email = '',
    this.phone = '',
    this.source = 'manual',
    this.userId,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
        'phone': phone,
      };

  String get key => '${email.toLowerCase()}|${phone.replaceAll(RegExp(r'\D'), '')}';
}

class ContactBook {
  final int id;
  final String name;
  final String description;
  final String type;
  final int contactCount;
  final String createdAt;
  final String createdFa;

  const ContactBook({
    required this.id,
    this.name = '',
    this.description = '',
    this.type = 'custom',
    this.contactCount = 0,
    this.createdAt = '',
    this.createdFa = '',
  });

  factory ContactBook.fromJson(Map<String, dynamic> json) {
    return ContactBook(
      id: int.tryParse('${json['id']}') ?? 0,
      name: (json['name'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      type: (json['type'] ?? 'custom').toString(),
      contactCount: int.tryParse('${json['contact_count']}') ?? 0,
      createdAt: (json['created_at'] ?? '').toString(),
      createdFa: (json['created_fa'] ?? '').toString(),
    );
  }
}

class BookContact {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String source;

  const BookContact({
    required this.id,
    this.name = '',
    this.email = '',
    this.phone = '',
    this.source = '',
  });

  factory BookContact.fromJson(Map<String, dynamic> json) {
    return BookContact(
      id: int.tryParse('${json['id']}') ?? 0,
      name: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      source: (json['source'] ?? '').toString(),
    );
  }
}

class CampaignItem {
  final int id;
  final String name;
  final String type;
  final String subject;
  final String message;
  final String fileUrl;
  final String status;
  final String createdAt;
  final String createdFa;
  final int sent;
  final int total;
  final int failed;

  const CampaignItem({
    required this.id,
    this.name = '',
    this.type = 'email',
    this.subject = '',
    this.message = '',
    this.fileUrl = '',
    this.status = 'draft',
    this.createdAt = '',
    this.createdFa = '',
    this.sent = 0,
    this.total = 0,
    this.failed = 0,
  });

  String get statusLabel {
    switch (status) {
      case 'sent':
        return 'ارسال‌شده';
      case 'sending':
        return 'در حال ارسال';
      case 'partial':
        return 'ناقص';
      case 'failed':
        return 'ناموفق';
      case 'draft':
        return 'پیش‌نویس';
      default:
        return status;
    }
  }

  String get typeLabel => type == 'sms' ? 'پیامک' : 'ایمیل';

  factory CampaignItem.fromJson(Map<String, dynamic> json) {
    return CampaignItem(
      id: int.tryParse('${json['id']}') ?? 0,
      name: (json['name'] ?? '').toString(),
      type: (json['type'] ?? 'email').toString(),
      subject: (json['subject'] ?? '').toString(),
      message: (json['message'] ?? '').toString(),
      fileUrl: (json['file_url'] ?? '').toString(),
      status: (json['status'] ?? 'draft').toString(),
      createdAt: (json['created_at'] ?? '').toString(),
      createdFa: (json['created_fa'] ?? '').toString(),
      sent: int.tryParse('${json['sent']}') ?? 0,
      total: int.tryParse('${json['total']}') ?? 0,
      failed: int.tryParse('${json['failed']}') ?? 0,
    );
  }
}

class SiteCustomer {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String login;

  const SiteCustomer({
    required this.id,
    this.name = '',
    this.email = '',
    this.phone = '',
    this.login = '',
  });

  factory SiteCustomer.fromJson(Map<String, dynamic> json) {
    return SiteCustomer(
      id: int.tryParse('${json['id']}') ?? 0,
      name: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      login: (json['login'] ?? '').toString(),
    );
  }
}
