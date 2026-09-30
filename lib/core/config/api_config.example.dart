/// Example compile-time configuration for local development/CI.
///
/// Real credentials must be supplied with --dart-define (or GitHub Actions
/// Secrets). Do not put real credentials in this file or commit them.
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

  static const bool demoLoginEnabled =
      bool.fromEnvironment('EZLENS_DEMO_LOGIN', defaultValue: false);
}
