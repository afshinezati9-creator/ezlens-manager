import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../data/user_models.dart';
import '../data/user_repository.dart';
import 'users_provider.dart';

String _toFaDigits(String input) {
  const en = '0123456789';
  const fa = '۰۱۲۳۴۵۶۷۸۹';
  var out = input;
  for (var i = 0; i < 10; i++) {
    out = out.replaceAll(en[i], fa[i]);
  }
  return out;
}

String _jalali(DateTime? d) {
  if (d == null) return '—';
  final j = Jalali.fromDateTime(d.toLocal());
  final s =
      '${j.year}/${j.month.toString().padLeft(2, '0')}/${j.day.toString().padLeft(2, '0')}';
  return _toFaDigits(s);
}

String _jalaliWithTime(DateTime? d) {
  if (d == null) return '—';
  final local = d.toLocal();
  final j = Jalali.fromDateTime(local);
  final t =
      '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  final s =
      '${j.year}/${j.month.toString().padLeft(2, '0')}/${j.day.toString().padLeft(2, '0')}  $t';
  return _toFaDigits(s);
}

String _formatMoney(String price) {
  final n = double.tryParse(price) ?? 0;
  if (n == 0) return '۰ تومان';
  final formatted = n.toInt().toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );
  return '${_toFaDigits(formatted)} تومان';
}

class UsersListPage extends ConsumerStatefulWidget {
  const UsersListPage({super.key});

  @override
  ConsumerState<UsersListPage> createState() => _UsersListPageState();
}

class _UsersListPageState extends ConsumerState<UsersListPage> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      final q = ref.read(usersQueryProvider);
      ref.read(usersQueryProvider.notifier).state =
          q.copyWith(search: v.trim(), page: 1);
    });
  }

  Future<void> _confirmDelete(ManagerUser u) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف مشتری'),
        content: Text(
          '«${u.displayName}» برای همیشه حذف شود؟\nاین عمل قابل بازگشت نیست.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('انصراف'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('حذف کامل'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(userRepositoryProvider).deleteUser(u.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('مشتری حذف شد'),
          backgroundColor: AppColors.success,
        ),
      );
      ref.invalidate(usersListProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطا در حذف: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncList = ref.watch(usersListProvider);
    final query = ref.watch(usersQueryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('کاربران'),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/more'),
        ),
        actions: [
          IconButton(
            tooltip: 'افزودن مشتری',
            icon: const Icon(Icons.person_add_alt_1_outlined,
                color: AppColors.primary),
            onPressed: () => context.go('/users/new'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/users/new'),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.person_add_alt_1, color: Colors.white),
        label: const Text('مشتری جدید', style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  onChanged: _onSearch,
                  textDirection: TextDirection.rtl,
                  decoration: InputDecoration(
                    hintText: 'جستجو: نام، موبایل، ایمیل...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _Chip(
                        label: 'همه',
                        selected: query.role == 'all',
                        onTap: () => ref
                            .read(usersQueryProvider.notifier)
                            .state = query.copyWith(role: 'all', page: 1),
                      ),
                      _Chip(
                        label: 'مشتری',
                        selected: query.role == 'customer',
                        onTap: () => ref
                            .read(usersQueryProvider.notifier)
                            .state =
                            query.copyWith(role: 'customer', page: 1),
                      ),
                      _Chip(
                        label: 'مشترک',
                        selected: query.role == 'subscriber',
                        onTap: () => ref
                            .read(usersQueryProvider.notifier)
                            .state =
                            query.copyWith(role: 'subscriber', page: 1),
                      ),
                      const SizedBox(width: 8),
                      _Chip(
                        label: 'جدیدترین',
                        selected: query.orderby == 'registered_date' &&
                            query.order == 'desc',
                        onTap: () => ref
                            .read(usersQueryProvider.notifier)
                            .state = query.copyWith(
                          orderby: 'registered_date',
                          order: 'desc',
                          page: 1,
                        ),
                      ),
                      _Chip(
                        label: 'قدیمی‌ترین',
                        selected: query.orderby == 'registered_date' &&
                            query.order == 'asc',
                        onTap: () => ref
                            .read(usersQueryProvider.notifier)
                            .state = query.copyWith(
                          orderby: 'registered_date',
                          order: 'asc',
                          page: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: asyncList.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('خطا در دریافت کاربران\n$e',
                          textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () =>
                            ref.invalidate(usersListProvider),
                        child: const Text('تلاش مجدد'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (res) {
                if (res.items.isEmpty) {
                  return const Center(
                    child: Text(
                      'مشتری‌ای یافت نشد',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  );
                }
                return Column(
                  children: [
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () async =>
                            ref.invalidate(usersListProvider),
                        child: ListView.separated(
                          padding:
                              const EdgeInsets.fromLTRB(16, 12, 16, 96),
                          itemCount: res.items.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, i) {
                            final u = res.items[i];
                            return _UserCard(
                              user: u,
                              onOpen: () =>
                                  context.go('/users/${u.id}'),
                              onEdit: () =>
                                  context.go('/users/${u.id}/edit'),
                              onDelete: () => _confirmDelete(u),
                            );
                          },
                        ),
                      ),
                    ),
                    if (res.totalPages > 1)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              onPressed: query.page > 1
                                  ? () => ref
                                      .read(usersQueryProvider.notifier)
                                      .state = query.copyWith(
                                      page: query.page - 1)
                                  : null,
                              icon: const Icon(Icons.chevron_right),
                            ),
                            Text(
                              _toFaDigits(
                                  '${query.page} / ${res.totalPages}  (${res.total})'),
                              style: const TextStyle(
                                  color: AppColors.textSecondary),
                            ),
                            IconButton(
                              onPressed: query.page < res.totalPages
                                  ? () => ref
                                      .read(usersQueryProvider.notifier)
                                      .state = query.copyWith(
                                      page: query.page + 1)
                                  : null,
                              icon: const Icon(Icons.chevron_left),
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Chip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withOpacity(0.1)
                : AppColors.background,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color:
                  selected ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final ManagerUser user;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _UserCard({
    required this.user,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    backgroundImage: user.avatarUrl.isNotEmpty
                        ? NetworkImage(user.avatarUrl)
                        : null,
                    child: user.avatarUrl.isEmpty
                        ? Text(
                            user.displayName.isNotEmpty
                                ? user.displayName.characters.first
                                : '?',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.displayName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user.primaryPhone.isNotEmpty
                              ? _toFaDigits(user.primaryPhone)
                              : user.username,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                          textDirection: TextDirection.ltr,
                          textAlign: TextAlign.right,
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (v) {
                      if (v == 'edit') onEdit();
                      if (v == 'delete') onDelete();
                      if (v == 'open') onOpen();
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'open', child: Text('مشاهده')),
                      PopupMenuItem(value: 'edit', child: Text('ویرایش')),
                      PopupMenuItem(value: 'delete', child: Text('حذف')),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _Meta(
                    label: 'عضویت',
                    value: _jalali(user.dateCreated),
                  ),
                  _Meta(
                    label: 'آخرین ورود',
                    value: _jalaliWithTime(user.lastLogin),
                  ),
                  _Meta(
                    label: 'نقش',
                    value: user.role == 'customer'
                        ? 'مشتری'
                        : (user.role == 'subscriber' ? 'مشترک' : user.role),
                  ),
                  if (user.ordersCount > 0)
                    _Meta(
                      label: 'سفارش',
                      value: _toFaDigits('${user.ordersCount}'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  final String label;
  final String value;
  const _Meta({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
      ),
    );
  }
}
