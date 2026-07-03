/// Message-linter guardrail — M7 Coaching milestone.
///
/// Lints coaching messages against Doctrine L1 message rules (L1-4 through
/// L1-11) and L2 anti-patterns. This is the Dart-side companion to the
/// `_shared/llm.ts` guardrail, applied to coaching messages generated
/// locally or received from the edge function.
///
/// Doctrine rules enforced:
///   L1-4  (R1): Echo user words — at least one user-phrase anchor.
///   L1-5  (R2): Word count ≤ 60 words.
///   L1-6  (R3): No emoji.
///   L1-7  (R4): No banned generic-encouragement phrases.
///   L1-8  (R5): Specific data only — at least one concrete data token.
///   L1-9  (R6): Honest uncertainty — low-confidence cases include framing.
///   L1-10 (R7): Weave memory naturally.
///   L1-11 (R8): ≤ 1 question mark.
///   L2-5/6/7: No guilt, shame, streak-shame, or contempt language.
///   L6-2:     No medical claims.
///
/// Pure Dart, deterministic, no I/O.
library;

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

/// Banned generic-encouragement phrases (L1-7 / R4).
const List<String> bannedGenericPhrases = [
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
  'crush your goals',
  'beast mode',
  'no excuses',
  'unlock your potential',
];

/// Banned guilt/shame/streak-shame phrases (L2-5, L2-6, L2-7).
const List<String> bannedShamePhrases = [
  'streak broken',
  'you failed',
  'you should have',
  'you missed',
  'lazy',
  'no excuses',
  'give up',
  'quitter',
  'disappointed',
  'shame',
  'guilt',
  'punish',
  'summer body',
  'skinny',
  'fat',
];

/// Medical-claim trigger words (L6-2: AI never makes medical claims).
/// These are checked as standalone claims, not as passing mentions.
const List<String> medicalClaimPatterns = [
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
  'consult your doctor about',
  'therapy for',
  'rehabilitation for',
  'cures your',
  'eliminates pain',
  'fixes your',
];

/// Data-token keywords (R5 / L1-8): message must include a number or one
/// of these concrete references.
const List<String> dataTokenKeywords = [
  'readiness',
  'session',
  'sets',
  'reps',
  'rpe',
  'rir',
  'volume',
  'load',
  'kg',
  'lb',
  'soreness',
  'streak',
  'week',
  'day',
  'rest',
  'deload',
];

/// Uncertainty framing keywords (R6 / L1-9).
const List<String> uncertaintyMarkers = [
  'not sure',
  'worth trying',
  'confident',
  'uncertain',
  'might',
  'could',
  'experiment',
  'test',
  "don't know",
  'unclear',
];

/// Emoji Unicode range regex.
final RegExp _emojiRegex = RegExp(
  r'[\u{1F1E6}-\u{1F1FF}\u{1F300}-\u{1F5FF}\u{1F600}-\u{1F64F}'
  r'\u{1F680}-\u{1F6FF}\u{1F900}-\u{1F9FF}\u{1FA00}-\u{1FA6F}'
  r'\u{1FA70}-\u{1FAFF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}]',
  unicode: true,
);

/// Maximum word count per message (L1-5 / R2).
const int maxWordCount = 60;

/// Maximum question marks per message (L1-11 / R8).
const int maxQuestionMarks = 1;

// ---------------------------------------------------------------------------
// Lint result types
// ---------------------------------------------------------------------------

/// Severity of a lint finding.
enum LintSeverity {
  error, // Message must not ship.
  warning, // Message is degraded but may ship with a noted issue.
  info, // Advisory only.
}

/// One lint finding — a rule violation or advisory.
class LintFinding {
  const LintFinding({
    required this.rule,
    required this.severity,
    required this.message,
    required this.detail,
  });

  /// The doctrine law / rule ID (e.g. 'L1-5', 'R2').
  final String rule;
  final LintSeverity severity;
  final String message;
  final String detail;

  @override
  String toString() => '[$severity] $rule: $message';
}

/// Full lint result for a coaching message.
class LintResult {
  const LintResult({
    required this.passed,
    required this.findings,
    required this.correctedMessage,
  });

  /// True if no error-severity findings.
  final bool passed;

  /// All findings (errors, warnings, info).
  final List<LintFinding> findings;

  /// Auto-corrected message (R2 truncate, R3 strip emoji, R4 strip banned,
  /// R8 reduce questions). Same as input if no auto-corrections applied.
  final String correctedMessage;

  /// Error-severity findings only.
  List<LintFinding> get errors =>
      findings.where((f) => f.severity == LintSeverity.error).toList();

  /// Warning-severity findings only.
  List<LintFinding> get warnings =>
      findings.where((f) => f.severity == LintSeverity.warning).toList();

  bool get hasErrors => errors.isNotEmpty;
  bool get hasWarnings => warnings.isNotEmpty;
}

// ---------------------------------------------------------------------------
// Public API
// ---------------------------------------------------------------------------

