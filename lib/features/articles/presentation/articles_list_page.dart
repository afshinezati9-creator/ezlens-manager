// lib/features/articles/presentation/articles_list_page.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../data/article_models.dart';
import 'articles_provider.dart';

// ============================================================
//  ویجت نمایش وضعیت مقاله
// ============================================================
class _StatusBadge extends StatelessWidget {
  final ArticleStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    String label;
    Color bgColor;
    Color textColor;
    IconData icon;

    switch (status) {
      case ArticleStatus.publish:
        label = 'منتشر شده';
        bgColor = const Color(0xFFDCFCE7);
        textColor = const Color(0xFF166534);
        icon = Icons.check_circle_outline;
        break;
      case ArticleStatus.draft:
        label = 'پیش‌نویس';
        bgColor = const Color(0xFFFEF9C3);
        textColor = const Color(0xFF854D0E);
        icon = Icons.edit_note_outlined;
        break;
      case ArticleStatus.pending:
        label = 'در انتظار';
        bgColor = const Color(0xFFFEF3C7);
        textColor = const Color(0xFF92400E);
        icon = Icons.schedule_outlined;
        break;
      case ArticleStatus.private:
        label = 'خصوصی';
        bgColor = const Color(0xFFE0E7FF);
        textColor = const Color(0xFF3730A3);
        icon = Icons.lock_outline;
        break;
      case ArticleStatus.trash:
        label = 'زباله‌دان';
        bgColor = const Color(0xFFFEE2E2);
        textColor = const Color(0xFF991B1B);
        icon = Icons.delete_outline;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
//  ویجت آیکون دکمه‌ای (M3 style)
// ============================================================
class _IconAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback? onTap;
  final bool isLoading;

  const _IconAction({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withOpacity(0.15)),
            ),
            child: isLoading
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: color,
                    ),
                  )
                : Icon(icon, size: 17, color: color),
          ),
        ),
      ),
    );
  }
}

// ============================================================
//  کارت مقاله
// ============================================================
class _ArticleCard extends StatelessWidget {
  final Article article;
  final VoidCallback onDelete;
  final VoidCallback onView;
  final bool isDeleting;

  const _ArticleCard({
    required this.article,
    required this.onDelete,
    required this.onView,
    required this.isDeleting,
  });

  String _formatDate(DateTime? date) {
    if (date == null) return 'تاریخ نامشخص';
    final persianMonths = [
      'فروردین', 'اردیبهشت', 'خرداد', 'تیر', 'مرداد', 'شهریور',
      'مهر', 'آبان', 'آذر', 'دی', 'بهمن', 'اسفند'
    ];
    return '${date.day} ${persianMonths[date.month - 1]} ${date.year}';
  }

