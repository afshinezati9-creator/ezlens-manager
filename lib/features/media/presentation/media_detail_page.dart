// lib/features/media/presentation/media_detail_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import 'package:ezlens_manager/core/theme/app_theme.dart';
import 'package:ezlens_manager/core/widgets/app_loading.dart';
import 'package:ezlens_manager/core/widgets/app_error_state.dart';
import '../data/media_models.dart';
import 'media_provider.dart';

class MediaDetailPage extends ConsumerStatefulWidget {
  final int mediaId;
  final bool isEditing;

  const MediaDetailPage({
    super.key,
    required this.mediaId,
    this.isEditing = false,
  });

  @override
  ConsumerState<MediaDetailPage> createState() => _MediaDetailPageState();
}

class _MediaDetailPageState extends ConsumerState<MediaDetailPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _altController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _altController.dispose();
    super.dispose();
  }

  void _copyLink(String url) async {
    await Clipboard.setData(ClipboardData(text: url));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لینک کپی شد')),
      );
    }
  }

  Future<void> _saveChanges(int id) async {
    final title = _titleController.text.trim();
    final alt = _altController.text.trim();

    setState(() => _isSaving = true);
    try {
      final repo = ref.read(mediaRepositoryProvider);
      await repo.updateMediaItem(
        id: id,
        title: title.isNotEmpty ? title : null,
        altText: alt.isNotEmpty ? alt : null,
      );
      ref.invalidate(mediaDetailProvider(id));
      ref.invalidate(mediaProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تغییرات ذخیره شد')),
        );
        context.go('/media');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaAsync = ref.watch(mediaDetailProvider(widget.mediaId));

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(widget.isEditing ? 'ویرایش رسانه' : 'جزئیات رسانه'),
        centerTitle: true,
        backgroundColor: AppTheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/media'),
        ),
      ),
      body: mediaAsync.when(
        loading: () => const AppLoading(),
        error: (err, _) => Center(
          child: AppErrorState(
            title: 'خطا در دریافت اطلاعات',
            subtitle: err.toString(),
            onRetry: () => ref.invalidate(mediaDetailProvider(widget.mediaId)),
          ),
        ),
        data: (item) {
          if (!widget.isEditing) {
            return _buildViewMode(item);
          }
          return _buildEditMode(item);
        },
      ),
    );
  }

  Widget _buildViewMode(MediaItem item) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxHeight: 400),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: _buildPreview(item),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoRow('عنوان', item.title),
                _infoRow('متن جایگزین', item.alt.isEmpty ? '—' : item.alt),
                _infoRow('نوع', _typeLabel(item.type)),
                _infoRow('حجم', item.size),
                if (item.width != null && item.height != null)
                  _infoRow('ابعاد', '${item.width} × ${item.height}'),
                _infoRow('تاریخ ایجاد', _toPersianDate(item.date)),
                _infoRow('تاریخ ویرایش', _toPersianDate(item.modified)),
                const SizedBox(height: 8),
                _infoRow('لینک', item.url, isLink: true),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => context.go('/media/${item.id}/edit'),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('ویرایش'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _copyLink(item.url),
                  icon: const Icon(Icons.copy_outlined),
                  label: const Text('کپی لینک'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showDeleteDialog(item),
              icon: const Icon(Icons.delete_outline, color: AppTheme.danger),
              label: const Text('حذف فایل', style: TextStyle(color: AppTheme.danger)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditMode(MediaItem item) {
    if (_titleController.text.isEmpty) {
      _titleController.text = item.title;
      _altController.text = item.alt;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: _buildPreview(item),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('عنوان', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.border),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('متن جایگزین (ALT)', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                TextField(
                  controller: _altController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.border),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(),
                _infoRow('نوع', _typeLabel(item.type)),
                _infoRow('حجم', item.size),
                if (item.width != null && item.height != null)
                  _infoRow('ابعاد', '${item.width} × ${item.height}'),
                _infoRow('تاریخ ایجاد', _toPersianDate(item.date)),
                const SizedBox(height: 8),
                _infoRow('لینک', item.url, isLink: true),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isSaving ? null : () => context.go('/media'),
                  child: const Text('لغو'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isSaving ? null : () => _saveChanges(item.id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: _isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('ذخیره تغییرات'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPreview(MediaItem item) {
    if (item.type == 'image' && item.url.isNotEmpty) {
      return Image.network(
        item.url,
        fit: BoxFit.contain,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => Icon(Icons.broken_image, size: 60, color: AppTheme.textMuted),
      );
    }
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            item.type == 'video' ? Icons.videocam_outlined :
            item.type == 'audio' ? Icons.audiotrack_outlined :
            Icons.insert_drive_file_outlined,
            size: 50,
            color: AppTheme.textMuted,
          ),
          const SizedBox(height: 8),
          Text(
            _typeLabel(item.type),
            style: const TextStyle(fontSize: 14, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 4),
          Text(item.size, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, {bool isLink = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: isLink ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textSecondary),
            ),
          ),
          Expanded(
            child: isLink
                ? SelectableText(
                    value,
                    style: const TextStyle(fontSize: 13, color: AppTheme.primary),
                  )
                : Text(
                    value,
                    style: const TextStyle(fontSize: 13),
                  ),
          ),
        ],
      ),
    );
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'image': return 'تصویر';
      case 'video': return 'ویدیو';
      case 'audio': return 'صوت';
      default: return 'فایل';
    }
  }

  String _toPersianDate(DateTime date) {
    final jalali = Jalali.fromDateTime(date);
    return '${jalali.year}/${jalali.month.toString().padLeft(2, '0')}/${jalali.day.toString().padLeft(2, '0')}';
  }

  void _showDeleteDialog(MediaItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف فایل'),
        content: Text('آیا از حذف "${item.title}" مطمئن هستید؟ این عمل غیرقابل بازگشت است.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('انصراف'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final repo = ref.read(mediaRepositoryProvider);
                await repo.deleteMediaItem(item.id);
                ref.invalidate(mediaProvider);
                ref.invalidate(mediaTotalCountProvider);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('فایل حذف شد')),
                  );
                  context.go('/media');
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('خطا در حذف: $e')),
                  );
                }
              }
            },
            child: const Text('حذف', style: TextStyle(color: AppTheme.danger)),
          ),
        ],
      ),
    );
  }
}