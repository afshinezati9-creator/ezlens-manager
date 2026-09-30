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
  final int totalPostViews;
  final int totalPageViews;
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
    this.totalPostViews = 0,
    this.totalPageViews = 0,
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
      totalProductViews: int.tryParse('${views['total_product_views'] ?? views['product_views'] ?? 0}') ?? 0,
      totalPostViews: int.tryParse('${views['total_post_views'] ?? views['total_article_views'] ?? views['post_views'] ?? views['posts'] ?? content['total_post_views'] ?? json['total_post_views'] ?? json['total_article_views'] ?? json['post_views'] ?? 0}') ?? 0,
      totalPageViews: int.tryParse('${views['total_page_views'] ?? views['page_views'] ?? 0}') ?? 0,
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

int _readViewCount(Map<String, dynamic> json) {
  var best = 0;
  void consider(dynamic value) {
    final n = int.tryParse('${value ?? ''}') ?? 0;
    if (n > best) best = n;
  }
  for (final key in const ['score', 'views', 'post_views_count', 'view_count', 'views_count', 'pageviews', 'total_views', 'count']) {
    consider(json[key]);
  }
  final nested = json['stats'] ?? json['statistics'] ?? json['view_stats'];
  if (nested is Map) {
    for (final key in const ['views', 'count', 'total', 'total_views', 'post_views_count']) {
      consider(nested[key]);
    }
  }
  return best;
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
      score: _readViewCount(json),
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
      title: () {
        final raw = json['title'] ?? json['name'] ?? '';
        if (raw is Map) {
          return (raw['rendered'] ?? raw['raw'] ?? '').toString();
        }
        return raw.toString();
      }(),
      views: _readViewCount(json),
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

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'views': views,
        'image': image,
        'type': type,
        if (date != null) 'date': date!.toIso8601String(),
      };
}

class GscOverview {
  final bool ok;
  final bool configured;
  final String period;
  final String startDate;
  final String endDate;
  final int clicks;
  final int impressions;
  final double ctr;
  final double position;
  final List<GscSeriesPoint> series;
  final String? message;

  const GscOverview({
    this.ok = false,
    this.configured = true,
    this.period = 'week',
    this.startDate = '',
    this.endDate = '',
    this.clicks = 0,
    this.impressions = 0,
    this.ctr = 0,
    this.position = 0,
    this.series = const [],
    this.message,
  });

  factory GscOverview.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const GscOverview();
    final seriesRaw = json['series'];
    final series = <GscSeriesPoint>[];
    if (seriesRaw is List) {
      for (final e in seriesRaw) {
        if (e is Map) {
          series.add(GscSeriesPoint.fromJson(Map<String, dynamic>.from(e)));
        }
      }
    }
    return GscOverview(
      ok: json['ok'] == true,
      configured: json['configured'] != false,
      period: '${json['period'] ?? 'week'}',
      startDate: '${json['start_date'] ?? ''}',
      endDate: '${json['end_date'] ?? ''}',
      clicks: int.tryParse('${json['clicks']}') ?? 0,
      impressions: int.tryParse('${json['impressions']}') ?? 0,
      ctr: double.tryParse('${json['ctr']}') ?? 0,
      position: double.tryParse('${json['position']}') ?? 0,
      series: series,
      message: json['message']?.toString(),
    );
  }
}

class GscSeriesPoint {
  final String date;
  final int clicks;
  final int impressions;
  final double ctr;
  final double position;

  const GscSeriesPoint({
    this.date = '',
    this.clicks = 0,
    this.impressions = 0,
    this.ctr = 0,
    this.position = 0,
  });

  factory GscSeriesPoint.fromJson(Map<String, dynamic> json) {
    return GscSeriesPoint(
      date: '${json['date'] ?? ''}',
      clicks: int.tryParse('${json['clicks']}') ?? 0,
      impressions: int.tryParse('${json['impressions']}') ?? 0,
      ctr: double.tryParse('${json['ctr']}') ?? 0,
      position: double.tryParse('${json['position']}') ?? 0,
    );
  }
}

