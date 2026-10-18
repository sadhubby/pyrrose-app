class AppConfig {
  const AppConfig._();

  /// Supabase project URL. Empty until configured — the app then runs in
  /// local-only mode (see BouquetRepository in Phase 3).
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');

  /// Supabase anon (public) key. Safe to ship in clients; RLS guards access.
  static const String supabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY');

  /// Base URL of the hosted Three.js viewer (GitHub Pages), used to build
  /// share links. Example: https://sadhubby.github.io/pyrrose-app/viewer
  static const String webViewerBaseUrl =
      String.fromEnvironment('WEB_VIEWER_BASE_URL');

  static bool get isSupabaseConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  static bool get isWebViewerConfigured => webViewerBaseUrl.isNotEmpty;
}
