// lib/features/articles/presentation/article_form_page.dart

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/network/providers.dart';
import '../../product_features/presentation/widgets/unified_code_editor.dart';
import '../data/article_models.dart';
import '../data/article_repository.dart';
import 'articles_provider.dart';

// ============================================================
//  ویجت تحلیل سئو
// ============================================================
class SeoAnalyzerWidget extends StatelessWidget {
  final String title;
  final String description;
  final String keywords;
  final String slug;

  const SeoAnalyzerWidget({
    super.key,
    required this.title,
    required this.description,
    required this.keywords,
    required this.slug,
  });

  int _calculateScore() {
    int score = 100;
    final cleanTitle = title.replaceAll(RegExp(r'%[^%]+%'), '');
    final cleanDesc = description.replaceAll(RegExp(r'%[^%]+%'), '');

    if (cleanTitle.length < 30) {
      score -= 15;
    } else if (cleanTitle.length > 60) {
      score -= 10;
    }

    if (cleanDesc.length < 120) {
      score -= 15;
    } else if (cleanDesc.length > 160) {
      score -= 10;
    }

    if (keywords.trim().isNotEmpty) {
      if (!title.toLowerCase().contains(keywords.toLowerCase())) {
        score -= 20;
      }
      if (!description.toLowerCase().contains(keywords.toLowerCase())) {
        score -= 15;
      }
    } else {
      score -= 25;
    }

    if (slug.trim().isEmpty) {
      score -= 10;
    } else if (!slug.contains('-')) {
      score -= 5;
    }

    return score.clamp(0, 100);
  }

  List<String> _getIssues() {
    final issues = <String>[];
    final cleanTitle = title.replaceAll(RegExp(r'%[^%]+%'), '');
    final cleanDesc = description.replaceAll(RegExp(r'%[^%]+%'), '');

    if (cleanTitle.length < 30) {
      issues.add('⚠️ عنوان کوتاه است (${cleanTitle.length}/۳۰ کاراکتر)');
    } else if (cleanTitle.length > 60) {
      issues.add('⚠️ عنوان بلند است (${cleanTitle.length}/۶۰ کاراکتر)');
    } else if (cleanTitle.isNotEmpty) {
      issues.add('✅ طول عنوان مناسب است');
    }

    if (cleanDesc.length < 120) {
      issues.add('⚠️ توضیحات کوتاه است (${cleanDesc.length}/۱۲۰ کاراکتر)');
    } else if (cleanDesc.length > 160) {
      issues.add('⚠️ توضیحات بلند است (${cleanDesc.length}/۱۶۰ کاراکتر)');
    } else if (cleanDesc.isNotEmpty) {
      issues.add('✅ طول توضیحات مناسب است');
    }

    if (keywords.trim().isNotEmpty) {
      if (title.toLowerCase().contains(keywords.toLowerCase())) {
        issues.add('✅ کلمه کلیدی در عنوان وجود دارد');
      } else {
        issues.add('⚠️ کلمه کلیدی در عنوان وجود ندارد');
      }
      if (description.toLowerCase().contains(keywords.toLowerCase())) {
        issues.add('✅ کلمه کلیدی در توضیحات وجود دارد');
      } else {
        issues.add('⚠️ کلمه کلیدی در توضیحات وجود ندارد');
      }
    } else {
      issues.add('⚠️ کلمه کلیدی مشخص نشده است');
    }

    if (slug.trim().isEmpty) {
      issues.add('⚠️ پیوند یکتا مشخص نشده است');
    } else if (slug.contains('-')) {
      issues.add('✅ پیوند یکتا از کلمات معنادار تشکیل شده');
    }

    return issues;
  }

