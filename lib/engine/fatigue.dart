/// Fatigue / ACWR engine — M4 logging milestone.
///
/// Computes the acute:chronic workload ratio and resulting fatigue state
/// from a history of training volume. Pure and deterministic; the Deno
/// mirror at `supabase/functions/_shared/engines/fatigue.ts` must agree.
///
/// Doctrine L6-2: this engine owns the fatigue number. The LLM may only
/// narrate. A surfaced deterministic fallback is used on LLM failure.
library;

/// A daily volume entry for ACWR computation.
class DailyVolume {
  const DailyVolume({required this.date, required this.volumeKg});

  final DateTime date;
  final double volumeKg;
}

/// Result of the fatigue computation.
class FatigueResult {
  const FatigueResult({
    required this.acwr,
    required this.state,
    required this.acuteLoad,
    required this.chronicLoad,
    required this.volumeMultiplier,
  });

  final double acwr;
  final String state; // 'safe' | 'caution' | 'high'
  final double acuteLoad;
  final double chronicLoad;
  final double volumeMultiplier;

  Map<String, Object?> toJson() => {
    'acwr': acwr,
    'state': state,
    'acuteLoad': acuteLoad,
    'chronicLoad': chronicLoad,
    'volumeMultiplier': volumeMultiplier,
  };
}

/// Compute the ACWR and fatigue state from daily volume history.
///
/// Expects [history] sorted oldest-first. The last entry is treated as
/// "today". Acute = sum of the last 7 days; chronic = average of the
/// preceding 21 days (28-day rolling window).
FatigueResult computeFatigue(List<DailyVolume> history) {
  if (history.isEmpty) {
    return const FatigueResult(
      acwr: 0.0,
      state: 'safe',
      acuteLoad: 0.0,
      chronicLoad: 0.0,
      volumeMultiplier: 1.0,
    );
  }

  final now = history.last.date;
  // Acute window = last 7 days inclusive (today + 6 prior).
  final sixDaysAgo = now.subtract(const Duration(days: 6));
  // Chronic window = preceding 21 days (days 7–27 inclusive).
  final twentySevenDaysAgo = now.subtract(const Duration(days: 27));

  double acuteVolume = 0.0;
  double chronicVolume = 0.0;

  for (final entry in history) {
    if (!entry.date.isBefore(sixDaysAgo)) {
      acuteVolume += entry.volumeKg;
    } else if (!entry.date.isBefore(twentySevenDaysAgo)) {
      chronicVolume += entry.volumeKg;
    }
  }

  final acuteLoad = acuteVolume / 7.0;
  final chronicLoad = chronicVolume / 21.0;

  double acwr;
  if (chronicLoad == 0.0) {
    acwr = 0.0;
  } else {
    acwr = acuteLoad / chronicLoad;
  }

  final state = _classifyFatigue(acwr);
  final volumeMultiplier = _volumeMultiplierForFatigue(acwr);

  return FatigueResult(
    acwr: acwr,
    state: state,
    acuteLoad: acuteLoad,
    chronicLoad: chronicLoad,
    volumeMultiplier: volumeMultiplier,
  );
}

String _classifyFatigue(double acwr) {
  if (acwr == 0.0) return 'safe';
  if (acwr < 1.3) return 'safe';
  if (acwr < 1.5) return 'caution';
  return 'high';
}

double _volumeMultiplierForFatigue(double acwr) {
  if (acwr >= 1.5) return 0.70;
  if (acwr >= 1.3) return 0.85;
  return 1.0;
}

/// Round ACWR to 2 decimal places for display/parity.
double roundAcwr(double acwr) {
  return (acwr * 100).round() / 100.0;
}
