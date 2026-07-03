// Unit tests for the M7 message-linter guardrail.

import 'package:flutter_test/flutter_test.dart';
import 'package:transformfit/features/coaching/message_linter.dart';

void main() {
  group('wordCount', () {
    test('empty string is 0', () {
      expect(wordCount(''), 0);
      expect(wordCount('   '), 0);
    });

    test('counts whitespace-delimited words', () {
      expect(wordCount('one two three'), 3);
      expect(wordCount('  leading'), 1);
      expect(wordCount('trailing  '), 1);
    });
  });

  group('countEmoji', () {
    test('no emoji returns 0', () {
      expect(countEmoji('no emoji here'), 0);
    });

    test('detects emoji runs', () {
      expect(countEmoji('hello 💪 there'), 1);
      expect(countEmoji('🔥💪'), 2);
    });
  });

  group('countQuestions', () {
    test('no question marks', () {
      expect(countQuestions('statement.'), 0);
    });

    test('counts question marks', () {
      expect(countQuestions('one? two? three?'), 3);
    });
  });

  group('hasBannedGeneric', () {
    test('detects banned phrase', () {
      expect(hasBannedGeneric('great job today'), isTrue);
      expect(hasBannedGeneric('you got this'), isTrue);
    });

    test('clean text returns false', () {
      expect(hasBannedGeneric('log the next set'), isFalse);
    });
  });

  group('hasDataToken', () {
    test('number counts as data token', () {
      expect(hasDataToken('readiness 72'), isTrue);
    });

    test('keyword counts as data token', () {
      expect(hasDataToken('log your sets'), isTrue);
      expect(hasDataToken('rpe target'), isTrue);
    });

    test('no data token returns false', () {
      expect(hasDataToken('go exercise'), isFalse);
    });
  });

  group('hasUncertaintyMarker', () {
    test('detects uncertainty markers', () {
      expect(hasUncertaintyMarker('not sure about this'), isTrue);
      expect(hasUncertaintyMarker('worth trying'), isTrue);
    });

    test('no marker returns false', () {
      expect(hasUncertaintyMarker('do 3 sets'), isFalse);
    });
  });

  group('detectBannedShame', () {
    test('detects shame phrase', () {
      expect(detectBannedShame('you failed'), 'you failed');
      expect(detectBannedShame('streak broken'), 'streak broken');
    });

    test('clean text returns null', () {
      expect(detectBannedShame('good session today'), isNull);
    });
  });

  group('detectMedicalClaim', () {
    test('detects medical claim', () {
      expect(detectMedicalClaim('this cures your pain'), 'cures');
      expect(detectMedicalClaim('diagnose your issue'), 'diagnose');
    });

    test('clean text returns null', () {
      expect(detectMedicalClaim('log 3 sets at rpe 7'), isNull);
    });
  });

  group('stripEmoji', () {
    test('removes emoji', () {
      expect(stripEmoji('hello 💪 there'), 'hello there');
    });

    test('no change without emoji', () {
      expect(stripEmoji('clean text'), 'clean text');
    });
  });

  group('stripBannedPhrases', () {
    test('removes banned phrases', () {
      final result = stripBannedPhrases('Great job logging 3 sets');
      expect(result.toLowerCase(), isNot(contains('great job')));
    });

    test('clean text unchanged', () {
      expect(stripBannedPhrases('Log 3 sets'), 'Log 3 sets');
    });
  });

  group('stripExcessQuestions', () {
    test('reduces to 1 question mark', () {
      final result = stripExcessQuestions('one? two? three?');
      expect(countQuestions(result), 1);
    });

    test('keeps first question mark', () {
      final result = stripExcessQuestions('one? two?');
      expect(result, startsWith('one?'));
    });
  });

  group('truncateWords', () {
    test('under limit unchanged', () {
      expect(truncateWords('one two three', 5), 'one two three');
    });

    test('over limit truncates', () {
      final result = truncateWords('one two three four five', 3);
      expect(result, contains('…'));
      expect(wordCount(result.replaceAll('…', '').trim()), lessThanOrEqualTo(3));
    });
  });

  group('echoesUserPhrase', () {
    test('direct substring match', () {
      expect(
        echoesUserPhrase('build strength for the season', 'build strength'),
        isTrue,
      );
    });

    test('3-word window match', () {
      expect(
        echoesUserPhrase(
          'you want to build muscle and feel better',
          'I want to build muscle this year',
        ),
        isTrue,
      );
    });

    test('no overlap returns false', () {
      expect(
        echoesUserPhrase('log your sets at rpe 7', 'run a marathon'),
        isFalse,
      );
    });
  });

  group('lintMessage: passing messages', () {
    test('clean message with data token passes', () {
      const msg = 'Readiness 72 and 3 sessions logged. The data shows clean progress.';
      final result = lintMessage(msg);
      expect(result.passed, isTrue);
      expect(result.errors, isEmpty);
    });

    test('message with number and uncertainty passes', () {
      const ctx = LintContext(isLowConfidence: true);
      const msg = 'Not sure yet — readiness 65 might mean a lighter session today.';
      final result = lintMessage(msg, ctx);
      expect(result.passed, isTrue);
    });
  });

  group('lintMessage: R2 word count', () {
    test('message over 60 words is truncated (warning)', () {
      final longMsg = List.generate(70, (i) => 'word$i').join(' ');
      final result = lintMessage(longMsg);
      expect(result.findings.any((f) => f.rule == 'R2'), isTrue);
      expect(wordCount(result.correctedMessage), lessThanOrEqualTo(60));
    });
  });

  group('lintMessage: R3 emoji', () {
    test('emoji is stripped (warning)', () {
      const msg = 'Readiness 72 💪 and 3 sets logged.';
      final result = lintMessage(msg);
      expect(result.findings.any((f) => f.rule == 'R3'), isTrue);
      expect(countEmoji(result.correctedMessage), 0);
    });
  });

  group('lintMessage: R4 banned phrases', () {
    test('banned phrase is stripped (warning)', () {
      const msg = 'Great job on 3 sets today.';
      final result = lintMessage(msg);
      expect(result.findings.any((f) => f.rule == 'R4'), isTrue);
      expect(hasBannedGeneric(result.correctedMessage), isFalse);
    });
  });

  group('lintMessage: R5 data token', () {
    test('no data token is an error', () {
      const msg = 'Go exercise now and feel the burn.';
      final result = lintMessage(msg);
      expect(result.findings.any(
        (f) => f.severity == LintSeverity.error && f.rule == 'R5',
      ), isTrue);
      expect(result.passed, isFalse);
    });
  });

  group('lintMessage: R6 uncertainty', () {
    test('low-confidence without uncertainty marker is error', () {
      const ctx = LintContext(isLowConfidence: true);
      const msg = 'Readiness 72 and 3 sets logged.';
      final result = lintMessage(msg, ctx);
      expect(result.findings.any(
        (f) => f.severity == LintSeverity.error && f.rule == 'R6',
      ), isTrue);
    });
  });

  group('lintMessage: R8 question marks', () {
    test('multiple question marks are reduced (warning)', () {
      const msg = 'Ready for 3 sets? How about rpe 7? Last one at 8?';
      final result = lintMessage(msg);
      expect(result.findings.any((f) => f.rule == 'R8'), isTrue);
      expect(countQuestions(result.correctedMessage), lessThanOrEqualTo(1));
    });
  });

  group('lintMessage: L2-5/6/7 shame language', () {
    test('shame language is an error', () {
      const msg = 'You failed to log 3 sets. Shame on you.';
      final result = lintMessage(msg);
      expect(result.findings.any(
        (f) => f.severity == LintSeverity.error && f.rule == 'L2-5/6/7',
      ), isTrue);
      expect(result.passed, isFalse);
    });
  });

  group('lintMessage: L6-2 medical claims', () {
    test('medical claim is an error', () {
      const msg = 'This routine cures your back pain in 3 sessions.';
      final result = lintMessage(msg);
      expect(result.findings.any(
        (f) => f.severity == LintSeverity.error && f.rule == 'L6-2',
      ), isTrue);
      expect(result.passed, isFalse);
    });
  });

  group('lintMessage: R1 echo user phrase', () {
    test('message without user-phrase echo is error when context has phrase', () {
      const ctx = LintContext(userPhrase: 'build muscle for summer');
      const msg = 'Log 3 sets at rpe 7 today.';
      final result = lintMessage(msg, ctx);
      expect(result.findings.any(
        (f) => f.severity == LintSeverity.error && f.rule == 'R1',
      ), isTrue);
    });

    test('message with user-phrase echo passes R1', () {
      const ctx = LintContext(userPhrase: 'build muscle');
      const msg = 'Build muscle with 3 sets at rpe 7.';
      final result = lintMessage(msg, ctx);
      expect(
        result.findings.where((f) => f.rule == 'R1' && f.severity == LintSeverity.error),
        isEmpty,
      );
    });
  });

  group('lintMessage: combined auto-corrections', () {
    test('emoji + banned phrase + excess questions all corrected', () {
      const msg = 'Great job 💪 on readiness 72! Ready for sets? How about rpe 7?';
      final result = lintMessage(msg);
      expect(countEmoji(result.correctedMessage), 0);
      expect(hasBannedGeneric(result.correctedMessage), isFalse);
      expect(countQuestions(result.correctedMessage), lessThanOrEqualTo(1));
    });
  });

  group('messagePasses', () {
    test('returns bool', () {
      expect(messagePasses('Readiness 72 and 3 sets done.'), isTrue);
      expect(messagePasses('go exercise'), isFalse);
    });
  });

  group('determinism', () {
    test('same message + context yields identical result', () {
      const msg = 'Readiness 72 and 3 sets logged with good form.';
      const ctx = LintContext(isLowConfidence: false);
      final a = lintMessage(msg, ctx);
      final b = lintMessage(msg, ctx);
      expect(a.passed, b.passed);
      expect(a.findings.length, b.findings.length);
      expect(a.correctedMessage, b.correctedMessage);
    });
  });
}
