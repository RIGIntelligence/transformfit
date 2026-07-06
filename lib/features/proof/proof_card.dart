import 'package:transformfit/features/session/models.dart';
import 'package:transformfit/features/session/session_controller.dart';

class ProofMetric {
  const ProofMetric({
    required this.label,
    required this.value,
    required this.spokenValue,
  });

  final String label;
  final String value;
  final String spokenValue;
}

class ProofCardSummary {
  const ProofCardSummary({
    required this.readyToShare,
    required this.headline,
    required this.subhead,
    required this.completedSessions,
    required this.keptPromises,
    required this.recoveryWins,
    required this.comebackDays,
    required this.totalSets,
    required this.totalVolumeKg,
    required this.topSet,
    required this.nextFocus,
    required this.metrics,
    required this.shareText,
    required this.sharePrivacySummary,
    required this.shareRedactions,
    required this.shareConsentLabel,
    required this.semanticLabel,
  });

  final bool readyToShare;
  final String headline;
  final String subhead;
  final int completedSessions;
  final int keptPromises;
  final int recoveryWins;
  final int comebackDays;
  final int totalSets;
  final double totalVolumeKg;
  final String topSet;
  final String nextFocus;
  final List<ProofMetric> metrics;
  final String shareText;
  final String sharePrivacySummary;
  final List<String> shareRedactions;
  final String shareConsentLabel;
  final String semanticLabel;
}

ProofCardSummary buildProofCardSummary(SessionState state) {
  final sessions = [...state.history]
    ..sort((a, b) => a.startedAt.compareTo(b.startedAt));
  final completed = sessions
      .where(
        (session) => session.endedAt != null && session.loggedSets.isNotEmpty,
      )
      .toList(growable: false);

  if (completed.isEmpty) {
    const shareText =
        'TransformFitAI proof starts after the first completed session. Private by default.';
    return const ProofCardSummary(
      readyToShare: false,
      headline: 'Proof begins after session 1',
      subhead: 'Readiness-adjusted training proof',
      completedSessions: 0,
      keptPromises: 0,
      recoveryWins: 0,
      comebackDays: 0,
      totalSets: 0,
      totalVolumeKg: 0,
      topSet: 'No top set yet',
      nextFocus: 'Complete one session to create proof',
      metrics: [
        ProofMetric(
          label: 'Kept promises',
          value: '0',
          spokenValue: '0 kept promises',
        ),
        ProofMetric(
          label: 'Recovery wins',
          value: '0',
          spokenValue: '0 recovery wins',
        ),
        ProofMetric(
          label: 'Comeback days',
          value: '0',
          spokenValue: '0 comeback days',
        ),
        ProofMetric(label: 'Sets', value: '0', spokenValue: '0 sets'),
      ],
      shareText: shareText,
      sharePrivacySummary:
          'Private by default. Copy is disabled until there is completed training proof.',
      shareRedactions: [
        'No measurements',
        'No session notes',
        'No injury details',
        'No body comparison',
      ],
      shareConsentLabel: 'I reviewed this redacted proof text',
      semanticLabel:
          'Proof card is waiting for the first completed session. Private by default. 0 kept promises.',
    );
  }

  final recoveryWins = completed.where(_isRecoverySession).length;
  final comebackDays = _countComebackDays(completed);
  final totalSets = completed.fold<int>(
    0,
    (total, session) => total + session.totalSets,
  );
  final totalVolumeKg = completed.fold<double>(
    0,
    (total, session) => total + (session.totalVolume ?? 0),
  );
  final topSet = _topSetLabel(completed);
  final nextFocus = _safeNextFocus(state.lastDebrief?.nextSessionFocus);
  final keptPromises = completed.length;
  final sessionLabel = _plural(keptPromises, 'kept promise', 'kept promises');
  final headline = '$keptPromises $sessionLabel';
  final volumeValue = totalVolumeKg > 0
      ? '${_formatNumber(totalVolumeKg)} kg'
      : '--';
  final spokenVolume = totalVolumeKg > 0
      ? '${_formatNumber(totalVolumeKg)} kilograms'
      : 'volume not recorded';

  final metrics = [
    ProofMetric(
      label: 'Kept promises',
      value: keptPromises.toString(),
      spokenValue: '$keptPromises $sessionLabel',
    ),
    ProofMetric(
      label: 'Recovery wins',
      value: recoveryWins.toString(),
      spokenValue:
          '$recoveryWins ${_plural(recoveryWins, 'recovery win', 'recovery wins')}',
    ),
    ProofMetric(
      label: 'Comeback days',
      value: comebackDays.toString(),
      spokenValue:
          '$comebackDays ${_plural(comebackDays, 'comeback day', 'comeback days')}',
    ),
    ProofMetric(
      label: 'Sets',
      value: totalSets.toString(),
      spokenValue: '$totalSets ${_plural(totalSets, 'set', 'sets')}',
    ),
    ProofMetric(label: 'Volume', value: volumeValue, spokenValue: spokenVolume),
  ];
  final recoveryPhrase = recoveryWins == 0
      ? '0 recovery wins'
      : '$recoveryWins ${_plural(recoveryWins, 'recovery win', 'recovery wins')}';
  final comebackPhrase = comebackDays == 0
      ? '0 comeback days'
      : '$comebackDays ${_plural(comebackDays, 'comeback day', 'comeback days')}';
  final shareText =
      'TransformFitAI proof: $headline, $recoveryPhrase, $comebackPhrase. '
      'Shared by choice; measurements and session notes stay private.';

  return ProofCardSummary(
    readyToShare: true,
    headline: headline,
    subhead: 'Body-neutral, readiness-adjusted training proof',
    completedSessions: completed.length,
    keptPromises: keptPromises,
    recoveryWins: recoveryWins,
    comebackDays: comebackDays,
    totalSets: totalSets,
    totalVolumeKg: totalVolumeKg,
    topSet: topSet,
    nextFocus: nextFocus,
    metrics: metrics,
    shareText: shareText,
    sharePrivacySummary:
        'Private by default. Copy only after review; measurements, session notes, injury details, and body comparisons stay out of the public text.',
    shareRedactions: const [
      'No measurements',
      'No session notes',
      'No injury details',
      'No body comparison',
    ],
    shareConsentLabel: 'I reviewed this redacted proof text',
    semanticLabel:
        'Proof card: private by default. $headline, $recoveryPhrase, $comebackPhrase, '
        '$totalSets ${_plural(totalSets, 'set', 'sets')}, '
        '$spokenVolume. Next focus: $nextFocus.',
  );
}

