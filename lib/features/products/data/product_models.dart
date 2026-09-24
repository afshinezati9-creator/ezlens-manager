// lib/features/products/data/product_models.dart

class Product {
  final int id;
  final String name;
  final String slug;
  final String? permalink;
  final String? description;
  final String? shortDescription;
  final String? sku;

  final String price;
  final String regularPrice;
  final String? salePrice;

  final int? stockQuantity;
  final String stockStatus;

  final List<ProductImage> images;
  final List<ProductCategory> categories;
  final List<ProductTag> tags;
  final List<ProductTag> brands;

  final String status;

  final DateTime? dateCreated;
  final DateTime? dateModified;

  final Map<String, dynamic>? metaData;

  // =========================================================
  // آمار محصول
  // =========================================================

  /// تعداد فروش محصول
  final int? totalSales;

  /// تعداد بازدید محصول
  final int? viewCount;

  List<String> get categoryNames =>
      categories.map((c) => c.name).toList();

  List<int> get categoryIds =>
      categories.map((c) => c.id).toList();

  List<int> get tagIds =>
      tags.map((t) => t.id).toList();

  List<String> get imageUrls =>
      images.map((i) => i.src).toList();

  List<int> get brandIds =>
      brands.map((b) => b.id).toList();

  Product({
    required this.id,
    required this.name,
    required this.slug,
    this.permalink,
    this.description,
    this.shortDescription,
    this.sku,
    required this.price,
    required this.regularPrice,
    this.salePrice,
    this.stockQuantity,
    required this.stockStatus,
    required this.images,
    required this.categories,
    required this.tags,
    required this.brands,
    required this.status,
    this.dateCreated,
    this.dateModified,
    this.metaData,
    this.totalSales,
    this.viewCount,
  });

  // =========================================================
  // تبدیل مقدار به int
  // =========================================================

  static int? _parseInt(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    if (value is double) {
      return value.toInt();
    }

    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      var cleaned = value.trim();

      if (cleaned.isEmpty) {
        return null;
      }

      // حذف جداکننده‌های عددی
      cleaned = cleaned.replaceAll(',', '');
      cleaned = cleaned.replaceAll('٬', '');
      cleaned = cleaned.replaceAll(' ', '');

      // تبدیل اعداد فارسی
      cleaned = cleaned
          .replaceAll('۰', '0')
          .replaceAll('۱', '1')
          .replaceAll('۲', '2')
          .replaceAll('۳', '3')
          .replaceAll('۴', '4')
          .replaceAll('۵', '5')
          .replaceAll('۶', '6')
          .replaceAll('۷', '7')
          .replaceAll('۸', '8')
          .replaceAll('۹', '9');

      return int.tryParse(cleaned);
    }

