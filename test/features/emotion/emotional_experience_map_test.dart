import 'package:flutter_test/flutter_test.dart';
import 'package:transformfit/features/emotion/emotional_experience_map.dart';
import 'package:transformfit/features/session/models.dart';
import 'package:transformfit/features/session/session_controller.dart';

void main() {
  group('EmotionalExperienceMap', () {
    test('empty state routes to orientation', () {
      final map = buildEmotionalExperienceMap(
        const SessionState(),
        now: DateTime(2026, 7, 3, 8),
      );

      expect(map.stage, EmotionalExperienceStage.orientation);
      expect(map.headline, 'Feel safe to begin');
      expect(map.emotionalPromise, 'The first win is clarity, not intensity.');
      expect(map.nextExperience, contains('readiness check'));
      expect(map.vectors.map((vector) => vector.label), [
        'Certainty',
        'Agency',
        'Safety',
        'Momentum',
      ]);
      expect(emotionalExperienceCopyIsGateSafe(map), isTrue);
    });

    test('active session routes to agency', () {
      final map = buildEmotionalExperienceMap(
        SessionState(
          readinessEntry: _readiness(score: 82, zone: 'push'),
          activeSession: WorkoutSession(
            id: 'session-active-emotion',
            startedAt: DateTime(2026, 7, 3, 8),
            readinessEntryId: 'readiness-emotion',
            loggedSets: const [
              LoggedSet(
                id: 'set-active-emotion',
                exerciseName: 'Goblet squat',
                setNumber: 1,
                weightKg: 24,
                reps: 10,
                rpe: 7,
              ),
            ],
          ),
        ),
        now: DateTime(2026, 7, 3, 8, 20),
      );

      expect(map.stage, EmotionalExperienceStage.agency);
      expect(map.headline, 'Feel in control while moving');
      expect(map.nextExperience, 'Finish and debrief while context is fresh.');
      expect(emotionalExperienceCopyIsGateSafe(map), isTrue);
    });

    test('pain debrief routes to safety', () {
      final map = buildEmotionalExperienceMap(
        SessionState(
          history: [_session(id: 'session-pain-emotion', day: 2)],
          lastDebrief: SessionDebrief(
            id: 'debrief-pain-emotion',
            sessionId: 'session-pain-emotion',
            createdAt: DateTime(2026, 7, 2, 9),
            perceivedExertion: 8,
            satisfaction: 3,
            painNotes: 'Sharp knee pain.',
          ),
        ),
        now: DateTime(2026, 7, 3, 8),
      );

      expect(map.stage, EmotionalExperienceStage.safety);
      expect(map.headline, 'Feel protected before pushed');
      expect(map.riskToAvoid, 'Do not imply load increases are approved.');
      expect(
        map.nextExperience,
        'Choose a pain-free variation before progression.',
      );
      expect(emotionalExperienceCopyIsGateSafe(map), isTrue);
    });

    test('missed day routes to comeback', () {
      final map = buildEmotionalExperienceMap(
        SessionState(
          history: [_session(id: 'session-comeback-emotion', day: 1)],
        ),
        now: DateTime(2026, 7, 3, 9),
      );

      expect(map.stage, EmotionalExperienceStage.comeback);
      expect(map.headline, 'Feel invited back');
      expect(map.riskToAvoid, contains('Do not add missed volume'));
      expect(map.nextExperience, 'Run readiness and log one warm-up set.');
      expect(emotionalExperienceCopyIsGateSafe(map), isTrue);
    });

    test('three completed sessions route to proof identity', () {
      final map = buildEmotionalExperienceMap(
        SessionState(
          history: [
            _session(id: 'session-proof-1', day: 1),
            _session(id: 'session-proof-2', day: 2),
            _session(id: 'session-proof-3', day: 3),
          ],
        ),
        now: DateTime(2026, 7, 3, 12),
      );

      expect(map.stage, EmotionalExperienceStage.proofIdentity);
      expect(map.headline, 'Feel like the kind of person who returns');
      expect(map.primaryFeeling, 'self-trust');
      expect(
        map.riskToAvoid,
        'Do not reduce identity to a score, body, or streak.',
      );
      expect(emotionalExperienceCopyIsGateSafe(map), isTrue);
    });
  });
}

ReadinessEntry _readiness({required int score, required String zone}) {
  return ReadinessEntry(
    id: 'readiness-emotion',
    date: DateTime(2026, 7, 3),
    score: score,
    zone: zone,
    energyLevel: 8,
    sleepQuality: 8,
    sorenessMap: const [],
  );
}

WorkoutSession _session({required String id, required int day}) {
  return WorkoutSession(
    id: id,
    startedAt: DateTime(2026, 7, day, 8),
    endedAt: DateTime(2026, 7, day, 8, 45),
    readinessEntryId: 'readiness-$id',
    loggedSets: const [
      LoggedSet(
        id: 'set-emotion',
        exerciseName: 'Trap bar deadlift',
        setNumber: 1,
        weightKg: 100,
        reps: 5,
        rpe: 7,
      ),
    ],
  );
}
