import 'package:flutter/material.dart';

class DigitalAtelierTokens {
  const DigitalAtelierTokens._();

  static const Color background = Color(0xFF0A0A0A);
  static const Color textPrimary = Color(0xFFF0EDE8);
  static const Color accentOrange = Color(0xFFF97316);

  static const String coachVoiceFontFamily = 'Playfair';
  static const String dataFontFamily = 'Inter';

  static const double cornerRadius = 4;
}

/// Applies [fontFamily] to every non-null [TextStyle] in a [TextTheme], so no
/// style can ever fall back to the Material default (Roboto) on Flutter web.
///
/// The Material 3 default typography (`Typography.material2021`) is built on
/// Roboto. If even one style is left without an explicit bundled family, the
/// web engine requests Roboto from fonts.gstatic.com at runtime. This helper
/// guarantees every slot resolves to a bundled font (Inter for data, Playfair
/// for coach voice).
TextTheme _applyFontFamily(TextTheme theme, String fontFamily) {
  TextStyle? withFont(TextStyle? style) => style?.copyWith(fontFamily: fontFamily);

  return TextTheme(
    displayLarge: withFont(theme.displayLarge),
    displayMedium: withFont(theme.displayMedium),
    displaySmall: withFont(theme.displaySmall),
    headlineLarge: withFont(theme.headlineLarge),
    headlineMedium: withFont(theme.headlineMedium),
    headlineSmall: withFont(theme.headlineSmall),
    titleLarge: withFont(theme.titleLarge),
    titleMedium: withFont(theme.titleMedium),
    titleSmall: withFont(theme.titleSmall),
    bodyLarge: withFont(theme.bodyLarge),
    bodyMedium: withFont(theme.bodyMedium),
    bodySmall: withFont(theme.bodySmall),
    labelLarge: withFont(theme.labelLarge),
    labelMedium: withFont(theme.labelMedium),
    labelSmall: withFont(theme.labelSmall),
  );
}

/// Builds the full Material 3 [Typography] with the bundled data font (Inter)
/// applied to both the black and white text themes, so any widget reading
/// `Theme.of(context).typography` (the Material 3 typography path) resolves to
/// Inter rather than the Roboto default.
Typography _bundledTypography(String dataFont) {
  final base = Typography.material2021();
  return Typography(
    black: _applyFontFamily(base.black, dataFont),
    white: _applyFontFamily(base.white, dataFont),
    englishLike: _applyFontFamily(base.englishLike, dataFont),
    dense: _applyFontFamily(base.dense, dataFont),
    tall: _applyFontFamily(base.tall, dataFont),
  );
}

ThemeData buildDigitalAtelierTheme() {
  final shape =
      RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DigitalAtelierTokens.cornerRadius),
      );

  const colorScheme = ColorScheme.dark(
    surface: DigitalAtelierTokens.background,
    onSurface: DigitalAtelierTokens.textPrimary,
    primary: DigitalAtelierTokens.accentOrange,
    onPrimary: DigitalAtelierTokens.background,
    secondary: DigitalAtelierTokens.accentOrange,
  );

  // Start from the full Material 3 typography with Inter applied to every
  // style (no Roboto anywhere), then craft the coach-voice (Playfair) and
  // data-voice (Inter) roles on top. Every TextTheme slot keeps an explicit
  // bundled fontFamily so no glyph can fall back to Roboto.
  final interTypography = _bundledTypography(DigitalAtelierTokens.dataFontFamily);
  final baseWhite = interTypography.white;

  final textTheme = _applyFontFamily(baseWhite, DigitalAtelierTokens.dataFontFamily).copyWith(
    headlineMedium: TextStyle(
      fontFamily: DigitalAtelierTokens.coachVoiceFontFamily,
      color: DigitalAtelierTokens.textPrimary,
      fontSize: 40,
      fontWeight: FontWeight.w600,
      height: 1.1,
    ),
    titleMedium: TextStyle(
      fontFamily: DigitalAtelierTokens.coachVoiceFontFamily,
      color: DigitalAtelierTokens.textPrimary,
      fontSize: 22,
      fontWeight: FontWeight.w500,
    ),
    bodyLarge: TextStyle(
      fontFamily: DigitalAtelierTokens.dataFontFamily,
      color: DigitalAtelierTokens.textPrimary,
      fontSize: 16,
      height: 1.4,
    ),
    bodyMedium: TextStyle(
      fontFamily: DigitalAtelierTokens.dataFontFamily,
      color: DigitalAtelierTokens.textPrimary,
      fontSize: 14,
      height: 1.4,
    ),
  );

  // primaryTextTheme drives widgets like AppBar titles; keep it Inter-based
  // (data role) with the same full coverage so it never resolves to Roboto.
  final primaryTextTheme = _applyFontFamily(
    baseWhite,
    DigitalAtelierTokens.dataFontFamily,
  );

  return ThemeData(
    brightness: Brightness.dark,
    fontFamily: DigitalAtelierTokens.dataFontFamily,
    typography: interTypography,
    scaffoldBackgroundColor: DigitalAtelierTokens.background,
    colorScheme: colorScheme,
    textTheme: textTheme,
    primaryTextTheme: primaryTextTheme,
    useMaterial3: true,
    cardTheme: CardThemeData(
      color: Color(0xFF0A0A0A),
      margin: EdgeInsets.zero,
      shape: shape,
      surfaceTintColor: Colors.transparent,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: DigitalAtelierTokens.accentOrange,
        foregroundColor: DigitalAtelierTokens.background,
        shape: shape,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: DigitalAtelierTokens.textPrimary,
        shape: shape,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF151515),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DigitalAtelierTokens.cornerRadius),
        borderSide: const BorderSide(color: Color(0xFFF97316)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DigitalAtelierTokens.cornerRadius),
        borderSide: const BorderSide(color: Color(0xFFF97316)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DigitalAtelierTokens.cornerRadius),
        borderSide: const BorderSide(color: Color(0xFFF97316), width: 1.2),
      ),
    ),
  );
}
