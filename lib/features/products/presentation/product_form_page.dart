// lib/features/products/presentation/product_form_page.dart
// نسخه نهایی - کامل، ایجکسی، بدون رفرش، پیام زیر فرم، لود برند و سئو

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../product_features/data/feature_models.dart';
import '../../product_features/data/feature_repository.dart';
import '../../product_features/presentation/widgets/feature_picker_sheet.dart';
import '../../product_features/presentation/widgets/unified_code_editor.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../../../core/network/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../data/product_models.dart';
import 'products_provider.dart';

// ===== تبدیل عدد به حروف فارسی =====
String _numberToWords(int num) {
  if (num == 0) return 'صفر';
  const units = ['', 'یک', 'دو', 'سه', 'چهار', 'پنج', 'شش', 'هفت', 'هشت', 'نه'];
  const tens = ['', 'ده', 'بیست', 'سی', 'چهل', 'پنجاه', 'شصت', 'هفتاد', 'هشتاد', 'نود'];
  const hundreds = ['', 'صد', 'دویست', 'سیصد', 'چهارصد', 'پانصد', 'ششصد', 'هفتصد', 'هشتصد', 'نهصد'];
  const thousands = ['', 'هزار', 'میلیون', 'میلیارد'];

  String _convertLessThanThousand(int n) {
    if (n == 0) return '';
    String result = '';
    if (n >= 100) {
      result += hundreds[n ~/ 100];
      n %= 100;
      if (n > 0) result += ' و ';
    }
    if (n >= 20) {
      result += tens[n ~/ 10];
      n %= 10;
      if (n > 0) result += ' و ' + units[n];
    } else if (n > 0) {
      result += units[n];
    }
    return result;
  }

  List<String> parts = [];
  int index = 0;
  while (num > 0) {
    final chunk = num % 1000;
    if (chunk > 0) {
      final chunkText = _convertLessThanThousand(chunk);
      parts.add(chunkText + (thousands[index] != '' ? ' ' + thousands[index] : ''));
    }
    num ~/= 1000;
    index++;
  }
  return parts.reversed.join(' و ');
}

// ===== فرمت‌کننده قیمت با کاما =====
class PriceInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final cleaned = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (cleaned.isEmpty) return newValue.copyWith(text: '');

    final intValue = int.tryParse(cleaned) ?? 0;
    final formatted = intValue.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]},',
    );

    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

// ===== ویجت نمایش تصویر با اطلاعات =====
class _ImageDisplayWidget extends StatelessWidget {
  final Uint8List? imageBytes;
  final String? imageUrl;
  final String? fileName;
  final int? fileSize;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  const _ImageDisplayWidget({
    required this.onTap,
    this.imageBytes,
    this.imageUrl,
    this.fileName,
    this.fileSize,
    this.onRemove,
  });

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
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
                child: imageBytes != null
                    ? Image.memory(imageBytes!, fit: BoxFit.cover)
                    : imageUrl != null
                        ? Image.network(
                            imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.broken_image,
                              size: 60,
                              color: AppTheme.textSecondary,
                            ),
                          )
                        : Container(
                            color: AppTheme.background,
                            child: const Icon(
                              Icons.add_photo_alternate,
                              size: 60,
                              color: AppTheme.textSecondary,
                            ),
                          ),
              ),
            ),
            if (imageBytes != null || imageUrl != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (fileName != null)
                            Text(
                              fileName!,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          if (fileSize != null)
                            Text(
                              'حجم: ${_formatFileSize(fileSize!)}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          if (imageUrl != null && imageBytes == null)
                            const Text(
                              'تصویر از سرور',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (onRemove != null)
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: AppTheme.danger,
                          size: 20,
                        ),
                        onPressed: onRemove,
                        tooltip: 'حذف تصویر',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                  ],
                ),
              ),
            if (imageBytes == null && imageUrl == null)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    'برای انتخاب تصویر کلیک کنید',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ===== ویجت درخت دسته‌بندی =====
class CategoryTreeSelector extends ConsumerStatefulWidget {
  final List<ProductCategory> categories;
  final List<int> selectedIds;
  final Function(List<int>) onChanged;

  const CategoryTreeSelector({
    super.key,
    required this.categories,
    required this.selectedIds,
    required this.onChanged,
  });

  @override
  ConsumerState<CategoryTreeSelector> createState() =>
      _CategoryTreeSelectorState();
}

