import 'package:flutter_test/flutter_test.dart';
import 'package:transformfit/features/proof/proof_card.dart';
import 'package:transformfit/features/session/models.dart';
import 'package:transformfit/features/session/session_controller.dart';

void main() {
  test('empty proof card waits for first completed session', () {
    final summary = buildProofCardSummary(const SessionState());

    expect(summary.readyToShare, isFalse);
    expect(summary.keptPromises, 0);
    expect(summary.shareText, contains('first completed session'));
    expect(proofCopyIsBodyNeutral(summary), isTrue);
    expect(proofShareTextIsPrivacySafe(summary), isTrue);
  });

  test(
    'proof card summarizes kept promises, recovery wins, and comeback days',
    () {
      final state = SessionState(
        history: [
          _session(
            id: 's-1',
            day: 1,
            sets: const [
              LoggedSet(
                id: 's-1-a',
                exerciseName: 'Goblet squat',
                setNumber: 1,
                weightKg: 50,
                reps: 8,
                rpe: 7,
              ),
            ],
          ),
          _session(
            id: 's-2',
            day: 4,
            notes: 'Completed 12-minute mobility reset.',
            sets: const [
              LoggedSet(
                id: 's-2-a',
                exerciseName: 'Mobility reset',
                setNumber: 1,
                durationSeconds: 720,
                rpe: 3,
              ),
            ],
          ),
          _session(
            id: 's-3',
            day: 5,
            sets: const [
              LoggedSet(
                id: 's-3-a',
                exerciseName: 'Dumbbell bench press',
                setNumber: 1,
                weightKg: 40,
                reps: 10,
                rpe: 8,
              ),
            ],
          ),
        ],
        lastDebrief: SessionDebrief(
          id: 'd-3',
          sessionId: 's-3',
          createdAt: DateTime(2026, 7, 5, 9),
          perceivedExertion: 7,
          satisfaction: 4,
          nextSessionFocus: 'Pull strength with quiet shoulders',
        ),
      );

      final summary = buildProofCardSummary(state);

      expect(summary.readyToShare, isTrue);
      expect(summary.keptPromises, 3);
      expect(summary.recoveryWins, 1);
      expect(summary.comebackDays, 1);
      expect(summary.totalSets, 3);
      expect(summary.totalVolumeKg, 800);
      expect(summary.topSet, 'Goblet squat: 50 kg x 8');
      expect(summary.nextFocus, 'Pull strength with quiet shoulders');
      expect(summary.shareText, contains('3 kept promises'));
      expect(summary.shareText, contains('1 recovery win'));
      expect(summary.shareText, contains('1 comeback day'));
      expect(summary.shareText, isNot(contains('800 kg')));
      expect(summary.shareText, isNot(contains('Goblet squat')));
      expect(summary.shareText, isNot(contains('Pull strength')));
      expect(summary.sharePrivacySummary, contains('Private by default'));
      expect(summary.shareRedactions, contains('No measurements'));
      expect(summary.shareRedactions, contains('No injury details'));
      expect(proofCopyIsBodyNeutral(summary), isTrue);
      expect(proofShareTextIsPrivacySafe(summary), isTrue);
    },
  );

  test('proof card sorts history before computing comeback days', () {
    final state = SessionState(
      history: [
        _session(id: 's-3', day: 6),
        _session(id: 's-1', day: 1),
        _session(id: 's-2', day: 2),
      ],
    );

    final summary = buildProofCardSummary(state);

    expect(summary.keptPromises, 3);
    expect(summary.comebackDays, 1);
  });

  test(
    '1000 generated proof scenarios stay body-neutral and deterministic',
    () {
      for (var i = 0; i < 1000; i += 1) {
        final state = _scenarioState(i);
        final first = buildProofCardSummary(state);
        final second = buildProofCardSummary(state);

        expect(second.shareText, first.shareText, reason: 'scenario $i');
        expect(first.keptPromises, state.history.length, reason: 'scenario $i');
        expect(proofCopyIsBodyNeutral(first), isTrue, reason: 'scenario $i');
        expect(
          first.shareText.length,
          lessThanOrEqualTo(220),
          reason: 'scenario $i',
        );
        expect(first.shareText.toLowerCase(), isNot(contains('streak')));
        expect(first.shareText.toLowerCase(), isNot(contains('weight loss')));
        expect(first.shareText.toLowerCase(), isNot(contains('kg')));
        expect(first.shareText.toLowerCase(), isNot(contains('rpe')));
        expect(
          first.shareText.toLowerCase(),
          isNot(contains('before and after')),
        );
        expect(
          proofShareTextIsPrivacySafe(first),
          isTrue,
          reason: 'scenario $i',
        );
      }
    },
  );
}

SessionState _scenarioState(int seed) {
  final sessionCount = (seed % 6) + 1;
  final sessions = <WorkoutSession>[];
  var day = 1;
  for (var index = 0; index < sessionCount; index += 1) {
    day += index == 0 ? 0 : (seed + index) % 3;
    final recovery = (seed + index) % 5 == 0;
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
                  durationSeconds: 600 + index,
                  rpe: 3,
                ),
              ]
            : [
                LoggedSet(
                  id: 'scenario-$seed-$index-a',
                  exerciseName: 'Controlled press',
                  setNumber: 1,
                  weightKg: 20 + (seed % 40),
                  reps: 6 + (index % 8),
                  rpe: 6 + (index % 4),
                ),
              ],
      ),
    );
  }

  final last = sessions.last;
  return SessionState(
    history: sessions,
    lastDebrief: SessionDebrief(
      id: 'scenario-$seed-debrief',
      sessionId: last.id,
      createdAt: last.endedAt!.add(const Duration(minutes: 3)),
      perceivedExertion: 6,
      satisfaction: 4,
      nextSessionFocus: 'Repeat the appointment with clean reps',
    ),
  );
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
