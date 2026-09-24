/// آدرس‌های API وردپرس و ووکامرس
/// همه endpointها اینجا متمرکز هستند تا تغییر آن‌ها آسان باشد
class ApiEndpoints {
  // احراز هویت
  static const String login = '/wp-json/jwt-auth/v1/token';
  static const String currentUser = '/wp-json/wp/v2/users/me';

  // محصولات
  static const String products = '/wp-json/wc/v3/products';
  static String product(int id) => '/wp-json/wc/v3/products/$id';

  // سفارش‌ها
  static const String orders = '/wp-json/wc/v3/orders';
  static String order(int id) => '/wp-json/wc/v3/orders/$id';

  // کاربران
  static const String users = '/wp-json/wp/v2/users';
  static String user(int id) => '/wp-json/wp/v2/users/$id';

  // رسانه
  static const String media = '/wp-json/wp/v2/media';
  static String mediaItem(int id) => '/wp-json/wp/v2/media/$id';

  // نظرات
  static const String comments = '/wp-json/wp/v2/comments';
  static String comment(int id) => '/wp-json/wp/v2/comments/$id';

  // مقالات / پست‌ها
  static const String posts = '/wp-json/wp/v2/posts';
  static String post(int id) => '/wp-json/wp/v2/posts/$id';

  // دسته‌بندی‌ها
  static const String categories = '/wp-json/wc/v3/products/categories';
  static const String postCategories = '/wp-json/wp/v2/categories';

  // درخواست‌ها (فرم‌ساز EI)
  static const String eiRequests = '/wp-json/ei/v1/requests';
  static String eiRequest(int id) => '/wp-json/ei/v1/requests/$id';

  // یادداشت‌ها
  static const String notes = '/wp-json/ei/v1/notes';
  static String note(int id) => '/wp-json/ei/v1/notes/$id';

  // داشبورد
  static const String dashboardStats = '/wp-json/ei/v1/dashboard/stats';

  // ویژگی‌های محصول (Product Options)
  static const String productOptions = '/wp-json/ezlens/v1/product-options';
  static String productOption(int id) => '/wp-json/ezlens/v1/product-options/$id';
  static String productOptionSlots(int productId) =>
      '/wp-json/ezlens/v1/products/$productId/option-slots';

  // Manager API
  static const String managerStats = '/wp-json/ezlens/v1/manager/stats';
  static const String managerInbox = '/wp-json/ezlens/v1/manager/inbox';
  static const String managerWallet = '/wp-json/ezlens/v1/manager/wallet';
  static const String managerPurchase = '/wp-json/ezlens/v1/manager/purchase';
}
