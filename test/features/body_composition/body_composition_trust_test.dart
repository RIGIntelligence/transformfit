import 'package:flutter_test/flutter_test.dart';
import 'package:transformfit/features/body_composition/body_composition_trust.dart';
import 'package:transformfit/features/session/models.dart';
import 'package:transformfit/features/session/session_controller.dart';

void main() {
  test('empty composition trust waits for training context', () {
    final summary = buildBodyCompositionTrustSummary(const SessionState());

    expect(summary.hasTrainingContext, isFalse);
    expect(summary.headline, 'No composition signal yet');
    expect(summary.subhead, contains('Signals, not verdicts'));
    expect(summary.trustFrame, 'Imperfect signal');
    expect(summary.nextBestAction, 'Log first training action');
    expect(summary.privacyLabel, 'Private by default');
    expect(summary.sourceIds, bodyCompositionTrustSourceIds);
    expect(bodyCompositionCopyIsTrustSafe(summary), isTrue);
  });

  test(
    'composition trust connects strength recovery adherence and nutrition',
    () {
      final state = SessionState(
        nutritionTarget: NutritionTarget(
          id: 'nutrition-composition-1',
          createdAt: DateTime(2026, 7, 2, 7),
          targetType: 'protein',
          label: 'Protein target',
          dailyTarget: 135,
          unit: 'g/day',
        ),
        history: [
          _session(
            id: 'composition-strength-1',
            day: 1,
            sets: const [
              LoggedSet(
                id: 'composition-set-1',
                exerciseName: 'Trap bar deadlift',
                setNumber: 1,
                weightKg: 100,
                reps: 5,
                rpe: 7,
              ),
              LoggedSet(
                id: 'composition-set-2',
                exerciseName: 'Trap bar deadlift',
                setNumber: 2,
                weightKg: 100,
                reps: 5,
                rpe: 7,
              ),
            ],
          ),
          _session(
            id: 'composition-recovery-1',
            day: 2,
            notes: 'Recovery mobility session.',
            sets: const [
              LoggedSet(
                id: 'composition-set-3',
                exerciseName: 'Mobility reset',
                setNumber: 1,
                durationSeconds: 600,
                rpe: 3,
              ),
            ],
          ),
        ],
      );

      final summary = buildBodyCompositionTrustSummary(
        state,
        now: DateTime(2026, 7, 2),
      );

      expect(summary.hasTrainingContext, isTrue);
      expect(summary.headline, 'Context before change');
      expect(summary.nextBestAction, 'Review after repeated readings');
      expect(summary.signals.map((signal) => signal.label), [
        'Strength context',
        'Recovery context',
        'Adherence context',
        'Nutrition context',
      ]);
      expect(
        summary.signals
            .singleWhere((signal) => signal.label == 'Strength context')
            .value,
        '2 weighted sets',
      );
      expect(
        summary.signals
            .singleWhere((signal) => signal.label == 'Recovery context')
            .value,
        '1 recovery win',
      );
      expect(
        summary.signals
            .singleWhere((signal) => signal.label == 'Nutrition context')
            .value,
        '135 g/day',
      );
      expect(
        summary.signals
            .singleWhere((signal) => signal.label == 'Adherence context')
            .status,
        'Pattern evidence',
      );
      expect(bodyCompositionCopyIsTrustSafe(summary), isTrue);
    },
  );

  test(
    'composition adherence uses wall-clock today, not stale latest session',
    () {
      final state = SessionState(
        history: [
          _session(
            id: 'composition-stale-1',
            day: 1,
            sets: const [
              LoggedSet(
                id: 'composition-stale-set-1',
                exerciseName: 'Trap bar deadlift',
                setNumber: 1,
                weightKg: 100,
                reps: 5,
                rpe: 7,
              ),
            ],
          ),
          _session(
            id: 'composition-stale-2',
            day: 2,
            sets: const [
              LoggedSet(
                id: 'composition-stale-set-2',
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

      final summary = buildBodyCompositionTrustSummary(
        state,
        now: DateTime(2026, 7, 20),
      );
      final adherence = summary.signals.singleWhere(
        (signal) => signal.label == 'Adherence context',
      );

      expect(summary.hasTrainingContext, isTrue);
      expect(adherence.value, '2 sessions');
      expect(adherence.status, 'Baseline');
      expect(bodyCompositionCopyIsTrustSafe(summary), isTrue);
    },
  );

  test(
    '1000 generated composition scenarios remain deterministic and safe',
    () {
      final now = DateTime(2026, 8, 10);
      for (var seed = 0; seed < 1000; seed += 1) {
        final state = _scenarioState(seed);
        final first = buildBodyCompositionTrustSummary(state, now: now);
        final second = buildBodyCompositionTrustSummary(state, now: now);

        expect(second.headline, first.headline, reason: 'scenario $seed');
        expect(
          second.semanticLabel,
          first.semanticLabel,
          reason: 'scenario $seed',
        );
        expect(first.signals, hasLength(4), reason: 'scenario $seed');
        expect(
          first.sourceIds,
          bodyCompositionTrustSourceIds,
          reason: 'scenario $seed',
        );
        expect(
          bodyCompositionCopyIsTrustSafe(first),
          isTrue,
          reason: 'scenario $seed',
        );
        expect(
          first.semanticLabel.toLowerCase(),
          isNot(contains('weight loss')),
          reason: 'scenario $seed',
        );
        expect(
          first.semanticLabel.toLowerCase(),
          isNot(contains('before and after')),
          reason: 'scenario $seed',
        );
        expect(
          first.semanticLabel.toLowerCase(),
          isNot(contains('shred')),
          reason: 'scenario $seed',
        );
      }
    },
  );
}

SessionState _scenarioState(int seed) {
  final sessionCount = seed % 8;
  final sessions = <WorkoutSession>[];
  for (var index = 0; index < sessionCount; index += 1) {
    final recovery = (seed + index) % 5 == 0;
    sessions.add(
      _session(
        id: 'composition-scenario-$seed-$index',
        day: 1 + index,
        notes: recovery ? 'Recovery mobility session.' : null,
        sets: recovery
            ? [
                LoggedSet(
                  id: 'composition-scenario-$seed-$index-recovery',
                  exerciseName: 'Mobility reset',
                  setNumber: 1,
                  durationSeconds: 480 + index,
                  rpe: 3,
                ),
              ]
            : [
                LoggedSet(
                  id: 'composition-scenario-$seed-$index-a',
                  exerciseName: index.isEven
                      ? 'Controlled press'
                      : 'Split squat',
                  setNumber: 1,
                  weightKg: 20 + (seed % 60),
                  reps: 5 + (index % 8),
                  rpe: 6 + (index % 4),
                ),
              ],
      ),
    );
  }

  return SessionState(
    nutritionTarget: seed.isEven
        ? NutritionTarget(
            id: 'composition-nutrition-$seed',
            createdAt: DateTime(2026, 7, 2, 7),
            targetType: 'protein',
            label: 'Protein target',
            dailyTarget: 90 + (seed % 90),
            unit: 'g/day',
          )
        : null,
    history: sessions,
  );
}

WorkoutSession _session({
  required String id,
  required int day,
  String? notes,
  required List<LoggedSet> sets,
}) {
  return WorkoutSession(
    id: id,
    startedAt: DateTime(2026, 7, day, 8),
    endedAt: DateTime(2026, 7, day, 8, 45),
    readinessEntryId: 'readiness-$id',
    loggedSets: sets,
    sessionNotes: notes,
  );
}
