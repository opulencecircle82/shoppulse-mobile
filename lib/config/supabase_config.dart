/// Supabase project credentials, injected at build/run time via --dart-define.
///
/// Example:
///   flutter run \
///     --dart-define=SUPABASE_URL=https://ghbmcepnjrviinseiwqr.supabase.co \
///     --dart-define=SUPABASE_ANON_KEY=your-anon-public-key
class SupabaseConfig {
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;
}
