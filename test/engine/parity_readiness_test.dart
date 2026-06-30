import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:transformfit/engine/readiness.dart';

ReadinessInputs _inputs(Map<String, Object?> json) => ReadinessInputs(
  energyLevel: json['energyLevel'] as int,
  sleepQuality: json['sleepQuality'] as int,
  sorenessMap: (json['sorenessMap'] as List).cast<String>(),
  hrv: json['hrv'] as int?,
  strain: json['strain'] as int?,
);

void main() {
  test('VAL-RDY-010: Dart and Deno readiness engines agree', () {
    final deno = Process.runSync('deno', [
      'run',
      'supabase/functions/_shared/engines/parity_readiness.ts',
    ], workingDirectory: Directory.current.path);
    expect(deno.exitCode, equals(0), reason: deno.stderr.toString());

    final entries = json.decode(deno.stdout.toString()) as List<Object?>;
    expect(entries, hasLength(greaterThanOrEqualTo(7)));

    for (final entry in entries) {
      final vector = entry as Map<String, Object?>;
      final name = vector['name'] as String;
      final inputs = _inputs(vector['inputs'] as Map<String, Object?>);
      final denoResult = vector['result'] as Map<String, Object?>;
      final dartResult = computeReadinessScore(inputs).toJson();
      expect(
        dartResult,
        equals(denoResult),
        reason: 'Dart/Deno divergence on readiness vector "$name"',
      );
    }
  });
}
