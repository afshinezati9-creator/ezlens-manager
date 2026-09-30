import 'package:flutter/material.dart';

/// Top CTA — opens full visits analytics page.
class VisitsHeroBanner extends StatelessWidget {
  const VisitsHeroBanner({
    super.key,
    required this.onOpenCharts,
    this.visitorsLabel = '—',
  });

  final VoidCallback onOpenCharts;
  final String visitorsLabel;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onOpenCharts,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [Color(0xFF071B7A), Color(0xFF1E3A8A), Color(0xFF0F172A)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF071B7A).withValues(alpha: 0.28),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.show_chart_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'آمار بازدید سایت',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'نمودار تفصیلی · بازدید فعلی: $visitorsLabel',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_left, color: Colors.white.withValues(alpha: 0.9)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
