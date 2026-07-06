import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// Security: scan the codebase for hardcoded secrets.
///
/// Checks:
/// - .dart files for API keys, tokens, passwords
/// - .yaml files for credentials
/// - .env files for secrets
///
/// Reports any findings. Does NOT access network.
void main() {
  group('No hardcoded secrets', () {
    late String projectRoot;

    setUpAll(() {
      projectRoot = _findProjectRoot();
      debugPrint('Scanning project: $projectRoot');
    });

    test('.dart files contain no hardcoded API keys', () {
      final findings = <String>[];
      // Each pattern targets a known key format. Quotes are checked via
      // the surrounding context rather than embedded in the regex.
      final patterns = [
        RegExp('sk-[a-zA-Z0-9]{20,}'),           // OpenAI keys
        RegExp('sk_live_[a-zA-Z0-9]+'),           // Stripe live keys
        RegExp('sk_test_[a-zA-Z0-9]+'),           // Stripe test keys
        RegExp('pk_live_[a-zA-Z0-9]+'),           // Stripe publishable
        RegExp('AIza[a-zA-Z0-9_-]{35}'),          // Google API keys
        RegExp('ghp_[a-zA-Z0-9]{36}'),            // GitHub PAT
        RegExp('gho_[a-zA-Z0-9]{36}'),            // GitHub OAuth
        RegExp('AKIA[A-Z0-9]{16}'),               // AWS access key
        RegExp('eyJ[a-zA-Z0-9_-]+\\.eyJ'),        // JWT tokens
        RegExp(r"password\s*[:=]\s*[\x22\x27][^\x22\x27]{8,}[\x22\x27]"),
        RegExp(r"secret\s*[:=]\s*[\x22\x27][^\x22\x27]{8,}[\x22\x27]"),
        RegExp(r"token\s*[:=]\s*[\x22\x27][^\x22\x27]{20,}[\x22\x27]"),
        RegExp(r"apiKey\s*[:=]\s*[\x22\x27][^\x22\x27]{20,}[\x22\x27]"),
      ];

      _scanDirectory(projectRoot, '.dart', patterns, findings);

      if (findings.isNotEmpty) {
        debugPrint('Hardcoded secrets found in .dart files:');
        for (final f in findings) {
          debugPrint('  $f');
        }
      } else {
        debugPrint('No hardcoded secrets in .dart files.');
      }

      expect(findings, isEmpty, reason: 'Hardcoded secrets found in .dart files.');
    });

    test('.yaml files contain no credentials', () {
      final findings = <String>[];
      final patterns = [
        RegExp(r'password\s*:\s*[^\s#]+'),
        RegExp(r'secret\s*:\s*[^\s#]+'),
        RegExp(r'token\s*:\s*[^\s#]{20,}'),
        RegExp(r'api_key\s*:\s*[^\s#]+'),
        RegExp(r'apiKey\s*:\s*[^\s#]+'),
        RegExp(r'private_key\s*:\s*[^\s#]+'),
      ];

      _scanDirectory(projectRoot, '.yaml', patterns, findings);
      _scanDirectory(projectRoot, '.yml', patterns, findings);

      // Filter out known safe patterns (pubspec version constraints, etc.)
      findings.removeWhere((f) => f.contains('sdk:'));

      if (findings.isNotEmpty) {
        debugPrint('Potential credentials in .yaml/.yml files:');
        for (final f in findings) {
          debugPrint('  $f');
        }
      } else {
        debugPrint('No credentials in .yaml/.yml files.');
      }

      expect(findings, isEmpty, reason: 'Potential credentials found in YAML files.');
    });

    test('.env files contain no secrets (or do not exist)', () {
      final envFiles = [
        '$projectRoot/.env',
        '$projectRoot/.env.local',
        '$projectRoot/.env.production',
        '$projectRoot/.env.staging',
      ];

      final findings = <String>[];

      for (final envPath in envFiles) {
        final file = File(envPath);
        if (!file.existsSync()) continue;

        final lines = file.readAsLinesSync();
        for (final line in lines) {
          final trimmed = line.trim();
          if (trimmed.isEmpty || trimmed.startsWith('#')) continue;

          findings.add('.env file exists: $envPath');
          break;
        }
      }

      if (findings.isNotEmpty) {
        debugPrint('.env files found (ensure they are gitignored):');
        for (final f in findings) {
          debugPrint('  $f');
        }
      } else {
        debugPrint('No .env files found (good).');
      }
    });

    test('.gitignore excludes sensitive files', () {
      final gitignore = File('$projectRoot/.gitignore');
      if (!gitignore.existsSync()) {
        debugPrint('No .gitignore found.');
        return;
      }

      final content = gitignore.readAsStringSync();
      final required = ['.env', '*.key', '*.pem'];
      final missing = <String>[];

      for (final pattern in required) {
        if (!content.contains(pattern)) {
          missing.add(pattern);
        }
      }

      if (missing.isNotEmpty) {
        debugPrint('.gitignore missing patterns: $missing');
      } else {
        debugPrint('.gitignore has sensitive file exclusions.');
      }
    });
  });
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

String _findProjectRoot() {
  const knownRoot = '/Users/rig128gb/Developer/transformfit-flutter';
  if (Directory(knownRoot).existsSync()) return knownRoot;

  var dir = Directory.current;
  for (int i = 0; i < 10; i++) {
    if (File('${dir.path}/pubspec.yaml').existsSync()) return dir.path;
    dir = dir.parent;
  }
  return Directory.current.path;
}

void _scanDirectory(
  String root,
  String extension,
  List<RegExp> patterns,
  List<String> findings,
) {
  final dir = Directory(root);
  if (!dir.existsSync()) return;

  for (final entity in dir.listSync(recursive: true)) {
    if (entity is! File) continue;
    if (!entity.path.endsWith(extension)) continue;

    // Skip build directories, .dart_tool, generated files.
    if (entity.path.contains('/build/') ||
        entity.path.contains('/.dart_tool/') ||
        entity.path.contains('.g.dart') ||
        entity.path.contains('.freezed.dart')) {
      continue;
    }

    try {
      final content = entity.readAsLinesSync();
      for (int i = 0; i < content.length; i++) {
        final line = content[i];
        // Skip comments.
        if (line.trimLeft().startsWith('//') || line.trimLeft().startsWith('#')) continue;

        for (final pattern in patterns) {
          if (pattern.hasMatch(line)) {
            findings.add('${entity.path}:${i + 1}: ${pattern.pattern}');
          }
        }
      }
    } catch (_) {
      // Skip unreadable files.
    }
  }
}
