import 'package:flutter_test/flutter_test.dart';
import 'package:transformfit/features/session/models.dart';
import 'package:transformfit/features/session/session_controller.dart';

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
  });

  group('Session Debrief', () {
    test('submitDebrief creates debrief linked to last session', () {
      controller.submitReadiness(
        energyLevel: 8,
        sleepQuality: 8,
        sorenessMap: [],
      );
      controller.startSession();
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
      controller.submitDebrief(
        perceivedExertion: 5,
        satisfaction: 3,
      );
      expect(controller.state.lastDebrief, isNull);
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
      controller.endSession();

      controller.resetDay();

      expect(controller.state.readinessEntry, isNull);
      expect(controller.state.activeSession, isNull);
      expect(controller.state.history.length, 1);
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
  });
}
