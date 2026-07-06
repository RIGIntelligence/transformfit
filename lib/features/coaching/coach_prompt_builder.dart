/// Prompt construction for LLM coaching — M8 LLM Coaching milestone.
///
/// Builds the system prompt and user-message context for the LLM call.
/// The prompt architecture is:
///
///   [System Prompt]
///     ├─ Core persona behavior rules (motivator/analyst/challenger/zen)
///     ├─ Expertise overlay (optional: strengthCoach, longevity, etc.)
///     ├─ Safety rules (doctrine L1, L2, L6 enforcement)
///     ├─ Tone-arc directive/supportive ratio
///     └─ Token budget instruction
///
///   [User Context Block]
///     ├─ Readiness/fatigue state
///     ├─ Emotional experience stage
///     ├─ Behavioral repair mode
///     ├─ Deterministic coach decision (the signal to narrate)
///     └─ DAI rationale
///
///   [Conversation History]
///     └─ Last N messages (user + coach turns)
///
/// Pure Dart, deterministic, no I/O.
library;

import 'package:transformfit/features/behavior/behavioral_repair_loop.dart';
import 'package:transformfit/features/coaching/coach_message.dart';
import 'package:transformfit/features/coaching/coach_signal.dart';
import 'package:transformfit/features/coaching/dai_interface.dart';
import 'package:transformfit/features/coaching/expertise_personas.dart';
import 'package:transformfit/features/coaching/persona_system.dart';
import 'package:transformfit/features/emotion/emotional_experience_map.dart';

/// Maximum conversation history messages to include in the context window.
const int maxConversationHistory = 10;

/// Maximum token budget for LLM responses.
const int maxResponseTokens = 500;

/// Build the full LLM prompt context from the current coaching state.
class CoachPromptContext {
  const CoachPromptContext({
    required this.systemPrompt,
    required this.userContext,
    required this.conversationHistory,
    required this.maxTokens,
  });

  /// The system prompt defining persona, expertise, safety rules, and behavior.
  final String systemPrompt;

  /// The user-context block with readiness, emotion, repair loop, and the
  /// deterministic coach signal to narrate.
  final String userContext;

  /// Formatted conversation history (last N turns).
  final List<Map<String, String>> conversationHistory;

  /// Token budget for the response.
  final int maxTokens;
}

/// Build the complete prompt context for an LLM coaching call.
CoachPromptContext buildCoachPrompt({
  required CoachSignal coachSignal,
  required EmotionalExperienceMap emotion,
  required BehavioralRepairLoop repairLoop,
  required DaiInterface dai,
  required List<CoachMessage> history,
  ExpertisePersona? expertisePersona,
  int? daySinceStart,
}) {
  final persona = _resolvePersona(coachSignal.persona);
  final toneArcPhase = daySinceStart != null
      ? toneArcForDay(daySinceStart)
      : ToneArcPhase.days0to7;

  final systemPrompt = _buildSystemPrompt(
    persona: persona,
    expertisePersona: expertisePersona,
    toneArcPhase: toneArcPhase,
    coachSignal: coachSignal,
  );

  final userContext = _buildUserContext(
    coachSignal: coachSignal,
    emotion: emotion,
    repairLoop: repairLoop,
    dai: dai,
  );

  final formattedHistory = _formatHistory(history);

  return CoachPromptContext(
    systemPrompt: systemPrompt,
    userContext: userContext,
    conversationHistory: formattedHistory,
    maxTokens: maxResponseTokens,
  );
}

// ---------------------------------------------------------------------------
// System prompt construction
// ---------------------------------------------------------------------------

