import 'dart:math' as math;
import 'package:flutter/painting.dart';

// ============================================================================
// TransformFit Mathematical Design System
//
// Production-grade design tokens derived from mathematical formulas:
//   - Golden Ratio (φ = 1.618) for typography and layout proportions
//   - Fibonacci Sequence for spacing, radius, and animation timing
//   - Modular Scale (Major Third 1.25) for consistent typography
//   - 8-Point Grid System for spatial alignment
//   - Rule of Thirds for layout composition
//
// Usage:
//   import 'package:transformfit/theme/mathematical_design.dart';
//   final spacing = MathematicalDesign.spaceMd; // 8.0
//   final fontSize = MathematicalDesign.textLg; // 21.0 (fib)
// ============================================================================

class MathematicalDesign {
  const MathematicalDesign._();

  // =========================================================================
  // Constants
  // =========================================================================

  /// Golden Ratio (φ) — the divine proportion
  static const double phi = 1.618033988749895;

  /// Golden Ratio conjugate (1/φ = φ - 1 ≈ 0.618)
  static const double phiConjugate = 0.618033988749895;

  /// Modular Scale ratio (Major Third — harmonious for UI)
  static const double scaleRatio = 1.25;

  /// Modular Scale base (16px body text)
  static const double scaleBase = 16.0;

  // =========================================================================
  // Fibonacci Spacing
  //
  // Natural, harmonious spacing derived from the Fibonacci sequence.
  // Each value is the sum of the two preceding values, creating
  // visually balanced proportions found throughout nature.
  // =========================================================================

  static const double fib1 = 1.0;
  static const double fib2 = 2.0;
  static const double fib3 = 3.0;
  static const double fib5 = 5.0;
  static const double fib8 = 8.0;
  static const double fib13 = 13.0;
  static const double fib21 = 21.0;
  static const double fib34 = 34.0;
  static const double fib55 = 55.0;
  static const double fib89 = 89.0;

  // =========================================================================
  // Typography Scale
  //
  // Combines Golden Ratio and Fibonacci for a harmonious type scale.
  // - Small sizes use Fibonacci (natural progression)
  // - Larger sizes use Golden Ratio multiplication (visual hierarchy)
  // =========================================================================

  /// Extra small — labels, metadata (10px)
  static const double textXs = 10.0;

  /// Small — captions, badges (13px, Fibonacci)
  static const double textSm = 13.0;

  /// Medium — body text, base (16px, Modular Scale base)
  static const double textMd = 16.0;

  /// Large — h3, card titles (21px, Fibonacci)
  static const double textLg = 21.0;

  /// Extra large — h2, section headers (26px, 16 × φ)
  static const double textXl = 26.0;

  /// 2XL — h1, screen titles (34px, Fibonacci)
  static const double text2xl = 34.0;

  /// 3XL — display, hero headings (42px, 16 × φ²)
  static const double text3xl = 42.0;

  /// 4XL — hero display (55px, Fibonacci)
  static const double text4xl = 55.0;

  // =========================================================================
  // Spacing Scale (Fibonacci)
  //
  // All spacing values are Fibonacci numbers, creating natural
  // visual rhythm and proportional harmony throughout the UI.
  // =========================================================================

  /// Extra small spacing (3px, Fibonacci)
  static const double spaceXs = 3.0;

  /// Small spacing (5px, Fibonacci)
  static const double spaceSm = 5.0;

  /// Medium spacing (8px, Fibonacci)
  static const double spaceMd = 8.0;

  /// Large spacing (13px, Fibonacci)
  static const double spaceLg = 13.0;

  /// Extra large spacing (21px, Fibonacci)
  static const double spaceXl = 21.0;

  /// 2XL spacing (34px, Fibonacci)
  static const double space2xl = 34.0;

  /// 3XL spacing (55px, Fibonacci)
  static const double space3xl = 55.0;

