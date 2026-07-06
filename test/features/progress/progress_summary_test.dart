import 'package:flutter_test/flutter_test.dart';
import 'package:transformfit/features/progress/progress_summary.dart';
import 'package:transformfit/features/session/models.dart';
import 'package:transformfit/features/session/session_controller.dart';

void main() {
  test('empty progress summary waits for completed session evidence', () {
    final summary = buildProgressSummary(const SessionState());

    expect(summary.hasProgress, isFalse);
    expect(summary.headline, 'No proof yet');
    expect(summary.nextBestAction, 'Start from Today');
    expect(summary.ledger, isEmpty);
    expect(progressCopyIsBodyNeutral(summary), isTrue);
  });

  test('progress summary compares current week against previous week', () {
    final state = SessionState(
      history: [
        _session(
          id: 'previous-1',
          day: 1,
          sets: const [
            LoggedSet(
              id: 'previous-1-a',
              exerciseName: 'Goblet squat',
              setNumber: 1,
              weightKg: 20,
              reps: 5,
              rpe: 6,
            ),
          ],
        ),
        _session(
          id: 'current-1',
          day: 8,
          sets: const [
            LoggedSet(
              id: 'current-1-a',
              exerciseName: 'Trap bar deadlift',
              setNumber: 1,
              weightKg: 100,
              reps: 5,
              rpe: 7,
            ),
          ],
        ),
        _session(
          id: 'current-2',
          day: 9,
          notes: 'Recovery mobility work.',
          sets: const [
            LoggedSet(
              id: 'current-2-a',
              exerciseName: 'Mobility reset',
              setNumber: 1,
              durationSeconds: 600,
              rpe: 3,
            ),
          ],
        ),
      ],
    );

    final summary = buildProgressSummary(state, now: DateTime(2026, 7, 9));

    expect(summary.hasProgress, isTrue);
    expect(summary.keptPromises, 3);
    expect(summary.currentWeekSessions, 2);
    expect(summary.previousWeekSessions, 1);
    expect(summary.recoveryWins, 1);
    expect(summary.comebackDays, 1);
    expect(summary.totalVolumeKg, 600);
    expect(summary.currentWeekVolumeKg, 500);
    expect(summary.previousWeekVolumeKg, 100);
    expect(summary.volumeDeltaKg, 400);
    expect(summary.volumeTrendLabel, 'Volume up');
    expect(summary.topSet, 'Trap bar deadlift: 100 kg x 5');
    expect(summary.ledger, hasLength(3));
    expect(summary.ledger.first.kind, 'Recovery');
    expect(progressCopyIsBodyNeutral(summary), isTrue);
  });

  test(
    'progress current week uses wall-clock today, not stale latest session',
    () {
      final state = SessionState(
        history: [
          _session(
            id: 'stale-1',
            day: 1,
            sets: const [
              LoggedSet(
                id: 'stale-1-a',
                exerciseName: 'Goblet squat',
                setNumber: 1,
                weightKg: 20,
                reps: 5,
                rpe: 6,
              ),
            ],
          ),
          _session(
            id: 'stale-2',
            day: 2,
            sets: const [
              LoggedSet(
                id: 'stale-2-a',
                exerciseName: 'Split squat',
                setNumber: 1,
                weightKg: 25,
                reps: 6,
                rpe: 7,
              ),
            ],
          ),
        ],
      );

      final summary = buildProgressSummary(state, now: DateTime(2026, 7, 20));

      expect(summary.hasProgress, isTrue);
      expect(summary.keptPromises, 2);
      expect(summary.currentWeekSessions, 0);
      expect(summary.previousWeekSessions, 0);
      expect(summary.currentWeekVolumeKg, 0);
      expect(summary.previousWeekVolumeKg, 0);
      expect(summary.subhead, 'Last 7 days anchored to today.');
      expect(summary.coachCue, 'Choose one low-friction action today.');
      expect(summary.nextBestAction, 'Start from Today');
      expect(summary.ledger, hasLength(2));
      expect(progressCopyIsBodyNeutral(summary), isTrue);
    },
  );

  test('1000 generated progress scenarios remain deterministic and safe', () {
    final now = DateTime(2026, 8, 10);
    for (var seed = 0; seed < 1000; seed += 1) {
      final state = _scenarioState(seed);
      final first = buildProgressSummary(state, now: now);
      final second = buildProgressSummary(state, now: now);

      expect(second.headline, first.headline, reason: 'scenario $seed');
      expect(
        second.semanticLabel,
        first.semanticLabel,
        reason: 'scenario $seed',
      );
      expect(
        first.keptPromises,
        state.history.length,
        reason: 'scenario $seed',
      );
      expect(
        first.ledger.length,
        lessThanOrEqualTo(6),
        reason: 'scenario $seed',
      );
      expect(
        progressCopyIsBodyNeutral(first),
        isTrue,
        reason: 'scenario $seed',
      );
      expect(first.semanticLabel.toLowerCase(), isNot(contains('streak')));
      expect(first.semanticLabel.toLowerCase(), isNot(contains('weight loss')));
      expect(
        first.semanticLabel.toLowerCase(),
        isNot(contains('before and after')),
      );
    }
  });
}

SessionState _scenarioState(int seed) {
  final sessionCount = (seed % 9) + 1;
  final sessions = <WorkoutSession>[];
  var day = 1 + (seed % 3);
  for (var index = 0; index < sessionCount; index += 1) {
    day += index == 0 ? 0 : ((seed + index) % 4) + 1;
    final recovery = (seed + index) % 4 == 0;
    sessions.add(
      _session(
        id: 'scenario-$seed-$index',
        day: day,
        notes: recovery ? 'Recovery mobility session.' : null,
        sets: recovery
            ? [
                LoggedSet(
                  id: 'scenario-$seed-$index-a',
                  exerciseName: 'Mobility reset',
                  setNumber: 1,
                  durationSeconds: 480 + index,
                  rpe: 3,
                ),
              ]
            : [
                LoggedSet(
                  id: 'scenario-$seed-$index-a',
                  exerciseName: index.isEven
                      ? 'Controlled press'
                      : 'Split squat',
                  setNumber: 1,
                  weightKg: 20 + (seed % 55),
                  reps: 5 + (index % 9),
                  rpe: 6 + (index % 4),
                ),
              ],
      ),
    );
  }

  return SessionState(history: sessions);
}

WorkoutSession _session({
  required String id,
  required int day,
  String? notes,
  List<LoggedSet> sets = const [
    LoggedSet(
      id: 'default-set',
      exerciseName: 'Split squat',
      setNumber: 1,
      weightKg: 30,
      reps: 8,
      rpe: 7,
    ),
  ],
}) {
  return WorkoutSession(
    id: id,
    startedAt: DateTime(2026, 7, day, 8),
    endedAt: DateTime(2026, 7, day, 8, 45),
    readinessEntryId: 'r-$id',
    loggedSets: sets,
    sessionNotes: notes,
  );
}
