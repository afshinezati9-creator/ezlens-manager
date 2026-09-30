import 'package:flutter/material.dart';

class NoteTagWidget extends StatelessWidget {
  final List<String> tags;
  final Function(String) onAddTag;
  final Function(String) onRemoveTag;
  final TextEditingController tagInputController;

  const NoteTagWidget({
    super.key,
    required this.tags,
    required this.onAddTag,
    required this.onRemoveTag,
    required this.tagInputController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('برچسب‌ها', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            ...tags.map((tag) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '#$tag',
                      style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () => onRemoveTag(tag),
                      child: Icon(Icons.close, size: 14, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              );
            }),
            // فیلد افزودن برچسب جدید
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 120,
                    child: TextField(
                      controller: tagInputController,
                      decoration: const InputDecoration(
                        hintText: 'برچسب جدید...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: const TextStyle(fontSize: 12),
                      onSubmitted: (value) {
                        if (value.trim().isNotEmpty) {
                          onAddTag(value);
                        }
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, size: 16),
                    onPressed: () {
                      final text = tagInputController.text.trim();
                      if (text.isNotEmpty) {
                        onAddTag(text);
                      }
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}