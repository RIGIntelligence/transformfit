import 'package:flutter/material.dart';

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
// (backward-compatible, unchanged — existing code references these statics)
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
        surface: Color(0xFF111111),
        surfaceElevated: Color(0xFF1A1A1A),
        surfaceInput: Color(0xFF151515),
        surfaceBorder: Color(0xFF1E1E1E),
        surfaceDivider: Color(0xFF252525),
        // Accent Colors
        accentPrimary: Color(0xFFF97316),
        accentSecondary: Color(0xFF8B5CF6),
        accentTertiary: Color(0xFF10B981),
        accentDanger: Color(0xFFEF4444),
        accentInfo: Color(0xFF3B82F6),
        // Text Colors
        textPrimary: Color(0xFFF0EDE8),
        textSecondary: Color(0xFF9CA3AF),
        textMuted: Color(0xFF8B95A5),
        textInverse: Color(0xFF0A0A0A),
        // Semantic Colors
        success: Color(0xFF10B981),
        warning: Color(0xFFF59E0B),
        recovery: Color(0xFF8B5CF6),
        calm: Color(0xFF6366F1),
        // Spacing (4px base)
        spaceXs: 4,
        spaceSm: 8,
        spaceMd: 12,
        spaceLg: 16,
        spaceXl: 24,
        spaceXxl: 32,
        spaceXxxl: 48,
        spaceHuge: 64,
        // Border Radius
        radiusSm: 8,
        radiusMd: 12,
        radiusLg: 16,
        radiusXl: 24,
        radiusPill: 999,
        // Animation
        durationFast: Duration(milliseconds: 150),
        durationNormal: Duration(milliseconds: 300),
        durationSlow: Duration(milliseconds: 500),
        durationCelebration: Duration(milliseconds: 1500),
        curveDefault: Curves.easeOutCubic,
        curveBounce: Curves.elasticOut,
        curveSlide: Curves.easeOutQuart,
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

  /// Standard card: surface bg, md radius, surfaceBorder.
  BoxDecoration get cardDecoration => BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(radiusMd),
        border: Border.all(color: surfaceBorder, width: 1),
      );

  /// Elevated card: surfaceElevated bg, md radius, surfaceBorder.
  BoxDecoration get cardElevated => BoxDecoration(
        color: surfaceElevated,
        borderRadius: BorderRadius.circular(radiusMd),
        border: Border.all(color: surfaceBorder, width: 1),
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

  /// Modal bottom sheet: surfaceElevated bg, lg radius, tinted shadow.
  BoxDecoration get modalDecoration => BoxDecoration(
        color: surfaceElevated,
        borderRadius: BorderRadius.circular(radiusLg),
        border: Border.all(color: surfaceBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: accentPrimary.withValues(alpha: 0.05),
            blurRadius: 32,
            offset: const Offset(0, -4),
          ),
        ],
      );

  // =========================================================================
  // Gradient Presets
  // =========================================================================

  /// Orange → Purple (135°) — hero moments, onboarding.
  LinearGradient get gradientHero => LinearGradient(
        colors: [accentPrimary, accentSecondary],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  /// Green → Blue (135°) — progress, achievements.
  LinearGradient get gradientProgress => LinearGradient(
        colors: [accentTertiary, accentInfo],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  /// Blue → Purple (135°) — recovery, wellness.
  LinearGradient get gradientRecovery => LinearGradient(
        colors: [accentInfo, accentSecondary],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  // =========================================================================
  // Elevation / Shadows — subtle, tinted
  // =========================================================================

  /// No shadow — cards use border only.
  List<BoxShadow> get elevationNone => const [];

  /// Modal shadow — primary tint at 5% opacity.
  List<BoxShadow> get elevationModal => [
        BoxShadow(
          color: accentPrimary.withValues(alpha: 0.05),
          blurRadius: 32,
          offset: const Offset(0, -4),
        ),
      ];

  /// FAB shadow — primary tint.
  List<BoxShadow> get elevationFab => [
        BoxShadow(
          color: accentPrimary.withValues(alpha: 0.25),
          blurRadius: 24,
          offset: const Offset(0, 8),
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

  LinearGradient get heroGradient => gradientHero;
  LinearGradient get recoveryGradient => gradientRecovery;
  LinearGradient get progressGradient => gradientProgress;

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

  /// Returns a static decoration alternative for gradient hero.
  /// Use when reduced motion is active — no animated gradient shimmer.
  BoxDecoration get staticHeroDecoration => BoxDecoration(
        color: accentPrimary,
        borderRadius: BorderRadius.circular(radiusMd),
      );

  /// Returns a static decoration alternative for gradient progress.
  BoxDecoration get staticProgressDecoration => BoxDecoration(
        color: accentTertiary,
        borderRadius: BorderRadius.circular(radiusMd),
      );

  /// Returns a static decoration alternative for gradient recovery.
  BoxDecoration get staticRecoveryDecoration => BoxDecoration(
        color: accentInfo,
        borderRadius: BorderRadius.circular(radiusMd),
      );

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

  // -- Heading: Display — Playfair 40px/1.1 bold (hero moments only) --------

  TextStyle get display => _scaled(const TextStyle(
        fontFamily: 'Playfair',
        fontSize: 40,
        fontWeight: FontWeight.w700,
        height: 1.1,
        letterSpacing: -0.5,
        color: Color(0xFFF0EDE8),
      ));

  // -- Heading: H1 — Inter 28px/1.2 semibold (screen titles) ----------------

  TextStyle get h1 => _scaled(const TextStyle(
        fontFamily: 'Inter',
        fontSize: 28,
        fontWeight: FontWeight.w600,
        height: 1.2,
        color: Color(0xFFF0EDE8),
      ));

  // -- Heading: H2 — Inter 22px/1.3 semibold (section headers) --------------

  TextStyle get h2 => _scaled(const TextStyle(
        fontFamily: 'Inter',
        fontSize: 22,
        fontWeight: FontWeight.w600,
        height: 1.3,
        color: Color(0xFFF0EDE8),
      ));

  // -- Heading: H3 — Inter 18px/1.3 medium (card titles) --------------------

  TextStyle get h3 => _scaled(const TextStyle(
        fontFamily: 'Inter',
        fontSize: 18,
        fontWeight: FontWeight.w500,
        height: 1.3,
        color: Color(0xFFF0EDE8),
      ));

  // -- Body — Inter 16px/1.5 regular (body text) ----------------------------

  TextStyle get body => _scaled(const TextStyle(
        fontFamily: 'Inter',
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: Color(0xFFF0EDE8),
      ));

  // -- BodySmall — Inter 14px/1.4 regular (secondary text) ------------------

  TextStyle get bodySmall => _scaled(const TextStyle(
        fontFamily: 'Inter',
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.4,
        color: Color(0xFF9CA3AF),
      ));

  // -- Caption — Inter 12px/1.3 regular (labels, metadata) ------------------

  TextStyle get caption => _scaled(const TextStyle(
        fontFamily: 'Inter',
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.3,
        color: Color(0xFF8B95A5),
      ));

  // -- DataLarge — Inter 32px/1.0 bold tabular (Whoop recovery score) -------

  TextStyle get dataLarge => _scaled(const TextStyle(
        fontFamily: 'Inter',
        fontSize: 32,
        fontWeight: FontWeight.w700,
        height: 1.0,
        color: Color(0xFFF0EDE8),
        fontFeatures: [FontFeature.tabularFigures()],
      ));

  // -- DataMedium — Inter 24px/1.0 semibold tabular (metrics) ---------------

  TextStyle get dataMedium => _scaled(const TextStyle(
        fontFamily: 'Inter',
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 1.0,
        color: Color(0xFFF0EDE8),
        fontFeatures: [FontFeature.tabularFigures()],
      ));

  // -- DataSmall — Inter 16px/1.0 medium tabular (inline data) --------------

  TextStyle get dataSmall => _scaled(const TextStyle(
        fontFamily: 'Inter',
        fontSize: 16,
        fontWeight: FontWeight.w500,
        height: 1.0,
        color: Color(0xFFF0EDE8),
        fontFeatures: [FontFeature.tabularFigures()],
      ));

  // -- CoachVoice — Playfair 18px/1.4 medium (coach messages) ---------------

  TextStyle get coachVoice => _scaled(const TextStyle(
        fontFamily: 'Playfair',
        fontSize: 18,
        fontWeight: FontWeight.w500,
        height: 1.4,
        color: Color(0xFFF0EDE8),
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
      fontFamily: DigitalAtelierExtension.coachVoiceFontFamily,
      color: ext.textPrimary,
      fontSize: 40 * textScaleFactor,
      fontWeight: FontWeight.w600,
      height: 1.1,
    ),
    titleMedium: TextStyle(
      fontFamily: DigitalAtelierExtension.coachVoiceFontFamily,
      color: ext.textPrimary,
      fontSize: 22 * textScaleFactor,
      fontWeight: FontWeight.w500,
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
        side: BorderSide(color: ext.surfaceBorder, width: 1),
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
