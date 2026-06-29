import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:transformfit/config/app_environment.dart';
import 'package:transformfit/data/local/drift_store_bootstrap.dart';

typedef SupabaseInitializer =
    Future<void> Function({
      required String url,
      required String publishableKey,
    });

class AppBootstrapState {
  const AppBootstrapState({
    required this.driftInitialized,
    required this.supabaseInitialized,
    required this.bootstrapErrors,
  });

  final bool driftInitialized;
  final bool supabaseInitialized;
  final List<String> bootstrapErrors;
}

class AppBootstrap {
  AppBootstrap({
    AppEnvironment? environment,
    DriftStoreBootstrap? driftStoreBootstrap,
    SupabaseInitializer? supabaseInitializer,
  }) : environment = environment ?? const AppEnvironment.fromDartDefines(),
       driftStoreBootstrap = driftStoreBootstrap ?? DriftStoreBootstrap(),
       supabaseInitializer = supabaseInitializer ?? _defaultSupabaseInitializer;

  final AppEnvironment environment;
  final DriftStoreBootstrap driftStoreBootstrap;
  final SupabaseInitializer supabaseInitializer;

  static bool _supabaseInitialized = false;

  Future<AppBootstrapState> initialize() async {
    final errors = <String>[];
    var driftInitialized = false;
    var supabaseInitialized = false;

    try {
      await driftStoreBootstrap.initialize();
      driftInitialized = driftStoreBootstrap.isInitialized || !kIsWeb;
    } catch (error) {
      errors.add('drift_init_failed: $error');
      debugPrint('Drift store initialization failed: $error');
    }

    if (environment.hasSupabaseConfig) {
      try {
        await supabaseInitializer(
          url: environment.supabaseUrl,
          publishableKey: environment.supabaseAnonKey,
        );
        supabaseInitialized = true;
        unawaited(_warmSupabaseClient());
      } catch (error) {
        errors.add('supabase_init_failed: $error');
        debugPrint(
          'Supabase initialization failed, continuing app boot: $error',
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
