import 'package:flutter/material.dart';
import 'package:transformfit/theme/mathematical_design.dart';

// ============================================================================
// TransformFit Design System — "Digital Atelier"
//
// Production-grade design tokens inspired by MacroFactor, Ladder, and Whoop.
//
// Architecture:
//   - DigitalAtelierTokens  — v1 backward-compat (unchanged)
//   - DigitalAtelierTokens2 — v2 backward-compat (unchanged)
//   - DigitalAtelierExtension — v3 production ThemeExtension (primary API)
//
// Usage:
//   final t = Theme.of(context).extension<DigitalAtelierExtension>()!;
//   Text('Hello', style: t.textTheme.h1);
// ============================================================================

// ---------------------------------------------------------------------------
// DigitalAtelierTokens — Original v1 tokens (backward-compatible, unchanged)
// ---------------------------------------------------------------------------

class DigitalAtelierTokens {
  const DigitalAtelierTokens._();

  static const Color background = Color(0xFF0A0A0A);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color accentOrange = Color(0xFFFF6B35);

  /// Muted red for inline error text (distinct from the accent token so it
  /// does not consume the <=3 accent-uses-per-screen budget).
  static const Color errorText = Color(0xFFE5484D);

  static const String coachVoiceFontFamily = 'Playfair';
  static const String dataFontFamily = 'Inter';

  static const double cornerRadius = 4;
}

// ---------------------------------------------------------------------------
// DigitalAtelierTokens2 — v2 luxury fitness design tokens
// (backward-compatible, unchanged — existing code references these statics)
// ---------------------------------------------------------------------------

class DigitalAtelierTokens2 {
  const DigitalAtelierTokens2._();

  // -- Surface colors -------------------------------------------------------

  static const Color surface = Color(0xFF141414);
  static const Color surfaceElevated = Color(0xFF1C1C1C);
  static Color surfaceGlass({double opacity = 0.08}) =>
      Colors.white.withValues(alpha: opacity);
  static const Color surfaceBorder = Color(0xFF1E1E1E);

  // -- Semantic colors ------------------------------------------------------