  /// 4XL spacing (89px, Fibonacci)
  static const double space4xl = 89.0;

  // =========================================================================
  // 8-Point Grid System
  //
  // All spacing must be multiples of 8 for pixel-perfect alignment.
  // Exception: 4px for fine adjustments.
  // =========================================================================

  static const double grid4 = 4.0;
  static const double grid8 = 8.0;
  static const double grid16 = 16.0;
  static const double grid24 = 24.0;
  static const double grid32 = 32.0;
  static const double grid40 = 40.0;
  static const double grid48 = 48.0;
  static const double grid56 = 56.0;
  static const double grid64 = 64.0;
  static const double grid72 = 72.0;
  static const double grid80 = 80.0;

  // =========================================================================
  // Border Radius (Fibonacci)
  //
  // Radius values follow Fibonacci sequence for consistent,
  // natural-feeling rounded corners.
  // =========================================================================

  /// Small radius (3px, Fibonacci) — subtle rounding
  static const double radiusSm = 3.0;

  /// Medium radius (5px, Fibonacci) — standard cards
  static const double radiusMd = 5.0;

  /// Large radius (8px, Fibonacci) — elevated cards
  static const double radiusLg = 8.0;

  /// Extra large radius (13px, Fibonacci) — modals, bottom sheets
  static const double radiusXl = 13.0;

  /// Pill radius (21px, Fibonacci) — chips, tags
  static const double radiusPill = 21.0;

  /// Circle radius — fully rounded
  static const double radiusCircle = 999.0;

  // =========================================================================
  // Icon Sizes (Fibonacci)
  //
  // Icon sizes follow Fibonacci for visual consistency with spacing.
  // =========================================================================

  /// Small icon (8px, Fibonacci)
  static const double iconSm = 8.0;

  /// Medium icon (13px, Fibonacci)
  static const double iconMd = 13.0;

  /// Large icon (21px, Fibonacci)
  static const double iconLg = 21.0;

  /// Extra large icon (34px, Fibonacci)
  static const double iconXl = 34.0;

  // =========================================================================
  // Animation Durations (Fibonacci)
  //
  // Duration values follow Fibonacci sequence for natural,
  // perceptually balanced motion timing.
  // =========================================================================

  /// Fast animation (100ms, Fibonacci) — micro-interactions
  static const Duration animFast = Duration(milliseconds: 100);

  /// Normal animation (200ms, Fibonacci) — standard transitions
  static const Duration animNormal = Duration(milliseconds: 200);

  /// Medium animation (300ms, Fibonacci) — page transitions
  static const Duration animMedium = Duration(milliseconds: 300);

  /// Slow animation (500ms, Fibonacci) — emphasis
  static const Duration animSlow = Duration(milliseconds: 500);

  /// Very slow animation (800ms, Fibonacci) — dramatic reveals
  static const Duration animVerySlow = Duration(milliseconds: 800);

  /// Celebration animation (1300ms, Fibonacci) — achievements
  static const Duration animCelebration = Duration(milliseconds: 1300);

  /// Hero animation (2100ms, Fibonacci) — hero transitions
  static const Duration animHero = Duration(milliseconds: 2100);

  // =========================================================================
  // Golden Ratio Layout
  //
  // The Golden Ratio creates visually pleasing proportions.
  // - Major section: 61.8% of available space
  // - Minor section: 38.2% of available space
  // =========================================================================

  /// Major section proportion (61.8%)
  static const double goldenMajor = 0.618;

  /// Minor section proportion (38.2%)
  static const double goldenMinor = 0.382;

  // =========================================================================
  // Card Aspect Ratios
  //
  // Aspect ratios derived from Golden Ratio for visually
  // harmonious card proportions.
  // =========================================================================

  /// Hero card aspect ratio (1:0.618) — wide, prominent
  static const double cardHero = 1.0 / phi;

  /// Compact card aspect ratio (1:0.382) — narrow, stacked
  static const double cardCompact = 1.0 / (phi * phi);

