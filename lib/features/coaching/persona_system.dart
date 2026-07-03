/// Persona / tone-arc system — M7 Coaching milestone.
///
/// Implements Doctrine L1-2 (fixed 4-persona system) and L1-3 (tone-arc:
/// directive share decays from ~80% to ~20% over day 0-30 as competence
/// is demonstrated).
///
/// Personas (L1-2.1..L1-2.4):
///   - Motivator  — momentum builder, warm, effort-noticing
///   - Analyst    — pattern interpreter, precise, trend-driven
///   - Challenger — standard-raiser, direct, evidence-led
///   - Zen        — recovery stabilizer, calm, quality-first
///
/// Tone-arc (L1-3): directive share by day-range:
///   Day  0-7  → 80% directive / 20% supportive
///   Day  8-14 → 60% directive / 40% supportive
///   Day 15-21 → 40% directive / 60% supportive
///   Day 22-30 → 20% directive / 80% supportive
///
/// The tone-arc also adjusts persona *intensity* based on the user's current
/// readiness/fatigue state: when fatigue is high or readiness low, even the
/// Challenger softens and Zen takes priority. This is the meta-cognitive layer
/// (L1-1.10: the coach audits its own stance and adjusts intensity).
///
/// Pure Dart, deterministic, no I/O.
library;

import 'package:transformfit/engine/fatigue.dart';

// ---------------------------------------------------------------------------
// Personas (L1-2)
// ---------------------------------------------------------------------------

/// The four doctrine-defined coaching personas.
enum CoachingPersona {
  motivator,
  analyst,
  challenger,
  zen;

  String get label => switch (this) {
    motivator => 'Motivator',
    analyst => 'Analyst',
    challenger => 'Challenger',
    zen => 'Zen',
  };

  /// L1-2.1: Motivator role is momentum builder.
  /// L1-2.2: Analyst role is pattern interpreter.
  /// L1-2.3: Challenger role is standard-raiser.
  /// L1-2.4: Zen role is recovery stabilizer.
  String get role => switch (this) {
    motivator => 'Momentum builder',
    analyst => 'Pattern interpreter',
    challenger => 'Standard-raiser',
    zen => 'Recovery stabilizer',
  };

  /// Behavior descriptor matching doctrine law text.
  String get behavior => switch (this) {
    motivator => 'Warm, forward, effort-noticing, and consistency-celebrating.',
    analyst => 'Precise, trend-driven, and anomaly-aware.',
    challenger =>
      'Direct, high-bar, and evidence-led confrontation without shame.',
    zen => 'Calm, quality-first, and sustainability-focused.',
  };
}

/// Full persona definition: role + behavior rules + message templates.
class PersonaDefinition {
  const PersonaDefinition({
    required this.persona,
    required this.role,
    required this.behaviorRules,
    required this.templates,
  });

  final CoachingPersona persona;
  final String role;
  final List<String> behaviorRules;
  final PersonaTemplates templates;
}

/// Message templates per persona. Each template is a function that takes
/// concrete data tokens and returns a <=60-word coaching message body.
class PersonaTemplates {
  const PersonaTemplates({
    required this.sessionStart,
    required this.midSession,
    required this.sessionEnd,
    required this.recovery,
    required this.stall,
  });

  final String Function(PersonaData data) sessionStart;
  final String Function(PersonaData data) midSession;
  final String Function(PersonaData data) sessionEnd;
  final String Function(PersonaData data) recovery;
  final String Function(PersonaData data) stall;
}

/// Concrete data tokens injected into persona templates (L1-8: specific
/// data only). Every template must use at least one of these.
class PersonaData {
  const PersonaData({
    this.readinessScore,
    this.sessionCount,
    this.volumeKg,
    this.rpe,
    this.streakDays,
    this.sorenessAreas,
    this.userPhrase,
  });

  final int? readinessScore;
  final int? sessionCount;
  final double? volumeKg;
  final int? rpe;
  final int? streakDays;
  final int? sorenessAreas;
  final String? userPhrase;
}

// ---------------------------------------------------------------------------
// Persona registry — all four definitions (L1-2)
// ---------------------------------------------------------------------------

