/// Copy to api_config.dart and fill values. DO NOT commit real secrets.
class ApiConfig {
  static const String wpBaseUrl = 'https://ezlens.ir';

  /// Prefer empty here — set after login via SecureStorage.
  static const String wpUsername = '';
  static const String wpAppPassword = '';

  /// Optional legacy WC keys (prefer Application Password instead)
  static const String wcConsumerKey = '';
  static const String wcConsumerSecret = '';
}
