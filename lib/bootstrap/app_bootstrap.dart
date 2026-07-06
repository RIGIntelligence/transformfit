import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:transformfit/bootstrap/crashlytics_bootstrap.dart';
import 'package:transformfit/config/app_environment.dart';
import 'package:transformfit/config/feature_flags.dart';
import 'package:transformfit/data/local/drift_store_bootstrap.dart';
import 'package:transformfit/services/analytics/analytics_backend.dart';
import 'package:transformfit/services/crashlytics/crashlytics_service.dart';
import 'package:transformfit/services/notifications/notification_service.dart';

typedef SupabaseInitializer =
    Future<void> Function({
      required String url,
      required String publishableKey,
    });

class AppBootstrapState {
  const AppBootstrapState({
    required this.driftInitialized,
    required this.supabaseInitialized,
    required this.crashReportingInitialized,
    required this.analyticsInitialized,
    required this.notificationsInitialized,
    required this.bootstrapErrors,
  });

  final bool driftInitialized;
  final bool supabaseInitialized;
  final bool crashReportingInitialized;
  final bool analyticsInitialized;
  final bool notificationsInitialized;
  final List<String> bootstrapErrors;
}

class AppBootstrap {
  AppBootstrap({
    AppEnvironment? environment,
    DriftStoreBootstrap? driftStoreBootstrap,
    SupabaseInitializer? supabaseInitializer,
    CrashReportingService? crashReportingService,
    AnalyticsBackend? analyticsBackend,
    NotificationService? notificationService,
  }) : environment = environment ?? const AppEnvironment.fromDartDefines(),
       driftStoreBootstrap = driftStoreBootstrap ?? DriftStoreBootstrap(),
       supabaseInitializer = supabaseInitializer ?? _defaultSupabaseInitializer,
       crashReportingService = crashReportingService,
       analyticsBackend = analyticsBackend,
       notificationService = notificationService;

  final AppEnvironment environment;
  final DriftStoreBootstrap driftStoreBootstrap;
  final SupabaseInitializer supabaseInitializer;
  final CrashReportingService? crashReportingService;
  final AnalyticsBackend? analyticsBackend;
  final NotificationService? notificationService;

  static bool _supabaseInitialized = false;

  /// Services initialized during bootstrap — available after [initialize].
  late final CrashReportingService? initializedCrashService;
  late final AnalyticsBackend? initializedAnalytics;
  late final NotificationService? initializedNotifications;

  static String _diagnosticCode(Object error) => error.runtimeType.toString();

  Future<AppBootstrapState> initialize() async {
    final errors = <String>[];
    var driftInitialized = false;
    var supabaseInitialized = false;
    var crashReportingInitialized = false;
    var analyticsInitialized = false;
    var notificationsInitialized = false;

    // ---------------------------------------------------------------
    // 1. Crash reporting (must be first)
    // ---------------------------------------------------------------
    if (FeatureFlags.enableCrashReporting) {
      try {
        initializedCrashService =
            crashReportingService ?? createCrashReportingService();
        bootstrapCrashReporting(service: initializedCrashService);
        crashReportingInitialized = true;
      } catch (error) {
        final code = _diagnosticCode(error);
        errors.add('crash_reporting_init_failed:$code');
        debugPrint('Crash reporting initialization failed: $code');
        initializedCrashService = null;
      }
    } else {
      initializedCrashService = null;
    }

    // ---------------------------------------------------------------
    // 2. Analytics backend
    // ---------------------------------------------------------------
    if (FeatureFlags.enableAnalytics) {
      try {
        initializedAnalytics = analyticsBackend ?? AnalyticsBackend();
        analyticsInitialized = true;
      } catch (error) {
        final code = _diagnosticCode(error);
        errors.add('analytics_init_failed:$code');
        debugPrint('Analytics initialization failed: $code');
        initializedAnalytics = null;
      }
    } else {
      initializedAnalytics = null;
    }

    // ---------------------------------------------------------------
    // 3. Notification service
    // ---------------------------------------------------------------
    if (FeatureFlags.enablePushNotifications) {
      try {
        initializedNotifications =
            notificationService ?? createNotificationService();
        await initializedNotifications!.requestPermission();
        notificationsInitialized = true;
      } catch (error) {
        final code = _diagnosticCode(error);
        errors.add('notifications_init_failed:$code');
        debugPrint('Notification service initialization failed: $code');
        initializedNotifications = null;
      }
    } else {
      initializedNotifications = null;
    }

    // ---------------------------------------------------------------
    // 4. Drift (local database)
    // ---------------------------------------------------------------
    try {
      await driftStoreBootstrap.initialize();
      driftInitialized = driftStoreBootstrap.isInitialized || !kIsWeb;
    } catch (error) {
      final code = _diagnosticCode(error);
      errors.add('drift_init_failed:$code');
      debugPrint('Drift store initialization failed: $code');
    }

    // ---------------------------------------------------------------
    // 5. Supabase (remote database)
    // ---------------------------------------------------------------
    if (environment.hasSupabaseConfig) {
      try {
        await supabaseInitializer(
          url: environment.supabaseUrl,
          publishableKey: environment.supabaseAnonKey,
        );
        supabaseInitialized = true;
        unawaited(_warmSupabaseClient());
      } catch (error) {
        final code = _diagnosticCode(error);
        errors.add('supabase_init_failed:$code');
        debugPrint(
          'Supabase initialization failed, continuing app boot: $code',
        );
      }
    } else {
      errors.add('supabase_config_missing');
      debugPrint(
        'Supabase URL or publishable key missing, continuing app boot in offline mode.',
      );
    }

    return AppBootstrapState(
      driftInitialized: driftInitialized,
      supabaseInitialized: supabaseInitialized,
      crashReportingInitialized: crashReportingInitialized,
      analyticsInitialized: analyticsInitialized,
      notificationsInitialized: notificationsInitialized,
      bootstrapErrors: errors,
    );
  }

  static Future<void> _defaultSupabaseInitializer({
    required String url,
    required String publishableKey,
  }) async {
    if (_supabaseInitialized) {
      return;
    }

    await Supabase.initialize(url: url, publishableKey: publishableKey);
    _supabaseInitialized = true;
  }

  Future<void> _warmSupabaseClient() async {
    try {
      await Supabase.instance.client.from('profiles').select('id').limit(1);
    } catch (_) {
      // Ignore warm-up failures so bootstrap remains offline-first.
    }
  }
}
