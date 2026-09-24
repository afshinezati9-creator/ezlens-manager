/// EzLens Manager compile-time configuration.
///
/// Real credentials are NOT stored in the public repository.
/// CI can inject them with --dart-define from GitHub Actions Secrets.
class ApiConfig {
  static const String wpBaseUrl =
      String.fromEnvironment('EZLENS_WP_BASE_URL', defaultValue: 'https://ezlens.ir');

  static const String wpUsername =
      String.fromEnvironment('EZLENS_WP_USERNAME', defaultValue: '');

  static const String wpAppPassword =
      String.fromEnvironment('EZLENS_WP_APP_PASSWORD', defaultValue: '');

  static const String wcConsumerKey =
      String.fromEnvironment('EZLENS_WC_CONSUMER_KEY', defaultValue: '');

  static const String wcConsumerSecret =
      String.fromEnvironment('EZLENS_WC_CONSUMER_SECRET', defaultValue: '');

  /// Temporary development login.
  /// When true, the access-code tab is local-only and accepts any non-empty
  /// value. Disable this before the production authentication is finalized.
  static const bool demoLoginEnabled =
      bool.fromEnvironment('EZLENS_DEMO_LOGIN', defaultValue: false);
}
