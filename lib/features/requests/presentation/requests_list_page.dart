import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/request_models.dart';
import 'requests_provider.dart';
import 'widgets/request_card.dart';
import 'widgets/request_skeleton.dart';
import 'widgets/request_stats_cards.dart';
import 'request_detail_page.dart';

class RequestsListPage extends ConsumerStatefulWidget {
  const RequestsListPage({
    super.key,
  });

  @override
  ConsumerState<RequestsListPage> createState() =>
      _RequestsListPageState();
}

class _RequestsListPageState
    extends ConsumerState<RequestsListPage> {
  final searchController =
      TextEditingController();

  String? _selectedFormTitle;

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> refresh() async {
    ref.invalidate(requestsProvider);
    await ref.read(
      requestsProvider.future,
    );
  }

  String _toPersianDigits(String value) {
    const english = [
      '0',
      '1',
      '2',
      '3',
      '4',
      '5',
      '6',
      '7',
      '8',
      '9',
    ];

    const persian = [
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

    for (int i = 0;
        i < english.length;
        i++) {
      value = value.replaceAll(
        english[i],
        persian[i],
      );
    }

    return value;
  }

  String _jalaliDateTime(String? value) {
    if (value == null || value.isEmpty) {
      return '—';
    }

    final date = DateTime.tryParse(value);

    if (date == null) {
      return value;
    }

    final local = date.toLocal();

    final j = _gregorianToJalali(
      local.year,
      local.month,
      local.day,
    );

    final result =
        '${j[0].toString().padLeft(4, '0')}/'
        '${j[1].toString().padLeft(2, '0')}/'
        '${j[2].toString().padLeft(2, '0')} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';

    return _toPersianDigits(result);
  }

  List<int> _gregorianToJalali(
    int gy,
    int gm,
    int gd,
  ) {
    final gdm = const [
      0,
      31,
      59,
      90,
      120,
      151,
      181,
      212,
      243,
      273,
      304,
      334,
    ];

    int gy2 = gm > 2 ? gy + 1 : gy;

    int days = 355666 +
        (365 * gy) +
        ((gy2 + 3) ~/ 4) -
        ((gy2 + 99) ~/ 100) +
        ((gy2 + 399) ~/ 400) +
        gd +
        gdm[gm - 1];

    int jy = -1595 +
        (33 * (days ~/ 12053));

    days %= 12053;

    jy += 4 * (days ~/ 1461);

    days %= 1461;

    if (days > 365) {
      jy += (days - 1) ~/ 365;
      days = (days - 1) % 365;
    }

    int jm;
    int jd;

    if (days < 186) {
      jm = 1 + (days ~/ 31);
      jd = 1 + (days % 31);
    } else {
      jm = 7 + ((days - 186) ~/ 30);
      jd = 1 + ((days - 186) % 30);
    }

    return [
      jy,
      jm,
      jd,
    ];
  }

  Future<void> _pickDate({
    required bool from,
  }) async {
    final now = DateTime.now();

    final picked =
        await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: now,
      helpText: from
          ? 'انتخاب تاریخ شروع'
          : 'انتخاب تاریخ پایان',
      cancelText: 'انصراف',
      confirmText: 'انتخاب',
    );

    if (picked == null) {
      return;
    }

    final j = _gregorianToJalali(
      picked.year,
      picked.month,
      picked.day,
    );

    final value =
        '${j[0].toString().padLeft(4, '0')}/'
        '${j[1].toString().padLeft(2, '0')}/'
        '${j[2].toString().padLeft(2, '0')}';

    if (from) {
      ref
          .read(
            requestsDateFromProvider
                .notifier,
          )
          .state = value;
    } else {
      ref
          .read(
            requestsDateToProvider
                .notifier,
          )
          .state = value;
    }

    ref
        .read(
          requestsPageProvider.notifier,
        )
        .state = 1;

    ref.invalidate(
      requestsProvider,
    );
  }

  Future<void> _changeStatus(
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
        requestsProvider,
      );

      ref.invalidate(
        requestDetailProvider(item.id),
      );

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              'وضعیت تغییر کرد',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
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

  Future<void> _delete(
    RequestItem item,
  ) async {
    final yes =
        await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(
          'حذف درخواست',
        ),
        content: Text(
          'درخواست «${item.name ?? '#${item.id}'}» حذف شود؟',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(
              context,
              false,
            ),
            child: const Text(
              'انصراف',
            ),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(
              context,
              true,
            ),
            child: const Text(
              'حذف',
            ),
          ),
        ],
      ),
    );

    if (yes != true) {
      return;
    }

    try {
      await ref
          .read(requestRepositoryProvider)
          .deleteRequest(
            item.id,
          );

      ref.invalidate(
        requestsProvider,
      );

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              'درخواست حذف شد',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
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

  void _clearFilters() {
    searchController.clear();
    _selectedFormTitle = null;

    ref
        .read(
          requestsSearchProvider.notifier,
        )
        .state = '';

    ref
        .read(
          requestsStatusProvider.notifier,
        )
        .state = 'all';

    ref
        .read(
          requestsDateFromProvider.notifier,
        )
        .state = '';

    ref
        .read(
          requestsDateToProvider.notifier,
        )
        .state = '';

    ref
        .read(
          requestsFormTitleProvider.notifier,
        )
        .state = '';

    ref
        .read(
          requestsPageProvider.notifier,
        )
        .state = 1;

    ref.invalidate(
      requestsProvider,
    );

    setState(() {});
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final async =
        ref.watch(requestsProvider);

    final status =
        ref.watch(requestsStatusProvider);

    final perPage =
        ref.watch(
      requestsPerPageProvider,
    );

    final page =
        ref.watch(
      requestsPageProvider,
    );

    final from =
        ref.watch(
      requestsDateFromProvider,
    );

    final to =
        ref.watch(
      requestsDateToProvider,
    );

    final formTitle =
        ref.watch(
      requestsFormTitleProvider,
    );

    final hasFilter =
        searchController.text.isNotEmpty ||
        status != 'all' ||
        from.isNotEmpty ||
        to.isNotEmpty ||
        formTitle.isNotEmpty;

    // ===== استخراج لیست فرم‌ها از داده‌های موجود =====
    List<String> formTitles = [];
    if (async.hasValue) {
      final items = async.value!.items;
      final uniqueTitles = items
          .map((item) => item.formTitle ?? '')
          .where((title) => title.isNotEmpty)
          .toSet()
          .toList();
      uniqueTitles.sort();
      formTitles = uniqueTitles;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'درخواست‌ها',
        ),
        actions: [
          IconButton(
            tooltip: 'بروزرسانی',
            onPressed: refresh,
            icon: const Icon(
              Icons.refresh_rounded,
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: refresh,
        child: ListView(
          padding:
              const EdgeInsets.fromLTRB(
            12,
            12,
            12,
            30,
          ),
          children: [
            // ============================================================
            // باکس‌های آماری (ریسپانسیو)
            // ============================================================
            async.when(
              loading: () =>
                  const RequestSkeleton(),
              error: (_, __) =>
                  const SizedBox.shrink(),
              data: (data) =>
                  RequestStatsCards(
                counts: data.counts,
                total: data.total,
              ),
            ),

            const SizedBox(
              height: 12,
            ),

            // ============================================================
            // جستجوی عمومی (نام، ایمیل، تلفن، پیام)
            // ============================================================
            TextField(
              controller:
                  searchController,
              onChanged: (value) {
                ref
                    .read(
                      requestsSearchProvider
                          .notifier,
                    )
                    .state = value;

                ref
                    .read(
                      requestsPageProvider
                          .notifier,
                    )
                    .state = 1;

                Future<void>.delayed(
                  const Duration(
                    milliseconds: 450,
                  ),
                  () {
                    if (!mounted) {
                      return;
                    }

                    if (searchController
                            .text ==
                        value) {
                      ref.invalidate(
                        requestsProvider,
                      );
                    }
                  },
                );

                setState(() {});
              },
              decoration:
                  InputDecoration(
                hintText:
                    'جستجو نام، ایمیل، تلفن، موضوع...',
                prefixIcon:
                    const Icon(
                  Icons.search,
                ),
                suffixIcon:
                    searchController
                            .text
                            .isEmpty
                        ? null
                        : IconButton(
                            onPressed:
                                () {
                              searchController
                                  .clear();

                              ref
                                  .read(
                                    requestsSearchProvider
                                        .notifier,
                                  )
                                  .state = '';

                              ref
                                  .read(
                                    requestsPageProvider
                                        .notifier,
                                  )
                                  .state = 1;

                              ref.invalidate(
                                requestsProvider,
                              );

                              setState(
                                () {},
                              );
                            },
                            icon:
                                const Icon(
                              Icons.clear,
                            ),
                          ),
                border:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),

            const SizedBox(
              height: 9,
            ),

            // ============================================================
            // فیلتر فرم با Dropdown
            // ============================================================
            DropdownButtonFormField<String>(
              value: _selectedFormTitle,
              hint: const Text('همه فرم‌ها'),
              decoration: InputDecoration(
                prefixIcon: const Icon(
                  Icons.description_outlined,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('همه فرم‌ها'),
                ),
                ...formTitles.map(
                  (title) => DropdownMenuItem<String>(
                    value: title,
                    child: Text(title),
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedFormTitle = value;
                });

                ref
                    .read(
                      requestsFormTitleProvider.notifier,
                    )
                    .state = value ?? '';

                ref
                    .read(
                      requestsPageProvider.notifier,
                    )
                    .state = 1;

                ref.invalidate(
                  requestsProvider,
                );
              },
            ),

            const SizedBox(
              height: 9,
            ),

            // ============================================================
            // فیلتر وضعیت
            // ============================================================
            SingleChildScrollView(
              scrollDirection:
                  Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text(
                      'همه',
                    ),
                    selected:
                        status == 'all',
                    onSelected: (_) {
                      ref
                          .read(
                            requestsStatusProvider
                                .notifier,
                          )
                          .state = 'all';

                      ref
                          .read(
                            requestsPageProvider
                                .notifier,
                          )
                          .state = 1;

                      ref.invalidate(
                        requestsProvider,
                      );
                    },
                  ),
                  const SizedBox(
                    width: 6,
                  ),
                  for (final x in const [
                    (
                      'new',
                      'جدید',
                    ),
                    (
                      'review',
                      'در حال بررسی',
                    ),
                    (
                      'processed',
                      'بررسی شده',
                    ),
                    (
                      'rejected',
                      'رد شده',
                    ),
                  ])
                    Padding(
                      padding:
                          const EdgeInsets.only(
                        right: 6,
                      ),
                      child: ChoiceChip(
                        label:
                            Text(x.$2),
                        selected:
                            status == x.$1,
                        onSelected:
                            (_) {
                          ref
                              .read(
                                requestsStatusProvider
                                    .notifier,
                              )
                              .state = x.$1;

                          ref
                              .read(
                                requestsPageProvider
                                    .notifier,
                              )
                              .state = 1;

                          ref.invalidate(
                            requestsProvider,
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            // ============================================================
            // فیلتر تاریخ
            // ============================================================
            Row(
              children: [
                Expanded(
                  child:
                      OutlinedButton.icon(
                    onPressed: () =>
                        _pickDate(
                      from: true,
                    ),
                    icon: const Icon(
                      Icons
                          .calendar_today_outlined,
                      size: 17,
                    ),
                    label: Text(
                      from.isEmpty
                          ? 'از تاریخ'
                          : from,
                    ),
                  ),
                ),
                const SizedBox(
                  width: 7,
                ),
                Expanded(
                  child:
                      OutlinedButton.icon(
                    onPressed: () =>
                        _pickDate(
                      from: false,
                    ),
                    icon: const Icon(
                      Icons
                          .event_outlined,
                      size: 17,
                    ),
                    label: Text(
                      to.isEmpty
                          ? 'تا تاریخ'
                          : to,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 8,
            ),

            // ============================================================
            // دکمه حذف فیلترها و انتخاب تعداد
            // ============================================================
            Row(
              children: [
                if (hasFilter)
                  TextButton.icon(
                    onPressed:
                        _clearFilters,
                    icon: const Icon(
                      Icons.clear_all,
                      size: 18,
                    ),
                    label: const Text(
                      'حذف فیلترها',
                    ),
                  ),

                const Spacer(),

                DropdownButton<int>(
                  value: perPage,
                  items: const [
                    5,
                    10,
                    20,
                    50,
                  ]
                      .map(
                        (e) =>
                            DropdownMenuItem(
                          value: e,
                          child:
                              Text('$e'),
                        ),
                      )
                      .toList(),
                  onChanged:
                      (value) {
                    if (value ==
                        null) {
                      return;
                    }

                    ref
                        .read(
                          requestsPerPageProvider
                              .notifier,
                        )
                        .state = value;

                    ref
                        .read(
                          requestsPageProvider
                              .notifier,
                        )
                        .state = 1;

                    ref.invalidate(
                      requestsProvider,
                    );
                  },
                ),
              ],
            ),

            const SizedBox(
              height: 12,
            ),

            // ============================================================
            // نمایش لیست درخواست‌ها
            // ============================================================
            async.when(
              loading: () =>
                  const RequestSkeleton(),

              error: (e, _) =>
                  Padding(
                padding:
                    const EdgeInsets.all(
                      30,
                    ),
                child: Center(
                  child: Text(
                    'خطا در دریافت درخواست‌ها\n$e',
                    textAlign:
                        TextAlign.center,
                  ),
                ),
              ),

              data: (data) {
                if (data.items.isEmpty) {
                  return const Padding(
                    padding:
                        EdgeInsets.all(
                          40,
                        ),
                    child: Center(
                      child: Text(
                        'درخواستی یافت نشد',
                      ),
                    ),
                  );
                }

                return Column(
                  children: [
                    ...data.items.map(
                      (item) =>
                          RequestCard(
                        item: item,
                        onTap: () =>
                            Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                RequestDetailPage(
                              id: item.id,
                            ),
                          ),
                        ),
                        onProcess: () =>
                            _changeStatus(
                          item,
                          'processed',
                        ),
                        onReject: () =>
                            _changeStatus(
                          item,
                          'rejected',
                        ),
                        onDelete: () =>
                            _delete(item),
                      ),
                    ),

                    const SizedBox(
                      height: 8,
                    ),

                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment
                              .center,
                      children: [
                        IconButton(
                          onPressed:
                              page > 1
                                  ? () {
                                      ref
                                          .read(
                                            requestsPageProvider
                                                .notifier,
                                          )
                                          .state =
                                          page -
                                              1;
                                    }
                                  : null,
                          icon:
                              const Icon(
                            Icons
                                .chevron_right,
                          ),
                        ),

                        Text(
                          'صفحه $page از ${data.totalPages}',
                        ),

                        IconButton(
                          onPressed:
                              page <
                                      data.totalPages
                                  ? () {
                                      ref
                                          .read(
                                            requestsPageProvider
                                                .notifier,
                                          )
                                          .state =
                                          page +
                                              1;
                                    }
                                  : null,
                          icon:
                              const Icon(
                            Icons
                                .chevron_left,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}