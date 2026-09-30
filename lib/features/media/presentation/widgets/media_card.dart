// lib/features/media/presentation/widgets/media_card.dart

import 'package:flutter/material.dart';
import 'package:ezlens_manager/core/theme/app_theme.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import '../../data/media_models.dart';

class MediaCard extends StatelessWidget {
  final MediaItem item;
  final bool isGrid;
  final VoidCallback onTap;
  final VoidCallback onCopyLink;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const MediaCard({
    super.key,
    required this.item,
    this.isGrid = false,
    required this.onTap,
    required this.onCopyLink,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (isGrid) {
      return _buildGridCard();
    }
    return _buildListCard();
  }

  Widget _buildListCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: onTap,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.surfaceHover,
                borderRadius: BorderRadius.circular(12),
              ),
              child: _buildThumbnail(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_typeLabel(item.type)} · ${item.size} · ${_toPersianDate(item.date)}',
                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.url,
                    style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _actionButton('مشاهده', Icons.visibility_outlined, onTap),
                      _actionButton('ویرایش', Icons.edit_outlined, onEdit),
                      _actionButton('کپی لینک', Icons.copy_outlined, onCopyLink),
                      _actionButton('حذف', Icons.delete_outline, onDelete, color: AppTheme.danger),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridCard() {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceHover,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: _buildThumbnail(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${item.size} · ${_toPersianDate(item.date)}',
                    style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: IconButton(
                          icon: const Icon(Icons.copy_outlined, size: 18),
                          onPressed: onCopyLink,
                          tooltip: 'کپی لینک',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ),
                      Expanded(
                        child: IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          onPressed: onEdit,
                          tooltip: 'ویرایش',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ),
                      Expanded(
                        child: IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.danger),
                          onPressed: onDelete,
                          tooltip: 'حذف',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    if (item.type == 'image' && item.url.isNotEmpty) {
      return Image.network(
        item.url,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => Icon(Icons.broken_image, size: 40, color: AppTheme.textMuted),
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
            size: 30,
            color: AppTheme.textMuted,
          ),
          const SizedBox(height: 4),
          Text(
            _typeLabel(item.type),
            style: TextStyle(fontSize: 10, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(String label, IconData icon, VoidCallback onPressed, {Color? color}) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        side: BorderSide(color: AppTheme.border.withOpacity(0.5)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color ?? AppTheme.textSecondary),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, color: color ?? AppTheme.textSecondary)),
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
}