class GscRow {
  final String key;
  final int clicks;
  final int impressions;
  final double ctr;
  final double position;

  const GscRow({
    this.key = '',
    this.clicks = 0,
    this.impressions = 0,
    this.ctr = 0,
    this.position = 0,
  });

  factory GscRow.fromJson(Map<String, dynamic> json) {
    return GscRow(
      key: '${json['key'] ?? ''}',
      clicks: int.tryParse('${json['clicks']}') ?? 0,
      impressions: int.tryParse('${json['impressions']}') ?? 0,
      ctr: double.tryParse('${json['ctr']}') ?? 0,
      position: double.tryParse('${json['position']}') ?? 0,
    );
  }
}


class RecentVisitor {
  final int ts;
  final String timeFa;
  final int postId;
  final String title;
  final String type;
  final String path;
  final String referrer;
  final String refHost;
  final String source;
  final String ip;
  final String country;
  final String device;
  final String os;
  final String browser;

  const RecentVisitor({
    this.ts = 0,
    this.timeFa = '',
    this.postId = 0,
    this.title = '',
    this.type = '',
    this.path = '',
    this.referrer = '',
    this.refHost = '',
    this.source = '',
    this.ip = '',
    this.country = '',
    this.device = '',
    this.os = '',
    this.browser = '',
  });

  factory RecentVisitor.fromJson(Map<String, dynamic> json) {
    final ua = '${json['user_agent'] ?? json['ua'] ?? ''}';
    final parsed = _parseUserAgent(ua);
    return RecentVisitor(
      ts: int.tryParse('${json['ts']}') ?? 0,
      timeFa: '${json['time_fa'] ?? ''}',
      postId: int.tryParse('${json['post_id']}') ?? 0,
      title: '${json['title'] ?? ''}',
      type: '${json['type'] ?? ''}',
      path: '${json['path'] ?? ''}',
      referrer: '${json['referrer'] ?? ''}',
      refHost: '${json['ref_host'] ?? ''}',
      source: '${json['source'] ?? ''}',
      ip: '${json['ip'] ?? json['ip_address'] ?? json['client_ip'] ?? ''}',
      country: _countryLabel('${json['country'] ?? json['country_code'] ?? ''}'),
      device: '${json['device'] ?? json['device_name'] ?? json['device_type'] ?? parsed.device}',
      os: '${json['os'] ?? json['operating_system'] ?? parsed.os}',
      browser: '${json['browser'] ?? parsed.browser}',
    );
  }

  String get typeLabel {
    switch (type) {
      case 'product':
        return 'محصول';
      case 'page':
        return 'صفحه';
      case 'post':
        return 'مقاله';
      default:
        return type;
    }
  }

  String get fromLabel {
    if (refHost.isNotEmpty) return refHost;
    if (referrer.isEmpty) return 'ورود مستقیم';
    return referrer;
  }
}




class _ParsedUserAgent {
  final String device;
  final String os;
  final String browser;
  const _ParsedUserAgent(this.device, this.os, this.browser);
}

_ParsedUserAgent _parseUserAgent(String ua) {
  if (ua.isEmpty) return const _ParsedUserAgent('نامشخص', 'نامشخص', 'نامشخص');

  String os = 'نامشخص';
  if (RegExp(r'Android', caseSensitive: false).hasMatch(ua)) {
    os = 'Android';
  } else if (RegExp(r'iPhone|iPad|iPod', caseSensitive: false).hasMatch(ua)) {
    os = 'iOS';
  } else if (RegExp(r'Windows NT', caseSensitive: false).hasMatch(ua)) {
    os = 'Windows';
  } else if (RegExp(r'Mac OS X', caseSensitive: false).hasMatch(ua)) {
    os = 'macOS';
  } else if (RegExp(r'Linux', caseSensitive: false).hasMatch(ua)) {
    os = 'Linux';
  }

  String device = 'کامپیوتر';
  if (RegExp(r'iPad|Tablet', caseSensitive: false).hasMatch(ua) ||
      (RegExp(r'Android', caseSensitive: false).hasMatch(ua) &&
          !RegExp(r'Mobile', caseSensitive: false).hasMatch(ua))) {
    device = 'تبلت';
  } else if (RegExp(r'Mobile|iPhone|iPod|Android', caseSensitive: false).hasMatch(ua)) {
    device = 'موبایل';
  }

  String browser = 'مرورگر نامشخص';
  final edge = RegExp(r'(?:Edg|Edge)/([0-9.]+)', caseSensitive: false).firstMatch(ua);
  final chrome = RegExp(r'(?:Chrome|CriOS)/([0-9.]+)', caseSensitive: false).firstMatch(ua);
  final firefox = RegExp(r'(?:Firefox|FxiOS)/([0-9.]+)', caseSensitive: false).firstMatch(ua);
  final safari = RegExp(r'Version/([0-9.]+).*Safari', caseSensitive: false).firstMatch(ua);
  if (edge != null) browser = 'Edge';
  else if (chrome != null) browser = 'Chrome';
  else if (firefox != null) browser = 'Firefox';
  else if (safari != null) browser = 'Safari';

  return _ParsedUserAgent(device, os, browser);
}

