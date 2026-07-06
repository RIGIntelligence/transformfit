/// Abstract crash reporting interface with local file-based implementation
/// and a Sentry integration stub.
///
/// Pure Dart — no external SDK dependency. When ready to integrate Sentry or
/// Firebase Crashlytics, swap the implementation and add the real SDK.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

// ---------------------------------------------------------------------------
// Abstract interface
// ---------------------------------------------------------------------------

/// Crash reporting contract. Implementations may forward to Sentry, Firebase
/// Crashlytics, or a local log file.
abstract class CrashReportingService {
  /// Record a caught error with optional stack trace and context.
  void recordError(
    Object error,
    StackTrace? stack, {
    String? reason,
    Map<String, Object?>? context,
    bool fatal = false,
  });

  /// Record a Flutter framework error (from [FlutterError.onError]).
  void recordFlutterError(FlutterErrorDetails details);

  /// Associate a user ID with subsequent reports.
  void setUserId(String? userId);

  /// Attach a custom key-value pair to the crash context.
  void setCustomKey(String key, Object value);

  /// Write a breadcrumb / log line.
  void log(String message, {LogLevel level});

  /// Flush any buffered data.
  Future<void> flush();
}

/// Severity levels for breadcrumbs.
enum LogLevel { debug, info, warning, error, fatal }

// ---------------------------------------------------------------------------
// Local file-based implementation
// ---------------------------------------------------------------------------

/// Logs crash reports to a local file. Useful for development and as a
/// fallback when no remote service is configured.
class LocalCrashReportingService implements CrashReportingService {
  LocalCrashReportingService({this.logDirectory = 'crash_logs'});

  final String logDirectory;

  final List<Map<String, Object?>> _breadcrumbs = [];
  String? _userId;
  final Map<String, Object> _customKeys = {};

  @override
  void recordError(
    Object error,
    StackTrace? stack, {
    String? reason,
    Map<String, Object?>? context,
    bool fatal = false,
  }) {
    final report = <String, Object?>{
      'type': 'error',
      'fatal': fatal,
      'timestamp': DateTime.now().toIso8601String(),
      'error': error.toString(),
      'stackTrace': stack?.toString(),
      'reason': reason,
      'context': context,
      'userId': _userId,
      'customKeys': Map.unmodifiable(_customKeys),
      'breadcrumbs': List.unmodifiable(_breadcrumbs),
    };
    _writeToFile(report);
    if (kDebugMode) {
      debugPrint('[CrashReporting] ${fatal ? "FATAL " : ""}Error: $error');
      if (reason != null) debugPrint('  Reason: $reason');
    }
  }

  @override
  void recordFlutterError(FlutterErrorDetails details) {
    recordError(
      details.exception,
      details.stack,
      reason: details.context?.toDescription(),
      context: {
        'library': details.library,
        'silent': details.silent,
      },
    );
  }

  @override
  void setUserId(String? userId) => _userId = userId;

  @override
  void setCustomKey(String key, Object value) => _customKeys[key] = value;

  @override
  void log(String message, {LogLevel level = LogLevel.info}) {
    _breadcrumbs.add({
      'timestamp': DateTime.now().toIso8601String(),
      'level': level.name,
      'message': message,
    });
    // Keep breadcrumbs bounded.
    if (_breadcrumbs.length > 100) {
      _breadcrumbs.removeRange(0, _breadcrumbs.length - 100);
    }
    if (kDebugMode) {
      debugPrint('[CrashReporting:${level.name}] $message');
    }
  }

  @override
  Future<void> flush() async {
    // No-op: local writes are immediate.
  }

  void _writeToFile(Map<String, Object?> report) {
    try {
      final dir = Directory(logDirectory);
      if (!dir.existsSync()) dir.createSync(recursive: true);
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final file = File('${dir.path}/crash_$timestamp.json');
      file.writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert(report),
      );
    } catch (e) {
      // Last resort — don't crash the crash reporter.
      if (kDebugMode) debugPrint('[CrashReporting] Failed to write log: $e');
    }
  }
}

// ---------------------------------------------------------------------------
// Sentry integration stub
// ---------------------------------------------------------------------------

/// Stub for Sentry SDK integration. All methods are no-ops until the real
/// Sentry SDK (`sentry_flutter`) is added to pubspec.yaml and the
/// implementation is filled in.
///
/// To activate:
/// 1. Add `sentry_flutter: ^8.x` to pubspec.yaml
/// 2. Replace body of each method with real Sentry calls
/// 3. Initialize via `SentryFlutter.init(...)` in bootstrap
class SentryCrashReportingService implements CrashReportingService {
  const SentryCrashReportingService();

  @override
  void recordError(
    Object error,
    StackTrace? stack, {
    String? reason,
    Map<String, Object?>? context,
    bool fatal = false,
  }) {
    // TODO: Sentry.captureException(error, stackTrace: stack);
  }

  @override
  void recordFlutterError(FlutterErrorDetails details) {
    // TODO: Sentry.captureException(details.exception, stackTrace: details.stack);
  }

  @override
  void setUserId(String? userId) {
    // TODO: Sentry.configureScope((scope) => scope.setUser(SentryUser(id: userId)));
  }

  @override
  void setCustomKey(String key, Object value) {
    // TODO: Sentry.configureScope((scope) => scope.setTag(key, value.toString()));
  }

  @override
  void log(String message, {LogLevel level = LogLevel.info}) {
    // TODO: Sentry.addBreadcrumb(Breadcrumb(message: message, level: _mapLevel(level)));
  }

  @override
  Future<void> flush() async {
    // TODO: await Sentry.close();
  }
}

// ---------------------------------------------------------------------------
// Factory
// ---------------------------------------------------------------------------

/// Create the appropriate [CrashReportingService] based on environment.
CrashReportingService createCrashReportingService({bool useSentry = false}) {
  if (useSentry) {
    return const SentryCrashReportingService();
  }
  return LocalCrashReportingService();
}
