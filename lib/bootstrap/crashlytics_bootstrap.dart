/// Bootstrap crash reporting — must be the FIRST initialization step.
///
/// Wraps the app in a guarded zone so uncaught async errors are captured
/// alongside Flutter framework errors.
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:transformfit/services/crashlytics/crashlytics_service.dart';

/// Initializes crash reporting and installs error handlers.
///
/// Call before [runApp] — returns the service instance so it can be stored
/// and passed to the rest of the app.
CrashReportingService bootstrapCrashReporting({
  CrashReportingService? service,
}) {
  final crashService = service ?? createCrashReportingService();

  // 1. Flutter framework errors
  FlutterError.onError = (FlutterErrorDetails details) {
    crashService.recordFlutterError(details);
    // Also print in debug so Flutter's default behavior is preserved.
    FlutterError.presentError(details);
  };

  // 2. Platform dispatcher errors (Dart isolate errors on native)
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    crashService.recordError(error, stack, fatal: true);
    return true; // Handled
  };

  crashService.log('Crash reporting initialized', level: LogLevel.info);
  return crashService;
}

/// Wraps [body] in a guarded [Zone] that captures uncaught async errors.
///
/// Usage in main():
/// ```dart
/// void main() {
///   final crashService = bootstrapCrashReporting();
///   runZonedGuarded(() async {
///     WidgetsFlutterBinding.ensureInitialized();
///     await AppBootstrap().initialize();
///     runApp(const MyApp());
///   }, (error, stack) {
///     crashService.recordError(error, stack, fatal: true);
///   });
/// }
/// ```
void guardedZone(
  void Function() body,
  CrashReportingService crashService,
) {
  runZonedGuarded(body, (Object error, StackTrace stack) {
    crashService.recordError(error, stack, fatal: true);
  });
}
