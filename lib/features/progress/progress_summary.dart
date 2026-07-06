import 'package:transformfit/features/session/models.dart';
import 'package:transformfit/features/session/session_controller.dart';

class ProgressMetric {
  const ProgressMetric({
    required this.label,
    required this.value,
    required this.spokenValue,
  });

  final String label;
  final String value;
  final String spokenValue;
}

class ProgressLedgerEntry {
  const ProgressLedgerEntry({
    required this.dateLabel,
    required this.kind,
    required this.primary,
    required this.secondary,
    required this.semanticLabel,
  });

  final String dateLabel;
  final String kind;
  final String primary;
  final String secondary;
  final String semanticLabel;
}

class ProgressSummary {
  const ProgressSummary({
    required this.hasProgress,
    required this.headline,
    required this.subhead,
    required this.coachCue,
    required this.nextBestAction,
    required this.keptPromises,
    required this.currentWeekSessions,
    required this.previousWeekSessions,
    required this.recoveryWins,
    required this.comebackDays,
    required this.totalSets,
    required this.totalVolumeKg,
    required this.currentWeekVolumeKg,
    required this.previousWeekVolumeKg,
    required this.volumeDeltaKg,
    required this.volumeTrendLabel,
    required this.topSet,
    required this.metrics,
    required this.ledger,
    required this.semanticLabel,
  });

  final bool hasProgress;
  final String headline;
  final String subhead;
  final String coachCue;
  final String nextBestAction;
  final int keptPromises;
  final int currentWeekSessions;
  final int previousWeekSessions;
  final int recoveryWins;
  final int comebackDays;
  final int totalSets;
  final double totalVolumeKg;
  final double currentWeekVolumeKg;
  final double previousWeekVolumeKg;
  final double volumeDeltaKg;
  final String volumeTrendLabel;
  final String topSet;
  final List<ProgressMetric> metrics;
  final List<ProgressLedgerEntry> ledger;
  final String semanticLabel;
}

