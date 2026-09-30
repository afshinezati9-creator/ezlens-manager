import 'package:flutter/material.dart';

class StatsPeriodChips extends StatelessWidget {
  const StatsPeriodChips({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final String value; // day | week | month | all
  final ValueChanged<String> onChanged;

  static const _items = [
    ('day', 'روزانه'),
    ('week', 'هفتگی'),
    ('month', 'ماهانه'),
    ('all', 'کل'),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _items.map((e) {
          final selected = value == e.$1;
          return Padding(
            padding: const EdgeInsets.only(left: 8),
            child: ChoiceChip(
              label: Text(e.$2),
              selected: selected,
              onSelected: (_) => onChanged(e.$1),
              selectedColor: const Color(0xFF071B7A),
              labelStyle: TextStyle(
                color: selected ? Colors.white : const Color(0xFF334155),
                fontWeight: FontWeight.w600,
                fontSize: 12.5,
              ),
              backgroundColor: const Color(0xFFF1F5F9),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: selected ? const Color(0xFF071B7A) : const Color(0xFFE2E8F0),
                ),
              ),
              showCheckmark: false,
              visualDensity: VisualDensity.compact,
            ),
          );
        }).toList(),
      ),
    );
  }
}
