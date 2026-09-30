import 'package:flutter/material.dart';

class RequestStatsCards extends StatelessWidget {
  final Map<String, int> counts;
  final int total;

  const RequestStatsCards({
    super.key,
    required this.counts,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final data = [
      ('کل', total, Icons.inbox_outlined, Colors.blue.shade700),
      ('جدید', counts['new'] ?? 0, Icons.fiber_new_outlined, Colors.orange.shade700),
      ('در حال بررسی', counts['review'] ?? 0, Icons.hourglass_empty_rounded, Colors.purple.shade700),
      ('بررسی شده', counts['processed'] ?? 0, Icons.check_circle_outline, Colors.green.shade700),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: data.map((x) {
        return Container(
          width: _getCardWidth(context),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade100,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: x.$4.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(x.$3, size: 20, color: x.$4),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      x.$1,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${x.$2}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ===== محاسبه عرض کارت بر اساس اندازه صفحه =====
  double _getCardWidth(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 400) {
      // موبایل کوچک
      return (width - 32 - 8) / 2; // ۲ ستون با فاصله
    } else if (width < 700) {
      // موبایل بزرگ / تبلت کوچک
      return (width - 32 - 16) / 3; // ۳ ستون
    } else {
      // تبلت / دسکتاپ
      return (width - 32 - 24) / 4; // ۴ ستون
    }
  }
}