class _CategoryTreeSelectorState extends ConsumerState<CategoryTreeSelector> {
  late List<int> _selectedIds;
  final TextEditingController _newCatController = TextEditingController();
  int? _newCatParentId;
  bool _showAddForm = false;

  @override
  void initState() {
    super.initState();
    _selectedIds = List.from(widget.selectedIds);
  }

  List<Map<String, dynamic>> _buildTree(
    List<ProductCategory> cats, {
    int parentId = 0,
  }) {
    return cats
        .where((c) => c.parentId == parentId)
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
        final cat = node['category'] as ProductCategory;
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
                        },
                      ),
                      Expanded(child: Text(cat.name)),
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
                      },
                    ),
                    Expanded(child: Text(cat.name)),
                  ],
                ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tree = _buildTree(widget.categories, parentId: 0);
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
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
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
                      child: DropdownButtonFormField<int>(
                        value: _newCatParentId,
                        decoration: const InputDecoration(
                          labelText: 'والد',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items: [
                          const DropdownMenuItem<int>(
                            value: 0,
                            child: Text('بدون والد'),
                          ),
                          ...widget.categories.map(
                            (c) => DropdownMenuItem<int>(
                              value: c.id,
                              child: Text(c.name),
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
                        final repo = ref.read(productRepositoryProvider);
                        try {
                          final newCat = await repo.createCategory({
                            'name': _newCatController.text.trim(),
                            'parent': _newCatParentId ?? 0,
                          });
                          ref.invalidate(categoriesProvider);
                          setState(() {
                            _selectedIds.add(newCat.id);
                            _newCatController.clear();
                            _newCatParentId = null;
                            _showAddForm = false;
                          });
                          widget.onChanged(_selectedIds);
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('دسته جدید اضافه شد'),
                            ),
                          );
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('خطا در افزودن دسته: $e'),
                            ),
                          );
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

// ===== ویجت مدیریت برندها =====
class BrandSelector extends ConsumerStatefulWidget {
  final List<ProductTag> brands;
  final List<int> selectedBrandIds;
  final Function(List<int>) onChanged;

  const BrandSelector({
    super.key,
    required this.brands,
    required this.selectedBrandIds,
    required this.onChanged,
  });

  @override
  ConsumerState<BrandSelector> createState() => _BrandSelectorState();
}

class _BrandSelectorState extends ConsumerState<BrandSelector> {
  late List<int> _selectedIds;
  final TextEditingController _newBrandController = TextEditingController();
  bool _showAddField = false;

  @override
  void initState() {
    super.initState();
    _selectedIds = List.from(widget.selectedBrandIds);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_selectedIds.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Wrap(
              spacing: 8,
              children: _selectedIds.map((id) {
                final brand = widget.brands.firstWhere(
                  (b) => b.id == id,
                  orElse: () => ProductTag(id: 0, name: ''),
                );
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    brand.name.isNotEmpty ? brand.name : 'برند',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.primary,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        if (widget.brands.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: Text(
                'هیچ برندی یافت نشد',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.brands.map((brand) {
              final isSelected = _selectedIds.contains(brand.id);
              return FilterChip(
                label: Text(brand.name),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedIds.add(brand.id);
                    } else {
                      _selectedIds.remove(brand.id);
                    }
                  });
                  widget.onChanged(_selectedIds);
                },
              );
            }).toList(),
          ),
        const SizedBox(height: 8),
        if (!_showAddField)
          TextButton.icon(
            onPressed: () => setState(() => _showAddField = true),
            icon: const Icon(Icons.add_circle_outline, size: 18),
            label: const Text('افزودن برند جدید'),
          )
        else
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _newBrandController,
                    decoration: const InputDecoration(
                      labelText: 'نام برند',
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.check, color: AppTheme.success),
                  onPressed: () async {
                    if (_newBrandController.text.trim().isEmpty) return;
                    final repo = ref.read(productRepositoryProvider);
                    try {
                      final newBrand = await repo.createBrand({
                        'name': _newBrandController.text.trim(),
                      });
                      ref.invalidate(brandsProvider);
                      setState(() {
                        _selectedIds.add(newBrand.id);
                        _newBrandController.clear();
                        _showAddField = false;
                      });
                      widget.onChanged(_selectedIds);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('برند جدید اضافه شد')),
                      );
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('خطا در افزودن برند: $e')),
                      );
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppTheme.danger),
                  onPressed: () {
                    setState(() {
                      _showAddField = false;
                      _newBrandController.clear();
                    });
                  },
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ===== ویجت سئو با امتیازدهی =====
class SeoScorerWidget extends StatelessWidget {
  final String title;
  final String description;
  final String keywords;

  const SeoScorerWidget({
    super.key,
    required this.title,
    required this.description,
    required this.keywords,
  });

  int _calculateScore(String text, int minLen, int maxLen) {
    final len = text.length;
    if (len == 0) return 0;
    if (len >= minLen && len <= maxLen) return 100;
    if (len < minLen) return ((len / minLen) * 100).toInt();
    return ((maxLen / len) * 100).toInt().clamp(0, 100);
  }

  List<String> _getSuggestions(
    String title,
    String description,
    String keywords,
  ) {
    List<String> suggestions = [];
    if (title.isEmpty) {
      suggestions.add('⚠️ عنوان سئو خالی است');
    } else if (title.length < 30) {
      suggestions.add(
        '✏️ عنوان سئو کوتاه است (${title.length} کاراکتر) - حداقل ۳۰',
      );
    } else if (title.length > 60) {
      suggestions.add(
        '✏️ عنوان سئو طولانی است (${title.length} کاراکتر) - حداکثر ۶۰',
      );
    } else {
      suggestions.add('✅ عنوان سئو عالی است');
    }

    if (description.isEmpty) {
      suggestions.add('⚠️ توضیحات سئو خالی است');
    } else if (description.length < 120) {
      suggestions.add(
        '✏️ توضیحات سئو کوتاه است (${description.length} کاراکتر) - حداقل ۱۴۰',
      );
    } else if (description.length > 160) {
      suggestions.add(
        '✏️ توضیحات سئو طولانی است (${description.length} کاراکتر) - حداکثر ۱۶۰',
      );
    } else {
      suggestions.add('✅ توضیحات سئو عالی است');
    }

    if (keywords.isEmpty) {
      suggestions.add('⚠️ کلمات کلیدی خالی است');
    } else {
      final count =
          keywords.split(',').where((k) => k.trim().isNotEmpty).length;
      if (count < 2) {
        suggestions.add(
          '✏️ فقط $count کلمه کلیدی وارد شده - پیشنهاد: ۳ تا ۵ کلمه',
        );
      } else if (count > 7) {
        suggestions.add('✏️ $count کلمه کلیدی زیاد است - پیشنهاد: ۳ تا ۵ کلمه');
      } else {
        suggestions.add('✅ تعداد کلمات کلیدی مناسب است ($count مورد)');
      }
    }
    return suggestions;
  }

  @override
  Widget build(BuildContext context) {
    final titleScore = _calculateScore(title, 30, 60);
    final descScore = _calculateScore(description, 140, 160);
    final totalScore = ((titleScore + descScore) / 2).round();
    final suggestions = _getSuggestions(title, description, keywords);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'امتیاز سئو',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: totalScore >= 80
                      ? AppTheme.success.withOpacity(0.15)
                      : totalScore >= 50
                          ? Colors.orange.withOpacity(0.15)
                          : AppTheme.danger.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$totalScore%',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: totalScore >= 80
                        ? AppTheme.success
                        : totalScore >= 50
                            ? Colors.orange
                            : AppTheme.danger,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: totalScore / 100,
            backgroundColor: AppTheme.border,
            color: totalScore >= 80
                ? AppTheme.success
                : totalScore >= 50
                    ? Colors.orange
                    : AppTheme.danger,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),
          const Text(
            'پیشنهادات بهبود:',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          ...suggestions.map(
            (s) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                s,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ===== صفحه اصلی =====
class ProductFormPage extends ConsumerStatefulWidget {
  final int? productId;
  const ProductFormPage({super.key, this.productId});

  @override
  ConsumerState<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends ConsumerState<ProductFormPage> {
  final _formKey = GlobalKey<FormState>();

  // کنترلرهای فیلدها
  final _titleController = TextEditingController();
  final _slugController = TextEditingController();
  final _shortDescController = TextEditingController();
  final _regularPriceController = TextEditingController();
  final _salePriceController = TextEditingController();
  final _stockController = TextEditingController();
  final _seoTitleController = TextEditingController();
  final _seoDescController = TextEditingController();
  final _seoKeywordsController = TextEditingController();

  // وضعیت‌ها
  String? _status = 'draft';
  String _stockStatus = 'instock'; // instock | outofstock | onbackorder
  List<int> _selectedCategories = [];
  List<int> _selectedTags = [];
  List<int> _selectedBrandIds = [];

  // تصاویر
  Uint8List? _mainImageBytes;
  String? _mainImageName;
  int? _mainImageSize;
  List<Uint8List> _galleryBytes = [];
  List<String> _galleryNames = [];
  List<int> _gallerySizes = [];
  List<String> _existingImageUrls = [];
  List<String> _existingImageNames = [];

  // کدها
  String _htmlCode = '<p>توضیحات محصول...</p>';
  String _cssCode = '/* CSS */';
  String _jsCode = '// JS';
  String _unifiedCode = '';
  final TextEditingController _codeController = TextEditingController();
  List<ProductFeatureSlot> _featureSlots = [];

  bool _loading = true;
  bool _uploading = false;
  String? _error;
  String? _message;

  @override
  void initState() {
    super.initState();
    if (widget.productId != null) {
      _loadProduct();
    } else {
      _loading = false;
      _unifiedCode =
          UnifiedCodeEditor.combine(_htmlCode, _cssCode, _jsCode);
      _codeController.text = _unifiedCode;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _slugController.dispose();
    _shortDescController.dispose();
    _regularPriceController.dispose();
    _salePriceController.dispose();
    _stockController.dispose();
    _seoTitleController.dispose();
    _seoDescController.dispose();
    _seoKeywordsController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  // ============================================================
  // لود اطلاعات محصول
  // ============================================================
  Future<void> _loadProduct() async {
    if (widget.productId == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    final repo = ref.read(productRepositoryProvider);
    try {
      final product = await repo.fetchProduct(widget.productId!);
      if (!mounted) return;

      final rawDesc = product.description ?? '';
      final parts = UnifiedCodeEditor.split(rawDesc);

      String htmlPart = parts[0];
      String cssPart = parts[1];
      String jsPart = parts[2];

      String? metaCss;
      String? metaJs;
      String? seoTitle;
      String? seoDesc;
      String? seoKeywords;

      if (product.metaData != null) {
        metaCss = product.metaData!['ezlens_desc_css']?.toString();
        metaJs = product.metaData!['ezlens_desc_js']?.toString();
        seoTitle = product.metaData!['rank_math_title']?.toString();
        seoDesc = product.metaData!['rank_math_description']?.toString();
        seoKeywords =
            product.metaData!['rank_math_focus_keyword']?.toString();
      }

      final finalCss = (metaCss != null && metaCss.trim().isNotEmpty)
          ? metaCss
          : (cssPart.isNotEmpty ? cssPart : '/* CSS */');
      final finalJs = (metaJs != null && metaJs.trim().isNotEmpty)
          ? metaJs
          : (jsPart.isNotEmpty ? jsPart : '// JS');

      if (htmlPart.isEmpty && rawDesc.isNotEmpty) {
        htmlPart = rawDesc;
      }

      setState(() {
        _titleController.text = product.name;
        _slugController.text = product.slug;
        _status = product.status;
        _stockStatus = product.stockStatus.isNotEmpty ? product.stockStatus : 'instock';
        _regularPriceController.text = product.regularPrice;
        _salePriceController.text = product.salePrice ?? '';
        _stockController.text = product.stockQuantity?.toString() ?? '';
        _shortDescController.text = product.shortDescription ?? '';

        _htmlCode = htmlPart;
        _cssCode = finalCss;
        _jsCode = finalJs;

        _selectedCategories =
            product.categories.map((c) => c.id).toList();
        _selectedTags = product.tags.map((t) => t.id).toList();

        if (product.brands.isNotEmpty) {
          _selectedBrandIds =
              product.brands.map((b) => b.id).toList();
        } else if (product.metaData != null &&
            product.metaData!['rank_math_primary_product_brand'] != null) {
          final brandId = int.tryParse(
            product.metaData!['rank_math_primary_product_brand'].toString(),
          );
          if (brandId != null) _selectedBrandIds = [brandId];
        }

        _existingImageUrls = product.images.map((i) => i.src).toList();
        _existingImageNames =
            product.images.map((i) => i.name ?? '').toList();

        _unifiedCode =
            UnifiedCodeEditor.combine(_htmlCode, _cssCode, _jsCode);
        _codeController.text = _unifiedCode;

        _loading = false;
      });

      setState(() {
        _seoTitleController.text = seoTitle ?? '';
        _seoDescController.text = seoDesc ?? '';
        _seoKeywordsController.text = seoKeywords ?? '';
      });

      try {
        final slots = await ref
            .read(productFeatureRepositoryProvider)
            .fetchProductSlots(widget.productId!);
        if (mounted) setState(() => _featureSlots = slots);
      } catch (_) {}

      _updateSeoScore();
    } catch (e) {
      setState(() {
        _error = 'خطا در دریافت اطلاعات: $e';
        _loading = false;
      });
    }
  }

  void _updateSeoScore() {
    setState(() {});
  }

  Future<void> _pickImage({required bool isMain}) async {
    final picker = ImagePicker();
    final pickedFile =
        await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      final size = await pickedFile.length();
      setState(() {
        if (isMain) {
          _mainImageBytes = bytes;
          _mainImageName = pickedFile.name;
          _mainImageSize = size;
        } else {
          _galleryBytes.add(bytes);
          _galleryNames.add(pickedFile.name);
          _gallerySizes.add(size);
        }
      });
    }
  }

  void _removeMainImage() {
    setState(() {
      _mainImageBytes = null;
      _mainImageName = null;
      _mainImageSize = null;
    });
  }

  void _removeGalleryImage(int index) {
    setState(() {
      _galleryBytes.removeAt(index);
      _galleryNames.removeAt(index);
      _gallerySizes.removeAt(index);
    });
  }

  void _removeExistingImage(int index) {
    setState(() {
      _existingImageUrls.removeAt(index);
      _existingImageNames.removeAt(index);
    });
  }

  Future<int> _uploadImage(Uint8List bytes, String fileName) async {
    final apiClient = ref.read(apiClientProvider);
    final tempFile = File('temp_$fileName');
    await tempFile.writeAsBytes(bytes);
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        tempFile.path,
        filename: fileName,
      ),
    });
    final response = await apiClient.uploadMedia(
      '/wp-json/wp/v2/media',
      formData: formData,
    );
    await tempFile.delete();
    return response.data['id'];
  }

  // ============================================================
  // ذخیره محصول
  // ============================================================
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _uploading = true;
      _error = null;
      _message = null;
    });

    final repo = ref.read(productRepositoryProvider);

    try {
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

      final productData = {
        'name': _titleController.text.trim(),
        'slug': _slugController.text.trim().isNotEmpty
            ? _slugController.text.trim()
            : null,
        'status': _status,
        'regular_price':
            _regularPriceController.text.replaceAll(',', ''),
        'sale_price': _salePriceController.text.replaceAll(',', ''),
        'manage_stock': true,
        'stock_status': _stockStatus,
        'stock_quantity':
            int.tryParse(_stockController.text.trim()) ?? 0,
        'short_description': _shortDescController.text.trim(),
        'description': cleanHtml,
        'categories':
            _selectedCategories.map((id) => {'id': id}).toList(),
        'tags': _selectedTags.map((id) => {'id': id}).toList(),
        'product_brand':
            _selectedBrandIds.map((id) => {'id': id}).toList(),
        'meta_data': [
          {'key': 'ezlens_desc_css', 'value': cleanCss},
          {'key': 'ezlens_desc_js', 'value': cleanJs},
          {
            'key': 'rank_math_title',
            'value': _seoTitleController.text.trim()
          },
          {
            'key': 'rank_math_description',
            'value': _seoDescController.text.trim(),
          },
          {
            'key': 'rank_math_focus_keyword',
            'value': _seoKeywordsController.text.trim(),
          },
        ],
      };

      List<Map<String, dynamic>> images = [];
      for (int i = 0; i < _existingImageUrls.length; i++) {
        images.add({'src': _existingImageUrls[i]});
      }
      if (_mainImageBytes != null) {
        final imageId =
            await _uploadImage(_mainImageBytes!, _mainImageName!);
        images.insert(0, {'id': imageId});
      }
      for (int i = 0; i < _galleryBytes.length; i++) {
        final imageId =
            await _uploadImage(_galleryBytes[i], _galleryNames[i]);
        images.add({'id': imageId});
      }
      if (images.isNotEmpty) {
        productData['images'] = images;
      }

      if (widget.productId == null) {
        final newProduct = await repo.createProduct(productData);
        if (_featureSlots.isNotEmpty) {
          try {
            await ref
                .read(productFeatureRepositoryProvider)
                .saveProductSlots(newProduct.id, _featureSlots);
          } catch (_) {}
        }
        setState(() => _message = 'محصول با موفقیت ساخته شد');
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) context.go('/products/${newProduct.id}');
        });
      } else {
        await repo.updateProduct(widget.productId!, productData);
        try {
          await ref
              .read(productFeatureRepositoryProvider)
              .saveProductSlots(widget.productId!, _featureSlots);
        } catch (_) {}
        setState(() {
          _message = 'تغییرات با موفقیت ذخیره شد';
          _codeController.text = UnifiedCodeEditor.combine(
            cleanHtml,
            cleanCss,
            cleanJs,
          );
          _unifiedCode = _codeController.text;
        });
        // Stay on product edit page
      }
    } catch (e) {
      setState(() => _error = '❌ خطا در ذخیره: $e');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Widget _buildPriceField({
    required TextEditingController controller,
    required String label,
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            border: const OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [PriceInputFormatter()],
        ),
        if (controller.text.isNotEmpty &&
            int.tryParse(controller.text.replaceAll(',', '')) != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '${_numberToWords(int.parse(controller.text.replaceAll(',', '')))} تومان',
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final brandsAsync = ref.watch(brandsProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          widget.productId == null ? 'محصول جدید' : 'ویرایش محصول',
        ),
        centerTitle: true,
        backgroundColor: AppTheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/products'),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (_error != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppTheme.danger.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.danger.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: AppTheme.danger),
                      ),
                    ),
                  if (_message != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppTheme.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.success.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        _message!,
                        style: const TextStyle(color: AppTheme.success),
                      ),
                    ),

                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ===== تصویر اصلی =====
                        _sectionTitle('تصویر اصلی'),
                        _ImageDisplayWidget(
                          onTap: () => _pickImage(isMain: true),
                          imageBytes: _mainImageBytes,
                          imageUrl: _existingImageUrls.isNotEmpty &&
                                  _mainImageBytes == null
                              ? _existingImageUrls.first
                              : null,
                          fileName: _mainImageName,
                          fileSize: _mainImageSize,
                          onRemove:
                              _mainImageBytes != null ? _removeMainImage : null,
                        ),
                        const SizedBox(height: 20),

                        // ===== گالری محصول =====
                        _sectionTitle(
                          'گالری محصول (${_existingImageUrls.length + _galleryBytes.length})',
                        ),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ..._existingImageUrls
                                .asMap()
                                .entries
                                .map((entry) {
                              final index = entry.key;
                              final url = entry.value;
                              return Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      url,
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        width: 80,
                                        height: 80,
                                        color: AppTheme.border,
                                        child: const Icon(
                                          Icons.broken_image,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 0,
                                    right: 0,
                                    child: GestureDetector(
                                      onTap: () => _removeExistingImage(index),
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }),
                            ..._galleryBytes
                                .asMap()
                                .entries
                                .map((entry) {
                              final index = entry.key;
                              final bytes = entry.value;
                              return Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.memory(
                                      bytes,
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: 0,
                                    right: 0,
                                    child: GestureDetector(
                                      onTap: () => _removeGalleryImage(index),
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }),
                            GestureDetector(
                              onTap: () => _pickImage(isMain: false),
                              child: Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppTheme.border),
                                ),
                                child: const Icon(
                                  Icons.add,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // ===== اطلاعات اصلی =====
                        _sectionTitle('اطلاعات اصلی'),
                        TextFormField(
                          controller: _titleController,
                          decoration: const InputDecoration(
                            labelText: 'نام محصول *',
                          ),
                          validator: (value) => value!.isEmpty
                              ? 'نام محصول الزامی است'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _shortDescController,
                          decoration: const InputDecoration(
                            labelText: 'توضیح کوتاه',
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _buildPriceField(
                                controller: _regularPriceController,
                                label: 'قیمت عادی',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildPriceField(
                                controller: _salePriceController,
                                label: 'قیمت ویژه',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _stockController,
                                decoration: const InputDecoration(
                                  labelText: 'موجودی انبار',
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _stockStatus,
                                decoration: const InputDecoration(
                                  labelText: 'موجود بودن',
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'instock',
                                    child: Text('موجود'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'outofstock',
                                    child: Text('ناموجود'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'onbackorder',
                                    child: Text('پیش‌سفارش'),
                                  ),
                                ],
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() => _stockStatus = value);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _status,
                                decoration: const InputDecoration(
                                  labelText: 'وضعیت انتشار',
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'draft',
                                    child: Text('پیش‌نویس'),
                                  ),
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
                                onChanged: (value) =>
                                    setState(() => _status = value),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // ===== دسته‌بندی =====
                        Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: const BorderSide(color: AppTheme.border),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.category,
                                      color: AppTheme.primary,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'مدیریت دسته‌بندی',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                if (_selectedCategories.isNotEmpty)
                                  Padding(
                                    padding:
                                        const EdgeInsets.only(bottom: 8),
                                    child: Consumer(
                                      builder: (context, ref, child) {
                                        final categories = ref
                                            .watch(categoriesProvider)
                                            .value;
                                        if (categories == null) {
                                          return const SizedBox.shrink();
                                        }
                                        return Wrap(
                                          spacing: 8,
                                          children: _selectedCategories
                                              .map((id) {
                                            final cat = categories
                                                .firstWhere(
                                              (c) => c.id == id,
                                              orElse: () =>
                                                  ProductCategory(
                                                id: 0,
                                                name: '',
                                              ),
                                            );
                                            return Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: AppTheme.primary
                                                    .withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(
                                                  16,
                                                ),
                                              ),
                                              child: Text(
                                                cat.name.isNotEmpty
                                                    ? cat.name
                                                    : 'دسته',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color:
                                                      AppTheme.primary,
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                        );
                                      },
                                    ),
                                  ),
                                categoriesAsync.when(
                                  data: (categories) => Container(
                                    height: 280,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: AppTheme.border,
                                      ),
                                      borderRadius:
                                          BorderRadius.circular(12),
                                    ),
                                    child: CategoryTreeSelector(
                                      categories: categories,
                                      selectedIds: _selectedCategories,
                                      onChanged: (ids) => setState(
                                        () => _selectedCategories = ids,
                                      ),
                                    ),
                                  ),
                                  loading: () => const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                  error: (err, _) => Text(
                                    'خطا در بارگذاری دسته‌ها: $err',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // ===== برندها =====
                        Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: const BorderSide(color: AppTheme.border),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.label,
                                      color: AppTheme.secondary,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'مدیریت برندها',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                brandsAsync.when(
                                  data: (brands) => BrandSelector(
                                    brands: brands,
                                    selectedBrandIds: _selectedBrandIds,
                                    onChanged: (ids) => setState(
                                      () => _selectedBrandIds = ids,
                                    ),
                                  ),
                                  loading: () => const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                  error: (err, _) => Text(
                                    'خطا در بارگذاری برندها: $err',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // ===== ویرایشگر کد یکپارچه =====
                        _sectionTitle('توضیحات بلند'),
                        const Text(
                          'HTML + CSS + JS در یک ویرایشگر یکپارچه — جداکننده /**CSS**/ و /**JS**/',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        UnifiedCodeEditor(
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
                        const SizedBox(height: 24),

                        // ===== سئو =====
                        _sectionTitle('سئو (Rank Math)'),
                        SeoScorerWidget(
                          title: _seoTitleController.text,
                          description: _seoDescController.text,
                          keywords: _seoKeywordsController.text,
                        ),
                        const SizedBox(height: 12),

                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '۱) عنوان سئو',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                            const Text(
                              'حدود ۵۰ تا ۶۰ کاراکتر',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            TextFormField(
                              controller: _seoTitleController,
                              onChanged: (_) => _updateSeoScore(),
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                hintText:
                                    'مثال: خرید لنز هارد Boston XO2 | EzLens',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '۲) پیوند یکتا (Slug)',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                            const Text(
                              'انگلیسی، با خط تیره',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            TextFormField(
                              controller: _slugController,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                hintText: 'مثال: boston-xo2-hard-lens',
                              ),
                              textDirection: TextDirection.ltr,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '۳) توضیحات سئو',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                            const Text(
                              'حدود ۱۴۰ تا ۱۶۰ کاراکتر',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            TextFormField(
                              controller: _seoDescController,
                              maxLines: 3,
                              onChanged: (_) => _updateSeoScore(),
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                hintText:
                                    'خلاصه‌ای از محصول را بنویسید...',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '۴) کلمات کلیدی',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                            const Text(
                              'کلمه اصلی + ۲-۳ کلمه مرتبط، با ویرگول',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            TextFormField(
                              controller: _seoKeywordsController,
                              onChanged: (_) => _updateSeoScore(),
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                hintText:
                                    'لنز طبی هارد, Boston XO2, لنز RGP',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // ===== ویژگی‌های محصول =====
                        const Text(
                          'ویژگی‌های محصول',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'پالت‌های آماده را وصل کنید و محل/نحوه نمایش را تنظیم کنید',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: () async {
                            final result = await showFeaturePickerSheet(
                              context,
                              current: _featureSlots,
                            );
                            if (result != null && mounted) {
                              setState(() => _featureSlots = result);
                            }
                          },
                          icon: const Icon(Icons.layers_outlined),
                          label: const Text('انتخاب ویژگی محصول'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(44),
                            side: const BorderSide(color: AppTheme.primary),
                            foregroundColor: AppTheme.primary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ..._featureSlots.asMap().entries.map((e) {
                          final i = e.key;
                          final slot = e.value;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.layers_outlined,
                                      size: 18,
                                      color: AppTheme.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        slot.title.isNotEmpty
                                            ? slot.title
                                            : 'ویژگی #${slot.templateId}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close, size: 18),
                                      onPressed: () => setState(
                                        () => _featureSlots.removeAt(i),
                                      ),
                                    ),
                                  ],
                                ),
                                TextFormField(
                                  initialValue: slot.label,
                                  decoration: const InputDecoration(
                                    labelText: 'عنوان نمایشی',
                                    isDense: true,
                                    border: OutlineInputBorder(),
                                  ),
                                  onChanged: (v) => _featureSlots[i] =
                                      slot.copyWith(label: v),
                                ),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<String>(
                                  value: ProductFeatureSlot
                                          .placements
                                          .containsKey(slot.placement)
                                      ? slot.placement
                                      : 'below_summary',
                                  decoration: const InputDecoration(
                                    labelText: 'محل قرارگیری',
                                    isDense: true,
                                    border: OutlineInputBorder(),
                                  ),
                                  items: ProductFeatureSlot
                                      .placements.entries
                                      .map(
                                        (x) => DropdownMenuItem(
                                          value: x.key,
                                          child: Text(x.value),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (v) {
                                    if (v != null) {
                                      setState(
                                        () => _featureSlots[i] =
                                            slot.copyWith(placement: v),
                                      );
                                    }
                                  },
                                ),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<String>(
                                  value: ProductFeatureSlot.displays
                                          .containsKey(slot.display)
                                      ? slot.display
                                      : 'inline',
                                  decoration: const InputDecoration(
                                    labelText: 'نحوه باز شدن',
                                    isDense: true,
                                    border: OutlineInputBorder(),
                                  ),
                                  items: ProductFeatureSlot
                                      .displays.entries
                                      .map(
                                        (x) => DropdownMenuItem(
                                          value: x.key,
                                          child: Text(x.value),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (v) {
                                    if (v != null) {
                                      setState(
                                        () => _featureSlots[i] =
                                            slot.copyWith(display: v),
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                          );
                        }),
                        const SizedBox(height: 16),

                        // ===== دکمه ذخیره =====
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _uploading ? null : _save,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF071b7a),
                              foregroundColor: Colors.white,
                              disabledBackgroundColor:
                                  const Color(0xFF071b7a).withValues(alpha: 0.4),
                              disabledForegroundColor: Colors.white70,
                              padding: const EdgeInsets.symmetric(
                                vertical: 14,
                                horizontal: 24,
                              ),
                              elevation: 0,
                            ),
                            child: _uploading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    widget.productId == null
                                        ? 'ایجاد محصول'
                                        : 'ذخیره تغییرات',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // ===== پیام‌های موفقیت / خطا =====
                        if (_message != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color:
                                    AppTheme.success.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppTheme.success
                                      .withValues(alpha: 0.3),
                                ),
                              ),
                              child: Text(
                                _message!,
                                style: const TextStyle(
                                  color: AppTheme.success,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        if (_error != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color:
                                    AppTheme.danger.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppTheme.danger
                                      .withValues(alpha: 0.3),
                                ),
                              ),
                              child: Text(
                                _error!,
                                style: const TextStyle(
                                  color: AppTheme.danger,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }
}