    return null;
  }

  // =========================================================
  // استخراج متادیتا
  // =========================================================

  static Map<String, dynamic>? _parseMetaData(
    dynamic rawMetaData,
  ) {
    if (rawMetaData is! List) {
      return null;
    }

    final Map<String, dynamic> result = {};

    for (final item in rawMetaData) {
      if (item is Map &&
          item['key'] != null) {
        result[item['key'].toString()] = item['value'];
      }
    }

    return result;
  }

  // =========================================================
  // Factory
  // =========================================================

  factory Product.fromJson(Map<String, dynamic> json) {

    // ---------------------------------------------------------
    // Meta Data
    // ---------------------------------------------------------

    final metaData = _parseMetaData(
      json['meta_data'],
    );

    // ---------------------------------------------------------
    // TOTAL SALES
    //
    // اول فیلد مستقیم API
    // بعد meta_data
    // ---------------------------------------------------------

    int? totalSales;

    if (json.containsKey('total_sales')) {
      totalSales = _parseInt(
        json['total_sales'],
      );
    }

    if (totalSales == null && metaData != null) {
      totalSales = _parseInt(
        metaData['total_sales'],
      );
    }

    // ---------------------------------------------------------
    // VIEW COUNT
    //
    // اول post_views_count مستقیم API
    // بعد سایر نام‌ها
    // بعد meta_data
    // ---------------------------------------------------------

    int? viewCount;

    // اولویت اول: فیلدی که اسنیپت EzLens اضافه می‌کند
    if (json.containsKey('post_views_count')) {
      viewCount = _parseInt(
        json['post_views_count'],
      );
    }

    // اگر وجود نداشت، چند نام احتمالی دیگر
    if (viewCount == null) {
      const directViewKeys = [
        'papvfwc_views',
        'views',
        'view_count',
      ];

      for (final key in directViewKeys) {
        if (json.containsKey(key)) {
          final parsed = _parseInt(json[key]);

          if (parsed != null) {
            viewCount = parsed;
            break;
          }
        }
      }
    }

    // ---------------------------------------------------------
    // fallback به meta_data
    // ---------------------------------------------------------

    if (viewCount == null && metaData != null) {
      const metaViewKeys = [
        'post_views_count',
        'papvfwc_views',
        'views',
        'view_count',
      ];

      for (final key in metaViewKeys) {
        if (metaData.containsKey(key)) {
          final parsed = _parseInt(
            metaData[key],
          );

          if (parsed != null) {
            viewCount = parsed;
            break;
          }
        }
      }
    }

    // =========================================================
    // ساخت Product
    // =========================================================

    return Product(
      id: _parseInt(json['id']) ?? 0,

      name: json['name']?.toString() ?? 'بدون نام',

      slug: json['slug']?.toString() ?? '',

      permalink: json['permalink']?.toString(),

      description: json['description']?.toString(),

      shortDescription:
          json['short_description']?.toString(),

      sku: json['sku']?.toString(),

      price: json['price']?.toString() ?? '0',

      regularPrice:
          json['regular_price']?.toString() ?? '0',

      salePrice:
          json['sale_price']?.toString(),

      stockQuantity:
          _parseInt(json['stock_quantity']),

      stockStatus:
          json['stock_status']?.toString() ?? 'instock',

      images: (json['images'] is List)
          ? (json['images'] as List)
              .whereType<Map>()
              .map(
                (e) => ProductImage.fromJson(
                  Map<String, dynamic>.from(e),
                ),
              )
              .toList()
          : [],

      categories: (json['categories'] is List)
          ? (json['categories'] as List)
              .whereType<Map>()
              .map(
                (e) => ProductCategory.fromJson(
                  Map<String, dynamic>.from(e),
                ),
              )
              .toList()
          : [],

      tags: (json['tags'] is List)
          ? (json['tags'] as List)
              .whereType<Map>()
              .map(
                (e) => ProductTag.fromJson(
                  Map<String, dynamic>.from(e),
                ),
              )
              .toList()
          : [],

      brands: (json['product_brand'] is List)
          ? (json['product_brand'] as List)
              .whereType<Map>()
              .map(
                (e) => ProductTag.fromJson(
                  Map<String, dynamic>.from(e),
                ),
              )
              .toList()
          : [],

      status:
          json['status']?.toString() ?? 'publish',

      dateCreated:
          json['date_created'] != null
              ? DateTime.tryParse(
                  json['date_created'].toString(),
                )
              : null,

      dateModified:
          json['date_modified'] != null
              ? DateTime.tryParse(
                  json['date_modified'].toString(),
                )
              : null,

      metaData: metaData,

      totalSales: totalSales,

      viewCount: viewCount,
    );
  }

  // =========================================================
  // To JSON
  // =========================================================

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'slug': slug,
      'description': description,
      'short_description': shortDescription,
      'sku': sku,
      'regular_price': regularPrice,
      'sale_price': salePrice,
      'stock_quantity': stockQuantity,
      'stock_status': stockStatus,
      'images': images
          .map((e) => e.toJson())
          .toList(),
      'categories': categories
          .map((e) => e.toJson())
          .toList(),
      'tags': tags
          .map((e) => e.toJson())
          .toList(),
      'product_brand': brands
          .map((e) => e.toJson())
          .toList(),
    };
  }

  // =========================================================
  // Copy With
  // =========================================================

  Product copyWith({
    int? id,
    String? name,
    String? slug,
    String? permalink,
    String? description,
    String? shortDescription,
    String? sku,
    String? price,
    String? regularPrice,
    String? salePrice,
    int? stockQuantity,
    String? stockStatus,
    List<ProductImage>? images,
    List<ProductCategory>? categories,
    List<ProductTag>? tags,
    List<ProductTag>? brands,
    String? status,
    DateTime? dateCreated,
    DateTime? dateModified,
    Map<String, dynamic>? metaData,
    int? totalSales,
    int? viewCount,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      permalink: permalink ?? this.permalink,
      description: description ?? this.description,
      shortDescription:
          shortDescription ?? this.shortDescription,
      sku: sku ?? this.sku,
      price: price ?? this.price,
      regularPrice:
          regularPrice ?? this.regularPrice,
      salePrice: salePrice ?? this.salePrice,
      stockQuantity:
          stockQuantity ?? this.stockQuantity,
      stockStatus:
          stockStatus ?? this.stockStatus,
      images: images ?? this.images,
      categories:
          categories ?? this.categories,
      tags: tags ?? this.tags,
      brands: brands ?? this.brands,
      status: status ?? this.status,
      dateCreated:
          dateCreated ?? this.dateCreated,
      dateModified:
          dateModified ?? this.dateModified,
      metaData:
          metaData ?? this.metaData,
      totalSales:
          totalSales ?? this.totalSales,
      viewCount:
          viewCount ?? this.viewCount,
    );
  }
}


