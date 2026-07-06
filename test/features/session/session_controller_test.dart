import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:transformfit/features/session/models.dart';
import 'package:transformfit/features/session/session_controller.dart';
import 'package:transformfit/features/wearables/wearable_signal.dart';

void main() {
  late SessionController controller;

  setUp(() {
    controller = SessionController();
  });

  group('Readiness Entry', () {
    test('submitReadiness creates a readiness entry with computed score', () {
      controller.submitReadiness(
        energyLevel: 8,
        sleepQuality: 9,
        sorenessMap: [],
      );

      final entry = controller.state.readinessEntry;
      expect(entry, isNotNull);
      expect(entry!.energyLevel, 8);
      expect(entry.sleepQuality, 9);
      // Without HRV: score = 90*0.55 + 80*0.45 = 49.5 + 36 = 85.5 -> 86
      expect(entry.score, greaterThan(80));
      expect(entry.zone, 'push'); // score >= 75
    });

    test('high soreness reduces score and can push to deload zone', () {
      controller.submitReadiness(
        energyLevel: 5,
        sleepQuality: 5,
        sorenessMap: ['quads', 'hamstrings', 'chest', 'back'],
      );

      final entry = controller.state.readinessEntry!;
      // sorenessPenalty = min(20, 4*5) = 20
      // score = 50*0.55 + 50*0.45 - 20 = 27.5 + 22.5 - 20 = 30
      expect(entry.score, lessThanOrEqualTo(30));
      expect(entry.zone, 'deload');
    });

    test('readiness with HRV uses the with_hrv variant', () {
      controller.submitReadiness(
        energyLevel: 8,
        sleepQuality: 8,
        sorenessMap: [],
        hrv: 80,
      );

      // hrvScore = min(100, 80/120 * 100) = 66.67
      // sleepScore = 8/10 * 60 = 48
      // energyScore = 8/10 * 40 = 32
      // raw = 66.67*0.4 + 48*0.35 + 32*0.25 = 26.67 + 16.8 + 8 = 51.47
      final entry = controller.state.readinessEntry!;
      expect(entry.hrv, 80);
      expect(entry.score, greaterThan(40));
    });
  });

  group('Session Logging', () {
    test('startSession creates active session linked to readiness entry', () {
      controller.submitReadiness(
        energyLevel: 8,
        sleepQuality: 8,
        sorenessMap: [],
      );
      controller.startSession();

      final session = controller.state.activeSession;
      expect(session, isNotNull);
      expect(session!.readinessEntryId, controller.state.readinessEntry!.id);
      expect(session.loggedSets, isEmpty);
      expect(session.endedAt, isNull);
    });

    test('startSession without readiness entry is a no-op', () {
      controller.startSession();
      expect(controller.state.activeSession, isNull);
    });

    test('startSession can atomically attach the active session plan', () {
      controller.submitReadiness(
        energyLevel: 8,
        sleepQuality: 8,
        sorenessMap: [],
      );

      controller.startSession(
        plan: const [
          SessionPlanExercise(
            exerciseId: 'split_squat_left',
            exerciseName: 'Split Squat',
            targetSets: 1,
            targetReps: 8,
            targetRpe: 7,
            targetRestSeconds: 90,
          ),
        ],
      );

      expect(controller.state.activeSession, isNotNull);
      expect(controller.state.activeSessionPlan, hasLength(1));
      expect(
        controller.state.activeSessionPlan.single.exerciseId,
        'split_squat_left',
      );
    });

    test(
      'attachActiveSessionPlan accepts an empty list as an explicit clear',
      () {
        controller.submitReadiness(
          energyLevel: 8,
          sleepQuality: 8,
          sorenessMap: [],
        );
        controller.startSession(
          plan: const [
            SessionPlanExercise(
              exerciseId: 'tempo_squat',
              exerciseName: 'Tempo Squat',
              targetSets: 2,
              targetReps: 6,
              targetRpe: 7,
              targetRestSeconds: 120,
            ),
          ],
        );

        expect(controller.state.activeSession, isNotNull);
        expect(controller.state.activeSessionPlan, hasLength(1));

        controller.attachActiveSessionPlan(const []);

        expect(controller.state.activeSession, isNotNull);
        expect(controller.state.activeSessionPlan, isEmpty);
      },
    );

    test('active session locks readiness and duplicate starts', () {
      controller.submitReadiness(
        energyLevel: 8,
        sleepQuality: 8,
        sorenessMap: [],
      );
      controller.startSession();
      controller.logSet(
        exerciseName: 'Bench Press',
        setNumber: 1,
        weightKg: 80,
        reps: 8,
      );

      final readinessId = controller.state.readinessEntry!.id;
      final active = controller.state.activeSession!;
      final activeId = active.id;
      final startedAt = active.startedAt;

      controller.submitReadiness(
        energyLevel: 5,
        sleepQuality: 5,
        sorenessMap: ['quads', 'hamstrings', 'chest', 'back'],
      );
      controller.startSession();

      expect(controller.state.readinessEntry!.id, readinessId);
      expect(controller.state.readinessEntry!.zone, 'push');
      expect(controller.state.activeSession!.id, activeId);
      expect(controller.state.activeSession!.startedAt, startedAt);
      expect(controller.state.activeSession!.readinessEntryId, readinessId);
      expect(controller.state.activeSession!.loggedSets, hasLength(1));
      expect(
        controller.state.activeSession!.loggedSets.single.exerciseName,
        'Bench Press',
      );
      expect(controller.state.activeSession!.volumeMultiplier, 1.10);
    });

    test('logSet adds sets to the active session', () {
      controller.submitReadiness(
        energyLevel: 8,
        sleepQuality: 8,
        sorenessMap: [],
      );
      controller.startSession();

      controller.logSet(
        exerciseName: 'Bench Press',
        setNumber: 1,
        weightKg: 80,
        reps: 8,
      );
      controller.logSet(
        exerciseName: 'Bench Press',
        setNumber: 2,
        weightKg: 85,
        reps: 6,
      );

      final session = controller.state.activeSession!;
      expect(session.loggedSets.length, 2);
      expect(session.totalSets, 2);
      expect(session.completedSets, 2);
      expect(session.totalVolume, 80 * 8 + 85 * 6);
    });

    test('logSet trims exercise names at the controller boundary', () {
      controller.submitReadiness(
        energyLevel: 8,
        sleepQuality: 8,
        sorenessMap: [],
      );
      controller.startSession();

      controller.logSet(
        exerciseName: '  Front Squat  ',
        setNumber: 1,
        exerciseId: '  front_squat  ',
        weightKg: 60,
        reps: 8,
        rpe: 7,
      );

      expect(
        controller.state.activeSession!.loggedSets.single.exerciseName,
        'Front Squat',
      );
      expect(
        controller.state.activeSession!.loggedSets.single.exerciseId,
        'front_squat',
      );
    });

    test('logSet rejects invalid direct inputs', () {
      controller.submitReadiness(
        energyLevel: 8,
        sleepQuality: 8,
        sorenessMap: [],
      );
      controller.startSession();

      controller.logSet(exerciseName: '   ', setNumber: 1, reps: 8);
      controller.logSet(exerciseName: 'Row', setNumber: 0, reps: 8);
      controller.logSet(
        exerciseName: 'Row',
        setNumber: 1,
        weightKg: -20,
        reps: 8,
      );
      controller.logSet(
        exerciseName: 'Row',
        setNumber: 1,
        weightKg: double.nan,
        reps: 8,
      );
      controller.logSet(
        exerciseName: 'Row',
        setNumber: 1,
        weightKg: double.infinity,
        reps: 8,
      );
      controller.logSet(exerciseName: 'Row', setNumber: 1, reps: 0);
      controller.logSet(exerciseName: 'Row', setNumber: 1, durationSeconds: 0);
      controller.logSet(exerciseName: 'Row', setNumber: 1);
      controller.logSet(exerciseName: 'Row', setNumber: 1, reps: 8, rpe: 11);
      controller.logSet(exerciseName: 'Row', setNumber: 1, reps: 8, rpe: 0);
      controller.logSet(
        exerciseName: 'Row',
        setNumber: 1,
        reps: 8,
        prescribedRestSeconds: -1,
      );
      controller.logSet(
        exerciseName: 'Row',
        setNumber: 1,
        reps: 8,
        actualRestSeconds: -1,
      );
      controller.logSet(
        exerciseName: 'Row',
        setNumber: 1,
        reps: 8,
        actualRestSeconds: 7201,
      );

      expect(controller.state.activeSession!.loggedSets, isEmpty);

      controller.logSet(
        exerciseName: 'Timed carry',
        setNumber: 1,
        durationSeconds: 45,
        rpe: 6,
      );

      final loggedSet = controller.state.activeSession!.loggedSets.single;
      expect(loggedSet.exerciseName, 'Timed carry');
      expect(loggedSet.durationSeconds, 45);
      expect(loggedSet.rpe, 6);
    });

    test('logSet records loggedAt and rest timing fields', () {
      controller.submitReadiness(
        energyLevel: 8,
        sleepQuality: 8,
        sorenessMap: [],
      );
      controller.startSession();
      final loggedAt = DateTime(2026, 7, 3, 10, 15, 30);

      controller.logSet(
        exerciseName: 'Bench Press',
        setNumber: 1,
        loggedAt: loggedAt,
        weightKg: 80,
        reps: 8,
        rpe: 7,
        prescribedRestSeconds: 90,
        actualRestSeconds: 45,
      );

      final loggedSet = controller.state.activeSession!.loggedSets.single;
      expect(loggedSet.loggedAt, loggedAt);
      expect(loggedSet.prescribedRestSeconds, 90);
      expect(loggedSet.actualRestSeconds, 45);

      final restored = SessionState.fromJson(controller.state.toJson());
      final restoredSet = restored.activeSession!.loggedSets.single;
      expect(restoredSet.loggedAt, loggedAt);
      expect(restoredSet.prescribedRestSeconds, 90);
      expect(restoredSet.actualRestSeconds, 45);
    });

    test('removeLastSet removes the most recent active set only', () {
      controller.submitReadiness(
        energyLevel: 8,
        sleepQuality: 8,
        sorenessMap: [],
      );
      controller.startSession();

      controller.logSet(
        exerciseName: 'Bench Press',
        setNumber: 1,
        weightKg: 80,
        reps: 8,
      );
      controller.logSet(
        exerciseName: 'Bench Press',
        setNumber: 2,
        weightKg: 85,
        reps: 6,
      );

      controller.removeLastSet();

      final session = controller.state.activeSession!;
      expect(session.loggedSets, hasLength(1));
      expect(session.loggedSets.single.setNumber, 1);
      expect(session.loggedSets.single.weightKg, 80);
      expect(session.totalVolume, 80 * 8);

      controller.removeLastSet();
      expect(controller.state.activeSession!.loggedSets, isEmpty);

      controller.removeLastSet();
      expect(controller.state.activeSession!.loggedSets, isEmpty);
    });

    test('endSession moves session to history and clears active', () {
      controller.submitReadiness(
        energyLevel: 7,
        sleepQuality: 7,
        sorenessMap: [],
      );
      controller.startSession();
      controller.logSet(
        exerciseName: 'Squat',
        setNumber: 1,
        weightKg: 100,
        reps: 5,
      );
      controller.endSession(notes: 'Felt good');

      expect(controller.state.activeSession, isNull);
      expect(controller.state.history.length, 1);
      expect(controller.state.history.first.sessionNotes, 'Felt good');
      expect(controller.state.history.first.endedAt, isNotNull);
    });

    test('endSession without logged sets is a no-op', () {
      controller.submitReadiness(
        energyLevel: 7,
        sleepQuality: 7,
        sorenessMap: [],
      );
      controller.startSession();

      final activeSession = controller.state.activeSession!;
      controller.endSession(notes: 'Skipped workout');

      expect(controller.state.activeSession, same(activeSession));
      expect(controller.state.history, isEmpty);
    });

    test('endSession trims optional notes at the controller boundary', () {
      controller.submitReadiness(
        energyLevel: 7,
        sleepQuality: 7,
        sorenessMap: [],
      );
      controller.startSession();
      controller.logSet(exerciseName: 'Tempo squat', setNumber: 1, reps: 8);
      controller.endSession(notes: '  Felt stable through tempo  ');

      expect(
        controller.state.history.single.sessionNotes,
        'Felt stable through tempo',
      );

      controller.submitReadiness(
        energyLevel: 7,
        sleepQuality: 7,
        sorenessMap: [],
      );
      controller.startSession();
      controller.logSet(
        exerciseName: 'Mobility flow',
        setNumber: 1,
        durationSeconds: 60,
      );
      controller.endSession(notes: '   ');

      expect(controller.state.history.last.sessionNotes, isNull);
    });
  });

  group('Session Debrief', () {
    test('submitDebrief creates debrief linked to last session', () {
      controller.submitReadiness(
        energyLevel: 8,
        sleepQuality: 8,
        sorenessMap: [],
      );
      controller.startSession();
      controller.logSet(
        exerciseName: 'Goblet squat',
        setNumber: 1,
        weightKg: 20,
        reps: 10,
      );
      controller.endSession();
      controller.submitDebrief(
        perceivedExertion: 7,
        satisfaction: 4,
        whatWorked: 'Good energy',
        whatToChange: 'More rest between sets',
      );

      final debrief = controller.state.lastDebrief;
      expect(debrief, isNotNull);
      expect(debrief!.perceivedExertion, 7);
      expect(debrief.satisfaction, 4);
      expect(debrief.whatWorked, 'Good energy');
      expect(debrief.sessionId, controller.state.history.first.id);
    });

    test('submitDebrief without a session is a no-op', () {
      controller.submitDebrief(perceivedExertion: 5, satisfaction: 3);
      expect(controller.state.lastDebrief, isNull);
    });

    test('submitDebrief while a session is active is a no-op', () {
      controller.submitReadiness(
        energyLevel: 8,
        sleepQuality: 8,
        sorenessMap: [],
      );
      controller.startSession();
      controller.logSet(
        exerciseName: 'Goblet squat',
        setNumber: 1,
        weightKg: 20,
        reps: 10,
      );

      final activeSession = controller.state.activeSession!;
      controller.submitDebrief(
        perceivedExertion: 6,
        satisfaction: 4,
        whatWorked: 'Too early',
      );

      expect(controller.state.activeSession, same(activeSession));
      expect(controller.state.history, isEmpty);
      expect(controller.state.lastDebrief, isNull);
    });

    test('submitDebrief trims optional text at the controller boundary', () {
      controller.submitReadiness(
        energyLevel: 8,
        sleepQuality: 8,
        sorenessMap: [],
      );
      controller.startSession();
      controller.logSet(
        exerciseName: 'Goblet squat',
        setNumber: 1,
        weightKg: 20,
        reps: 10,
      );
      controller.endSession();

      controller.submitDebrief(
        perceivedExertion: 6,
        satisfaction: 4,
        painNotes: '  Left knee quiet  ',
        whatWorked: '  Good brace  ',
        whatToChange: '    ',
        nextSessionFocus: '\nPull strength\t',
      );

      final debrief = controller.state.lastDebrief!;
      expect(debrief.painNotes, 'Left knee quiet');
      expect(debrief.whatWorked, 'Good brace');
      expect(debrief.whatToChange, isNull);
      expect(debrief.nextSessionFocus, 'Pull strength');
    });

    test('submitDebrief rejects invalid direct ratings', () {
      controller.submitReadiness(
        energyLevel: 8,
        sleepQuality: 8,
        sorenessMap: [],
      );
      controller.startSession();
      controller.logSet(
        exerciseName: 'Goblet squat',
        setNumber: 1,
        weightKg: 20,
        reps: 10,
      );
      controller.endSession();
      controller.submitDebrief(
        perceivedExertion: 6,
        satisfaction: 4,
        whatWorked: 'Baseline',
      );
      final originalDebrief = controller.state.lastDebrief!;

      controller.submitDebrief(perceivedExertion: 0, satisfaction: 4);
      controller.submitDebrief(perceivedExertion: 11, satisfaction: 4);
      controller.submitDebrief(perceivedExertion: 6, satisfaction: 0);
      controller.submitDebrief(perceivedExertion: 6, satisfaction: 6);

      expect(controller.state.lastDebrief, same(originalDebrief));
    });
  });

  group('Full M3 Loop', () {
    test('complete readiness -> session -> debrief cycle', () {
      // 1. Readiness entry
      controller.submitReadiness(
        energyLevel: 9,
        sleepQuality: 8,
        sorenessMap: ['chest'],
      );
      expect(controller.state.readinessEntry, isNotNull);
      expect(controller.state.readinessEntry!.zone, isNotEmpty);

      // 2. Start session
      controller.startSession();
      expect(controller.state.activeSession, isNotNull);

      // 3. Log sets
      controller.logSet(
        exerciseName: 'Push Press',
        setNumber: 1,
        weightKg: 60,
        reps: 8,
        rpe: 7,
      );
      controller.logSet(
        exerciseName: 'Push Press',
        setNumber: 2,
        weightKg: 65,
        reps: 6,
        rpe: 8,
      );
      controller.logSet(
        exerciseName: 'Push Press',
        setNumber: 3,
        weightKg: 70,
        reps: 5,
        rpe: 9,
      );
      expect(controller.state.activeSession!.totalSets, 3);

      // 4. End session
      controller.endSession(notes: 'Strong day');
      expect(controller.state.history.length, 1);
      expect(controller.state.activeSession, isNull);

      // 5. Debrief
      controller.submitDebrief(
        perceivedExertion: 8,
        satisfaction: 5,
        whatWorked: 'Push press PR',
        nextSessionFocus: 'Pull movements',
      );
      expect(controller.state.lastDebrief, isNotNull);
      expect(controller.state.lastDebrief!.satisfaction, 5);
    });

    test('resetDay clears readiness but preserves history', () {
      controller.submitReadiness(
        energyLevel: 8,
        sleepQuality: 8,
        sorenessMap: [],
      );
      controller.startSession();
      controller.logSet(exerciseName: 'Goblet squat', setNumber: 1, reps: 10);
      controller.endSession();

      controller.resetDay();

      expect(controller.state.readinessEntry, isNull);
      expect(controller.state.activeSession, isNull);
      expect(controller.state.history.length, 1);
    });

    test('resetDay while a session is active is a no-op', () {
      controller.submitReadiness(
        energyLevel: 8,
        sleepQuality: 8,
        sorenessMap: [],
      );
      controller.startSession();
      controller.logSet(
        exerciseName: 'Front squat',
        setNumber: 1,
        weightKg: 60,
        reps: 8,
      );

      final readinessEntry = controller.state.readinessEntry!;
      final activeSession = controller.state.activeSession!;
      controller.resetDay();

      expect(controller.state.readinessEntry, same(readinessEntry));
      expect(controller.state.activeSession, same(activeSession));
      expect(controller.state.activeSession!.loggedSets, hasLength(1));
      expect(controller.state.history, isEmpty);
    });
  });

  group('Nutrition Target', () {
    test('setNutritionTarget creates a safe source-traced target', () {
      controller.setNutritionTarget(
        targetType: 'protein',
        label: 'Protein target',
        dailyTarget: 120,
        unit: 'g/day',
      );

      final target = controller.state.nutritionTarget;
      expect(target, isNotNull);
      expect(target!.targetType, 'protein');
      expect(target.label, 'Protein target');
      expect(target.targetDisplay, '120 g/day');
      expect(target.sourceIds, NutritionTarget.defaultSourceIds);
      expect(
        target.safetyNote.toLowerCase(),
        contains('not medical nutrition advice'),
      );
    });

    test('setNutritionTarget rejects unsafe or out-of-range targets', () {
      controller.setNutritionTarget(
        targetType: 'protein',
        label: 'Protein target',
        dailyTarget: 301,
        unit: 'g/day',
      );
      controller.setNutritionTarget(
        targetType: 'calorie_deficit',
        label: 'Calories',
        dailyTarget: 1800,
        unit: 'g/day',
      );
      controller.setNutritionTarget(
        targetType: 'protein',
        label: 'Protein target',
        dailyTarget: 120,
        unit: 'g/day',
        safetyNote: 'Personalized plan.',
      );

      expect(controller.state.nutritionTarget, isNull);
    });

    test('nutrition target survives JSON restore and resetDay', () {
      controller.submitReadiness(
        energyLevel: 8,
        sleepQuality: 8,
        sorenessMap: [],
      );
      controller.startSession();
      controller.logSet(exerciseName: 'Row', setNumber: 1, reps: 10);
      controller.endSession();
      controller.setNutritionTarget(
        targetType: 'protein',
        label: 'Protein target',
        dailyTarget: 135,
        unit: 'g/day',
      );

      controller.resetDay();
      final decoded = jsonDecode(jsonEncode(controller.snapshot()));
      final restored = SessionState.fromJson(
        Map<String, Object?>.from(decoded as Map),
      );

      expect(controller.state.nutritionTarget, isNotNull);
      expect(restored.nutritionTarget!.targetDisplay, '135 g/day');
      expect(restored.history, hasLength(1));
      expect(restored.readinessEntry, isNull);
    });

    test('clearNutritionTarget removes only the nutrition target', () {
      controller.submitReadiness(
        energyLevel: 8,
        sleepQuality: 8,
        sorenessMap: [],
      );
      controller.setNutritionTarget(
        targetType: 'protein',
        label: 'Protein target',
        dailyTarget: 120,
        unit: 'g/day',
      );

      controller.clearNutritionTarget();

      expect(controller.state.readinessEntry, isNotNull);
      expect(controller.state.nutritionTarget, isNull);
    });
  });

  group('Wearable Signal', () {
    test('wearable signal persists and can feed readiness HRV', () {
      controller.setWearableSignal(
        WearableSignal.localSample(capturedAt: DateTime(2026, 7, 2, 7, 30)),
      );
      controller.submitReadiness(
        energyLevel: 7,
        sleepQuality: 7,
        sorenessMap: const [],
        hrv: controller.state.wearableSignal?.heartRateVariabilityMs,
      );

      expect(controller.state.wearableSignal, isNotNull);
      expect(controller.state.readinessEntry!.hrv, 68);

      controller.resetDay();
      final decoded = jsonDecode(jsonEncode(controller.snapshot()));
      final restored = SessionState.fromJson(
        Map<String, Object?>.from(decoded as Map),
      );

      expect(restored.wearableSignal, isNotNull);
      expect(restored.wearableSignal!.source, 'local_sample');
      expect(restored.wearableSignal!.heartRateVariabilityMs, 68);
      expect(restored.readinessEntry, isNull);
    });

    test('invalid wearable signal is rejected at the controller boundary', () {
      controller.setWearableSignal(
        WearableSignal(
          id: 'wearable-invalid',
          capturedAt: DateTime(2026, 7, 2),
          source: 'unsupported_device',
          syncState: 'synced',
          stepsToday: 6400,
        ),
      );

      expect(controller.state.wearableSignal, isNull);
    });

    test('clearWearableSignal removes only wearable context', () {
      controller.submitReadiness(
        energyLevel: 8,
        sleepQuality: 8,
        sorenessMap: const [],
      );
      controller.setWearableSignal(
        WearableSignal.localSample(capturedAt: DateTime(2026, 7, 2, 7, 30)),
      );

      controller.clearWearableSignal();

      expect(controller.state.readinessEntry, isNotNull);
      expect(controller.state.wearableSignal, isNull);
    });
  });

  group('Models serialization', () {
    test('WorkoutSession toJson includes computed fields', () {
      final session = WorkoutSession(
        id: 'test-1',
        startedAt: DateTime(2026, 7, 1, 10),
        readinessEntryId: 're-1',
        loggedSets: [
          const LoggedSet(
            id: 's1',
            exerciseName: 'Squat',
            setNumber: 1,
            weightKg: 100,
            reps: 5,
          ),
          const LoggedSet(
            id: 's2',
            exerciseName: 'Squat',
            setNumber: 2,
            weightKg: 105,
            reps: 3,
          ),
        ],
      );

      final json = session.toJson();
      expect(json['totalSets'], 2);
      expect(json['completedSets'], 2);
      expect(json['totalVolume'], 100 * 5 + 105 * 3);
    });

    test('WorkoutSession effort units include bodyweight and timed work', () {
      final session = WorkoutSession(
        id: 'recovery-1',
        startedAt: DateTime(2026, 7, 1, 10),
        readinessEntryId: 're-1',
        loggedSets: const [
          LoggedSet(
            id: 's1',
            exerciseName: 'Trap Bar Deadlift',
            setNumber: 1,
            weightKg: 100,
            reps: 5,
          ),
          LoggedSet(
            id: 's2',
            exerciseName: 'Bodyweight Split Squat',
            setNumber: 2,
            reps: 12,
          ),
          LoggedSet(
            id: 's3',
            exerciseName: 'Side Plank',
            setNumber: 3,
            durationSeconds: 60,
          ),
          LoggedSet(
            id: 's4',
            exerciseName: 'Skipped Carry',
            setNumber: 4,
            durationSeconds: 90,
            completed: false,
          ),
        ],
      );

      final json = session.toJson();
      expect(session.totalVolume, 500);
      expect(session.totalEffortUnits, 19);
      expect(json['totalVolume'], 500);
      expect(json['totalEffortUnits'], 19);
    });

    test('SessionState snapshot survives a JSON encode/decode boundary', () {
      controller.submitReadiness(
        energyLevel: 8,
        sleepQuality: 7,
        sorenessMap: ['left shoulder'],
        hrv: 74,
      );
      controller.startSession();
      controller.logSet(
        exerciseName: 'Incline Dumbbell Press',
        setNumber: 1,
        weightKg: 30,
        reps: 10,
        rpe: 7,
      );
      controller.endSession(notes: 'No shoulder pain');
      controller.submitDebrief(
        perceivedExertion: 7,
        satisfaction: 5,
        painNotes: 'Clear',
        whatWorked: 'Controlled tempo',
        nextSessionFocus: 'Pull strength',
      );
      controller.setNutritionTarget(
        targetType: 'protein',
        label: 'Protein target',
        dailyTarget: 120,
        unit: 'g/day',
      );
      controller.setWearableSignal(
        WearableSignal.localSample(capturedAt: DateTime(2026, 7, 2, 7, 30)),
      );

      final decoded = jsonDecode(jsonEncode(controller.snapshot()));
      final restoredState = SessionState.fromJson(
        Map<String, Object?>.from(decoded as Map),
      );
      final restoredController = SessionController(initialState: restoredState);

      expect(restoredController.state.readinessEntry!.hrv, 74);
      expect(restoredController.state.readinessEntry!.sorenessMap, [
        'left shoulder',
      ]);
      expect(restoredController.state.history, hasLength(1));
      expect(
        restoredController.state.history.single.loggedSets.single.exerciseName,
        'Incline Dumbbell Press',
      );
      expect(restoredController.state.history.single.loggedSets.single.rpe, 7);
      expect(
        restoredController.state.history.single.sessionNotes,
        'No shoulder pain',
      );
      expect(
        restoredController.state.lastDebrief!.whatWorked,
        'Controlled tempo',
      );
      expect(
        restoredController.state.lastDebrief!.nextSessionFocus,
        'Pull strength',
      );
      expect(
        restoredController.state.nutritionTarget!.targetDisplay,
        '120 g/day',
      );
      expect(
        restoredController.state.wearableSignal!.sourceLabel,
        'Local wearable sample',
      );
    });

    test('SessionController writes snapshots after state mutations', () async {
      final writes = <SessionState>[];
      final persistedController = SessionController(
        snapshotWriter: (state) async {
          writes.add(state);
        },
      );

      persistedController.submitReadiness(
        energyLevel: 8,
        sleepQuality: 8,
        sorenessMap: [],
      );
      persistedController.startSession();
      persistedController.logSet(
        exerciseName: 'Row',
        setNumber: 1,
        weightKg: 45,
        reps: 10,
      );
      persistedController.endSession(notes: 'Smooth');
      persistedController.submitDebrief(perceivedExertion: 6, satisfaction: 5);
      persistedController.setNutritionTarget(
        targetType: 'protein',
        label: 'Protein target',
        dailyTarget: 120,
        unit: 'g/day',
      );
      await persistedController.snapshotWritesIdle;

      expect(writes, hasLength(6));
      expect(writes.last.lastDebrief, isNotNull);
      expect(writes.last.nutritionTarget, isNotNull);
      expect(writes.last.history.single.sessionNotes, 'Smooth');
    });

    test('snapshot writes are serialized in mutation order', () async {
      final startedWrites = <SessionState>[];
      final pendingWrites = <Completer<void>>[];
      final persistedController = SessionController(
        snapshotWriter: (state) {
          startedWrites.add(state);
          final completer = Completer<void>();
          pendingWrites.add(completer);
          return completer.future;
        },
      );

      persistedController.submitReadiness(
        energyLevel: 8,
        sleepQuality: 8,
        sorenessMap: [],
      );
      persistedController.startSession();
      persistedController.logSet(
        exerciseName: 'Row',
        setNumber: 1,
        weightKg: 45,
        reps: 10,
      );
      await Future<void>.delayed(Duration.zero);

      expect(startedWrites, hasLength(1));
      expect(startedWrites.single.readinessEntry, isNotNull);
      expect(startedWrites.single.activeSession, isNull);

      pendingWrites.single.complete();
      await Future<void>.delayed(Duration.zero);

      expect(startedWrites, hasLength(2));
      expect(startedWrites.last.activeSession, isNotNull);
      expect(startedWrites.last.activeSession!.loggedSets, isEmpty);

      pendingWrites.last.complete();
      await Future<void>.delayed(Duration.zero);

      expect(startedWrites, hasLength(3));
      expect(startedWrites.last.activeSession!.loggedSets, hasLength(1));
      expect(
        startedWrites.last.activeSession!.loggedSets.single.exerciseName,
        'Row',
      );

      pendingWrites.last.complete();
      await persistedController.snapshotWritesIdle;
    });

    test('snapshot persistence failures do not block later writes', () async {
      var attempts = 0;
      final successfulWrites = <SessionState>[];
      final persistedController = SessionController(
        snapshotWriter: (state) async {
          attempts += 1;
          if (attempts == 1) {
            throw StateError('storage unavailable');
          }
          successfulWrites.add(state);
        },
      );

      persistedController.submitReadiness(
        energyLevel: 8,
        sleepQuality: 8,
        sorenessMap: [],
      );
      persistedController.startSession();
      await persistedController.snapshotWritesIdle;

      expect(attempts, equals(2));
      expect(successfulWrites, hasLength(1));
      expect(successfulWrites.single.activeSession, isNotNull);
    });
  });
}
