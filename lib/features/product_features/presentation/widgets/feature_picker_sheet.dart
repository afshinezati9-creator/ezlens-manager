import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/feature_models.dart';
import '../../data/feature_repository.dart';

/// Modal to multi-select product features and configure slots.
Future<List<ProductFeatureSlot>?> showFeaturePickerSheet(
  BuildContext context, {
  required List<ProductFeatureSlot> current,
}) {
  return showModalBottomSheet<List<ProductFeatureSlot>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _FeaturePickerSheet(initial: current),
  );
}

class _FeaturePickerSheet extends ConsumerStatefulWidget {
  final List<ProductFeatureSlot> initial;
  const _FeaturePickerSheet({required this.initial});

  @override
  ConsumerState<_FeaturePickerSheet> createState() => _FeaturePickerSheetState();
}

class _FeaturePickerSheetState extends ConsumerState<_FeaturePickerSheet> {
  final _search = TextEditingController();
  List<ProductFeature> _all = [];
  List<ProductFeatureSlot> _slots = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _slots = List.of(widget.initial);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await ref.read(productFeatureRepositoryProvider).fetchList(perPage: 100);
      setState(() {
        _all = res.items;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  bool _selected(int id) => _slots.any((s) => s.templateId == id);

  void _toggle(ProductFeature f) {
    setState(() {
      if (_selected(f.id)) {
        _slots.removeWhere((s) => s.templateId == f.id);
      } else {
        _slots.add(ProductFeatureSlot(
          templateId: f.id,
          title: f.title,
          label: f.title,
          placement: 'below_summary',
          display: 'inline',
          order: _slots.length + 1,
        ));
      }
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = _search.text.trim();
    final filtered = q.isEmpty
        ? _all
        : _all.where((f) => f.title.contains(q) || f.description.contains(q)).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollCtrl) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(4))),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text('انتخاب ویژگی محصول', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, _slots),
                      child: const Text('تأیید'),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'جستجو...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                        ? Center(child: Text(_error!))
                        : filtered.isEmpty
                            ? const Center(child: Text('موردی یافت نشد'))
                            : ListView.builder(
                                controller: scrollCtrl,
                                itemCount: filtered.length,
                                itemBuilder: (context, i) {
                                  final f = filtered[i];
                                  final sel = _selected(f.id);
                                  return CheckboxListTile(
                                    value: sel,
                                    onChanged: (_) => _toggle(f),
                                    title: Text(f.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                                    subtitle: f.description.isEmpty
                                        ? null
                                        : Text(f.description, maxLines: 1, overflow: TextOverflow.ellipsis),
                                    secondary: const Icon(Icons.layers_outlined, color: AppColors.primary),
                                  );
                                },
                              ),
              ),
              if (_slots.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  color: AppColors.background,
                  child: Text(
                    '${_slots.length} ویژگی انتخاب شد — بعد از تأیید، محل و نحوه نمایش را تنظیم کنید',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
