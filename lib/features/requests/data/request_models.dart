class RequestAttachment {
  final String name;
  final String? url;
  final String? path;
  final String? type;
  final int? size;

  const RequestAttachment({
    required this.name,
    this.url,
    this.path,
    this.type,
    this.size,
  });

  factory RequestAttachment.fromJson(Map<String, dynamic> json) {
    return RequestAttachment(
      name: (json['name'] ??
              json['file_name'] ??
              json['filename'] ??
              'فایل پیوست')
          .toString(),
      url: json['url']?.toString(),
      // ===== کلید اصلاح‌شده: file_path =====
      path: json['file_path']?.toString() ?? json['path']?.toString(),
      type: json['type']?.toString() ?? json['mime_type']?.toString(),
      size: int.tryParse(
        '${json['size'] ?? json['file_size'] ?? ''}',
      ),
    );
  }

  // ===== متد تولید URL =====
  String? get downloadUrl {
    if (url != null && url!.isNotEmpty) {
      return url;
    }

    if (path != null && path!.isNotEmpty) {
      final fileName = path!.split('/').last;
      if (fileName.isNotEmpty) {
        return 'https://ezlens.ir/wp-content/uploads/ei-uploads/$fileName';
      }
    }

    return null;
  }
}

// ===== بقیه کلاس‌ها (RequestNote, RequestItem, RequestsResponse) مانند قبل =====


class RequestNote {
  final int? id;
  final String author;
  final String text;
  final String? date;

  const RequestNote({
    this.id,
    required this.author,
    required this.text,
    this.date,
  });

  factory RequestNote.fromJson(Map<String, dynamic> json) {
    return RequestNote(
      id: int.tryParse('${json['id'] ?? ''}'),
      author: (json['author'] ??
              json['user_name'] ??
              json['author_name'] ??
              'مدیر')
          .toString(),
      text: (json['text'] ??
              json['content'] ??
              json['note'] ??
              '')
          .toString(),
      date: json['date']?.toString() ??
          json['created_at']?.toString(),
    );
  }
}

class RequestItem {
  final int id;
  final int? formId;
  final String? formTitle;
  final String? formKey;
  final int? sourcePageId;
  final String? sourcePageTitle;
  final String? sourcePageUrl;
  final String? name;
  final String? email;
  final String? phone;
  final String? subject;
  final String? message;
  final String status;
  final String? date;
  final String? createdAt;
  final int? userId;
  final List<RequestAttachment> files;
  final Map<String, dynamic> meta;
  final Map<String, dynamic> fields;
  final List<RequestNote> notes;

  const RequestItem({
    required this.id,
    this.formId,
    this.formTitle,
    this.formKey,
    this.sourcePageId,
    this.sourcePageTitle,
    this.sourcePageUrl,
    this.name,
    this.email,
    this.phone,
    this.subject,
    this.message,
    required this.status,
    this.date,
    this.createdAt,
    this.userId,
    this.files = const [],
    this.meta = const {},
    this.fields = const {},
    this.notes = const [],
  });

  factory RequestItem.fromJson(Map<String, dynamic> json) {
    final rawFiles =
        json['files'] ??
        json['attachments'] ??
        json['file'];

    final rawMeta = json['meta'];
    final rawFields =
        json['fields'] ??
        json['form_fields'] ??
        json['form_data_decoded'] ??
        json['form_data'];

    final rawNotes = json['notes'];

    List<RequestAttachment> parseFiles() {
      if (rawFiles is List) {
        return rawFiles
            .whereType<Map>()
            .map(
              (e) => RequestAttachment.fromJson(
                Map<String, dynamic>.from(e),
              ),
            )
            .toList();
      }

      if (rawFiles is Map) {
        return [
          RequestAttachment.fromJson(
            Map<String, dynamic>.from(rawFiles),
          ),
        ];
      }

      return const [];
    }

    Map<String, dynamic> parseMap(dynamic value) {
      if (value is Map) {
        return Map<String, dynamic>.from(value);
      }
      return {};
    }

    List<RequestNote> parseNotes() {
      if (rawNotes is List) {
        return rawNotes
            .whereType<Map>()
            .map(
              (e) => RequestNote.fromJson(
                Map<String, dynamic>.from(e),
              ),
            )
            .toList();
      }
      return const [];
    }

    final sourcePageId = int.tryParse(
      '${json['source_page_id'] ??
          json['sourcePageId'] ??
          json['page_id'] ??
          ''}',
    );

