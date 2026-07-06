import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transformfit/theme/digital_atelier.dart';

/// Accessibility: color contrast audit per WCAG 2.1 AA.
///
/// AA requires ≥ 4.5:1 for normal text, ≥ 3:1 for large text (≥ 18pt or 14pt bold).
///
/// Reports contrast ratios for all text/background combinations used by
/// the Digital Atelier theme.
void main() {
  group('Color contrast (WCAG AA)', () {
    final standard = DigitalAtelierExtension.standard();

    // -- Primary text on backgrounds -----------------------------------------
    test('primary text on background meets AA', () {
      final ratio = _contrastRatio(standard.textPrimary, standard.background);
      debugPrint('📊  textPrimary on background: ${ratio.toStringAsFixed(2)}:1');
      expect(ratio, greaterThanOrEqualTo(4.5), reason: 'textPrimary fails AA (need ≥ 4.5:1)');
    });

    test('primary text on surface meets AA', () {
      final ratio = _contrastRatio(standard.textPrimary, standard.surface);
      debugPrint('📊  textPrimary on surface: ${ratio.toStringAsFixed(2)}:1');
      expect(ratio, greaterThanOrEqualTo(4.5), reason: 'textPrimary on surface fails AA.');
    });

    test('primary text on surfaceElevated meets AA', () {
      final ratio = _contrastRatio(standard.textPrimary, standard.surfaceElevated);
      debugPrint('📊  textPrimary on surfaceElevated: ${ratio.toStringAsFixed(2)}:1');
      expect(ratio, greaterThanOrEqualTo(4.5), reason: 'textPrimary on surfaceElevated fails AA.');
    });

    // -- Secondary text ------------------------------------------------------
    test('secondary text on background meets AA', () {
      final ratio = _contrastRatio(standard.textSecondary, standard.background);
      debugPrint('📊  textSecondary on background: ${ratio.toStringAsFixed(2)}:1');
      expect(ratio, greaterThanOrEqualTo(4.5), reason: 'textSecondary fails AA.');
    });

    test('secondary text on surface meets AA', () {
      final ratio = _contrastRatio(standard.textSecondary, standard.surface);
      debugPrint('📊  textSecondary on surface: ${ratio.toStringAsFixed(2)}:1');
      expect(ratio, greaterThanOrEqualTo(4.5), reason: 'textSecondary on surface fails AA.');
    });

    // -- Muted text (lower contrast acceptable for decorative only) -----------
    test('muted text on background — report ratio', () {
      final ratio = _contrastRatio(standard.textMuted, standard.background);
      debugPrint('📊  textMuted on background: ${ratio.toStringAsFixed(2)}:1');
      // Muted text is intentionally lower contrast — report but don't hard-fail
      // unless it drops below 3:1 (large text minimum).
      expect(ratio, greaterThanOrEqualTo(3.0), reason: 'textMuted below large-text minimum (3:1).');
    });

    // -- Accent text ---------------------------------------------------------
    test('accent (orange) on background meets AA for large text', () {
      final ratio = _contrastRatio(standard.accentPrimary, standard.background);
      debugPrint('📊  accentPrimary on background: ${ratio.toStringAsFixed(2)}:1');
      // Orange on dark is typically used at ≥ 14pt bold → large text threshold.
      expect(ratio, greaterThanOrEqualTo(3.0), reason: 'accentPrimary fails large-text AA (3:1).');
    });

    test('accent (orange) on surface meets AA for large text', () {
      final ratio = _contrastRatio(standard.accentPrimary, standard.surface);
      debugPrint('📊  accentPrimary on surface: ${ratio.toStringAsFixed(2)}:1');
      expect(ratio, greaterThanOrEqualTo(3.0), reason: 'accentPrimary on surface fails large-text AA.');
    });

    test('accentSecondary (purple) on background meets AA', () {
      final ratio = _contrastRatio(standard.accentSecondary, standard.background);
      debugPrint('📊  accentSecondary on background: ${ratio.toStringAsFixed(2)}:1');
      expect(ratio, greaterThanOrEqualTo(3.0), reason: 'accentSecondary fails large-text AA.');
    });

    test('accentTertiary (green) on background meets AA', () {
      final ratio = _contrastRatio(standard.accentTertiary, standard.background);
      debugPrint('📊  accentTertiary on background: ${ratio.toStringAsFixed(2)}:1');
      expect(ratio, greaterThanOrEqualTo(3.0), reason: 'accentTertiary fails large-text AA.');
    });

    // -- Danger text ---------------------------------------------------------
    test('accentDanger on background meets AA', () {
      final ratio = _contrastRatio(standard.accentDanger, standard.background);
      debugPrint('📊  accentDanger on background: ${ratio.toStringAsFixed(2)}:1');
      expect(ratio, greaterThanOrEqualTo(3.0), reason: 'accentDanger fails large-text AA.');
    });

    // -- Inverse text (dark on light) ----------------------------------------
    test('textInverse on accentPrimary meets AA', () {
      final ratio = _contrastRatio(standard.textInverse, standard.accentPrimary);
      debugPrint('📊  textInverse on accentPrimary: ${ratio.toStringAsFixed(2)}:1');
      // Primary button: dark text on orange background.
      expect(ratio, greaterThanOrEqualTo(4.5), reason: 'textInverse on accentPrimary fails AA.');
    });

    // -- Info text -----------------------------------------------------------
    test('accentInfo on background meets AA', () {
      final ratio = _contrastRatio(standard.accentInfo, standard.background);
      debugPrint('📊  accentInfo on background: ${ratio.toStringAsFixed(2)}:1');
      expect(ratio, greaterThanOrEqualTo(3.0), reason: 'accentInfo fails large-text AA.');
    });

    // -- Summary report ------------------------------------------------------
    test('contrast summary report', () {
      final pairs = <String, (Color, Color)>{
        'textPrimary / background': (standard.textPrimary, standard.background),
        'textPrimary / surface': (standard.textPrimary, standard.surface),
        'textPrimary / surfaceElevated': (standard.textPrimary, standard.surfaceElevated),
        'textSecondary / background': (standard.textSecondary, standard.background),
        'textSecondary / surface': (standard.textSecondary, standard.surface),
        'textMuted / background': (standard.textMuted, standard.background),
        'accentPrimary / background': (standard.accentPrimary, standard.background),
        'accentPrimary / surface': (standard.accentPrimary, standard.surface),
        'accentSecondary / background': (standard.accentSecondary, standard.background),
        'accentTertiary / background': (standard.accentTertiary, standard.background),
        'accentDanger / background': (standard.accentDanger, standard.background),
        'accentInfo / background': (standard.accentInfo, standard.background),
        'textInverse / accentPrimary': (standard.textInverse, standard.accentPrimary),
      };

      debugPrint('\n📊  === Contrast Ratio Summary ===');
      for (final entry in pairs.entries) {
        final ratio = _contrastRatio(entry.value.$1, entry.value.$2);
        final pass = ratio >= 4.5 ? '✅ AA' : ratio >= 3.0 ? '⚠️  AA-large' : '❌ FAIL';
        debugPrint('    ${entry.key}: ${ratio.toStringAsFixed(2)}:1 $pass');
      }
    });
  });
}

// ---------------------------------------------------------------------------
// WCAG 2.1 contrast ratio calculation
// ---------------------------------------------------------------------------

/// Calculate relative luminance per WCAG 2.1.
/// Color.r/g/b in Dart 3.x already returns 0.0-1.0.
double _relativeLuminance(Color color) {
  final r = _linearize(color.r);
  final g = _linearize(color.g);
  final b = _linearize(color.b);
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

double _linearize(double channel) {
  return channel <= 0.03928 ? channel / 12.92 : ((channel + 0.055) / 1.055) * ((channel + 0.055) / 1.055);
}

/// Contrast ratio between two colors (1:1 to 21:1).
double _contrastRatio(Color fg, Color bg) {
  final l1 = _relativeLuminance(fg);
  final l2 = _relativeLuminance(bg);
  final lighter = l1 > l2 ? l1 : l2;
  final darker = l1 > l2 ? l2 : l1;
  return (lighter + 0.05) / (darker + 0.05);
}
