import 'package:flutter/material.dart';
import '../../data/note_models.dart';

class NoteChecklistWidget extends StatelessWidget {
  final List<ChecklistItem> items;
  final Function(String) onAddItem;
  final Function(int) onRemoveItem;
  final Function(int) onToggleItem;
  final TextEditingController inputController;

  const NoteChecklistWidget({
    super.key,
    required this.items,
    required this.onAddItem,
    required this.onRemoveItem,
    required this.onToggleItem,
    required this.inputController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('چک‌لیست', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        if (items.isEmpty)
          const Padding(
            padding: EdgeInsets.all(8),
            child: Text('هیچ آیتمی اضافه نشده است', style: TextStyle(color: Colors.grey, fontSize: 12)),
          )
        else
          ...items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => onToggleItem(index),
                    child: Icon(
                      item.done ? Icons.check_box : Icons.check_box_outline_blank,
                      size: 20,
                      color: item.done ? Colors.green : Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.text,
                      style: TextStyle(
                        decoration: item.done ? TextDecoration.lineThrough : null,
                        color: item.done ? Colors.grey.shade600 : null,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    onPressed: () => onRemoveItem(index),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    color: Colors.red.shade400,
                  ),
                ],
              ),
            );
          }),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: inputController,
                decoration: const InputDecoration(
                  hintText: 'آیتم جدید...',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
                onSubmitted: (value) {
                  if (value.trim().isNotEmpty) {
                    onAddItem(value);
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: () {
                final text = inputController.text.trim();
                if (text.isNotEmpty) {
                  onAddItem(text);
                }
              },
              icon: const Icon(Icons.add, size: 18),
              padding: const EdgeInsets.all(8),
            ),
          ],
        ),
      ],
    );
  }
}