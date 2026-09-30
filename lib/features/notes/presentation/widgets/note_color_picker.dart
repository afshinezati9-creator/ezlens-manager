import 'package:flutter/material.dart';
import '../../data/note_models.dart';

class NoteColorPicker extends StatelessWidget {
  final NoteColor selectedColor;
  final Function(NoteColor) onColorSelected;

  const NoteColorPicker({
    super.key,
    required this.selectedColor,
    required this.onColorSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: NoteColor.values.map((color) {
        final isSelected = color == selectedColor;
        return GestureDetector(
          onTap: () => onColorSelected(color),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Color(int.parse(color.hex.replaceFirst('#', '0xFF'))),
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.blue.shade700 : Colors.transparent,
                width: 3,
              ),
            ),
            child: isSelected
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : null,
          ),
        );
      }).toList(),
    );
  }
}