  /// Square card aspect ratio (1:1) — equal dimensions
  static const double cardSquare = 1.0;

  /// Portrait card aspect ratio (0.618:1) — tall, vertical
  static const double cardPortrait = phiConjugate;

  // =========================================================================
  // Modular Scale Helper
  //
  // Generates font sizes using the Major Third modular scale.
  // Each step multiplies by 1.25, creating harmonious size progression.
  //
  // Steps:
  //   -2: 10.24px (xs)
  //   -1: 12.80px (sm)
  //    0: 16.00px (md, base)
  //    1: 20.00px (lg)
  //    2: 25.00px (xl)
  //    3: 31.25px (2xl)
  //    4: 40.00px (3xl)
  //    5: 50.00px (4xl)
  //    6: 62.50px (5xl)
  // =========================================================================

  /// Returns font size for the given modular scale step.
  /// Step 0 = base (16px), positive = larger, negative = smaller.
  static double scale(int step) => scaleBase * math.pow(scaleRatio, step);

  // =========================================================================
  // Golden Ratio Helpers
  //
  // Utility methods for applying Golden Ratio to dimensions.
  // =========================================================================

  /// Returns the major portion (61.8%) of [total].
  static double goldenMajorOf(double total) => total * goldenMajor;

  /// Returns the minor portion (38.2%) of [total].
  static double goldenMinorOf(double total) => total * goldenMinor;

  /// Returns [value] scaled by Golden Ratio.
  static double goldenScale(double value) => value * phi;

  /// Returns [value] scaled by Golden Ratio conjugate.
  static double goldenShrink(double value) => value * phiConjugate;

  // =========================================================================
  // Fibonacci Spiral Visual Flow
  //
  // Eye movement follows Fibonacci spiral:
  //   - Primary action: center of spiral
  //   - Secondary action: next ring
  //   - Tertiary action: outer ring
  //
  // Use these offsets from center to position key elements.
  // =========================================================================

  /// Primary focal point offset (center, 0,0)
  static const Offset spiralCenter = Offset.zero;

  /// Secondary focal point offset (first ring)
  static const Offset spiralRing1 = Offset(8.0, 8.0);

  /// Tertiary focal point offset (second ring)
  static const Offset spiralRing2 = Offset(21.0, 21.0);

  /// Quaternary focal point offset (third ring)
  static const Offset spiralRing3 = Offset(55.0, 55.0);

  // =========================================================================
  // Rule of Thirds
  //
  // Layout composition guideline:
  //   - Hero element: 2/3 of viewport
  //   - Supporting elements: 1/3 of viewport
  //   - Focal points at intersection of thirds
  // =========================================================================

  /// Major section proportion (2/3 ≈ 66.7%)
  static const double thirdMajor = 2.0 / 3.0;

  /// Minor section proportion (1/3 ≈ 33.3%)
  static const double thirdMinor = 1.0 / 3.0;

  /// Returns the major third of [total] (2/3).
  static double thirdMajorOf(double total) => total * thirdMajor;

  /// Returns the minor third of [total] (1/3).
  static double thirdMinorOf(double total) => total * thirdMinor;

  // =========================================================================
  // Recovery Circle Proportions
  //
  // Specialized proportions for the Whoop-style recovery circle widget.
  // All values follow Fibonacci for visual consistency.
  // =========================================================================

  /// Circle stroke width (8px, Fibonacci)
  static const double circleStrokeWidth = 8.0;

  /// Circle diameter (233px, Fibonacci F(13))
  static const double circleSize = 233.0;

  /// Score font size (55px, Fibonacci)
  static const double circleScoreFontSize = 55.0;

  /// Label font size (13px, Fibonacci)
  static const double circleLabelFontSize = 13.0;

  /// Score label spacing (13px, Fibonacci)
  static const double circleScoreSpacing = 13.0;
}
