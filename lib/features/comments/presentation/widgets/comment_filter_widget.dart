// lib/features/comments/presentation/widgets/comment_filter_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import 'package:ezlens_manager/core/theme/app_theme.dart';
import '../comment_provider.dart';

class CommentFilterWidget extends ConsumerStatefulWidget {
  final TextEditingController searchController;
  final VoidCallback onSearchChanged;

  const CommentFilterWidget({
    super.key,
    required this.searchController,
    required this.onSearchChanged,
  });

  @override
  ConsumerState<CommentFilterWidget> createState() => _CommentFilterWidgetState();
}

class _CommentFilterWidgetState extends ConsumerState<CommentFilterWidget> {
  DateTime? _dateFrom;
  DateTime? _dateTo;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final perPage = ref.watch(commentsPerPageProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          // ===== ردیف اول: جستجو و وضعیت =====
          isMobile
              ? Column(
                  children: [
                    _buildSearchField(),
                    const SizedBox(height: 10),
                    _buildStatusDropdown(),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 2, child: _buildSearchField()),
                    const SizedBox(width: 10),
                    Expanded(child: _buildStatusDropdown()),
                  ],
                ),
          const SizedBox(height: 10),

          // ===== ردیف دوم: نوع پست، نویسنده، تاریخ =====
          isMobile
              ? Column(
                  children: [
                    _buildPostTypeDropdown(),
                    const SizedBox(height: 10),
                    _buildAuthorField(),
                    const SizedBox(height: 10),
                    _buildDateButton(),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildPostTypeDropdown()),
                    const SizedBox(width: 10),
                    Expanded(child: _buildAuthorField()),
                    const SizedBox(width: 10),
                    Expanded(child: _buildDateButton()),
                  ],
                ),
          const SizedBox(height: 10),

          // ===== ردیف سوم: تعداد در صفحه =====
          Row(
            children: [
              const Text('تعداد در صفحه:', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
              const SizedBox(width: 8),
              DropdownButton<int>(
                value: perPage,
                items: const [
                  DropdownMenuItem(value: 5, child: Text('۵')),
                  DropdownMenuItem(value: 10, child: Text('۱۰')),
                  DropdownMenuItem(value: 20, child: Text('۲۰')),
                  DropdownMenuItem(value: 50, child: Text('۵۰')),
                ],
                onChanged: (v) {
                  if (v != null) {
                    ref.read(commentsPerPageProvider.notifier).state = v;
                    ref.read(commentsPageProvider.notifier).state = 1;
                    ref.invalidate(commentsProvider);
                    ref.invalidate(commentsTotalCountProvider);
                  }
                },
                underline: const SizedBox(),
              ),
              const Spacer(),
              Text(
                'تعداد کل: ${_formatNumber(ref.watch(commentsTotalCountProvider).value ?? 0)}',
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatNumber(int value) {
    return value.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: widget.searchController,
      onChanged: (_) => widget.onSearchChanged(),
      decoration: InputDecoration(
        hintText: 'جستجو در نظرات...',
        prefixIcon: const Icon(Icons.search, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.border),
        ),
        filled: true,
        fillColor: AppTheme.background,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        isDense: false,
      ),
      textDirection: TextDirection.rtl,
    );
  }

  Widget _buildStatusDropdown() {
    return DropdownButtonFormField<String?>(
      value: ref.watch(commentsStatusProvider),
      decoration: InputDecoration(
        labelText: 'وضعیت',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.border),
        ),
        filled: true,
        fillColor: AppTheme.background,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        isDense: false,
      ),
      items: const [
        DropdownMenuItem(value: 'any', child: Text('همه')),
        DropdownMenuItem(value: 'approved', child: Text('تأیید شده')),
        DropdownMenuItem(value: 'pending', child: Text('در انتظار')),
        DropdownMenuItem(value: 'spam', child: Text('اسپم')),
        DropdownMenuItem(value: 'trash', child: Text('حذف شده')),
      ],
      onChanged: (value) {
        ref.read(commentsStatusProvider.notifier).state = value;
        ref.read(commentsPageProvider.notifier).state = 1;
        ref.invalidate(commentsProvider);
        ref.invalidate(commentsTotalCountProvider);
      },
    );
  }

  Widget _buildPostTypeDropdown() {
    return DropdownButtonFormField<String?>(
      value: ref.watch(commentsPostTypeProvider),
      decoration: InputDecoration(
        labelText: 'نوع پست',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.border),
        ),
        filled: true,
        fillColor: AppTheme.background,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        isDense: false,
      ),
      items: const [
        DropdownMenuItem(value: null, child: Text('همه')),
        DropdownMenuItem(value: 'product', child: Text('محصولات')),
        DropdownMenuItem(value: 'post', child: Text('نوشته‌ها')),
        DropdownMenuItem(value: 'page', child: Text('برگه‌ها')),
      ],
      onChanged: (value) {
        ref.read(commentsPostTypeProvider.notifier).state = value;
        ref.read(commentsPageProvider.notifier).state = 1;
        ref.invalidate(commentsProvider);
      },
    );
  }

  Widget _buildAuthorField() {
    return TextFormField(
      decoration: InputDecoration(
        labelText: 'شناسه نویسنده',
        hintText: 'مثلاً ۱ برای مدیر',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.border),
        ),
        filled: true,
        fillColor: AppTheme.background,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        isDense: false,
      ),
      keyboardType: TextInputType.number,
      onFieldSubmitted: (value) {
        final id = int.tryParse(value);
        ref.read(commentsAuthorIdProvider.notifier).state = id;
        ref.read(commentsPageProvider.notifier).state = 1;
        ref.invalidate(commentsProvider);
        ref.invalidate(commentsTotalCountProvider);
      },
    );
  }

  Widget _buildDateButton() {
    return GestureDetector(
      onTap: _selectDateRange,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.border),
          borderRadius: BorderRadius.circular(12),
          color: AppTheme.background,
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_outlined, size: 16, color: AppTheme.primary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                _getDateRangeLabel(),
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (_dateFrom != null || _dateTo != null)
              GestureDetector(
                onTap: _clearDateFilter,
                child: Icon(Icons.close, size: 16, color: AppTheme.danger),
              ),
          ],
        ),
      ),
    );
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
      ref.read(commentsDateFromProvider.notifier).state = _dateFrom;
      ref.read(commentsDateToProvider.notifier).state = _dateTo;
      ref.read(commentsPageProvider.notifier).state = 1;
      ref.invalidate(commentsProvider);
      ref.invalidate(commentsTotalCountProvider);
    }
  }

  void _clearDateFilter() {
    setState(() {
      _dateFrom = null;
      _dateTo = null;
    });
    ref.read(commentsDateFromProvider.notifier).state = null;
    ref.read(commentsDateToProvider.notifier).state = null;
    ref.read(commentsPageProvider.notifier).state = 1;
    ref.invalidate(commentsProvider);
    ref.invalidate(commentsTotalCountProvider);
  }

  String _getDateRangeLabel() {
    if (_dateFrom == null && _dateTo == null) return 'همه تاریخ';
    final start = _dateFrom != null ? _toPersianDate(_dateFrom!) : 'نامشخص';
    final end = _dateTo != null ? _toPersianDate(_dateTo!) : 'نامشخص';
    return '$start تا $end';
  }

  String _toPersianDate(DateTime date) {
    final jalali = Jalali.fromDateTime(date);
    return '${jalali.year}/${jalali.month.toString().padLeft(2, '0')}/${jalali.day.toString().padLeft(2, '0')}';
  }
}