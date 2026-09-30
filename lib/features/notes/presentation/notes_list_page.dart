import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_error_state.dart';
import '../data/note_models.dart';
import 'notes_provider.dart';
import 'widgets/note_card.dart';
import 'widgets/note_stats_cards.dart';
import 'widgets/note_skeleton.dart';
import 'note_detail_page.dart';
import 'note_form_page.dart';

class NotesListPage extends ConsumerStatefulWidget {
  const NotesListPage({super.key});

  @override
  ConsumerState<NotesListPage> createState() => _NotesListPageState();
}

class _NotesListPageState extends ConsumerState<NotesListPage> {
  final searchController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isGridView = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // برای بارگذاری خودکار صفحه بعدی (اختیاری)
  }

  Future<void> _refresh() async {
    ref.invalidate(notesProvider);
    await ref.read(notesProvider.future);
  }

  void _clearFilters() {
    searchController.clear();
    ref.read(notesSearchProvider.notifier).state = '';
    ref.read(notesColorProvider.notifier).state = 'all';
    ref.read(notesPriorityProvider.notifier).state = 'all';
    ref.read(notesTagProvider.notifier).state = 'all';
    ref.read(notesDueProvider.notifier).state = '';
    ref.read(notesPinnedProvider.notifier).state = false;
    ref.read(notesPageProvider.notifier).state = 1;
    ref.invalidate(notesProvider);
  }

  @override
  Widget build(BuildContext context) {
    final notesAsync = ref.watch(notesProvider);
    final colorFilter = ref.watch(notesColorProvider);
    final priorityFilter = ref.watch(notesPriorityProvider);
    final tagFilter = ref.watch(notesTagProvider);
    final dueFilter = ref.watch(notesDueProvider);
    final pinnedOnly = ref.watch(notesPinnedProvider);
    final page = ref.watch(notesPageProvider);
    final perPage = ref.watch(notesPerPageProvider);

    // استخراج لیست برچسب‌ها از داده‌های موجود
    List<String> allTags = [];
    if (notesAsync.hasValue) {
      final tagsSet = <String>{};
      for (var note in notesAsync.value!.items) {
        tagsSet.addAll(note.tags);
      }
      allTags = tagsSet.toList()..sort();
    }

    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('دفترچه یادداشت'),
        actions: [
          // دکمه Refresh
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _refresh,
            tooltip: 'بروزرسانی',
          ),
          // دکمه تغییر حالت نمایش (لیستی/دوستونه) - فقط در صفحه‌های بزرگ
          if (!isSmallScreen)
            IconButton(
              icon: Icon(_isGridView ? Icons.list : Icons.grid_view),
              onPressed: () => setState(() => _isGridView = !_isGridView),
              tooltip: _isGridView ? 'نمایش لیستی' : 'نمایش دوستونه',
            ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NoteFormPage()),
            ).then((_) => _refresh()),
            tooltip: 'یادداشت جدید',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: Column(
          children: [
            // ===== فیلترها =====
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.white,
              child: Column(
                children: [
                  // جستجو
                  TextField(
                    controller: searchController,
                    onChanged: (value) {
                      ref.read(notesSearchProvider.notifier).state = value;
                      ref.read(notesPageProvider.notifier).state = 1;
                      ref.invalidate(notesProvider);
                    },
                    decoration: InputDecoration(
                      hintText: 'جستجو در یادداشت‌ها...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                searchController.clear();
                                ref.read(notesSearchProvider.notifier).state = '';
                                ref.read(notesPageProvider.notifier).state = 1;
                                ref.invalidate(notesProvider);
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // فیلترهای افقی (اسکرول‌شونده در موبایل)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        // فیلتر رنگ
                        DropdownButton<String>(
                          value: colorFilter,
                          items: [
                            const DropdownMenuItem(value: 'all', child: Text('همه رنگ‌ها')),
                            ...NoteColor.values.map((c) => DropdownMenuItem(
                                  value: c.name,
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 14,
                                        height: 14,
                                        decoration: BoxDecoration(
                                          color: Color(int.parse(c.hex.replaceFirst('#', '0xFF'))),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(c.label, style: const TextStyle(fontSize: 12)),
                                    ],
                                  ),
                                )),
                          ],
                          onChanged: (value) {
                            ref.read(notesColorProvider.notifier).state = value ?? 'all';
                            ref.read(notesPageProvider.notifier).state = 1;
                            ref.invalidate(notesProvider);
                          },
                          underline: const SizedBox(),
                          iconSize: 18,
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(width: 6),
                        // فیلتر اولویت
                        DropdownButton<String>(
                          value: priorityFilter,
                          items: [
                            const DropdownMenuItem(value: 'all', child: Text('همه اولویت‌ها')),
                            ...NotePriority.values.map((p) => DropdownMenuItem(
                                  value: p.name,
                                  child: Text(p.label, style: const TextStyle(fontSize: 12)),
                                )),
                          ],
                          onChanged: (value) {
                            ref.read(notesPriorityProvider.notifier).state = value ?? 'all';
                            ref.read(notesPageProvider.notifier).state = 1;
                            ref.invalidate(notesProvider);
                          },
                          underline: const SizedBox(),
                          iconSize: 18,
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(width: 6),
                        // فیلتر برچسب
                        if (allTags.isNotEmpty)
                          DropdownButton<String>(
                            value: tagFilter,
                            items: [
                              const DropdownMenuItem(value: 'all', child: Text('همه برچسب‌ها')),
                              ...allTags.map((t) => DropdownMenuItem(
                                    value: t,
                                    child: Text('#$t', style: const TextStyle(fontSize: 12)),
                                  )),
                            ],
                            onChanged: (value) {
                              ref.read(notesTagProvider.notifier).state = value ?? 'all';
                              ref.read(notesPageProvider.notifier).state = 1;
                              ref.invalidate(notesProvider);
                            },
                            underline: const SizedBox(),
                            iconSize: 18,
                            style: const TextStyle(fontSize: 12),
                          ),
                        const SizedBox(width: 6),
                        // فیلتر سررسید
                        DropdownButton<String>(
                          value: dueFilter.isEmpty ? null : dueFilter,
                          hint: const Text('سررسید', style: TextStyle(fontSize: 12)),
                          items: const [
                            DropdownMenuItem(value: 'overdue', child: Text('معوق', style: TextStyle(fontSize: 12))),
                            DropdownMenuItem(value: 'today', child: Text('امروز', style: TextStyle(fontSize: 12))),
                            DropdownMenuItem(value: 'upcoming', child: Text('آینده', style: TextStyle(fontSize: 12))),
                          ],
                          onChanged: (value) {
                            ref.read(notesDueProvider.notifier).state = value ?? '';
                            ref.read(notesPageProvider.notifier).state = 1;
                            ref.invalidate(notesProvider);
                          },
                          underline: const SizedBox(),
                          iconSize: 18,
                        ),
                        const SizedBox(width: 6),
                        // فیلتر پین شده
                        FilterChip(
                          label: const Text('پین شده', style: TextStyle(fontSize: 11)),
                          selected: pinnedOnly,
                          onSelected: (selected) {
                            ref.read(notesPinnedProvider.notifier).state = selected;
                            ref.read(notesPageProvider.notifier).state = 1;
                            ref.invalidate(notesProvider);
                          },
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                        const SizedBox(width: 6),
                        // دکمه پاک کردن فیلترها
                        if (searchController.text.isNotEmpty ||
                            colorFilter != 'all' ||
                            priorityFilter != 'all' ||
                            tagFilter != 'all' ||
                            dueFilter.isNotEmpty ||
                            pinnedOnly)
                          IconButton(
                            icon: const Icon(Icons.clear_all, size: 18),
                            onPressed: _clearFilters,
                            tooltip: 'حذف فیلترها',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  // اطلاعات تعداد و صفحه‌بندی
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        notesAsync.hasValue
                            ? '${notesAsync.value!.total} یادداشت'
                            : 'در حال بارگذاری...',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Row(
                        children: [
                          const Text('تعداد: ', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          DropdownButton<int>(
                            value: perPage,
                            items: const [6, 10, 20, 50].map((e) {
                              return DropdownMenuItem(value: e, child: Text('$e', style: TextStyle(fontSize: 12)));
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                ref.read(notesPerPageProvider.notifier).state = value;
                                ref.read(notesPageProvider.notifier).state = 1;
                                ref.invalidate(notesProvider);
                              }
                            },
                            underline: const SizedBox(),
                            iconSize: 16,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // ===== کارت‌های آماری =====
            if (notesAsync.hasValue)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: NoteStatsCards(
                  total: notesAsync.value!.total,
                  pinnedCount: notesAsync.value!.items.where((n) => n.pinned).length,
                  overdueCount: notesAsync.value!.items
                      .where((n) => n.dueDate != null &&
                          DateTime.parse(n.dueDate!).isBefore(DateTime.now()))
                      .length,
                  todayCount: notesAsync.value!.items
                      .where((n) => n.dueDate != null &&
                          DateTime.parse(n.dueDate!).day == DateTime.now().day &&
                          DateTime.parse(n.dueDate!).month == DateTime.now().month)
                      .length,
                ),
              ),
            // ===== لیست یادداشت‌ها =====
            Expanded(
              child: notesAsync.when(
                loading: () => const NoteSkeleton(),
                error: (e, _) => AppErrorState(
                  title: 'خطا در بارگذاری',
                  subtitle: e.toString(),
                  onRetry: _refresh,
                ),
                data: (data) {
                  if (data.items.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text(
                          'یادداشتی یافت نشد',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    );
                  }
                  return _isGridView && !isSmallScreen
                      ? GridView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(8),
                          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 300,
                            childAspectRatio: 1.1,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                          itemCount: data.items.length,
                          itemBuilder: (context, index) {
                            final note = data.items[index];
                            return NoteCard(
                              note: note,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => NoteDetailPage(noteId: note.id),
                                ),
                              ).then((_) => _refresh()),
                            );
                          },
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          itemCount: data.items.length,
                          itemBuilder: (context, index) {
                            final note = data.items[index];
                            return NoteCard(
                              note: note,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => NoteDetailPage(noteId: note.id),
                                ),
                              ).then((_) => _refresh()),
                            );
                          },
                        );
                },
              ),
            ),
            // ===== صفحه‌بندی =====
            if (notesAsync.hasValue)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left, size: 20),
                      onPressed: page > 1
                          ? () {
                              ref.read(notesPageProvider.notifier).state = page - 1;
                              ref.invalidate(notesProvider);
                            }
                          : null,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 40),
                    ),
                    Text(
                      'صفحه $page از ${notesAsync.value!.totalPages}',
                      style: const TextStyle(fontSize: 13),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right, size: 20),
                      onPressed: page < notesAsync.value!.totalPages
                          ? () {
                              ref.read(notesPageProvider.notifier).state = page + 1;
                              ref.invalidate(notesProvider);
                            }
                          : null,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 40),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NoteFormPage()),
        ).then((_) => _refresh()),
        child: const Icon(Icons.add),
        tooltip: 'یادداشت جدید',
      ),
    );
  }
}