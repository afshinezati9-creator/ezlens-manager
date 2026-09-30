import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../data/campaign_models.dart';
import '../data/campaign_repository.dart';

class BookDetailPage extends ConsumerStatefulWidget {
  final int bookId;
  const BookDetailPage({super.key, required this.bookId});

  @override
  ConsumerState<BookDetailPage> createState() => _BookDetailPageState();
}

class _BookDetailPageState extends ConsumerState<BookDetailPage> {
  ContactBook? _book;
  List<BookContact> _contacts = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data =
          await ref.read(campaignRepositoryProvider).fetchBook(widget.bookId);
      final book = data['book'] is Map
          ? ContactBook.fromJson(Map<String, dynamic>.from(data['book'] as Map))
          : null;
      final contacts = <BookContact>[];
      if (data['contacts'] is List) {
        for (final e in data['contacts'] as List) {
          if (e is Map) {
            contacts.add(BookContact.fromJson(Map<String, dynamic>.from(e)));
          }
        }
      }
      if (!mounted) return;
      setState(() {
        _book = book;
        _contacts = contacts;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_book?.name ?? 'دفترچه'),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/campaign'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.campaign_outlined, color: AppColors.primary),
            onPressed: () =>
                context.go('/campaign/new?bookId=${widget.bookId}'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _contacts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final c = _contacts[i];
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c.name.isEmpty ? 'بدون نام' : c.name,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          if (c.email.isNotEmpty)
                            Text(c.email,
                                textDirection: TextDirection.ltr,
                                textAlign: TextAlign.right,
                                style: const TextStyle(fontSize: 12)),
                          if (c.phone.isNotEmpty)
                            Text(c.phone,
                                textDirection: TextDirection.ltr,
                                textAlign: TextAlign.right,
                                style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