ProgressSummary buildProgressSummary(SessionState state, {DateTime? now}) {
  final sessions = [...state.history]
    ..sort((a, b) => a.startedAt.compareTo(b.startedAt));
  final completed = sessions
      .where(
        (session) => session.endedAt != null && session.loggedSets.isNotEmpty,
      )
      .toList(growable: false);

  if (completed.isEmpty) {
    return const ProgressSummary(
      hasProgress: false,
      headline: 'No proof yet',
      subhead: 'Progress builds from completed sessions.',
      coachCue: 'Complete one readiness-adjusted action to start the ledger.',
      nextBestAction: 'Start from Today',
      keptPromises: 0,
      currentWeekSessions: 0,
      previousWeekSessions: 0,
      recoveryWins: 0,
      comebackDays: 0,
      totalSets: 0,
      totalVolumeKg: 0,
      currentWeekVolumeKg: 0,
      previousWeekVolumeKg: 0,
      volumeDeltaKg: 0,
      volumeTrendLabel: 'Waiting for first session',
      topSet: 'No top set yet',
      metrics: [
        ProgressMetric(
          label: 'Kept promises',
          value: '0',
          spokenValue: '0 kept promises',
        ),
        ProgressMetric(
          label: 'Recovery wins',
          value: '0',
          spokenValue: '0 recovery wins',
        ),
        ProgressMetric(label: 'Sets', value: '0', spokenValue: '0 sets'),
        ProgressMetric(
          label: 'Volume',
          value: '--',
          spokenValue: 'volume not recorded',
        ),
      ],
      ledger: [],
      semanticLabel:
          'Progress summary waiting for the first completed session.',
    );
  }

  final anchorDay = _dateOnly(now ?? DateTime.now());
  final currentStart = anchorDay.subtract(const Duration(days: 6));
  final previousStart = anchorDay.subtract(const Duration(days: 13));
  final previousEnd = currentStart.subtract(const Duration(days: 1));
  final currentWeek = completed
      .where((session) => _inRange(session.startedAt, currentStart, anchorDay))
      .toList(growable: false);
  final previousWeek = completed
      .where(
        (session) => _inRange(session.startedAt, previousStart, previousEnd),
      )
      .toList(growable: false);
  final recoveryWins = completed.where(_isRecoverySession).length;
  final comebackDays = _countComebackDays(completed);
  final totalSets = completed.fold<int>(
    0,
    (total, session) => total + session.totalSets,
  );
  final totalVolumeKg = _totalVolume(completed);
  final currentWeekVolumeKg = _totalVolume(currentWeek);
  final previousWeekVolumeKg = _totalVolume(previousWeek);
  final volumeDeltaKg = currentWeekVolumeKg - previousWeekVolumeKg;
  final volumeTrendLabel = _volumeTrendLabel(
    previousWeek: previousWeek,
    volumeDeltaKg: volumeDeltaKg,
  );
  final topSet = _topSetLabel(completed);
  final keptPromises = completed.length;
  final headline =
      '$keptPromises ${_plural(keptPromises, 'kept promise', 'kept promises')}';
  final volumeValue = totalVolumeKg > 0
      ? '${_formatNumber(totalVolumeKg)} kg'
      : '--';
  final currentWeekLabel = currentWeek.length.toString();
  final coachCue = _coachCue(
    currentWeek: currentWeek,
    recoveryWins: recoveryWins,
    comebackDays: comebackDays,
    volumeDeltaKg: volumeDeltaKg,
  );
  final nextBestAction = _nextBestAction(
    hasActiveSession: state.activeSession != null,
    currentWeek: currentWeek,
    recoveryWins: recoveryWins,
    comebackDays: comebackDays,
  );

  final metrics = [
    ProgressMetric(
      label: 'Current week',
      value: currentWeekLabel,
      spokenValue:
          '$currentWeekLabel ${_plural(currentWeek.length, 'session', 'sessions')} this week',
    ),
    ProgressMetric(
      label: 'Recovery wins',
      value: recoveryWins.toString(),
      spokenValue:
          '$recoveryWins ${_plural(recoveryWins, 'recovery win', 'recovery wins')}',
    ),
    ProgressMetric(
      label: 'Comeback days',
      value: comebackDays.toString(),
      spokenValue:
          '$comebackDays ${_plural(comebackDays, 'comeback day', 'comeback days')}',
    ),
    ProgressMetric(
      label: 'Sets',
      value: totalSets.toString(),
      spokenValue: '$totalSets ${_plural(totalSets, 'set', 'sets')}',
    ),
    ProgressMetric(
      label: 'Volume',
      value: volumeValue,
      spokenValue: totalVolumeKg > 0
          ? '${_formatNumber(totalVolumeKg)} kilograms'
          : 'volume not recorded',
    ),
  ];

  final ledger = completed.reversed
      .take(6)
      .map(_ledgerEntry)
      .toList(growable: false);

  return ProgressSummary(
    hasProgress: true,
    headline: headline,
    subhead: 'Last 7 days anchored to today.',
    coachCue: coachCue,
    nextBestAction: nextBestAction,
    keptPromises: keptPromises,
    currentWeekSessions: currentWeek.length,
    previousWeekSessions: previousWeek.length,
    recoveryWins: recoveryWins,
    comebackDays: comebackDays,
    totalSets: totalSets,
    totalVolumeKg: totalVolumeKg,
    currentWeekVolumeKg: currentWeekVolumeKg,
    previousWeekVolumeKg: previousWeekVolumeKg,
    volumeDeltaKg: volumeDeltaKg,
    volumeTrendLabel: volumeTrendLabel,
    topSet: topSet,
    metrics: metrics,
    ledger: ledger,
    semanticLabel:
        'Progress summary: $headline, ${currentWeek.length} current week sessions, '
        '$recoveryWins recovery wins, $comebackDays comeback days, '
        '$totalSets ${_plural(totalSets, 'set', 'sets')}, '
        '${totalVolumeKg > 0 ? '${_formatNumber(totalVolumeKg)} kilograms' : 'volume not recorded'}. '
        'Trend: $volumeTrendLabel. Next action: $nextBestAction.',
  );
}

