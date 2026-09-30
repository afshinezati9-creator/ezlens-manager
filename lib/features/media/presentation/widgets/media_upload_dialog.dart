// lib/features/media/presentation/widgets/media_upload_dialog.dart

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:ezlens_manager/core/theme/app_theme.dart';
import '../../data/media_repository.dart';
import '../media_provider.dart';

class MediaUploadDialog extends ConsumerStatefulWidget {
  final VoidCallback onUploadComplete;

  const MediaUploadDialog({
    super.key,
    required this.onUploadComplete,
  });

  @override
  ConsumerState<MediaUploadDialog> createState() => _MediaUploadDialogState();
}

class _MediaUploadDialogState extends ConsumerState<MediaUploadDialog> {
  final TextEditingController _titleController = TextEditingController();
  bool _isUploading = false;
  double _progress = 0;
  String _statusMessage = '';
  List<({Uint8List bytes, String name})> _selectedFiles = [];

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.any,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _selectedFiles = result.files.map((f) {
          return (
            bytes: f.bytes!,
            name: f.name,
          );
        }).toList();
        _progress = 0;
        _statusMessage = '';
      });
    }
  }

  Future<void> _uploadFiles() async {
    if (_selectedFiles.isEmpty) {
      setState(() => _statusMessage = 'لطفاً حداقل یک فایل انتخاب کنید.');
      return;
    }

    setState(() {
      _isUploading = true;
      _progress = 0;
      _statusMessage = '';
    });

    try {
      final repo = ref.read(mediaRepositoryProvider);
      final total = _selectedFiles.length;
      int uploaded = 0;

      for (final file in _selectedFiles) {
        await repo.uploadMediaFromBytes(
          bytes: file.bytes,
          fileName: file.name,
          title: _titleController.text.trim().isNotEmpty ? _titleController.text.trim() : null,
        );

        uploaded++;
        setState(() {
          _progress = (uploaded / total) * 100;
          _statusMessage = '$uploaded از $total آپلود شد...';
        });
      }

      setState(() {
        _statusMessage = '✅ ${NumberFormat.decimalPattern('fa').format(total)} فایل با موفقیت آپلود شد.';
        _selectedFiles.clear();
        _titleController.clear();
      });

      widget.onUploadComplete();

      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) Navigator.pop(context);
      });

    } catch (e) {
      setState(() {
        _statusMessage = '❌ خطا: $e';
      });
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'آپلود فایل',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'عنوان اختیاری',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
              const SizedBox(height: 12),

              ElevatedButton.icon(
                onPressed: _isUploading ? null : _pickFiles,
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: Text(_selectedFiles.isEmpty ? 'انتخاب فایل‌ها...' : '${_selectedFiles.length} فایل انتخاب شد'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 44),
                ),
              ),
              const SizedBox(height: 12),

              if (_selectedFiles.isNotEmpty)
                Container(
                  constraints: const BoxConstraints(maxHeight: 100),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _selectedFiles.length,
                    itemBuilder: (context, index) {
                      final file = _selectedFiles[index];
                      return ListTile(
                        title: Text(file.name, style: const TextStyle(fontSize: 13)),
                        leading: const Icon(Icons.insert_drive_file, size: 18),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      );
                    },
                  ),
                ),

              if (_isUploading || _progress > 0) ...[
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: _progress / 100,
                  backgroundColor: AppTheme.border,
                  color: AppTheme.primary,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
                const SizedBox(height: 4),
                Text(
                  _statusMessage,
                  style: TextStyle(
                    fontSize: 13,
                    color: _statusMessage.contains('✅')
                        ? AppTheme.success
                        : _statusMessage.contains('❌')
                            ? AppTheme.danger
                            : AppTheme.textSecondary,
                  ),
                ),
              ],

              if (_statusMessage.isNotEmpty && !_isUploading && _statusMessage.contains('❌'))
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _statusMessage,
                    style: const TextStyle(fontSize: 13, color: AppTheme.danger),
                  ),
                ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isUploading ? null : () => Navigator.pop(context),
                      child: const Text('لغو'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: (_selectedFiles.isEmpty || _isUploading) ? null : _uploadFiles,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: _isUploading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('آپلود'),
                    ),
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