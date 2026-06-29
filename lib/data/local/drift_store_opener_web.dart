import 'package:drift/wasm.dart';

Future<Object> defaultOpenWasmDatabase({
  required String databaseName,
  required Uri sqlite3Uri,
  required Uri driftWorkerUri,
}) {
  return WasmDatabase.open(
    databaseName: databaseName,
    sqlite3Uri: sqlite3Uri,
    driftWorkerUri: driftWorkerUri,
  );
}
