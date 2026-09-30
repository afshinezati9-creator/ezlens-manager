import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/stats_models.dart';
import 'widgets/stats_period_chips.dart';

/// Full-screen visits analytics with line + bar charts.
class VisitsChartPage extends ConsumerStatefulWidget {
  const VisitsChartPage({
    super.key,
    this.series,
    this.onRangeChanged,
  });

  final VisitsSeries? series;
  final Future<VisitsSeries> Function(String range)? onRangeChanged;

  @override
  ConsumerState<VisitsChartPage> createState() => _VisitsChartPageState();
}

class _VisitsChartPageState extends ConsumerState<VisitsChartPage> {
  String _range = 'week';
  VisitsSeries? _data;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _data = widget.series ?? _sampleSeries('week');
    if (widget.onRangeChanged != null) {
      _reload('week');
    }
  }

  Future<void> _reload(String range) async {
    setState(() {
      _range = range;
      _loading = true;
      _error = null;
    });
    try {
      if (widget.onRangeChanged != null) {
        final s = await widget.onRangeChanged!(range);
        if (mounted) setState(() => _data = s);
      } else {
        await Future<void>.delayed(const Duration(milliseconds: 200));
        if (mounted) setState(() => _data = _sampleSeries(range));
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  VisitsSeries _sampleSeries(String range) {
    final labels = switch (range) {
      'day' => List.generate(12, (i) => '${i * 2}:00'),
      'month' => List.generate(12, (i) => '${i + 1}'),
      'all' => ['۱۴۰۳', '۱۴۰۴', '۱۴۰۵'],
      _ => ['ش', 'ی', 'د', 'س', 'چ', 'پ', 'ج'],
    };
    final values = switch (range) {
      'day' => [12.0, 18.0, 9.0, 22.0, 30.0, 28.0, 35.0, 40.0, 32.0, 25.0, 20.0, 15.0],
      'month' => [120.0, 140.0, 110.0, 160.0, 180.0, 200.0, 170.0, 190.0, 210.0, 195.0, 220.0, 240.0],
      'all' => [1200.0, 3400.0, 5100.0],
      _ => [40.0, 55.0, 48.0, 70.0, 62.0, 80.0, 75.0],
    };
    final points = <VisitPoint>[];
    for (var i = 0; i < labels.length && i < values.length; i++) {
      points.add(VisitPoint(label: labels[i], value: values[i]));
    }
    return VisitsSeries(
      points: points,
      range: range,
      total: points.fold<int>(0, (a, b) => a + b.value.round()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final series = _data ?? const VisitsSeries(points: []);

    // 🔴 maxY صریحاً double
    final double maxY = series.points.isEmpty
        ? 10.0
        : (series.points
                .map((e) => e.value.toDouble())
                .reduce((a, b) => a > b ? a : b)) *
            1.2;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const Text('نمودار بازدید'),
          backgroundColor: const Color(0xFF071B7A),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            StatsPeriodChips(value: _range, onChanged: _reload),
            const SizedBox(height: 14),
            _SummaryRow(total: series.total, range: _range),
            const SizedBox(height: 16),
            if (_loading) const LinearProgressIndicator(minHeight: 2),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(_error!,
                    style: const TextStyle(color: Colors.red, fontSize: 12)),
              ),
            _ChartCard(
              title: 'روند بازدید',
              child: SizedBox(
                height: 220,
                child: series.points.isEmpty
                    ? const Center(child: Text('داده‌ای نیست'))
                    : LineChart(
                        LineChartData(
                          minY: 0,
                          maxY: maxY,
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            getDrawingHorizontalLine: (v) => const FlLine(
                              color: Color(0xFFE2E8F0),
                              strokeWidth: 1,
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          titlesData: FlTitlesData(
                            topTitles: const AxisTitles(
                                sideTitles:
                                    SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(
                                sideTitles:
                                    SideTitles(showTitles: false)),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 36,
                                getTitlesWidget: (v, m) => Text(
                                  v.toInt().toString(),
                                  style: const TextStyle(
                                      fontSize: 10,
                                      color: Color(0xFF94A3B8)),
                                ),
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                interval: 1,
                                getTitlesWidget: (v, m) {
                                  final i = v.toInt();
                                  if (i < 0 || i >= series.points.length) {
                                    return const SizedBox.shrink();
                                  }
                                  return Padding(
                                    padding:
                                        const EdgeInsets.only(top: 6),
                                    child: Text(
                                      series.points[i].label,
                                      style: const TextStyle(
                                          fontSize: 10,
                                          color: Color(0xFF64748B)),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          lineBarsData: [
                            LineChartBarData(
                              spots: [
                                for (var i = 0;
                                    i < series.points.length;
                                    i++)
                                  FlSpot(
                                    i.toDouble(),
                                    series.points[i].value.toDouble(),
                                  ),
                              ],
                              isCurved: true,
                              color: const Color(0xFF071B7A),
                              barWidth: 3,
                              dotData: const FlDotData(show: true),
                              belowBarData: BarAreaData(
                                show: true,
                                color: const Color(0xFF071B7A)
                                    .withValues(alpha: 0.12),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            _ChartCard(
              title: 'مقایسه ستونی',
              child: SizedBox(
                height: 200,
                child: series.points.isEmpty
                    ? const Center(child: Text('داده‌ای نیست'))
                    : BarChart(
                        BarChartData(
                          maxY: maxY,
                          gridData: const FlGridData(show: false),
                          borderData: FlBorderData(show: false),
                          titlesData: FlTitlesData(
                            topTitles: const AxisTitles(
                                sideTitles:
                                    SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(
                                sideTitles:
                                    SideTitles(showTitles: false)),
                            leftTitles: const AxisTitles(
                                sideTitles:
                                    SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (v, m) {
                                  final i = v.toInt();
                                  if (i < 0 || i >= series.points.length) {
                                    return const SizedBox.shrink();
                                  }
                                  return Text(
                                    series.points[i].label,
                                    style: const TextStyle(
                                        fontSize: 10,
                                        color: Color(0xFF64748B)),
                                  );
                                },
                              ),
                            ),
                          ),
                          barGroups: [
                            for (var i = 0;
                                i < series.points.length;
                                i++)
                              BarChartGroupData(
                                x: i,
                                barRods: [
                                  BarChartRodData(
                                    toY:
                                        series.points[i].value.toDouble(),
                                    width: 14,
                                    borderRadius:
                                        const BorderRadius.vertical(
                                            top: Radius.circular(6)),
                                    gradient: const LinearGradient(
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                      colors: [
                                        Color(0xFF1E3A8A),
                                        Color(0xFF3B82F6),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.total, required this.range});
  final int total;
  final String range;

  @override
  Widget build(BuildContext context) {
    final label = switch (range) {
      'day' => 'امروز',
      'month' => 'این ماه',
      'all' => 'کل دوره',
      _ => 'این هفته',
    };
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          const Icon(Icons.visibility_outlined, color: Color(0xFF071B7A)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'مجموع بازدید · $label',
              style: const TextStyle(
                  fontWeight: FontWeight.w600, color: Color(0xFF334155)),
            ),
          ),
          Text(
            _fmt(total),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF071B7A),
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      final rev = s.length - i;
      buf.write(s[i]);
      if (rev > 1 && rev % 3 == 1) buf.write(',');
    }
    return buf.toString();
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}