/// All four persona definitions, keyed by enum.
final Map<CoachingPersona, PersonaDefinition> personaDefinitions = {
  CoachingPersona.motivator: PersonaDefinition(
    persona: CoachingPersona.motivator,
    role: 'Momentum builder',
    behaviorRules: [
      'Emphasize momentum and effort with specific session evidence.',
      'Celebrate consistency, not intensity.',
      'Notice and name forward progress.',
      'Never use generic encouragement (L1-7).',
    ],
    templates: PersonaTemplates(
      sessionStart: (d) =>
          'Readiness ${d.readinessScore ?? '—'} and ${d.sessionCount ?? 0} sessions logged. '
          'Momentum is building — today keeps the chain going.',
      midSession: (d) =>
          '${d.volumeKg?.round() ?? 0} kg moved so far. Effort is showing up in the numbers.',
      sessionEnd: (d) =>
          'Session complete. ${d.sessionCount ?? 0} promises kept. '
          'That consistency is the whole game.',
      recovery: (d) =>
          '${d.sorenessAreas ?? 0} sore ${(d.sorenessAreas ?? 0) == 1 ? 'area' : 'areas'} today. '
          'A recovery walk counts — momentum stays.',
      stall: (d) =>
          'No session in ${d.streakDays ?? 0} days. The restart is small: one set, logged.',
    ),
  ),
  CoachingPersona.analyst: PersonaDefinition(
    persona: CoachingPersona.analyst,
    role: 'Pattern interpreter',
    behaviorRules: [
      'Cite specific metrics and trend deltas.',
      'Surface anomalies with data.',
      'Compare current vs prior sessions.',
      'Use precise numbers, never vague estimates.',
    ],
    templates: PersonaTemplates(
      sessionStart: (d) =>
          'Readiness ${d.readinessScore ?? '—'}. '
          'Last session hit ${d.volumeKg?.round() ?? 0} kg — baseline is set.',
      midSession: (d) =>
          'RPE ${d.rpe ?? '—'} on the last set. '
          'Trend is tracking the progression corridor.',
      sessionEnd: (d) =>
          'Volume: ${d.volumeKg?.round() ?? 0} kg across ${d.sessionCount ?? 0} sessions. '
          'The data shows a clean upward path.',
      recovery: (d) =>
          '${d.sorenessAreas ?? 0} sore ${(d.sorenessAreas ?? 0) == 1 ? 'area' : 'areas'}, '
          'readiness ${d.readinessScore ?? '—'}. Recovery is within normal range.',
      stall: (d) =>
          'Gap of ${d.streakDays ?? 0} days detected. '
          'Pattern suggests recalibration, not restart.',
    ),
  ),
  CoachingPersona.challenger: PersonaDefinition(
    persona: CoachingPersona.challenger,
    role: 'Standard-raiser',
    behaviorRules: [
      'Challenge coasting with data and no guilt framing.',
      'Raise the bar with evidence, not pressure.',
      'Confront honestly without shame (L2-5, L2-7).',
      'Name the gap between intent and execution.',
    ],
    templates: PersonaTemplates(
      sessionStart: (d) =>
          'Readiness ${d.readinessScore ?? '—'}. '
          'The target is ${d.rpe ?? '—'} RPE. Earn the last set.',
      midSession: (d) =>
          '${d.volumeKg?.round() ?? 0} kg logged. '
          'Is this the standard you set, or the one you settled for?',
      sessionEnd: (d) =>
          '${d.sessionCount ?? 0} sessions done. '
          'Next week the bar moves — data says you are ready.',
      recovery: (d) =>
          '${d.sorenessAreas ?? 0} sore ${(d.sorenessAreas ?? 0) == 1 ? 'area' : 'areas'}. '
          'Recovery is not optional — it is how the standard holds.',
      stall: (d) =>
          '${d.streakDays ?? 0} days off. The standard does not lower — it waits. '
          'Log the next set.',
    ),
  ),
  CoachingPersona.zen: PersonaDefinition(
    persona: CoachingPersona.zen,
    role: 'Recovery stabilizer',
    behaviorRules: [
      'Prioritize recovery quality and long-term continuity.',
      'Keep calm and quality-first in every message.',
      'Frame rest as productive, not passive.',
      'Reduce intensity when fatigue is high.',
    ],
    templates: PersonaTemplates(
      sessionStart: (d) =>
          'Readiness ${d.readinessScore ?? '—'}. '
          'Today is about quality of movement, not quantity.',
      midSession: (d) =>
          'RPE ${d.rpe ?? '—'}. Breathe into the effort. Form first, load second.',
      sessionEnd: (d) =>
          'Session done. ${d.sessionCount ?? 0} in the ledger. '
          'Rest is where the work integrates.',
      recovery: (d) =>
          '${d.sorenessAreas ?? 0} sore ${(d.sorenessAreas ?? 0) == 1 ? 'area' : 'areas'}. '
          'A walk, water, sleep — recovery is training.',
      stall: (d) =>
          '${d.streakDays ?? 0} days away. Return gently. The body remembers.',
    ),
  ),
};

