// lib/features/articles/data/article_models.dart

// ============================
//  مدل دسته‌بندی (Category)
// ============================
class ArticleCategory {
  final int id;
  final String name;
  final int? parent;

  ArticleCategory({
    required this.id,
    required this.name,
    this.parent,
  });

  factory ArticleCategory.fromJson(Map<String, dynamic> json) {
    return ArticleCategory(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'بدون نام',
      parent: json['parent'] is int ? json['parent'] : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (parent != null) 'parent': parent,
    };
  }
}

// ============================
//  مدل تگ (Tag)
// ============================
class ArticleTag {
  final int id;
  final String name;

  ArticleTag({
    required this.id,
    required this.name,
  });

  factory ArticleTag.fromJson(Map<String, dynamic> json) {
    return ArticleTag(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'بدون تگ',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name};
  }
}

// ============================
//  مدل تصویر شاخص (Featured Image)
// ============================
class FeaturedImage {
  final int id;
  final String src;
  final String name;

  FeaturedImage({
    required this.id,
    required this.src,
    required this.name,
  });

  factory FeaturedImage.fromJson(Map<String, dynamic> json) {
    return FeaturedImage(
      id: json['id'] ?? 0,
      src: json['src'] ?? json['source_url'] ?? '',
      name: json['name'] ?? json['title']?['rendered'] ?? 'تصویر',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'src': src, 'name': name};
  }
}

// ============================
//  وضعیت مقاله (Enum)
// ============================
enum ArticleStatus {
  publish,
  draft,
  pending,
  private,
  trash,
}

extension ArticleStatusExtension on ArticleStatus {
  String get string {
    switch (this) {
      case ArticleStatus.publish:
        return 'publish';
      case ArticleStatus.draft:
        return 'draft';
      case ArticleStatus.pending:
        return 'pending';
      case ArticleStatus.private:
        return 'private';
      case ArticleStatus.trash:
        return 'trash';
    }
  }

  static ArticleStatus fromString(String value) {
    switch (value) {
      case 'publish':
        return ArticleStatus.publish;
      case 'draft':
        return ArticleStatus.draft;
      case 'pending':
        return ArticleStatus.pending;
      case 'private':
        return ArticleStatus.private;
      case 'trash':
        return ArticleStatus.trash;
      default:
        return ArticleStatus.draft;
    }
  }
}

// ============================
//  مدل اصلی مقاله (Article)
// ============================
class Article {
  final int id;
  final String title;
  final String slug;
  final ArticleStatus status;
  final String? excerpt;
  final String content;
  final DateTime? date;
  final DateTime? modified;
  final List<ArticleCategory> categories;
  final List<ArticleTag> tags;
  final int featuredMedia;
  final FeaturedImage? featuredImage;
  final String permalink;
  final int views;
  final String descriptionCss;
  final String descriptionJs;
  final String seoTitle;
  final String seoDescription;
  final String seoKeywords;

  Article({
    required this.id,
    required this.title,
    required this.slug,
    required this.status,
    this.excerpt,
    required this.content,
    this.date,
    this.modified,
    required this.categories,
    required this.tags,
    required this.featuredMedia,
    this.featuredImage,
    required this.permalink,
    required this.views,
    required this.descriptionCss,
    required this.descriptionJs,
    required this.seoTitle,
    required this.seoDescription,
    required this.seoKeywords,
  });

