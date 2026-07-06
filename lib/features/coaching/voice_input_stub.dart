library;

/// Status of the voice input service.
enum VoiceInputStatus {
  /// Service is idle, not listening.
  idle,

  /// Actively listening for speech.
  listening,

  /// Processing the captured audio.
  processing,

  /// Service is unavailable (no mic permission, hardware issue, etc.).
  unavailable,

  /// An error occurred.
  error,
}

/// Represents a single voice input capture.
class VoiceInput {
  const VoiceInput({
    required this.transcript,
    required this.confidence,
    required this.language,
    required this.duration,
  });

  /// The transcribed text.
  final String transcript;

  /// Confidence score from 0.0 to 1.0.
  final double confidence;

  /// BCP-47 language tag (e.g. 'en-US').
  final String language;

  /// Duration of the captured audio.
  final Duration duration;

  /// Whether the confidence is high enough to act on (≥ 0.7).
  bool get isHighConfidence => confidence >= 0.7;

  /// Whether the transcript is empty or whitespace-only.
  bool get isEmpty => transcript.trim().isEmpty;
}

/// Stub implementation of a voice input service.
///
/// This provides the interface contract for speech-to-text integration.
/// Replace the stub logic with a real STT engine (e.g. speech_to_text,
/// whisper, or a platform channel) when ready.
class VoiceInputService {
  VoiceInputService();

  VoiceInputStatus _status = VoiceInputStatus.idle;
  String _transcript = '';
  String _language = 'en-US';

  /// Current service status.
  VoiceInputStatus get status => _status;

  /// Whether the service is currently listening.
  bool get isListening => _status == VoiceInputStatus.listening;

  /// The currently active language.
  String get activeLanguage => _language;

  /// Sets the active recognition language.
  void setLanguage(String bcp47Tag) {
    _language = bcp47Tag;
  }

  /// Starts listening for speech.
  ///
  /// Returns `true` if listening started successfully.
  /// Returns `false` if the service is unavailable or already listening.
  bool startListening() {
    if (_status == VoiceInputStatus.listening) return false;
    if (_status == VoiceInputStatus.unavailable) return false;

    _status = VoiceInputStatus.listening;
    _transcript = '';
    return true;
  }

  /// Stops listening and returns the captured input.
  ///
  /// Returns `null` if no speech was captured or the service wasn't listening.
  VoiceInput? stopListening() {
    if (_status != VoiceInputStatus.listening) return null;

    _status = VoiceInputStatus.idle;

    // Stub: return empty — a real implementation would finalize the audio.
    if (_transcript.trim().isEmpty) return null;

    return VoiceInput(
      transcript: _transcript,
      confidence: 0.85, // Stub confidence
      language: _language,
      duration: const Duration(seconds: 3), // Stub duration
    );
  }

  /// Returns the current partial/final transcript.
  String getTranscript() => _transcript;

  /// Whether the voice input service is available on this device.
  ///
  /// A real implementation would check microphone permission and hardware.
  bool isAvailable() => _status != VoiceInputStatus.unavailable;

  /// Simulates receiving a transcript (for testing / stub purposes).
  ///
  /// In production, this would be driven by the STT engine's callbacks.
  void simulateTranscript(String text, {double confidence = 0.9}) {
    if (_status == VoiceInputStatus.listening) {
      _transcript = text;
    }
  }

  /// Resets the service to its initial state.
  void reset() {
    _status = VoiceInputStatus.idle;
    _transcript = '';
  }
}
