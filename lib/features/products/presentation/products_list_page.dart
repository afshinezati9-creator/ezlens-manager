// lib/features/products/presentation/products_list_page.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../data/product_models.dart';
import 'products_provider.dart';


// =============================================================
// Helpers
// =============================================================

String _toFa(num value) {
  const fa = [
    '۰',
    '۱',
    '۲',
    '۳',
    '۴',
    '۵',
    '۶',
    '۷',
    '۸',
    '۹',
  ];

  return value
      .toString()
      .split('')
      .map((char) {
        final digit = int.tryParse(char);

        return digit != null
            ? fa[digit]
            : char;
      })
      .join();
}


String _formatPrice(String price) {
  if (price.isEmpty) {
    return '—';
  }

  final numValue = double.tryParse(price) ?? 0;

  if (numValue == 0) {
    return '—';
  }

  final formatted = numValue
      .toInt()
      .toString()
      .replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
        (match) => '${match[1]},',
      );

  return '$formatted تومان';
}


// =============================================================
// Category Tree
// =============================================================

class CategoryTreeWidget extends StatelessWidget {
  final List<ProductCategory> categories;
  final List<int> selectedIds;
  final Function(List<int>) onChanged;

  const CategoryTreeWidget({
    super.key,
    required this.categories,
    required this.selectedIds,
    required this.onChanged,
  });

  List<Map<String, dynamic>> _buildTree(
    List<ProductCategory> cats, {
    int parentId = 0,
  }) {
    return cats
        .where((c) => (c.parentId ?? 0) == parentId)
        .map(
          (c) => {
            'category': c,
            'children': _buildTree(
              cats,
              parentId: c.id,
            ),
          },
        )
        .toList();
  }

