import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:transformfit/features/session/models.dart';
import 'package:transformfit/features/wearables/wearable_signal.dart';

void main() {
  group('WearableSignal', () {
    test('snapshot survives a JSON encode decode boundary', () {
      final signal = WearableSignal.localSample(
        capturedAt: DateTime(2026, 7, 2, 7, 30),
      );

      final decoded = jsonDecode(jsonEncode(signal.toJson()));
      final restored = WearableSignal.fromJson(
        Map<String, Object?>.from(decoded as Map),
      );

      expect(restored.source, 'local_sample');
      expect(restored.sleepLabel, '7.4h sleep');
      expect(restored.hrvLabel, '68 ms HRV');
      expect(restored.sourceIds, wearableIntegrationSourceIds);
    });

    test('not connected insight is honest and source traced', () {
      final insight = buildWearableReadinessInsight(null);

      expect(insight.status, 'not_connected');
      expect(insight.statusLabel, 'HealthKit / Health Connect ready');
      expect(insight.primaryAdjustment, contains('readiness'));
      expect(insight.sourceIds, hasLength(4));
      expect(wearableSignalCopyIsGateSafe(insight), isTrue);
    });

    test(
      'pending permission does not bias readiness from supplied metrics',
      () {
        final insight = buildWearableReadinessInsight(
          WearableSignal(
            id: 'wearable-permission-needed',
            capturedAt: DateTime(2026, 7, 2, 7),
            source: 'health_package',
            syncState: 'pending_permission',
            stepsToday: 9000,
            restingHeartRateBpm: 54,
            heartRateVariabilityMs: 82,
            sleepMinutes: 510,
            activeEnergyKcal: 620,
            workoutMinutes: 45,
          ),
        );

        expect(insight.status, 'permission_needed');
        expect(insight.statusLabel, 'Wearable permission needed');
        expect(insight.connected, isFalse);
        expect(insight.readinessModifier, 0);
        expect(insight.primaryAdjustment, contains('permission is granted'));
        expect(insight.detail, contains('not authorized yet'));
        expect(insight.detail, isNot(contains('normal progression')));
        expect(wearableSignalCopyIsGateSafe(insight), isTrue);
      },
    );

    test(
      'unavailable sync does not infer recovery from missing wearable data',
      () {
        final insight = buildWearableReadinessInsight(
          WearableSignal(
            id: 'wearable-unavailable',
            capturedAt: DateTime(2026, 7, 2, 7),
            source: 'health_package',
            syncState: 'unavailable',
            restingHeartRateBpm: 58,
            heartRateVariabilityMs: 78,
            sleepMinutes: 480,
          ),
        );

        expect(insight.status, 'sync_unavailable');
        expect(insight.statusLabel, 'Wearable sync unavailable');
        expect(insight.connected, isFalse);
        expect(insight.readinessModifier, 0);
        expect(insight.primaryAdjustment, contains('manual readiness'));
        expect(insight.detail, contains('will not infer recovery'));
        expect(insight.detail, isNot(contains('normal progression')));
        expect(wearableSignalCopyIsGateSafe(insight), isTrue);
      },
    );

    test('low sleep creates recovery-biased readiness adjustment', () {
      final insight = buildWearableReadinessInsight(
        WearableSignal(
          id: 'wearable-low-sleep',
          capturedAt: DateTime(2026, 7, 2, 7),
          source: 'apple_healthkit',
          syncState: 'synced',
          stepsToday: 3200,
          restingHeartRateBpm: 62,
          heartRateVariabilityMs: 42,
          sleepMinutes: 310,
          activeEnergyKcal: 120,
          workoutMinutes: 0,
        ),
        readiness: ReadinessEntry(
          id: 'readiness-low',
          date: DateTime(2026, 7, 2),
          score: 52,
          zone: 'maintain',
          energyLevel: 6,
          sleepQuality: 5,
          sorenessMap: const [],
        ),
      );

      expect(insight.status, 'recovery_bias');
      expect(insight.readinessModifier, -7);
      expect(insight.detail, contains('lower load'));
      expect(wearableSignalCopyIsGateSafe(insight), isTrue);
    });

    test('strong recovery supports normal progression with checks', () {
      final insight = buildWearableReadinessInsight(
        WearableSignal(
          id: 'wearable-ready',
          capturedAt: DateTime(2026, 7, 2, 7),
          source: 'android_health_connect',
          syncState: 'synced',
          stepsToday: 7100,
          restingHeartRateBpm: 58,
          heartRateVariabilityMs: 72,
          sleepMinutes: 480,
          activeEnergyKcal: 460,
          workoutMinutes: 44,
        ),
      );

      expect(insight.status, 'ready_bias');
      expect(insight.modifierLabel, '+4 readiness points');
      expect(insight.primaryAdjustment, contains('normal progression'));
      expect(wearableSignalCopyIsGateSafe(insight), isTrue);
    });

    test('1000 generated wearable scenarios stay deterministic and safe', () {
      final snapshots = <String>[];
      for (var index = 0; index < 1000; index += 1) {
        final insight = buildWearableReadinessInsight(_scenarioSignal(index));
        snapshots.add(
          '${insight.status}:${insight.modifierLabel}:${insight.primaryAdjustment}',
        );
        expect(wearableSignalCopyIsGateSafe(insight), isTrue);
      }

      final repeat = <String>[];
      for (var index = 0; index < 1000; index += 1) {
        final insight = buildWearableReadinessInsight(_scenarioSignal(index));
        repeat.add(
          '${insight.status}:${insight.modifierLabel}:${insight.primaryAdjustment}',
        );
      }

      expect(repeat, snapshots);
    });
  });
}

WearableSignal _scenarioSignal(int index) {
  return WearableSignal(
    id: 'wearable-$index',
    capturedAt: DateTime(2026, 7, 2, index % 24, index % 60),
    source: index.isEven ? 'apple_healthkit' : 'android_health_connect',
    syncState: 'synced',
    stepsToday: 1000 + (index * 17) % 16000,
    restingHeartRateBpm: 52 + index % 32,
    heartRateVariabilityMs: 25 + index % 70,
    sleepMinutes: 280 + index % 260,
    activeEnergyKcal: 100 + index % 900,
    workoutMinutes: index % 95,
  );
}
