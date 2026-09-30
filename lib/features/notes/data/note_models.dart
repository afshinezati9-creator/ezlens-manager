import 'package:equatable/equatable.dart';

// ============================================================
// ۱. Enum‌ها (رنگ‌ها و اولویت‌ها)
// ============================================================

enum NoteColor {
  yellow,
  blue,
  red,
  green,
  purple,
  orange,
  gray,
}

enum NotePriority {
  low,
  medium,
  high,
  critical,
}

// ============================================================
// ۲. تبدیل‌های کمکی Enum
// ============================================================

extension NoteColorExtension on NoteColor {
  String get label {
    switch (this) {
      case NoteColor.yellow:
        return 'زرد';
      case NoteColor.blue:
        return 'آبی';
      case NoteColor.red:
        return 'قرمز';
      case NoteColor.green:
        return 'سبز';
      case NoteColor.purple:
        return 'بنفش';
      case NoteColor.orange:
        return 'نارنجی';
      case NoteColor.gray:
        return 'خاکستری';
    }
  }

  String get hex {
    switch (this) {
      case NoteColor.yellow:
        return '#FDE047';
      case NoteColor.blue:
        return '#60A5FA';
      case NoteColor.red:
        return '#F87171';
      case NoteColor.green:
        return '#34D399';
      case NoteColor.purple:
        return '#A78BFA';
      case NoteColor.orange:
        return '#FB923C';
      case NoteColor.gray:
        return '#9CA3AF';
    }
  }

  static NoteColor fromString(String value) {
    return NoteColor.values.firstWhere(
      (e) => e.name == value,
      orElse: () => NoteColor.yellow,
    );
  }
}

extension NotePriorityExtension on NotePriority {
  String get label {
    switch (this) {
      case NotePriority.low:
        return 'کم';
      case NotePriority.medium:
        return 'متوسط';
      case NotePriority.high:
        return 'بالا';
      case NotePriority.critical:
        return 'بحرانی';
    }
  }

  static NotePriority fromString(String value) {
    return NotePriority.values.firstWhere(
      (e) => e.name == value,
      orElse: () => NotePriority.low,
    );
  }
}

// ============================================================
// ۳. مدل آیتم چک‌لیست
// ============================================================

class ChecklistItem extends Equatable {
  final String text;
  final bool done;

  const ChecklistItem({
    required this.text,
    this.done = false,
  });

