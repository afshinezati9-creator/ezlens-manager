import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/request_models.dart';
import '../requests_provider.dart';

class RequestNotesSection extends ConsumerStatefulWidget {
  final int requestId;

  const RequestNotesSection({super.key, required this.requestId});

  @override
  ConsumerState<RequestNotesSection> createState() => _RequestNotesSectionState();
}

class _RequestNotesSectionState extends ConsumerState<RequestNotesSection> {
  final controller = TextEditingController();
  bool saving = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> add() async {
    final text = controller.text.trim();
    if (text.isEmpty || saving) return;

    setState(() => saving = true);
    try {
      await ref.read(requestRepositoryProvider).addNote(widget.requestId, text);
      controller.clear();
      ref.invalidate(requestNotesProvider(widget.requestId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('یادداشت ثبت شد')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final notes = ref.watch(requestNotesProvider(widget.requestId));

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('یادداشت داخلی تیم', style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'یادداشت داخلی برای پیگیری...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: saving ? null : add,
              icon: saving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.add_comment_outlined),
              label: const Text('ثبت یادداشت'),
            ),
            const SizedBox(height: 8),
            notes.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(12),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Text('خطا در دریافت یادداشت‌ها: $e'),
              data: (items) => items.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(10),
                      child: Text('هنوز یادداشتی ثبت نشده است'),
                    )
                  : Column(
                      children: items.map((RequestNote n) {
                        return Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(top: 7),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${n.author} · ${n.date ?? ''}',
                                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                              const SizedBox(height: 4),
                              Text(n.text),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}