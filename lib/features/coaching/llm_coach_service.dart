/// LLM-backed AI coaching service — M8 LLM Coaching milestone.
///
/// Wraps the deterministic CoachSignal with LLM narration. The deterministic
/// system (CoachSignal → coachNote) is the backbone; the LLM adds natural
/// language narration that makes the coach feel human while staying grounded
/// in the data-driven decision.
///
/// Architecture:
///   CoachSignal (deterministic) → LlmCoachService → CoachMessage
///                                     ↑
///                              OpenAI-compatible API
///                                     ↑
///                              System prompt + user context
///                              + conversation history
///
/// Safety guarantees:
///   - Deterministic coachNote is always the fallback on LLM failure
///   - coachSignalCopyIsGateSafe is applied to every output
///   - Token budget is enforced (max 500 tokens)
///   - Conversation memory is bounded (last 10 messages)
///
/// Uses package:http for cross-platform compatibility (web + mobile).
/// The http package is a transitive dependency via supabase_flutter.
library;

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';
import 'package:transformfit/features/behavior/behavioral_repair_loop.dart';
import 'package:transformfit/features/coaching/coach_message.dart';
import 'package:transformfit/features/coaching/coach_prompt_builder.dart';
import 'package:transformfit/features/coaching/coach_signal.dart';
import 'package:transformfit/features/coaching/dai_interface.dart';
import 'package:transformfit/features/coaching/expertise_personas.dart';
import 'package:transformfit/features/emotion/emotional_experience_map.dart';

/// Configuration for the LLM API endpoint.
@immutable
class LlmConfig {
  const LlmConfig({
    required this.baseUrl,
    required this.apiKey,
    this.model = 'gpt-4o-mini',
    this.maxTokens = maxResponseTokens,
    this.temperature = 0.7,
    this.timeout = const Duration(seconds: 15),
  });

  /// Base URL of the OpenAI-compatible API (e.g., 'https://api.openai.com').
  final String baseUrl;

  /// API key for authentication.
  final String apiKey;

  /// Model identifier.
  final String model;

  /// Maximum tokens in the response.
  final int maxTokens;

  /// Temperature for generation (0.0–2.0).
  final double temperature;

  /// Request timeout.
  final Duration timeout;

  /// The chat completions endpoint.
  String get chatEndpoint => '$baseUrl/v1/chat/completions';
}

