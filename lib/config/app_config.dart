class AppConfig {
  /// The web-based technician app this wrapper loads. Overridable via
  /// --dart-define=TECH_APP_URL=... for testing against a different
  /// deployment; defaults to production.
  static const String techAppUrl = String.fromEnvironment(
    'TECH_APP_URL',
    defaultValue: 'https://shoppulse-web.vercel.app/tech',
  );
}
