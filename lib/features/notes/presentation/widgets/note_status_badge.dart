import 'package:flutter/material.dart';
import '../../data/note_models.dart';

class NoteStatusBadge extends StatelessWidget {
  final NotePriority priority;
  final NoteColor color;

  const NoteStatusBadge({
    super.key,
    required this.priority,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Color(int.parse(color.hex.replaceFirst('#', '0xFF'))).withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        priority.label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: Color(int.parse(color.hex.replaceFirst('#', '0xFF'))),
        ),
      ),
    );
  }
}