// =============================================================
// Product Image
// =============================================================

class ProductImage {
  final int? id;
  final String src;
  final String? name;
  final String? alt;

  ProductImage({
    this.id,
    required this.src,
    this.name,
    this.alt,
  });

  factory ProductImage.fromJson(
    Map<String, dynamic> json,
  ) {
    return ProductImage(
      id: _parseImageId(json['id']),
      src: json['src']?.toString() ?? '',
      name: json['name']?.toString(),
      alt: json['alt']?.toString(),
    );
  }

  static int? _parseImageId(dynamic value) {
    if (value is int) {
      return value;
    }

    return int.tryParse(
      value?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'src': src,
      'name': name,
      'alt': alt,
    };
  }
}


// =============================================================
// Product Category
// =============================================================

class ProductCategory {
  final int id;
  final String name;
  final String? slug;
  final int? parentId;

  ProductCategory({
    required this.id,
    required this.name,
    this.slug,
    this.parentId,
  });

  factory ProductCategory.fromJson(
    Map<String, dynamic> json,
  ) {
    return ProductCategory(
      id: _parseCategoryId(json['id']),
      name:
          json['name']?.toString() ??
          'دسته‌بندی نشده',
      slug: json['slug']?.toString(),
      parentId: _parseCategoryId(
        json['parent'],
      ),
    );
  }

  static int _parseCategoryId(dynamic value) {
    if (value is int) {
      return value;
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'parent': parentId,
    };
  }
}


// =============================================================
// Product Tag / Brand
// =============================================================

class ProductTag {
  final int id;
  final String name;
  final String? slug;

  ProductTag({
    required this.id,
    required this.name,
    this.slug,
  });

  factory ProductTag.fromJson(
    Map<String, dynamic> json,
  ) {
    return ProductTag(
      id: _parseTagId(json['id']),
      name:
          json['name']?.toString() ??
          'بدون برند',
      slug: json['slug']?.toString(),
    );
  }

  static int _parseTagId(dynamic value) {
    if (value is int) {
      return value;
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
    };
  }
}