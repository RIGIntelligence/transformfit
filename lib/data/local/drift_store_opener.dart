import 'drift_store_opener_stub.dart'
    if (dart.library.js_interop) 'drift_store_opener_web.dart'
    as impl;

typedef OpenWasmDatabase =
    Future<Object> Function({
      required String databaseName,
      required Uri sqlite3Uri,
      required Uri driftWorkerUri,
    });

OpenWasmDatabase get defaultOpenWasmDatabase => impl.defaultOpenWasmDatabase;
