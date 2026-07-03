// Widget + model tests for the M7 coach-consistency screen.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transformfit/features/coaching/coach_consistency_screen.dart';
import 'package:transformfit/features/coaching/persona_system.dart';

void main() {
  group('CoachLogEntry', () {
    test('can be constructed with required fields', () {
      final entry = CoachLogEntry(
        id: 'test1',
        persona: CoachingPersona.analyst,
        message: 'Readiness 72 and 3 sets logged.',
        timestamp: DateTime(2026, 7, 3),
        passed: true,
        findingsCount: 0,
      );
      expect(entry.id, 'test1');
      expect(entry.persona, CoachingPersona.analyst);
    });
  });

  group('computeConsistencyReport', () {
    test('empty entries gives perfect score', () {
      final report = computeConsistencyReport([]);
      expect(report.totalMessages, 0);
      expect(report.consistencyScore, 100);
      expect(report.recentEntries, isEmpty);
      expect(report.personaDistribution, isEmpty);
    });

    test('all-passing entries give 100 score', () {
      final now = DateTime(2026, 7, 3);
      final entries = [
        CoachLogEntry(
          id: '1',
          persona: CoachingPersona.motivator,
          message: 'Readiness 72, 3 sessions.',
          timestamp: now,
          passed: true,
          findingsCount: 0,
        ),
        CoachLogEntry(
          id: '2',
          persona: CoachingPersona.analyst,
          message: 'Volume 2500 kg across 3 sessions.',
          timestamp: now,
          passed: true,
          findingsCount: 0,
        ),
      ];
      final report = computeConsistencyReport(entries);
      expect(report.totalMessages, 2);
      expect(report.passedMessages, 2);
      expect(report.consistencyScore, 100);
    });

    test('mixed pass/fail gives proportional score', () {
      final now = DateTime(2026, 7, 3);
      final entries = [
        CoachLogEntry(
          id: '1',
          persona: CoachingPersona.motivator,
          message: 'Readiness 72.',
          timestamp: now,
          passed: true,
          findingsCount: 0,
        ),
        CoachLogEntry(
          id: '2',
          persona: CoachingPersona.analyst,
          message: 'No data token.',
          timestamp: now,
          passed: false,
          findingsCount: 1,
        ),
        CoachLogEntry(
          id: '3',
          persona: CoachingPersona.motivator,
          message: '3 sets done.',
          timestamp: now,
          passed: true,
          findingsCount: 0,
        ),
        CoachLogEntry(
          id: '4',
          persona: CoachingPersona.zen,
          message: 'No evidence.',
          timestamp: now,
          passed: false,
          findingsCount: 2,
        ),
      ];
      final report = computeConsistencyReport(entries);
      expect(report.totalMessages, 4);
      expect(report.passedMessages, 2);
      expect(report.consistencyScore, 50);
    });

    test('persona distribution counts correctly', () {
      final now = DateTime(2026, 7, 3);
      final entries = [
        CoachLogEntry(
          id: '1',
          persona: CoachingPersona.motivator,
          message: 'msg1',
          timestamp: now,
          passed: true,
          findingsCount: 0,
        ),
        CoachLogEntry(
          id: '2',
          persona: CoachingPersona.motivator,
          message: 'msg2',
          timestamp: now,
          passed: true,
          findingsCount: 0,
        ),
        CoachLogEntry(
          id: '3',
          persona: CoachingPersona.analyst,
          message: 'msg3',
          timestamp: now,
          passed: true,
          findingsCount: 0,
        ),
      ];
      final report = computeConsistencyReport(entries);
      expect(report.personaDistribution[CoachingPersona.motivator], 2);
      expect(report.personaDistribution[CoachingPersona.analyst], 1);
      expect(report.personaDistribution[CoachingPersona.challenger], isNull);
    });

    test('fallback rate computed correctly', () {
      final now = DateTime(2026, 7, 3);
      final entries = [
        CoachLogEntry(
          id: '1',
          persona: CoachingPersona.motivator,
          message: 'msg1',
          timestamp: now,
          passed: true,
          findingsCount: 0,
          isFallback: false,
        ),
        CoachLogEntry(
          id: '2',
          persona: CoachingPersona.motivator,
          message: 'msg2',
          timestamp: now,
          passed: true,
          findingsCount: 0,
          isFallback: true,
        ),
        CoachLogEntry(
          id: '3',
          persona: CoachingPersona.motivator,
          message: 'msg3',
          timestamp: now,
          passed: true,
          findingsCount: 0,
          isFallback: true,
        ),
      ];
      final report = computeConsistencyReport(entries);
      expect(report.fallbackRate, closeTo(0.667, 0.01));
    });

    test('recent entries sorted newest first, limited to 20', () {
      final base = DateTime(2026, 7, 3);
      final entries = [
        for (int i = 0; i < 25; i++)
          CoachLogEntry(
            id: 'entry_$i',
            persona: CoachingPersona.analyst,
            message: 'msg $i',
            timestamp: base.add(Duration(hours: i)),
            passed: true,
            findingsCount: 0,
          ),
      ];
      final report = computeConsistencyReport(entries);
      expect(report.recentEntries.length, 20);
      // Newest first.
      expect(report.recentEntries.first.id, 'entry_24');
    });

    test('deterministic — same input yields same report', () {
      final now = DateTime(2026, 7, 3);
      final entries = [
        CoachLogEntry(
          id: '1',
          persona: CoachingPersona.motivator,
          message: 'Readiness 72.',
          timestamp: now,
          passed: true,
          findingsCount: 0,
        ),
      ];
      final a = computeConsistencyReport(entries);
      final b = computeConsistencyReport(entries);
      expect(a.totalMessages, b.totalMessages);
      expect(a.consistencyScore, b.consistencyScore);
      expect(a.personaDistribution, b.personaDistribution);
      expect(a.fallbackRate, b.fallbackRate);
    });
  });

  group('CoachConsistencyScreen widget', () {
    testWidgets('renders with header and consistency score', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: CoachConsistencyScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Consistency score'), findsOneWidget);
      expect(find.text('Persona distribution'), findsOneWidget);
      expect(find.text('Recent coaching'), findsOneWidget);
    });

    testWidgets('shows persona labels in distribution', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: CoachConsistencyScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Motivator'), findsWidgets);
      expect(find.text('Analyst'), findsWidgets);
      expect(find.text('Challenger'), findsWidgets);
      expect(find.text('Zen'), findsWidgets);
    });

    testWidgets('shows consistency score number', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: CoachConsistencyScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // The seed entries are all passing, so score should be 100.
      expect(find.text('100'), findsOneWidget);
    });
  });
}
