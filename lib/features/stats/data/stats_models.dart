library;

class StatsSnapshot {
  final String period;
  final String periodLabel;
  final String rangeFa;
  final int ordersCount;
  final int revenue;
  final int avgOrder;
  final List<StatusCount> byStatus;
  final int totalUsers;
  final int totalCustomers;
  final int newCustomers;
  final int postsTotal;
  final int postsNew;
  final int comments;
  final int productsPublished;
  final int totalProductViews;
  final String viewsScope;
  final String noteProductViews;
  final String noteGa4;

  const StatsSnapshot({
    this.period = 'week',
    this.periodLabel = '',
    this.rangeFa = '',
    this.ordersCount = 0,
    this.revenue = 0,
    this.avgOrder = 0,
    this.byStatus = const [],
    this.totalUsers = 0,
    this.totalCustomers = 0,
    this.newCustomers = 0,
    this.postsTotal = 0,
    this.postsNew = 0,
    this.comments = 0,
    this.productsPublished = 0,
    this.totalProductViews = 0,
    this.viewsScope = 'lifetime',
    this.noteProductViews = '',
    this.noteGa4 = '',
  });

  factory StatsSnapshot.fromJson(Map<String, dynamic> json) {
    final orders = json['orders'] is Map
        ? Map<String, dynamic>.from(json['orders'] as Map)
        : <String, dynamic>{};
    final users = json['users'] is Map
        ? Map<String, dynamic>.from(json['users'] as Map)
        : <String, dynamic>{};
    final content = json['content'] is Map
        ? Map<String, dynamic>.from(json['content'] as Map)
        : <String, dynamic>{};
    final products = json['products'] is Map
        ? Map<String, dynamic>.from(json['products'] as Map)
        : <String, dynamic>{};
    final views = json['views'] is Map
        ? Map<String, dynamic>.from(json['views'] as Map)
        : <String, dynamic>{};
    final notes = json['notes'] is Map
        ? Map<String, dynamic>.from(json['notes'] as Map)
        : <String, dynamic>{};

    final statusList = <StatusCount>[];
    if (orders['by_status'] is List) {
      for (final e in orders['by_status'] as List) {
        if (e is Map) {
          statusList.add(StatusCount.fromJson(Map<String, dynamic>.from(e)));
        }
      }
    }

    return StatsSnapshot(
      period: (json['period'] ?? 'week').toString(),
      periodLabel: (json['period_label'] ?? '').toString(),
      rangeFa: (json['range_fa'] ?? '').toString(),
      ordersCount: int.tryParse('${orders['count']}') ?? 0,
      revenue: int.tryParse('${orders['revenue']}') ?? 0,
      avgOrder: int.tryParse('${orders['avg']}') ?? 0,
      byStatus: statusList,
      totalUsers: int.tryParse('${users['total_users']}') ?? 0,
      totalCustomers: int.tryParse('${users['total_customers']}') ?? 0,
      newCustomers: int.tryParse('${users['new_in_period']}') ?? 0,
      postsTotal: int.tryParse('${content['posts_total']}') ?? 0,
      postsNew: int.tryParse('${content['posts_new']}') ?? 0,
      comments: int.tryParse('${content['comments']}') ?? 0,
      productsPublished: int.tryParse('${products['published']}') ?? 0,
      totalProductViews: int.tryParse('${views['total_product_views']}') ?? 0,
      viewsScope: (views['scope'] ?? 'lifetime').toString(),
      noteProductViews: (notes['product_views'] ?? '').toString(),
      noteGa4: (notes['ga4'] ?? '').toString(),
    );
  }
}

class StatusCount {
  final String status;
  final String label;
  final int count;

  const StatusCount({
    this.status = '',
    this.label = '',
    this.count = 0,
  });

  factory StatusCount.fromJson(Map<String, dynamic> json) {
    return StatusCount(
      status: (json['status'] ?? '').toString(),
      label: (json['label'] ?? '').toString(),
      count: int.tryParse('${json['count']}') ?? 0,
    );
  }
}

class TopProduct {
  final int id;
  final String title;
  final int score;
  final String image;

  const TopProduct({
    required this.id,
    this.title = '',
    this.score = 0,
    this.image = '',
  });

  factory TopProduct.fromJson(Map<String, dynamic> json) {
    return TopProduct(
      id: int.tryParse('${json['id']}') ?? 0,
      title: (json['title'] ?? '').toString(),
      score: int.tryParse('${json['score']}') ?? 0,
      image: (json['image'] ?? '').toString(),
    );
  }
}


/// Unified row for latest posts / products with view counts.
class TopContentItem {
  final int id;
  final String title;
  final int views;
  final String image;
  final String type; // product | post
  final DateTime? date;

  const TopContentItem({
    required this.id,
    this.title = '',
    this.views = 0,
    this.image = '',
    this.type = 'post',
    this.date,
  });

  factory TopContentItem.fromJson(Map<String, dynamic> json, {String type = 'post'}) {
    DateTime? d;
    final raw = json['date'] ?? json['date_created'] ?? json['modified'];
    if (raw != null) {
      d = DateTime.tryParse(raw.toString());
    }
    return TopContentItem(
      id: int.tryParse('${json['id']}') ?? 0,
      title: (json['title'] ?? json['name'] ?? '').toString(),
      views: int.tryParse('${json['views'] ?? json['score'] ?? json['post_views_count'] ?? 0}') ?? 0,
      image: (json['image'] ?? json['featured_image'] ?? '').toString(),
      type: type,
      date: d,
    );
  }

  factory TopContentItem.fromTopProduct(TopProduct p) {
    return TopContentItem(
      id: p.id,
      title: p.title,
      views: p.score,
      image: p.image,
      type: 'product',
    );
  }
}
