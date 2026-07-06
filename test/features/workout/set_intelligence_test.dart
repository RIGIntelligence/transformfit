import 'package:flutter_test/flutter_test.dart';
import 'package:transformfit/features/session/models.dart';
import 'package:transformfit/features/workout/set_intelligence.dart';

void main() {
  test('previous set reference prefers stable exercise IDs and date context', () {
    final history = [
      WorkoutSession(
        id: 'history-1',
        startedAt: DateTime(2026, 6, 30, 8),
        readinessEntryId: 'readiness-oldest',
        loggedSets: const [
          LoggedSet(
            id: 'old-left',
            exerciseId: 'split_squat_left',
            exerciseName: 'Split Squat',
            setNumber: 1,
            weightKg: 25,
            reps: 8,
            rpe: 7,
          ),
        ],
      ),
      WorkoutSession(
        id: 'history-2',
        startedAt: DateTime(2026, 7, 1, 8),
        readinessEntryId: 'readiness-right',
        loggedSets: const [
          LoggedSet(
            id: 'new-right',
            exerciseId: 'split_squat_right',
            exerciseName: 'Split Squat',
            setNumber: 1,
            weightKg: 40,
            reps: 10,
            rpe: 8,
          ),
        ],
      ),
    ];

    final reference = previousSetReferenceForExercise(
      history,
      exerciseName: 'Split Squat',
      exerciseId: 'split_squat_right',
    );

    expect(reference?.set.id, 'new-right');
    expect(
      previousSetReferenceLabel(reference),
      'Jul 1 · Split Squat, 40 kg x 10 reps, RPE 8 · readiness check-in readiness-right',
    );
  });

  test('set intelligence explains progression intent and rest pace', () {
    final previousReference = PreviousSetReference(
      session: WorkoutSession(
        id: 'history',
        startedAt: DateTime(2026, 7, 1, 8),
        readinessEntryId: 'readiness-history',
        loggedSets: const [],
      ),
      set: const LoggedSet(
        id: 'set-1',
        exerciseName: 'Goblet squat',
        setNumber: 1,
        weightKg: 40,
        reps: 8,
        rpe: 7,
      ),
    );

    final intelligence = buildSetIntelligence(
      previousReference: previousReference,
      readiness: _readiness(score: 78, zone: 'push'),
      currentWeightKg: 40,
      currentReps: 8,
      currentRpe: 7,
      selectedRestSeconds: 90,
      prescribedRestSeconds: 90,
    );

    expect(intelligence.progressionIntent, 'Add one rep next');
    expect(intelligence.restPace, 'On pace');
    expect(intelligence.previousReference, contains('Jul 1'));
    expect(intelligence.readinessContext, 'push 78/100');
    expect(
      intelligence.postSetCountdown,
      'Post-set countdown: selected 1:30 / prescribed 1:30.',
    );
    expect(
      intelligence.sourceIds,
      contains('src_macrofactor_workouts_product'),
    );
  });

  test('set intelligence reduces target on low readiness before overload', () {
    final intelligence = buildSetIntelligence(
      previousReference: null,
      readiness: _readiness(score: 38, zone: 'recover'),
      currentWeightKg: 60,
      currentReps: 10,
      currentRpe: 6,
      selectedRestSeconds: 60,
      prescribedRestSeconds: 120,
    );

    expect(intelligence.progressionIntent, 'Reduce target');
    expect(intelligence.restPace, 'Short rest');
    expect(intelligence.progressionReason, contains('Readiness is low'));
  });

  test('set intelligence detects load progression and long rest', () {
    final intelligence = buildSetIntelligence(
      previousReference: _previous(weightKg: 100, reps: 5, rpe: 8, day: 1),
      readiness: _readiness(score: 82, zone: 'push'),
      currentWeightKg: 105,
      currentReps: 5,
      currentRpe: 8,
      selectedRestSeconds: 180,
      prescribedRestSeconds: 120,
    );

    expect(intelligence.progressionIntent, 'Load progression');
    expect(intelligence.restPace, 'Long rest');
  });

  test('set intelligence blocks progression when pain safety is active', () {
    final intelligence = buildSetIntelligence(
      previousReference: _previous(weightKg: 40, reps: 8, rpe: 7, day: 1),
      readiness: _readiness(score: 82, zone: 'push'),
      currentWeightKg: 45,
      currentReps: 8,
      currentRpe: 8,
      selectedRestSeconds: 90,
      prescribedRestSeconds: 90,
      painSafetyActive: true,
    );

    expect(intelligence.progressionIntent, 'Pain safety');
    expect(intelligence.progressionReason, contains('block load progression'));
    expect(intelligence.semanticLabel, contains('Pain safety'));
  });

  test(
    '1000 generated set intelligence scenarios stay deterministic and safe',
    () {
      final results = <String>{};

      for (var index = 0; index < 1000; index += 1) {
        final readinessScore = 35 + (index % 61);
        final zone = index % 7 == 0
            ? 'recover'
            : index % 5 == 0
            ? 'maintain'
            : 'push';
        final prescribedRest = 60 + (index % 5) * 30;
        final selectedRest = index % 11 == 0
            ? 0
            : (prescribedRest + ((index % 7) - 3) * 15).clamp(0, 300);
        final currentWeight = 20 + (index % 31) * 5;
        final currentReps = 4 + (index % 12);
        final currentRpe = 5 + (index % 5);
        final previousReference = index % 9 == 0
            ? null
            : _previous(
                weightKg: (currentWeight - ((index % 3) * 5)).clamp(0, 300),
                reps: (currentReps - (index % 2)).clamp(1, 60),
                rpe: 6 + (index % 4),
                day: 1 + (index % 28),
              );

        final intelligence = buildSetIntelligence(
          previousReference: previousReference,
          readiness: _readiness(score: readinessScore, zone: zone),
          currentWeightKg: currentWeight,
          currentReps: currentReps,
          currentRpe: currentRpe,
          selectedRestSeconds: selectedRest,
          prescribedRestSeconds: prescribedRest,
        );

        results.add(
          '${intelligence.progressionIntent}|${intelligence.restPace}',
        );
        expect(intelligence.progressionIntent.trim(), isNotEmpty);
        expect(intelligence.progressionReason.trim(), isNotEmpty);
        expect(intelligence.restDetail.trim(), isNotEmpty);
        expect(intelligence.previousReference.trim(), isNotEmpty);
        expect(intelligence.semanticLabel, contains('Progression intent'));
        expect(intelligence.sourceIds, hasLength(6));
        expect(
          intelligence.semanticLabel.toLowerCase(),
          isNot(contains('punish')),
        );
        expect(
          intelligence.semanticLabel.toLowerCase(),
          isNot(contains('shame')),
        );
      }

      expect(results.length, greaterThanOrEqualTo(8));
    },
  );
}

ReadinessEntry _readiness({required int score, required String zone}) {
  return ReadinessEntry(
    id: 'readiness-$score-$zone',
    date: DateTime(2026, 7, 2),
    score: score,
    zone: zone,
    energyLevel: 8,
    sleepQuality: 8,
    sorenessMap: const ['hips'],
  );
}

PreviousSetReference _previous({
  required int weightKg,
  required int reps,
  required int rpe,
  required int day,
}) {
  return PreviousSetReference(
    session: WorkoutSession(
      id: 'history-$day',
      startedAt: DateTime(2026, 7, day, 8),
      readinessEntryId: 'readiness-history-$day',
      loggedSets: const [],
    ),
    set: LoggedSet(
      id: 'set-$day',
      exerciseName: 'Goblet squat',
      setNumber: 1,
      weightKg: weightKg.toDouble(),
      reps: reps,
      rpe: rpe,
    ),
  );
}
