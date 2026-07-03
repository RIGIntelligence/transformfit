import 'package:flutter_test/flutter_test.dart';
import 'package:transformfit/features/coaching/dai_interface.dart';
import 'package:transformfit/features/session/models.dart';
import 'package:transformfit/features/session/session_controller.dart';
import 'package:transformfit/features/wearables/wearable_signal.dart';

void main() {
  group('DaiInterface', () {
    test(
      'defaults to wearable connection workflow without making sync claims',
      () {
        final dai = buildDaiInterface(const SessionState());

        expect(dai.workflowId, 'dai_wearable_connect');
        expect(dai.primaryCommand, 'Connect wearable context');
        expect(
          dai.wearableInsight.statusLabel,
          'HealthKit / Health Connect ready',
        );
        expect(dai.sourceIds, contains('src_flutter_health_package'));
        expect(daiInterfaceCopyIsGateSafe(dai), isTrue);
      },
    );

    test('wearable recovery bias changes the DAI command', () {
      final dai = buildDaiInterface(
        SessionState(
          wearableSignal: WearableSignal(
            id: 'wearable-recovery',
            capturedAt: DateTime(2026, 7, 2, 7),
            source: 'apple_healthkit',
            syncState: 'synced',
            sleepMinutes: 320,
            restingHeartRateBpm: 76,
            heartRateVariabilityMs: 34,
          ),
        ),
      );

      expect(dai.workflowId, 'dai_wearable_recovery_bias');
      expect(dai.primaryCommand, 'Bias toward recovery-safe training');
      expect(dai.wearableInsight.readinessModifier, lessThan(0));
      expect(dai.boundary, contains('context only'));
      expect(daiInterfaceCopyIsGateSafe(dai), isTrue);
    });

    test('pending wearable permission stays manual and zero modifier', () {
      final dai = buildDaiInterface(
        SessionState(
          wearableSignal: WearableSignal(
            id: 'wearable-pending-permission',
            capturedAt: DateTime(2026, 7, 2, 7),
            source: 'health_package',
            syncState: 'pending_permission',
            sleepMinutes: 500,
            restingHeartRateBpm: 55,
            heartRateVariabilityMs: 80,
          ),
        ),
      );

      expect(dai.workflowId, 'dai_wearable_connect');
      expect(dai.primaryCommand, 'Grant wearable permission');
      expect(dai.wearableInsight.status, 'permission_needed');
      expect(dai.wearableInsight.connected, isFalse);
      expect(dai.wearableInsight.readinessModifier, 0);
      expect(dai.rationale, contains('until wearable permission is granted'));
      expect(dai.boundary, contains('No wearable metric changes training'));
      expect(daiInterfaceCopyIsGateSafe(dai), isTrue);
    });

    test('pain guardrail overrides wearable ready bias', () {
      final readiness = ReadinessEntry(
        id: 'readiness-pain',
        date: DateTime(2026, 7, 2),
        score: 82,
        zone: 'push',
        energyLevel: 8,
        sleepQuality: 8,
        sorenessMap: const [],
      );
      final dai = buildDaiInterface(
        SessionState(
          readinessEntry: readiness,
          wearableSignal: WearableSignal(
            id: 'wearable-ready',
            capturedAt: DateTime(2026, 7, 2, 7),
            source: 'android_health_connect',
            syncState: 'synced',
            sleepMinutes: 480,
            restingHeartRateBpm: 57,
            heartRateVariabilityMs: 70,
          ),
          lastDebrief: SessionDebrief(
            id: 'debrief-pain',
            sessionId: 'session-pain',
            createdAt: DateTime(2026, 7, 2, 9),
            perceivedExertion: 8,
            satisfaction: 3,
            painNotes: 'Sharp knee pain after squats.',
          ),
        ),
      );

      expect(dai.workflowId, 'dai_pain_override');
      expect(dai.primaryCommand, 'Choose pain-free variation');
      expect(dai.rationale, contains('overrides wearable readiness'));
      expect(daiInterfaceCopyIsGateSafe(dai), isTrue);
    });

    test('connected neutral wearable blends with coach workflow', () {
      final dai = buildDaiInterface(
        SessionState(
          wearableSignal: WearableSignal.localSample(
            capturedAt: DateTime(2026, 7, 2, 7),
          ),
        ),
      );

      expect(dai.workflowId, 'dai_coach_blend');
      expect(dai.primaryCommand, 'Submit readiness');
      expect(dai.sourceIds, contains('src_android_health_connect_overview'));
      expect(dai.confidence, greaterThan(0.7));
      expect(daiInterfaceCopyIsGateSafe(dai), isTrue);
    });
  });
}
