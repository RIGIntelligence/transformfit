import 'package:flutter_test/flutter_test.dart';
import 'package:transformfit/bootstrap/app_bootstrap.dart';
import 'package:transformfit/config/app_environment.dart';
import 'package:transformfit/data/local/drift_store_bootstrap.dart';

void main() {
  test('initializes Supabase with dart-define environment values', () async {
    String? capturedUrl;
    String? capturedAnonKey;

    final bootstrap = AppBootstrap(
      environment: const AppEnvironment(
        supabaseUrl: 'https://zuwtgdqsxmtiqojckpus.supabase.co',
        supabaseAnonKey: 'sb_publishable_test_key',
      ),
      driftStoreBootstrap: DriftStoreBootstrap(isWeb: false),
      supabaseInitializer: ({required url, required publishableKey}) async {
        capturedUrl = url;
        capturedAnonKey = publishableKey;
      },
    );

    final state = await bootstrap.initialize();

    expect(state.supabaseInitialized, isTrue);
    expect(capturedUrl, equals('https://zuwtgdqsxmtiqojckpus.supabase.co'));
    expect(capturedAnonKey, equals('sb_publishable_test_key'));
  });

  test('continues boot when Supabase initialization throws', () async {
    final bootstrap = AppBootstrap(
      environment: const AppEnvironment(
        supabaseUrl: 'https://zuwtgdqsxmtiqojckpus.supabase.co',
        supabaseAnonKey: 'sb_publishable_test_key',
      ),
      driftStoreBootstrap: DriftStoreBootstrap(isWeb: false),
      supabaseInitializer: ({required url, required publishableKey}) async {
        throw Exception('offline');
      },
    );

    final state = await bootstrap.initialize();

    expect(state.supabaseInitialized, isFalse);
    expect(state.bootstrapErrors, isNotEmpty);
  });

  test('skips Supabase init when url or anon key is missing', () async {
    var initializerCalled = false;

    final bootstrap = AppBootstrap(
      environment: const AppEnvironment(supabaseUrl: '', supabaseAnonKey: ''),
      driftStoreBootstrap: DriftStoreBootstrap(isWeb: false),
      supabaseInitializer: ({required url, required publishableKey}) async {
        initializerCalled = true;
      },
    );

    final state = await bootstrap.initialize();

    expect(initializerCalled, isFalse);
    expect(state.supabaseInitialized, isFalse);
  });
}
