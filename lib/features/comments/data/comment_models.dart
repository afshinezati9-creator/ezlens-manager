// lib/features/comments/data/comment_models.dart

// ============================================================
// Enum وضعیت‌های نظر (بدون تغییر)
// ============================================================
enum CommentStatus {
  approved,
  pending,
  spam,
  trash,
}

extension CommentStatusExtension on CommentStatus {
  String get label {
    switch (this) {
      case CommentStatus.approved:
        return 'تأیید شده';
      case CommentStatus.pending:
        return 'در انتظار';
      case CommentStatus.spam:
        return 'اسپم';
      case CommentStatus.trash:
        return 'حذف شده';
    }
  }

  String get apiValue {
    switch (this) {
      case CommentStatus.approved:
        return 'approved';
      case CommentStatus.pending:
        return 'pending';
      case CommentStatus.spam:
        return 'spam';
      case CommentStatus.trash:
        return 'trash';
    }
  }

  static CommentStatus fromString(String value) {
    switch (value) {
      case 'approved':
        return CommentStatus.approved;
      case 'pending':
        return CommentStatus.pending;
      case 'spam':
        return CommentStatus.spam;
      case 'trash':
        return CommentStatus.trash;
      default:
        return CommentStatus.pending;
    }
  }
}

// ============================================================
// مدل نظر
// ============================================================
class Comment {
  final int id;
  final int author;
  final String authorName;
  final String authorEmail;
  final String? authorUrl;
  final String? authorAvatar;
  final String content;
  final DateTime date;
  final CommentStatus status;
  final String link;
  final int post;
  final String postTitle;
  final String postLink;
  final String postType;
  final String postTypeLabel;
  final int parent;
  final String? ip;
  final String? userAgent;
  List<Comment>? children; // ← غیر final برای ساخت درخت
  final String? authorRole;
  final String? authorPhone;

