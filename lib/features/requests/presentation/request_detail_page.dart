import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/request_models.dart';
import 'requests_provider.dart';
import 'widgets/request_attachment_section.dart';
import 'widgets/request_status_badge.dart';
import 'widgets/request_notes_section.dart';

class RequestDetailPage extends ConsumerWidget {
  final int id;

  const RequestDetailPage({
    super.key,
    required this.id,
  });

  String _date(String? value) {
    if (value == null || value.isEmpty) {
      return '—';
    }

    final d = DateTime.tryParse(value);

    if (d == null) {
      return value;
    }

    final x = d.toLocal();

    return '${x.year}/${x.month.toString().padLeft(2, '0')}/${x.day.toString().padLeft(2, '0')} '
        '${x.hour.toString().padLeft(2, '0')}:${x.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _open(String? value) async {
    if (value == null || value.isEmpty) {
      return;
    }

    final uri = Uri.tryParse(value);

    if (uri == null) {
      return;
    }

    await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
  }

  Future<void> _status(
    BuildContext context,
    WidgetRef ref,
    RequestItem item,
    String status,
  ) async {
    try {
      await ref
          .read(requestRepositoryProvider)
          .updateStatus(
            item.id,
            status,
          );

      ref.invalidate(
        requestDetailProvider(item.id),
      );

      ref.invalidate(
        requestsProvider,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              'وضعیت ذخیره شد',
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            content: Text(
              'خطا: $e',
            ),
          ),
        );
      }
    }
  }

  Widget section(
    String title,
    Widget child,
  ) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(17),
        side: BorderSide(
          color: Colors.grey.shade200,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _row(
    String key,
    String value, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          vertical: 10,
        ),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Colors.grey.shade100,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 110,
              child: Text(
                key,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
            ),
            Expanded(
              child: SelectableText(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (onTap != null)
              const Icon(
                Icons.open_in_new_rounded,
                size: 16,
              ),
          ],
        ),
      ),
    );
  }

  Widget _sourcePageCard(
    RequestItem item,
  ) {
    if (item.sourcePageTitle == null && item.sourcePageUrl == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.web_outlined,
                size: 19,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 8),
              const Text(
                'صفحه مبدأ درخواست',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            item.displaySourcePage,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (item.sourcePageId != null) ...[
            const SizedBox(height: 4),
            Text(
              'شناسه صفحه: ${item.sourcePageId}',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
            ),
          ],
          if (item.sourcePageUrl != null &&
              item.sourcePageUrl!.isNotEmpty) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () =>
                  _open(item.sourcePageUrl),
              icon: const Icon(
                Icons.open_in_new,
                size: 17,
              ),
              label: const Text(
                'باز کردن صفحه',
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    final async =
        ref.watch(
      requestDetailProvider(id),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'درخواست #$id',
        ),
      ),
      body: async.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'خطا در دریافت درخواست\n$e',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (item) {
          // ===== ترکیب تمام داده‌های فرم =====
          final allFields = <String, dynamic>{};

          if (item.name != null && item.name!.isNotEmpty) {
            allFields['نام'] = item.name!;
          }
          if (item.email != null && item.email!.isNotEmpty) {
            allFields['ایمیل'] = item.email!;
          }
          if (item.phone != null && item.phone!.isNotEmpty) {
            allFields['تلفن'] = item.phone!;
          }
          if (item.message != null && item.message!.isNotEmpty) {
            allFields['پیام'] = item.message!;
          }

          final extraFields = <String, dynamic>{
            ...item.fields,
            ...item.meta,
          };

          extraFields.forEach((key, value) {
            if (!allFields.containsKey(key)) {
              allFields[key] = value;
            }
          });

          // ===== لاگ برای بررسی فایل‌ها =====
          print('📁 تعداد فایل‌های پیوست: ${item.files.length}');
          for (var file in item.files) {
            print('📎 نام: ${file.name}, URL: ${file.downloadUrl}');
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(
                requestDetailProvider(id),
              );
              await ref.read(
                requestDetailProvider(id).future,
              );
            },
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                // ============================================================
                // خلاصه درخواست
                // ============================================================
                section(
                  'خلاصه درخواست',
                  Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          RequestStatusBadge(
                            status: item.status,
                          ),
                          const Spacer(),
                          Text(
                            '#${item.id}',
                            style: TextStyle(
                              color:
                                  Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 13),
                      _row(
                        'فرم',
                        item.displayFormTitle,
                      ),
                      _row(
                        'شناسه فرم',
                        item.formId?.toString() ??
                            '—',
                      ),
                      _row(
                        'تاریخ و ساعت',
                        _date(
                          item.date ??
                              item.createdAt,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _sourcePageCard(item),
                    ],
                  ),
                ),

                // ============================================================
                // تغییر وضعیت
                // ============================================================
                section(
                  'تغییر وضعیت',
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: [
                      for (final x in const [
                        ('new', 'جدید'),
                        ('review', 'در حال بررسی'),
                        ('processed', 'بررسی شده'),
                        ('rejected', 'رد شده'),
                      ])
                        ChoiceChip(
                          label: Text(x.$2),
                          selected:
                              item.status == x.$1,
                          onSelected: (_) =>
                              _status(
                            context,
                            ref,
                            item,
                            x.$1,
                          ),
                        ),
                    ],
                  ),
                ),

                // ============================================================
                // اطلاعات کاربر
                // ============================================================
                section(
                  'اطلاعات کاربر',
                  Column(
                    children: [
                      if (item.name != null && item.name!.isNotEmpty)
                        _row(
                          'نام',
                          item.name!,
                        ),
                      if (item.phone != null && item.phone!.isNotEmpty)
                        _row(
                          'تلفن',
                          item.phone!,
                          onTap: () => _open(
                            'tel:${item.phone}',
                          ),
                        ),
                      if (item.email != null && item.email!.isNotEmpty)
                        _row(
                          'ایمیل',
                          item.email!,
                          onTap: () => _open(
                            'mailto:${item.email}',
                          ),
                        ),
                      if (item.phone != null &&
                          item.phone!.isNotEmpty)
                        Align(
                          alignment:
                              Alignment.centerLeft,
                          child:
                              OutlinedButton.icon(
                            onPressed: () => _open(
                              'tel:${item.phone}',
                            ),
                            icon: const Icon(
                              Icons.phone_outlined,
                            ),
                            label: const Text(
                              'تماس با مشتری',
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // ============================================================
                // پیام درخواست
                // ============================================================
                if (item.subject != null &&
                        item.subject!.isNotEmpty ||
                    (item.message != null &&
                        item.message!.isNotEmpty &&
                        !allFields.containsKey(
                          'پیام',
                        )))
                  section(
                    'پیام درخواست',
                    Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        if (item.subject != null &&
                            item.subject!.isNotEmpty) ...[
                          Text(
                            item.subject!,
                            style:
                                const TextStyle(
                              fontWeight:
                                  FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(
                            height: 8,
                          ),
                        ],
                        if (item.message != null &&
                            item.message!.isNotEmpty &&
                            !allFields.containsKey(
                              'پیام',
                            ))
                          SelectableText(
                            item.message!,
                            style:
                                const TextStyle(
                              height: 1.8,
                              fontSize: 13,
                            ),
                          ),
                      ],
                    ),
                  ),

                // ============================================================
                // اطلاعات کامل فرم
                // ============================================================
                if (allFields.isNotEmpty)
                  section(
                    'اطلاعات کامل فرم',
                    Column(
                      children: allFields.entries
                          .map(
                            (e) => _row(
                              e.key,
                              _formatValue(
                                e.value,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),

                // ============================================================
                // فایل‌های پیوست (با ویجت اختصاصی)
                // ============================================================
                RequestAttachmentSection(
                  files: item.files,
                ),

                // ============================================================
                // یادداشت‌ها
                // ============================================================
                RequestNotesSection(
                  requestId: item.id,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatValue(dynamic value) {
    if (value == null) {
      return '—';
    }

    if (value is List) {
      return value
          .map((e) => '$e')
          .join('، ');
    }

    if (value is Map) {
      return value.entries
          .map(
            (e) => '${e.key}: ${e.value}',
          )
          .join(' | ');
    }

    final text = value.toString();

    return text.isEmpty ? '—' : text;
  }
}