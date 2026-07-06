import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// DigitalAtelierTokens — Original v1 tokens (backward-compatible, unchanged)
// ---------------------------------------------------------------------------

class DigitalAtelierTokens {
  const DigitalAtelierTokens._();

  static const Color background = Color(0xFF0A0A0A);
  static const Color textPrimary = Color(0xFFF0EDE8);
  static const Color accentOrange = Color(0xFFF97316);

  /// Muted red for inline error text (distinct from the accent token so it
  /// does not consume the <=3 accent-uses-per-screen budget).
  static const Color errorText = Color(0xFFE5484D);

  static const String coachVoiceFontFamily = 'Playfair';
  static const String dataFontFamily = 'Inter';

  static const double cornerRadius = 4;
}

// ---------------------------------------------------------------------------
// DigitalAtelierTokens2 — v2 luxury fitness design tokens
// ---------------------------------------------------------------------------

class DigitalAtelierTokens2 {
  const DigitalAtelierTokens2._();

  // -- Surface colors -------------------------------------------------------

  static const Color surface = Color(0xFF111111);
  static const Color surfaceElevated = Color(0xFF1A1A1A);
  static Color surfaceGlass({double opacity = 0.08}) =>
      Colors.white.withValues(alpha: opacity);
  static const Color surfaceBorder = Color(0xFF262626);