String _buildSystemPrompt({
  required CoachingPersona persona,
  required ExpertisePersona? expertisePersona,
  required ToneArcPhase toneArcPhase,
  required CoachSignal coachSignal,
}) {
  final buffer = StringBuffer();

  // Role definition
  buffer.writeln('# Role');
  buffer.writeln(
    'You are TransformFit\'s AI fitness coach operating in '
    '${persona.label} mode.',
  );
  buffer.writeln();

  // Core persona behavior
  buffer.writeln('# Persona: ${persona.label}');
  final definition = personaDefinitions[persona]!;
  buffer.writeln('Role: ${definition.role}');
  buffer.writeln('Style: ${persona.behavior}');
  buffer.writeln();
  buffer.writeln('Behavior rules:');
  for (final rule in definition.behaviorRules) {
    buffer.writeln('- $rule');
  }
  buffer.writeln();

  // Expertise overlay
  if (expertisePersona != null) {
    final expertise = expertisePersonaDefinitions[expertisePersona];
    if (expertise != null) {
      buffer.writeln('# Expertise Overlay: ${expertise.name}');
      buffer.writeln(expertise.systemPromptFragment);
      buffer.writeln();
      buffer.writeln('Expertise behavior rules:');
      for (final rule in expertise.behaviorRules) {
        buffer.writeln('- $rule');
      }
      buffer.writeln();
      buffer.writeln('Evidence-based protocols you reference:');
      for (final protocol in expertise.protocols) {
        buffer.writeln('- $protocol');
      }
      buffer.writeln();
      buffer.writeln('Stay in your lane — do not address:');
      for (final topic in expertise.forbiddenTopics) {
        buffer.writeln('- $topic');
      }
      buffer.writeln();
    }
  }

  // Tone-arc directive ratio
  buffer.writeln('# Tone-Arc');
  final directivePercent = (toneArcPhase.directiveShare * 100).round();
  final supportivePercent = (toneArcPhase.supportiveShare * 100).round();
  buffer.writeln(
    'Current phase: ${toneArcPhase.label} — '
    '$directivePercent% directive / $supportivePercent% supportive.',
  );
  buffer.writeln(
    'Directive language: clear next-action commands, specific instructions.',
  );
  buffer.writeln(
    'Supportive language: acknowledgment, framing, emotional validation.',
  );
  buffer.writeln(
    'Blend your message to match this ratio. '
    'Early training: more direct commands. Later: more collaborative framing.',
  );
  buffer.writeln();

  // Safety rules (doctrine enforcement)
  buffer.writeln('# Safety Rules (Mandatory)');
  buffer.writeln('- NEVER diagnose injuries, conditions, or medical issues.');
  buffer.writeln('- NEVER prescribe medical treatment, rehabilitation, or therapy.');
  buffer.writeln('- NEVER use shame, guilt, streak-shame, or contempt language.');
  buffer.writeln('- NEVER use generic encouragement phrases ("great job", "you got this", "keep it up", "crush your goals", "beast mode", "no excuses").');
  buffer.writeln('- NEVER use emoji in your response.');
  buffer.writeln('- NEVER recommend specific supplements, medications, or dosages.');
  buffer.writeln('- NEVER make claims about curing, treating, or preventing disease.');
  buffer.writeln('- ALWAYS cite specific data (RPE, sets, reps, volume, readiness) when making recommendations.');
  buffer.writeln('- ALWAYS keep responses under 60 words.');
  buffer.writeln('- ALWAYS include at most one question mark.');
  buffer.writeln('- If confidence is below 0.7, frame your response with honest uncertainty.');
  buffer.writeln('- If pain was reported, prioritize safety and conservative action.');
  buffer.writeln();

  // Token budget
  buffer.writeln('# Output Constraints');
  buffer.writeln('- Maximum response length: 50 words (hard limit).');
  buffer.writeln('- Format: plain text, no markdown, no bullet lists.');
  buffer.writeln('- You are narrating a deterministic coaching decision. '
      'The system has already decided the action. '
      'Your job is to make it feel human, specific, and motivating.');
  buffer.writeln(
    '- Include at least one specific data point from the context.',
  );

  return buffer.toString();
}

// ---------------------------------------------------------------------------
// User context construction
// ---------------------------------------------------------------------------

String _buildUserContext({
  required CoachSignal coachSignal,
  required EmotionalExperienceMap emotion,
  required BehavioralRepairLoop repairLoop,
  required DaiInterface dai,
}) {
  final buffer = StringBuffer();

  buffer.writeln('# Current Coaching Context');
  buffer.writeln();

  // Deterministic signal to narrate
  buffer.writeln('## Deterministic Coach Decision');
  buffer.writeln('Workflow: ${coachSignal.workflowId}');
  buffer.writeln('Coach note: ${coachSignal.coachNote}');
  buffer.writeln('Observation: ${coachSignal.observation}');
  buffer.writeln('Next action: ${coachSignal.nextAction}');
  buffer.writeln('Confidence: ${coachSignal.confidenceLabel}');
  buffer.writeln();

  // Emotional state
  buffer.writeln('## Emotional Experience');
  buffer.writeln('Stage: ${emotion.stage.label}');
  buffer.writeln('Headline: ${emotion.headline}');
  buffer.writeln('Primary feeling: ${emotion.primaryFeeling}');
  buffer.writeln('Risk to avoid: ${emotion.riskToAvoid}');
  buffer.writeln('Emotional promise: ${emotion.emotionalPromise}');
  buffer.writeln();

  // Behavioral repair
  buffer.writeln('## Behavioral Repair Loop');
  buffer.writeln('Mode: ${repairLoop.mode.label}');
  buffer.writeln('Emotional need: ${repairLoop.emotionalNeed}');
  buffer.writeln('Friction: ${repairLoop.friction}');
  buffer.writeln('Repair action: ${repairLoop.repairAction}');
  buffer.writeln('Micro-commitment: ${repairLoop.microCommitment}');
  buffer.writeln();

  // DAI context
  buffer.writeln('## DAI Rationale');
  buffer.writeln('Title: ${dai.title}');
  buffer.writeln('Primary command: ${dai.primaryCommand}');
  buffer.writeln('Rationale: ${dai.rationale}');
  buffer.writeln('Boundary: ${dai.boundary}');
  buffer.writeln();

  // Instruction
  buffer.writeln(
    '## Your Task',
  );
  buffer.writeln(
    'Narrate the deterministic coach decision above in your persona voice. '
    'Make it feel human, specific, and grounded in the data provided. '
    'Keep it under 50 words. Include at least one specific number or data point.',
  );

  return buffer.toString();
}

// ---------------------------------------------------------------------------
// Conversation history formatting
// ---------------------------------------------------------------------------

List<Map<String, String>> _formatHistory(List<CoachMessage> history) {
  // Take the last N messages
  final recent = history.length > maxConversationHistory
      ? history.sublist(history.length - maxConversationHistory)
      : history;

  return recent.map((msg) {
    final role = msg.role == CoachMessageRole.coach ? 'assistant' : 'user';
    return {
      'role': role,
      'content': msg.role == CoachMessageRole.coach
          ? msg.effectiveContent
          : msg.content,
    };
  }).toList(growable: false);
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

CoachingPersona _resolvePersona(String personaKey) {
  return switch (personaKey) {
    'motivator' => CoachingPersona.motivator,
    'analyst' => CoachingPersona.analyst,
    'challenger' => CoachingPersona.challenger,
    'zen' => CoachingPersona.zen,
    _ => CoachingPersona.analyst,
  };
}