  String _getCategoryNames() {
    if (article.categories.isEmpty) return 'بدون دسته';
    return article.categories.map((c) => c.name).join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () => context.go('/articles/${article.id}/edit'),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ===== تصویر شاخص =====
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 76,
                    height: 76,
                    color: AppTheme.background,
                    child: article.featuredImage != null &&
                            article.featuredImage!.src.isNotEmpty
                        ? Image.network(
                            article.featuredImage!.src,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.image_outlined,
                              size: 28,
                              color: AppTheme.textSecondary,
                            ),
                          )
                        : const Icon(
                            Icons.image_outlined,
                            size: 28,
                            color: AppTheme.textSecondary,
                          ),
                  ),
                ),
                const SizedBox(width: 12),

                // ===== اطلاعات =====
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // عنوان + بج وضعیت
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              article.title,
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                                height: 1.5,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _StatusBadge(status: article.status),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // دسته‌بندی
                      Text(
                        _getCategoryNames(),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),

                      // تاریخ + بازدید + دکمه‌ها
                      Row(
                        children: [
                          // تاریخ
                          Icon(
                            Icons.schedule_outlined,
                            size: 13,
                            color: AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            _formatDate(article.date),
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          // بازدید
                          const Icon(
                            Icons.visibility_outlined,
                            size: 13,
                            color: AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${article.views}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const Spacer(),

                          // دکمه‌ها
                          _IconAction(
                            icon: Icons.open_in_new,
                            tooltip: 'مشاهده در سایت',
                            color: AppTheme.primary,
                            onTap: onView,
                          ),
                          const SizedBox(width: 6),
                          _IconAction(
                            icon: Icons.edit_outlined,
                            tooltip: 'ویرایش',
                            color: const Color(0xFF0F766E),
                            onTap: () =>
                                context.go('/articles/${article.id}/edit'),
                          ),
                          const SizedBox(width: 6),
                          _IconAction(
                            icon: Icons.delete_outline,
                            tooltip: 'حذف',
                            color: AppTheme.danger,
                            onTap: isDeleting ? null : onDelete,
                            isLoading: isDeleting,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
//  صفحه اصلی لیست مقالات
// ============================================================
class ArticlesListPage extends ConsumerStatefulWidget {
  const ArticlesListPage({super.key});

  @override
  ConsumerState<ArticlesListPage> createState() => _ArticlesListPageState();
}

class _ArticlesListPageState extends ConsumerState<ArticlesListPage> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _dateFromController = TextEditingController();
  final TextEditingController _dateToController = TextEditingController();
  Timer? _debounce;
  int? _deletingArticleId;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _dateFromController.dispose();
    _dateToController.dispose();
    super.dispose();
  }

  // ===== مشاهده مقاله در سایت =====
  Future<void> _viewOnSite(Article article) async {
    if (article.permalink.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لینک مقاله موجود نیست')),
        );
      }
      return;
    }

    final uri = Uri.tryParse(article.permalink);
    if (uri == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لینک نامعتبر است')),
        );
      }
      return;
    }

    try {
      final ok = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('باز کردن لینک ناموفق بود')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا: $e')),
        );
      }
    }
  }

  // ===== جستجو =====
  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      ref.read(articlesSearchProvider.notifier).state = value;
      ref.read(articlesPageProvider.notifier).state = 1;
      ref.invalidate(articlesProvider);
      ref.invalidate(articlesTotalProvider);
    });
  }

  // ===== فیلترها =====
  void _onCategoryFilterChanged(int? value) {
    ref.read(articlesCategoryFilterProvider.notifier).state = value;
    ref.read(articlesPageProvider.notifier).state = 1;
    ref.invalidate(articlesProvider);
    ref.invalidate(articlesTotalProvider);
  }

  void _onStatusFilterChanged(String? value) {
    ref.read(articlesStatusFilterProvider.notifier).state = value;
    ref.read(articlesPageProvider.notifier).state = 1;
    ref.invalidate(articlesProvider);
    ref.invalidate(articlesTotalProvider);
  }

  void _onSortChanged(String? value) {
    if (value != null) {
      ref.read(articlesSortProvider.notifier).state = value;
      ref.read(articlesPageProvider.notifier).state = 1;
      ref.invalidate(articlesProvider);
      ref.invalidate(articlesTotalProvider);
    }
  }

  void _onPerPageChanged(int value) {
    ref.read(articlesPerPageProvider.notifier).state = value;
    ref.read(articlesPageProvider.notifier).state = 1;
    ref.invalidate(articlesProvider);
    ref.invalidate(articlesTotalProvider);
  }

  // ===== مودال فیلتر تاریخ =====
  void _showDateFilterModal() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('فیلتر تاریخ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _dateFromController,
              decoration: const InputDecoration(
                labelText: 'از تاریخ',
                hintText: '1404/01/01',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _dateToController,
              decoration: const InputDecoration(
                labelText: 'تا تاریخ',
                hintText: '1404/12/29',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _dateFromController.clear();
              _dateToController.clear();
              ref.read(articlesDateFromProvider.notifier).state = '';
              ref.read(articlesDateToProvider.notifier).state = '';
              ref.read(articlesPageProvider.notifier).state = 1;
              ref.invalidate(articlesProvider);
              ref.invalidate(articlesTotalProvider);
              Navigator.pop(ctx);
            },
            child: const Text('پاک کردن'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(articlesDateFromProvider.notifier).state =
                  _dateFromController.text;
              ref.read(articlesDateToProvider.notifier).state =
                  _dateToController.text;
              ref.read(articlesPageProvider.notifier).state = 1;
              ref.invalidate(articlesProvider);
              ref.invalidate(articlesTotalProvider);
              Navigator.pop(ctx);
            },
            child: const Text('اعمال'),
          ),
        ],
      ),
    );
  }

  // ===== حذف =====
  Future<void> _confirmDelete(Article article) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف مقاله'),
        content: Text('آیا از حذف «${article.title}» مطمئن هستید؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('انصراف'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'حذف',
              style: TextStyle(color: AppTheme.danger),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _deletingArticleId = article.id);
    final repo = ref.read(articleRepositoryProvider);

    try {
      await repo.deleteArticle(article.id);
      ref.invalidate(articlesProvider);
      ref.invalidate(articlesTotalProvider);

      final currentPage = ref.read(articlesPageProvider);
      final total = await ref.read(articlesTotalProvider.future);
      final perPage = ref.read(articlesPerPageProvider);

      if (total % perPage == 1 && currentPage > 1) {
        ref.read(articlesPageProvider.notifier).state = currentPage - 1;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('مقاله حذف شد')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در حذف: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _deletingArticleId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final articlesAsync = ref.watch(articlesProvider);
    final totalAsync = ref.watch(articlesTotalProvider);
    final categoriesAsync = ref.watch(articleCategoriesProvider);
    final currentPage = ref.watch(articlesPageProvider);
    final perPage = ref.watch(articlesPerPageProvider);
    final currentSearch = ref.watch(articlesSearchProvider);
    final currentCategoryFilter = ref.watch(articlesCategoryFilterProvider);
    final currentStatusFilter = ref.watch(articlesStatusFilterProvider);
    final currentSort = ref.watch(articlesSortProvider);
    final currentDateFrom = ref.watch(articlesDateFromProvider);
    final currentDateTo = ref.watch(articlesDateToProvider);

    if (_searchController.text != currentSearch) {
      _searchController.text = currentSearch;
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('مقالات'),
        centerTitle: true,
        backgroundColor: AppTheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppTheme.primary),
            onPressed: () => context.go('/articles/new'),
            tooltip: 'مقاله جدید',
          ),
        ],
      ),
      body: Column(
        children: [
          // ===== فیلترها =====
          Container(
            color: AppTheme.surface,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  textDirection: TextDirection.rtl,
                  decoration: InputDecoration(
                    hintText: 'جستجوی مقاله...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.border),
                    ),
                    filled: true,
                    fillColor: AppTheme.background,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  ),
                ),
                const SizedBox(height: 10),

                // دسته‌بندی + وضعیت
                Row(
                  children: [
                    Expanded(
                      child: categoriesAsync.when(
                        data: (categories) {
                          return DropdownButtonFormField<int?>(
                            value: currentCategoryFilter,
                            isExpanded: true,
                            decoration: InputDecoration(
                              hintText: 'دسته‌بندی',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              isDense: true,
                            ),
                            items: [
                              const DropdownMenuItem<int?>(
                                value: null,
                                child: Text('همه دسته‌ها'),
                              ),
                              ...categories.map(
                                (cat) => DropdownMenuItem<int?>(
                                  value: cat.id,
                                  child: Text(
                                    cat.name,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                            onChanged: _onCategoryFilterChanged,
                          );
                        },
                        loading: () => const SizedBox(
                          height: 40,
                          child: Center(
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        ),
                        error: (_, __) => const SizedBox(height: 40),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        value: currentStatusFilter,
                        isExpanded: true,
                        decoration: InputDecoration(
                          hintText: 'وضعیت',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          isDense: true,
                        ),
                        items: const [
                          DropdownMenuItem<String?>(
                            value: null,
                            child: Text('همه وضعیت‌ها'),
                          ),
                          DropdownMenuItem<String?>(
                            value: 'publish',
                            child: Text('منتشر شده'),
                          ),
                          DropdownMenuItem<String?>(
                            value: 'draft',
                            child: Text('پیش‌نویس'),
                          ),
                          DropdownMenuItem<String?>(
                            value: 'pending',
                            child: Text('در انتظار'),
                          ),
                          DropdownMenuItem<String?>(
                            value: 'private',
                            child: Text('خصوصی'),
                          ),
                        ],
                        onChanged: _onStatusFilterChanged,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // مرتب‌سازی + تاریخ
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: currentSort,
                        decoration: InputDecoration(
                          hintText: 'مرتب‌سازی',
                          prefixIcon: const Icon(Icons.sort, size: 18),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          isDense: true,
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: 'newest', child: Text('جدیدترین')),
                          DropdownMenuItem(
                              value: 'oldest', child: Text('قدیمی‌ترین')),
                          DropdownMenuItem(
                              value: 'views', child: Text('پربازدیدترین')),
                          DropdownMenuItem(
                              value: 'title', child: Text('حروف الفبا')),
                        ],
                        onChanged: _onSortChanged,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _showDateFilterModal,
                        icon: const Icon(Icons.date_range, size: 16),
                        label: Text(
                          (currentDateFrom.isNotEmpty ||
                                  currentDateTo.isNotEmpty)
                              ? 'تاریخ فعال'
                              : 'فیلتر تاریخ',
                          style: const TextStyle(fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                        style: OutlinedButton.styleFrom(
                          padding:
                              const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          side: BorderSide(
                            color: (currentDateFrom.isNotEmpty ||
                                    currentDateTo.isNotEmpty)
                                ? AppTheme.primary
                                : AppTheme.border,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // تعداد در صفحه
                Row(
                  children: [
                    const Text(
                      'نمایش:',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: perPage,
                        isExpanded: true,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          isDense: true,
                        ),
                        items: const [
                          DropdownMenuItem(value: 5, child: Text('۵ مورد')),
                          DropdownMenuItem(value: 10, child: Text('۱۰ مورد')),
                          DropdownMenuItem(value: 20, child: Text('۲۰ مورد')),
                          DropdownMenuItem(value: 50, child: Text('۵۰ مورد')),
                          DropdownMenuItem(value: 100, child: Text('۱۰۰ مورد')),
                        ],
                        onChanged: (value) {
                          if (value != null) _onPerPageChanged(value);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ===== لیست مقالات =====
          Expanded(
            child: articlesAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppTheme.primary),
              ),
              error: (error, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: AppTheme.danger,
                        size: 44,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'خطا در دریافت مقالات\n$error',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          ref.invalidate(articlesProvider);
                          ref.invalidate(articlesTotalProvider);
                        },
                        child: const Text('تلاش مجدد'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (articles) {
                if (articles.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.inbox_outlined,
                          size: 56,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'هیچ مقاله‌ای یافت نشد',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(articlesProvider);
                    ref.invalidate(articlesTotalProvider);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                    itemCount: articles.length,
                    itemBuilder: (context, index) {
                      final article = articles[index];
                      return _ArticleCard(
                        article: article,
                        isDeleting: _deletingArticleId == article.id,
                        onDelete: () => _confirmDelete(article),
                        onView: () => _viewOnSite(article),
                      );
                    },
                  ),
                );
              },
            ),
          ),

          // ===== صفحه‌بندی =====
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            color: AppTheme.surface,
            child: totalAsync.when(
              data: (total) {
                if (total <= 0) return const SizedBox.shrink();
                final totalPages = (total / perPage).ceil();
                if (totalPages <= 1) return const SizedBox.shrink();
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: currentPage > 1
                          ? () {
                              ref.read(articlesPageProvider.notifier).state--;
                              ref.invalidate(articlesProvider);
                            }
                          : null,
                      icon: const Icon(Icons.chevron_left),
                      tooltip: 'صفحه قبل',
                    ),
                    Text(
                      '$currentPage / $totalPages',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    IconButton(
                      onPressed: currentPage < totalPages
                          ? () {
                              ref.read(articlesPageProvider.notifier).state++;
                              ref.invalidate(articlesProvider);
                            }
                          : null,
                      icon: const Icon(Icons.chevron_right),
                      tooltip: 'صفحه بعد',
                    ),
                  ],
                );
              },
              loading: () => const SizedBox(height: 40),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }
}