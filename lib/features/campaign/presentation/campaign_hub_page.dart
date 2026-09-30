import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../data/campaign_models.dart';
import '../data/campaign_repository.dart';
import 'campaign_provider.dart';

String _fa(String s) {
  const en = '0123456789';
  const fa = '۰۱۲۳۴۵۶۷۸۹';
  var o = s;
  for (var i = 0; i < 10; i++) {
    o = o.replaceAll(en[i], fa[i]);
  }
  return o;
}

class CampaignHubPage extends ConsumerStatefulWidget {
  const CampaignHubPage({super.key});

  @override
  ConsumerState<CampaignHubPage> createState() => _CampaignHubPageState();
}

class _CampaignHubPageState extends ConsumerState<CampaignHubPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _deleteBook(ContactBook b) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف دفترچه'),
        content: Text('«${b.name}» حذف شود؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(campaignRepositoryProvider).deleteBook(b.id);
      ref.invalidate(booksProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('دفترچه حذف شد'), backgroundColor: AppColors.success),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا: $e'), backgroundColor: AppColors.danger),
      );
    }
  }

  Future<void> _deleteCampaign(CampaignItem c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف کمپین'),
        content: Text('«${c.name}» حذف شود؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(campaignRepositoryProvider).deleteCampaign(c.id);
      ref.invalidate(campaignsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('کمپین حذف شد'), backgroundColor: AppColors.success),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا: $e'), backgroundColor: AppColors.danger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final booksAsync = ref.watch(booksProvider);
    final campaignsAsync = ref.watch(campaignsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('کمپین'),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/more'),
        ),
        actions: [
          IconButton(
            tooltip: 'دفترچه جدید',
            icon: const Icon(Icons.contact_page_outlined, color: AppColors.primary),
            onPressed: () => context.go('/campaign/book/new'),
          ),
          IconButton(
            tooltip: 'کمپین جدید',
            icon: const Icon(Icons.campaign_outlined, color: AppColors.primary),
            onPressed: () => context.go('/campaign/new'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(booksProvider);
              ref.invalidate(campaignsProvider);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'مخاطبان'),
            Tab(text: 'کمپین‌ها'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          // Books
          booksAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('$e')),
            data: (books) {
              if (books.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('دفترچه‌ای نیست',
                          style: TextStyle(color: AppColors.textMuted)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => context.go('/campaign/book/new'),
                        child: const Text('ایجاد دفترچه'),
                      ),
                    ],
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(booksProvider),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: books.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final b = books[i];
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  b.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700, fontSize: 15),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    color: AppColors.danger, size: 20),
                                onPressed: () => _deleteBook(b),
                              ),
                            ],
                          ),
                          Text(
                            '${_fa('${b.contactCount}')} مخاطب · ${b.createdFa.isNotEmpty ? b.createdFa : b.createdAt}',
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () =>
                                      context.go('/campaign/book/${b.id}'),
                                  icon: const Icon(Icons.people_outline, size: 18),
                                  label: const Text('مخاطبان'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => context.go(
                                      '/campaign/new?bookId=${b.id}'),
                                  icon: const Icon(Icons.campaign_outlined,
                                      size: 18, color: Colors.white),
                                  label: const Text('کمپین',
                                      style: TextStyle(color: Colors.white)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),
          // Campaigns
          campaignsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('$e')),
            data: (items) {
              if (items.isEmpty) {
                return const Center(
                  child: Text('کمپینی ثبت نشده',
                      style: TextStyle(color: AppColors.textMuted)),
                );
              }
              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(campaignsProvider),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final c = items[i];
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  c.typeLabel,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  c.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    color: AppColors.danger, size: 20),
                                onPressed: () => _deleteCampaign(c),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'موفق: ${_fa('${c.sent}')} از ${_fa('${c.total}')} · ${c.statusLabel}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          Text(
                            c.createdFa.isNotEmpty ? c.createdFa : c.createdAt,
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