    final sourcePageTitle =
        json['source_page_title']?.toString() ??
        json['sourcePageTitle']?.toString() ??
        json['page_title']?.toString() ??
        json['source_page_name']?.toString();

    final sourcePageUrl =
        json['source_page_url']?.toString() ??
        json['sourcePageUrl']?.toString() ??
        json['page_url']?.toString() ??
        json['source_url']?.toString();

    return RequestItem(
      id: int.tryParse('${json['id'] ?? 0}') ?? 0,

      formId: int.tryParse(
        '${json['form_id'] ?? json['formId'] ?? ''}',
      ),

      formTitle:
          json['form_title']?.toString() ??
          json['formTitle']?.toString() ??
          json['form_name']?.toString(),

      formKey:
          json['form_key']?.toString() ??
          json['formKey']?.toString(),

      sourcePageId: sourcePageId,
      sourcePageTitle: sourcePageTitle,
      sourcePageUrl: sourcePageUrl,

      name: json['name']?.toString(),
      email: json['email']?.toString(),
      phone: json['phone']?.toString(),
      subject: json['subject']?.toString(),
      message: json['message']?.toString(),

      status: (json['status'] ?? 'new').toString(),

      date:
          json['date']?.toString() ??
          json['created_at']?.toString(),

      createdAt: json['created_at']?.toString(),

      userId: int.tryParse(
        '${json['user_id'] ?? json['userId'] ?? ''}',
      ),

      files: parseFiles(),
      meta: parseMap(rawMeta),
      fields: parseMap(rawFields),
      notes: parseNotes(),
    );
  }

  String get displayFormTitle {
    if (formTitle != null && formTitle!.trim().isNotEmpty) {
      return formTitle!.trim();
    }
    if (formKey != null && formKey!.trim().isNotEmpty) {
      return formKey!.trim();
    }
    if (formId != null) {
      return 'فرم #$formId';
    }
    return 'فرم نامشخص';
  }

  String get displaySourcePage {
    if (sourcePageTitle != null &&
        sourcePageTitle!.trim().isNotEmpty) {
      return sourcePageTitle!.trim();
    }
    if (sourcePageUrl != null &&
        sourcePageUrl!.trim().isNotEmpty) {
      return sourcePageUrl!.trim();
    }
    return 'صفحه نامشخص';
  }

  RequestItem copyWith({
    String? status,
    List<RequestNote>? notes,
  }) {
    return RequestItem(
      id: id,
      formId: formId,
      formTitle: formTitle,
      formKey: formKey,
      sourcePageId: sourcePageId,
      sourcePageTitle: sourcePageTitle,
      sourcePageUrl: sourcePageUrl,
      name: name,
      email: email,
      phone: phone,
      subject: subject,
      message: message,
      status: status ?? this.status,
      date: date,
      createdAt: createdAt,
      userId: userId,
      files: files,
      meta: meta,
      fields: fields,
      notes: notes ?? this.notes,
    );
  }
}

class RequestsResponse {
  final List<RequestItem> items;
  final int total;
  final int totalPages;
  final int page;
  final int perPage;
  final Map<String, int> counts;

  const RequestsResponse({
    required this.items,
    required this.total,
    required this.totalPages,
    required this.page,
    required this.perPage,
    this.counts = const {},
  });

  factory RequestsResponse.fromJson(Map<String, dynamic> json) {
    final rawItems =
        json['items'] ??
        json['data'] ??
        json['requests'] ??
        [];

    final rawCounts = json['counts'];

    return RequestsResponse(
      items: rawItems is List
          ? rawItems
              .whereType<Map>()
              .map(
                (e) => RequestItem.fromJson(
                  Map<String, dynamic>.from(e),
                ),
              )
              .toList()
          : const [],

      total: int.tryParse(
            '${json['total'] ?? 0}',
          ) ??
          0,

      totalPages: int.tryParse(
            '${json['total_pages'] ??
                json['totalPages'] ??
                1}',
          ) ??
          1,

      page: int.tryParse(
            '${json['page'] ?? 1}',
          ) ??
          1,

      perPage: int.tryParse(
            '${json['per_page'] ??
                json['perPage'] ??
                10}',
          ) ??
          10,

      counts: rawCounts is Map
          ? rawCounts.map(
              (key, value) => MapEntry(
                key.toString(),
                int.tryParse('$value') ?? 0,
              ),
            )
          : const {},
    );
  }
}