  @override
  Widget build(BuildContext context) {
    final score = _calculateScore();
    final issues = _getIssues();
    Color statusColor;
    String statusText;

    if (score >= 85) {
      statusColor = AppColors.success;
      statusText = 'عالی';
    } else if (score >= 70) {
      statusColor = AppColors.primary;
      statusText = 'خوب';
    } else if (score >= 50) {
      statusColor = Colors.orange;
      statusText = 'متوسط';
    } else {
      statusColor = AppColors.danger;
      statusText = 'ضعیف';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '📊 تحلیل سئو',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '$score%',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: score / 100,
              backgroundColor: AppColors.border,
              color: statusColor,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 12),
          ...issues.map(
            (issue) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Text(
                    issue.startsWith('✅') ? '✅' : '⚠️',
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      issue.substring(2),
                      style: TextStyle(
                        fontSize: 12,
                        color: issue.startsWith('✅')
                            ? AppColors.success
                            : AppColors.danger,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Divider(),
          const Text(
            '🔍 پیش‌نمایش نتایج جستجو',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.isNotEmpty ? title : 'عنوان سئو',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  slug.isNotEmpty
                      ? 'https://ezlens.ir/$slug'
                      : 'https://ezlens.ir/...',
                  style: const TextStyle(fontSize: 12, color: Colors.green),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  description.isNotEmpty ? description : 'توضیحات سئو',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
//  ویجت درخت دسته‌بندی
// ============================================================
class CategoryTreeWidget extends ConsumerStatefulWidget {
  final List<ArticleCategory> categories;
  final List<int> selectedIds;
  final Function(List<int>) onChanged;

  const CategoryTreeWidget({
    super.key,
    required this.categories,
    required this.selectedIds,
    required this.onChanged,
  });

  @override
  ConsumerState<CategoryTreeWidget> createState() => _CategoryTreeWidgetState();
}

class _CategoryTreeWidgetState extends ConsumerState<CategoryTreeWidget> {
  late List<int> _selectedIds;
  final TextEditingController _newCatController = TextEditingController();
  int? _newCatParentId;
  bool _showAddForm = false;

  @override
  void initState() {
    super.initState();
    _selectedIds = List.from(widget.selectedIds);
  }

  @override
  void didUpdateWidget(CategoryTreeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIds != widget.selectedIds) {
      _selectedIds = List.from(widget.selectedIds);
    }
  }

  List<Map<String, dynamic>> _buildTree(
    List<ArticleCategory> cats, {
    int parentId = 0,
  }) {
    return cats
        .where((c) => (c.parent ?? 0) == parentId)
        .map((c) => {
              'category': c,
              'children': _buildTree(cats, parentId: c.id),
            })
        .toList();
  }

  Widget _buildTreeWidget(List<Map<String, dynamic>> nodes, int depth) {
    if (nodes.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: Text('زیرمجموعه‌ای وجود ندارد')),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: nodes.map((node) {
        final cat = node['category'] as ArticleCategory;
        final children = node['children'] as List<Map<String, dynamic>>;
        final isChecked = _selectedIds.contains(cat.id);
        final hasChildren = children.isNotEmpty;

        return Padding(
          padding: EdgeInsets.only(right: depth * 16.0),
          child: hasChildren
              ? ExpansionTile(
                  title: Row(
                    children: [
                      Checkbox(
                        value: isChecked,
                        onChanged: (val) {
                          setState(() {
                            if (val == true) {
                              _selectedIds.add(cat.id);
                            } else {
                              _selectedIds.remove(cat.id);
                            }
                          });
                          widget.onChanged(_selectedIds);
                          ref
                              .read(selectedCategoriesProvider.notifier)
                              .state = _selectedIds;
                        },
                      ),
                      Expanded(child: Text(cat.name)),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: AppColors.danger,
                          size: 16,
                        ),
                        onPressed: () => _deleteCategory(cat.id),
                        tooltip: 'حذف دسته',
                      ),
                    ],
                  ),
                  children: [_buildTreeWidget(children, depth + 1)],
                  initiallyExpanded: true,
                )
              : Row(
                  children: [
                    Checkbox(
                      value: isChecked,
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            _selectedIds.add(cat.id);
                          } else {
                            _selectedIds.remove(cat.id);
                          }
                        });
                        widget.onChanged(_selectedIds);
                        ref
                            .read(selectedCategoriesProvider.notifier)
                            .state = _selectedIds;
                      },
                    ),
                    Expanded(child: Text(cat.name)),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: AppColors.danger,
                        size: 16,
                      ),
                      onPressed: () => _deleteCategory(cat.id),
                      tooltip: 'حذف دسته',
                    ),
                  ],
                ),
        );
      }).toList(),
    );
  }

  Future<void> _deleteCategory(int id) async {
    final repo = ref.read(articleRepositoryProvider);
    try {
      await repo.deleteCategory(id);
      ref.invalidate(articleCategoriesProvider);
      _selectedIds.remove(id);
      widget.onChanged(_selectedIds);
      ref.read(selectedCategoriesProvider.notifier).state = _selectedIds;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('دسته حذف شد')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در حذف: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tree = _buildTree(widget.categories);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: _buildTreeWidget(tree, 0),
          ),
        ),
        const Divider(),
        if (!_showAddForm)
          TextButton.icon(
            onPressed: () => setState(() => _showAddForm = true),
            icon: const Icon(Icons.add_circle_outline, size: 18),
            label: const Text('افزودن دسته جدید'),
          )
        else
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _newCatController,
                        decoration: const InputDecoration(
                          labelText: 'نام دسته',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: DropdownButtonFormField<int?>(
                        isExpanded: true,
                        initialValue: _newCatParentId,
                        decoration: const InputDecoration(
                          labelText: 'والد',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text(
                              'بدون والد',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          ...widget.categories.map(
                            (c) => DropdownMenuItem<int?>(
                              value: c.id,
                              child: Text(
                                c.name,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ),
                        ],
                        onChanged: (val) =>
                            setState(() => _newCatParentId = val),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _showAddForm = false;
                          _newCatController.clear();
                          _newCatParentId = null;
                        });
                      },
                      child: const Text('لغو'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () async {
                        if (_newCatController.text.trim().isEmpty) return;
                        final repo = ref.read(articleRepositoryProvider);
                        try {
                          final newCat = await repo.createCategory({
                            'name': _newCatController.text.trim(),
                            'parent': _newCatParentId ?? 0,
                          });
                          ref.invalidate(articleCategoriesProvider);
                          final newList = List<int>.from(_selectedIds)
                            ..add(newCat.id);
                          _selectedIds = newList;
                          widget.onChanged(newList);
                          ref
                              .read(selectedCategoriesProvider.notifier)
                              .state = newList;
                          setState(() {
                            _newCatController.clear();
                            _newCatParentId = null;
                            _showAddForm = false;
                          });
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('دسته جدید اضافه شد'),
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('خطا در افزودن دسته: $e'),
                              ),
                            );
                          }
                        }
                      },
                      child: const Text('افزودن'),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ============================================================