  factory ChecklistItem.fromJson(Map<String, dynamic> json) {
    return ChecklistItem(
      text: json['text']?.toString() ?? '',
      done: json['done'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
    'text': text,
    'done': done,
  };

  ChecklistItem copyWith({
    String? text,
    bool? done,
  }) {
    return ChecklistItem(
      text: text ?? this.text,
      done: done ?? this.done,
    );
  }

  @override
  List<Object?> get props => [text, done];
}

// ============================================================
// ۴. مدل فایل پیوست
// ============================================================

class NoteFile extends Equatable {
  final String? url;
  final String path;
  final String name;
  final int? size;
  final String? type;

  const NoteFile({
    this.url,
    required this.path,
    required this.name,
    this.size,
    this.type,
  });

  factory NoteFile.fromJson(Map<String, dynamic> json) {
    return NoteFile(
      url: json['url']?.toString(),
      path: json['path']?.toString() ?? '',
      name: json['name']?.toString() ?? 'فایل',
      size: int.tryParse('${json['size'] ?? 0}'),
      type: json['type']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    if (url != null) 'url': url,
    'path': path,
    'name': name,
    if (size != null) 'size': size,
    if (type != null) 'type': type,
  };

  String? get downloadUrl {
    if (url != null && url!.isNotEmpty) return url;
    if (path.isNotEmpty) {
      final fileName = path.split('/').last;
      if (fileName.isNotEmpty) {
        return 'https://ezlens.ir/wp-content/uploads/ei-notes/$fileName';
      }
    }
    return null;
  }

  @override
  List<Object?> get props => [url, path, name, size, type];
}

// ============================================================
// ۵. مدل پاسخ (کامنت)
// ============================================================

class NoteReply extends Equatable {
  final String id;
  final String authorName;
  final String content;
  final String date;
  final String? parentId;

  const NoteReply({
    required this.id,
    required this.authorName,
    required this.content,
    required this.date,
    this.parentId,
  });

  factory NoteReply.fromJson(Map<String, dynamic> json) {
    return NoteReply(
      id: json['id']?.toString() ?? '',
      authorName: json['author_name']?.toString() ?? 'نامشخص',
      content: json['content']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      parentId: json['parent_id']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'author_name': authorName,
    'content': content,
    'date': date,
    if (parentId != null) 'parent_id': parentId,
  };

  NoteReply copyWith({
    String? id,
    String? authorName,
    String? content,
    String? date,
    String? parentId,
  }) {
    return NoteReply(
      id: id ?? this.id,
      authorName: authorName ?? this.authorName,
      content: content ?? this.content,
      date: date ?? this.date,
      parentId: parentId ?? this.parentId,
    );
  }

  @override
  List<Object?> get props => [id, authorName, content, date, parentId];
}

// ============================================================
// ۶. مدل اصلی یادداشت
// ============================================================

class NoteItem extends Equatable {
  final int id;
  final String title;
  final String content;
  final NoteColor color;
  final NotePriority priority;
  final bool pinned;
  final String? dueDate;
  final String? remindAt;
  final List<ChecklistItem> checklist;
  final List<NoteFile> files;
  final List<String> tags;
  final List<NoteReply> replies;
  final String date;
  final String modified;
  final int author;
  final String authorName;

  const NoteItem({
    required this.id,
    required this.title,
    required this.content,
    this.color = NoteColor.yellow,
    this.priority = NotePriority.low,
    this.pinned = false,
    this.dueDate,
    this.remindAt,
    this.checklist = const [],
    this.files = const [],
    this.tags = const [],
    this.replies = const [],
    required this.date,
    required this.modified,
    required this.author,
    required this.authorName,
  });

  factory NoteItem.fromJson(Map<String, dynamic> json) {
    return NoteItem(
      id: int.tryParse('${json['id'] ?? 0}') ?? 0,
      title: json['title']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      color: NoteColorExtension.fromString(json['color']?.toString() ?? 'yellow'),
      priority: NotePriorityExtension.fromString(json['priority']?.toString() ?? 'low'),
      pinned: json['pinned'] == true,
      dueDate: json['due_date']?.toString(),
      remindAt: json['remind_at']?.toString(),
      checklist: (json['checklist'] as List?)
          ?.map((e) => ChecklistItem.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      files: (json['files'] as List?)
          ?.map((e) => NoteFile.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      tags: (json['tags'] as List?)?.map((e) => e.toString()).toList() ?? [],
      replies: (json['replies'] as List?)
          ?.map((e) => NoteReply.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      date: json['date']?.toString() ?? '',
      modified: json['modified']?.toString() ?? '',
      author: int.tryParse('${json['author'] ?? 0}') ?? 0,
      authorName: json['author_name']?.toString() ?? 'نامشخص',
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'content': content,
    'color': color.name,
    'priority': priority.name,
    'pinned': pinned,
    if (dueDate != null) 'due_date': dueDate,
    if (remindAt != null) 'remind_at': remindAt,
    'checklist': checklist.map((e) => e.toJson()).toList(),
    'files': files.map((e) => e.toJson()).toList(),
    'tags': tags,
    'replies': replies.map((e) => e.toJson()).toList(),
  };

  NoteItem copyWith({
    int? id,
    String? title,
    String? content,
    NoteColor? color,
    NotePriority? priority,
    bool? pinned,
    String? dueDate,
    String? remindAt,
    List<ChecklistItem>? checklist,
    List<NoteFile>? files,
    List<String>? tags,
    List<NoteReply>? replies,
    String? date,
    String? modified,
    int? author,
    String? authorName,
  }) {
    return NoteItem(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      color: color ?? this.color,
      priority: priority ?? this.priority,
      pinned: pinned ?? this.pinned,
      dueDate: dueDate ?? this.dueDate,
      remindAt: remindAt ?? this.remindAt,
      checklist: checklist ?? this.checklist,
      files: files ?? this.files,
      tags: tags ?? this.tags,
      replies: replies ?? this.replies,
      date: date ?? this.date,
      modified: modified ?? this.modified,
      author: author ?? this.author,
      authorName: authorName ?? this.authorName,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    content,
    color,
    priority,
    pinned,
    dueDate,
    remindAt,
    checklist,
    files,
    tags,
    replies,
    date,
    modified,
    author,
    authorName,
  ];
}

// ============================================================
// ۷. پاسخ لیست یادداشت‌ها (با صفحه‌بندی) - اصلاح شده
// ============================================================

class NotesResponse {
  final List<NoteItem> items;
  final int total;
  final int totalPages;
  final int page;
  final int perPage;

  const NotesResponse({
    required this.items,
    required this.total,
    required this.totalPages,
    required this.page,
    required this.perPage,
  });

  factory NotesResponse.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] ?? json['data'] ?? [];

    return NotesResponse(
      items: rawItems is List
          ? rawItems
              .whereType<Map<String, dynamic>>()
              .map((e) => NoteItem.fromJson(e))
              .toList()
          : [],
      total: int.tryParse('${json['total'] ?? 0}') ?? 0,
      totalPages: int.tryParse('${json['total_pages'] ?? json['totalPages'] ?? 1}') ?? 1,
      page: int.tryParse('${json['page'] ?? 1}') ?? 1,
      perPage: int.tryParse('${json['per_page'] ?? json['perPage'] ?? 10}') ?? 10,
    );
  }
}

// ============================================================
// ۸. مدل قالب‌های آماده
// ============================================================

class NoteTemplate {
  final String id;
  final String title;
  final String icon;
  final NoteColor color;
  final NotePriority priority;
  final List<String> tags;
  final String content;
  final List<ChecklistItem> checklist;

  const NoteTemplate({
    required this.id,
    required this.title,
    required this.icon,
    required this.color,
    required this.priority,
    required this.tags,
    required this.content,
    required this.checklist,
  });

  factory NoteTemplate.fromJson(Map<String, dynamic> json) {
    return NoteTemplate(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      icon: json['icon']?.toString() ?? '📝',
      color: NoteColorExtension.fromString(json['color']?.toString() ?? 'yellow'),
      priority: NotePriorityExtension.fromString(json['priority']?.toString() ?? 'low'),
      tags: (json['tags'] as List?)?.map((e) => e.toString()).toList() ?? [],
      content: json['content']?.toString() ?? '',
      checklist: (json['checklist'] as List?)
          ?.map((e) => ChecklistItem.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
    );
  }
}