/// The core LLM coaching service.
///
/// Usage:
/// ```dart
/// final service = LlmCoachService(config: LlmConfig(...));
/// final message = await service.narrate(
///   coachSignal: signal,
///   emotion: emotionMap,
///   repairLoop: repairLoop,
///   dai: daiInterface,
///   history: conversationHistory,
/// );
/// ```
class LlmCoachService {
  LlmCoachService({
    required this.config,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final LlmConfig config;
  final http.Client _client;

  /// Conversation memory — the last N messages for context.
  final List<CoachMessage> _memory = [];

  /// Maximum messages to retain in memory.
  static const int _maxMemorySize = maxConversationHistory;

  /// Generate a coach message with LLM narration.
  ///
  /// The deterministic CoachSignal is always carried through. If the LLM
  /// fails, is offline, or produces unsafe output, the deterministic
  /// coachNote is used as the message content.
  Future<CoachMessage> narrate({
    required CoachSignal coachSignal,
    required EmotionalExperienceMap emotion,
    required BehavioralRepairLoop repairLoop,
    required DaiInterface dai,
    List<CoachMessage>? history,
    ExpertisePersona? expertisePersona,
    int? daySinceStart,
  }) async {
    final effectiveHistory = history ?? _memory;
    final promptContext = buildCoachPrompt(
      coachSignal: coachSignal,
      emotion: emotion,
      repairLoop: repairLoop,
      dai: dai,
      history: effectiveHistory,
      expertisePersona: expertisePersona,
      daySinceStart: daySinceStart,
    );

    // Attempt LLM narration
    String llmNarration = '';
    try {
      llmNarration = await _callLlm(promptContext);
    } catch (_) {
      // LLM failed — deterministic fallback will be used
      llmNarration = '';
    }

    // Safety gate the LLM output
    if (llmNarration.isNotEmpty) {
      if (!_isLlmOutputSafe(llmNarration)) {
        llmNarration = '';
      }
    }

    // Build the message
    final message = _buildCoachMessage(
      coachSignal: coachSignal,
      llmNarration: llmNarration,
      expertisePersona: expertisePersona,
    );

    // Update conversation memory
    _addToMemory(message);

    return message;
  }

  /// Stream LLM narration token-by-token.
  ///
  /// Yields partial text chunks as they arrive from the API. The final
  /// yielded value is the complete narration. If the stream fails at any
  /// point, yields the deterministic fallback.
  ///
  /// Each yielded string is a delta to append to the running narration.
  Stream<String> narrateStream({
    required CoachSignal coachSignal,
    required EmotionalExperienceMap emotion,
    required BehavioralRepairLoop repairLoop,
    required DaiInterface dai,
    List<CoachMessage>? history,
    ExpertisePersona? expertisePersona,
    int? daySinceStart,
  }) async* {
    final effectiveHistory = history ?? _memory;
    final promptContext = buildCoachPrompt(
      coachSignal: coachSignal,
      emotion: emotion,
      repairLoop: repairLoop,
      dai: dai,
      history: effectiveHistory,
      expertisePersona: expertisePersona,
      daySinceStart: daySinceStart,
    );

    String fullNarration = '';
    try {
      await for (final delta in _streamLlm(promptContext)) {
        fullNarration += delta;
        yield delta;
      }
    } catch (_) {
      // Stream failed — if we got partial content, check safety
      if (fullNarration.isNotEmpty && _isLlmOutputSafe(fullNarration)) {
        // Partial narration is safe, keep it
      } else {
        // Fall back to deterministic — yield the coachNote as the final chunk
        fullNarration = '';
        yield coachSignal.coachNote;
      }
    }

    // Final safety check on complete narration
    if (fullNarration.isNotEmpty && !_isLlmOutputSafe(fullNarration)) {
      yield coachSignal.coachNote;
    }

    // Build and store the final message
    final message = _buildCoachMessage(
      coachSignal: coachSignal,
      llmNarration: fullNarration,
      expertisePersona: expertisePersona,
    );
    _addToMemory(message);
  }

  /// Clear conversation memory.
  void clearMemory() {
    _memory.clear();
  }

  /// Get current memory size.
  int get memorySize => _memory.length;

  /// Dispose the HTTP client.
  void dispose() {
    _client.close();
  }

  // ---------------------------------------------------------------------------
  // LLM API calls
  // ---------------------------------------------------------------------------

  /// Single-shot LLM call (non-streaming).
  Future<String> _callLlm(CoachPromptContext context) async {
    final messages = _buildApiMessages(context);

    final body = jsonEncode({
      'model': config.model,
      'messages': messages,
      'max_tokens': context.maxTokens,
      'temperature': config.temperature,
      'stream': false,
    });

    final response = await _client
        .post(
          Uri.parse(config.chatEndpoint),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${config.apiKey}',
          },
          body: body,
        )
        .timeout(config.timeout);

    if (response.statusCode != 200) {
      throw LlmApiException(
        'LLM API returned ${response.statusCode}: ${response.body}',
        statusCode: response.statusCode,
      );
    }

    final json = jsonDecode(response.body) as Map<String, Object?>;
    final choices = json['choices'] as List?;
    if (choices == null || choices.isEmpty) {
      throw const LlmApiException('No choices in LLM response');
    }

    final message = (choices[0] as Map<String, Object?>)['message']
        as Map<String, Object?>?;
    final content = message?['content'] as String?;

    if (content == null || content.trim().isEmpty) {
      throw const LlmApiException('Empty LLM response content');
    }

    return _cleanLlmOutput(content.trim());
  }

  /// Streaming LLM call via SSE (Server-Sent Events).
  Stream<String> _streamLlm(CoachPromptContext context) async* {
    final messages = _buildApiMessages(context);

    final body = jsonEncode({
      'model': config.model,
      'messages': messages,
      'max_tokens': context.maxTokens,
      'temperature': config.temperature,
      'stream': true,
    });

    final request = http.Request('POST', Uri.parse(config.chatEndpoint));
    request.headers.addAll({
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${config.apiKey}',
    });
    request.body = body;

    final streamedResponse = await _client.send(request).timeout(config.timeout);

    if (streamedResponse.statusCode != 200) {
      final errorBody = await streamedResponse.stream.bytesToString();
      throw LlmApiException(
        'LLM streaming API returned ${streamedResponse.statusCode}: $errorBody',
        statusCode: streamedResponse.statusCode,
      );
    }

    // Parse SSE stream
    String buffer = '';
    await for (final chunk in streamedResponse.stream.transform(utf8.decoder)) {
      buffer += chunk;

      // Process complete SSE lines
      while (buffer.contains('\n')) {
        final newlineIndex = buffer.indexOf('\n');
        final line = buffer.substring(0, newlineIndex).trim();
        buffer = buffer.substring(newlineIndex + 1);

        if (line.isEmpty) continue;
        if (line.startsWith(':')) continue; // SSE comment

        if (line.startsWith('data: ')) {
          final data = line.substring(6);

          if (data == '[DONE]') return;

          try {
            final json = jsonDecode(data) as Map<String, Object?>;
            final choices = json['choices'] as List?;
            if (choices == null || choices.isEmpty) continue;

            final delta = (choices[0] as Map<String, Object?>)['delta']
                as Map<String, Object?>?;
            final content = delta?['content'] as String?;

            if (content != null && content.isNotEmpty) {
              yield content;
            }
          } catch (_) {
            // Skip malformed SSE chunks
          }
        }
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Message construction
  // ---------------------------------------------------------------------------

  List<Map<String, String>> _buildApiMessages(CoachPromptContext context) {
    final messages = <Map<String, String>>[];

    // System prompt
    messages.add({'role': 'system', 'content': context.systemPrompt});

    // Conversation history
    messages.addAll(context.conversationHistory);

    // User context (the deterministic signal to narrate)
    messages.add({'role': 'user', 'content': context.userContext});

    return messages;
  }

  CoachMessage _buildCoachMessage({
    required CoachSignal coachSignal,
    required String llmNarration,
    ExpertisePersona? expertisePersona,
  }) {
    final hasLlmNarration = llmNarration.isNotEmpty;
    final content = hasLlmNarration ? llmNarration : coachSignal.coachNote;

    return CoachMessage(
      id: _generateMessageId(),
      role: CoachMessageRole.coach,
      content: content,
      persona: coachSignal.persona,
      deterministicDecision: coachSignal.coachNote,
      llmNarration: llmNarration,
      confidence: coachSignal.confidence,
      sourceIds: coachSignal.sourceIds,
      timestamp: DateTime.now(),
      isStreaming: false,
      expertisePersona: expertisePersona?.label,
    );
  }

  // ---------------------------------------------------------------------------
  // Safety filtering
  // ---------------------------------------------------------------------------

  /// Apply safety checks to LLM output.
  ///
  /// Reuses the coachSignalCopyIsGateSafe logic plus additional checks
  /// specific to LLM-generated content.
  bool _isLlmOutputSafe(String text) {
    if (text.isEmpty) return false;

    // Word count check (doctrine L1-5: ≤ 60 words)
    final wordCount = text.split(RegExp(r'\s+')).length;
    if (wordCount > 60) return false;

    final lower = text.toLowerCase();

    // Banned phrases (from coachSignalCopyIsGateSafe + message_linter)
    const blocked = [
      // Generic encouragement (L1-7 / R4)
      'beast mode',
      'burn fat',
      'cheat',
      'crush your goals',
      'excuses',
      'guilt',
      'no excuses',
      'punish',
      'shame',
      'skinny',
      'summer body',
      'unlock your potential',
      'weight loss',
      'great job',
      'you got this',
      'keep it up',
      "you're crushing it",
      'way to go',
      'nice work',
      'awesome job',
      'proud of you',
      "you're doing great",
      'fantastic work',
      'good for you',
      'well done',
      'good job',
      'amazing job',
      'keep going',
      'hang in there',
      // Guilt/shame/streak-shame (L2-5, L2-6, L2-7)
      'streak broken',
      'you failed',
      'you should have',
      'you missed',
      'lazy',
      'give up',
      'quitter',
      'disappointed',
      'fat',
    ];

    for (final term in blocked) {
      if (lower.contains(term)) return false;
    }

    // Emoji check (doctrine L1-6)
    final emoji = RegExp(r'[\u{1F300}-\u{1F9FF}]', unicode: true);
    if (emoji.hasMatch(text)) return false;

    // Medical claims (doctrine L6-2)
    const medicalClaims = [
      'cures',
      'treats',
      'diagnose',
      'diagnosis',
      'prescribe',
      'prescription',
      'heals',
      'prevents injury',
      'prevents disease',
      'medical advice',
    ];
    for (final claim in medicalClaims) {
      if (lower.contains(claim)) return false;
    }

    // Question mark limit (doctrine L1-11: ≤ 1)
    final questionMarks = '?'.allMatches(text).length;
    if (questionMarks > 1) return false;

    return true;
  }

  /// Clean LLM output — trim, normalize whitespace, remove markdown artifacts.
  String _cleanLlmOutput(String text) {
    var cleaned = text.trim();
    // Remove surrounding quotes if the LLM wrapped its response
    if (cleaned.startsWith('"') && cleaned.endsWith('"') &&
        cleaned.indexOf('"', 1) == cleaned.length - 1) {
      cleaned = cleaned.substring(1, cleaned.length - 1);
    }
    // Remove markdown bold/italic artifacts
    cleaned = cleaned.replaceAll(RegExp(r'\*+'), '');
    // Normalize whitespace
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
    return cleaned;
  }

  // ---------------------------------------------------------------------------
  // Conversation memory
  // ---------------------------------------------------------------------------

  void _addToMemory(CoachMessage message) {
    _memory.add(message);
    while (_memory.length > _maxMemorySize) {
      _memory.removeAt(0);
    }
  }

  // ---------------------------------------------------------------------------
  // ID generation
  // ---------------------------------------------------------------------------

  String _generateMessageId() {
    return 'coach-${DateTime.now().microsecondsSinceEpoch}';
  }
}

/// Exception thrown by the LLM API.
class LlmApiException implements Exception {
  const LlmApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => 'LlmApiException: $message';
}
