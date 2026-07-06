/// Feature flags for TransformFit gradual rollout.
///
/// Reads from compile-time dart defines so flags are baked in at build time.
/// The [FeatureFlagOverrides] class allows runtime override (e.g. from a
/// remote config fetch) without restarting the app.
library;

import 'package:flutter/foundation.dart';

// ---------------------------------------------------------------------------
// Default flag definitions (compile-time)
// ---------------------------------------------------------------------------

/// Compile-time feature flags read from `--dart-define`.
class FeatureFlags {
  const FeatureFlags._();

  /// LLM-powered AI coach.
  static const bool enableLlmCoach = bool.fromEnvironment(
    'ENABLE_LLM_COACH',
    defaultValue: true,
  );

  /// Push notifications.
  static const bool enablePushNotifications = bool.fromEnvironment(
    'ENABLE_PUSH_NOTIFICATIONS',
    defaultValue: false,
  );

  /// Crash reporting (Sentry / Crashlytics).
  static const bool enableCrashReporting = bool.fromEnvironment(
    'ENABLE_CRASH_REPORTING',
    defaultValue: false,
  );

  /// Analytics event collection.
  static const bool enableAnalytics = bool.fromEnvironment(
    'ENABLE_ANALYTICS',
    defaultValue: false,
  );

  /// Social features (sharing, leaderboards).
  static const bool enableSocial = bool.fromEnvironment(
    'ENABLE_SOCIAL',
    defaultValue: false,
  );

  /// Camera-based form check (pose estimation).
  static const bool enableCameraFormCheck = bool.fromEnvironment(
    'ENABLE_CAMERA_FORM_CHECK',
    defaultValue: false,
  );
}

// ---------------------------------------------------------------------------
// Runtime overrides (remote config stub)
// ---------------------------------------------------------------------------

/// Mutable runtime overrides for feature flags.
///
/// Values set here take precedence over compile-time defaults. Use this when
/// fetching flags from a remote config service (e.g. Firebase Remote Config,
/// Supabase, LaunchDarkly).
class FeatureFlagOverrides extends ChangeNotifier {
  final Map<String, bool> _overrides = {};

  /// Override a flag at runtime.
  void setFlag(String name, bool value) {
    if (_overrides[name] == value) return;
    _overrides[name] = value;
    notifyListeners();
  }

  /// Remove a runtime override (revert to compile-time default).
  void clearFlag(String name) {
    if (_overrides.containsKey(name)) {
      _overrides.remove(name);
      notifyListeners();
    }
  }

  /// Clear all overrides.
  void clearAll() {
    if (_overrides.isEmpty) return;
    _overrides.clear();
    notifyListeners();
  }

  /// Check if a flag has a runtime override.
  bool hasOverride(String name) => _overrides.containsKey(name);

  /// Get the runtime override value, or `null` if not overridden.
  bool? getOverride(String name) => _overrides[name];
}

// ---------------------------------------------------------------------------
// Unified flag resolver
// ---------------------------------------------------------------------------

/// Resolves feature flags with override support.
///
/// Usage:
/// ```dart
/// final resolver = FeatureFlagResolver(overrides: remoteOverrides);
/// if (resolver.isEnabled(FlagNames.crashReporting)) { ... }
/// ```
class FeatureFlagResolver {
  FeatureFlagResolver({this.overrides});

  final FeatureFlagOverrides? overrides;

  bool isEnabled(String flagName) {
    // Check runtime override first.
    final override = overrides?.getOverride(flagName);
    if (override != null) return override;

    // Fall back to compile-time default.
    return _compileTimeDefaults[flagName] ?? false;
  }

  static const Map<String, bool> _compileTimeDefaults = {
    FlagNames.llmCoach: FeatureFlags.enableLlmCoach,
    FlagNames.pushNotifications: FeatureFlags.enablePushNotifications,
    FlagNames.crashReporting: FeatureFlags.enableCrashReporting,
    FlagNames.analytics: FeatureFlags.enableAnalytics,
    FlagNames.social: FeatureFlags.enableSocial,
    FlagNames.cameraFormCheck: FeatureFlags.enableCameraFormCheck,
  };
}

/// String constants for flag names to avoid typos.
abstract final class FlagNames {
  static const String llmCoach = 'enableLlmCoach';
  static const String pushNotifications = 'enablePushNotifications';
  static const String crashReporting = 'enableCrashReporting';
  static const String analytics = 'enableAnalytics';
  static const String social = 'enableSocial';
  static const String cameraFormCheck = 'enableCameraFormCheck';
}
