import 'package:flutter/material.dart';
import '../../data/note_models.dart';

class NoteCard extends StatelessWidget {
  final NoteItem note;
  final VoidCallback onTap;

  const NoteCard({super.key, required this.note, required this.onTap});

  Color _getColor(NoteColor color) {
    return Color(int.parse(color.hex.replaceFirst('#', '0xFF')));
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _getColor(note.color).withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===== عنوان (آیکون پین حذف شد) =====
              Text(
                note.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              // ===== محتوای خلاصه =====
              Text(
                note.content.replaceAll(RegExp(r'<[^>]*>'), ''),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 6),
              // ===== ردیف پایین: تگ‌ها + چک‌لیست + آیکون پین (ریسپانسیو) =====
              Row(
                children: [
                  // تگ‌ها (حداکثر ۲ عدد)
                  if (note.tags.isNotEmpty)
                    ...note.tags.take(2).map((tag) => Container(
                      margin: const EdgeInsets.only(right: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '#$tag',
                        style: const TextStyle(fontSize: 9, color: Colors.blue),
                      ),
                    )),
                  // وضعیت چک‌لیست
                  if (note.checklist.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(right: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${note.checklist.where((c) => c.done).length}/${note.checklist.length} ✅',
                        style: const TextStyle(fontSize: 9, color: Colors.green),
                      ),
                    ),
                  const Spacer(),
                  // ===== آیکون پین در پایین (ریسپانسیو) =====
                  if (note.pinned)
                    const Icon(
                      Icons.push_pin,
                      size: 14,
                      color: Colors.blue,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}