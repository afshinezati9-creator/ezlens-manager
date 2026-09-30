/// Snapshot numbers for dashboard cards.
class StatsOverview {
  const StatsOverview({
    this.visitorsToday = 0,
    this.visitorsWeek = 0,
    this.visitorsMonth = 0,
    this.visitorsTotal = 0,
    this.ordersToday = 0,
    this.ordersWeek = 0,
    this.salesToday = 0,
    this.salesWeek = 0,
    this.productsCount = 0,
    this.articlesCount = 0,
    this.customersCount = 0,
    this.period = 'week',
  });

  final int visitorsToday;
  final int visitorsWeek;
  final int visitorsMonth;
  final int visitorsTotal;
  final int ordersToday;
  final int ordersWeek;
  final double salesToday;
  final double salesWeek;
  final int productsCount;
  final int articlesCount;
  final int customersCount;
  final String period;

  factory StatsOverview.fromJson(Map<String, dynamic> j) {
    int i(dynamic v) => int.tryParse('${v ?? 0}') ?? 0;
    double d(dynamic v) => double.tryParse('${v ?? 0}') ?? 0;
    return StatsOverview(
      visitorsToday: i(j['visitors_today'] ?? j['visitorsToday']),
      visitorsWeek: i(j['visitors_week'] ?? j['visitorsWeek']),
      visitorsMonth: i(j['visitors_month'] ?? j['visitorsMonth']),
      visitorsTotal: i(j['visitors_total'] ?? j['visitorsTotal'] ?? j['total_visitors']),
      ordersToday: i(j['orders_today'] ?? j['ordersToday']),
      ordersWeek: i(j['orders_week'] ?? j['ordersWeek']),
      salesToday: d(j['sales_today'] ?? j['salesToday'] ?? j['revenue_today']),
      salesWeek: d(j['sales_week'] ?? j['salesWeek'] ?? j['revenue_week']),
      productsCount: i(j['products'] ?? j['products_count']),
      articlesCount: i(j['articles'] ?? j['posts'] ?? j['articles_count']),
      customersCount: i(j['customers'] ?? j['customers_count']),
      period: '${j['period'] ?? 'week'}',
    );
  }

  Map<String, dynamic> toJson() => {
        'visitors_today': visitorsToday,
        'visitors_week': visitorsWeek,
        'visitors_month': visitorsMonth,
        'visitors_total': visitorsTotal,
        'orders_today': ordersToday,
        'orders_week': ordersWeek,
        'sales_today': salesToday,
        'sales_week': salesWeek,
        'products': productsCount,
        'articles': articlesCount,
        'customers': customersCount,
        'period': period,
      };
}

/// One point on a visits time series.
class VisitPoint {
  const VisitPoint({required this.label, required this.value});

  final String label;
  final double value;

  factory VisitPoint.fromJson(Map<String, dynamic> j) => VisitPoint(
        label: '${j['label'] ?? j['date'] ?? ''}',
        value: double.tryParse('${j['value'] ?? j['views'] ?? j['count'] ?? 0}') ?? 0,
      );

  Map<String, dynamic> toJson() => {'label': label, 'value': value};
}

class VisitsSeries {
  const VisitsSeries({
    required this.points,
    this.range = 'week',
    this.total = 0,
  });

  final List<VisitPoint> points;
  final String range;
  final int total;

  factory VisitsSeries.fromJson(Map<String, dynamic> j) {
    final raw = j['points'] ?? j['items'] ?? j['series'] ?? [];
    final list = <VisitPoint>[];
    if (raw is List) {
      for (final e in raw) {
        if (e is Map) {
          list.add(VisitPoint.fromJson(Map<String, dynamic>.from(e)));
        }
      }
    }
    return VisitsSeries(
      points: list,
      range: '${j['range'] ?? j['period'] ?? 'week'}',
      total: int.tryParse('${j['total'] ?? 0}') ??
          list.fold<int>(0, (a, b) => a + b.value.round()),
    );
  }

  Map<String, dynamic> toJson() => {
        'points': points.map((e) => e.toJson()).toList(),
        'range': range,
        'total': total,
      };
}
