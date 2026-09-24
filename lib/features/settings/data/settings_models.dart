library;

class AppModuleInfo {
  final String id;
  final String title;
  final String subtitle;
  final String route;
  final String category;

  const AppModuleInfo({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.route,
    required this.category,
  });
}

/// All manager modules exposed in Settings.
const kAppModules = <AppModuleInfo>[
  AppModuleInfo(
    id: 'products',
    title: 'محصولات',
    subtitle: 'لیست و ویرایش محصولات ووکامرس',
    route: '/products',
    category: 'فروشگاه',
  ),
  AppModuleInfo(
    id: 'orders',
    title: 'سفارش‌ها',
    subtitle: 'جزئیات سفارش، نسخه و ویژگی محصول',
    route: '/orders',
    category: 'فروشگاه',
  ),
  AppModuleInfo(
    id: 'purchase',
    title: 'فرآیند خرید',
    subtitle: 'اسکریپت‌های PHP سفارشی فروشگاه',
    route: '/purchase',
    category: 'فروشگاه',
  ),
  AppModuleInfo(
    id: 'discounts',
    title: 'تخفیف و هدیه',
    subtitle: 'کد تخفیف و کارت هدیه',
    route: '/discounts',
    category: 'فروشگاه',
  ),
  AppModuleInfo(
    id: 'media',
    title: 'رسانه‌ها',
    subtitle: 'گالری و فایل‌ها',
    route: '/media',
    category: 'فروشگاه',
  ),
  AppModuleInfo(
    id: 'articles',
    title: 'مقالات',
    subtitle: 'محتوای وبلاگ',
    route: '/articles',
    category: 'فروشگاه',
  ),
  AppModuleInfo(
    id: 'users',
    title: 'کاربران',
    subtitle: 'پرونده مشتری، کیف پول، نسخه‌ها',
    route: '/users',
    category: 'مشتریان',
  ),
  AppModuleInfo(
    id: 'comments',
    title: 'نظرات',
    subtitle: 'مدیریت دیدگاه‌های سایت',
    route: '/comments',
    category: 'مشتریان',
  ),
  AppModuleInfo(
    id: 'requests',
    title: 'درخواست‌ها',
    subtitle: 'فرم‌های دریافتی سایت',
    route: '/requests',
    category: 'مشتریان',
  ),
  AppModuleInfo(
    id: 'charity',
    title: 'هم‌یاری بینایی',
    subtitle: 'موارد، کمک‌ها و گزارش اثر',
    route: '/charity',
    category: 'مشتریان',
  ),
  AppModuleInfo(
    id: 'support',
    title: 'پشتیبانی',
    subtitle: 'تیکت و گفتگو با مشتری',
    route: '/support',
    category: 'ارتباطات',
  ),
  AppModuleInfo(
    id: 'messages',
    title: 'پیام تکی',
    subtitle: 'ایمیل و پیامک به یک مشتری',
    route: '/messages',
    category: 'ارتباطات',
  ),
  AppModuleInfo(
    id: 'mass',
    title: 'پیام جمعی',
    subtitle: 'ارسال گروهی به مشتریان سایت',
    route: '/mass',
    category: 'ارتباطات',
  ),
  AppModuleInfo(
    id: 'campaign',
    title: 'کمپین',
    subtitle: 'دفترچه مخاطب و ارسال گروهی',
    route: '/campaign',
    category: 'ارتباطات',
  ),
  AppModuleInfo(
    id: 'inbox',
    title: 'صندوق ایمیل',
    subtitle: 'ایمیل‌های دریافتی info@',
    route: '/inbox',
    category: 'ارتباطات',
  ),
  AppModuleInfo(
    id: 'wallet',
    title: 'شارژ کیف پول',
    subtitle: 'تأیید واریز و تعدیل موجودی',
    route: '/wallet',
    category: 'مالی',
  ),
  AppModuleInfo(
    id: 'notes',
    title: 'یادداشت‌ها',
    subtitle: 'یادداشت داخلی تیم',
    route: '/notes',
    category: 'داخلی',
  ),
];

class AppSettingsState {
  final bool confirmBulkSend;
  final bool confirmDelete;
  final bool compactLists;
  final String defaultHome; // dashboard | orders | products
  final bool showModuleHints;

  const AppSettingsState({
    this.confirmBulkSend = true,
    this.confirmDelete = true,
    this.compactLists = false,
    this.defaultHome = 'dashboard',
    this.showModuleHints = true,
  });

  AppSettingsState copyWith({
    bool? confirmBulkSend,
    bool? confirmDelete,
    bool? compactLists,
    String? defaultHome,
    bool? showModuleHints,
  }) {
    return AppSettingsState(
      confirmBulkSend: confirmBulkSend ?? this.confirmBulkSend,
      confirmDelete: confirmDelete ?? this.confirmDelete,
      compactLists: compactLists ?? this.compactLists,
      defaultHome: defaultHome ?? this.defaultHome,
      showModuleHints: showModuleHints ?? this.showModuleHints,
    );
  }

  Map<String, dynamic> toJson() => {
        'confirmBulkSend': confirmBulkSend,
        'confirmDelete': confirmDelete,
        'compactLists': compactLists,
        'defaultHome': defaultHome,
        'showModuleHints': showModuleHints,
      };

  factory AppSettingsState.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const AppSettingsState();
    return AppSettingsState(
      confirmBulkSend: json['confirmBulkSend'] != false,
      confirmDelete: json['confirmDelete'] != false,
      compactLists: json['compactLists'] == true,
      defaultHome: (json['defaultHome'] ?? 'dashboard').toString(),
      showModuleHints: json['showModuleHints'] != false,
    );
  }
}