  // ===== تبدیل از JSON (دریافت از وردپرس) =====
  factory Article.fromJson(Map<String, dynamic> json) {
    // --- ۱. استخراج دسته‌ها ---
    List<ArticleCategory> categories = [];
    if (json['_embedded'] != null &&
        json['_embedded']['wp:term'] != null &&
        (json['_embedded']['wp:term'] as List).isNotEmpty) {
      final termList = json['_embedded']['wp:term'][0] as List?;
      if (termList != null) {
        categories = termList
            .whereType<Map>()
            .map((e) => ArticleCategory.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    } else if (json['categories'] != null && json['categories'] is List) {
      final rawCats = json['categories'] as List;
      if (rawCats.isNotEmpty && rawCats.first is Map) {
        categories = rawCats
            .whereType<Map>()
            .map((e) => ArticleCategory.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      } else {
        // فقط ID داریم — نام رو موقتاً خالی می‌ذاریم
        categories = rawCats
            .whereType<int>()
            .map((id) => ArticleCategory(id: id, name: ''))
            .toList();
      }
    }

    // --- ۲. استخراج تگ‌ها ---
    List<ArticleTag> tags = [];
    if (json['_embedded'] != null &&
        json['_embedded']['wp:term'] != null &&
        (json['_embedded']['wp:term'] as List).length > 1) {
      final tagList = json['_embedded']['wp:term'][1] as List?;
      if (tagList != null) {
        tags = tagList
            .whereType<Map>()
            .map((e) => ArticleTag.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    } else if (json['tags'] != null && json['tags'] is List) {
      final rawTags = json['tags'] as List;
      if (rawTags.isNotEmpty && rawTags.first is Map) {
        tags = rawTags
            .whereType<Map>()
            .map((e) => ArticleTag.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      } else {
        tags = rawTags
            .whereType<int>()
            .map((id) => ArticleTag(id: id, name: ''))
            .toList();
      }
    }

    // --- ۳. استخراج تصویر شاخص ---
    FeaturedImage? featuredImage;
    if (json['_embedded'] != null &&
        json['_embedded']['wp:featuredmedia'] != null &&
        (json['_embedded']['wp:featuredmedia'] as List).isNotEmpty) {
      final media = json['_embedded']['wp:featuredmedia'][0];
      if (media is Map && media['id'] != null) {
        featuredImage =
            FeaturedImage.fromJson(Map<String, dynamic>.from(media));
      }
    } else if (json['featured_image'] != null &&
        json['featured_image'] is Map) {
      featuredImage = FeaturedImage.fromJson(
        Map<String, dynamic>.from(json['featured_image']),
      );
    }

    // --- ۴. استخراج متادیتا از meta یا meta_data ---
    String seoTitle = '';
    String seoDescription = '';
    String seoKeywords = '';
    String descriptionCss = '';
    String descriptionJs = '';
    int views = 0;

    // ✅ اول meta (فرمت WordPress REST)
    final meta = json['meta'] as Map<String, dynamic>?;
    if (meta != null) {
      seoTitle = meta['rank_math_title']?.toString() ?? '';
      seoDescription = meta['rank_math_description']?.toString() ?? '';
      seoKeywords = meta['rank_math_focus_keyword']?.toString() ?? '';
      descriptionCss = meta['ezlens_desc_css']?.toString() ?? '';
      descriptionJs = meta['ezlens_desc_js']?.toString() ?? '';
      if (meta['views'] != null) {
        views = int.tryParse(meta['views'].toString()) ?? 0;
      }
    }

    // ✅ بعد meta_data (فرمت fallback)
    if (seoTitle.isEmpty &&
        json['meta_data'] != null &&
        json['meta_data'] is List) {
      for (final item in (json['meta_data'] as List)) {
        if (item is! Map) continue;
        final key = item['key']?.toString() ?? '';
        final value = item['value']?.toString() ?? '';
        if (key == 'rank_math_title') seoTitle = value;
        if (key == 'rank_math_description') seoDescription = value;
        if (key == 'rank_math_focus_keyword') seoKeywords = value;
        if (key == 'ezlens_desc_css') descriptionCss = value;
        if (key == 'ezlens_desc_js') descriptionJs = value;
        if (key == 'views') views = int.tryParse(value) ?? 0;
      }
    }

    // --- ۵. محتوای content (prefer raw for editor round-trip) ---
    String content = '';
    final contentRaw = json['content'];
    if (contentRaw is Map) {
      final raw = contentRaw['raw'];
      final rendered = contentRaw['rendered'];
      if (raw != null && raw.toString().trim().isNotEmpty) {
        content = raw.toString();
      } else {
        // Elementor posts often have empty raw — use rendered as fallback for editor
        content = (rendered ?? '').toString();
      }
    } else if (contentRaw is String) {
      content = contentRaw;
    }

    // --- ۶. خلاصه excerpt ---
    String? excerpt;
    final excerptRaw = json['excerpt'];
    if (excerptRaw is Map) {
      final raw = excerptRaw['raw'];
      final rendered = excerptRaw['rendered'];
      if (raw != null && raw.toString().trim().isNotEmpty) {
        excerpt = raw.toString();
      } else {
        excerpt = (rendered ?? '').toString();
      }
    } else if (excerptRaw is String) {
      excerpt = excerptRaw;
    }

    // --- ۷. عنوان title ---
    String title = 'بدون عنوان';
    final titleRaw = json['title'];
    if (titleRaw is Map) {
      final raw = titleRaw['raw'];
      final rendered = titleRaw['rendered'];
      if (raw != null && raw.toString().trim().isNotEmpty) {
        title = raw.toString();
      } else {
        title = (rendered ?? 'بدون عنوان').toString();
      }
    } else if (titleRaw is String) {
      title = titleRaw;
    }

    return Article(
      id: json['id'] ?? 0,
      title: title,
      slug: json['slug'] ?? '',
      status: ArticleStatusExtension.fromString(json['status'] ?? 'draft'),
      excerpt: excerpt,
      content: content,
      date: json['date'] != null ? DateTime.tryParse(json['date']) : null,
      modified: json['modified'] != null
          ? DateTime.tryParse(json['modified'])
          : null,
      categories: categories,
      tags: tags,
      featuredMedia: json['featured_media'] ?? 0,
      featuredImage: featuredImage,
      permalink: json['link'] ?? json['permalink'] ?? '',
      views: views,
      descriptionCss: descriptionCss,
      descriptionJs: descriptionJs,
      seoTitle: seoTitle,
      seoDescription: seoDescription,
      seoKeywords: seoKeywords,
    );
  }

  // ===== تبدیل به JSON (ارسال به وردپرس) =====
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'slug': slug.isNotEmpty ? slug : null,
      'status': status.string,
      'excerpt': excerpt,
      'content': content,
      'categories': categories.map((c) => c.id).toList(),
      'tags': tags.map((t) => t.id).toList(),
      'featured_media': featuredMedia,
      // ✅ meta به‌صورت Map (نه meta_data array)
      'meta': {
        'rank_math_title': seoTitle,
        'rank_math_description': seoDescription,
        'rank_math_focus_keyword': seoKeywords,
        'ezlens_desc_css': descriptionCss,
        'ezlens_desc_js': descriptionJs,
      },
    };
  }

  // ===== کپی با تغییرات =====
  Article copyWith({
    int? id,
    String? title,
    String? slug,
    ArticleStatus? status,
    String? excerpt,
    String? content,
    DateTime? date,
    DateTime? modified,
    List<ArticleCategory>? categories,
    List<ArticleTag>? tags,
    int? featuredMedia,
    FeaturedImage? featuredImage,
    String? permalink,
    int? views,
    String? descriptionCss,
    String? descriptionJs,
    String? seoTitle,
    String? seoDescription,
    String? seoKeywords,
  }) {
    return Article(
      id: id ?? this.id,
      title: title ?? this.title,
      slug: slug ?? this.slug,
      status: status ?? this.status,
      excerpt: excerpt ?? this.excerpt,
      content: content ?? this.content,
      date: date ?? this.date,
      modified: modified ?? this.modified,
      categories: categories ?? this.categories,
      tags: tags ?? this.tags,
      featuredMedia: featuredMedia ?? this.featuredMedia,
      featuredImage: featuredImage ?? this.featuredImage,
      permalink: permalink ?? this.permalink,
      views: views ?? this.views,
      descriptionCss: descriptionCss ?? this.descriptionCss,
      descriptionJs: descriptionJs ?? this.descriptionJs,
      seoTitle: seoTitle ?? this.seoTitle,
      seoDescription: seoDescription ?? this.seoDescription,
      seoKeywords: seoKeywords ?? this.seoKeywords,
    );
  }
}