import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transformfit/theme/digital_atelier.dart';

double _contrastRatio(Color foreground, Color background) {
  final l1 = foreground.computeLuminance();
  final l2 = background.computeLuminance();
  final light = l1 > l2 ? l1 : l2;
  final dark = l1 > l2 ? l2 : l1;

  return (light + 0.05) / (dark + 0.05);
}

void main() {
  group('Digital Atelier theme tokens', () {
    test('uses the canonical color and font tokens', skip: true, () {
      final theme = buildDigitalAtelierTheme();

      expect(
        theme.scaffoldBackgroundColor,
        DigitalAtelierTokens.background,
      );
      expect(
        theme.textTheme.headlineMedium?.color,
        DigitalAtelierTokens.textPrimary,
      );
      expect(
        theme.textTheme.bodyLarge?.color,
        DigitalAtelierTokens.textPrimary,
      );
      expect(theme.colorScheme.primary, DigitalAtelierTokens.accentOrange);

      expect(theme.textTheme.headlineMedium?.fontFamily, 'Playfair');
      expect(theme.textTheme.bodyLarge?.fontFamily, 'Inter');
    });

    test('uses design system radius tokens for shapes', skip: true, () {
      final theme = buildDigitalAtelierTheme();

      // Cards use radiusMd (12px) per design system spec.
      final cardShape = theme.cardTheme.shape as RoundedRectangleBorder;
      expect(
        cardShape.borderRadius,
        BorderRadius.circular(12),
      );

      // Buttons use radiusSm (8px).
      final elevatedShape =
          theme.elevatedButtonTheme.style?.shape?.resolve(<WidgetState>{})
              as RoundedRectangleBorder;
      expect(
        elevatedShape.borderRadius,
        BorderRadius.circular(8),
      );

      final textButtonShape =
          theme.textButtonTheme.style?.shape?.resolve(<WidgetState>{})
              as RoundedRectangleBorder;
      expect(
        textButtonShape.borderRadius,
        BorderRadius.circular(8),
      );

      // Inputs use radiusSm (8px).
      final inputBorder = theme.inputDecorationTheme.border as OutlineInputBorder;
      expect(
        inputBorder.borderRadius,
        BorderRadius.circular(8),
      );
    });

    test('meets WCAG AA contrast for primary text on background', () {
      final ratio = _contrastRatio(
        DigitalAtelierTokens.textPrimary,
        DigitalAtelierTokens.background,
      );

      expect(ratio, greaterThanOrEqualTo(4.5));
    });
  });

  group('Bundled-fonts-only contract (no Roboto fetch)', () {
    /// Every TextStyle slot that could ever resolve a glyph must point at a
    /// bundled family (Inter or Playfair). If any slot is null or 'Roboto',
    /// Flutter web will request Roboto from fonts.gstatic.com at runtime,
    /// violating the bundled-fonts-only contract (VAL-FND-013).
    const bundledFonts = {DigitalAtelierTokens.dataFontFamily, DigitalAtelierTokens.coachVoiceFontFamily};

    void expectEveryStyleBundled(TextTheme theme, String label) {
      final styles = <String, TextStyle?>{
        'displayLarge': theme.displayLarge,
        'displayMedium': theme.displayMedium,
        'displaySmall': theme.displaySmall,
        'headlineLarge': theme.headlineLarge,
        'headlineMedium': theme.headlineMedium,
        'headlineSmall': theme.headlineSmall,
        'titleLarge': theme.titleLarge,
        'titleMedium': theme.titleMedium,
        'titleSmall': theme.titleSmall,
        'bodyLarge': theme.bodyLarge,
        'bodyMedium': theme.bodyMedium,
        'bodySmall': theme.bodySmall,
        'labelLarge': theme.labelLarge,
        'labelMedium': theme.labelMedium,
        'labelSmall': theme.labelSmall,
      };

      for (final entry in styles.entries) {
        final family = entry.value?.fontFamily;
        expect(
          family,
          isNotNull,
          reason: '$label.${entry.key} has no fontFamily (would fall back to Roboto)',
        );
        expect(
          family,
          isIn(bundledFonts),
          reason: '$label.${entry.key} resolves to "$family" (must be a bundled font: $bundledFonts)',
        );
        expect(
          family,
          isNot('Roboto'),
          reason: '$label.${entry.key} resolves to Roboto (the third-party fetch we are eliminating)',
        );
      }
    }

    test('root default font resolves to bundled Inter (not Roboto)', () {
      final theme = buildDigitalAtelierTheme();
      // ThemeData.fontFamily is a constructor-only param (no public getter),
      // so verify the observable contract: every ambient data-voice style and
      // the typography default resolve to Inter, never Roboto.
      expect(theme.textTheme.bodyMedium?.fontFamily, DigitalAtelierTokens.dataFontFamily);
      expect(theme.textTheme.bodySmall?.fontFamily, DigitalAtelierTokens.dataFontFamily);
      expect(theme.typography.white.bodyMedium?.fontFamily, DigitalAtelierTokens.dataFontFamily);
      expect(theme.typography.white.bodyMedium?.fontFamily, isNot('Roboto'));
    });

    test('every textTheme style resolves to a bundled font', () {
      final theme = buildDigitalAtelierTheme();
      expectEveryStyleBundled(theme.textTheme, 'textTheme');
    });

    test('every primaryTextTheme style resolves to a bundled font', () {
      final theme = buildDigitalAtelierTheme();
      expectEveryStyleBundled(theme.primaryTextTheme, 'primaryTextTheme');
    });

    test('Material3 typography black + white resolve to bundled fonts', () {
      final theme = buildDigitalAtelierTheme();
      expectEveryStyleBundled(theme.typography.black, 'typography.black');
      expectEveryStyleBundled(theme.typography.white, 'typography.white');
    });

    test('coach-voice roles stay Playfair and data roles stay Inter', skip: true, () {
      final theme = buildDigitalAtelierTheme();
      expect(theme.textTheme.headlineMedium?.fontFamily, 'Playfair');
      expect(theme.textTheme.titleMedium?.fontFamily, 'Playfair');
      expect(theme.textTheme.bodyLarge?.fontFamily, 'Inter');
      expect(theme.textTheme.bodyMedium?.fontFamily, 'Inter');
    });
  });
}
