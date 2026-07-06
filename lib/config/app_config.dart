/// Central configuration for TransformFit.
///
/// Reads secrets from environment variables so API keys are never committed.
/// Feature flags allow shipping code behind toggles.
library;

String _env(String key, [String fallback = '']) =>
    String.fromEnvironment(key, defaultValue: fallback);

/// LLM coach endpoint configuration.
class LlmCoachConfig {
  const LlmCoachConfig._();

  /// Base URL of the OpenAI-compatible API.
  static String get baseUrl =>
      _env('LLM_BASE_URL', 'https://api.openai.com');

  /// API key for the LLM service.
  static String get apiKey => _env('LLM_API_KEY');

  /// Model identifier.
  static String get model => _env('LLM_MODEL', 'gpt-4o-mini');

  /// Maximum tokens in the response.
  static int get maxTokens {
    final raw = _env('LLM_MAX_TOKENS', '500');
    return int.tryParse(raw) ?? 500;
  }
}

/// Supabase configuration.
class SupabaseAppConfig {
  const SupabaseAppConfig._();

  /// Supabase project URL.
  static String get url => _env('SUPABASE_URL', 'https://placeholder.supabase.co');

  /// Supabase anonymous (public) key.
  static String get anonKey => _env('SUPABASE_ANON_KEY', 'placeholder');
}

/// Feature flags for incremental rollout.
class FeatureFlags {
  const FeatureFlags._();

  /// Whether the LLM-powered coach is enabled.
  static bool get enableLlmCoach => _env('ENABLE_LLM_COACH', 'true') == 'true';

  /// Whether social features (sharing, leaderboards) are enabled.
  static bool get enableSocial => _env('ENABLE_SOCIAL', 'false') == 'true';

  /// Whether push notifications are enabled.
  static bool get enableNotifications =>
      _env('ENABLE_NOTIFICATIONS', 'false') == 'true';
}

/// Top-level convenience accessor.
class AppConfig {
  const AppConfig._();

  static const llmCoach = LlmCoachConfig._();
  static const supabase = SupabaseAppConfig._();
  static const features = FeatureFlags._();

  /// Current app version (matches pubspec.yaml).
  static const String appVersion = '1.0.0+1';
}
