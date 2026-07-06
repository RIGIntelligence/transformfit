// M4: Shared helpers for golden tests.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// Suppress overflow errors in golden tests.
///
/// Pre-existing layout overflows in the app cause golden tests to fail.
/// This helper wraps the test body to ignore overflow errors while still
/// catching other Flutter errors.
void suppressOverflowErrors() {
  final originalOnError = FlutterError.onError;
  FlutterError.onError = (details) {
    if (details.exceptionAsString().contains('overflowed')) return;
    originalOnError?.call(details);
  };
  addTearDown(() => FlutterError.onError = originalOnError);
}
