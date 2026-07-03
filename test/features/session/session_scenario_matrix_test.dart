import 'package:flutter_test/flutter_test.dart';
import 'package:transformfit/features/session/session_controller.dart';

void main() {
  test('1000 deterministic session scenarios preserve core invariants', () {
    for (var seed = 0; seed < 1000; seed += 1) {
      final controller = SessionController();
      final energy = (seed % 10) + 1;
      final sleep = ((seed ~/ 10) % 10) + 1;
      final soreness = <String>[
        if (seed.isEven) 'hips',
        if (seed % 3 == 0) 'back',
        if (seed % 5 == 0) 'shoulders',
        if (seed % 7 == 0) 'ankles',
      ];

      controller.submitReadiness(
        energyLevel: energy,
        sleepQuality: sleep,
        sorenessMap: soreness,
        hrv: seed % 4 == 0 ? 42 + (seed % 40) : null,
      );
      controller.startSession();

      final active = controller.state.activeSession;
      expect(active, isNotNull, reason: 'seed $seed should start a session');
      expect(
        active!.readinessEntryId,
        controller.state.readinessEntry!.id,
        reason: 'seed $seed should link session to readiness',
      );

      final setCount = (seed % 3) + 1;
      for (var set = 1; set <= setCount; set += 1) {
        if (seed % 11 == 0 && set == 1) {
          controller.logSet(
            exerciseName: 'Recovery carry',
            setNumber: set,
            durationSeconds: 120 + (seed % 240),
            rpe: (seed % 6) + 3,
          );
        } else {
          controller.logSet(
            exerciseName: seed.isEven ? 'Goblet squat' : 'Dumbbell row',
            setNumber: set,
            weightKg: 15 + ((seed + set) % 45).toDouble(),
            reps: 5 + ((seed + set) % 12),
            rpe: (seed % 8) + 1,
          );
        }
      }

      if (seed % 13 == 0) {
        controller.removeLastSet();
        controller.logSet(
          exerciseName: 'Comeback set',
          setNumber: controller.state.activeSession!.loggedSets.length + 1,
          reps: 8,
          rpe: 5,
        );
      }

      expect(
        controller.state.activeSession!.loggedSets,
        isNotEmpty,
        reason: 'seed $seed should retain at least one logged set',
      );

      controller.endSession(notes: 'Scenario $seed completed.');
      expect(controller.state.activeSession, isNull);
      expect(controller.state.history, hasLength(1));
      expect(controller.state.history.single.endedAt, isNotNull);
      expect(controller.state.history.single.completedSets, greaterThan(0));

      controller.submitDebrief(
        perceivedExertion: (seed % 10) + 1,
        satisfaction: (seed % 5) + 1,
        painNotes: seed % 6 == 0 ? 'Monitor knee' : null,
        whatWorked: 'Seed $seed kept the appointment',
        nextSessionFocus: 'Repeat the first clean rep',
      );
      expect(controller.state.lastDebrief, isNotNull);
      expect(
        controller.state.lastDebrief!.sessionId,
        controller.state.history.single.id,
      );

      final restored = SessionState.fromJson(controller.state.toJson());
      expect(restored.history.single.completedSets, greaterThan(0));
      expect(restored.activeSession, isNull);
      expect(restored.lastDebrief, isNotNull);
    }
  });
}