  static const Color success = Color(0xFF30D158);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);
  static const Color calm = Color(0xFF6366F1);
  static const Color recovery = Color(0xFF8B5CF6);

  // -- Gradient presets -----------------------------------------------------

  // Gradient presets removed in v3.0 Obsidian Forge.
  // -- Spacing scale --------------------------------------------------------

  static const double s1 = MathematicalDesign.spaceXs;   // 3px (fib)
  static const double s2 = MathematicalDesign.spaceMd;   // 8px (fib)
  static const double s3 = MathematicalDesign.spaceLg;   // 13px (fib)
  static const double s4 = MathematicalDesign.textMd;    // 16px (base)
  static const double s5 = MathematicalDesign.spaceXl;   // 21px (fib)
  static const double s6 = MathematicalDesign.space2xl;  // 34px (fib)
  static const double s7 = MathematicalDesign.text2xl;   // 34px (fib)
  static const double s8 = MathematicalDesign.space3xl;  // 55px (fib)

  // -- Border radius --------------------------------------------------------

  static const double radiusSm = MathematicalDesign.radiusSm;   // 3px (fib)
  static const double radiusMd = MathematicalDesign.radiusMd;   // 5px (fib)
  static const double radiusLg = MathematicalDesign.radiusLg;   // 8px (fib)
  static const double radiusXl = MathematicalDesign.radiusXl;   // 13px (fib)
  static const double radiusPill = MathematicalDesign.radiusPill; // 21px (fib)

  // -- Elevation presets with tinted shadows --------------------------------

  static const List<BoxShadow> elevationLow = [
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> elevationMedium = [
    BoxShadow(
      color: Color(0x1F000000),
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> elevationHigh = [
    BoxShadow(
      color: Color(0x29000000),
      blurRadius: 32,
      offset: Offset(0, 8),
    ),
  ];

  // -- Animation durations --------------------------------------------------

  static const Duration durationFast = MathematicalDesign.animFast;           // 100ms (fib)
  static const Duration durationNormal = MathematicalDesign.animNormal;       // 200ms (fib)
  static const Duration durationSlow = MathematicalDesign.animSlow;           // 500ms (fib)
  static const Duration durationCelebration = MathematicalDesign.animCelebration; // 1300ms (fib)

  // -- Reusable gradient decorations ----------------------------------------

  // Gradient decorations removed in v3.0 Obsidian Forge.

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
    fontFamily: DigitalAtelierTokens.dataFontFamily,
    color: Color(0xFFFFFFFF),
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: DigitalAtelierTokens.dataFontFamily,
    color: Color(0xFFFFFFFF),
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );

  static const TextStyle headlineLarge = TextStyle(
    fontFamily: DigitalAtelierTokens.dataFontFamily,
    color: Color(0xFFFFFFFF),
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamily: DigitalAtelierTokens.dataFontFamily,
    color: Color(0xFFFFFFFF),
    fontSize: 18,
    fontWeight: FontWeight.w500,
    height: 1.3,
  );

  static const TextStyle titleLarge = TextStyle(
    fontFamily: DigitalAtelierTokens.dataFontFamily,
    color: Color(0xFFFFFFFF),
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: DigitalAtelierTokens.dataFontFamily,
    color: Color(0xFFFFFFFF),
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: DigitalAtelierTokens.dataFontFamily,
    color: Color(0xFFFFFFFF),
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: DigitalAtelierTokens.dataFontFamily,
    color: Color(0xFFFFFFFF),
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
    color: Color(0xFFFFFFFF),
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );

  static const TextStyle dataValue = TextStyle(
    fontFamily: DigitalAtelierTokens.dataFontFamily,
    color: Color(0xFFFFFFFF),
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
    color: Color(0xFFFF6B35),
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );
}

// ============================================================================
// DigitalAtelierExtension — v3 production ThemeExtension
//
// Primary API for all design tokens. Access via:
//   Theme.of(context).extension<DigitalAtelierExtension>()!
//
// Every color, spacing, radius, animation, decoration, and text style is
// a named token — zero hardcoded Color(0xFF...) values.
// ============================================================================

class DigitalAtelierExtension
    extends ThemeExtension<DigitalAtelierExtension> {
  const DigitalAtelierExtension({
    // -- Background & Surface -----------------------------------------------
    required this.background,
    required this.surface,
    required this.surfaceElevated,
    required this.surfaceInput,
    required this.surfaceBorder,
    required this.surfaceDivider,
    // -- Accent Colors ------------------------------------------------------
    required this.accentPrimary,
    required this.accentSecondary,
    required this.accentTertiary,
    required this.accentDanger,
    required this.accentInfo,
    // -- Text Colors --------------------------------------------------------
    required this.textPrimary,
    // -- Deep Canvas (bottom nav) -------------------------------------------
    required this.canvasDeep,
    required this.textSecondary,
    required this.textMuted,
    required this.textInverse,
    // -- Semantic Colors (legacy compat) ------------------------------------
    required this.success,
    required this.warning,
    required this.recovery,
    required this.calm,
    // -- Spacing ------------------------------------------------------------
    required this.spaceXs,
    required this.spaceSm,
    required this.spaceMd,
    required this.spaceLg,
    required this.spaceXl,
    required this.spaceXxl,
    required this.spaceXxxl,
    required this.spaceHuge,
    // -- Border Radius ------------------------------------------------------
    required this.radiusSm,
    required this.radiusMd,
    required this.radiusLg,
    required this.radiusXl,
    required this.radiusPill,
    // -- Animation ----------------------------------------------------------
    required this.durationFast,
    required this.durationNormal,
    required this.durationSlow,
    required this.durationCelebration,
    required this.curveDefault,
    required this.curveBounce,
    required this.curveSlide,
  });

  // =========================================================================
  // Default constructor — the canonical production palette
  // =========================================================================

  factory DigitalAtelierExtension.standard() => const DigitalAtelierExtension(
        // Background & Surface
        background: Color(0xFF0A0A0A),
        surface: Color(0xFF141414),
        surfaceElevated: Color(0xFF1C1C1C),
        surfaceInput: Color(0xFF1C1C1C),
        surfaceBorder: Color(0xFF1E1E1E),
        surfaceDivider: Color(0xFF252525),
        // Accent Colors
        accentPrimary: Color(0xFFFF6B35),
        accentSecondary: Color(0xFF8B5CF6),
        accentTertiary: Color(0xFF30D158),
        accentDanger: Color(0xFFEF4444),
        accentInfo: Color(0xFF3B82F6),
        // Text Colors
        textPrimary: Color(0xFFFFFFFF),
        canvasDeep: Color(0xFF050505),
        textSecondary: Color(0xFF8E8E93),
        textMuted: Color(0xFF48484A),
        textInverse: Color(0xFF0A0A0A),
        // Semantic Colors
        success: Color(0xFF30D158),
        warning: Color(0xFFF59E0B),
        recovery: Color(0xFF8B5CF6),
        calm: Color(0xFF6366F1),
        // DEVIATION ENGINE 34: Fine-Tuning — Fibonacci spacing
        // Previous: 4, 8, 12, 16, 24, 32, 48, 64 (arbitrary 4px base)
        // Now:      3, 5, 8, 13, 21, 34, 55, 89 (Fibonacci F(4)–F(11))
        spaceXs: MathematicalDesign.spaceXs,   // 3  (F4)
        spaceSm: MathematicalDesign.spaceSm,   // 5  (F5)
        spaceMd: MathematicalDesign.spaceMd,   // 8  (F6)
        spaceLg: MathematicalDesign.spaceLg,   // 13 (F7)
        spaceXl: MathematicalDesign.spaceXl,   // 21 (F8)
        spaceXxl: MathematicalDesign.space2xl, // 34 (F9)
        spaceXxxl: MathematicalDesign.space3xl, // 55 (F10)
        spaceHuge: MathematicalDesign.space4xl, // 89 (F11)
        // DEVIATION ENGINE 34: Fine-Tuning — Fibonacci radii
        radiusSm: MathematicalDesign.radiusSm,     // 3  (F4)
        radiusMd: MathematicalDesign.radiusMd,     // 5  (F5)
        radiusLg: MathematicalDesign.radiusLg,     // 8  (F6)
        radiusXl: MathematicalDesign.radiusXl,     // 13 (F7)
        radiusPill: MathematicalDesign.radiusCircle, // 999 (fully round)
        // DEVIATION ENGINE 36: Speed of Light — Fibonacci animation durations
        // Small → fast, large → slow (physical law)
        durationFast: MathematicalDesign.animFast,           // 100ms (F5 micro)
        durationNormal: MathematicalDesign.animNormal,       // 200ms (F6 standard)
        durationSlow: MathematicalDesign.animSlow,           // 500ms (F7 emphasis)
        durationCelebration: MathematicalDesign.animCelebration, // 1300ms (F8 celebration)
        // DEVIATION ENGINE 37: Absolute Zero — meaningful easing only
        curveDefault: Curves.easeOutCubic,   // deceleration (arrival)
        curveBounce: Curves.elasticOut,      // spring (celebration only)
        curveSlide: Curves.easeOutQuart,     // smooth slide (transitions)
      );

  // -- Background & Surface -------------------------------------------------
  final Color background;
  final Color surface;
  final Color surfaceElevated;
  final Color surfaceInput;
  final Color surfaceBorder;
  final Color surfaceDivider;

  // -- Accent Colors --------------------------------------------------------
  final Color accentPrimary;
  final Color accentSecondary;
  final Color accentTertiary;
  final Color accentDanger;
  final Color accentInfo;

  // -- Text Colors ----------------------------------------------------------
  final Color textPrimary;
  // -- Deep Canvas ----------------------------------------------------------
  final Color canvasDeep;
  final Color textSecondary;
  final Color textMuted;
  final Color textInverse;

  // -- Semantic Colors (backward compat with v2 getters) --------------------
  final Color success;
  final Color warning;
  final Color recovery;
  final Color calm;

  // -- Spacing (4px base) ---------------------------------------------------
  final double spaceXs;
  final double spaceSm;
  final double spaceMd;
  final double spaceLg;
  final double spaceXl;
  final double spaceXxl;
  final double spaceXxxl;
  final double spaceHuge;

  // -- Border Radius --------------------------------------------------------
  final double radiusSm;
  final double radiusMd;
  final double radiusLg;
  final double radiusXl;
  final double radiusPill;

  // -- Animation Tokens -----------------------------------------------------
  final Duration durationFast;
  final Duration durationNormal;
  final Duration durationSlow;
  final Duration durationCelebration;
  final Curve curveDefault;
  final Curve curveBounce;
  final Curve curveSlide;

  // =========================================================================
  // Layout Spacing Constants (Golden Ratio / Fibonacci)
  //
  // DEVIATION ENGINE 33: Casimir Pressure — constrained whitespace creates
  // measurable visual force. The screen margin (21px) is deliberately tight
  // to create tension; the section gap (34px) is deliberately large to draw
  // the eye to the hero element.
  //
  // DEVIATION ENGINE 34: Fine-Tuning — every value is a Fibonacci number.
  // No arbitrary values. The mathematical foundation ensures visual harmony.
  // =========================================================================

  static const double screenMargin = 20.0;
  static const double cardGap = 12.0;
  static const double sectionGap = 32.0;

  // =========================================================================
  // Golden Ratio Layout Helpers
  // =========================================================================

  /// Major section proportion (61.8%) for Golden Ratio layouts.
  static const double goldenMajor = MathematicalDesign.goldenMajor;

  /// Minor section proportion (38.2%) for Golden Ratio layouts.
  static const double goldenMinor = MathematicalDesign.goldenMinor;

  /// Returns the major portion (61.8%) of [total].
  static double goldenMajorOf(double total) =>
      MathematicalDesign.goldenMajorOf(total);

  /// Returns the minor portion (38.2%) of [total].
  static double goldenMinorOf(double total) =>
      MathematicalDesign.goldenMinorOf(total);

  /// Major section proportion (2/3) for Rule of Thirds layouts.
  static const double thirdMajor = MathematicalDesign.thirdMajor;

  /// Minor section proportion (1/3) for Rule of Thirds layouts.
  static const double thirdMinor = MathematicalDesign.thirdMinor;

  /// Returns the major third (2/3) of [total].
  static double thirdMajorOf(double total) =>
      MathematicalDesign.thirdMajorOf(total);

  /// Returns the minor third (1/3) of [total].
  static double thirdMinorOf(double total) =>
      MathematicalDesign.thirdMinorOf(total);

  // =========================================================================
  // Font families
  // =========================================================================

  static const String coachVoiceFontFamily = 'Playfair';
  static const String dataFontFamily = 'Inter';

  // =========================================================================
  // Typography Scale — MacroFactor-quality data typography
  // =========================================================================

  /// Creates a [TransformFitTextTheme] scaled by the given factor.
  /// Use with MediaQuery.textScaleFactor for Dynamic Type support.
  TransformFitTextTheme textThemeWithScale(double scale) =>
      TransformFitTextTheme(scale: scale);

  /// Default text theme (scale 1.0). Access via `t.textTheme`.
  TransformFitTextTheme get textTheme => const TransformFitTextTheme();

  // =========================================================================
  // Surface Glass — backward-compat helper
  // =========================================================================

  Color surfaceGlass({double opacity = 0.08}) =>
      Colors.white.withValues(alpha: opacity);

  // =========================================================================
  // Component Presets — pre-built BoxDecoration
  // =========================================================================

  /// Standard card: surface bg, md radius, no border.
  BoxDecoration get cardDecoration => BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(radiusMd),
      );

  /// Elevated card: surfaceElevated bg, md radius, no border.
  BoxDecoration get cardElevated => BoxDecoration(
        color: surfaceElevated,
        borderRadius: BorderRadius.circular(radiusMd),
      );

  /// Input field: surfaceInput bg, sm radius, surfaceBorder.
  BoxDecoration get inputDecoration => BoxDecoration(
        color: surfaceInput,
        borderRadius: BorderRadius.circular(radiusSm),
        border: Border.all(color: surfaceBorder, width: 1),
      );

  /// Chip/tag: surface bg, pill radius, surfaceBorder.
  BoxDecoration get chipDecoration => BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(radiusPill),
        border: Border.all(color: surfaceBorder, width: 1),
      );

  /// Modal bottom sheet: surfaceElevated bg, lg radius, shadow.
  BoxDecoration get modalDecoration => BoxDecoration(
        color: surfaceElevated,
        borderRadius: BorderRadius.circular(radiusLg),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F000000),
            blurRadius: 32,
            offset: Offset(0, -4),
          ),
        ],
      );

  // =========================================================================
  // Gradient Presets
  // =========================================================================

  // gradientHero removed in v3.0 Obsidian Forge.

  // gradientProgress removed in v3.0 Obsidian Forge.

  // gradientRecovery removed in v3.0 Obsidian Forge.

  // =========================================================================
  // Elevation / Shadows — subtle, tinted
  // =========================================================================

  /// No shadow — cards use border only.
  List<BoxShadow> get elevationNone => const [];

  /// Modal shadow — neutral dark.
  List<BoxShadow> get elevationModal => const [
        BoxShadow(
          color: Color(0x1F000000),
          blurRadius: 32,
          offset: Offset(0, -4),
        ),
      ];

  /// FAB shadow — neutral dark.
  List<BoxShadow> get elevationFab => const [
        BoxShadow(
          color: Color(0x29000000),
          blurRadius: 24,
          offset: Offset(0, 8),
        ),
      ];

  // =========================================================================
  // Legacy v2 decoration getters (backward compat)
  // =========================================================================

  BoxDecoration get surfaceDecoration => BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(radiusMd),
      );

  BoxDecoration get elevatedDecoration => BoxDecoration(
        color: surfaceElevated,
        borderRadius: BorderRadius.circular(radiusMd),
      );

  BoxDecoration get glassDecoration => BoxDecoration(
        color: surfaceGlass(),
        borderRadius: BorderRadius.circular(radiusMd),
        border: Border.all(color: surfaceBorder),
      );

  // =========================================================================
  // Legacy v2 gradient getters (backward compat)
  // =========================================================================

  // Legacy gradient getters removed in v3.0 Obsidian Forge.

  // =========================================================================
  // Legacy v2 spacing getters (backward compat)
  // =========================================================================

  double get s1 => spaceXs;
  double get s2 => spaceSm;
  double get s3 => spaceMd;
  double get s4 => spaceLg;
  double get s5 => spaceXl;
  double get s6 => spaceXxl;
  double get s7 => spaceXxxl;
  double get s8 => spaceHuge;

  // =========================================================================
  // Legacy v2 text style getters (backward compat)
  // =========================================================================

  TextStyle get displayLarge => textTheme.display;
  TextStyle get displayMedium => textTheme.display.copyWith(fontSize: 36);
  TextStyle get headlineLarge => textTheme.h1;
  TextStyle get headlineMedium => textTheme.h2;
  TextStyle get titleLarge => textTheme.h3;
  TextStyle get titleMedium => textTheme.body;
  TextStyle get bodyLarge => textTheme.body;
  TextStyle get bodyMedium => textTheme.bodySmall;
  TextStyle get bodySmall => textTheme.caption;
  TextStyle get labelLarge =>
      textTheme.body.copyWith(fontWeight: FontWeight.w600);
  TextStyle get dataValue => textTheme.dataLarge;
  TextStyle get dataLabel => textTheme.caption;
  TextStyle get accent =>
      textTheme.body.copyWith(color: accentPrimary, fontWeight: FontWeight.w600);

  // =========================================================================
  // Reduced Motion Support
  //
  // Critical for App Store accessibility review. Returns a Duration
  // appropriate for the current motion preference.
  // =========================================================================

  /// Returns [duration] when animations are enabled, [Duration.zero] otherwise.
  /// Use this for all animated transitions:
  ///   AnimatedContainer(duration: t.resolvedDuration(t.durationNormal, context))
  Duration resolvedDuration(Duration duration, BuildContext context) {
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return disableAnimations ? Duration.zero : duration;
  }

  /// Returns the curve when animations are enabled, [Curves.linear] otherwise.
  Curve resolvedCurve(Curve curve, BuildContext context) {
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return disableAnimations ? Curves.linear : curve;
  }

  // staticHeroDecoration removed in v3.0 Obsidian Forge.

  // staticProgressDecoration removed in v3.0 Obsidian Forge.

  // staticRecoveryDecoration removed in v3.0 Obsidian Forge.

  // =========================================================================
  // ThemeExtension — copyWith
  // =========================================================================

  @override
  DigitalAtelierExtension copyWith({
    Color? background,
    Color? surface,
    Color? surfaceElevated,
    Color? surfaceInput,
    Color? surfaceBorder,
    Color? surfaceDivider,
    Color? accentPrimary,
    Color? accentSecondary,
    Color? accentTertiary,
    Color? accentDanger,
    Color? accentInfo,
    Color? textPrimary,
    Color? canvasDeep,
    Color? textSecondary,
    Color? textMuted,
    Color? textInverse,
    Color? success,
    Color? warning,
    Color? recovery,
    Color? calm,
    double? spaceXs,
    double? spaceSm,
    double? spaceMd,
    double? spaceLg,
    double? spaceXl,
    double? spaceXxl,
    double? spaceXxxl,
    double? spaceHuge,
    double? radiusSm,
    double? radiusMd,
    double? radiusLg,
    double? radiusXl,
    double? radiusPill,
    Duration? durationFast,
    Duration? durationNormal,
    Duration? durationSlow,
    Duration? durationCelebration,
    Curve? curveDefault,
    Curve? curveBounce,
    Curve? curveSlide,
  }) {
    return DigitalAtelierExtension(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      surfaceInput: surfaceInput ?? this.surfaceInput,
      surfaceBorder: surfaceBorder ?? this.surfaceBorder,
      surfaceDivider: surfaceDivider ?? this.surfaceDivider,
      accentPrimary: accentPrimary ?? this.accentPrimary,
      accentSecondary: accentSecondary ?? this.accentSecondary,
      accentTertiary: accentTertiary ?? this.accentTertiary,
      accentDanger: accentDanger ?? this.accentDanger,
      accentInfo: accentInfo ?? this.accentInfo,
      textPrimary: textPrimary ?? this.textPrimary,
      canvasDeep: canvasDeep ?? this.canvasDeep,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      textInverse: textInverse ?? this.textInverse,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      recovery: recovery ?? this.recovery,
      calm: calm ?? this.calm,
      spaceXs: spaceXs ?? this.spaceXs,
      spaceSm: spaceSm ?? this.spaceSm,
      spaceMd: spaceMd ?? this.spaceMd,
      spaceLg: spaceLg ?? this.spaceLg,
      spaceXl: spaceXl ?? this.spaceXl,
      spaceXxl: spaceXxl ?? this.spaceXxl,
      spaceXxxl: spaceXxxl ?? this.spaceXxxl,
      spaceHuge: spaceHuge ?? this.spaceHuge,
      radiusSm: radiusSm ?? this.radiusSm,
      radiusMd: radiusMd ?? this.radiusMd,
      radiusLg: radiusLg ?? this.radiusLg,
      radiusXl: radiusXl ?? this.radiusXl,
      radiusPill: radiusPill ?? this.radiusPill,
      durationFast: durationFast ?? this.durationFast,
      durationNormal: durationNormal ?? this.durationNormal,
      durationSlow: durationSlow ?? this.durationSlow,
      durationCelebration: durationCelebration ?? this.durationCelebration,
      curveDefault: curveDefault ?? this.curveDefault,
      curveBounce: curveBounce ?? this.curveBounce,
      curveSlide: curveSlide ?? this.curveSlide,
    );
  }

  // =========================================================================
  // ThemeExtension — lerp (smooth theme transitions)
  // =========================================================================

  @override
  DigitalAtelierExtension lerp(
    covariant ThemeExtension<DigitalAtelierExtension>? other,
    double t,
  ) {
    if (other is! DigitalAtelierExtension) return this;
    return DigitalAtelierExtension(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceElevated:
          Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      surfaceInput: Color.lerp(surfaceInput, other.surfaceInput, t)!,
      surfaceBorder: Color.lerp(surfaceBorder, other.surfaceBorder, t)!,
      surfaceDivider: Color.lerp(surfaceDivider, other.surfaceDivider, t)!,
      accentPrimary: Color.lerp(accentPrimary, other.accentPrimary, t)!,
      accentSecondary:
          Color.lerp(accentSecondary, other.accentSecondary, t)!,
      accentTertiary:
          Color.lerp(accentTertiary, other.accentTertiary, t)!,
      accentDanger: Color.lerp(accentDanger, other.accentDanger, t)!,
      accentInfo: Color.lerp(accentInfo, other.accentInfo, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      canvasDeep: Color.lerp(canvasDeep, other.canvasDeep, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      textInverse: Color.lerp(textInverse, other.textInverse, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      recovery: Color.lerp(recovery, other.recovery, t)!,
      calm: Color.lerp(calm, other.calm, t)!,
      spaceXs: spaceXs + (other.spaceXs - spaceXs) * t,
      spaceSm: spaceSm + (other.spaceSm - spaceSm) * t,
      spaceMd: spaceMd + (other.spaceMd - spaceMd) * t,
      spaceLg: spaceLg + (other.spaceLg - spaceLg) * t,
      spaceXl: spaceXl + (other.spaceXl - spaceXl) * t,
      spaceXxl: spaceXxl + (other.spaceXxl - spaceXxl) * t,
      spaceXxxl: spaceXxxl + (other.spaceXxxl - spaceXxxl) * t,
      spaceHuge: spaceHuge + (other.spaceHuge - spaceHuge) * t,
      radiusSm: radiusSm + (other.radiusSm - radiusSm) * t,
      radiusMd: radiusMd + (other.radiusMd - radiusMd) * t,
      radiusLg: radiusLg + (other.radiusLg - radiusLg) * t,
      radiusXl: radiusXl + (other.radiusXl - radiusXl) * t,
      radiusPill: radiusPill + (other.radiusPill - radiusPill) * t,
      durationFast: lerpDuration(durationFast, other.durationFast, t),
      durationNormal: lerpDuration(durationNormal, other.durationNormal, t),
      durationSlow: lerpDuration(durationSlow, other.durationSlow, t),
      durationCelebration:
          lerpDuration(durationCelebration, other.durationCelebration, t),
      curveDefault: t < 0.5 ? curveDefault : other.curveDefault,
      curveBounce: t < 0.5 ? curveBounce : other.curveBounce,
      curveSlide: t < 0.5 ? curveSlide : other.curveSlide,
    );
  }
}

// ============================================================================
// TransformFitTextTheme — MacroFactor-quality data typography
//
// All text styles are named tokens. Data fonts use tabular figures.
// Supports dynamic type via [scale] parameter.
//
// Usage:
//   final tt = t.textTheme;                    // default scale
//   final tt = t.textThemeWithScale(1.3);      // large text accessibility
//   Text('Hello', style: tt.h1);
// ============================================================================

class TransformFitTextTheme {
  const TransformFitTextTheme({this.scale = 1.0});

  /// Scale factor for Dynamic Type support.
  /// 1.0 = default, 1.3 = large, 2.0 = extra large accessibility.
  final double scale;

  TextStyle _scaled(TextStyle style) {
    if (scale == 1.0) return style;
    return style.copyWith(fontSize: (style.fontSize ?? 16) * scale);
  }

  // -- Heading: Display — Inter 34px/1.2 semibold (screen titles) -----------
  // Golden Ratio: 16 × φ² ≈ 42px, Fibonacci: 34px

  TextStyle get display => _scaled(const TextStyle(
        fontFamily: 'Inter',
        fontSize: MathematicalDesign.text2xl,  // 34px (fib)
        fontWeight: FontWeight.w600,
        height: 1.2,
        color: Color(0xFFFFFFFF),
      ));

  // -- Heading: H1 — Inter 34px/1.2 semibold (screen titles) ----------------
  // Fibonacci: 34px

  TextStyle get h1 => _scaled(const TextStyle(
        fontFamily: 'Inter',
        fontSize: MathematicalDesign.text2xl,  // 34px (fib)
        fontWeight: FontWeight.w600,
        height: 1.2,
        color: Color(0xFFFFFFFF),
      ));

  // -- Heading: H2 — Inter 21px/1.3 medium (section headers) ----------------
  // Fibonacci: 21px

  TextStyle get h2 => _scaled(const TextStyle(
        fontFamily: 'Inter',
        fontSize: MathematicalDesign.textLg,   // 21px (fib)
        fontWeight: FontWeight.w500,
        height: 1.3,
        color: Color(0xFFFFFFFF),
      ));

  // -- Heading: H3 — Inter 21px/1.3 medium (card titles) --------------------
  // Fibonacci: 21px

  TextStyle get h3 => _scaled(const TextStyle(
        fontFamily: 'Inter',
        fontSize: MathematicalDesign.textLg,   // 21px (fib)
        fontWeight: FontWeight.w500,
        height: 1.3,
        color: Color(0xFFFFFFFF),
      ));

  // -- Body — Inter 16px/1.5 regular (body text) ----------------------------
  // Modular Scale base: 16px

  TextStyle get body => _scaled(const TextStyle(
        fontFamily: 'Inter',
        fontSize: MathematicalDesign.textMd,   // 16px (base)
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: Color(0xFFFFFFFF),
      ));

  // -- BodySmall — Inter 13px/1.4 regular (secondary text) ------------------
  // Fibonacci: 13px

  TextStyle get bodySmall => _scaled(const TextStyle(
        fontFamily: 'Inter',
        fontSize: MathematicalDesign.textSm,   // 13px (fib)
        fontWeight: FontWeight.w400,
        height: 1.4,
        color: Color(0xFF9CA3AF),
      ));

  // -- Caption — Inter 10px/1.3 regular (labels, metadata) ------------------
  // Modular Scale: 10px

  TextStyle get caption => _scaled(const TextStyle(
        fontFamily: 'Inter',
        fontSize: MathematicalDesign.textXs,   // 10px (scale)
        fontWeight: FontWeight.w400,
        height: 1.3,
        color: Color(0xFF8B95A5),
      ));

  // -- DataLarge — Inter 34px/1.0 bold tabular (Whoop recovery score) -------
  // Fibonacci: 34px

  TextStyle get dataLarge => _scaled(const TextStyle(
        fontFamily: 'Inter',
        fontSize: MathematicalDesign.text2xl,  // 34px (fib)
        fontWeight: FontWeight.w700,
        height: 1.0,
        color: Color(0xFFFFFFFF),
        fontFeatures: [FontFeature.tabularFigures()],
      ));

  // -- DataMedium — Inter 21px/1.0 semibold tabular (metrics) ---------------
  // Fibonacci: 21px

  TextStyle get dataMedium => _scaled(const TextStyle(
        fontFamily: 'Inter',
        fontSize: MathematicalDesign.textLg,   // 21px (fib)
        fontWeight: FontWeight.w600,
        height: 1.0,
        color: Color(0xFFFFFFFF),
        fontFeatures: [FontFeature.tabularFigures()],
      ));

  // -- DataSmall — Inter 13px/1.0 medium tabular (inline data) --------------
  // Fibonacci: 13px

  TextStyle get dataSmall => _scaled(const TextStyle(
        fontFamily: 'Inter',
        fontSize: MathematicalDesign.textSm,   // 13px (fib)
        fontWeight: FontWeight.w500,
        height: 1.0,
        color: Color(0xFFFFFFFF),
        fontFeatures: [FontFeature.tabularFigures()],
      ));

  // -- CoachVoice — Playfair 16px/1.4 medium (coach messages) ---------------
  // Modular Scale base: 16px

  TextStyle get coachVoice => _scaled(const TextStyle(
        fontFamily: 'Playfair',
        fontSize: MathematicalDesign.textMd,   // 16px (base)
        fontWeight: FontWeight.w500,
        height: 1.4,
        color: Color(0xFFFFFFFF),
      ));
}

// ============================================================================
// Private helpers
// ============================================================================

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

/// Helper for lerping [Duration] values.
Duration lerpDuration(Duration a, Duration b, double t) {
  return Duration(
    microseconds:
        (a.inMicroseconds + (b.inMicroseconds - a.inMicroseconds) * t).round(),
  );
}

// ============================================================================
// buildDigitalAtelierTheme — production theme builder
// ============================================================================

ThemeData buildDigitalAtelierTheme({double textScaleFactor = 1.0}) {
  final ext = DigitalAtelierExtension.standard();

  final colorScheme = ColorScheme.dark(
    surface: ext.background,
    onSurface: ext.textPrimary,
    primary: ext.accentPrimary,
    onPrimary: ext.background,
    secondary: ext.accentSecondary,
    error: ext.accentDanger,
    onError: ext.textPrimary,
  );

  final interTypography = _bundledTypography(
    DigitalAtelierExtension.dataFontFamily,
  );
  final baseWhite = interTypography.white;

  // Apply Dynamic Type scaling via TransformFitTextTheme.

  final textTheme = _applyFontFamily(
    baseWhite,
    DigitalAtelierExtension.dataFontFamily,
  ).copyWith(
    headlineMedium: TextStyle(
      fontFamily: DigitalAtelierExtension.dataFontFamily,
      color: ext.textPrimary,
      fontSize: 24 * textScaleFactor,
      fontWeight: FontWeight.w600,
      height: 1.2,
    ),
    titleMedium: TextStyle(
      fontFamily: DigitalAtelierExtension.dataFontFamily,
      color: ext.textPrimary,
      fontSize: 18 * textScaleFactor,
      fontWeight: FontWeight.w500,
      height: 1.3,
    ),
    bodyLarge: TextStyle(
      fontFamily: DigitalAtelierExtension.dataFontFamily,
      color: ext.textPrimary,
      fontSize: 16 * textScaleFactor,
      height: 1.5,
    ),
    bodyMedium: TextStyle(
      fontFamily: DigitalAtelierExtension.dataFontFamily,
      color: ext.textSecondary,
      fontSize: 14 * textScaleFactor,
      height: 1.4,
    ),
    bodySmall: TextStyle(
      fontFamily: DigitalAtelierExtension.dataFontFamily,
      color: ext.textMuted,
      fontSize: 12 * textScaleFactor,
      height: 1.3,
    ),
  );

  final primaryTextTheme = _applyFontFamily(
    baseWhite,
    DigitalAtelierExtension.dataFontFamily,
  );

  return ThemeData(
    brightness: Brightness.dark,
    fontFamily: DigitalAtelierExtension.dataFontFamily,
    typography: interTypography,
    scaffoldBackgroundColor: ext.background,
    colorScheme: colorScheme,
    textTheme: textTheme,
    primaryTextTheme: primaryTextTheme,
    useMaterial3: true,
    extensions: [ext],
    cardTheme: CardThemeData(
      color: ext.surface,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ext.radiusMd),
      ),
      surfaceTintColor: Colors.transparent,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: ext.accentPrimary,
        foregroundColor: ext.textInverse,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ext.radiusSm),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: ext.textPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ext.radiusSm),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: ext.textPrimary,
        side: BorderSide(color: ext.surfaceBorder),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ext.radiusSm),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: ext.surfaceInput,
      hintStyle: TextStyle(
        color: ext.textMuted,
        fontFamily: DigitalAtelierExtension.dataFontFamily,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(ext.radiusSm),
        borderSide: BorderSide(color: ext.surfaceBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(ext.radiusSm),
        borderSide: BorderSide(color: ext.surfaceBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(ext.radiusSm),
        borderSide: BorderSide(color: ext.accentPrimary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(ext.radiusSm),
        borderSide: BorderSide(color: ext.accentDanger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(ext.radiusSm),
        borderSide: BorderSide(color: ext.accentDanger, width: 1.5),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: ext.surfaceDivider,
      thickness: 1,
      space: 1,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: ext.surfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(ext.radiusLg),
        ),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: ext.surface,
      side: BorderSide(color: ext.surfaceBorder),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ext.radiusPill),
      ),
      labelStyle: TextStyle(
        color: ext.textPrimary,
        fontFamily: DigitalAtelierExtension.dataFontFamily,
        fontSize: 14,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: ext.surfaceElevated,
      contentTextStyle: TextStyle(
        color: ext.textPrimary,
        fontFamily: DigitalAtelierExtension.dataFontFamily,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ext.radiusSm),
      ),
      behavior: SnackBarBehavior.floating,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: ext.background,
      foregroundColor: ext.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        fontFamily: DigitalAtelierExtension.dataFontFamily,
        color: ext.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: ext.surface,
      indicatorColor: ext.accentPrimary.withValues(alpha: 0.15),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final isSelected = states.contains(WidgetState.selected);
        return TextStyle(
          fontFamily: DigitalAtelierExtension.dataFontFamily,
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          color: isSelected ? ext.accentPrimary : ext.textMuted,
        );
      }),
    ),
  );
}
