import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:transformfit/features/session/models.dart';
import 'package:transformfit/features/session/session_controller.dart';
import 'package:transformfit/features/session/session_snapshot_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('saves and restores a complete session snapshot', () async {
    final controller = SessionController();
    controller.submitReadiness(
      energyLevel: 9,
      sleepQuality: 8,
      sorenessMap: ['hips'],
      hrv: 82,
    );
    controller.startSession();
    controller.logSet(
      exerciseName: 'Front Squat',
      setNumber: 1,
      exerciseId: 'front_squat',
      weightKg: 32,
      reps: 12,
      rpe: 7,
    );
    controller.endSession(notes: 'Moved well');
    controller.submitDebrief(
      perceivedExertion: 7,
      satisfaction: 5,
      whatWorked: 'Brace stayed strong',
      nextSessionFocus: 'Single-leg balance',
    );

    final store = SessionSnapshotStore();
    await store.save(controller.state);

    final restored = await store.load();

    expect(restored, isNotNull);
    expect(restored!.readinessEntry!.hrv, 82);
    expect(
      restored.history.single.loggedSets.single.exerciseName,
      'Front Squat',
    );
    expect(restored.history.single.loggedSets.single.exerciseId, 'front_squat');
    expect(restored.history.single.sessionNotes, 'Moved well');
    expect(restored.lastDebrief!.nextSessionFocus, 'Single-leg balance');
  });

  test('saves and restores the active session plan queue', () async {
    final controller = SessionController();
    controller.submitReadiness(
      energyLevel: 8,
      sleepQuality: 8,
      sorenessMap: ['hips'],
    );
    controller.startSession();
    controller.attachActiveSessionPlan(const [
      SessionPlanExercise(
        exerciseId: 'dumbbell_bench_press',
        exerciseName: 'Dumbbell Bench Press',
        targetSets: 2,
        targetReps: 8,
        targetRpe: 8,
        targetRestSeconds: 120,
      ),
      SessionPlanExercise(
        exerciseId: 'dumbbell_row',
        exerciseName: 'Dumbbell Row',
        targetSets: 3,
        targetReps: 10,
        targetRpe: 7,
        targetRestSeconds: 90,
      ),
    ]);
    controller.logSet(
      exerciseName: 'Dumbbell Bench Press',
      setNumber: 1,
      exerciseId: 'dumbbell_bench_press',
      reps: 8,
      rpe: 8,
    );

    final store = SessionSnapshotStore();
    await store.save(controller.state);

    final restored = await store.load();

    expect(restored, isNotNull);
    expect(restored!.activeSession, isNotNull);
    expect(restored.activeSession!.loggedSets, hasLength(1));
    expect(
      restored.activeSession!.loggedSets.single.exerciseId,
      'dumbbell_bench_press',
    );
    expect(restored.activeSessionPlan, hasLength(2));
    expect(restored.activeSessionPlan.first.targetSets, 2);
    expect(restored.activeSessionPlan.last.exerciseName, 'Dumbbell Row');
    expect(restored.activeSessionPlan.last.targetRestSeconds, 90);
  });

  test('clears malformed snapshots so offline boot can continue', () async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(SessionSnapshotStore.defaultKey, '{broken');

    final store = SessionSnapshotStore();

    expect(await store.load(), isNull);
    expect(preferences.getString(SessionSnapshotStore.defaultKey), isNull);
  });

  test('clears semantically invalid workout snapshots on boot', () async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      SessionSnapshotStore.defaultKey,
      jsonEncode({
        'activeSession': {
          'id': 'session-corrupt',
          'startedAt': '2026-07-02T10:00:00.000Z',
          'readinessEntryId': 'readiness-1',
          'loggedSets': [
            {
              'id': 'set-corrupt',
              'exerciseName': 'Row',
              'setNumber': 1,
              'weightKg': -20,
              'reps': 8,
              'completed': true,
            },
          ],
        },
        'history': [],
      }),
    );

    final store = SessionSnapshotStore();

    expect(await store.load(), isNull);
    expect(preferences.getString(SessionSnapshotStore.defaultKey), isNull);
  });

  test('clears semantically invalid workout metadata on boot', () async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      SessionSnapshotStore.defaultKey,
      jsonEncode({
        'activeSession': {
          'id': '   ',
          'startedAt': '2026-07-02T10:00:00.000Z',
          'endedAt': '2026-07-02T09:59:00.000Z',
          'readinessEntryId': ' ',
          'loggedSets': [
            {
              'id': 'set-1',
              'exerciseName': 'Row',
              'setNumber': 1,
              'weightKg': 20,
              'reps': 8,
              'completed': true,
            },
          ],
          'volumeMultiplier': -1,
        },
        'history': [],
      }),
    );

    final store = SessionSnapshotStore();

    expect(await store.load(), isNull);
    expect(preferences.getString(SessionSnapshotStore.defaultKey), isNull);
  });

  test('clears semantically invalid logged set identity on boot', () async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      SessionSnapshotStore.defaultKey,
      jsonEncode({
        'readinessEntry': {
          'id': 'readiness-1',
          'date': '2026-07-02T09:50:00.000Z',
          'score': 82,
          'zone': 'push',
          'energyLevel': 9,
          'sleepQuality': 8,
          'sorenessMap': [],
        },
        'activeSession': {
          'id': 'session-1',
          'startedAt': '2026-07-02T10:00:00.000Z',
          'readinessEntryId': 'readiness-1',
          'loggedSets': [
            {
              'id': 'set-duplicate',
              'exerciseName': 'Row',
              'setNumber': 1,
              'weightKg': 20,
              'reps': 8,
              'completed': true,
            },
            {
              'id': 'set-duplicate',
              'exerciseName': 'Press',
              'setNumber': 2,
              'weightKg': 30,
              'reps': 8,
              'completed': true,
            },
          ],
        },
        'history': [],
      }),
    );

    final store = SessionSnapshotStore();

    expect(await store.load(), isNull);
    expect(preferences.getString(SessionSnapshotStore.defaultKey), isNull);
  });

  test('clears semantically invalid logged set numbering on boot', () async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      SessionSnapshotStore.defaultKey,
      jsonEncode({
        'readinessEntry': {
          'id': 'readiness-1',
          'date': '2026-07-02T09:50:00.000Z',
          'score': 82,
          'zone': 'push',
          'energyLevel': 9,
          'sleepQuality': 8,
          'sorenessMap': [],
        },
        'activeSession': {
          'id': 'session-corrupt-set-numbers',
          'startedAt': '2026-07-02T10:00:00.000Z',
          'readinessEntryId': 'readiness-1',
          'loggedSets': [
            {
              'id': 'set-1',
              'exerciseName': 'Row',
              'setNumber': 1,
              'weightKg': 20,
              'reps': 8,
              'completed': true,
            },
            {
              'id': 'set-2',
              'exerciseName': 'Press',
              'setNumber': 1,
              'weightKg': 30,
              'reps': 8,
              'completed': true,
            },
          ],
        },
        'history': [],
      }),
    );

    final store = SessionSnapshotStore();

    expect(await store.load(), isNull);
    expect(preferences.getString(SessionSnapshotStore.defaultKey), isNull);
  });

  test(
    'clears semantically invalid workout session identity on boot',
    () async {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(
        SessionSnapshotStore.defaultKey,
        jsonEncode({
          'readinessEntry': {
            'id': 'readiness-active',
            'date': '2026-07-02T09:50:00.000Z',
            'score': 82,
            'zone': 'push',
            'energyLevel': 9,
            'sleepQuality': 8,
            'sorenessMap': [],
          },
          'activeSession': {
            'id': 'session-duplicate',
            'startedAt': '2026-07-02T11:00:00.000Z',
            'readinessEntryId': 'readiness-active',
            'loggedSets': [
              {
                'id': 'set-active',
                'exerciseName': 'Press',
                'setNumber': 1,
                'weightKg': 30,
                'reps': 8,
                'completed': true,
              },
            ],
          },
          'history': [
            {
              'id': 'session-duplicate',
              'startedAt': '2026-07-02T10:00:00.000Z',
              'endedAt': '2026-07-02T10:30:00.000Z',
              'readinessEntryId': 'readiness-older',
              'loggedSets': [
                {
                  'id': 'set-history',
                  'exerciseName': 'Row',
                  'setNumber': 1,
                  'weightKg': 20,
                  'reps': 8,
                  'completed': true,
                },
              ],
            },
          ],
        }),
      );

      final store = SessionSnapshotStore();

      expect(await store.load(), isNull);
      expect(preferences.getString(SessionSnapshotStore.defaultKey), isNull);
    },
  );

  test('clears semantically invalid session topology on boot', () async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      SessionSnapshotStore.defaultKey,
      jsonEncode({
        'readinessEntry': {
          'id': 'readiness-1',
          'date': '2026-07-02T09:50:00.000Z',
          'score': 82,
          'zone': 'push',
          'energyLevel': 9,
          'sleepQuality': 8,
          'sorenessMap': [],
        },
        'activeSession': {
          'id': 'session-ended-but-active',
          'startedAt': '2026-07-02T10:00:00.000Z',
          'endedAt': '2026-07-02T10:30:00.000Z',
          'readinessEntryId': 'readiness-1',
          'loggedSets': [
            {
              'id': 'set-1',
              'exerciseName': 'Row',
              'setNumber': 1,
              'weightKg': 20,
              'reps': 8,
              'completed': true,
            },
          ],
          'volumeMultiplier': 1.1,
        },
        'lastDebrief': {
          'id': 'debrief-orphan',
          'sessionId': 'missing-session',
          'createdAt': '2026-07-02T10:40:00.000Z',
          'perceivedExertion': 6,
          'satisfaction': 4,
        },
        'history': [],
      }),
    );

    final store = SessionSnapshotStore();

    expect(await store.load(), isNull);
    expect(preferences.getString(SessionSnapshotStore.defaultKey), isNull);
  });

  test('clears semantically invalid session chronology on boot', () async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      SessionSnapshotStore.defaultKey,
      jsonEncode({
        'lastDebrief': {
          'id': 'debrief-older',
          'sessionId': 'session-older',
          'createdAt': '2026-07-02T10:20:00.000Z',
          'perceivedExertion': 6,
          'satisfaction': 4,
        },
        'history': [
          {
            'id': 'session-newer',
            'startedAt': '2026-07-02T11:00:00.000Z',
            'endedAt': '2026-07-02T11:30:00.000Z',
            'readinessEntryId': 'readiness-newer',
            'loggedSets': [
              {
                'id': 'set-newer',
                'exerciseName': 'Press',
                'setNumber': 1,
                'weightKg': 30,
                'reps': 8,
                'completed': true,
              },
            ],
          },
          {
            'id': 'session-older',
            'startedAt': '2026-07-02T10:00:00.000Z',
            'endedAt': '2026-07-02T10:30:00.000Z',
            'readinessEntryId': 'readiness-older',
            'loggedSets': [
              {
                'id': 'set-older',
                'exerciseName': 'Row',
                'setNumber': 1,
                'weightKg': 20,
                'reps': 8,
                'completed': true,
              },
            ],
          },
        ],
      }),
    );

    final store = SessionSnapshotStore();

    expect(await store.load(), isNull);
    expect(preferences.getString(SessionSnapshotStore.defaultKey), isNull);
  });

  test('clears semantically invalid readiness snapshots on boot', () async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      SessionSnapshotStore.defaultKey,
      jsonEncode({
        'readinessEntry': {
          'id': 'readiness-corrupt',
          'date': '2026-07-02T10:00:00.000Z',
          'score': 140,
          'zone': 'push',
          'energyLevel': 99,
          'sleepQuality': 8,
          'sorenessMap': [],
        },
        'history': [],
      }),
    );

    final store = SessionSnapshotStore();

    expect(await store.load(), isNull);
    expect(preferences.getString(SessionSnapshotStore.defaultKey), isNull);
  });

  test('clears semantically invalid readiness identity on boot', () async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      SessionSnapshotStore.defaultKey,
      jsonEncode({
        'readinessEntry': {
          'id': '   ',
          'date': '2026-07-02T10:00:00.000Z',
          'score': 82,
          'zone': 'push',
          'energyLevel': 9,
          'sleepQuality': 8,
          'sorenessMap': [],
        },
        'history': [],
      }),
    );

    final store = SessionSnapshotStore();

    expect(await store.load(), isNull);
    expect(preferences.getString(SessionSnapshotStore.defaultKey), isNull);
  });

  test('clears semantically invalid readiness soreness map on boot', () async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      SessionSnapshotStore.defaultKey,
      jsonEncode({
        'readinessEntry': {
          'id': 'readiness-corrupt-map',
          'date': '2026-07-02T10:00:00.000Z',
          'score': 82,
          'zone': 'push',
          'energyLevel': 9,
          'sleepQuality': 8,
          'sorenessMap': ['hips', ' ', 'hips'],
        },
        'history': [],
      }),
    );

    final store = SessionSnapshotStore();

    expect(await store.load(), isNull);
    expect(preferences.getString(SessionSnapshotStore.defaultKey), isNull);
  });

  test('clears semantically invalid debrief snapshots on boot', () async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      SessionSnapshotStore.defaultKey,
      jsonEncode({
        'lastDebrief': {
          'id': 'debrief-corrupt',
          'sessionId': 'session-1',
          'createdAt': '2026-07-02T10:10:00.000Z',
          'perceivedExertion': 11,
          'satisfaction': 9,
          'nextSessionFocus': 'Repeat the hinge pattern',
        },
        'history': [],
      }),
    );

    final store = SessionSnapshotStore();

    expect(await store.load(), isNull);
    expect(preferences.getString(SessionSnapshotStore.defaultKey), isNull);
  });

  test('clear removes a saved snapshot', () async {
    final store = SessionSnapshotStore();
    await store.save(const SessionState(history: []));

    expect(await store.load(), isNotNull);

    await store.clear();

    expect(await store.load(), isNull);
  });
}
