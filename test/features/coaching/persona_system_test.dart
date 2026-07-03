// Unit tests for the M7 persona/tone-arc system.

import 'package:flutter_test/flutter_test.dart';
import 'package:transformfit/engine/fatigue.dart';
import 'package:transformfit/features/coaching/persona_system.dart';

void main() {
  group('CoachingPersona enum', () {
    test('has exactly 4 personas (L1-2)', () {
      expect(CoachingPersona.values.length, 4);
      expect(CoachingPersona.values, contains(CoachingPersona.motivator));
      expect(CoachingPersona.values, contains(CoachingPersona.analyst));
      expect(CoachingPersona.values, contains(CoachingPersona.challenger));
      expect(CoachingPersona.values, contains(CoachingPersona.zen));
    });

    test('each persona has a label, role, and behavior (L1-2.1..L1-2.4)', () {
      for (final p in CoachingPersona.values) {
        expect(p.label, isNotEmpty);
        expect(p.role, isNotEmpty);
        expect(p.behavior, isNotEmpty);
      }
    });

    test('Motivator role matches doctrine', () {
      expect(CoachingPersona.motivator.role, 'Momentum builder');
    });

    test('Analyst role matches doctrine', () {
      expect(CoachingPersona.analyst.role, 'Pattern interpreter');
    });

    test('Challenger role matches doctrine', () {
      expect(CoachingPersona.challenger.role, 'Standard-raiser');
    });

    test('Zen role matches doctrine', () {
      expect(CoachingPersona.zen.role, 'Recovery stabilizer');
    });
  });

  group('personaDefinitions', () {
    test('has a definition for each persona', () {
      for (final p in CoachingPersona.values) {
        expect(personaDefinitions, contains(p));
        final def = personaDefinitions[p]!;
        expect(def.behaviorRules, isNotEmpty);
        expect(def.role, isNotEmpty);
      }
    });

    test('every template function returns a non-empty string', () {
      const data = PersonaData(
        readinessScore: 70,
        sessionCount: 3,
        volumeKg: 1500.0,
        rpe: 7,
        streakDays: 5,
        sorenessAreas: 1,
      );
      for (final p in CoachingPersona.values) {
        final def = personaDefinitions[p]!;
        expect(def.templates.sessionStart(data), isNotEmpty);
        expect(def.templates.midSession(data), isNotEmpty);
        expect(def.templates.sessionEnd(data), isNotEmpty);
        expect(def.templates.recovery(data), isNotEmpty);
        expect(def.templates.stall(data), isNotEmpty);
      }
    });
  });

  group('ToneArcPhase', () {
    test('has exactly 4 phases', () {
      expect(ToneArcPhase.values.length, 4);
    });

    test('directive share decays from 0.80 to 0.20 (L1-3)', () {
      expect(ToneArcPhase.days0to7.directiveShare, 0.80);
      expect(ToneArcPhase.days8to14.directiveShare, 0.60);
      expect(ToneArcPhase.days15to21.directiveShare, 0.40);
      expect(ToneArcPhase.days22to30.directiveShare, 0.20);
    });

    test('supportive share is complement of directive', () {
      for (final phase in ToneArcPhase.values) {
        expect(
          phase.directiveShare + phase.supportiveShare,
          closeTo(1.0, 0.001),
        );
      }
    });
  });

  group('toneArcForDay', () {
    test('day 0-7 returns days0to7', () {
      expect(toneArcForDay(0), ToneArcPhase.days0to7);
      expect(toneArcForDay(3), ToneArcPhase.days0to7);
      expect(toneArcForDay(7), ToneArcPhase.days0to7);
    });

    test('day 8-14 returns days8to14', () {
      expect(toneArcForDay(8), ToneArcPhase.days8to14);
      expect(toneArcForDay(14), ToneArcPhase.days8to14);
    });

    test('day 15-21 returns days15to21', () {
      expect(toneArcForDay(15), ToneArcPhase.days15to21);
      expect(toneArcForDay(21), ToneArcPhase.days15to21);
    });

    test('day 22+ returns days22to30', () {
      expect(toneArcForDay(22), ToneArcPhase.days22to30);
      expect(toneArcForDay(30), ToneArcPhase.days22to30);
      expect(toneArcForDay(100), ToneArcPhase.days22to30);
    });

    test('negative day clamps to 0', () {
      expect(toneArcForDay(-5), ToneArcPhase.days0to7);
    });
  });

  group('PersonaContext', () {
    test('isRecoveryPriority is true for low readiness', () {
      const ctx = PersonaContext(
        daySinceStart: 10,
        readinessScore: 40,
        fatigueState: 'safe',
      );
      expect(ctx.isRecoveryPriority, isTrue);
    });

    test('isRecoveryPriority is true for high fatigue', () {
      const ctx = PersonaContext(
        daySinceStart: 10,
        readinessScore: 70,
        fatigueState: 'high',
      );
      expect(ctx.isRecoveryPriority, isTrue);
    });

    test('isRecoveryPriority is false for good readiness + safe fatigue', () {
      const ctx = PersonaContext(
        daySinceStart: 10,
        readinessScore: 75,
        fatigueState: 'safe',
      );
      expect(ctx.isRecoveryPriority, isFalse);
    });

    test('isCoasting requires high readiness + safe + 3+ sessions', () {
      const coasting = PersonaContext(
        daySinceStart: 20,
        readinessScore: 80,
        fatigueState: 'safe',
        recentSessionCount: 4,
      );
      expect(coasting.isCoasting, isTrue);

      const notCoasting = PersonaContext(
        daySinceStart: 20,
        readinessScore: 80,
        fatigueState: 'safe',
        recentSessionCount: 2,
      );
      expect(notCoasting.isCoasting, isFalse);
    });
  });

  group('selectPersona', () {
    test('returns Zen when recovery is priority', () {
      const ctx = PersonaContext(
        daySinceStart: 10,
        readinessScore: 35,
        fatigueState: 'high',
      );
      final sel = selectPersona(ctx);
      expect(sel.persona, CoachingPersona.zen);
      expect(sel.rationale, contains('Zen'));
    });

    test('returns Challenger when coasting', () {
      const ctx = PersonaContext(
        daySinceStart: 20,
        readinessScore: 80,
        fatigueState: 'safe',
        recentSessionCount: 5,
      );
      final sel = selectPersona(ctx);
      expect(sel.persona, CoachingPersona.challenger);
      expect(sel.intensity, PersonaIntensity.high);
    });

    test('returns Motivator for early-stage with few sessions', () {
      const ctx = PersonaContext(
        daySinceStart: 3,
        readinessScore: 70,
        fatigueState: 'safe',
        recentSessionCount: 1,
      );
      final sel = selectPersona(ctx);
      expect(sel.persona, CoachingPersona.motivator);
      expect(sel.intensity, PersonaIntensity.high);
    });

    test('returns Motivator when missed days >= 3', () {
      const ctx = PersonaContext(
        daySinceStart: 15,
        readinessScore: 70,
        fatigueState: 'safe',
        recentSessionCount: 5,
        missedDays: 4,
      );
      final sel = selectPersona(ctx);
      expect(sel.persona, CoachingPersona.motivator);
    });

    test('returns Analyst as default steady-state', () {
      const ctx = PersonaContext(
        daySinceStart: 15,
        readinessScore: 65,
        fatigueState: 'safe',
        recentSessionCount: 4,
      );
      final sel = selectPersona(ctx);
      expect(sel.persona, CoachingPersona.analyst);
    });

    test('recovery priority overrides coasting', () {
      const ctx = PersonaContext(
        daySinceStart: 20,
        readinessScore: 35,
        fatigueState: 'high',
        recentSessionCount: 5,
      );
      final sel = selectPersona(ctx);
      expect(sel.persona, CoachingPersona.zen);
    });

    test('low intensity when readiness very low', () {
      const ctx = PersonaContext(
        daySinceStart: 10,
        readinessScore: 25,
        fatigueState: 'high',
      );
      final sel = selectPersona(ctx);
      expect(sel.persona, CoachingPersona.zen);
      expect(sel.intensity, PersonaIntensity.low);
    });

    test('selection is deterministic — same context yields same result', () {
      const ctx = PersonaContext(
        daySinceStart: 10,
        readinessScore: 65,
        fatigueState: 'safe',
        recentSessionCount: 3,
      );
      final a = selectPersona(ctx);
      final b = selectPersona(ctx);
      expect(a.persona, b.persona);
      expect(a.intensity, b.intensity);
      expect(a.rationale, b.rationale);
    });
  });

  group('PersonaIntensity', () {
    test('multiplier values', () {
      expect(PersonaIntensity.low.multiplier, 0.70);
      expect(PersonaIntensity.normal.multiplier, 1.0);
      expect(PersonaIntensity.high.multiplier, 1.15);
    });
  });

  group('PersonaSelection', () {
    test('directiveShare incorporates intensity multiplier', () {
      const ctx = PersonaContext(
        daySinceStart: 3,
        readinessScore: 70,
        fatigueState: 'safe',
        recentSessionCount: 1,
      );
      final sel = selectPersona(ctx);
      // Motivator at high intensity in days0to7 (0.80 base).
      // directiveShare = 0.80 * 1.15 = 0.92
      expect(sel.directiveShare, closeTo(0.92, 0.001));
    });

    test('definition returns the correct PersonaDefinition', () {
      const ctx = PersonaContext(
        daySinceStart: 20,
        readinessScore: 80,
        fatigueState: 'safe',
        recentSessionCount: 5,
      );
      final sel = selectPersona(ctx);
      expect(sel.definition.persona, CoachingPersona.challenger);
    });
  });

  group('renderPersonaMessage', () {
    const data = PersonaData(
      readinessScore: 72,
      sessionCount: 3,
      volumeKg: 2500.0,
      rpe: 7,
      streakDays: 0,
      sorenessAreas: 2,
    );

    test('renders session_start template', () {
      final msg = renderPersonaMessage(
        CoachingPersona.analyst,
        'session_start',
        data,
      );
      expect(msg, contains('72'));
    });

    test('renders recovery template', () {
      final msg = renderPersonaMessage(
        CoachingPersona.zen,
        'recovery',
        data,
      );
      expect(msg, contains('2'));
    });

    test('unknown template type falls back to session_start', () {
      final msg = renderPersonaMessage(
        CoachingPersona.motivator,
        'unknown_type',
        data,
      );
      expect(msg, isNotEmpty);
    });
  });

  group('buildPersonaContext', () {
    test('builds context from fatigue result', () {
      const fatigue = FatigueResult(
        acwr: 1.4,
        state: 'caution',
        acuteLoad: 2000,
        chronicLoad: 1428,
        volumeMultiplier: 0.85,
      );
      final ctx = buildPersonaContext(
        daySinceStart: 10,
        readinessScore: 55,
        fatigue: fatigue,
        recentSessionCount: 3,
      );
      expect(ctx.fatigueState, 'caution');
      expect(ctx.isRecoveryPriority, isTrue);
    });
  });
}
