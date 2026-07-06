import 'package:flutter_test/flutter_test.dart';
import 'package:transformfit/features/coaching/coach_command_center.dart';
import 'package:transformfit/features/session/models.dart';
import 'package:transformfit/features/session/session_controller.dart';
import 'package:transformfit/features/wearables/wearable_signal.dart';

void main() {
  group('CoachCommandCenter', () {
    test('empty state creates first command and required lanes', () {
      final center = buildCoachCommandCenter(const SessionState());

      expect(center.headline, 'First command is ready');
      expect(center.primaryAction, 'Connect wearable context');
      expect(center.riskLabel, 'Normal guardrails');
      expect(center.lanes.map((lane) => lane.id), contains('lane-dai-command'));
      expect(
        center.lanes.map((lane) => lane.id),
        contains('lane-wearable-readiness'),
      );
      expect(
        center.lanes.map((lane) => lane.id),
        contains('lane-behavior-repair'),
      );
      expect(
        center.lanes
            .singleWhere((lane) => lane.id == 'lane-behavior-repair')
            .status,
        'Day-zero activation',
      );
      expect(
        center.lanes.map((lane) => lane.id),
        contains('lane-review-readiness'),
      );
      expect(
        center.lanes
            .singleWhere((lane) => lane.id == 'lane-review-readiness')
            .status,
        'Build value',
      );
      expect(
        center.next24Hours,
        contains('Submit readiness with wearable HRV when available'),
      );
      expect(center.handoffSummary, contains('readiness pending'));
      expect(coachCommandCenterCopyIsGateSafe(center), isTrue);
    });

    test(
      'connected wearable and nutrition produce full coach review context',
      () {
        final center = buildCoachCommandCenter(
          SessionState(
            readinessEntry: ReadinessEntry(
              id: 'readiness-v25',
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
              id: 'nutrition-v25',
              createdAt: DateTime(2026, 7, 2),
              targetType: 'protein',
              label: 'Protein target',
              dailyTarget: 130,
              unit: 'g/day',
            ),
            history: [
              WorkoutSession(
                id: 'session-v25',
                startedAt: DateTime(2026, 7, 2, 6),
                endedAt: DateTime(2026, 7, 2, 6, 45),
                readinessEntryId: 'readiness-old',
                loggedSets: const [
                  LoggedSet(
                    id: 'set-v25',
                    exerciseName: 'Front squat',
                    setNumber: 1,
                    weightKg: 80,
                    reps: 6,
                    rpe: 7,
                  ),
                ],
              ),
            ],
            lastDebrief: SessionDebrief(
              id: 'debrief-v25',
              sessionId: 'session-v25',
              createdAt: DateTime(2026, 7, 2, 7),
              perceivedExertion: 7,
              satisfaction: 4,
            ),
          ),
          now: DateTime(2026, 7, 2, 8),
        );

        expect(center.headline, 'Review then progress');
        expect(center.primaryAction, 'Start from Today');
        expect(center.riskLabel, 'Normal guardrails');
        expect(center.handoffSummary, contains('1 completed session'));
        expect(
          center.lanes
              .singleWhere((lane) => lane.id == 'lane-nutrition')
              .status,
          'Protein target',
        );
        expect(
          center.lanes
              .singleWhere((lane) => lane.id == 'lane-training-ledger')
              .detail,
          contains('Top set: Front squat 80 kg x 6.'),
        );
        expect(
          center.lanes
              .singleWhere((lane) => lane.id == 'lane-behavior-repair')
              .status,
          'Proof recommitment',
        );
        expect(
          center.lanes
              .singleWhere((lane) => lane.id == 'lane-review-readiness')
              .status,
          'Build value',
        );
        expect(coachCommandCenterCopyIsGateSafe(center), isTrue);
      },
    );

    test('pain review overrides the command center risk label', () {
      final center = buildCoachCommandCenter(
        SessionState(
          history: [
            WorkoutSession(
              id: 'session-pain',
              startedAt: DateTime(2026, 7, 1, 8),
              endedAt: DateTime(2026, 7, 1, 8, 45),
              readinessEntryId: 'readiness-pain',
              loggedSets: const [
                LoggedSet(
                  id: 'set-pain',
                  exerciseName: 'Squat',
                  setNumber: 1,
                  weightKg: 80,
                  reps: 6,
                ),
              ],
            ),
          ],
          lastDebrief: SessionDebrief(
            id: 'debrief-pain',
            sessionId: 'session-pain',
            createdAt: DateTime(2026, 7, 1, 9),
            perceivedExertion: 8,
            satisfaction: 3,
            painNotes: 'Sharp knee pain.',
          ),
        ),
        now: DateTime(2026, 7, 3, 10),
      );

      expect(center.headline, 'Safety leads today');
      expect(center.riskLabel, 'Safety review');
      expect(center.primaryAction, 'Choose pain-free variation');
      expect(center.handoffSummary, contains('Pain review needed'));
      expect(
        center.lanes.singleWhere((lane) => lane.id == 'lane-safety').status,
        'Pain reported',
      );
      expect(
        center.lanes
            .singleWhere((lane) => lane.id == 'lane-behavior-repair')
            .status,
        'Pain safety repair',
      );
      expect(
        center.lanes
            .singleWhere((lane) => lane.id == 'lane-review-readiness')
            .status,
        'Safety hold',
      );
      expect(coachCommandCenterCopyIsGateSafe(center), isTrue);
    });

    test('activated positive natural break becomes review eligible', () {
      final center = buildCoachCommandCenter(
        SessionState(
          readinessEntry: ReadinessEntry(
            id: 'readiness-review',
            date: DateTime(2026, 7, 3),
            score: 78,
            zone: 'steady',
            energyLevel: 7,
            sleepQuality: 7,
            sorenessMap: const ['quads'],
          ),
          nutritionTarget: NutritionTarget(
            id: 'nutrition-review',
            createdAt: DateTime(2026, 7, 3),
            targetType: 'protein',
            label: 'Protein target',
            dailyTarget: 130,
            unit: 'g/day',
          ),
          history: [
            _completedReviewSession('session-review-1', DateTime(2026, 7, 1)),
            _completedReviewSession('session-review-2', DateTime(2026, 7, 3)),
          ],
          lastDebrief: SessionDebrief(
            id: 'debrief-review',
            sessionId: 'session-review-2',
            createdAt: DateTime(2026, 7, 3, 9),
            perceivedExertion: 7,
            satisfaction: 5,
            painNotes: 'No pain.',
          ),
        ),
      );

      final lane = center.lanes.singleWhere(
        (lane) => lane.id == 'lane-review-readiness',
      );
      expect(lane.label, 'Review readiness');
      expect(lane.status, 'Eligible at a natural break');
      expect(lane.detail, contains('Value has been earned'));
      expect(
        lane.nextAction,
        'Use the native review flow after the session recap',
      );
      expect(coachCommandCenterCopyIsGateSafe(center), isTrue);
    });
  });
}

WorkoutSession _completedReviewSession(String id, DateTime date) {
  return WorkoutSession(
    id: id,
    startedAt: DateTime(date.year, date.month, date.day, 8),
    endedAt: DateTime(date.year, date.month, date.day, 8, 45),
    readinessEntryId: 'readiness-$id',
    loggedSets: const [
      LoggedSet(
        id: 'set-review-1',
        exerciseName: 'Front squat',
        setNumber: 1,
        weightKg: 80,
        reps: 6,
      ),
      LoggedSet(
        id: 'set-review-2',
        exerciseName: 'Front squat',
        setNumber: 2,
        weightKg: 80,
        reps: 6,
      ),
      LoggedSet(
        id: 'set-review-3',
        exerciseName: 'Front squat',
        setNumber: 3,
        weightKg: 80,
        reps: 6,
      ),
    ],
  );
}