//  صفحه اصلی فرم مقاله
// ============================================================
class ArticleFormPage extends ConsumerStatefulWidget {
  final int? articleId;

  const ArticleFormPage({super.key, this.articleId});

  @override
  ConsumerState<ArticleFormPage> createState() => _ArticleFormPageState();
}

class _ArticleFormPageState extends ConsumerState<ArticleFormPage> {
  // کنترلرها
  final _titleController = TextEditingController();
  final _slugController = TextEditingController();
  final _excerptController = TextEditingController();
  final _seoTitleController = TextEditingController();
  final _seoDescController = TextEditingController();
  final _seoKeywordsController = TextEditingController();

  // وضعیت‌ها
  String _status = 'draft';
  bool _loading = true;
  bool _uploading = false;
  double _uploadProgress = 0; // 0..1
  bool _saving = false;
  String? _permalink;
  bool _catModalOpen = false;
  String? _errorMessage;

  // تصویر شاخص
  Uint8List? _featuredImageBytes;
  String? _featuredImageName;
  int? _featuredImageSize;
  FeaturedImage? _existingFeaturedImage;

  // کدها
  String _htmlCode = '';
  String _cssCode = '';
  String _jsCode = '';
  String _unifiedCode = '';
  final TextEditingController _codeController = TextEditingController();
  int _editorKey = 0;