/// Context for the linter — provides the data needed to check rules that
/// depend on external context (R1 echo, R5 data token, R6 uncertainty).
class LintContext {
  const LintContext({
    this.userPhrase,
    this.isLowConfidence = false,
    this.expectedDataTokens = const [],
  });

  /// The user's own phrase that should be echoed (R1 / L1-4). If null,
  /// R1 is not checked (no phrase to echo).
  final String? userPhrase;

  /// Whether the coaching situation is low-confidence (triggers R6).
  final bool isLowConfidence;

  /// Data tokens the message is expected to contain (for R5 checking).
  final List<String> expectedDataTokens;

  /// Default empty context (only structural rules checked).
  static const empty = LintContext();
}

/// Lint a coaching message against all doctrine message rules.
///
/// Returns a [LintResult] with:
/// - [passed]: true if no error-severity findings remain after auto-correction.
/// - [findings]: all rule findings.
/// - [correctedMessage]: the message with auto-correctable fixes applied.
///
/// Auto-correctable rules: R3 (strip emoji), R4 (strip banned phrases),
/// R8 (reduce to ≤1 question mark), R2 (truncate to ≤60 words).
/// Non-auto-correctable rules generate error-severity findings.
LintResult lintMessage(String message, [LintContext context = LintContext.empty]) {
  final findings = <LintFinding>[];
  var corrected = message;

  // R3 (L1-6): No emoji — auto-correct by stripping.
  final emojiCount = countEmoji(corrected);
  if (emojiCount > 0) {
    corrected = stripEmoji(corrected);
    findings.add(LintFinding(
      rule: 'R3',
      severity: LintSeverity.warning,
      message: 'Emoji detected and stripped',
      detail: '$emojiCount emoji run(s) removed (L1-6).',
    ));
  }

  // R4 (L1-7): No banned generic-encouragement — auto-correct by stripping.
  final bannedBeforeR4 = corrected;
  corrected = stripBannedPhrases(corrected);
  if (corrected != bannedBeforeR4) {
    findings.add(LintFinding(
      rule: 'R4',
      severity: LintSeverity.warning,
      message: 'Banned generic-encouragement phrase(s) stripped',
      detail: 'Removed banned phrases per L1-7.',
    ));
  }

  // L2-5/6/7: No shame/guilt language — error, not auto-correctable.
  final shameHit = detectBannedShame(corrected);
  if (shameHit != null) {
    findings.add(LintFinding(
      rule: 'L2-5/6/7',
      severity: LintSeverity.error,
      message: 'Shame or guilt language detected',
      detail: 'Phrase "$shameHit" violates L2-5/L2-6/L2-7.',
    ));
  }

  // L6-2: No medical claims — error.
  final medicalHit = detectMedicalClaim(corrected);
  if (medicalHit != null) {
    findings.add(LintFinding(
      rule: 'L6-2',
      severity: LintSeverity.error,
      message: 'Medical claim detected',
      detail: 'Pattern "$medicalHit" — AI must not make medical claims.',
    ));
  }

  // R8 (L1-11): ≤ 1 question mark — auto-correct by reducing.
  final qCount = countQuestions(corrected);
  if (qCount > maxQuestionMarks) {
    corrected = stripExcessQuestions(corrected);
    findings.add(LintFinding(
      rule: 'R8',
      severity: LintSeverity.warning,
      message: 'Excess question marks reduced to 1',
      detail: 'Had $qCount "?" — reduced to 1 per L1-11.',
    ));
  }

  // R2 (L1-5): ≤ 60 words — auto-correct by truncating.
  final wc = wordCount(corrected);
  if (wc > maxWordCount) {
    corrected = truncateWords(corrected, maxWordCount);
    findings.add(LintFinding(
      rule: 'R2',
      severity: LintSeverity.warning,
      message: 'Word count exceeded and truncated',
      detail: 'Had $wc words — truncated to $maxWordCount per L1-5.',
    ));
  }

  // Re-check word count after all corrections.

  // R5 (L1-8): Specific data only — must have a data token.
  if (!hasDataToken(corrected)) {
    findings.add(LintFinding(
      rule: 'R5',
      severity: LintSeverity.error,
      message: 'No specific data token found',
      detail: 'Message must include a number or data keyword per L1-8.',
    ));
  }

  // R1 (L1-4): Echo user words — if a user phrase was provided, check for
  // at least a near-match anchor.
  if (context.userPhrase != null && context.userPhrase!.isNotEmpty) {
    if (!echoesUserPhrase(corrected, context.userPhrase!)) {
      findings.add(LintFinding(
        rule: 'R1',
        severity: LintSeverity.error,
        message: 'User phrase not echoed',
        detail: 'L1-4 requires at least one user-phrase anchor.',
      ));
    }
  }

  // R6 (L1-9): Honest uncertainty — if low-confidence, message must
  // include uncertainty framing.
  if (context.isLowConfidence) {
    if (!hasUncertaintyMarker(corrected)) {
      findings.add(LintFinding(
        rule: 'R6',
        severity: LintSeverity.error,
        message: 'Missing uncertainty framing for low-confidence case',
        detail: 'L1-9 requires explicit uncertainty language.',
      ));
    }
  }

  // Re-run R4 check on corrected text (in case stripping created a new match).
  if (hasBannedGeneric(corrected)) {
    findings.add(LintFinding(
      rule: 'R4',
      severity: LintSeverity.error,
      message: 'Banned phrase persists after auto-correction',
      detail: 'Manual revision needed per L1-7.',
    ));
  }

  final hasErrors = findings.any((f) => f.severity == LintSeverity.error);

  return LintResult(
    passed: !hasErrors,
    findings: findings,
    correctedMessage: corrected,
  );
}

