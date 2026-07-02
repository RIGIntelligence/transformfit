import 'package:flutter_test/flutter_test.dart';
import 'package:transformfit/data/local/drift_store_bootstrap.dart';

class _FakeExecutor {
  var closeCount = 0;

  Future<void> close() async {
    closeCount += 1;
  }
}

class _FakeWasmHandle {
  _FakeWasmHandle(this.resolvedExecutor);

  final _FakeExecutor resolvedExecutor;
}

void main() {
  test('uses sqlite3.wasm and drift_worker.js on web initialization', () async {
    String? capturedDatabaseName;
    Uri? capturedSqlite3Uri;
    Uri? capturedDriftWorkerUri;

    final bootstrap = DriftStoreBootstrap(
      isWeb: true,
      openWasmDatabase:
          ({
            required databaseName,
            required sqlite3Uri,
            required driftWorkerUri,
          }) async {
            capturedDatabaseName = databaseName;
            capturedSqlite3Uri = sqlite3Uri;
            capturedDriftWorkerUri = driftWorkerUri;
            return Object();
          },
    );

    await bootstrap.initialize();

    expect(capturedDatabaseName, equals('transformfit.sqlite'));
    expect(capturedSqlite3Uri, equals(Uri.parse('sqlite3.wasm')));
    expect(capturedDriftWorkerUri, equals(Uri.parse('drift_worker.js')));
    expect(bootstrap.isInitialized, isTrue);
  });

  test('is a no-op when not running on web', () async {
    var called = false;
    final bootstrap = DriftStoreBootstrap(
      isWeb: false,
      openWasmDatabase:
          ({
            required databaseName,
            required sqlite3Uri,
            required driftWorkerUri,
          }) async {
            called = true;
            return Object();
          },
    );

    await bootstrap.initialize();

    expect(called, isFalse);
    expect(bootstrap.isInitialized, isFalse);
  });

  test('surfaces web open failures without marking initialized', () async {
    final bootstrap = DriftStoreBootstrap(
      isWeb: true,
      openWasmDatabase:
          ({
            required databaseName,
            required sqlite3Uri,
            required driftWorkerUri,
          }) async {
            throw StateError('wasm unavailable');
          },
    );

    await expectLater(bootstrap.initialize(), throwsA(isA<StateError>()));
    expect(bootstrap.isInitialized, isFalse);
  });

  test('close disposes the resolved executor and clears the initialized handle', () async {
    final executor = _FakeExecutor();
    final bootstrap = DriftStoreBootstrap(
      isWeb: true,
      openWasmDatabase:
          ({
            required databaseName,
            required sqlite3Uri,
            required driftWorkerUri,
          }) async {
            return _FakeWasmHandle(executor);
          },
    );

    await bootstrap.initialize();
    expect(bootstrap.isInitialized, isTrue);

    await bootstrap.close();

    expect(bootstrap.isInitialized, isFalse);
    expect(executor.closeCount, equals(1));
  });
}