// ---------------------------------------------------------------------------
// Tone-arc system (L1-3)
// ---------------------------------------------------------------------------

/// The four tone-arc phases defined by doctrine L1-3.
enum ToneArcPhase {
  days0to7, // 80% directive / 20% supportive
  days8to14, // 60% directive / 40% supportive
  days15to21, // 40% directive / 60% supportive
  days22to30; // 20% directive / 80% supportive

  /// Directive share as a fraction (0.0–1.0). L1-3.
  double get directiveShare => switch (this) {
    days0to7 => 0.80,
    days8to14 => 0.60,
    days15to21 => 0.40,
    days22to30 => 0.20,
  };

  /// Supportive share is the complement of directive.
  double get supportiveShare => 1.0 - directiveShare;

  String get label => switch (this) {
    days0to7 => 'Days 0–7',
    days8to14 => 'Days 8–14',
    days15to21 => 'Days 15–21',
    days22to30 => 'Days 22–30',
  };
}

/// Resolve the tone-arc phase from the user's day number (0-indexed from
/// first session / onboarding completion).
///
/// L1-3: directive share decays from ~80% to ~20% over day 0-30. After
/// day 30 the most permissive phase (20% directive) continues.
ToneArcPhase toneArcForDay(int daySinceStart) {
  if (daySinceStart < 0) daySinceStart = 0;
  if (daySinceStart <= 7) return ToneArcPhase.days0to7;
  if (daySinceStart <= 14) return ToneArcPhase.days8to14;
  if (daySinceStart <= 21) return ToneArcPhase.days15to21;
  return ToneArcPhase.days22to30;
}

// ---------------------------------------------------------------------------
// Persona selection (tone-arc × readiness/fatigue state)
// ---------------------------------------------------------------------------

/// User state that drives persona selection. Combines the tone-arc day
/// position with current readiness and fatigue to pick the right persona
/// and calibrate intensity.
class PersonaContext {
  const PersonaContext({
    required this.daySinceStart,
    required this.readinessScore,
    required this.fatigueState,
    this.recentSessionCount = 0,
    this.missedDays = 0,
  });

  final int daySinceStart;
  final int readinessScore; // 0–100
  final String fatigueState; // 'safe' | 'caution' | 'high'
  final int recentSessionCount;
  final int missedDays;

  ToneArcPhase get toneArcPhase => toneArcForDay(daySinceStart);

  /// Whether the user is in a low-readiness / high-fatigue state that
  /// should override the default persona toward Zen.
  bool get isRecoveryPriority =>
      readinessScore < 50 ||
      fatigueState == 'high' ||
      fatigueState == 'caution';

  /// Whether the user is coasting (many sessions, low fatigue, high
  /// readiness) — Challenger territory.
  bool get isCoasting =>
      readinessScore >= 70 && fatigueState == 'safe' && recentSessionCount >= 3;
}

/// Persona intensity level — controls how forceful the persona's voice is.
/// Calibrated by readiness/fatigue (meta-cognition L1-1.10).
enum PersonaIntensity {
  low, // Softened — recovery/fatigue detected
  normal, // Standard intensity
  high; // Elevated — coasting or early-stage momentum needed

  double get multiplier => switch (this) {
    low => 0.70,
    normal => 1.0,
    high => 1.15,
  };
}

/// Result of persona selection: which persona, what intensity, and the
/// directive/supportive split for this moment.
class PersonaSelection {
  const PersonaSelection({
    required this.persona,
    required this.intensity,
    required this.toneArc,
    required this.rationale,
  });

  final CoachingPersona persona;
  final PersonaIntensity intensity;
  final ToneArcPhase toneArc;
  final String rationale;

  double get directiveShare => toneArc.directiveShare * intensity.multiplier;
  double get supportiveShare => 1.0 - directiveShare;

  PersonaDefinition get definition => personaDefinitions[persona]!;
}

