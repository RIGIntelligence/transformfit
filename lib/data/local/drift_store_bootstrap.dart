import 'package:flutter/foundation.dart';
import 'package:transformfit/data/local/drift_store_opener.dart';

class DriftStoreBootstrap {
  DriftStoreBootstrap({
    bool? isWeb,
    OpenWasmDatabase? openWasmDatabase,
    this.databaseName = 'transformfit.sqlite',
  }) : _isWeb = isWeb ?? kIsWeb,
       _openWasmDatabase = openWasmDatabase ?? defaultOpenWasmDatabase;

  final bool _isWeb;
  final OpenWasmDatabase _openWasmDatabase;
  final String databaseName;

  Object? _databaseHandle;

  bool get isInitialized => _databaseHandle != null;

  Future<void> initialize() async {
    if (!_isWeb || isInitialized) {
      return;
    }

    _databaseHandle = await _openWasmDatabase(
      databaseName: databaseName,
      sqlite3Uri: Uri.parse('sqlite3.wasm'),
      driftWorkerUri: Uri.parse('drift_worker.js'),
    );
  }
}
