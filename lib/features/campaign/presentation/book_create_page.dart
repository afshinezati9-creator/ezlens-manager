import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../data/campaign_models.dart';
import '../data/campaign_repository.dart';
import 'campaign_provider.dart';

class BookCreatePage extends ConsumerStatefulWidget {
  const BookCreatePage({super.key});

  @override
  ConsumerState<BookCreatePage> createState() => _BookCreatePageState();
}

class _BookCreatePageState extends ConsumerState<BookCreatePage> {
  final _nameCtrl = TextEditingController();
  final _manualName = TextEditingController();
  final _manualEmail = TextEditingController();
  final _manualPhone = TextEditingController();
  final _customerSearch = TextEditingController();

  final List<ContactDraft> _final = [];
  final Set<int> _selectedUsers = {};
  List<SiteCustomer> _customers = [];
  bool _loadingCustomers = false;
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _manualName.dispose();
    _manualEmail.dispose();
    _manualPhone.dispose();
    _customerSearch.dispose();
    super.dispose();
  }

  void _merge(ContactDraft c) {
    final k = c.key;
    if (_final.any((e) => e.key == k && k != '|')) return;
    setState(() => _final.add(c));
  }

  Future<void> _pickCsv() async {
    final result = await FilePicker.platform.pickFiles(
      withData: true,
      type: FileType.custom,
      allowedExtensions: const ['csv', 'txt'],
    );
    if (result == null || result.files.isEmpty) return;
    final bytes = result.files.first.bytes;
    if (bytes == null) return;
    final text = utf8.decode(bytes, allowMalformed: true);
    final lines = text.split(RegExp(r'\r?\n'));
    var added = 0;
    for (final line in lines) {
      final t = line.trim();
      if (t.isEmpty) continue;
      final parts = t.split(RegExp(r'[,;\t]'));
      if (parts.isEmpty) continue;
      // skip header
      if (parts.first.toLowerCase().contains('name') ||
          parts.first.toLowerCase().contains('نام')) {
        continue;
      }
      String name = '', email = '', phone = '';
      if (parts.length >= 3) {
        name = parts[0].trim();
        email = parts[1].trim();
        phone = parts[2].trim();
      } else if (parts.length == 2) {
        if (parts[1].contains('@')) {
          name = parts[0].trim();
          email = parts[1].trim();
        } else {
          name = parts[0].trim();
          phone = parts[1].trim();
        }
      } else {
        if (t.contains('@')) {
          email = t;
        } else {
          phone = t;
        }
      }
      if (email.isEmpty && phone.isEmpty) continue;
      _merge(ContactDraft(
          name: name, email: email, phone: phone, source: 'file'));
      added++;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$added مخاطب از فایل اضافه شد')),
    );
  }

  Future<void> _loadCustomers([String q = '']) async {
    setState(() => _loadingCustomers = true);
    try {
      final list = await ref
          .read(campaignRepositoryProvider)
          .fetchCustomers(search: q);
      if (!mounted) return;
      setState(() {
        _customers = list;
        _loadingCustomers = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingCustomers = false);
    }
  }

  void _addManual() {
    final email = _manualEmail.text.trim();
    final phone = _manualPhone.text.trim();
    if (email.isEmpty && phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ایمیل یا موبایل لازم است')),
      );
      return;
    }
    _merge(ContactDraft(
      name: _manualName.text.trim(),
      email: email,
      phone: phone,
      source: 'manual',
    ));
    _manualName.clear();
    _manualEmail.clear();
    _manualPhone.clear();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('نام دفترچه را وارد کنید')),
      );
      return;
    }
    final contacts = List<ContactDraft>.from(_final);
    // merge selected site users as user_ids (server will convert)
    final userIds = _selectedUsers.toList();
    // also add site selected into contacts for display consistency
    for (final c in _customers) {
      if (_selectedUsers.contains(c.id)) {
        contacts.add(ContactDraft(
          name: c.name,
          email: c.email,
          phone: c.phone,
          source: 'site',
          userId: c.id,
        ));
      }
    }
    if (contacts.isEmpty && userIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('حداقل یک مخاطب اضافه کنید')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(campaignRepositoryProvider).createBook(
            name: name,
            contacts: contacts.where((c) => c.source != 'site').toList(),
            userIds: userIds,
          );
      if (!mounted) return;
      ref.invalidate(booksProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('دفترچه ذخیره شد'),
          backgroundColor: AppColors.success,
        ),
      );
      context.go('/campaign');
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا: $e'), backgroundColor: AppColors.danger),
      );
    }
  }

  Widget _palette({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('دفترچه مخاطبان'),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/campaign'),
        ),
        actions: [
          IconButton(
            tooltip: 'کمپین',
            icon: const Icon(Icons.campaign_outlined, color: AppColors.primary),
            onPressed: () => context.go('/campaign/new'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameCtrl,
            decoration: InputDecoration(
              labelText: 'نام دفترچه مخاطبان',
              filled: true,
              fillColor: AppColors.surface,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 14),

          // Palette 1 - file
          _palette(
            title: 'پالت ۱ — آپلود فایل',
            child: OutlinedButton.icon(
              onPressed: _pickCsv,
              icon: const Icon(Icons.upload_file_outlined),
              label: const Text('انتخاب CSV (نام، ایمیل، موبایل)'),
            ),
          ),

          // Palette 2 - site customers
          _palette(
            title: 'پالت ۲ — مشتریان سایت',
            child: Column(
              children: [
                TextField(
                  controller: _customerSearch,
                  onChanged: (v) {
                    if (v.trim().length >= 2 || v.isEmpty) {
                      _loadCustomers(v.trim());
                    }
                  },
                  onTap: () {
                    if (_customers.isEmpty) _loadCustomers();
                  },
                  decoration: InputDecoration(
                    hintText: 'جستجوی مشتری',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                if (_loadingCustomers)
                  const Padding(
                    padding: EdgeInsets.all(8),
                    child: LinearProgressIndicator(minHeight: 2),
                  ),
                if (_customers.isNotEmpty)
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 220),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _customers.length,
                      itemBuilder: (context, i) {
                        final c = _customers[i];
                        final sel = _selectedUsers.contains(c.id);
                        return CheckboxListTile(
                          dense: true,
                          value: sel,
                          title: Text(c.name.isEmpty ? c.login : c.name),
                          subtitle: Text(
                              '${c.email}${c.phone.isNotEmpty ? ' · ${c.phone}' : ''}'),
                          onChanged: (v) {
                            setState(() {
                              if (v == true) {
                                _selectedUsers.add(c.id);
                              } else {
                                _selectedUsers.remove(c.id);
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          // Palette 3 - manual
          _palette(
            title: 'پالت ۳ — ورود دستی',
            child: Column(
              children: [
                TextField(
                  controller: _manualName,
                  decoration: const InputDecoration(
                      labelText: 'نام', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _manualEmail,
                  textDirection: TextDirection.ltr,
                  decoration: const InputDecoration(
                      labelText: 'ایمیل', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _manualPhone,
                  textDirection: TextDirection.ltr,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                      labelText: 'موبایل', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: ElevatedButton(
                    onPressed: _addManual,
                    child: const Text('افزودن به لیست'),
                  ),
                ),
              ],
            ),
          ),

          // Palette 4 - final
          _palette(
            title: 'پالت ۴ — لیست نهایی (${_final.length + _selectedUsers.length})',
            child: _final.isEmpty && _selectedUsers.isEmpty
                ? const Text('هنوز مخاطبی اضافه نشده',
                    style: TextStyle(color: AppColors.textMuted))
                : Column(
                    children: [
                      ..._final.asMap().entries.map((e) {
                        final c = e.value;
                        return ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(c.name.isEmpty ? c.email : c.name),
                          subtitle: Text('${c.email} ${c.phone}'.trim()),
                          trailing: IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () =>
                                setState(() => _final.removeAt(e.key)),
                          ),
                        );
                      }),
                      ..._selectedUsers.map((id) {
                        final c = _customers.where((x) => x.id == id);
                        final name = c.isEmpty
                            ? 'کاربر #$id'
                            : (c.first.name.isEmpty
                                ? c.first.login
                                : c.first.name);
                        return ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(name),
                          subtitle: const Text('مشتری سایت'),
                          trailing: IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () =>
                                setState(() => _selectedUsers.remove(id)),
                          ),
                        );
                      }),
                    ],
                  ),
          ),

          const SizedBox(height: 8),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('ذخیره دفترچه'),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