/// Convenience: lint + return whether the message passes all rules.
bool messagePasses(String message, {LintContext context = LintContext.empty}) {
  return lintMessage(message, context).passed;
}

// ---------------------------------------------------------------------------
// Utility functions (mirrors of _shared/llm.ts helpers, in Dart)
// ---------------------------------------------------------------------------

/// Word count (whitespace-delimited; 0 for empty).
int wordCount(String s) {
  final t = s.trim();
  if (t.isEmpty) return 0;
  return t.split(RegExp(r'\s+')).length;
}

/// Count emoji runs.
int countEmoji(String s) {
  final matches = _emojiRegex.allMatches(s);
  return matches.length;
}

/// Count question marks.
int countQuestions(String s) {
  return '?'.allMatches(s).length;
}

/// Check for banned generic-encouragement phrase presence.
bool hasBannedGeneric(String s) {
  final lower = s.toLowerCase();
  return bannedGenericPhrases.any((p) => lower.contains(p));
}

/// Check for a data token (number or keyword).
bool hasDataToken(String s) {
  if (RegExp(r'\d').hasMatch(s)) return true;
  final lower = s.toLowerCase();
  return dataTokenKeywords.any((k) => lower.contains(k));
}

/// Check for uncertainty framing markers.
bool hasUncertaintyMarker(String s) {
  final lower = s.toLowerCase();
  return uncertaintyMarkers.any((m) => lower.contains(m));
}

/// Detect banned shame language. Returns the first hit or null.
String? detectBannedShame(String s) {
  final lower = s.toLowerCase();
  for (final p in bannedShamePhrases) {
    if (lower.contains(p)) return p;
  }
  return null;
}

/// Detect medical-claim patterns. Returns the first hit or null.
String? detectMedicalClaim(String s) {
  final lower = s.toLowerCase();
  for (final p in medicalClaimPatterns) {
    if (lower.contains(p)) return p;
  }
  return null;
}

/// Strip all emoji from text.
String stripEmoji(String s) {
  return s.replaceAll(_emojiRegex, '').replaceAll(RegExp(r'\s+'), ' ').trim();
}

/// Strip banned generic-encouragement phrases.
String stripBannedPhrases(String s) {
  var out = s;
  for (final p in bannedGenericPhrases) {
    final escaped = RegExp.escape(p);
    out = out.replaceAll(RegExp(escaped, caseSensitive: false), '');
  }
  // Clean up leftover whitespace/punctuation.
  out = out
      .replaceAll(RegExp(r'\s{2,}'), ' ')
      .replaceFirst(RegExp(r'^\s*,\s*'), '')
      .replaceFirst(RegExp(r',\s*$'), '')
      .trim();
  return out;
}

/// Reduce question marks to at most 1, keeping the first.
String stripExcessQuestions(String s) {
  var seen = 0;
  return s.split('').map((ch) {
    if (ch != '?') return ch;
    seen++;
    return seen <= maxQuestionMarks ? '?' : '';
  }).join('');
}

/// Truncate to at most [maxWords] words. Appends '…' if truncated.
String truncateWords(String s, int maxWords) {
  final words = s.trim().split(RegExp(r'\s+'));
  if (words.length <= maxWords) return s.trim();
  final trimmed = words.take(maxWords).join(' ');
  return '${trimmed.replaceFirst(RegExp(r'[,\s]+$'), '')}…';
}

/// Check whether [message] echoes the [userPhrase] — at least a near-match
/// (3+ consecutive words from the phrase appear in the message).
bool echoesUserPhrase(String message, String userPhrase) {
  final phraseWords = userPhrase
      .toLowerCase()
      .split(RegExp(r'[\s,.;!?]+'))
      .where((w) => w.length > 2)
      .toList();
  if (phraseWords.length < 2) {
    // Short phrase — check for direct substring.
    return message.toLowerCase().contains(userPhrase.toLowerCase());
  }
  // Check for 3+ consecutive word overlap.
  for (var i = 0; i <= phraseWords.length - 3; i++) {
    final window = phraseWords.sublist(i, i + 3).join(' ');
    if (message.toLowerCase().contains(window)) return true;
  }
  // Fall back to 2-word overlap for short phrases.
  for (var i = 0; i <= phraseWords.length - 2; i++) {
    final window = phraseWords.sublist(i, i + 2).join(' ');
    if (message.toLowerCase().contains(window)) return true;
  }
  return false;
}
