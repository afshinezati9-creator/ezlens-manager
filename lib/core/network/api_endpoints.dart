import '../../core/constants/app_constants.dart';

class ApiEndpoints {
  // آدرس پایه وردپرس
  static String get baseUrl => AppConstants.wpBaseUrl;

  // اندپوینت‌های احراز هویت
  static String get login => '$baseUrl/wp-json/jwt-auth/v1/token';
  static String get register => '$baseUrl/wp-json/jwt-auth/v1/register';
  static String get userInfo => '$baseUrl/wp-json/wp/v2/users/me';
}