  Comment({
    required this.id,
    required this.author,
    required this.authorName,
    required this.authorEmail,
    this.authorUrl,
    this.authorAvatar,
    required this.content,
    required this.date,
    required this.status,
    required this.link,
    required this.post,
    required this.postTitle,
    required this.postLink,
    required this.postType,
    required this.postTypeLabel,
    required this.parent,
    this.ip,
    this.userAgent,
    this.children,
    this.authorRole,
    this.authorPhone,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    // ===== ۱. استخراج نوع پست و لینک از _links =====
    String postType = '';
    String postLink = '';
    String postTypeLabel = '';
    int postId = json['post'] ?? 0;

    // ابتدا از _links استخراج می‌کنیم
    if (json['_links'] != null) {
      final links = json['_links'] as Map<String, dynamic>;
      if (links['up'] != null && (links['up'] as List).isNotEmpty) {
        final up = (links['up'] as List).first;
        postType = up['post_type'] ?? '';
        postLink = up['href'] ?? '';
        final labels = {
          'product': 'محصول',
          'post': 'نوشته',
          'page': 'برگه',
        };
        postTypeLabel = labels[postType] ?? postType;
      }
    }

    // ===== ۲. استخراج عنوان پست از _embedded =====
    String postTitle = '';
    if (json['_embedded'] != null) {
      final embedded = json['_embedded'] as Map<String, dynamic>;
      // بررسی up در embedded
      if (embedded['up'] != null && (embedded['up'] as List).isNotEmpty) {
        final up = (embedded['up'] as List).first;
        if (up['title'] != null) {
          postTitle = up['title']['rendered'] ?? up['title'] ?? '';
        }
      }
      // اگر از up نیامد، از خود json امتحان کن
      if (postTitle.isEmpty) {
        postTitle = json['post_title'] ?? '';
      }
    }
    // اگر باز هم خالی بود، از عدد پست استفاده کن
    if (postTitle.isEmpty) {
      postTitle = 'پست شماره $postId';
    }

    // ===== ۳. استخراج محتوا =====
    String content = '';
    if (json['content'] != null) {
      if (json['content'] is Map) {
        content = json['content']['rendered'] ?? '';
      } else {
        content = json['content'].toString();
      }
    }

    // ===== ۴. استخراج آواتار =====
    String? avatar;
    if (json['author_avatar_urls'] != null) {
      final avatars = json['author_avatar_urls'] as Map<String, dynamic>;
      avatar = avatars['96'] ?? avatars['48'] ?? avatars['24'];
    }

    // ===== ۵. استخراج نقش کاربر و تلفن =====
    String? authorRole;
    String? authorPhone;
    final authorId = json['author'] ?? 0;

    if (authorId == 0) {
      authorRole = 'guest'; // مهمان
    } else {
      // اگر اطلاعات کاربر در _embedded موجود باشد
      if (json['_embedded'] != null) {
        final embedded = json['_embedded'] as Map<String, dynamic>;
        if (embedded['author'] != null && (embedded['author'] as List).isNotEmpty) {
          final authorData = (embedded['author'] as List).first;
          // نقش کاربر
          final roles = authorData['roles'] as List?;
          if (roles != null && roles.isNotEmpty) {
            authorRole = roles.first;
          } else {
            authorRole = 'subscriber';
          }
          // استخراج تلفن از billing
          final billing = authorData['billing'] as Map<String, dynamic>?;
          if (billing != null && billing['phone'] != null) {
            authorPhone = billing['phone'].toString();
          }
          // اگر تلفن در billing نبود، از meta_data امتحان کن
          if (authorPhone == null || authorPhone.isEmpty) {
            final meta = authorData['meta_data'] as List?;
            if (meta != null) {
              for (final item in meta) {
                if (item['key'] == 'billing_phone') {
                  authorPhone = item['value']?.toString();
                  break;
                }
              }
            }
          }
        }
      }
    }

    // Flat fields from manager REST
    if ((json['post_title'] ?? '').toString().isNotEmpty) {
      postTitle = json['post_title'].toString();
    }
    if ((json['post_type'] ?? '').toString().isNotEmpty) {
      postType = json['post_type'].toString();
    }
    if ((json['post_type_label'] ?? '').toString().isNotEmpty) {
      postTypeLabel = json['post_type_label'].toString();
    }
    if ((json['post_link'] ?? '').toString().isNotEmpty) {
      postLink = json['post_link'].toString();
    }
    if ((json['author_phone'] ?? '').toString().isNotEmpty) {
      authorPhone = json['author_phone'].toString();
    }
    if ((json['author_role'] ?? '').toString().isNotEmpty) {
      authorRole = json['author_role'].toString();
    }
    final ip = (json['author_ip'] ?? json['ip'] ?? '').toString();
    final ua = (json['author_user_agent'] ?? json['user_agent'] ?? '').toString();

    return Comment(
      id: json['id'] ?? 0,
      author: authorId is int ? authorId : int.tryParse('$authorId') ?? 0,
      authorName: json['author_name'] ?? 'کاربر مهمان',
      authorEmail: json['author_email'] ?? '',
      authorUrl: json['author_url'],
      authorAvatar: avatar,
      content: content,
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
      status: CommentStatusExtension.fromString(json['status'] ?? 'pending'),
      link: json['link'] ?? '',
      post: postId is int ? postId : int.tryParse('$postId') ?? 0,
      postTitle: postTitle,
      postLink: postLink,
      postType: postType,
      postTypeLabel: postTypeLabel,
      parent: int.tryParse('${json['parent'] ?? 0}') ?? 0,
      ip: ip.isEmpty ? null : ip,
      userAgent: ua.isEmpty ? null : ua,
      children: null,
      authorRole: authorRole,
      authorPhone: authorPhone,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'author': author,
      'author_name': authorName,
      'author_email': authorEmail,
      'author_url': authorUrl,
      'author_avatar': authorAvatar,
      'content': content,
      'date': date.toIso8601String(),
      'status': status.apiValue,
      'link': link,
      'post': post,
      'post_title': postTitle,
      'post_link': postLink,
      'post_type': postType,
      'post_type_label': postTypeLabel,
      'parent': parent,
      'ip': ip,
      'user_agent': userAgent,
      'author_role': authorRole,
      'author_phone': authorPhone,
      if (children != null) 'children': children!.map((e) => e.toJson()).toList(),
    };
  }

  Comment copyWith({
    int? id,
    int? author,
    String? authorName,
    String? authorEmail,
    String? authorUrl,
    String? authorAvatar,
    String? content,
    DateTime? date,
    CommentStatus? status,
    String? link,
    int? post,
    String? postTitle,
    String? postLink,
    String? postType,
    String? postTypeLabel,
    int? parent,
    String? ip,
    String? userAgent,
    List<Comment>? children,
    String? authorRole,
    String? authorPhone,
  }) {
    return Comment(
      id: id ?? this.id,
      author: author ?? this.author,
      authorName: authorName ?? this.authorName,
      authorEmail: authorEmail ?? this.authorEmail,
      authorUrl: authorUrl ?? this.authorUrl,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      content: content ?? this.content,
      date: date ?? this.date,
      status: status ?? this.status,
      link: link ?? this.link,
      post: post ?? this.post,
      postTitle: postTitle ?? this.postTitle,
      postLink: postLink ?? this.postLink,
      postType: postType ?? this.postType,
      postTypeLabel: postTypeLabel ?? this.postTypeLabel,
      parent: parent ?? this.parent,
      ip: ip ?? this.ip,
      userAgent: userAgent ?? this.userAgent,
      children: children ?? this.children,
      authorRole: authorRole ?? this.authorRole,
      authorPhone: authorPhone ?? this.authorPhone,
    );
  }

  bool get hasChildren => children != null && children!.isNotEmpty;
}

// ============================================================
// مدل پروفایل کاربر (بدون تغییر)
// ============================================================
class UserProfile {
  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String role;
  final String? phone;
  final String? city;
  final String? address;
  final String? totalSpent;
  final DateTime? dateCreated;

  UserProfile({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.role,
    this.phone,
    this.city,
    this.address,
    this.totalSpent,
    this.dateCreated,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final billing = json['billing'] ?? {};
    final meta = json['meta_data'] ?? [];

    String? totalSpent;
    for (final item in meta) {
      if (item['key'] == 'total_spent') {
        totalSpent = item['value']?.toString();
        break;
      }
    }

    return UserProfile(
      id: json['id'] ?? 0,
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'subscriber',
      phone: billing['phone'],
      city: billing['city'],
      address: billing['address_1'],
      totalSpent: totalSpent,
      dateCreated: DateTime.tryParse(json['date_created'] ?? ''),
    );
  }

  String get fullName => '$firstName $lastName'.trim();
  String get roleLabel {
    switch (role) {
      case 'administrator':
        return 'مدیر';
      case 'customer':
        return 'مشتری';
      case 'subscriber':
        return 'کاربر';
      default:
        return 'مهمان';
    }
  }
}