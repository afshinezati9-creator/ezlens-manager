/// آدرس‌های متمرکز REST API وردپرس، ووکامرس و EzLens Manager.
/// مسیرها نسبی به ApiConfig.wpBaseUrl هستند.
class ApiEndpoints {
  // WordPress REST
  static const String wpRest = '/wp-json/wp/v2';
  static const String currentUser = '$wpRest/users/me';
  static const String users = '$wpRest/users';
  static String user(int id) => '$wpRest/users/$id';
  static const String media = '$wpRest/media';
  static String mediaItem(int id) => '$wpRest/media/$id';
  static const String comments = '$wpRest/comments';
  static String comment(int id) => '$wpRest/comments/$id';
  static const String posts = '$wpRest/posts';
  static String post(int id) => '$wpRest/posts/$id';
  static const String postCategories = '$wpRest/categories';

  // WooCommerce REST
  static const String wcRest = '/wp-json/wc/v3';
  static const String products = '$wcRest/products';
  static String product(int id) => '$wcRest/products/$id';
  static const String orders = '$wcRest/orders';
  static String order(int id) => '$wcRest/orders/$id';
  static String orderNotes(int id) => '$wcRest/orders/$id/notes';
  static const String customers = '$wcRest/customers';
  static String customer(int id) => '$wcRest/customers/$id';
  static const String categories = '$wcRest/products/categories';

  // EI Form Builder REST
  static const String eiRest = '/wp-json/ei/v1';
  static const String eiRequests = '$eiRest/requests';
  static String eiRequest(int id) => '$eiRest/requests/$id';
  static const String notes = '$eiRest/notes';
  static String note(int id) => '$eiRest/notes/$id';
  static const String dashboardStats = '$eiRest/dashboard/stats';

  // EzLens REST
  static const String ezlensRest = '/wp-json/ezlens/v1';
  static const String productOptions = '$ezlensRest/product-options';
  static String productOption(int id) => '$productOptions/$id';
  static String productOptionSlots(int productId) =>
      '$ezlensRest/products/$productId/option-slots';

  // EzLens Manager REST
  static const String managerRest = '$ezlensRest/manager';

  // Authentication
  static const String managerLogin = '$managerRest/login';
  static const String managerLogout = '$managerRest/logout';
  static const String managerMasterLogin = '$managerRest/master-login';
  static const String managerOtpSend = '$managerRest/otp/send';
  static const String managerOtpVerify = '$managerRest/otp/verify';

  // Dashboard / statistics
  static const String managerStats = '$managerRest/stats';
  static const String managerTopProducts = '$managerStats/top-products';
  static const String managerTopPosts = '$managerStats/top-posts';
  static const String managerRecentVisitors = '$managerStats/recent-visitors';
  static const String managerIndexStatus = '$managerStats/index-status';
  static const String managerViewsDebug = '$managerStats/views-debug';
  static const String managerGsc = '$managerStats/gsc';
  static const String managerGscQueries = '$managerGsc/queries';
  static const String managerGscPages = '$managerGsc/pages';
  static const String managerGscCountries = '$managerGsc/countries';

  // Customers
  static const String managerCustomers = '$managerRest/customers';
  static String managerCustomer(int id) => '$managerCustomers/$id';
  static String managerCustomerDossier(int id) =>
      '$managerCustomers/$id/dossier';

  // Wallet
  static const String managerWallet = '$managerRest/wallet';
  static const String managerWalletSettings = '$managerWallet/settings';
  static const String managerWalletDeposits = '$managerWallet/deposits';
  static String managerWalletDeposit(int id) => '$managerWalletDeposits/$id';
  static String managerWalletDepositApprove(int id) =>
      '$managerWalletDeposits/$id/approve';
  static String managerWalletDepositReject(int id) =>
      '$managerWalletDeposits/$id/reject';
  static const String managerWalletAdjust = '$managerWallet/adjust';
  static String managerWalletUser(int id) => '$managerWallet/user/$id';
  static const String managerWalletStats = '$managerWallet/stats';
  static const String managerWalletSearchUsers =
      '$managerWallet/search-users';

  // Purchase process
  static const String managerPurchase = '$managerRest/purchase';
  static const String managerPurchaseScripts = '$managerPurchase/scripts';
  static String managerPurchaseScript(int id) =>
      '$managerPurchaseScripts/$id';
  static String managerPurchaseScriptToggle(int id) =>
      '$managerPurchaseScripts/$id/toggle';
  static const String managerPurchaseStats = '$managerPurchase/stats';

  // Inbox
  static const String managerInbox = '$managerRest/inbox';
}