  // -- Semantic colors ------------------------------------------------------

  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);
  static const Color calm = Color(0xFF6366F1);
  static const Color recovery = Color(0xFF8B5CF6);

  // -- Gradient presets -----------------------------------------------------

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFFF97316), Color(0xFF8B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient recoveryGradient = LinearGradient(
    colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient progressGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF3B82F6)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // -- Spacing scale --------------------------------------------------------

  static const double s1 = 4;
  static const double s2 = 8;
  static const double s3 = 12;
  static const double s4 = 16;
  static const double s5 = 24;
  static const double s6 = 32;
  static const double s7 = 48;
  static const double s8 = 64;

  // -- Border radius --------------------------------------------------------

  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 24;
  static const double radiusPill = 999;

  // -- Elevation presets with tinted shadows --------------------------------

  static const List<BoxShadow> elevationLow = [
    BoxShadow(
      color: Color(0x1AF97316), // subtle orange tint
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> elevationMedium = [
    BoxShadow(
      color: Color(0x29F97316),
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> elevationHigh = [
    BoxShadow(
      color: Color(0x33F97316),
      blurRadius: 32,
      offset: Offset(0, 8),
    ),
  ];

  // -- Animation durations --------------------------------------------------

  static const Duration durationFast = Duration(milliseconds: 150);
  static const Duration durationNormal = Duration(milliseconds: 300);
  static const Duration durationSlow = Duration(milliseconds: 500);
  static const Duration durationCelebration = Duration(milliseconds: 1500);

  // -- Reusable gradient decorations ----------------------------------------

  static const BoxDecoration heroGradientDecoration = BoxDecoration(
    gradient: heroGradient,
  );

  static const BoxDecoration recoveryGradientDecoration = BoxDecoration(
    gradient: recoveryGradient,
  );

  static const BoxDecoration progressGradientDecoration = BoxDecoration(
    gradient: progressGradient,
  );

  // -- Reusable box decorations ---------------------------------------------

  static BoxDecoration get surfaceDecoration => BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(radiusMd),
        boxShadow: elevationLow,
      );

  static BoxDecoration get elevatedDecoration => BoxDecoration(
        color: surfaceElevated,
        borderRadius: BorderRadius.circular(radiusMd),
        boxShadow: elevationMedium,
      );

  static BoxDecoration get glassDecoration => BoxDecoration(
        color: surfaceGlass(),
        borderRadius: BorderRadius.circular(radiusMd),
        border: Border.all(color: surfaceBorder),
      );

  // -- Text style presets ---------------------------------------------------

  static const TextStyle displayLarge = TextStyle(
    fontFamily: DigitalAtelierTokens.coachVoiceFontFamily,
    color: DigitalAtelierTokens.textPrimary,
    fontSize: 48,
    fontWeight: FontWeight.w700,
    height: 1.1,
    letterSpacing: -1.0,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: DigitalAtelierTokens.coachVoiceFontFamily,
    color: DigitalAtelierTokens.textPrimary,
    fontSize: 36,
    fontWeight: FontWeight.w600,
    height: 1.15,
    letterSpacing: -0.5,
  );

  static const TextStyle headlineLarge = TextStyle(
    fontFamily: DigitalAtelierTokens.coachVoiceFontFamily,
    color: DigitalAtelierTokens.textPrimary,
    fontSize: 28,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamily: DigitalAtelierTokens.coachVoiceFontFamily,
    color: DigitalAtelierTokens.textPrimary,
    fontSize: 22,
    fontWeight: FontWeight.w500,
    height: 1.25,
  );

  static const TextStyle titleLarge = TextStyle(
    fontFamily: DigitalAtelierTokens.dataFontFamily,
    color: DigitalAtelierTokens.textPrimary,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: DigitalAtelierTokens.dataFontFamily,
    color: DigitalAtelierTokens.textPrimary,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: DigitalAtelierTokens.dataFontFamily,
    color: DigitalAtelierTokens.textPrimary,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: DigitalAtelierTokens.dataFontFamily,
    color: DigitalAtelierTokens.textPrimary,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: DigitalAtelierTokens.dataFontFamily,
    color: Color(0xFFA0A0A0),
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );

  static const TextStyle labelLarge = TextStyle(
    fontFamily: DigitalAtelierTokens.dataFontFamily,
    color: DigitalAtelierTokens.textPrimary,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );

  static const TextStyle dataValue = TextStyle(
    fontFamily: DigitalAtelierTokens.dataFontFamily,
    color: DigitalAtelierTokens.textPrimary,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
  );

  static const TextStyle dataLabel = TextStyle(
    fontFamily: DigitalAtelierTokens.dataFontFamily,
    color: Color(0xFFA0A0A0),
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.2,
  );

  /// Accent text style using the primary orange.
  static const TextStyle accent = TextStyle(
    fontFamily: DigitalAtelierTokens.dataFontFamily,
    color: DigitalAtelierTokens.accentOrange,
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );
}

// ---------------------------------------------------------------------------
// ThemeExtension for accessing v2 tokens via Theme.of(context)
// ---------------------------------------------------------------------------

class DigitalAtelierExtension
    extends ThemeExtension<DigitalAtelierExtension> {
  const DigitalAtelierExtension();

  @override
  DigitalAtelierExtension copyWith() => const DigitalAtelierExtension();

  @override
  DigitalAtelierExtension lerp(
    covariant ThemeExtension<DigitalAtelierExtension>? other,
    double t,
  ) {
    // Tokens are constant; no interpolation needed.
    return this;
  }

  // Surface
  Color get surface => DigitalAtelierTokens2.surface;
  Color get surfaceElevated => DigitalAtelierTokens2.surfaceElevated;
  Color surfaceGlass({double opacity = 0.08}) =>
      DigitalAtelierTokens2.surfaceGlass(opacity: opacity);
  Color get surfaceBorder => DigitalAtelierTokens2.surfaceBorder;

  // Semantic
  Color get success => DigitalAtelierTokens2.success;
  Color get warning => DigitalAtelierTokens2.warning;
  Color get info => DigitalAtelierTokens2.info;
  Color get calm => DigitalAtelierTokens2.calm;
  Color get recovery => DigitalAtelierTokens2.recovery;

  // Gradients
  LinearGradient get heroGradient => DigitalAtelierTokens2.heroGradient;
  LinearGradient get recoveryGradient => DigitalAtelierTokens2.recoveryGradient;
  LinearGradient get progressGradient => DigitalAtelierTokens2.progressGradient;

  // Spacing
  double get s1 => DigitalAtelierTokens2.s1;
  double get s2 => DigitalAtelierTokens2.s2;
  double get s3 => DigitalAtelierTokens2.s3;
  double get s4 => DigitalAtelierTokens2.s4;
  double get s5 => DigitalAtelierTokens2.s5;
  double get s6 => DigitalAtelierTokens2.s6;
  double get s7 => DigitalAtelierTokens2.s7;
  double get s8 => DigitalAtelierTokens2.s8;

  // Radius
  double get radiusSm => DigitalAtelierTokens2.radiusSm;
  double get radiusMd => DigitalAtelierTokens2.radiusMd;
  double get radiusLg => DigitalAtelierTokens2.radiusLg;
  double get radiusXl => DigitalAtelierTokens2.radiusXl;
  double get radiusPill => DigitalAtelierTokens2.radiusPill;

  // Elevation
  List<BoxShadow> get elevationLow => DigitalAtelierTokens2.elevationLow;
  List<BoxShadow> get elevationMedium => DigitalAtelierTokens2.elevationMedium;
  List<BoxShadow> get elevationHigh => DigitalAtelierTokens2.elevationHigh;

  // Animation
  Duration get durationFast => DigitalAtelierTokens2.durationFast;
  Duration get durationNormal => DigitalAtelierTokens2.durationNormal;
  Duration get durationSlow => DigitalAtelierTokens2.durationSlow;
  Duration get durationCelebration => DigitalAtelierTokens2.durationCelebration;

  // Decorations
  BoxDecoration get surfaceDecoration => DigitalAtelierTokens2.surfaceDecoration;
  BoxDecoration get elevatedDecoration =>
      DigitalAtelierTokens2.elevatedDecoration;
  BoxDecoration get glassDecoration => DigitalAtelierTokens2.glassDecoration;

  // Text styles
  TextStyle get displayLarge => DigitalAtelierTokens2.displayLarge;
  TextStyle get displayMedium => DigitalAtelierTokens2.displayMedium;
  TextStyle get headlineLarge => DigitalAtelierTokens2.headlineLarge;
  TextStyle get headlineMedium => DigitalAtelierTokens2.headlineMedium;
  TextStyle get titleLarge => DigitalAtelierTokens2.titleLarge;
  TextStyle get titleMedium => DigitalAtelierTokens2.titleMedium;
  TextStyle get bodyLarge => DigitalAtelierTokens2.bodyLarge;
  TextStyle get bodyMedium => DigitalAtelierTokens2.bodyMedium;
  TextStyle get bodySmall => DigitalAtelierTokens2.bodySmall;
  TextStyle get labelLarge => DigitalAtelierTokens2.labelLarge;
  TextStyle get dataValue => DigitalAtelierTokens2.dataValue;
  TextStyle get dataLabel => DigitalAtelierTokens2.dataLabel;
  TextStyle get accent => DigitalAtelierTokens2.accent;
}

// ---------------------------------------------------------------------------
// Private helpers (unchanged from v1)
// ---------------------------------------------------------------------------

/// Applies [fontFamily] to every non-null [TextStyle] in a [TextTheme], so no
/// style can ever fall back to the Material default (Roboto) on Flutter web.
TextTheme _applyFontFamily(TextTheme theme, String fontFamily) {
  TextStyle? withFont(TextStyle? style) =>
      style?.copyWith(fontFamily: fontFamily);

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
/// applied to both the black and white text themes.
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

// ---------------------------------------------------------------------------
// buildDigitalAtelierTheme — updated to include v2 extension
// ---------------------------------------------------------------------------

ThemeData buildDigitalAtelierTheme() {
  final shape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(DigitalAtelierTokens.cornerRadius),
  );

  const colorScheme = ColorScheme.dark(
    surface: DigitalAtelierTokens.background,
    onSurface: DigitalAtelierTokens.textPrimary,
    primary: DigitalAtelierTokens.accentOrange,
    onPrimary: DigitalAtelierTokens.background,
    secondary: DigitalAtelierTokens.accentOrange,
  );

  final interTypography =
      _bundledTypography(DigitalAtelierTokens.dataFontFamily);
  final baseWhite = interTypography.white;

  final textTheme =
      _applyFontFamily(baseWhite, DigitalAtelierTokens.dataFontFamily).copyWith(
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
    extensions: const [
      DigitalAtelierExtension(),
    ],
    cardTheme: CardThemeData(
      color: const Color(0xFF0A0A0A),
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
        borderRadius:
            BorderRadius.circular(DigitalAtelierTokens.cornerRadius),
        borderSide: const BorderSide(color: Color(0xFFF97316)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(DigitalAtelierTokens.cornerRadius),
        borderSide: const BorderSide(color: Color(0xFFF97316)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(DigitalAtelierTokens.cornerRadius),
        borderSide:
            const BorderSide(color: Color(0xFFF97316), width: 1.2),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Convenience extension on BuildContext for quick access
// ---------------------------------------------------------------------------

extension DigitalAtelierContext on BuildContext {
  /// Access v2 tokens via `context.atelier`.
  DigitalAtelierExtension get atelier =>
      Theme.of(this).extension<DigitalAtelierExtension>()!;
}
