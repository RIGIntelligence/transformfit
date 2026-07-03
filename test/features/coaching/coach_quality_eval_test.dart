import 'package:flutter_test/flutter_test.dart';
import 'package:transformfit/features/coaching/coach_quality_eval.dart';
import 'package:transformfit/features/coaching/coach_signal.dart';
import 'package:transformfit/features/session/models.dart';
import 'package:transformfit/features/session/session_controller.dart';

void main() {
  group('CoachQualityEval', () {
    test('day_zero_activation passes with source trace and next action', () {
      final verdict = buildCoachQualityVerdict(const SessionState());

      expect(verdict.passed, isTrue);
      expect(verdict.issueIds, isEmpty);
    });

    test('doms_or_low_readiness blocks load-push behavior', () {
      final verdict = buildCoachQualityVerdict(
        SessionState(
          readinessEntry: _readiness(
            id: 'readiness-low',
            score: 38,
            zone: 'deload',
            sleepQuality: 4,
            sorenessMap: const ['quads', 'hips', 'back'],
          ),
        ),
      );

      expect(verdict.passed, isTrue);
    });

    test('active coasting routes to challenger workflow', () {
      final verdict = buildCoachQualityVerdict(
        SessionState(
          readinessEntry: _readiness(id: 'readiness-coast'),
          activeSession: WorkoutSession(
            id: 'session-coast',
            startedAt: DateTime(2026, 7, 2, 8),
            readinessEntryId: 'readiness-coast',
            loggedSets: const [
              LoggedSet(
                id: 'set-1',
                exerciseName: 'Goblet squat',
                setNumber: 1,
                weightKg: 40,
                reps: 10,
                rpe: 5,
              ),
              LoggedSet(
                id: 'set-2',
                exerciseName: 'Goblet squat',
                setNumber: 2,
                weightKg: 40,
                reps: 10,
                rpe: 5,
              ),
              LoggedSet(
                id: 'set-3',
                exerciseName: 'Goblet squat',
                setNumber: 3,
                weightKg: 40,
                reps: 10,
                rpe: 4,
              ),
            ],
          ),
        ),
      );

      expect(verdict.passed, isTrue);
    });

    test('active_session_with_history routes to live guidance', () {
      final readiness = _readiness(id: 'readiness-live');
      final state = SessionState(
        readinessEntry: readiness,
        activeSession: WorkoutSession(
          id: 'session-live',
          startedAt: DateTime(2026, 7, 2, 8),
          readinessEntryId: readiness.id,
          loggedSets: const [
            LoggedSet(
              id: 'set-live-1',
              exerciseName: 'Goblet squat',
              setNumber: 1,
              weightKg: 40,
              reps: 8,
              rpe: 7,
            ),
          ],
        ),
        history: [
          _completedSession(
            id: 'session-history',
            startedAt: DateTime(2026, 7, 1, 8),
            endedAt: DateTime(2026, 7, 1, 8, 30),
            weightKg: 40,
            reps: 8,
          ),
        ],
      );

      final signal = buildCoachSignal(state);
      final verdict = evaluateCoachSignal(state: state, signal: signal);

      expect(signal.workflowId, 'live_session_guidance');
      expect(signal.nextAction, 'Log the next clean set');
      expect(verdict.passed, isTrue);
    });

    test('rapid_volume_jump routes to hold-volume challenger signal', () {
      final verdict = buildCoachQualityVerdict(
        SessionState(
          history: [
            _completedSession(
              id: 'session-previous',
              startedAt: DateTime(2026, 7, 1, 8),
              endedAt: DateTime(2026, 7, 1, 8, 30),
              weightKg: 40,
              reps: 8,
            ),
            _completedSession(
              id: 'session-latest',
              startedAt: DateTime(2026, 7, 2, 8),
              endedAt: DateTime(2026, 7, 2, 8, 35),
              weightKg: 80,
              reps: 10,
            ),
          ],
        ),
      );

      expect(verdict.passed, isTrue);
    });

    test('reported_pain blocks progression and routes to guardrail', () {
      final verdict = buildCoachQualityVerdict(
        SessionState(
          readinessEntry: _readiness(id: 'readiness-pain'),
          lastDebrief: SessionDebrief(
            id: 'debrief-pain',
            sessionId: 'session-pain',
            createdAt: DateTime(2026, 7, 2, 9),
            perceivedExertion: 8,
            satisfaction: 3,
            painNotes: 'Right shoulder pain during the final press.',
          ),
        ),
      );

      expect(verdict.passed, isTrue);
    });

    test('unsafe_copy is reported by the evaluator', () {
      const unsafe = CoachSignal(
        workflowId: 'day_0_activation',
        persona: 'motivator',
        coachNote: 'Coach note: No excuses, crush your goals today.',
        observationLabel: 'First action',
        observation: 'No completed session is in the ledger yet.',
        nextAction: 'Submit readiness',
        confidence: 0.8,
        sourceIds: [
          'src_cal_ai_app_store_preview',
          'src_ladder_app_store_preview',
          'src_nike_run_club_app_store_preview',
        ],
        uxPrincipleIds: [
          'uxp_goal_to_session_continuity',
          'uxp_coach_voice_with_data_token',
        ],
      );

      final verdict = evaluateCoachSignal(
        state: const SessionState(),
        signal: unsafe,
      );

      expect(verdict.passed, isFalse);
      expect(verdict.issueIds, contains('copy_safety'));
    });
  });
}

ReadinessEntry _readiness({
  required String id,
  int score = 82,
  String zone = 'push',
  int sleepQuality = 8,
  List<String> sorenessMap = const [],
}) {
  return ReadinessEntry(
    id: id,
    date: DateTime(2026, 7, 2),
    score: score,
    zone: zone,
    energyLevel: 8,
    sleepQuality: sleepQuality,
    sorenessMap: sorenessMap,
  );
}

WorkoutSession _completedSession({
  required String id,
  required DateTime startedAt,
  required DateTime endedAt,
  required double weightKg,
  required int reps,
}) {
  return WorkoutSession(
    id: id,
    startedAt: startedAt,
    endedAt: endedAt,
    readinessEntryId: 'readiness-$id',
    loggedSets: [
      LoggedSet(
        id: 'set-$id-1',
        exerciseName: 'Deadlift',
        setNumber: 1,
        weightKg: weightKg,
        reps: reps,
        rpe: 8,
      ),
      LoggedSet(
        id: 'set-$id-2',
        exerciseName: 'Deadlift',
        setNumber: 2,
        weightKg: weightKg,
        reps: reps,
        rpe: 8,
      ),
    ],
  );
}
