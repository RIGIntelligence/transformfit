/// Coach message data model — M8 LLM Coaching milestone.
///
/// Represents a single message in the coach conversation. Carries both the
/// deterministic decision (from CoachSignal) and the LLM narration so every
/// message is auditable and the deterministic backbone is never lost.
///
/// Pure Dart data class with JSON serialization for Drift/Supabase persistence.
library;

import 'package:meta/meta.dart';

/// Role of the message sender in the coach conversation.
enum CoachMessageRole {
  coach,
  user;

  String get label => switch (this) {
    CoachMessageRole.coach => 'coach',
    CoachMessageRole.user => 'user',
  };

  static CoachMessageRole fromString(String value) {
    return switch (value) {
      'coach' => CoachMessageRole.coach,
      'user' => CoachMessageRole.user,
      _ => CoachMessageRole.coach,
    };
  }
}

/// A single coach conversation message.
///
/// Every coach-role message carries [deterministicDecision] (the CoachSignal
/// output) alongside [llmNarration] (the LLM-generated text). This dual
/// structure ensures the deterministic backbone is always available for
/// fallback, auditing, and safety gating.
@immutable
class CoachMessage {
  const CoachMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.persona,
    required this.deterministicDecision,
    required this.llmNarration,
    required this.confidence,
    required this.sourceIds,
    required this.timestamp,
    this.isStreaming = false,
    this.expertisePersona,
  });

  /// Unique identifier for this message.
  final String id;

  /// Who sent this message — coach or user.
  final CoachMessageRole role;

  /// The displayed content. For coach messages this equals [llmNarration]
  /// when available, falling back to [deterministicDecision].
  final String content;

  /// The active coaching persona (motivator/analyst/challenger/zen).
  final String persona;

  /// The deterministic coach note from CoachSignal. Always present for
  /// coach-role messages; empty for user messages.
  final String deterministicDecision;

  /// The LLM-generated narration. Empty when the LLM is offline or failed
  /// and the deterministic fallback was used.
  final String llmNarration;

  /// Confidence score (0.0–1.0) from the coach signal.
  final double confidence;

  /// Source IDs that informed this message (for audit trail).
  final List<String> sourceIds;

  /// When this message was created.
  final DateTime timestamp;

  /// Whether this message is still being streamed from the LLM.
  final bool isStreaming;

  /// Optional expertise persona overlay (strengthCoach, longevity, etc.).
  final String? expertisePersona;

  /// Whether this message used the LLM narration or fell back to deterministic.
  bool get usedLlm => llmNarration.isNotEmpty;

  /// The effective display text — LLM narration if available, otherwise
  /// the deterministic decision.
  String get effectiveContent =>
      llmNarration.isNotEmpty ? llmNarration : deterministicDecision;

  /// Semantic label for accessibility.
  String get semanticLabel {
    final source = usedLlm ? 'LLM narration' : 'deterministic fallback';
    return 'Coach $persona ($source): $content';
  }

  /// Create a copy with updated fields (useful for streaming state transitions).
  CoachMessage copyWith({
    String? id,
    CoachMessageRole? role,
    String? content,
    String? persona,
    String? deterministicDecision,
    String? llmNarration,
    double? confidence,
    List<String>? sourceIds,
    DateTime? timestamp,
    bool? isStreaming,
    String? expertisePersona,
  }) {
    return CoachMessage(
      id: id ?? this.id,
      role: role ?? this.role,
      content: content ?? this.content,
      persona: persona ?? this.persona,
      deterministicDecision: deterministicDecision ?? this.deterministicDecision,
      llmNarration: llmNarration ?? this.llmNarration,
      confidence: confidence ?? this.confidence,
      sourceIds: sourceIds ?? this.sourceIds,
      timestamp: timestamp ?? this.timestamp,
      isStreaming: isStreaming ?? this.isStreaming,
      expertisePersona: expertisePersona ?? this.expertisePersona,
    );
  }

  /// Serialize to JSON for Drift/Supabase persistence.
  Map<String, Object?> toJson() => {
    'id': id,
    'role': role.label,
    'content': content,
    'persona': persona,
    'deterministicDecision': deterministicDecision,
    'llmNarration': llmNarration,
    'confidence': confidence,
    'sourceIds': sourceIds,
    'timestamp': timestamp.toIso8601String(),
    'isStreaming': isStreaming,
    'expertisePersona': expertisePersona,
  };

  /// Deserialize from JSON.
  factory CoachMessage.fromJson(Map<String, Object?> json) {
    return CoachMessage(
      id: _stringValue(json, 'id'),
      role: CoachMessageRole.fromString(_stringValue(json, 'role')),
      content: _stringValue(json, 'content'),
      persona: _stringValue(json, 'persona'),
      deterministicDecision: _stringValue(json, 'deterministicDecision'),
      llmNarration: _stringValue(json, 'llmNarration'),
      confidence: _doubleValue(json, 'confidence'),
      sourceIds: _stringListValue(json, 'sourceIds'),
      timestamp: DateTime.parse(_stringValue(json, 'timestamp')),
      isStreaming: json['isStreaming'] as bool? ?? false,
      expertisePersona: json['expertisePersona'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoachMessage &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'CoachMessage(id: $id, role: ${role.label}, persona: $persona, '
      'usedLlm: $usedLlm, confidence: ${confidence.toStringAsFixed(2)})';
}

// ---------------------------------------------------------------------------
// JSON helpers
// ---------------------------------------------------------------------------

String _stringValue(Map<String, Object?> json, String key) {
  return (json[key] as String?)?.trim() ?? '';
}

double _doubleValue(Map<String, Object?> json, String key) {
  final raw = json[key];
  if (raw is double) return raw;
  if (raw is int) return raw.toDouble();
  if (raw is String) return double.tryParse(raw) ?? 0.0;
  return 0.0;
}

List<String> _stringListValue(Map<String, Object?> json, String key) {
  final raw = json[key];
  if (raw is List) {
    return raw.map((e) => e.toString()).toList(growable: false);
  }
  return const [];
}
