/// Product feature (palette / template) models for EzLens Manager.
library;

class ProductFeature {
  final int id;
  final String title;
  final String description;
  final String status;
  final String code;
  final int fieldsCount;
  final int connectedCount;
  final String createdAt;
  final String updatedAt;

  const ProductFeature({
    required this.id,
    required this.title,
    this.description = '',
    this.status = 'active',
    this.code = '',
    this.fieldsCount = 0,
    this.connectedCount = 0,
    this.createdAt = '',
    this.updatedAt = '',
  });

  factory ProductFeature.fromJson(Map<String, dynamic> json) {
    return ProductFeature(
      id: _asInt(json['id']),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      status: (json['status'] ?? 'active').toString(),
      code: (json['code'] ?? '').toString(),
      fieldsCount: _asInt(json['fields_count']),
      connectedCount: _asInt(json['connected_count']),
      createdAt: (json['created_at'] ?? '').toString(),
      updatedAt: (json['updated_at'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'status': status,
        'code': code,
      };

  ProductFeature copyWith({
    int? id,
    String? title,
    String? description,
    String? status,
    String? code,
    int? fieldsCount,
    int? connectedCount,
  }) {
    return ProductFeature(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      code: code ?? this.code,
      fieldsCount: fieldsCount ?? this.fieldsCount,
      connectedCount: connectedCount ?? this.connectedCount,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static int _asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('$v') ?? 0;
  }
}

class ProductFeatureListResponse {
  final List<ProductFeature> items;
  final int total;
  final int page;
  final int perPage;

  const ProductFeatureListResponse({
    required this.items,
    required this.total,
    required this.page,
    required this.perPage,
  });

  factory ProductFeatureListResponse.fromJson(Map<String, dynamic> json) {
    final raw = json['items'];
    final list = <ProductFeature>[];
    if (raw is List) {
      for (final e in raw) {
        if (e is Map<String, dynamic>) {
          list.add(ProductFeature.fromJson(e));
        } else if (e is Map) {
          list.add(ProductFeature.fromJson(Map<String, dynamic>.from(e)));
        }
      }
    }
    return ProductFeatureListResponse(
      items: list,
      total: ProductFeature._asInt(json['total']),
      page: ProductFeature._asInt(json['page'] ?? 1),
      perPage: ProductFeature._asInt(json['per_page'] ?? 20),
    );
  }
}

/// Slot attached to a product (placement + display mode).
class ProductFeatureSlot {
  final int templateId;
  final String title;
  final String label;
  final String placement;
  final String display;
  final int order;

  const ProductFeatureSlot({
    required this.templateId,
    this.title = '',
    this.label = '',
    this.placement = 'below_summary',
    this.display = 'inline',
    this.order = 0,
  });

  factory ProductFeatureSlot.fromJson(Map<String, dynamic> json) {
    return ProductFeatureSlot(
      templateId: ProductFeature._asInt(json['template_id']),
      title: (json['title'] ?? '').toString(),
      label: (json['label'] ?? '').toString(),
      placement: (json['placement'] ?? 'below_summary').toString(),
      display: (json['display'] ?? 'inline').toString(),
      order: ProductFeature._asInt(json['order']),
    );
  }

  Map<String, dynamic> toJson() => {
        'template_id': templateId,
        'label': label,
        'placement': placement,
        'display': display,
        'order': order,
      };

  ProductFeatureSlot copyWith({
    int? templateId,
    String? title,
    String? label,
    String? placement,
    String? display,
    int? order,
  }) {
    return ProductFeatureSlot(
      templateId: templateId ?? this.templateId,
      title: title ?? this.title,
      label: label ?? this.label,
      placement: placement ?? this.placement,
      display: display ?? this.display,
      order: order ?? this.order,
    );
  }

  static const placements = <String, String>{
    'gallery_side': 'کنار گالری',
    'below_price': 'زیر قیمت',
    'below_summary': 'زیر خلاصه',
    'full_width': 'تمام‌عرض',
  };

  static const displays = <String, String>{
    'inline': 'مستقیم روی صفحه',
    'accordion': 'کشویی (آکاردئون)',
    'ajax_modal': 'باکس / مودال',
  };
}
