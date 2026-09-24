import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_loading.dart';
import '../data/note_models.dart';
import 'notes_provider.dart';
import 'widgets/note_attachment_widget.dart';
import 'widgets/note_reply_widget.dart';
import 'widgets/note_status_badge.dart';
import 'note_form_page.dart';

class NoteDetailPage extends ConsumerStatefulWidget {
  final int noteId;

  const NoteDetailPage({super.key, required this.noteId});

  @override
  ConsumerState<NoteDetailPage> createState() => _NoteDetailPageState();
}

class _NoteDetailPageState extends ConsumerState<NoteDetailPage> {
  final _replyController = TextEditingController();

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    ref.invalidate(noteDetailProvider(widget.noteId));
    await ref.read(noteDetailProvider(widget.noteId).future);
  }

  Future<void> _deleteNote() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف یادداشت'),
        content: const Text('آیا از حذف این یادداشت مطمئن هستید؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('انصراف'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ref.read(noteRepositoryProvider).deleteNote(widget.noteId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('یادداشت حذف شد')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در حذف: $e')),
        );
      }
    }
  }

  Future<void> _togglePinned() async {
    try {
      final currentNote = await ref.read(noteDetailProvider(widget.noteId).future);
      final updatedNote = currentNote.copyWith(pinned: !currentNote.pinned);
      await ref.read(noteRepositoryProvider).updateNote(updatedNote);
      ref.invalidate(noteDetailProvider(widget.noteId));
      ref.invalidate(notesProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(updatedNote.pinned ? 'یادداشت پین شد' : 'پین برداشته شد'),
          ),
        );
        _refresh();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا: $e')),
        );
      }
    }
  }

  Future<void> _addReply() async {
    final content = _replyController.text.trim();
    if (content.isEmpty) return;

    try {
      await ref.read(noteRepositoryProvider).addReply(
            noteId: widget.noteId,
            content: content,
          );
      _replyController.clear();
      ref.invalidate(noteDetailProvider(widget.noteId));
      ref.invalidate(noteRepliesProvider(widget.noteId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('پاسخ ثبت شد')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در ثبت پاسخ: $e')),
        );
      }
    }
  }

  Future<void> _deleteReply(String replyId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف پاسخ'),
        content: const Text('آیا از حذف این پاسخ مطمئن هستید؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('انصراف'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ref.read(noteRepositoryProvider).deleteReply(
            noteId: widget.noteId,
            replyId: replyId,
          );
      ref.invalidate(noteDetailProvider(widget.noteId));
      ref.invalidate(noteRepliesProvider(widget.noteId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('پاسخ حذف شد')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در حذف پاسخ: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final noteAsync = ref.watch(noteDetailProvider(widget.noteId));
    final repliesAsync = ref.watch(noteRepliesProvider(widget.noteId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('جزئیات یادداشت'),
        actions: [
          // دکمه پین از AppBar حذف شد و به FAB منتقل شد
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => NoteFormPage(noteId: widget.noteId),
              ),
            ).then((_) => _refresh()),
            tooltip: 'ویرایش',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _deleteNote,
            tooltip: 'حذف',
          ),
        ],
      ),
      body: noteAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('خطا در بارگذاری: $e', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              AppButton(
                label: 'تلاش مجدد',
                onPressed: _refresh,
                variant: AppButtonVariant.primary,
              ),
            ],
          ),
        ),
        data: (note) {
          return RefreshIndicator(
            onRefresh: _refresh,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // عنوان و وضعیت
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          note.title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (note.pinned)
                        const Icon(Icons.push_pin, color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      NoteStatusBadge(
                        priority: note.priority,
                        color: note.color,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'نویسنده: ${note.authorName} | ${_formatDate(note.modified)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  if (note.dueDate != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '🗓️ سررسید: ${_formatDate(note.dueDate!)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: _isOverdue(note.dueDate!) ? Colors.red : Colors.grey.shade600,
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  const Divider(),

                  // محتوا
                  if (note.content.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        note.content,
                        style: const TextStyle(height: 1.8),
                      ),
                    ),
                  const SizedBox(height: 16),

                  // برچسب‌ها
                  if (note.tags.isNotEmpty)
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: note.tags.map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '#$tag',
                            style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
                          ),
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 16),

                  // چک‌لیست
                  if (note.checklist.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'چک‌لیست',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        ...note.checklist.asMap().entries.map((entry) {
                          final index = entry.key;
                          final item = entry.value;
                          return CheckboxListTile(
                            value: item.done,
                            onChanged: (_) async {
                              final updatedChecklist = List.of(note.checklist);
                              updatedChecklist[index] = item.copyWith(done: !item.done);
                              try {
                                final updatedNote = note.copyWith(checklist: updatedChecklist);
                                await ref.read(noteRepositoryProvider).updateNote(updatedNote);
                                ref.invalidate(noteDetailProvider(widget.noteId));
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('خطا: $e')),
                                  );
                                }
                              }
                            },
                            title: Text(
                              item.text,
                              style: TextStyle(
                                decoration: item.done ? TextDecoration.lineThrough : null,
                                color: item.done ? Colors.grey.shade600 : null,
                              ),
                            ),
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            controlAffinity: ListTileControlAffinity.leading,
                          );
                        }),
                        const SizedBox(height: 8),
                      ],
                    ),

                  // فایل‌های پیوست
                  if (note.files.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'فایل‌های پیوست',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        ...note.files.map((file) => NoteAttachmentWidget(file: file)),
                        const SizedBox(height: 8),
                      ],
                    ),

                  const Divider(),

                  // پاسخ‌ها (کامنت‌ها)
                  const Text(
                    'پاسخ‌ها',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  repliesAsync.when(
                    loading: () => const AppLoading(message: 'بارگذاری پاسخ‌ها...'),
                    error: (e, _) => Text('خطا: $e', style: const TextStyle(color: Colors.red)),
                    data: (replies) {
                      if (replies.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(12),
                          child: Text(
                            'هنوز پاسخی ثبت نشده است',
                            style: TextStyle(color: Colors.grey),
                          ),
                        );
                      }
                      return Column(
                        children: replies.map((reply) {
                          return NoteReplyWidget(
                            reply: reply,
                            onDelete: () => _deleteReply(reply.id),
                            canDelete: true,
                          );
                        }).toList(),
                      );
                    },
                  ),

                  const SizedBox(height: 12),

                  // افزودن پاسخ جدید
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _replyController,
                          decoration: const InputDecoration(
                            hintText: 'پاسخ خود را بنویسید...',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          maxLines: null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        onPressed: _addReply,
                        icon: const Icon(Icons.send),
                        tooltip: 'ارسال پاسخ',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
      // ===== دکمه پین به‌صورت FloatingActionButton در پایین صفحه =====
      floatingActionButton: FloatingActionButton(
        onPressed: _togglePinned,
        child: Consumer(
          builder: (context, ref, child) {
            final noteAsync = ref.watch(noteDetailProvider(widget.noteId));
            return noteAsync.when(
              loading: () => const Icon(Icons.push_pin_outlined),
              error: (_, __) => const Icon(Icons.push_pin_outlined),
              data: (note) => Icon(
                note.pinned ? Icons.push_pin : Icons.push_pin_outlined,
                color: note.pinned ? Colors.white : null,
              ),
            );
          },
        ),
        tooltip: 'پین/برداشتن پین',
        backgroundColor: Colors.blue,
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final persian = date.toLocal();
      return '${persian.year}/${persian.month.toString().padLeft(2, '0')}/${persian.day.toString().padLeft(2, '0')} '
          '${persian.hour.toString().padLeft(2, '0')}:${persian.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateStr;
    }
  }

  bool _isOverdue(String dueDate) {
    try {
      final date = DateTime.parse(dueDate);
      return date.isBefore(DateTime.now());
    } catch (_) {
      return false;
    }
  }
}