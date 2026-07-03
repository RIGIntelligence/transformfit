import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transformfit/engine/fatigue.dart';
import 'package:transformfit/engine/recalibration.dart';
import 'package:transformfit/features/trends/trends_screen.dart';

void main() {
  group('TrendsScreen', () {
    testWidgets('renders empty state when no data', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: TrendsScreen()),
      );
      expect(find.text('No trends yet.'), findsOneWidget);
    });

    testWidgets('renders ACWR when volume history provided', (tester) async {
      final history = [
        for (int i = 27; i >= 0; i--)
          DailyVolume(
            date: DateTime(2026, 7, 1).subtract(Duration(days: i)),
            volumeKg: 1000.0,
          ),
      ];
      await tester.pumpWidget(
        MaterialApp(home: TrendsScreen(volumeHistory: history)),
      );
      expect(find.text('Workload Ratio'), findsOneWidget);
      expect(find.textContaining('SAFE'), findsOneWidget);
    });

    testWidgets('renders recalibration results', (tester) async {
      final results = [
        const RecalibrationResult(
          exerciseId: 'squat',
          oldTrainingMaxKg: 100,
          newTrainingMaxKg: 107.5,
          estimatedOneRmKg: 120,
          direction: 'up',
          reason: 'Estimated 1RM exceeded training max.',
        ),
      ];
      await tester.pumpWidget(
        MaterialApp(home: TrendsScreen(recalibrationResults: results)),
      );
      expect(find.text('Training Max Recalibration'), findsOneWidget);
      expect(find.text('squat'), findsOneWidget);
      expect(find.textContaining('107.5'), findsWidgets);
    });

    testWidgets('renders readiness trend', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: TrendsScreen(recentReadinessScores: [65, 72, 80, 75]),
      ));
      expect(find.text('Readiness Trend'), findsOneWidget);
      expect(find.textContaining('Improving'), findsOneWidget);
    });

    testWidgets('renders header and title', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: TrendsScreen()));
      expect(find.text('Trends'), findsOneWidget);
    });
  });
}
