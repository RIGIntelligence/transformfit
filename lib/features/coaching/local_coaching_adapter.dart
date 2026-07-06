// ignore_for_file: prefer_initializing_formals

/// Local model adapter for coaching copy generation.
///
/// Provides a local-only narration route using Ollama (`rig-128gb-coder:latest`)
/// so that no remote API key (OPENROUTER_API_KEY) is needed for local development.
///
/// Falls back to deterministic narration on any failure.
/// Used in local/dev mode only; production uses the server-side LLM proxy.
library;

import 'dart:convert';
import 'dart:io';

/// Result of a local coaching narration call.
class LocalNarrationResult {
  const LocalNarrationResult({
    required this.coachingCue,
    required this.modelUsed,
    required this.isFallback,
  });

  final String coachingCue;
  final String modelUsed;
  final bool isFallback;
}

/// Generates coaching copy using a local Ollama model.
///
/// In local/dev mode, this replaces the server-side OpenRouter call.
/// On any failure (model missing, timeout, malformed output), it returns
/// a deterministic coaching cue flagged as fallback.
///
/// Does NOT require any remote API key. Does NOT touch the network
/// (Ollama runs on localhost:11434).
class LocalCoachingAdapter {
  LocalCoachingAdapter({
    // Keep public named parameters stable for tests and dev configuration.
    String model = 'rig-128gb-coder:latest',
    String ollamaHost = 'http://localhost:11434',
    this.timeout = const Duration(seconds: 30),
  }) : _model = model,
       _ollamaHost = ollamaHost;

  final String _model;
  final String _ollamaHost;
  final Duration timeout;

  /// Generate a coaching cue for a readiness zone and session context.
  ///
  /// [readinessZone] is 'push', 'maintain', or 'deload'.
  /// [exerciseCount] is the number of exercises planned.
  /// [volumeMultiplier] is the volume adjustment from readiness.
  Future<LocalNarrationResult> generateCoachingCue({
    required String readinessZone,
    required int exerciseCount,
    required double volumeMultiplier,
    String? userGoal,
  }) async {
    final prompt = _buildPrompt(
      readinessZone: readinessZone,
      exerciseCount: exerciseCount,
      volumeMultiplier: volumeMultiplier,
      userGoal: userGoal,
    );

    try {
      final output = await _callOllama(prompt);
      if (output == null || output.trim().isEmpty) {
        return _fallback(readinessZone, exerciseCount, volumeMultiplier);
      }

      // Clean and validate the output
      final cue = output.trim();
      if (!_validateCue(cue)) {
        return _fallback(readinessZone, exerciseCount, volumeMultiplier);
      }

      return LocalNarrationResult(
        coachingCue: cue,
        modelUsed: _model,
        isFallback: false,
      );
    } catch (_) {
      return _fallback(readinessZone, exerciseCount, volumeMultiplier);
    }
  }

  /// Check if the local model is available.
  Future<bool> isModelAvailable() async {
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 5);
      final request = await client.getUrl(Uri.parse('$_ollamaHost/api/tags'));
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      client.close();

      final data = jsonDecode(body) as Map<String, dynamic>;
      final models = data['models'] as List? ?? [];
      return models.any(
        (m) => (m['name'] as String?)?.startsWith(_model) ?? false,
      );
    } catch (_) {
      return false;
    }
  }

  String _buildPrompt({
    required String readinessZone,
    required int exerciseCount,
    required double volumeMultiplier,
    String? userGoal,
  }) {
    final zoneDesc = switch (readinessZone) {
      'push' => 'high energy, ready to train hard',
      'maintain' => 'moderate energy, steady effort',
      'deload' => 'low energy, recovery focus',
      _ => 'balanced effort',
    };

    final goalPart = userGoal != null ? ' User goal: $userGoal.' : '';

    return 'Write a single sentence coaching cue for a workout session. '
        'Readiness zone: $readinessZone ($zoneDesc). '
        'Exercises planned: $exerciseCount. '
        'Volume multiplier: ${volumeMultiplier.toStringAsFixed(2)}.'
        '$goalPart'
        ' Be specific, motivating, and under 30 words. No emoji.';
  }

  Future<String?> _callOllama(String prompt) async {
    final client = HttpClient();
    client.connectionTimeout = timeout;

    try {
      final request = await client.postUrl(
        Uri.parse('$_ollamaHost/api/generate'),
      );
      request.headers.contentType = ContentType.json;
      request.write(
        jsonEncode({
          'model': _model,
          'prompt': prompt,
          'stream': false,
          'options': {'temperature': 0.3},
        }),
      );

      final response = await request.close().timeout(timeout);
      final body = await response.transform(utf8.decoder).join();
      client.close();

      final data = jsonDecode(body) as Map<String, dynamic>;
      return data['response'] as String?;
    } catch (_) {
      return null;
    }
  }

  bool _validateCue(String cue) {
    // Must not be empty or absurdly long
    if (cue.isEmpty || cue.length > 500) return false;

    // Must not contain banned generic phrases
    final banned = [
      'unlock your potential',
      'crush your goals',
      'be the best version',
      'embrace the journey',
    ];
    final lower = cue.toLowerCase();
    for (final phrase in banned) {
      if (lower.contains(phrase)) return false;
    }

    // Must not contain emoji (basic check)
    final emojiRegex = RegExp('[\u{1F300}-\u{1F9FF}]', unicode: true);
    if (emojiRegex.hasMatch(cue)) return false;

    return true;
  }

  LocalNarrationResult _fallback(
    String readinessZone,
    int exerciseCount,
    double volumeMultiplier,
  ) {
    final cue = switch (readinessZone) {
      'push' =>
        'Readiness is high — $exerciseCount exercises at full volume. Push the top sets.',
      'maintain' =>
        'Steady day — $exerciseCount exercises at standard volume. Hit your numbers.',
      'deload' =>
        'Recovery priority — $exerciseCount exercises at ${(volumeMultiplier * 100).round()}% volume. Move well, don\'t grind.',
      _ => 'Train $exerciseCount exercises today. Match effort to readiness.',
    };

    return LocalNarrationResult(
      coachingCue: cue,
      modelUsed: 'deterministic',
      isFallback: true,
    );
  }
}
