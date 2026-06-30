// Cross-runtime parity test (VAL-ONB-056 central deliverable). The Deno
// engine runs the shared input vectors (supabase/.../parity_vectors.json)
// and writes results to supabase/.../parity_results.json via
// `deno run --allow-all supabase/functions/_shared/engines/run_parity.ts`.
// This Dart test reads that file, builds the equivalent Dart [PlanIntake] for
// each vector, runs the Dart [generatePlan], and asserts byte-equal JSON vs
// the Deno result. Dart and Deno MUST agree for identical inputs.
//
// Prereq: run the Deno parity script first (it's run by the Deno lint/test
// gate).

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:transformfit/engine/plan_generation.dart';

PlanIntake _dartIntake(Object? raw) {
  final m = raw as Map<String, Object?>;
  return PlanIntake(
    goal: m['goal'] as String,
    trainingDaysPerWeek: m['trainingDaysPerWeek'] as int,
    equipment: (m['equipment'] as List).cast<String>(),
    experienceLevel: m['experienceLevel'] as String?,
    limitations: (m['limitations'] as List?)?.cast<String>() ?? const [],
  );
}

void main() {
  final resultsFile = File(
    'supabase/functions/_shared/engines/parity_results.json',
  );

  test('parity_results.json exists (generate with run_parity.ts first)', () {
    expect(
      resultsFile.existsSync(),
      isTrue,
      reason:
          'Run: deno run --allow-all supabase/functions/_shared/engines/run_parity.ts',
    );
  });

  test('Dart and Deno plan-generation engines agree on every shared input vector',
      () {
    final text = resultsFile.readAsStringSync();
    final vector = json.decode(text) as List<Object?>;

    int checked = 0;
    for (final entry in vector) {
      final m = entry as Map<String, Object?>;
      final name = m['name'] as String;
      final intake = _dartIntake(m['intake']);
      final denoResult = m['result'] as Map<String, Object?>;
      final dartResult = generatePlan(intake).toJson();
      expect(
        dartResult,
        equals(denoResult),
        reason: 'Dart/Deno divergence on vector "$name"',
      );
      checked++;
    }
    expect(checked, greaterThanOrEqualTo(7));
  });
}