bool proofCopyIsBodyNeutral(ProofCardSummary summary) {
  const blockedTerms = [
    'before and after',
    'body fat',
    'burn fat',
    'bikini',
    'cheat',
    'crush excuses',
    'excuses',
    'guilt',
    'no excuses',
    'punish',
    'shame',
    'skinny',
    'streak',
    'summer body',
    'transformation photo',
    'weight loss',
  ];
  final copy = [
    summary.headline,
    summary.subhead,
    summary.topSet,
    summary.nextFocus,
    summary.shareText,
    summary.sharePrivacySummary,
    summary.shareConsentLabel,
    ...summary.shareRedactions,
    summary.semanticLabel,
    ...summary.metrics.expand(
      (metric) => [metric.label, metric.value, metric.spokenValue],
    ),
  ].join(' ').toLowerCase();
  return blockedTerms.every((term) => !copy.contains(term));
}

bool proofShareTextIsPrivacySafe(ProofCardSummary summary) {
  const blockedPhrases = [
    'body fat',
    'before and after',
    'weight loss',
    'session notes:',
    'next focus:',
  ];
  const blockedTokens = [
    'kg',
    'lb',
    'pound',
    'rpe',
    'volume',
    'calorie',
    'pain',
    'injury',
    'knee',
    'shoulder',
    'hip',
    'back',
  ];
  final share = summary.shareText.toLowerCase();
  final phrasesAreClear = blockedPhrases.every((term) => !share.contains(term));
  final tokensAreClear = blockedTokens.every((term) {
    final pattern = RegExp('(^|[^a-z0-9])${RegExp.escape(term)}([^a-z0-9]|\$)');
    return !pattern.hasMatch(share);
  });
  return phrasesAreClear && tokensAreClear;
}

bool _isRecoverySession(WorkoutSession session) {
  final note = session.sessionNotes?.toLowerCase() ?? '';
  if (note.contains('recovery') ||
      note.contains('mobility') ||
      note.contains('walk')) {
    return true;
  }

  final totalVolume = session.totalVolume ?? 0;
  return session.loggedSets.any((set) {
    final exercise = set.exerciseName.toLowerCase();
    final durationOnly = set.durationSeconds != null && set.weightKg == null;
    return durationOnly &&
        totalVolume == 0 &&
        (exercise.contains('mobility') ||
            exercise.contains('walk') ||
            exercise.contains('reset') ||
            exercise.contains('recovery'));
  });
}

int _countComebackDays(List<WorkoutSession> sessions) {
  var comebackDays = 0;
  for (var i = 1; i < sessions.length; i += 1) {
    final previousDay = _dateOnly(sessions[i - 1].startedAt);
    final currentDay = _dateOnly(sessions[i].startedAt);
    if (currentDay.difference(previousDay).inDays > 1) {
      comebackDays += 1;
    }
  }
  return comebackDays;
}

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

String _topSetLabel(List<WorkoutSession> sessions) {
  LoggedSet? best;
  DateTime? bestStartedAt;
  for (final session in sessions) {
    for (final set in session.loggedSets) {
      if (!set.completed || set.weightKg == null || set.reps == null) {
        continue;
      }
      if (_isBetterTopSet(set, session.startedAt, best, bestStartedAt)) {
        best = set;
        bestStartedAt = session.startedAt;
      }
    }
  }
  if (best == null) {
    return 'Recovery-only week';
  }
  return '${best.exerciseName}: ${_formatNumber(best.weightKg!)} kg x ${best.reps}';
}

bool _isBetterTopSet(
  LoggedSet candidate,
  DateTime candidateStartedAt,
  LoggedSet? current,
  DateTime? currentStartedAt,
) {
  if (current == null) {
    return true;
  }
  final candidateVolume = candidate.weightKg! * candidate.reps!;
  final currentVolume = current.weightKg! * current.reps!;
  if (candidateVolume != currentVolume) {
    return candidateVolume > currentVolume;
  }
  if (candidate.weightKg != current.weightKg) {
    return candidate.weightKg! > current.weightKg!;
  }
  if (candidateStartedAt != currentStartedAt) {
    return candidateStartedAt.isAfter(currentStartedAt!);
  }
  return candidate.setNumber > current.setNumber;
}

String _safeNextFocus(String? value) {
  final normalized = value?.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (normalized == null || normalized.isEmpty) {
    return 'Keep the next training appointment';
  }
  if (normalized.length <= 72) {
    return normalized;
  }
  return '${normalized.substring(0, 69).trimRight()}...';
}

String _plural(int count, String singular, String plural) {
  return count == 1 ? singular : plural;
}

String _formatNumber(double value) {
  if (value == value.roundToDouble()) {
    return value.round().toString();
  }
  return value.toStringAsFixed(1);
}