/// Select the optimal persona for the current user context.
///
/// Decision logic (deterministic):
/// 1. If recovery is priority (low readiness, high fatigue) → Zen (intensity
///    may be low if extremely fatigued).
/// 2. If missed days >=3 → Motivator for low-friction re-entry.
/// 3. If coasting (high readiness, safe fatigue, 3+ sessions) → Challenger.
/// 4. If early stage (days 0-7) with few sessions → Motivator (momentum).
/// 5. Default → Analyst (steady-state pattern interpretation).
///
/// Intensity is calibrated by readiness/fatigue:
/// - High fatigue or very low readiness → low intensity
/// - Coasting or early momentum → high intensity
/// - Otherwise → normal
PersonaSelection selectPersona(PersonaContext ctx) {
  final phase = ctx.toneArcPhase;

  // 1. Recovery priority overrides everything (L1-2.4, L1-1.10).
  if (ctx.isRecoveryPriority) {
    final intensity = ctx.readinessScore < 35 || ctx.fatigueState == 'high'
        ? PersonaIntensity.low
        : PersonaIntensity.normal;
    return PersonaSelection(
      persona: CoachingPersona.zen,
      intensity: intensity,
      toneArc: phase,
      rationale: ctx.readinessScore < 35
          ? 'Readiness ${ctx.readinessScore} and ${ctx.fatigueState} fatigue — '
                'Zen at reduced intensity for recovery safety.'
          : 'Readiness ${ctx.readinessScore} with ${ctx.fatigueState} fatigue — '
                'Zen for recovery-first coaching.',
    );
  }

  // 2. Missed sessions pattern → Motivator for re-engagement.
  if (ctx.missedDays >= 3) {
    return PersonaSelection(
      persona: CoachingPersona.motivator,
      intensity: PersonaIntensity.normal,
      toneArc: phase,
      rationale:
          '${ctx.missedDays} days missed — '
          'Motivator for low-friction re-entry.',
    );
  }

  // 3. Coasting → Challenger (L1-2.3).
  if (ctx.isCoasting) {
    return PersonaSelection(
      persona: CoachingPersona.challenger,
      intensity: PersonaIntensity.high,
      toneArc: phase,
      rationale:
          'Readiness ${ctx.readinessScore}, safe fatigue, '
          '${ctx.recentSessionCount} sessions — Challenger to raise the standard.',
    );
  }

  // 4. Early stage with few sessions → Motivator (L1-2.1).
  if (phase == ToneArcPhase.days0to7 && ctx.recentSessionCount < 3) {
    return PersonaSelection(
      persona: CoachingPersona.motivator,
      intensity: PersonaIntensity.high,
      toneArc: phase,
      rationale:
          'Days ${ctx.daySinceStart}, ${ctx.recentSessionCount} sessions — '
          'Motivator to build activation momentum.',
    );
  }

  // 5. Default → Analyst (L1-2.2).
  return PersonaSelection(
    persona: CoachingPersona.analyst,
    intensity: PersonaIntensity.normal,
    toneArc: phase,
    rationale:
        'Steady state — Analyst for pattern interpretation and trend data.',
  );
}

/// Generate a coaching message from a persona + template type + data.
/// Returns a <=60-word message using the persona's template.
String renderPersonaMessage(
  CoachingPersona persona,
  String templateType,
  PersonaData data,
) {
  final def = personaDefinitions[persona]!;
  final String Function(PersonaData) template;
  switch (templateType) {
    case 'session_start':
      template = def.templates.sessionStart;
    case 'mid_session':
      template = def.templates.midSession;
    case 'session_end':
      template = def.templates.sessionEnd;
    case 'recovery':
      template = def.templates.recovery;
    case 'stall':
      template = def.templates.stall;
    default:
      template = def.templates.sessionStart;
  }
  return template(data);
}

/// Build a [PersonaContext] from the fatigue result and readiness inputs
/// that are already computed by existing engines.
PersonaContext buildPersonaContext({
  required int daySinceStart,
  required int readinessScore,
  required FatigueResult fatigue,
  int recentSessionCount = 0,
  int missedDays = 0,
}) {
  return PersonaContext(
    daySinceStart: daySinceStart,
    readinessScore: readinessScore,
    fatigueState: fatigue.state,
    recentSessionCount: recentSessionCount,
    missedDays: missedDays,
  );
}