String _countryLabel(String code) {
  switch (code.toUpperCase()) {
    case 'IR': return 'ایران';
    case 'DE': return 'آلمان';
    case 'US': return 'آمریکا';
    case 'GB': return 'بریتانیا';
    case 'AE': return 'امارات';
    case 'TR': return 'ترکیه';
    case 'CA': return 'کانادا';
    case 'FR': return 'فرانسه';
    case 'NL': return 'هلند';
    case 'IT': return 'ایتالیا';
    case 'SE': return 'سوئد';
    case 'AU': return 'استرالیا';
    case 'CN': return 'چین';
    case 'JP': return 'ژاپن';
    case 'KR': return 'کره جنوبی';
    case 'RU': return 'روسیه';
    case '': return 'کشور نامشخص';
    default: return code.toUpperCase();
  }
}

class IndexStatusItem {
  final int id;
  final String title;
  final String type;
  final String url;
  final bool noindex;
  final bool nofollow;
  final bool follow;
  final bool indexable;
  final String gscCoverage;
  final String gscIndexing;
  final bool gscIndexed;

  const IndexStatusItem({
    this.id = 0,
    this.title = '',
    this.type = '',
    this.url = '',
    this.noindex = false,
    this.nofollow = false,
    this.follow = true,
    this.indexable = true,
    this.gscCoverage = '',
    this.gscIndexing = '',
    this.gscIndexed = false,
  });

  factory IndexStatusItem.fromJson(Map<String, dynamic> json) {
    final gsc = json['gsc'];
    String coverage = '';
    String indexing = '';
    bool indexed = json['gsc_indexed'] == true;
    if (gsc is Map) {
      coverage = '${gsc['coverage'] ?? ''}';
      indexing = '${gsc['indexing'] ?? ''}';
      indexed = indexed || gsc['indexed'] == true;
    }
    final normalizedIndexing = indexing.toUpperCase();
    final normalizedCoverage = coverage.toLowerCase();
    if (!indexed) {
      indexed = normalizedIndexing == 'INDEXED' ||
          normalizedCoverage.contains('indexed') ||
          normalizedCoverage.contains('ایندکس');
    }
    return IndexStatusItem(
      id: int.tryParse('${json['id']}') ?? 0,
      title: '${json['title'] ?? ''}',
      type: '${json['type'] ?? ''}',
      url: '${json['url'] ?? ''}',
      noindex: json['noindex'] == true || json['robots_noindex'] == true,
      nofollow: json['nofollow'] == true || json['follow'] == false || json['robots_nofollow'] == true,
      follow: json['follow'] == true || (json['follow'] == null && json['nofollow'] != true && json['robots_nofollow'] != true),
      indexable: json['indexable'] != false,
      gscCoverage: coverage,
      gscIndexing: indexing,
      gscIndexed: indexed,
    );
  }

  String get typeLabel {
    switch (type) {
      case 'product':
        return 'محصول';
      case 'page':
        return 'صفحه';
      case 'post':
        return 'مقاله';
      default:
        return type;
    }
  }
}
