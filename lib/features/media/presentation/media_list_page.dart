// lib/features/media/presentation/media_list_page.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:go_router/go_router.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';

import 'package:ezlens_manager/core/theme/app_theme.dart';
import 'package:ezlens_manager/core/widgets/app_empty_state.dart';
import 'package:ezlens_manager/core/widgets/app_error_state.dart';
import 'package:ezlens_manager/core/widgets/app_loading.dart';
import '../data/media_models.dart';
import 'media_provider.dart';
import 'widgets/media_card.dart';
import 'widgets/media_upload_dialog.dart';

// ============================================================
// Helpers
// ============================================================

String _toFa(num value) {
  const fa = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
  return value.toString().split('').map((d) => fa[int.parse(d)]).join();
}

String _toPersianDate(DateTime date) {
  final jalali = Jalali.fromDateTime(date);
  return '${jalali.year}/${jalali.month.toString().padLeft(2, '0')}/${jalali.day.toString().padLeft(2, '0')}';
}

// ============================================================
// Main Page
// ============================================================

class MediaListPage extends ConsumerStatefulWidget {
  const MediaListPage({super.key});

  @override
  ConsumerState<MediaListPage> createState() => _MediaListPageState();
}

class _MediaListPageState extends ConsumerState<MediaListPage> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  DateTime? _dateFrom;
  DateTime? _dateTo;
  String _sizeFilter = 'all';

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      ref.read(mediaSearchProvider.notifier).state = value;
      ref.read(mediaPageProvider.notifier).state = 1;
      ref.invalidate(mediaProvider);
      ref.invalidate(mediaTotalCountProvider);
    });
  }

  void _onTypeChanged(String? value) {
    ref.read(mediaTypeProvider.notifier).state = value;
    ref.read(mediaPageProvider.notifier).state = 1;
    ref.invalidate(mediaProvider);
    ref.invalidate(mediaTotalCountProvider);
  }

  void _onPerPageChanged(int value) {
    ref.read(mediaPerPageProvider.notifier).state = value;
    ref.read(mediaPageProvider.notifier).state = 1;
    ref.invalidate(mediaProvider);
  }

  void _toggleViewMode() {
    final current = ref.read(mediaViewModeProvider);
    ref.read(mediaViewModeProvider.notifier).state = current == 'list' ? 'grid' : 'list';
  }

  Future<void> _selectDateRange() async {
    final now = DateTime.now();
    final start = _dateFrom ?? now.subtract(const Duration(days: 30));
    final end = _dateTo ?? now;

    final picked = await showPersianDateRangePicker(
      context: context,
      initialDate: Jalali.fromDateTime(start),
      initialDateRange: JalaliRange(
        start: Jalali.fromDateTime(start),
        end: Jalali.fromDateTime(end),
      ),
      firstDate: Jalali(1400, 1, 1),
      lastDate: Jalali(1410, 12, 29),
    );

    if (picked != null) {
      setState(() {
        _dateFrom = picked.start.toDateTime();
        _dateTo = picked.end.toDateTime();
      });
      ref.read(mediaDateFromProvider.notifier).state = _dateFrom;
      ref.read(mediaDateToProvider.notifier).state = _dateTo;
      ref.read(mediaPageProvider.notifier).state = 1;
      ref.invalidate(mediaProvider);
    }
  }

  void _clearDateFilter() {
    setState(() {
      _dateFrom = null;
      _dateTo = null;
    });
    ref.read(mediaDateFromProvider.notifier).state = null;
    ref.read(mediaDateToProvider.notifier).state = null;
    ref.read(mediaPageProvider.notifier).state = 1;
    ref.invalidate(mediaProvider);
  }

  String _getDateRangeLabel() {
    if (_dateFrom == null && _dateTo == null) return 'همه تاریخ';
    final start = _dateFrom != null ? _toPersianDate(_dateFrom!) : 'نامشخص';
    final end = _dateTo != null ? _toPersianDate(_dateTo!) : 'نامشخص';
    return '$start تا $end';
  }

  Future<void> _openUploadDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => MediaUploadDialog(
        onUploadComplete: () {
          ref.invalidate(mediaProvider);
          ref.invalidate(mediaTotalCountProvider);
          ref.read(mediaPageProvider.notifier).state = 1;
        },
      ),
    );
  }

  void _copyLink(String url) async {
    await Clipboard.setData(ClipboardData(text: url));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لینک کپی شد')),
      );
    }
  }

  List<MediaItem> _applyClientFilters(List<MediaItem> items) {
    var filtered = items;

    if (_sizeFilter != 'all') {
      filtered = filtered.where((item) {
        if (_sizeFilter == 'small') return item.bytes < 100 * 1024;
        if (_sizeFilter == 'medium') return item.bytes >= 100 * 1024 && item.bytes < 1024 * 1024;
        if (_sizeFilter == 'large') return item.bytes >= 1024 * 1024;
        return true;
      }).toList();
    }

    if (_dateFrom != null) {
      final fromMs = _dateFrom!.millisecondsSinceEpoch;
      filtered = filtered.where((item) => item.date.millisecondsSinceEpoch >= fromMs).toList();
    }

    if (_dateTo != null) {
      final toMs = _dateTo!.millisecondsSinceEpoch + 86400000;
      filtered = filtered.where((item) => item.date.millisecondsSinceEpoch <= toMs).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final mediaAsync = ref.watch(mediaProvider);
    final totalAsync = ref.watch(mediaTotalCountProvider);
    final currentPage = ref.watch(mediaPageProvider);
    final viewMode = ref.watch(mediaViewModeProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isMobile = screenWidth < 600;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('رسانه‌ها'),
        centerTitle: true,
        backgroundColor: AppTheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(viewMode == 'list' ? Icons.grid_view_rounded : Icons.list_rounded),
            onPressed: _toggleViewMode,
            tooltip: viewMode == 'list' ? 'نمایش جدولی' : 'نمایش لیستی',
          ),
          IconButton(
            icon: const Icon(Icons.upload_file_rounded),
            onPressed: _openUploadDialog,
            tooltip: 'آپلود',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(mediaProvider);
              ref.invalidate(mediaTotalCountProvider);
            },
            tooltip: 'به‌روزرسانی',
          ),
        ],
      ),
      body: Column(
        children: [
          // Header آمار
          Container(
            color: AppTheme.surface,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: totalAsync.when(
              loading: () => const Text('در حال دریافت تعداد...', style: TextStyle(fontSize: 13, color: AppTheme.textMuted)),
              error: (_, __) => const Text('خطا در دریافت تعداد', style: TextStyle(fontSize: 13, color: AppTheme.danger)),
              data: (total) => Text(
                '${_toFa(total)} مورد از کتابخانه وردپرس',
                style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
            ),
          ),

          // فیلترها
          Container(
            color: AppTheme.surface,
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        decoration: InputDecoration(
                          hintText: 'جستجوی عنوان...',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppTheme.border),
                          ),
                          filled: true,
                          fillColor: AppTheme.background,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: isMobile ? 100 : 120,
                      child: DropdownButtonFormField<String?>(
                        value: ref.watch(mediaTypeProvider),
                        decoration: InputDecoration(
                          labelText: 'فرمت',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppTheme.border),
                          ),
                          filled: true,
                          fillColor: AppTheme.background,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        ),
                        items: const [
                          DropdownMenuItem(value: null, child: Text('همه')),
                          DropdownMenuItem(value: 'image', child: Text('تصویر')),
                          DropdownMenuItem(value: 'video', child: Text('ویدیو')),
                          DropdownMenuItem(value: 'audio', child: Text('صوت')),
                          DropdownMenuItem(value: 'file', child: Text('فایل')),
                        ],
                        onChanged: _onTypeChanged,
                        isDense: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    // ✅ فیلتر سایز با Expanded (رفع Overflow)
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _sizeFilter,
                        decoration: InputDecoration(
                          labelText: 'سایز',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppTheme.border),
                          ),
                          filled: true,
                          fillColor: AppTheme.background,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('همه سایزها')),
                          DropdownMenuItem(value: 'small', child: Text('کوچک (زیر ۱۰۰KB)')),
                          DropdownMenuItem(value: 'medium', child: Text('متوسط (۱۰۰KB-۱MB)')),
                          DropdownMenuItem(value: 'large', child: Text('بزرگ (بالای ۱MB)')),
                        ],
                        onChanged: (value) {
                          setState(() => _sizeFilter = value ?? 'all');
                          ref.read(mediaPageProvider.notifier).state = 1;
                          ref.invalidate(mediaProvider);
                        },
                        isDense: true,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: _selectDateRange,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppTheme.border),
                            borderRadius: BorderRadius.circular(12),
                            color: AppTheme.background,
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today_outlined, size: 16, color: AppTheme.primary),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  _getDateRangeLabel(),
                                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (_dateFrom != null || _dateTo != null)
                                GestureDetector(
                                  onTap: _clearDateFilter,
                                  child: const Icon(Icons.close, size: 16, color: AppTheme.danger),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: isMobile ? 80 : 100,
                      child: DropdownButtonFormField<int>(
                        value: ref.watch(mediaPerPageProvider),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppTheme.border),
                          ),
                          filled: true,
                          fillColor: AppTheme.background,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        ),
                        items: const [
                          DropdownMenuItem(value: 12, child: Text('۱۲')),
                          DropdownMenuItem(value: 24, child: Text('۲۴')),
                          DropdownMenuItem(value: 48, child: Text('۴۸')),
                          DropdownMenuItem(value: 96, child: Text('۹۶')),
                        ],
                        onChanged: (v) => _onPerPageChanged(v!),
                        isDense: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // لیست
          Expanded(
            child: mediaAsync.when(
              loading: () => const AppLoading(),
              error: (err, _) => Center(
                child: AppErrorState(
                  title: 'خطا در دریافت رسانه‌ها',
                  subtitle: err.toString(),
                  onRetry: () {
                    ref.invalidate(mediaProvider);
                    ref.invalidate(mediaTotalCountProvider);
                  },
                ),
              ),
              data: (items) {
                final filtered = _applyClientFilters(items);

                if (filtered.isEmpty) {
                  return AppEmptyState(
                    icon: Icons.photo_library_outlined,
                    title: 'رسانه‌ای یافت نشد',
                    subtitle: 'با تغییر فیلترها یا جستجو مجدد امتحان کنید.',
                  );
                }

                if (viewMode == 'list') {
                  return ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: MediaCard(
                          item: item,
                          onTap: () => context.go('/media/${item.id}'),
                          onCopyLink: () => _copyLink(item.url),
                          onEdit: () => context.go('/media/${item.id}/edit'),
                          onDelete: () => _showDeleteDialog(item),
                        ),
                      );
                    },
                  );
                } else {
                  final crossAxisCount = isTablet ? 3 : 2;
                  return GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      return MediaCard(
                        item: item,
                        isGrid: true,
                        onTap: () => context.go('/media/${item.id}'),
                        onCopyLink: () => _copyLink(item.url),
                        onEdit: () => context.go('/media/${item.id}/edit'),
                        onDelete: () => _showDeleteDialog(item),
                      );
                    },
                  );
                }
              },
            ),
          ),

          // صفحه‌بندی
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            color: AppTheme.surface,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () {
                    ref.read(mediaPageProvider.notifier).state++;
                    ref.invalidate(mediaProvider);
                  },
                  icon: const Icon(Icons.chevron_left),
                  splashRadius: 20,
                ),
                Text(
                  'صفحه ${_toFa(currentPage)}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: currentPage > 1
                      ? () {
                          ref.read(mediaPageProvider.notifier).state--;
                          ref.invalidate(mediaProvider);
                        }
                      : null,
                  icon: const Icon(Icons.chevron_right),
                  splashRadius: 20,
                ),
              ],
            ),
          ),
        ],
      ),
    );
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