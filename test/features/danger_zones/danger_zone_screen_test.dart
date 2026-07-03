import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transformfit/engine/danger_zone.dart';
import 'package:transformfit/features/danger_zones/danger_zone_screen.dart';

void main() {
  group('DangerZoneScreen', () {
    testWidgets('renders clear state when no signals', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: DangerZoneScreen(
          result: DangerZoneResult(signals: [], overallSeverity: 'clear'),
        ),
      ));
      expect(find.text('No danger signals'), findsOneWidget);
      expect(find.textContaining('CLEAR'), findsOneWidget);
    });

    testWidgets('renders critical signal with action button', (tester) async {
      const result = DangerZoneResult(
        signals: [
          DangerSignal(
            code: 'ACWR_HIGH',
            severity: 'critical',
            title: 'Acute:chronic workload too high',
            detail: 'ACWR is above 1.5.',
            recommendedAction: 'Deload by 40%.',
          ),
        ],
        overallSeverity: 'critical',
      );
      await tester.pumpWidget(const MaterialApp(home: DangerZoneScreen(result: result)));
      expect(find.text('Acute:chronic workload too high'), findsOneWidget);
      expect(find.textContaining('CRITICAL'), findsOneWidget);
      expect(find.text('Stop & Rest'), findsOneWidget);
      expect(find.text('Start Deload Week'), findsOneWidget);
    });

    testWidgets('renders warning signal without stop button', (tester) async {
      const result = DangerZoneResult(
        signals: [
          DangerSignal(
            code: 'MONOTONY_HIGH',
            severity: 'warning',
            title: 'Training monotony high',
            detail: 'Monotony >2.0.',
            recommendedAction: 'Add variety.',
          ),
        ],
        overallSeverity: 'warning',
      );
      await tester.pumpWidget(const MaterialApp(home: DangerZoneScreen(result: result)));
      expect(find.text('Training monotony high'), findsOneWidget);
      expect(find.textContaining('WARNING'), findsOneWidget);
      expect(find.text('Stop & Rest'), findsNothing);
    });

    testWidgets('acknowledge button is always present when signals exist',
        (tester) async {
      const result = DangerZoneResult(
        signals: [
          DangerSignal(
            code: 'CONSISTENCY_RISK',
            severity: 'watch',
            title: 'Consistency dropping',
            detail: '3+ missed.',
            recommendedAction: 'Recommit.',
          ),
        ],
        overallSeverity: 'watch',
      );
      await tester.pumpWidget(const MaterialApp(home: DangerZoneScreen(result: result)));
      expect(find.text('Acknowledge & Continue'), findsOneWidget);
    });

    testWidgets('renders header', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: DangerZoneScreen(
          result: DangerZoneResult(signals: [], overallSeverity: 'clear'),
        ),
      ));
      expect(find.text('Safety Check'), findsOneWidget);
    });
  });
}
