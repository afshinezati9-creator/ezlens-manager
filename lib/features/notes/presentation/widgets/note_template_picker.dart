import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/note_models.dart';
import '../notes_provider.dart';

class NoteTemplatePicker extends ConsumerWidget {
  final Function(NoteTemplate) onTemplateSelected;

  const NoteTemplatePicker({
    super.key,
    required this.onTemplateSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templatesAsync = ref.watch(noteTemplatesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'شروع سریع با قالب',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        templatesAsync.when(
          loading: () => const SizedBox(
            height: 50,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          error: (_, __) => const SizedBox.shrink(),
          data: (templates) {
            if (templates.isEmpty) return const SizedBox.shrink();
            return SizedBox(
              height: 60,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: templates.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final template = templates[index];
                  final color = Color(int.parse(template.color.hex.replaceFirst('#', '0xFF')));
                  return GestureDetector(
                    onTap: () => onTemplateSelected(template),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: color.withOpacity(0.3)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(template.icon, style: const TextStyle(fontSize: 20)),
                          const SizedBox(height: 2),
                          Text(
                            template.title,
                            style: TextStyle(fontSize: 10, color: color),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        const Divider(),
      ],
    );
  }
}