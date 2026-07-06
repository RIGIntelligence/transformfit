import 'package:flutter_test/flutter_test.dart';
import 'package:transformfit/features/coaching/coach_signal.dart';
import 'package:transformfit/features/session/models.dart';
import 'package:transformfit/features/session/session_controller.dart';

void main() {
  group('CoachSignal', () {
    test('day zero activation is the default first-session workflow', () {
      final signal = buildCoachSignal(const SessionState());

      expect(signal.workflowId, 'day_0_activation');
      expect(signal.persona, 'motivator');
      expect(signal.sourceIds, hasLength(3));
      expect(
        signal.uxPrincipleIds,
        contains('uxp_coach_voice_with_data_token'),
      );
      expect(signal.coachNote, startsWith('Coach note:'));
      expect(coachSignalCopyIsGateSafe(signal), isTrue);
    });

    test('low readiness routes to recovery-protective coaching', () {
      final signal = buildCoachSignal(
        SessionState(
          readinessEntry: ReadinessEntry(
            id: 'readiness-low',
            date: DateTime(2026, 7, 2),
            score: 34,
            zone: 'deload',
            energyLevel: 4,
            sleepQuality: 4,
            sorenessMap: const ['hips', 'ankles', 'shoulders'],
          ),
        ),
      );

      expect(signal.workflowId, 'doms_or_low_readiness');
      expect(signal.persona, 'zen');
      expect(signal.observation, contains('34 readiness score'));
      expect(signal.nextAction, 'Choose recovery-safe session');
      expect(coachSignalCopyIsGateSafe(signal), isTrue);
    });

    test('reported pain routes to safety guardrail before progression', () {
      final readiness = ReadinessEntry(
        id: 'readiness-pain',
        date: DateTime(2026, 7, 2),
        score: 82,
        zone: 'push',
        energyLevel: 9,
        sleepQuality: 8,
        sorenessMap: const [],
      );
      final signal = buildCoachSignal(
        SessionState(
          readinessEntry: readiness,
          lastDebrief: SessionDebrief(
            id: 'debrief-pain',
            sessionId: 'session-pain',
            createdAt: DateTime(2026, 7, 2, 9),
            perceivedExertion: 8,
            satisfaction: 3,
            painNotes: 'Sharp left knee pain on the last squat set.',
          ),
        ),
      );

      expect(signal.workflowId, 'pain_or_injury_guardrail');
      expect(signal.persona, 'zen');
      expect(signal.observation, contains('No load increase is approved'));
      expect(signal.nextAction, 'Choose pain-free variation');
      expect(signal.coachNote, contains('stop sharp pain'));
      expect(coachSignalCopyIsGateSafe(signal), isTrue);
    });

    test('clear no-pain note does not trigger injury guardrail', () {
      expect(hasReportedPain('Left knee quiet, no sharp pain.'), isFalse);
      expect(hasReportedPain('No pain after the session.'), isFalse);
      expect(hasReportedPain('No sharp pain but a knee ache later.'), isTrue);
    });

    test('completed work routes to progress interpretation', () {
      final signal = buildCoachSignal(
        SessionState(
          lastDebrief: SessionDebrief(
            id: 'debrief-1',
            sessionId: 'session-1',
            createdAt: DateTime(2026, 7, 2, 9),
            perceivedExertion: 7,
            satisfaction: 4,
            nextSessionFocus: 'Keep squat reps controlled.',
          ),
          history: [
            WorkoutSession(
              id: 'session-1',
              startedAt: DateTime(2026, 7, 2, 8),
              endedAt: DateTime(2026, 7, 2, 8, 45),
              readinessEntryId: 'readiness-1',
              loggedSets: const [
                LoggedSet(
                  id: 'set-1',
                  exerciseName: 'Goblet squat',
                  setNumber: 1,
                  weightKg: 40,
                  reps: 8,
                  rpe: 7,
                ),
              ],
            ),
          ],
        ),
      );

      expect(signal.workflowId, 'progress_interpretation');
      expect(signal.persona, 'analyst');
      expect(signal.coachNote, contains('1 kept promise'));
      expect(signal.observation, contains('Keep squat reps controlled.'));
      expect(coachSignalCopyIsGateSafe(signal), isTrue);
    });

    test('active session with history stays in live session guidance', () {
      final readiness = ReadinessEntry(
        id: 'readiness-live',
        date: DateTime(2026, 7, 2),
        score: 82,
        zone: 'push',
        energyLevel: 8,
        sleepQuality: 8,
        sorenessMap: const [],
      );
      final signal = buildCoachSignal(
        SessionState(
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
          activeSessionPlan: const [
            SessionPlanExercise(
              exerciseId: 'goblet_squat',
              exerciseName: 'Goblet squat',
              targetSets: 3,
              targetReps: 8,
              targetRpe: 7,
              targetRestSeconds: 90,
              suggestedWeightKg: 40,
            ),
          ],
          history: [
            WorkoutSession(
              id: 'session-history',
              startedAt: DateTime(2026, 7, 1, 8),
              endedAt: DateTime(2026, 7, 1, 8, 45),
              readinessEntryId: 'readiness-history',
              loggedSets: const [
                LoggedSet(
                  id: 'set-history-1',
                  exerciseName: 'Goblet squat',
                  setNumber: 1,
                  weightKg: 40,
                  reps: 8,
                  rpe: 7,
                ),
              ],
            ),
          ],
        ),
      );

      expect(signal.workflowId, 'live_session_guidance');
      expect(signal.persona, 'analyst');
      expect(signal.observationLabel, 'Live set target');
      expect(signal.observation, contains('1 of 3 planned sets'));
      expect(signal.observation, contains('inside the workout'));
      expect(signal.nextAction, 'Log the next clean set');
      expect(signal.sourceIds, contains('src_hevy_app_store_preview'));
      expect(signal.uxPrincipleIds, contains('uxp_fast_active_logging'));
      expect(coachSignalCopyIsGateSafe(signal), isTrue);
    });

    test('active session ignores historical overreach and stays live', () {
      final readiness = ReadinessEntry(
        id: 'readiness-live-overreach',
        date: DateTime(2026, 7, 2),
        score: 82,
        zone: 'push',
        energyLevel: 8,
        sleepQuality: 8,
        sorenessMap: const [],
      );
      final signal = buildCoachSignal(
        SessionState(
          readinessEntry: readiness,
          activeSession: WorkoutSession(
            id: 'session-live-overreach',
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
            WorkoutSession(
              id: 'session-previous',
              startedAt: DateTime(2026, 6, 30, 8),
              endedAt: DateTime(2026, 6, 30, 8, 35),
              readinessEntryId: 'readiness-previous',
              loggedSets: const [
                LoggedSet(
                  id: 'set-previous-1',
                  exerciseName: 'Deadlift',
                  setNumber: 1,
                  weightKg: 40,
                  reps: 8,
                  rpe: 8,
                ),
              ],
            ),
            WorkoutSession(
              id: 'session-latest',
              startedAt: DateTime(2026, 7, 1, 8),
              endedAt: DateTime(2026, 7, 1, 8, 40),
              readinessEntryId: 'readiness-latest',
              loggedSets: const [
                LoggedSet(
                  id: 'set-latest-1',
                  exerciseName: 'Deadlift',
                  setNumber: 1,
                  weightKg: 90,
                  reps: 10,
                  rpe: 8,
                ),
              ],
            ),
          ],
          lastDebrief: SessionDebrief(
            id: 'debrief-latest',
            sessionId: 'session-latest',
            createdAt: DateTime(2026, 7, 1, 9),
            perceivedExertion: 8,
            satisfaction: 4,
            nextSessionFocus: 'Hold deadlift volume steady.',
          ),
        ),
      );

      expect(signal.workflowId, 'live_session_guidance');
      expect(signal.observationLabel, 'Live set target');
      expect(signal.observation, contains('inside the workout'));
      expect(signal.nextAction, 'Log the next clean set');
      expect(signal.observation, isNot(contains('Volume jumped')));
      expect(signal.nextAction, isNot('Hold volume steady next time'));
      expect(coachSignalCopyIsGateSafe(signal), isTrue);
    });

    test('soft live effort routes to challenger workflow', () {
      final readiness = ReadinessEntry(
        id: 'readiness-live',
        date: DateTime(2026, 7, 2),
        score: 78,
        zone: 'push',
        energyLevel: 8,
        sleepQuality: 8,
        sorenessMap: const [],
      );
      final signal = buildCoachSignal(
        SessionState(
          readinessEntry: readiness,
          activeSession: WorkoutSession(
            id: 'session-live',
            startedAt: DateTime(2026, 7, 2, 8),
            readinessEntryId: readiness.id,
            loggedSets: const [
              LoggedSet(
                id: 'set-1',
                exerciseName: 'Goblet squat',
                setNumber: 1,
                weightKg: 40,
                reps: 8,
                rpe: 5,
              ),
              LoggedSet(
                id: 'set-2',
                exerciseName: 'Goblet squat',
                setNumber: 2,
                weightKg: 40,
                reps: 8,
                rpe: 5,
              ),
              LoggedSet(
                id: 'set-3',
                exerciseName: 'Goblet squat',
                setNumber: 3,
                weightKg: 40,
                reps: 8,
                rpe: 4,
              ),
            ],
          ),
        ),
      );

      expect(signal.workflowId, 'coasting_or_overreaching');
      expect(signal.persona, 'challenger');
      expect(signal.observation, contains('live sets average'));
      expect(signal.nextAction, 'Raise the next set by one RPE');
      expect(coachSignalCopyIsGateSafe(signal), isTrue);
    });

    test(
      'shared effort classifier keeps live and historical coasting thresholds aligned',
      () {
        final liveSignal = buildCoachSignal(
          SessionState(
            activeSession: WorkoutSession(
              id: 'session-live-coasting',
              startedAt: DateTime(2026, 7, 2, 8),
              readinessEntryId: 'readiness-live-coasting',
              loggedSets: const [
                LoggedSet(
                  id: 'live-set-1',
                  exerciseName: 'Goblet squat',
                  setNumber: 1,
                  weightKg: 40,
                  reps: 8,
                  rpe: 5,
                ),
                LoggedSet(
                  id: 'live-set-2',
                  exerciseName: 'Goblet squat',
                  setNumber: 2,
                  weightKg: 40,
                  reps: 8,
                  rpe: 5,
                ),
                LoggedSet(
                  id: 'live-set-3',
                  exerciseName: 'Goblet squat',
                  setNumber: 3,
                  weightKg: 40,
                  reps: 8,
                  rpe: 5,
                ),
              ],
            ),
          ),
        );

        final historicalSignal = buildCoachSignal(
          SessionState(
            history: [
              WorkoutSession(
                id: 'session-previous-honest',
                startedAt: DateTime(2026, 7, 1, 8),
                endedAt: DateTime(2026, 7, 1, 8, 45),
                readinessEntryId: 'readiness-previous-honest',
                loggedSets: const [
                  LoggedSet(
                    id: 'previous-set-1',
                    exerciseName: 'Deadlift',
                    setNumber: 1,
                    weightKg: 125,
                    reps: 8,
                    rpe: 8,
                  ),
                ],
              ),
              WorkoutSession(
                id: 'session-latest-coasting',
                startedAt: DateTime(2026, 7, 2, 8),
                endedAt: DateTime(2026, 7, 2, 8, 45),
                readinessEntryId: 'readiness-latest-coasting',
                loggedSets: const [
                  LoggedSet(
                    id: 'latest-set-1',
                    exerciseName: 'Goblet squat',
                    setNumber: 1,
                    weightKg: 40,
                    reps: 8,
                    rpe: 5,
                  ),
                  LoggedSet(
                    id: 'latest-set-2',
                    exerciseName: 'Goblet squat',
                    setNumber: 2,
                    weightKg: 40,
                    reps: 8,
                    rpe: 5,
                  ),
                  LoggedSet(
                    id: 'latest-set-3',
                    exerciseName: 'Goblet squat',
                    setNumber: 3,
                    weightKg: 40,
                    reps: 8,
                    rpe: 5,
                  ),
                ],
              ),
            ],
          ),
        );

        expect(liveSignal.workflowId, 'coasting_or_overreaching');
        expect(historicalSignal.workflowId, 'coasting_or_overreaching');
        expect(liveSignal.observation, contains('5/10 RPE'));
        expect(historicalSignal.observation, contains('5/10 RPE'));
        expect(liveSignal.nextAction, 'Raise the next set by one RPE');
        expect(
          historicalSignal.nextAction,
          'Make the first working set honest',
        );
        expect(coachSignalCopyIsGateSafe(liveSignal), isTrue);
        expect(coachSignalCopyIsGateSafe(historicalSignal), isTrue);
      },
    );
  });
}
