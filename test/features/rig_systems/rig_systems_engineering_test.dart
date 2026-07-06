import 'package:flutter_test/flutter_test.dart';
import 'package:transformfit/features/rig_systems/rig_systems_engineering.dart';
import 'package:transformfit/features/session/models.dart';
import 'package:transformfit/features/session/session_controller.dart';
import 'package:transformfit/features/wearables/wearable_signal.dart';

void main() {
  group('RIG systems engineering', () {
    test('full A1 A2 A3 A4 archetypes and BMS bands are defined', () {
      expect(rigBuildModeArchetypes.map((item) => item.mode), [
        RigBuildMode.a1,
        RigBuildMode.a2,
        RigBuildMode.a3,
        RigBuildMode.a4,
      ]);
      expect(rigArchetypeForBms(0.82).label, 'A1 deterministic');
      expect(rigArchetypeForBms(0.60).label, 'A2 hybrid typed');
      expect(rigArchetypeForBms(0.33).label, 'A3 agent bounded');
      expect(rigArchetypeForBms(0.12).label, 'A4 LLM agent free');
    });

    test('empty state routes to A4 draft-only exploration', () {
      final snapshot = buildRigSystemsEngineeringSnapshot(const SessionState());

      expect(snapshot.selectedArchetype.mode, RigBuildMode.a4);
      expect(snapshot.bmsLabel, '0.22');
      expect(snapshot.coordinate, 'L4-D3-A4-I');
      expect(
        snapshot.killSwitch,
        'No external action, no prescription, no launch claim.',
      );
      expect(rigSystemsCopyIsGateSafe(snapshot), isTrue);
    });

    test('rich local state routes to A1 deterministic execution', () {
      final snapshot = buildRigSystemsEngineeringSnapshot(
        SessionState(
          readinessEntry: ReadinessEntry(
            id: 'readiness-rig',
            date: DateTime(2026, 7, 2),
            score: 82,
            zone: 'push',
            energyLevel: 8,
            sleepQuality: 8,
            sorenessMap: const ['hips'],
          ),
          wearableSignal: WearableSignal.localSample(
            capturedAt: DateTime(2026, 7, 2, 7),
          ),
          nutritionTarget: NutritionTarget(
            id: 'nutrition-rig',
            createdAt: DateTime(2026, 7, 2),
            targetType: 'protein',
            label: 'Protein target',
            dailyTarget: 130,
            unit: 'g/day',
          ),
          history: [
            WorkoutSession(
              id: 'session-rig',
              startedAt: DateTime(2026, 7, 1, 8),
              endedAt: DateTime(2026, 7, 1, 8, 45),
              readinessEntryId: 'readiness-old',
              loggedSets: const [
                LoggedSet(
                  id: 'set-rig',
                  exerciseName: 'Front squat',
                  setNumber: 1,
                  weightKg: 80,
                  reps: 6,
                ),
              ],
            ),
          ],
        ),
      );

      expect(snapshot.selectedArchetype.mode, RigBuildMode.a1);
      expect(snapshot.bmsLabel, '0.82');
      expect(snapshot.coordinate, 'L4-D2-A1-P');
    });

    test('pain state uses A1 safety override', () {
      final snapshot = buildRigSystemsEngineeringSnapshot(
        SessionState(
          lastDebrief: SessionDebrief(
            id: 'debrief-rig',
            sessionId: 'session-rig',
            createdAt: DateTime(2026, 7, 2),
            perceivedExertion: 8,
            satisfaction: 3,
            painNotes: 'Sharp knee pain.',
          ),
        ),
      );

      expect(snapshot.selectedArchetype.mode, RigBuildMode.a1);
      expect(snapshot.currentStep, RigProcessStep.quality);
      expect(
        snapshot.killSwitch,
        'Stop loaded progression until pain-free variation is selected.',
      );
    });

    test('triple double diamond maps D1 D2 D3 across IQRSQPI', () {
      final cells = buildTripleDoubleDiamondCells(RigBuildMode.a2);

      expect(cells.length, 21);
      for (final diamond in RigDiamond.values) {
        final diamondCells = cells.where((cell) => cell.diamond == diamond);
        expect(diamondCells.length, RigProcessStep.values.length);
        expect(
          diamondCells.map((cell) => cell.step).toSet(),
          RigProcessStep.values.toSet(),
        );
      }
      expect(cells.map((cell) => cell.coordinate), contains('L4-D1-A1-P'));
      expect(cells.map((cell) => cell.coordinate), contains('L4-D2-A2-S'));
      expect(cells.map((cell) => cell.coordinate), contains('L4-D3-A3-I'));
    });
  });
}
