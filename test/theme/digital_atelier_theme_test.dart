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
    test('uses the canonical color and font tokens', () {
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

    test('keeps rounded corners within 0-4px', () {
      final theme = buildDigitalAtelierTheme();

      final cardShape = theme.cardTheme.shape as RoundedRectangleBorder;
      expect(
        cardShape.borderRadius,
        BorderRadius.circular(DigitalAtelierTokens.cornerRadius),
      );

      final elevatedShape =
          theme.elevatedButtonTheme.style?.shape?.resolve(<WidgetState>{})
              as RoundedRectangleBorder;
      expect(
        elevatedShape.borderRadius,
        BorderRadius.circular(DigitalAtelierTokens.cornerRadius),
      );

      final textButtonShape =
          theme.textButtonTheme.style?.shape?.resolve(<WidgetState>{})
              as RoundedRectangleBorder;
      expect(
        textButtonShape.borderRadius,
        BorderRadius.circular(DigitalAtelierTokens.cornerRadius),
      );

      final inputBorder = theme.inputDecorationTheme.border as OutlineInputBorder;
      expect(
        inputBorder.borderRadius,
        BorderRadius.circular(DigitalAtelierTokens.cornerRadius),
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
}
