import 'package:flutter_test/flutter_test.dart';
import 'package:transformfit/features/reviews/five_star_experience.dart';
import 'package:transformfit/features/session/models.dart';
import 'package:transformfit/features/session/session_controller.dart';

void main() {
  group('FiveStarExperienceMoment', () {
    test('active workout suppresses review prompt during task', () {
      final moment = buildFiveStarExperienceMoment(
        _activatedState(
          activeSession: _activeSession(),
          lastDebrief: _debrief(satisfaction: 5),
        ),
      );

      expect(moment.status, FiveStarExperienceStatus.holdDuringTask);
      expect(moment.isStoreReviewEligible, isFalse);
      expect(moment.nextAction, 'Finish the live session first');
      expect(fiveStarExperienceCopyIsGateSafe(moment), isTrue);
    });

    test('pain debrief blocks review readiness', () {
      final moment = buildFiveStarExperienceMoment(
        _activatedState(
          lastDebrief: _debrief(
            satisfaction: 5,
            painNotes: 'Sharp knee pain after set two.',
          ),
        ),
      );

      expect(moment.status, FiveStarExperienceStatus.holdForSafety);
      expect(moment.headline, 'Resolve safety before praise');
      expect(moment.isStoreReviewEligible, isFalse);
      expect(fiveStarExperienceCopyIsGateSafe(moment), isTrue);
    });

    test('insufficient training proof keeps building value', () {
      final moment = buildFiveStarExperienceMoment(
        SessionState(
          history: [_completedSession(index: 1, sets: 3)],
          lastDebrief: _debrief(satisfaction: 5),
        ),
      );

      expect(moment.status, FiveStarExperienceStatus.buildValue);
      expect(moment.completedSessions, 1);
      expect(moment.completedSets, 3);
      expect(
        moment.nextAction,
        'Complete two sessions with at least six clean sets',
      );
      expect(fiveStarExperienceCopyIsGateSafe(moment), isTrue);
    });

    test('activation context must be complete before review eligibility', () {
      final moment = buildFiveStarExperienceMoment(
        SessionState(
          history: [
            _completedSession(index: 1, sets: 3),
            _completedSession(index: 2, sets: 3),
          ],
          lastDebrief: _debrief(satisfaction: 5),
        ),
      );

      expect(moment.status, FiveStarExperienceStatus.completeActivation);
      expect(moment.isStoreReviewEligible, isFalse);
      expect(moment.nextAction, 'Capture readiness before the next session');
      expect(fiveStarExperienceCopyIsGateSafe(moment), isTrue);
    });

    test('low satisfaction routes to repair before review', () {
      final moment = buildFiveStarExperienceMoment(
        _activatedState(lastDebrief: _debrief(satisfaction: 3)),
      );

      expect(moment.status, FiveStarExperienceStatus.repairExperience);
      expect(moment.headline, 'Repair the last session first');
      expect(moment.isStoreReviewEligible, isFalse);
      expect(fiveStarExperienceCopyIsGateSafe(moment), isTrue);
    });

    test('positive activated natural break is review eligible', () {
      final moment = buildFiveStarExperienceMoment(
        _activatedState(lastDebrief: _debrief(satisfaction: 5)),
      );

      expect(moment.status, FiveStarExperienceStatus.readyNaturalBreak);
      expect(moment.isStoreReviewEligible, isTrue);
      expect(moment.completedSessions, 2);
      expect(moment.completedSets, 6);
      expect(moment.sourceIds, contains('src_apple_hig_ratings_reviews'));
      expect(moment.sourceIds, contains('src_google_play_in_app_review_api'));
      expect(fiveStarExperienceCopyIsGateSafe(moment), isTrue);
    });

    test('1000 generated review-readiness scenarios stay safe', () {
      for (var i = 0; i < 1000; i += 1) {
        final sessionCount = i % 4;
        final setsPerSession = (i % 5) + 1;
        final satisfaction = (i % 5) + 1;
        final hasReadiness = i % 3 != 0;
        final hasNutrition = i % 4 != 0;
        final active = i % 11 == 0;
        final pain = i % 13 == 0;
        final state = SessionState(
          readinessEntry: hasReadiness ? _readiness() : null,
          nutritionTarget: hasNutrition ? _nutrition() : null,
          activeSession: active ? _activeSession() : null,
          history: [
            for (var index = 1; index <= sessionCount; index += 1)
              _completedSession(index: index, sets: setsPerSession),
          ],
          lastDebrief: _debrief(
            satisfaction: satisfaction,
            painNotes: pain ? 'Pain on the last rep.' : 'No pain.',
          ),
        );

        final moment = buildFiveStarExperienceMoment(state);
        expect(fiveStarExperienceCopyIsGateSafe(moment), isTrue);
        if (moment.isStoreReviewEligible) {
          expect(active, isFalse, reason: 'scenario $i');
          expect(pain, isFalse, reason: 'scenario $i');
          expect(hasReadiness, isTrue, reason: 'scenario $i');
          expect(hasNutrition, isTrue, reason: 'scenario $i');
          expect(sessionCount, greaterThanOrEqualTo(2), reason: 'scenario $i');
          expect(satisfaction, greaterThanOrEqualTo(4), reason: 'scenario $i');
        }
      }
    });
  });
}

SessionState _activatedState({
  WorkoutSession? activeSession,
  SessionDebrief? lastDebrief,
}) {
  return SessionState(
    readinessEntry: _readiness(),
    nutritionTarget: _nutrition(),
    activeSession: activeSession,
    history: [
      _completedSession(index: 1, sets: 3),
      _completedSession(index: 2, sets: 3),
    ],
    lastDebrief: lastDebrief,
  );
}

ReadinessEntry _readiness() {
  return ReadinessEntry(
    id: 'readiness-review',
    date: DateTime(2026, 7, 3),
    score: 76,
    zone: 'steady',
    energyLevel: 7,
    sleepQuality: 7,
    sorenessMap: const ['quads'],
  );
}

NutritionTarget _nutrition() {
  return NutritionTarget(
    id: 'nutrition-review',
    createdAt: DateTime(2026, 7, 3),
    targetType: 'protein',
    label: 'Protein target',
    dailyTarget: 130,
    unit: 'g/day',
  );
}

WorkoutSession _activeSession() {
  return WorkoutSession(
    id: 'session-live-review',
    startedAt: DateTime(2026, 7, 3, 8),
    readinessEntryId: 'readiness-review',
    loggedSets: const [
      LoggedSet(
        id: 'set-live-review',
        exerciseName: 'Trap bar deadlift',
        setNumber: 1,
        weightKg: 100,
        reps: 5,
      ),
    ],
  );
}

WorkoutSession _completedSession({required int index, required int sets}) {
  return WorkoutSession(
    id: 'session-review-$index',
    startedAt: DateTime(2026, 7, index, 8),
    endedAt: DateTime(2026, 7, index, 8, 45),
    readinessEntryId: 'readiness-review-$index',
    loggedSets: [
      for (var set = 1; set <= sets; set += 1)
        LoggedSet(
          id: 'set-review-$index-$set',
          exerciseName: 'Front squat',
          setNumber: set,
          weightKg: 80,
          reps: 6,
          rpe: 7,
        ),
    ],
  );
}

SessionDebrief _debrief({required int satisfaction, String? painNotes}) {
  return SessionDebrief(
    id: 'debrief-review',
    sessionId: 'session-review-2',
    createdAt: DateTime(2026, 7, 3, 9),
    perceivedExertion: 7,
    satisfaction: satisfaction,
    painNotes: painNotes,
  );
}
