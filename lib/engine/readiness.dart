/// Deterministic daily-readiness engine.
///
/// This is the Dart side of the M3 engine duality contract. The Deno mirror
/// lives at `supabase/functions/_shared/engines/readiness.ts`; both runtimes
/// must produce identical outputs for identical inputs.
library;

import 'dart:math' as math;

class ReadinessInputs {
  const ReadinessInputs({
    required this.energyLevel,
    required this.sleepQuality,
    required this.sorenessMap,
    this.hrv,
    this.strain,
  });

  final int energyLevel;
  final int sleepQuality;
  final List<String> sorenessMap;
  final int? hrv;
  final int? strain;

  Map<String, Object?> toJson() => {
    'energyLevel': energyLevel,
    'sleepQuality': sleepQuality,
    'sorenessMap': sorenessMap,
    if (hrv != null) 'hrv': hrv,
    if (strain != null) 'strain': strain,
  };
}

class ReadinessResult {
  const ReadinessResult({
    required this.score,
    required this.readinessZone,
    required this.readinessVariant,
    required this.sleepScore,
    required this.energyScore,
    required this.sorenessPenalty,
    required this.deloadRecommended,
    required this.volumeMultiplier,
    required this.inputs,
    this.hrvScore,
  });

  final int score;
  final String readinessZone;
  final String readinessVariant;
  final int? hrvScore;
  final int sleepScore;
  final int energyScore;
  final int sorenessPenalty;
  final bool deloadRecommended;
  final double volumeMultiplier;
  final ReadinessInputs inputs;

  Map<String, Object?> toJson() => {
    'readinessScore': score,
    'readinessZone': readinessZone,
    'readinessVariant': readinessVariant,
    'hrvScore': hrvScore,
    'sleepScore': sleepScore,
    'energyScore': energyScore,
    'sorenessPenalty': sorenessPenalty,
    'deloadRecommended': deloadRecommended,
    'volumeMultiplier': volumeMultiplier,
    'readinessInputs': inputs.toJson(),
  };
}

ReadinessResult computeReadinessScore(ReadinessInputs inputs) {
  _validate(inputs);

  final sorenessPenalty = math.min(20, inputs.sorenessMap.length * 5);
  const deloadRecommended = false;

  if (inputs.hrv != null) {
    final hrvScore = math.min(100.0, (inputs.hrv! / 120.0) * 100.0);
    final sleepScore = (inputs.sleepQuality / 10.0) * 60.0;
    final energyScore = (inputs.energyLevel / 10.0) * 40.0;
    final raw =
        hrvScore * 0.40 +
        sleepScore * 0.35 +
        energyScore * 0.25 -
        sorenessPenalty;
    return _result(
      score: math.max(0, raw.round()),
      variant: 'with_hrv',
      hrvScore: hrvScore.round(),
      sleepScore: sleepScore.round(),
      energyScore: energyScore.round(),
      sorenessPenalty: sorenessPenalty,
      deloadRecommended: deloadRecommended,
      inputs: inputs,
    );
  }

  final sleepScore = (inputs.sleepQuality / 10.0) * 100.0;
  final energyScore = (inputs.energyLevel / 10.0) * 100.0;
  final raw = sleepScore * 0.55 + energyScore * 0.45 - sorenessPenalty;
  return _result(
    score: math.max(0, raw.round()),
    variant: 'no_hrv',
    sleepScore: sleepScore.round(),
    energyScore: energyScore.round(),
    sorenessPenalty: sorenessPenalty,
    deloadRecommended: deloadRecommended,
    inputs: inputs,
  );
}

String computeReadinessZone(int score, {bool deloadRecommended = false}) {
  if (score < 0 || score > 100) {
    throw ArgumentError.value(score, 'score', 'must be between 0 and 100');
  }
  if (deloadRecommended) return 'deload';
  if (score >= 75) return 'push';
  if (score >= 50) return 'maintain';
  return 'deload';
}

double volumeMultiplierForZone(String zone) {
  switch (zone) {
    case 'push':
      return 1.10;
    case 'maintain':
      return 1.00;
    case 'deload':
      return 0.65;
    case 'rest':
      return 0.00;
    default:
      throw ArgumentError.value(zone, 'zone', 'unknown readiness zone');
  }
}

ReadinessResult _result({
  required int score,
  required String variant,
  required int sleepScore,
  required int energyScore,
  required int sorenessPenalty,
  required bool deloadRecommended,
  required ReadinessInputs inputs,
  int? hrvScore,
}) {
  final zone = computeReadinessZone(
    score,
    deloadRecommended: deloadRecommended,
  );
  return ReadinessResult(
    score: score,
    readinessZone: zone,
    readinessVariant: variant,
    hrvScore: hrvScore,
    sleepScore: sleepScore,
    energyScore: energyScore,
    sorenessPenalty: sorenessPenalty,
    deloadRecommended: deloadRecommended,
    volumeMultiplier: volumeMultiplierForZone(zone),
    inputs: inputs,
  );
}

void _validate(ReadinessInputs inputs) {
  if (inputs.energyLevel < 1 || inputs.energyLevel > 10) {
    throw ArgumentError.value(
      inputs.energyLevel,
      'energyLevel',
      'must be an integer from 1 to 10',
    );
  }
  if (inputs.sleepQuality < 1 || inputs.sleepQuality > 10) {
    throw ArgumentError.value(
      inputs.sleepQuality,
      'sleepQuality',
      'must be an integer from 1 to 10',
    );
  }
  if (inputs.hrv != null && inputs.hrv! <= 0) {
    throw ArgumentError.value(
      inputs.hrv,
      'hrv',
      'must be positive when supplied',
    );
  }
  if (inputs.strain != null && (inputs.strain! < 1 || inputs.strain! > 10)) {
    throw ArgumentError.value(
      inputs.strain,
      'strain',
      'must be an integer from 1 to 10 when supplied',
    );
  }
}