  Widget _buildTreeWidget(
    List<Map<String, dynamic>> nodes,
    int depth,
  ) {
    if (nodes.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: Text(
            'هیچ دسته‌بندی وجود ندارد',
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: nodes.map((node) {
        final cat =
            node['category'] as ProductCategory;

        final children =
            node['children']
                as List<Map<String, dynamic>>;

        final isChecked =
            selectedIds.contains(cat.id);

        final hasChildren =
            children.isNotEmpty;

        void toggle(bool? value) {
          if (value == true) {
            if (!selectedIds.contains(cat.id)) {
              onChanged([
                ...selectedIds,
                cat.id,
              ]);
            }
          } else {
            onChanged(
              selectedIds
                  .where(
                    (id) => id != cat.id,
                  )
                  .toList(),
            );
          }
        }

        return Padding(
          padding: EdgeInsets.only(
            right: depth * 16.0,
          ),
          child: hasChildren
              ? ExpansionTile(
                  title: Row(
                    children: [
                      Checkbox(
                        value: isChecked,
                        onChanged: toggle,
                      ),
                      Expanded(
                        child: Text(cat.name),
                      ),
                    ],
                  ),
                  children: [
                    _buildTreeWidget(
                      children,
                      depth + 1,
                    ),
                  ],
                  initiallyExpanded: true,
                )
              : Row(
                  children: [
                    Checkbox(
                      value: isChecked,
                      onChanged: toggle,
                    ),
                    Expanded(
                      child: Text(cat.name),
                    ),
                  ],
                ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return const Center(
        child: Text(
          'دسته‌بندی یافت نشد',
        ),
      );
    }

    final tree = _buildTree(
      categories,
      parentId: 0,
    );

    return SingleChildScrollView(
      child: _buildTreeWidget(
        tree,
        0,
      ),
    );
  }
}


// =============================================================
// Products List Page
// =============================================================

class ProductsListPage
    extends ConsumerStatefulWidget {
  const ProductsListPage({
    super.key,
  });

  @override
  ConsumerState<ProductsListPage> createState() =>
      _ProductsListPageState();
}


class _ProductsListPageState
    extends ConsumerState<ProductsListPage> {

  final TextEditingController
      _searchController =
      TextEditingController();

  Timer? _debounce;

  int? _categoryId;
  int? _brandId;
  String? _status;

  String _selectedOrderBy = 'date';
  String _selectedOrder = 'desc';

  String _selectedCategoryName = 'همه';
  String _selectedBrandName = 'همه';


  // ===========================================================
  // Sort Options
  // ===========================================================

  final Map<String, String>
      _orderByOptions = {
    'date': 'جدیدترین',
    'id': 'قدیمی‌ترین',
    'popularity': 'بیشترین فروش',
    'rating': 'بالاترین امتیاز',
    'price': 'ارزان‌ترین',
    'price-desc': 'گران‌ترین',
  };


  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }


  // ===========================================================
  // Search
  // ===========================================================

  void _onSearchChanged(
    String value,
  ) {
    if (_debounce?.isActive ?? false) {
      _debounce!.cancel();
    }

    _debounce = Timer(
      const Duration(
        milliseconds: 500,
      ),
      () {
        ref
            .read(
              productsSearchProvider
                  .notifier,
            )
            .state = value;

        ref
            .read(
              productsPageProvider
                  .notifier,
            )
            .state = 1;

        ref.invalidate(
          productsProvider,
        );
      },
    );
  }


  // ===========================================================
  // Category
  // ===========================================================

  void _onCategoryChanged(
    int? value,
  ) {
    setState(() {
      _categoryId = value;

      _selectedCategoryName =
          value == null
              ? 'همه'
              : _getCategoryName(value);
    });

    ref
        .read(
          productsCategoryProvider
              .notifier,
        )
        .state = value;

    ref
        .read(
          productsPageProvider
              .notifier,
        )
        .state = 1;

    ref.invalidate(
      productsProvider,
    );
  }


  String _getCategoryName(
    int id,
  ) {
    final categories =
        ref.read(
          categoriesProvider,
        ).value;

    if (categories == null) {
      return 'دسته';
    }

    final cat =
        categories.firstWhere(
      (c) => c.id == id,
      orElse: () =>
          ProductCategory(
        id: 0,
        name: '',
      ),
    );

    return cat.name.isEmpty
        ? 'دسته'
        : cat.name;
  }


  // ===========================================================
  // Brand
  // ===========================================================

  void _onBrandChanged(
    int? value,
  ) {
    setState(() {
      _brandId = value;

      _selectedBrandName =
          value == null
              ? 'همه'
              : _getBrandName(value);
    });

    ref
        .read(
          productsBrandProvider
              .notifier,
        )
        .state = value;

    ref
        .read(
          productsPageProvider
              .notifier,
        )
        .state = 1;

    ref.invalidate(
      productsProvider,
    );
  }


  String _getBrandName(
    int id,
  ) {
    final brands =
        ref.read(
          brandsProvider,
        ).value;

    if (brands == null) {
      return 'برند';
    }

    final brand =
        brands.firstWhere(
      (b) => b.id == id,
      orElse: () =>
          ProductTag(
        id: 0,
        name: '',
      ),
    );

    return brand.name.isEmpty
        ? 'برند'
        : brand.name;
  }


  // ===========================================================
  // Status
  // ===========================================================

  void _onStatusChanged(
    String? value,
  ) {
    setState(() {
      _status = value;
    });

    ref
        .read(
          productsStatusProvider
              .notifier,
        )
        .state = value;

    ref
        .read(
          productsPageProvider
              .notifier,
        )
        .state = 1;

    ref.invalidate(
      productsProvider,
    );
  }


  // ===========================================================
  // Per Page
  // ===========================================================

  void _onPerPageChanged(
    int value,
  ) {
    ref
        .read(
          productsPerPageProvider
              .notifier,
        )
        .state = value;

    ref
        .read(
          productsPageProvider
              .notifier,
        )
        .state = 1;

    ref.invalidate(
      productsProvider,
    );
  }


  // ===========================================================
  // Sort
  // ===========================================================

  void _onOrderByChanged(
    String? value,
  ) {
    if (value == null) {
      return;
    }

    String orderby;
    String order;

    if (value == 'price-desc') {
      orderby = 'price';
      order = 'desc';
    } else {
      orderby = value;
      order = value == 'id'
          ? 'asc'
          : 'desc';
    }

    setState(() {
      _selectedOrderBy = orderby;
      _selectedOrder = order;
    });

    ref
        .read(
          productsOrderByProvider
              .notifier,
        )
        .state = orderby;

    ref
        .read(
          productsOrderProvider
              .notifier,
        )
        .state = order;

    ref
        .read(
          productsPageProvider
              .notifier,
        )
        .state = 1;

    ref.invalidate(
      productsProvider,
    );
  }


  // ===========================================================
  // View product on site
  // ===========================================================

  Future<void> _openProduct(Product product) async {
    final raw = product.permalink?.trim() ?? '';
    if (raw.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لینک محصول در دسترس نیست')),
      );
      return;
    }

    final uri = Uri.tryParse(raw);
    if (uri == null || !uri.hasScheme) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لینک محصول نامعتبر است')),
      );
      return;
    }

    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('باز کردن صفحه محصول انجام نشد')),
      );
    }
  }


  // ===========================================================
  // Delete
  // ===========================================================

  Future<void> _confirmDelete(
    Product product,
  ) async {
    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (ctx) =>
          AlertDialog(
        title: const Text(
          'حذف محصول',
        ),
        content: Text(
          'آیا از حذف "${product.name}" مطمئن هستید؟',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(
              ctx,
              false,
            ),
            child: const Text(
              'انصراف',
            ),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(
              ctx,
              true,
            ),
            child: const Text(
              'حذف',
              style: TextStyle(
                color: AppTheme.danger,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    final repo =
        ref.read(
      productRepositoryProvider,
    );

    await repo.deleteProduct(
      product.id,
    );

    ref.invalidate(
      productsProvider,
    );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      const SnackBar(
        content: Text(
          'محصول حذف شد',
        ),
      ),
    );
  }


  // ===========================================================
  // Category Dialog
  // ===========================================================

  void _openCategoryDialog() {
    final categoriesAsync =
        ref.read(
      categoriesProvider,
    );

    categoriesAsync.whenData(
      (categories) {
        if (categories.isEmpty) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(
            const SnackBar(
              content: Text(
                'هیچ دسته‌بندی یافت نشد',
              ),
            ),
          );

          return;
        }

        showDialog(
          context: context,
          builder: (ctx) =>
              AlertDialog(
            title: Row(
              children: [
                const Icon(
                  Icons.category,
                  color: AppTheme.primary,
                ),
                const SizedBox(
                  width: 8,
                ),
                Text(
                  'انتخاب دسته‌بندی (${categories.length})',
                ),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              height: 400,
              child: Container(
                decoration:
                    BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                  border: Border.all(
                    color:
                        AppTheme.border,
                  ),
                ),
                child:
                    CategoryTreeWidget(
                  categories:
                      categories,
                  selectedIds:
                      _categoryId != null
                          ? [_categoryId!]
                          : [],
                  onChanged: (ids) {
                    final selectedId =
                        ids.isNotEmpty
                            ? ids.first
                            : null;

                    _onCategoryChanged(
                      selectedId,
                    );

                    Navigator.pop(
                      ctx,
                    );
                  },
                ),
              ),
            ),
            actions: [
              TextButton.icon(
                onPressed: () {
                  _onCategoryChanged(
                    null,
                  );

                  Navigator.pop(
                    ctx,
                  );
                },
                icon: const Icon(
                  Icons.clear,
                ),
                label: const Text(
                  'حذف فیلتر',
                ),
              ),
            ],
          ),
        );
      },
    );
  }


  // ===========================================================
  // Brand Dialog
  // ===========================================================

  void _openBrandDialog() {
    final brandsAsync =
        ref.read(
      brandsProvider,
    );

    brandsAsync.whenData(
      (brands) {
        if (brands.isEmpty) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(
            const SnackBar(
              content: Text(
                'هیچ برندی یافت نشد',
              ),
            ),
          );

          return;
        }

        showDialog(
          context: context,
          builder: (ctx) =>
              AlertDialog(
            title: Row(
              children: [
                const Icon(
                  Icons.label,
                  color: AppTheme.secondary,
                ),
                const SizedBox(
                  width: 8,
                ),
                Text(
                  'انتخاب برند (${brands.length})',
                ),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              height: 300,
              child: Container(
                decoration:
                    BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                  border: Border.all(
                    color:
                        AppTheme.border,
                  ),
                ),
                child: ListView(
                  children: [
                    ListTile(
                      title:
                          const Text(
                        'همه',
                      ),
                      leading:
                          Radio<int?>(
                        value: null,
                        groupValue:
                            _brandId,
                        onChanged:
                            (value) {
                          _onBrandChanged(
                            null,
                          );

                          Navigator.pop(
                            ctx,
                          );
                        },
                      ),
                    ),
                    ...brands.map(
                      (brand) =>
                          ListTile(
                        title:
                            Text(
                          brand.name,
                        ),
                        leading:
                            Radio<int?>(
                          value:
                              brand.id,
                          groupValue:
                              _brandId,
                          onChanged:
                              (value) {
                            _onBrandChanged(
                              value,
                            );

                            Navigator.pop(
                              ctx,
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }


  // ===========================================================
  // Statistic Box
  // ===========================================================

  Widget _statBox({
    required IconData icon,
    required String label,
    required int value,
    required Color color,
  }) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 4,
      ),
      decoration:
          BoxDecoration(
        color: color.withOpacity(
          0.08,
        ),
        borderRadius:
            BorderRadius.circular(
          12,
        ),
      ),
      child: Row(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          const SizedBox(
            width: 4,
          ),
          Text(
            '$label: ${_toFa(value)}',
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight:
                  FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }


  // ===========================================================
  // Build
  // ===========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final productsAsync =
        ref.watch(
      productsProvider,
    );

    final categoriesAsync =
        ref.watch(
      categoriesProvider,
    );

    final brandsAsync =
        ref.watch(
      brandsProvider,
    );

    final perPage =
        ref.watch(
      productsPerPageProvider,
    );

    final currentPage =
        ref.watch(
      productsPageProvider,
    );


    return Scaffold(
      backgroundColor:
          AppTheme.background,

      appBar: AppBar(
        title:
            const Text('محصولات'),
        centerTitle: true,
        backgroundColor:
            AppTheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'ویژگی محصول',
            icon: const Icon(
              Icons.layers_outlined,
              color: AppTheme.primary,
            ),
            onPressed: () => context.go('/product-features'),
          ),
          IconButton(
            tooltip: 'محصول جدید',
            icon: const Icon(
              Icons.add,
              color:
                  AppTheme.primary,
            ),
            onPressed: () =>
                context.go(
              '/products/new',
            ),
          ),
        ],
      ),

      body: Column(
        children: [

          // =====================================================
          // Filters
          // =====================================================

          Container(
            color:
                AppTheme.surface,
            padding:
                const EdgeInsets.all(
              16,
            ),
            child: Column(
              children: [

                TextField(
                  controller:
                      _searchController,
                  onChanged:
                      _onSearchChanged,
                  decoration:
                      InputDecoration(
                    hintText:
                        'جستجوی محصول...',
                    prefixIcon:
                        const Icon(
                      Icons.search,
                    ),
                    border:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius
                              .circular(
                        12,
                      ),
                      borderSide:
                          const BorderSide(
                        color:
                            AppTheme.border,
                      ),
                    ),
                    filled: true,
                    fillColor:
                        AppTheme
                            .background,
                  ),
                  textDirection:
                      TextDirection.rtl,
                ),

                const SizedBox(
                  height: 12,
                ),

                Row(
                  children: [

                    Expanded(
                      child:
                          categoriesAsync
                              .when(
                        data: (_) =>
                            OutlinedButton
                                .icon(
                          onPressed:
                              _openCategoryDialog,
                          icon:
                              const Icon(
                            Icons.category,
                            size: 18,
                            color: AppTheme
                                .primary,
                          ),
                          label: Text(
                            _categoryId ==
                                    null
                                ? 'دسته‌بندی'
                                : _selectedCategoryName,
                            overflow:
                                TextOverflow
                                    .ellipsis,
                          ),
                          style:
                              OutlinedButton
                                  .styleFrom(
                            padding:
                                const EdgeInsets
                                    .symmetric(
                              vertical:
                                  12,
                            ),
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                12,
                              ),
                            ),
                            side:
                                BorderSide(
                              color: _categoryId ==
                                      null
                                  ? AppTheme
                                      .border
                                  : AppTheme
                                      .primary,
                              width: 2,
                            ),
                          ),
                        ),
                        loading: () =>
                            const OutlinedButton(
                          onPressed: null,
                          child:
                              SizedBox(
                            width: 20,
                            height: 20,
                            child:
                                CircularProgressIndicator(
                              strokeWidth:
                                  2,
                            ),
                          ),
                        ),
                        error:
                            (error, _) =>
                                OutlinedButton
                                    .icon(
                          onPressed: () {
                            ScaffoldMessenger
                                .of(
                              context,
                            ).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'خطا در بارگذاری دسته‌ها: $error',
                                ),
                              ),
                            );
                          },
                          icon:
                              const Icon(
                            Icons.error,
                            color:
                                Colors.red,
                            size: 18,
                          ),
                          label:
                              const Text(
                            'خطا در دسته‌ها',
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(
                      width: 12,
                    ),

                    Expanded(
                      child:
                          brandsAsync.when(
                        data: (_) =>
                            OutlinedButton
                                .icon(
                          onPressed:
                              _openBrandDialog,
                          icon:
                              const Icon(
                            Icons.label,
                            size: 18,
                            color: AppTheme
                                .secondary,
                          ),
                          label: Text(
                            _brandId ==
                                    null
                                ? 'برند'
                                : _selectedBrandName,
                            overflow:
                                TextOverflow
                                    .ellipsis,
                          ),
                          style:
                              OutlinedButton
                                  .styleFrom(
                            padding:
                                const EdgeInsets
                                    .symmetric(
                              vertical:
                                  12,
                            ),
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                12,
                              ),
                            ),
                            side:
                                BorderSide(
                              color: _brandId ==
                                      null
                                  ? AppTheme
                                      .border
                                  : AppTheme
                                      .secondary,
                              width: 2,
                            ),
                          ),
                        ),
                        loading: () =>
                            const OutlinedButton(
                          onPressed: null,
                          child:
                              SizedBox(
                            width: 20,
                            height: 20,
                            child:
                                CircularProgressIndicator(
                              strokeWidth:
                                  2,
                            ),
                          ),
                        ),
                        error:
                            (error, _) =>
                                OutlinedButton
                                    .icon(
                          onPressed: () {},
                          icon:
                              const Icon(
                            Icons.error,
                            color:
                                Colors.red,
                            size: 18,
                          ),
                          label:
                              const Text(
                            'خطا در برندها',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 12,
                ),

                Row(
                  children: [

                    Expanded(
                      child:
                          DropdownButtonFormField<
                              String?>(
                        initialValue:
                            _status,
                        decoration:
                            const InputDecoration(
                          labelText:
                              'وضعیت',
                          border:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius
                                    .all(
                              Radius
                                  .circular(
                                12,
                              ),
                            ),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem<
                              String?>(
                            value: null,
                            child:
                                Text(
                              'همه',
                            ),
                          ),
                          DropdownMenuItem<
                              String?>(
                            value:
                                'publish',
                            child:
                                Text(
                              'منتشر شده',
                            ),
                          ),
                          DropdownMenuItem<
                              String?>(
                            value:
                                'draft',
                            child:
                                Text(
                              'پیش‌نویس',
                            ),
                          ),
                        ],
                        onChanged:
                            _onStatusChanged,
                      ),
                    ),

                    const SizedBox(
                      width: 12,
                    ),

                    Expanded(
                      child:
                          DropdownButtonFormField<
                              int>(
                        initialValue:
                            perPage,
                        decoration:
                            const InputDecoration(
                          labelText:
                              'تعداد در صفحه',
                          border:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius
                                    .all(
                              Radius
                                  .circular(
                                12,
                              ),
                            ),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 5,
                            child:
                                Text('۵'),
                          ),
                          DropdownMenuItem(
                            value: 10,
                            child:
                                Text('۱۰'),
                          ),
                          DropdownMenuItem(
                            value: 20,
                            child:
                                Text('۲۰'),
                          ),
                          DropdownMenuItem(
                            value: 50,
                            child:
                                Text('۵۰'),
                          ),
                        ],
                        onChanged:
                            (value) {
                          if (value !=
                              null) {
                            _onPerPageChanged(
                              value,
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 12,
                ),

                DropdownButtonFormField<
                    String>(
                  initialValue:
                      _selectedOrderBy ==
                                  'price' &&
                              _selectedOrder ==
                                  'desc'
                          ? 'price-desc'
                          : _selectedOrderBy,
                  decoration:
                      const InputDecoration(
                    labelText:
                        'مرتب‌سازی بر اساس',
                    border:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius
                              .all(
                        Radius.circular(
                          12,
                        ),
                      ),
                    ),
                  ),
                  items:
                      _orderByOptions
                          .entries
                          .map(
                    (entry) =>
                        DropdownMenuItem<
                            String>(
                      value:
                          entry.key,
                      child: Text(
                        entry.value,
                      ),
                    ),
                  ).toList(),
                  onChanged:
                      _onOrderByChanged,
                ),
              ],
            ),
          ),


          // =====================================================
          // Product List
          // =====================================================

          Expanded(
            child:
                productsAsync.when(
              loading: () =>
                  const Center(
                child:
                    CircularProgressIndicator(
                  color:
                      AppTheme.primary,
                ),
              ),

              error:
                  (error, stack) =>
                      Center(
                child: Padding(
                  padding:
                      const EdgeInsets
                          .all(
                    20,
                  ),
                  child: Column(
                    mainAxisAlignment:
                        MainAxisAlignment
                            .center,
                    children: [
                      const Icon(
                        Icons
                            .error_outline,
                        color:
                            AppTheme.danger,
                        size: 48,
                      ),
                      const SizedBox(
                        height: 12,
                      ),
                      Text(
                        'خطا در دریافت محصولات:\n${error.toString()}',
                        textAlign:
                            TextAlign
                                .center,
                      ),
                      const SizedBox(
                        height: 12,
                      ),
                      ElevatedButton(
                        onPressed: () =>
                            ref.invalidate(
                          productsProvider,
                        ),
                        child:
                            const Text(
                          'تلاش مجدد',
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              data: (products) {

                if (products.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment
                              .center,
                      children: [
                        Icon(
                          Icons
                              .inbox_outlined,
                          size: 64,
                          color: AppTheme
                              .textSecondary,
                        ),
                        SizedBox(
                          height: 12,
                        ),
                        Text(
                          'محصولی یافت نشد',
                          style:
                              TextStyle(
                            color: AppTheme
                                .textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }


                return ListView.builder(
                  padding:
                      const EdgeInsets
                          .all(
                    16,
                  ),
                  itemCount:
                      products.length,

                  itemBuilder:
                      (context, index) {

                    final product =
                        products[index];

                    final isSale =
                        product.salePrice
                                ?.isNotEmpty ??
                            false;

                    final categoryNames =
                        product.categories
                            .map(
                              (c) =>
                                  c.name,
                            )
                            .join(
                              ' · ',
                            );

                    final imageUrl =
                        product.images
                                .isNotEmpty
                            ? product
                                .images
                                .first
                                .src
                            : null;


                    return Container(
                      margin:
                          const EdgeInsets
                              .only(
                        bottom: 12,
                      ),
                      padding:
                          const EdgeInsets
                              .all(
                        12,
                      ),
                      decoration:
                          BoxDecoration(
                        color:
                            Colors.white,
                        borderRadius:
                            BorderRadius
                                .circular(
                          16,
                        ),
                        border:
                            Border.all(
                          color: AppTheme
                              .border,
                        ),
                      ),

                      child: Row(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [

                          // ===================================
                          // Image
                          // ===================================

                          Container(
                            width: 80,
                            height: 80,
                            decoration:
                                BoxDecoration(
                              color: AppTheme
                                  .background,
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                8,
                              ),
                              border:
                                  Border.all(
                                color: AppTheme
                                    .border,
                              ),
                            ),
                            child:
                                imageUrl !=
                                        null &&
                                    imageUrl
                                        .isNotEmpty
                                ? ClipRRect(
                                    borderRadius:
                                        BorderRadius
                                            .circular(
                                      8,
                                    ),
                                    child:
                                        Image.network(
                                      imageUrl,
                                      width:
                                          80,
                                      height:
                                          80,
                                      fit: BoxFit
                                          .cover,
                                      errorBuilder:
                                          (
                                        _,
                                        __,
                                        ___,
                                      ) =>
                                              const Icon(
                                        Icons
                                            .image_not_supported,
                                        size:
                                            40,
                                        color: AppTheme
                                            .textSecondary,
                                      ),
                                    ),
                                  )
                                : const Icon(
                                    Icons
                                        .image_not_supported,
                                    size: 40,
                                    color: AppTheme
                                        .textSecondary,
                                  ),
                          ),

                          const SizedBox(
                            width: 12,
                          ),


                          // ===================================
                          // Product Information
                          // ===================================

                          Expanded(
                            child:
                                Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                              children: [

                                // -------------------------------
                                // Name + Status
                                // -------------------------------

                                Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,
                                  children: [

                                    Expanded(
                                      child:
                                          GestureDetector(
                                        onTap: () =>
                                            context.go(
                                          '/products/${product.id}',
                                        ),
                                        child:
                                            Text(
                                          product
                                              .name,
                                          style:
                                              const TextStyle(
                                            fontSize:
                                                16,
                                            fontWeight:
                                                FontWeight
                                                    .bold,
                                            color:
                                                AppTheme
                                                    .textPrimary,
                                          ),
                                          maxLines:
                                              2,
                                          overflow:
                                              TextOverflow
                                                  .ellipsis,
                                        ),
                                      ),
                                    ),

                                    const SizedBox(
                                      width: 8,
                                    ),

                                    Container(
                                      padding:
                                          const EdgeInsets
                                              .symmetric(
                                        horizontal:
                                            8,
                                        vertical:
                                            4,
                                      ),
                                      decoration:
                                          BoxDecoration(
                                        color: product
                                                    .status ==
                                                'publish'
                                            ? AppTheme
                                                .success
                                                .withOpacity(
                                                0.1,
                                              )
                                            : AppTheme
                                                .textSecondary
                                                .withOpacity(
                                                0.1,
                                              ),
                                        borderRadius:
                                            BorderRadius
                                                .circular(
                                          8,
                                        ),
                                      ),
                                      child:
                                          Text(
                                        product.status ==
                                                'publish'
                                            ? 'منتشر شده'
                                            : 'پیش‌نویس',
                                        style:
                                            TextStyle(
                                          fontSize:
                                              12,
                                          color: product
                                                      .status ==
                                                  'publish'
                                              ? AppTheme
                                                  .success
                                              : AppTheme
                                                  .textSecondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),


                                const SizedBox(
                                  height: 4,
                                ),


                                // -------------------------------
                                // Categories
                                // -------------------------------

                                Text(
                                  categoryNames
                                          .isNotEmpty
                                      ? categoryNames
                                      : 'بدون دسته',
                                  style:
                                      const TextStyle(
                                    fontSize:
                                        13,
                                    color:
                                        AppTheme
                                            .textSecondary,
                                  ),
                                ),


                                const SizedBox(
                                  height: 4,
                                ),


                                // -------------------------------
                                // Price
                                // -------------------------------

                                Text(
                                  isSale
                                      ? _formatPrice(
                                          product
                                              .salePrice!,
                                        )
                                      : _formatPrice(
                                          product
                                              .regularPrice,
                                        ),
                                  style:
                                      TextStyle(
                                    fontSize:
                                        16,
                                    fontWeight:
                                        FontWeight
                                            .bold,
                                    color: isSale
                                        ? AppTheme
                                            .cta
                                        : AppTheme
                                            .primary,
                                  ),
                                ),


                                const SizedBox(
                                  height: 6,
                                ),


                                // =================================================
                                // Statistics
                                // =================================================

                                Wrap(
                                  spacing: 8,
                                  runSpacing: 6,
                                  children: [

                                    // -----------------------------
                                    // Stock
                                    // -----------------------------

                                    _statBox(
                                      icon: Icons
                                          .inventory_2_outlined,
                                      label:
                                          'موجودی',
                                      value:
                                          product.stockQuantity ??
                                              0,
                                      color:
                                          (product.stockQuantity ??
                                                      0) >
                                                  0
                                              ? AppTheme
                                                  .success
                                              : AppTheme
                                                  .danger,
                                    ),


                                    // -----------------------------
                                    // Sales
                                    // -----------------------------

                                    _statBox(
                                      icon: Icons
                                          .shopping_cart_outlined,
                                      label:
                                          'فروش',
                                      value:
                                          product.totalSales ??
                                              0,
                                      color:
                                          AppTheme
                                              .primary,
                                    ),


                                    // -----------------------------
                                    // Views
                                    // -----------------------------

                                    _statBox(
                                      icon: Icons
                                          .visibility_outlined,
                                      label:
                                          'بازدید',
                                      value:
                                          product.viewCount ??
                                              0,
                                      color:
                                          AppTheme
                                              .secondary,
                                    ),
                                  ],
                                ),


                                const SizedBox(
                                  height: 8,
                                ),


                                // -------------------------------
                                // Actions
                                // -------------------------------

                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment
                                          .end,
                                  children: [

                                    if (product.permalink != null && product.permalink!.isNotEmpty)
                                      TextButton.icon(
                                        onPressed: () async {
                                          final uri = Uri.tryParse(product.permalink!);
                                          if (uri != null) {
                                            await launchUrl(
                                              uri,
                                              mode: LaunchMode.externalApplication,
                                            );
                                          }
                                        },
                                        icon: const Icon(
                                          Icons.open_in_new_rounded,
                                          size: 16,
                                        ),
                                        label: const Text('مشاهده در سایت'),
                                      ),
                                    const SizedBox(width: 4),
                                    TextButton
                                        .icon(
                                      onPressed:
                                          () =>
                                              context.go(
                                        '/products/${product.id}/edit',
                                      ),
                                      icon:
                                          const Icon(
                                        Icons.edit,
                                        size:
                                            16,
                                      ),
                                      label:
                                          const Text(
                                        'ویرایش',
                                      ),
                                    ),

                                    const SizedBox(
                                      width: 4,
                                    ),

                                    TextButton
                                        .icon(
                                      onPressed:
                                          () =>
                                              _confirmDelete(
                                        product,
                                      ),
                                      icon:
                                          const Icon(
                                        Icons
                                            .delete_outline,
                                        size:
                                            16,
                                        color:
                                            AppTheme
                                                .danger,
                                      ),
                                      label:
                                          const Text(
                                        'حذف',
                                        style:
                                            TextStyle(
                                          color:
                                              AppTheme
                                                  .danger,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),


          // =====================================================
          // Pagination
          // =====================================================

          Container(
            padding:
                const EdgeInsets
                    .symmetric(
              vertical: 12,
            ),
            color:
                AppTheme.surface,
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment
                      .center,
              children: [

                IconButton(
                  onPressed: () {
                    ref
                        .read(
                          productsPageProvider
                              .notifier,
                        )
                        .state++;

                    ref.invalidate(
                      productsProvider,
                    );
                  },
                  icon: const Icon(
                    Icons.chevron_left,
                  ),
                  tooltip:
                      'صفحه بعد',
                ),

                Text(
                  'صفحه ${_toFa(currentPage)}',
                  style:
                      const TextStyle(
                    fontSize: 14,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                IconButton(
                  onPressed:
                      currentPage > 1
                          ? () {
                              ref
                                  .read(
                                    productsPageProvider
                                        .notifier,
                                  )
                                  .state--;

                              ref.invalidate(
                                productsProvider,
                              );
                            }
                          : null,
                  icon:
                      const Icon(
                    Icons.chevron_right,
                  ),
                  tooltip:
                      'صفحه قبل',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}