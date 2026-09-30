/// Inbox models for EzLens Manager.
library;

class InboxMessageSummary {
  final int uid;
  final int msgno;
  final String subject;
  final String from;
  final String fromName;
  final String to;
  final String dateRaw;
  final String dateFa;
  final int timestamp;
  final bool unseen;
  final bool hasAttachment;

  const InboxMessageSummary({
    required this.uid,
    this.msgno = 0,
    this.subject = '',
    this.from = '',
    this.fromName = '',
    this.to = '',
    this.dateRaw = '',
    this.dateFa = '',
    this.timestamp = 0,
    this.unseen = false,
    this.hasAttachment = false,
  });

  String get displayFrom =>
      fromName.isNotEmpty ? fromName : (from.isNotEmpty ? from : '—');

  factory InboxMessageSummary.fromJson(Map<String, dynamic> json) {
    return InboxMessageSummary(
      uid: int.tryParse('${json['uid']}') ?? 0,
      msgno: int.tryParse('${json['msgno']}') ?? 0,
      subject: (json['subject'] ?? '(بدون موضوع)').toString(),
      from: (json['from'] ?? '').toString(),
      fromName: (json['from_name'] ?? '').toString(),
      to: (json['to'] ?? '').toString(),
      dateRaw: (json['date_raw'] ?? '').toString(),
      dateFa: (json['date_fa'] ?? '').toString(),
      timestamp: int.tryParse('${json['timestamp'] ?? json['ts'] ?? 0}') ?? 0,
      unseen: json['unseen'] == true ||
          json['unseen'] == 1 ||
          json['unseen'] == 'U' ||
          (json['seen'] == false || json['seen'] == 0),
      hasAttachment: json['has_attachment'] == true ||
          json['has_attachments'] == true ||
          (json['attachments'] is List && (json['attachments'] as List).isNotEmpty),
    );
  }
}

class InboxAttachment {
  final String part;
  final String filename;
  final String mime;
  final int size;

  const InboxAttachment({
    this.part = '1',
    this.filename = '',
    this.mime = '',
    this.size = 0,
  });

  factory InboxAttachment.fromJson(Map<String, dynamic> json) {
    return InboxAttachment(
      part: (json['part'] ?? json['part_no'] ?? '1').toString(),
      filename: (json['filename'] ?? json['name'] ?? 'file').toString(),
      mime: (json['mime'] ?? json['type'] ?? '').toString(),
      size: int.tryParse('${json['size'] ?? 0}') ?? 0,
    );
  }
}

class InboxMessageDetail {
  final int uid;
  final String subject;
  final String from;
  final String fromName;
  final String to;
  final String dateFa;
  final String dateRaw;
  final String htmlBody;
  final String textBody;
  final List<InboxAttachment> attachments;
  final bool unseen;

  const InboxMessageDetail({
    required this.uid,
    this.subject = '',
    this.from = '',
    this.fromName = '',
    this.to = '',
    this.dateFa = '',
    this.dateRaw = '',
    this.htmlBody = '',
    this.textBody = '',
    this.attachments = const [],
    this.unseen = false,
  });

  String get bodyPreview {
    if (textBody.trim().isNotEmpty) return textBody.trim();
    // strip tags roughly
    return htmlBody
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  factory InboxMessageDetail.fromJson(Map<String, dynamic> json) {
    // API may nest under 'message' or be flat
    final m = json['message'] is Map
        ? Map<String, dynamic>.from(json['message'] as Map)
        : json;

    final atts = <InboxAttachment>[];
    final rawAtt = m['attachments'] ?? json['attachments'];
    if (rawAtt is List) {
      for (final e in rawAtt) {
        if (e is Map) {
          atts.add(InboxAttachment.fromJson(Map<String, dynamic>.from(e)));
        }
      }
    }

    return InboxMessageDetail(
      uid: int.tryParse('${m['uid'] ?? json['uid']}') ?? 0,
      subject: (m['subject'] ?? '(بدون موضوع)').toString(),
      from: (m['from'] ?? '').toString(),
      fromName: (m['from_name'] ?? '').toString(),
      to: (m['to'] ?? '').toString(),
      dateFa: (m['date_fa'] ?? '').toString(),
      dateRaw: (m['date_raw'] ?? m['date'] ?? '').toString(),
      htmlBody: (m['body_html'] ?? m['html'] ?? '').toString(),
      textBody: (m['body_text'] ?? m['text'] ?? m['body'] ?? '').toString(),
      attachments: atts,
      unseen: m['unseen'] == true,
    );
  }
}

class InboxListResult {
  final List<InboxMessageSummary> items;
  final int total;
  final int page;
  final int perPage;
  final int totalPages;
  final String? error;

  const InboxListResult({
    required this.items,
    this.total = 0,
    this.page = 1,
    this.perPage = 20,
    this.totalPages = 1,
    this.error,
  });

  factory InboxListResult.fromJson(Map<String, dynamic> json) {
    final items = <InboxMessageSummary>[];
    final raw = json['items'] ?? json['messages'] ?? json['list'];
    if (raw is List) {
      for (final e in raw) {
        if (e is Map) {
          items.add(InboxMessageSummary.fromJson(Map<String, dynamic>.from(e)));
        }
      }
    }
    final total = int.tryParse('${json['total'] ?? items.length}') ?? items.length;
    final per = int.tryParse('${json['per_page'] ?? 20}') ?? 20;
    final page = int.tryParse('${json['page'] ?? 1}') ?? 1;
    final pages = int.tryParse('${json['pages'] ?? json['total_pages']}') ??
        (total == 0 ? 1 : ((total + per - 1) ~/ per));
    return InboxListResult(
      items: items,
      total: total,
      page: page,
      perPage: per,
      totalPages: pages < 1 ? 1 : pages,
    );
  }
}