bool progressCopyIsBodyNeutral(ProgressSummary summary) {
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
    summary.coachCue,
    summary.nextBestAction,
    summary.volumeTrendLabel,
    summary.topSet,
    summary.semanticLabel,
    ...summary.metrics.expand(
      (metric) => [metric.label, metric.value, metric.spokenValue],
    ),
    ...summary.ledger.expand(
      (entry) => [
        entry.dateLabel,
        entry.kind,
        entry.primary,
        entry.secondary,
        entry.semanticLabel,
      ],
    ),
  ].join(' ').toLowerCase();
  return blockedTerms.every((term) => !copy.contains(term));
}

ProgressLedgerEntry _ledgerEntry(WorkoutSession session) {
  final volume = session.totalVolume ?? 0;
  final topSet = _topSetLabel([session]);
  final kind = _isRecoverySession(session) ? 'Recovery' : 'Training';
  final primary = kind == 'Recovery'
      ? '${session.totalSets} ${_plural(session.totalSets, 'action', 'actions')}'
      : '${session.totalSets} ${_plural(session.totalSets, 'set', 'sets')}';
  final secondary = volume > 0 ? '${_formatNumber(volume)} kg' : topSet;
  final dateLabel = _dateLabel(session.startedAt);
  return ProgressLedgerEntry(
    dateLabel: dateLabel,
    kind: kind,
    primary: primary,
    secondary: secondary,
    semanticLabel: '$dateLabel $kind session, $primary, $secondary.',
  );
}

bool _inRange(DateTime value, DateTime start, DateTime end) {
  final day = _dateOnly(value);
  return !day.isBefore(start) && !day.isAfter(end);
}

double _totalVolume(List<WorkoutSession> sessions) => sessions.fold<double>(
  0,
  (total, session) => total + (session.totalVolume ?? 0),
);

String _volumeTrendLabel({
  required List<WorkoutSession> previousWeek,
  required double volumeDeltaKg,
}) {
  if (previousWeek.isEmpty) return 'Baseline week';
  if (volumeDeltaKg > 0) return 'Volume up';
  if (volumeDeltaKg < 0) return 'Volume lower';
  return 'Volume held';
}

String _coachCue({
  required List<WorkoutSession> currentWeek,
  required int recoveryWins,
  required int comebackDays,
  required double volumeDeltaKg,
}) {
  if (currentWeek.isEmpty) {
    return 'Choose one low-friction action today.';
  }
  if (currentWeek.every(_isRecoverySession)) {
    return 'Recovery is carrying the promise. Keep the next action small.';
  }
  if (comebackDays > 0 && currentWeek.length == 1) {
    return 'The return matters most. Repeat the appointment before adding load.';
  }
  if (volumeDeltaKg > 0 && recoveryWins == 0 && currentWeek.length >= 3) {
    return 'Volume is moving. Add a recovery win before chasing more work.';
  }
  if (volumeDeltaKg < 0) {
    return 'Load is quieter this week. Protect the next clean session.';
  }
  return 'The pattern is stable. Keep the next rep boring and repeatable.';
}

String _nextBestAction({
  required bool hasActiveSession,
  required List<WorkoutSession> currentWeek,
  required int recoveryWins,
  required int comebackDays,
}) {
  if (hasActiveSession) {
    return 'Finish today session';
  }
  if (currentWeek.isEmpty) {
    return 'Start from Today';
  }
  if (currentWeek.every(_isRecoverySession)) {
    return 'Add one strength set';
  }
  if (recoveryWins == 0 && currentWeek.length >= 2) {
    return 'Take a recovery win';
  }
  if (comebackDays > 0) {
    return 'Book the next return';
  }
  return 'Repeat the next appointment';
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

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

String _dateLabel(DateTime value) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[value.month - 1]} ${value.day}';
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
