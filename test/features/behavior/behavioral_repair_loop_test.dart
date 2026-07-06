import 'package:flutter_test/flutter_test.dart';
import 'package:transformfit/features/behavior/behavioral_repair_loop.dart';
import 'package:transformfit/features/session/models.dart';
import 'package:transformfit/features/session/session_controller.dart';

void main() {
  group('Behavioral repair loop', () {
    test('empty state routes to day-zero activation', () {
      final loop = buildBehavioralRepairLoop(
        const SessionState(),
        now: DateTime(2026, 7, 2, 8),
      );

      expect(loop.mode, BehavioralRepairMode.dayZeroActivation);
      expect(loop.headline, 'Make starting feel safe');
      expect(loop.emotionalNeed, 'Belong before performance.');
      expect(loop.repairAction, 'Start with a 30-second readiness check.');
      expect(loop.sourceIds, contains('src_transformfit_behavioral_sidecar'));
      expect(behavioralRepairCopyIsGateSafe(loop), isTrue);
    });

    test('stale first check-in routes to comeback reset', () {
      final loop = buildBehavioralRepairLoop(
        SessionState(
          readinessEntry: ReadinessEntry(
            id: 'readiness-stale-repair',
            date: DateTime(2026, 7, 2, 7),
            score: 86,
            zone: 'push',
            energyLevel: 8,
            sleepQuality: 9,
            sorenessMap: const [],
            createdAt: DateTime(2026, 7, 2, 7),
          ),
        ),
        now: DateTime(2026, 7, 2, 12),
      );

      expect(loop.mode, BehavioralRepairMode.staleCheckIn);
      expect(loop.headline, 'Save the day without pretending');
      expect(loop.repairAction, 'Save today with an 8-minute recovery reset.');
      expect(loop.microCommitment, contains('Four minutes walk'));
      expect(behavioralRepairCopyIsGateSafe(loop), isTrue);
    });

    test('low readiness routes to recovery kept promise', () {
      final loop = buildBehavioralRepairLoop(
        SessionState(
          readinessEntry: ReadinessEntry(
            id: 'readiness-low-repair',
            date: DateTime(2026, 7, 2, 7),
            score: 32,
            zone: 'deload',
            energyLevel: 4,
            sleepQuality: 4,
            sorenessMap: const ['hips', 'back', 'shoulders'],
            createdAt: DateTime(2026, 7, 2, 7),
          ),
        ),
        now: DateTime(2026, 7, 2, 8),
      );

      expect(loop.mode, BehavioralRepairMode.recoveryKeptPromise);
      expect(loop.headline, 'Turn low readiness into a kept promise');
      expect(loop.repairAction, contains('12-minute mobility'));
      expect(loop.safetyBoundary, contains('No loaded pain work'));
      expect(behavioralRepairCopyIsGateSafe(loop), isTrue);
    });

    test('reported pain routes to pain safety repair', () {
      final history = [
        WorkoutSession(
          id: 'session-pain-repair',
          startedAt: DateTime(2026, 7, 1, 8),
          endedAt: DateTime(2026, 7, 1, 8, 40),
          readinessEntryId: 'readiness-old',
          loggedSets: const [
            LoggedSet(
              id: 'set-pain-repair',
              exerciseName: 'Squat',
              setNumber: 1,
              weightKg: 80,
              reps: 5,
              rpe: 7,
            ),
          ],
        ),
      ];
      final loop = buildBehavioralRepairLoop(
        SessionState(
          history: history,
          lastDebrief: SessionDebrief(
            id: 'debrief-pain-repair',
            sessionId: 'session-pain-repair',
            createdAt: DateTime(2026, 7, 1, 8, 45),
            perceivedExertion: 7,
            satisfaction: 3,
            painNotes: 'Sharp knee pain on rep five.',
          ),
        ),
        now: DateTime(2026, 7, 2, 8),
      );

      expect(loop.mode, BehavioralRepairMode.painSafety);
      expect(loop.headline, 'Protect trust before load');
      expect(
        loop.repairAction,
        'Choose a pain-free variation before any progression.',
      );
      expect(loop.safetyBoundary, contains('Stop sharp'));
      expect(behavioralRepairCopyIsGateSafe(loop), isTrue);
    });

    test('missed day routes to comeback without catch-up volume', () {
      final loop = buildBehavioralRepairLoop(
        SessionState(
          history: [
            WorkoutSession(
              id: 'session-missed-repair',
              startedAt: DateTime(2026, 6, 30, 8),
              endedAt: DateTime(2026, 6, 30, 8, 45),
              readinessEntryId: 'readiness-old',
              loggedSets: const [
                LoggedSet(
                  id: 'set-missed-repair',
                  exerciseName: 'Trap bar deadlift',
                  setNumber: 1,
                  weightKg: 120,
                  reps: 5,
                  rpe: 7,
                ),
              ],
            ),
          ],
        ),
        now: DateTime(2026, 7, 2, 9),
      );

      expect(loop.mode, BehavioralRepairMode.missedDayComeback);
      expect(loop.headline, 'Make return smaller than avoidance');
      expect(loop.repairAction, 'Begin with readiness, then one warm-up set.');
      expect(loop.safetyBoundary, 'Do not add missed volume back into today.');
      expect(behavioralRepairCopyIsGateSafe(loop), isTrue);
    });
  });
}