  // موقت برای مودال
  List<int> _tempSelectedCategories = [];

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(selectedCategoriesProvider.notifier).state = [];
        _tempSelectedCategories = [];
      }
    });

    if (widget.articleId != null) {
      _loadArticle();
    } else {
      _loading = false;
      _htmlCode = '<!-- محتوای مقاله -->\n<p>متن مقاله...</p>\n';
      _cssCode = '/* styles */\n';
      _jsCode = '// scripts\n';
      _unifiedCode = UnifiedCodeEditor.combine(
        _htmlCode,
        _cssCode,
        _jsCode,
      );
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _titleController.dispose();
    _slugController.dispose();
    _excerptController.dispose();
    _seoTitleController.dispose();
    _seoDescController.dispose();
    _seoKeywordsController.dispose();
    super.dispose();
  }

  Future<void> _loadArticle() async {
    if (widget.articleId == null) return;

    setState(() => _loading = true);

    try {
      final article = await ref.read(
        articleDetailProvider(widget.articleId!).future,
      );
      if (!mounted) return;

      final categoryIds = article.categories.map((c) => c.id).toList();

      if (categoryIds.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ref.read(selectedCategoriesProvider.notifier).state = categoryIds;
            _tempSelectedCategories = categoryIds;
          }
        });
      }

      final rawContent = article.content;
      final parts = ArticleRepository.parsePersistContent(rawContent);
      // Fallback to legacy meta if comment markers missing
      var finalHtml = parts[0].isNotEmpty ? parts[0] : '<p>متن مقاله...</p>\n';
      var finalCss = parts[1].isNotEmpty
          ? parts[1]
          : (article.descriptionCss.isNotEmpty
              ? article.descriptionCss
              : '/* styles */\n');
      var finalJs = parts[2].isNotEmpty
          ? parts[2]
          : (article.descriptionJs.isNotEmpty
              ? article.descriptionJs
              : '// scripts\n');

      setState(() {
        _titleController.text = article.title;
        _slugController.text = article.slug;
        _status = article.status.string;
        _excerptController.text = article.excerpt ?? '';

        _htmlCode = finalHtml;
        _cssCode = finalCss;
        _jsCode = finalJs;
        _editorKey++;
        _unifiedCode = UnifiedCodeEditor.combine(
          _htmlCode,
          _cssCode,
          _jsCode,
        );
        _codeController.text = _unifiedCode;

        _seoTitleController.text = article.seoTitle;
        _seoDescController.text = article.seoDescription;
        _seoKeywordsController.text = article.seoKeywords;
        _permalink = article.permalink;

        if (article.featuredImage != null) {
          _existingFeaturedImage = article.featuredImage;
        }

        _tempSelectedCategories = categoryIds;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در دریافت مقاله: $e')),
        );
      }
    }
  }

  Future<void> _pickFeaturedImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      final size = await pickedFile.length();
      setState(() {
        _featuredImageBytes = bytes;
        _featuredImageName = pickedFile.name;
        _featuredImageSize = size;
        _existingFeaturedImage = null;
      });
    }
  }

  void _removeFeaturedImage() {
    setState(() {
      _featuredImageBytes = null;
      _featuredImageName = null;
      _featuredImageSize = null;
      _existingFeaturedImage = null;
    });
  }

  Future<int> _uploadImage(Uint8List bytes, String fileName) async {
    final apiClient = ref.read(apiClientProvider);
    // Web-safe: MultipartFile.fromBytes (File temp path fails on Chrome)
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: fileName),
    });
    setState(() {
      _uploading = true;
      _uploadProgress = 0;
    });
    try {
      final response = await apiClient.uploadMedia(
        '/wp-json/wp/v2/media',
        formData: formData,
        onSendProgress: (sent, total) {
          if (!mounted) return;
          if (total > 0) {
            setState(() => _uploadProgress = sent / total);
          }
        },
      );
      final data = response.data;
      final id = data is Map ? int.tryParse('${data['id']}') : null;
      if (id == null || id <= 0) {
        throw Exception('آپلود تصویر ناموفق بود');
      }
      return id;
    } finally {
      if (mounted) {
        setState(() {
          _uploading = false;
          _uploadProgress = 0;
        });
      }
    }
  }

  // ============================================================
  //  ذخیره مقاله
  // ============================================================
  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('عنوان مقاله الزامی است')),
        );
      }
      return;
    }

    setState(() {
      _saving = true;
      _errorMessage = null;
    });

    final repo = ref.read(articleRepositoryProvider);
    final selectedCats = ref.read(selectedCategoriesProvider);

    try {
      // ===== استخراج HTML / CSS / JS (از controller واقعی ویرایشگر) =====
      final liveCode = _codeController.text.isNotEmpty
          ? _codeController.text
          : _unifiedCode;
      _unifiedCode = liveCode;
      final parts = UnifiedCodeEditor.split(liveCode);
      final cleanHtml = parts[0];
      final cleanCss = parts[1];
      final cleanJs = parts[2];

      _htmlCode = cleanHtml;
      _cssCode = cleanCss;
      _jsCode = cleanJs;

      // ===== ساخت payload =====
      final articleData = <String, dynamic>{
        'title': _titleController.text.trim(),
        if (_slugController.text.trim().isNotEmpty)
          'slug': _slugController.text.trim(),
        'status': _status,
        'excerpt': _excerptController.text.trim(),
        'content': cleanHtml,
        'categories': selectedCats,
        'tags': <int>[],
        'meta_data': [
          {
            'key': 'rank_math_title',
            'value': _seoTitleController.text.trim(),
          },
          {
            'key': 'rank_math_description',
            'value': _seoDescController.text.trim(),
          },
          {
            'key': 'rank_math_focus_keyword',
            'value': _seoKeywordsController.text.trim(),
          },
          {
            'key': 'ezlens_desc_css',
            'value': cleanCss,
          },
          {
            'key': 'ezlens_desc_js',
            'value': cleanJs,
          },
        ],
      };

      // ===== آپلود تصویر =====
      if (_featuredImageBytes != null) {
        final imageId =
            await _uploadImage(_featuredImageBytes!, _featuredImageName!);
        articleData['featured_media'] = imageId;
      } else if (_existingFeaturedImage != null) {
        articleData['featured_media'] = _existingFeaturedImage!.id;
      }

      // Guard: refuse empty body on update (protects Elementor / existing posts)
      if (widget.articleId != null &&
          cleanHtml.trim().isEmpty &&
          cleanCss.trim().isEmpty &&
          cleanJs.trim().isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'محتوای ویرایشگر خالی است — ذخیره نشد تا مقاله پاک نشود',
              ),
              backgroundColor: AppColors.danger,
            ),
          );
        }
        return;
      }

      // ===== ذخیره (ماندن در صفحه ویرایش + پیام AJAX) =====
      if (widget.articleId == null) {
        final newArticle = await repo.createArticle(articleData);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('مقاله با موفقیت ساخته شد'),
            backgroundColor: AppColors.success,
          ),
        );

        ref.invalidate(articlesProvider);
        ref.invalidate(articlesTotalProvider);
        ref.invalidate(articleDetailProvider(newArticle.id));

        // Stay in editor: open edit route for the new id
        if (mounted) {
          context.go('/articles/${newArticle.id}/edit');
        }
      } else {
        final updated = await repo.updateArticle(widget.articleId!, articleData);

        if (!mounted) return;

        // Sync editor from server response (raw content)
        final parsed = ArticleRepository.parsePersistContent(updated.content);
        setState(() {
          _titleController.text = updated.title;
          _slugController.text = updated.slug;
          _status = updated.status.string;
          _excerptController.text = updated.excerpt ?? '';
          _htmlCode = parsed[0];
          _cssCode = parsed[1];
          _jsCode = parsed[2];
          _unifiedCode = UnifiedCodeEditor.combine(
            _htmlCode,
            _cssCode,
            _jsCode,
          );
          _editorKey++;
          if (updated.featuredImage != null) {
            _existingFeaturedImage = updated.featuredImage;
            _featuredImageBytes = null;
            _featuredImageName = null;
            _featuredImageSize = null;
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تغییرات با موفقیت ذخیره شد'),
            backgroundColor: AppColors.success,
          ),
        );

        ref.invalidate(articlesProvider);
        ref.invalidate(articlesTotalProvider);
        ref.invalidate(articleDetailProvider(widget.articleId!));
      }
    } catch (e) {
      final msg = e.toString();
      if (mounted) {
        setState(() {
          if (msg.contains('401') || msg.contains('Unauthorized')) {
            _errorMessage = 'نام کاربری یا رمز عبور وردپرس نامعتبر است';
          } else if (msg.contains('403') || msg.contains('مجاز')) {
            _errorMessage =
                'شما دسترسی ویرایش مقاله را ندارید. لطفاً نقش کاربری را در وردپرس بررسی کنید.';
          } else if (msg.contains('404')) {
            _errorMessage = 'مقاله یافت نشد';
          } else {
            _errorMessage = 'خطا در ذخیره: $msg';
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage!),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ============================================================
  //  بخش‌های UI
  // ============================================================

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildSectionCard({required Widget child}) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }

  Widget _buildFeaturedImageSection() {
    return _buildSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('تصویر شاخص'),
          GestureDetector(
            onTap: _pickFeaturedImage,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: _featuredImageBytes != null
                          ? Image.memory(
                              _featuredImageBytes!,
                              fit: BoxFit.cover,
                            )
                          : _existingFeaturedImage != null
                              ? Image.network(
                                  _existingFeaturedImage!.src,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.broken_image,
                                    size: 60,
                                  ),
                                )
                              : Container(
                                  color: AppColors.background,
                                  child: const Icon(
                                    Icons.add_photo_alternate,
                                    size: 60,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_featuredImageName != null)
                                Text(
                                  _featuredImageName!,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              if (_featuredImageSize != null)
                                Text(
                                  'حجم: ${(_featuredImageSize! / 1024).toStringAsFixed(1)} KB',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              if (_existingFeaturedImage != null &&
                                  _featuredImageBytes == null)
                                const Text(
                                  'تصویر از سرور',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (_featuredImageBytes != null ||
                            _existingFeaturedImage != null)
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: AppColors.danger,
                              size: 20,
                            ),
                            onPressed: _removeFeaturedImage,
                            tooltip: 'حذف تصویر',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                      ],
                    ),
                  ),
                  if (_featuredImageBytes == null &&
                      _existingFeaturedImage == null)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          'برای انتخاب تصویر کلیک کنید',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (_uploading) ...[
            const SizedBox(height: 12),
            LinearProgressIndicator(
              minHeight: 4,
              value: _uploadProgress > 0 && _uploadProgress < 1
                  ? _uploadProgress
                  : null,
            ),
            const SizedBox(height: 4),
            Text(
              _uploadProgress > 0 && _uploadProgress < 1
                  ? 'در حال آپلود... ${(_uploadProgress * 100).toStringAsFixed(0)}٪'
                  : 'در حال آپلود...',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMainInfoSection() {
    return _buildSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('اطلاعات اصلی'),
          AppTextField(
            controller: _titleController,
            label: 'عنوان مقاله',
            hint: 'عنوان مقاله را وارد کنید',
          ),
          const SizedBox(height: 12),
          AppTextField(
            controller: _excerptController,
            label: 'خلاصه مقاله',
            hint: 'خلاصه کوتاه از مقاله',
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _status,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'وضعیت'),
                  items: const [
                    DropdownMenuItem(value: 'draft', child: Text('پیش‌نویس')),
                    DropdownMenuItem(
                      value: 'publish',
                      child: Text('منتشر شده'),
                    ),
                    DropdownMenuItem(
                      value: 'pending',
                      child: Text('در انتظار بررسی'),
                    ),
                    DropdownMenuItem(
                      value: 'private',
                      child: Text('خصوصی'),
                    ),
                  ],
                  onChanged: (value) => setState(() => _status = value!),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _slugController,
                  decoration: const InputDecoration(
                    labelText: 'پیوند یکتا',
                    hintText: 'فقط انگلیسی و خط تیره',
                    border: OutlineInputBorder(),
                  ),
                  textDirection: TextDirection.ltr,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesSection() {
    final selectedCats = ref.watch(selectedCategoriesProvider);

    return _buildSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('دسته‌بندی'),
          Row(
            children: [
              Expanded(
                child: Text(
                  selectedCats.isEmpty
                      ? 'هیچ دسته‌ای انتخاب نشده'
                      : '${selectedCats.length} دسته انتخاب شده',
                  style: const TextStyle(color: AppColors.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => setState(() => _catModalOpen = true),
                icon: const Icon(Icons.category, size: 18),
                label: const Text('مدیریت دسته‌ها'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Consumer(
            builder: (context, ref, child) {
              final cats = ref.watch(articleCategoriesProvider);
              final selected = ref.watch(selectedCategoriesProvider);

              return cats.when(
                data: (categories) {
                  if (selected.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  final selectedNames = selected
                      .map(
                        (id) => categories.firstWhere(
                          (c) => c.id == id,
                          orElse: () => ArticleCategory(id: 0, name: ''),
                        ),
                      )
                      .where((c) => c.name.isNotEmpty)
                      .map((c) => c.name)
                      .toList();

                  if (selectedNames.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: selectedNames
                        .map(
                          (name) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              name,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  );
                },
                loading: () => const SizedBox(
                  height: 20,
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                error: (err, _) => Text(
                  'خطا: $err',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.danger,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showCategoryModal() {
    final categoriesAsync = ref.read(articleCategoriesProvider);
    showDialog(
      context: context,
      builder: (ctx) {
        return categoriesAsync.when(
          data: (categories) => AlertDialog(
            title: const Text('مدیریت دسته‌ها'),
            content: SizedBox(
              width: double.maxFinite,
              height: 400,
              child: CategoryTreeWidget(
                categories: categories,
                selectedIds: _tempSelectedCategories,
                onChanged: (ids) {
                  setState(() {
                    _tempSelectedCategories = ids;
                  });
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      ref
                          .read(selectedCategoriesProvider.notifier)
                          .state = ids;
                    }
                  });
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('بستن'),
              ),
            ],
          ),
          loading: () => const AlertDialog(
            content: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => AlertDialog(
            title: const Text('خطا'),
            content: Text('خطا در بارگذاری دسته‌ها: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('بستن'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCodeEditorSection() {
    return _buildSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.code, size: 18, color: AppColors.primary),
              const SizedBox(width: 6),
              const Text(
                'محتوای مقاله',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(10),
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: AppColors.infoBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'HTML + CSS + JS در یک ویرایشگر یکپارچه\nجداکننده: /**CSS**/ و /**JS**/',
              style: TextStyle(
                fontSize: 12,
                height: 1.5,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          UnifiedCodeEditor(
            key: ValueKey('article-editor-$_editorKey'),
            initialValue: _unifiedCode,
            controller: _codeController,
            minHeight: 360,
            onChanged: (v) {
              _unifiedCode = v;
              final parts = UnifiedCodeEditor.split(v);
              _htmlCode = parts[0];
              _cssCode = parts[1];
              _jsCode = parts[2];
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSeoSection() {
    return _buildSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('سئو (Rank Math)'),
          AppTextField(
            controller: _seoTitleController,
            label: 'عنوان سئو',
            hint: '۵۰ تا ۶۰ کاراکتر',
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          Text(
            '${_seoTitleController.text.replaceAll(RegExp(r'%[^%]+%'), '').length}/۶۰ کاراکتر',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          AppTextField(
            controller: _seoDescController,
            label: 'توضیحات سئو',
            hint: '۱۴۰ تا ۱۶۰ کاراکتر',
            maxLines: 3,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          Text(
            '${_seoDescController.text.replaceAll(RegExp(r'%[^%]+%'), '').length}/۱۶۰ کاراکتر',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          AppTextField(
            controller: _seoKeywordsController,
            label: 'کلمات کلیدی',
            hint: 'کلمه کلیدی اصلی',
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          SeoAnalyzerWidget(
            title: _seoTitleController.text,
            description: _seoDescController.text,
            keywords: _seoKeywordsController.text,
            slug: _slugController.text,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_catModalOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showCategoryModal();
          setState(() => _catModalOpen = false);
        }
      });
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.articleId == null ? 'مقاله جدید' : 'ویرایش مقاله',
        ),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/articles'),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // پیام خطا
                  if (_errorMessage != null)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.dangerBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.danger.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: AppColors.danger,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: AppColors.danger,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () =>
                                setState(() => _errorMessage = null),
                          ),
                        ],
                      ),
                    ),
                  _buildFeaturedImageSection(),
                  _buildMainInfoSection(),
                  _buildCategoriesSection(),
                  _buildCodeEditorSection(),
                  _buildSeoSection(),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => context.go('/articles'),
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('بازگشت'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed:
                              _saving || _uploading ? null : _save,
                          icon: _saving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.save),
                          label: Text(
                            _saving
                                ? 'در حال ذخیره...'
                                : (widget.articleId == null
                                    ? 'ایجاد مقاله'
                                    : 'ذخیره تغییرات'),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(0, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_permalink != null && _permalink!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: InkWell(
                        onTap: () async {
                          final uri = Uri.tryParse(_permalink!);
                          if (uri != null) {
                            await launchUrl(
                              uri,
                              mode: LaunchMode.externalApplication,
                            );
                          }
                        },
                        child: Text(
                          '🔗 مشاهده مقاله در سایت',
                          style: TextStyle(color: AppColors.primary),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}