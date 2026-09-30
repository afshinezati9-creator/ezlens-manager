import 'package:flutter/material.dart';
import '../../data/note_models.dart';

class NoteReplyWidget extends StatelessWidget {
  final NoteReply reply;
  final VoidCallback onDelete;
  final bool canDelete;

  const NoteReplyWidget({
    super.key,
    required this.reply,
    required this.onDelete,
    this.canDelete = false,
  });

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final persian = date.toLocal();
      return '${persian.year}/${persian.month.toString().padLeft(2, '0')}/${persian.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            radius: 16,
            backgroundColor: Colors.blue,
            child: Icon(Icons.person, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      reply.authorName,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _formatDate(reply.date),
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(reply.content),
              ],
            ),
          ),
          if (canDelete)
            IconButton(
              icon: const Icon(Icons.close, size: 16),
              onPressed: onDelete,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              color: Colors.red.shade400,
            ),
        ],
      ),
    );
  }
}