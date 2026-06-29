Future<Object> defaultOpenWasmDatabase({
  required String databaseName,
  required Uri sqlite3Uri,
  required Uri driftWorkerUri,
}) async {
  throw UnsupportedError(
    'Wasm drift databases are only supported in web runtime.',
  );
}
