import 'package:flutter/material.dart';

class NoteStatsCards extends StatelessWidget {
  final int total;
  final int pinnedCount;
  final int overdueCount;
  final int todayCount;

  const NoteStatsCards({
    super.key,
    required this.total,
    required this.pinnedCount,
    required this.overdueCount,
    required this.todayCount,
  });

  @override
  Widget build(BuildContext context) {
    final stats = [
      ('کل', total, Colors.blue),
      ('پین شده', pinnedCount, Colors.purple),
      ('معوق', overdueCount, Colors.red),
      ('امروز', todayCount, Colors.green),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: stats.map((item) {
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Text(
                    item.$2.toString(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: item.$3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.$1,
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}