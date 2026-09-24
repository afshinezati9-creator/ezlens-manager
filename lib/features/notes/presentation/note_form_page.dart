import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';

import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../data/note_models.dart';
import 'notes_provider.dart';
import 'widgets/note_color_picker.dart';
import 'widgets/note_checklist_widget.dart';
import 'widgets/note_tag_widget.dart';
import 'widgets/note_template_picker.dart';

class NoteFormPage extends ConsumerStatefulWidget {
  final int? noteId;

  const NoteFormPage({super.key, this.noteId});

  @override
  ConsumerState<NoteFormPage> createState() => _NoteFormPageState();
}

class _NoteFormPageState extends ConsumerState<NoteFormPage> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  NoteColor _selectedColor = NoteColor.yellow;
  NotePriority _selectedPriority = NotePriority.medium;
  bool _isPinned = false;
  String? _dueDate;
  String? _remindAt;

  List<ChecklistItem> _checklist = [];
  final _checklistInputController = TextEditingController();

  List<NoteFile> _files = [];
  List<String> _tags = [];
  final _tagInputController = TextEditingController();

  bool _isLoading = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.noteId != null;
    if (_isEditing) {
      _loadNote();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _checklistInputController.dispose();
    _tagInputController.dispose();
    super.dispose();
  }

  Future<void> _loadNote() async {
    setState(() => _isLoading = true);
    try {
      final note = await ref.read(noteDetailProvider(widget.noteId!).future);
      _titleController.text = note.title;
      _contentController.text = note.content;
      _selectedColor = note.color;
      _selectedPriority = note.priority;
      _isPinned = note.pinned;
      _dueDate = note.dueDate;
      _remindAt = note.remindAt;
      _checklist = List.from(note.checklist);
      _files = List.from(note.files);
      _tags = List.from(note.tags);
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا در بارگذاری یادداشت: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('عنوان یادداشت را وارد کنید')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final note = NoteItem(
        id: widget.noteId ?? 0,
        title: title,
        content: _contentController.text,
        color: _selectedColor,
        priority: _selectedPriority,
        pinned: _isPinned,
        dueDate: _dueDate,
        remindAt: _remindAt,
        checklist: _checklist,
        files: _files,
        tags: _tags,
        date: DateTime.now().toIso8601String(),
        modified: DateTime.now().toIso8601String(),
        author: 0,
        authorName: '',
      );

      if (_isEditing) {
        await ref.read(noteRepositoryProvider).updateNote(note);
      } else {
        await ref.read(noteRepositoryProvider).createNote(note);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'یادداشت ویرایش شد' : 'یادداشت ایجاد شد'),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles();
      if (result == null) return;

      final file = result.files.first;
      if (file.path == null) return;

      // تشخیص نوع فایل از extension
      final ext = file.name.split('.').last.toLowerCase();
      String mimeType = 'application/octet-stream';
      if (['jpg', 'jpeg', 'jpe'].contains(ext)) mimeType = 'image/jpeg';
      else if (['png'].contains(ext)) mimeType = 'image/png';
      else if (['gif'].contains(ext)) mimeType = 'image/gif';
      else if (['webp'].contains(ext)) mimeType = 'image/webp';
      else if (['pdf'].contains(ext)) mimeType = 'application/pdf';
      else if (['doc', 'docx'].contains(ext)) mimeType = 'application/msword';
      else if (['xls', 'xlsx'].contains(ext)) mimeType = 'application/vnd.ms-excel';
      else if (['zip'].contains(ext)) mimeType = 'application/zip';
      else if (['txt'].contains(ext)) mimeType = 'text/plain';

      final uploadedFile = await ref.read(noteRepositoryProvider).uploadFile(
            filePath: file.path!,
            fileName: file.name,
            mimeType: mimeType,
          );

      setState(() {
        _files = [..._files, uploadedFile];
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا در آپلود فایل: $e')),
      );
    }
  }

  void _addTag(String tag) {
    final trimmed = tag.trim();
    if (trimmed.isNotEmpty && !_tags.contains(trimmed)) {
      setState(() => _tags = [..._tags, trimmed]);
    }
    _tagInputController.clear();
  }

  void _removeTag(String tag) {
    setState(() => _tags = _tags.where((t) => t != tag).toList());
  }

  void _addChecklistItem(String text) {
    final trimmed = text.trim();
    if (trimmed.isNotEmpty) {
      setState(() {
        _checklist = [
          ..._checklist,
          ChecklistItem(text: trimmed, done: false),
        ];
      });
    }
    _checklistInputController.clear();
  }

  void _removeChecklistItem(int index) {
    setState(() => _checklist.removeAt(index));
  }

  void _toggleChecklistItem(int index) {
    setState(() {
      final item = _checklist[index];
      _checklist[index] = item.copyWith(done: !item.done);
    });
  }

  void _removeFile(int index) {
    setState(() => _files.removeAt(index));
  }

  void _applyTemplate(NoteTemplate template) {
    setState(() {
      _titleController.text = template.title;
      _contentController.text = template.content;
      _selectedColor = template.color;
      _selectedPriority = template.priority;
      _tags = List.from(template.tags);
      _checklist = List.from(template.checklist);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'ویرایش یادداشت' : 'یادداشت جدید'),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _save,
              tooltip: 'ذخیره',
            ),
        ],
      ),
      body: _isLoading && _isEditing
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!_isEditing)
                    NoteTemplatePicker(
                      onTemplateSelected: _applyTemplate,
                    ),

                  const SizedBox(height: 16),

                  AppTextField(
                    controller: _titleController,
                    label: 'عنوان یادداشت',
                    hint: 'عنوان را وارد کنید...',
                    maxLines: 1,
                  ),

                  const SizedBox(height: 16),

                  AppTextField(
                    controller: _contentController,
                    label: 'محتوا',
                    hint: 'متن یادداشت را وارد کنید...',
                    maxLines: 5,
                  ),

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('رنگ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            NoteColorPicker(
                              selectedColor: _selectedColor,
                              onColorSelected: (color) => setState(() => _selectedColor = color),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('اولویت', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<NotePriority>(
                              value: _selectedPriority,
                              items: NotePriority.values.map((p) {
                                return DropdownMenuItem(
                                  value: p,
                                  child: Text(p.label),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) setState(() => _selectedPriority = value);
                              },
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('تاریخ سررسید', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            InkWell(
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: _dueDate != null
                                      ? DateTime.parse(_dueDate!)
                                      : DateTime.now(),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2030),
                                );
                                if (date != null) {
                                  setState(() => _dueDate = date.toIso8601String().split('T').first);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade400),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
                                    const SizedBox(width: 8),
                                    Text(
                                      _dueDate != null
                                          ? _dueDate!
                                          : 'انتخاب تاریخ',
                                      style: TextStyle(
                                        color: _dueDate != null ? Colors.black : Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('پین شده', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            SwitchListTile(
                              value: _isPinned,
                              onChanged: (value) => setState(() => _isPinned = value),
                              title: const Text('پین در بالای لیست'),
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  NoteTagWidget(
                    tags: _tags,
                    onAddTag: _addTag,
                    onRemoveTag: _removeTag,
                    tagInputController: _tagInputController,
                  ),

                  const SizedBox(height: 16),

                  NoteChecklistWidget(
                    items: _checklist,
                    onAddItem: _addChecklistItem,
                    onRemoveItem: _removeChecklistItem,
                    onToggleItem: _toggleChecklistItem,
                    inputController: _checklistInputController,
                  ),

                  const SizedBox(height: 16),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('فایل‌های پیوست', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: _pickFile,
                            icon: const Icon(Icons.attach_file, size: 18),
                            label: const Text('افزودن فایل'),
                          ),
                        ],
                      ),
                      if (_files.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(12),
                          child: Text('هیچ فایلی پیوست نشده است', style: TextStyle(color: Colors.grey)),
                        )
                      else
                        ..._files.asMap().entries.map((entry) {
                          final index = entry.key;
                          final file = entry.value;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.insert_drive_file, size: 20, color: Colors.grey),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        file.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontWeight: FontWeight.w500),
                                      ),
                                      if (file.size != null)
                                        Text(
                                          '${(file.size! / 1024).toStringAsFixed(1)} KB',
                                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                                        ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, size: 18),
                                  onPressed: () => _removeFile(index),
                                  tooltip: 'حذف فایل',
                                ),
                              ],
                            ),
                          );
                        }),
                    ],
                  ),

                  const SizedBox(height: 24),

                  AppButton(
                    label: _isEditing ? 'ویرایش یادداشت' : 'ایجاد یادداشت',
                    onPressed: _isLoading ? null : _save,
                    isExpanded: true,
                    variant: AppButtonVariant.primary,
                    isLoading: _isLoading,
                  ),
                  const SizedBox(height: 8),
                  AppButton(
                    label: 'انصراف',
                    onPressed: () => Navigator.pop(context),
                    isExpanded: true,
                    variant: AppButtonVariant.outline,
                  ),
                ],
              ),
            ),
    );
  }
}