import 'package:flutter/material.dart';
import 'package:transformfit/theme/mathematical_design.dart';

// ============================================================================
// TransformFit Golden Layout Widgets
//
// Layout widgets based on mathematical proportions:
//   - GoldenRatioSplit: 61.8% / 38.2% split layout
//   - FibonacciGrid: Grid with Fibonacci-based sizing
//   - RuleOfThirdsOverlay: Composition guide overlay
//   - GoldenCard: Card with Golden Ratio aspect ratio
//
// Usage:
//   GoldenRatioSplit(
//     major: Container(color: Colors.blue),
//     minor: Container(color: Colors.red),
//   )
// ============================================================================

// ---------------------------------------------------------------------------
// GoldenRatioSplit — 61.8% / 38.2% split layout
// ---------------------------------------------------------------------------

/// Splits available space using the Golden Ratio (φ ≈ 1.618).
///
/// The [major] widget receives 61.8% of space, [minor] receives 38.2%.
/// Set [vertical] to true for top/bottom split, false (default) for left/right.
///
/// Example:
/// ```dart
/// GoldenRatioSplit(
///   major: WorkoutSummary(),
///   minor: RecoveryScore(),
/// )
/// ```
class GoldenRatioSplit extends StatelessWidget {
  const GoldenRatioSplit({
    super.key,
    required this.major,
    required this.minor,
    this.vertical = false,
    this.gap = 0.0,
  });

  /// Widget in the major section (61.8%).
  final Widget major;

  /// Widget in the minor section (38.2%).
  final Widget minor;

  /// If true, splits vertically (top/bottom). If false, splits horizontally.
  final bool vertical;

  /// Gap between major and minor sections.
  final double gap;

  @override
  Widget build(BuildContext context) {
    if (vertical) {
      return Column(
        children: [
          Expanded(
            flex: 618, // 61.8%
            child: major,
          ),
          if (gap > 0) SizedBox(height: gap),
          Expanded(
            flex: 382, // 38.2%
            child: minor,
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          flex: 618, // 61.8%
          child: major,
        ),
        if (gap > 0) SizedBox(width: gap),
        Expanded(
          flex: 382, // 38.2%
          child: minor,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// FibonacciGrid — Grid with Fibonacci-based sizing
// ---------------------------------------------------------------------------

/// A grid layout where column counts follow Fibonacci numbers.
///
/// Use for dashboards, stat grids, and data-dense layouts.
/// Automatically adjusts columns based on available width.
///
/// Example:
/// ```dart
/// FibonacciGrid(
///   children: [
///     StatCard(label: 'Steps', value: '8,432'),
///     StatCard(label: 'Calories', value: '1,847'),
///     StatCard(label: 'Heart Rate', value: '72 bpm'),
///   ],
/// )
/// ```
class FibonacciGrid extends StatelessWidget {
  const FibonacciGrid({
    super.key,
    required this.children,
    this.spacing,
    this.runSpacing,
  });

  /// Grid children.
  final List<Widget> children;

  /// Horizontal spacing between items (defaults to Fibonacci spacing).
  final double? spacing;

  /// Vertical spacing between rows (defaults to Fibonacci spacing).
  final double? runSpacing;

  @override
  Widget build(BuildContext context) {
    final hSpacing = spacing ?? MathematicalDesign.spaceMd;
    final vSpacing = runSpacing ?? MathematicalDesign.spaceMd;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Determine column count based on width
        // Use Fibonacci numbers: 1, 2, 3, 5 columns
        final width = constraints.maxWidth;
        int columns;
        if (width < 400) {
          columns = 1;
        } else if (width < 600) {
          columns = 2;
        } else if (width < 900) {
          columns = 3;
        } else {
          columns = 5;
        }

        return Wrap(
          spacing: hSpacing,
          runSpacing: vSpacing,
          children: children.map((child) {
            final itemWidth =
                (width - (columns - 1) * hSpacing) / columns;
            return SizedBox(
              width: itemWidth,
              child: child,
            );
          }).toList(),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// RuleOfThirdsOverlay — Composition guide overlay
// ---------------------------------------------------------------------------

/// Overlays Rule of Thirds grid lines for visual composition debugging.
///
/// Shows a 3×3 grid with focal points at intersections.
/// Use during development to verify element placement.
///
/// Example:
/// ```dart
/// RuleOfThirdsOverlay(
///   showFocalPoints: true,
///   child: MyScreen(),
/// )
/// ```
class RuleOfThirdsOverlay extends StatelessWidget {
  const RuleOfThirdsOverlay({
    super.key,
    required this.child,
    this.showGrid = true,
    this.showFocalPoints = true,
    this.color,
    this.focalPointSize = 8.0,
  });

  /// Child widget to overlay.
  final Widget child;

  /// Whether to show grid lines.
  final bool showGrid;

  /// Whether to show focal points at intersections.
  final bool showFocalPoints;

  /// Color for grid lines and focal points.
  final Color? color;

  /// Size of focal point indicators.
  final double focalPointSize;

  @override
  Widget build(BuildContext context) {
    final overlayColor = color ?? Colors.white.withValues(alpha: 0.3);

    return Stack(
      children: [
        child,
        if (showGrid)
          Positioned.fill(
            child: CustomPaint(
              painter: _RuleOfThirdsPainter(
                color: overlayColor,
                showFocalPoints: showFocalPoints,
                focalPointSize: focalPointSize,
              ),
            ),
          ),
      ],
    );
  }
}

class _RuleOfThirdsPainter extends CustomPainter {
  _RuleOfThirdsPainter({
    required this.color,
    required this.showFocalPoints,
    required this.focalPointSize,
  });

  final Color color;
  final bool showFocalPoints;
  final double focalPointSize;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Vertical lines at 1/3 and 2/3
    final x1 = size.width * MathematicalDesign.thirdMinor;
    final x2 = size.width * MathematicalDesign.thirdMajor;
    canvas.drawLine(Offset(x1, 0), Offset(x1, size.height), paint);
    canvas.drawLine(Offset(x2, 0), Offset(x2, size.height), paint);

    // Horizontal lines at 1/3 and 2/3
    final y1 = size.height * MathematicalDesign.thirdMinor;
    final y2 = size.height * MathematicalDesign.thirdMajor;
    canvas.drawLine(Offset(0, y1), Offset(size.width, y1), paint);
    canvas.drawLine(Offset(0, y2), Offset(size.width, y2), paint);

    // Focal points at intersections
    if (showFocalPoints) {
      final focalPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      final points = [
        Offset(x1, y1),
        Offset(x2, y1),
        Offset(x1, y2),
        Offset(x2, y2),
      ];

      for (final point in points) {
        canvas.drawCircle(point, focalPointSize / 2, focalPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// GoldenCard — Card with Golden Ratio aspect ratio
// ---------------------------------------------------------------------------

/// A card widget with Golden Ratio proportions.
///
/// Use [GoldenCardType.hero] for wide cards (1:0.618),
/// [GoldenCardType.compact] for narrow cards (1:0.382),
/// or [GoldenCardType.square] for equal dimensions.
///
/// Example:
/// ```dart
/// GoldenCard(
///   type: GoldenCardType.hero,
///   child: WorkoutSummary(),
/// )
/// ```
class GoldenCard extends StatelessWidget {
  const GoldenCard({
    super.key,
    required this.child,
    this.type = GoldenCardType.hero,
    this.padding,
    this.decoration,
  });

  /// Card content.
  final Widget child;

  /// Card aspect ratio type.
  final GoldenCardType type;

  /// Internal padding.
  final EdgeInsetsGeometry? padding;

  /// Custom decoration (overrides default).
  final BoxDecoration? decoration;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: type.ratio,
      child: Container(
        padding: padding ?? EdgeInsets.all(MathematicalDesign.spaceMd),
        decoration: decoration ?? BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(MathematicalDesign.radiusMd),
        ),
        child: child,
      ),
    );
  }
}

/// Card aspect ratio types based on Golden Ratio.
enum GoldenCardType {
  /// Wide card (1:0.618) — for hero content, summaries.
  hero(1.0 / MathematicalDesign.phi),

  /// Narrow card (1:0.382) — for compact stats, badges.
  compact(1.0 / (MathematicalDesign.phi * MathematicalDesign.phi)),

  /// Square card (1:1) — for equal dimensions.
  square(1.0),

  /// Portrait card (0.618:1) — for vertical content.
  portrait(MathematicalDesign.phiConjugate);

  const GoldenCardType(this.ratio);

  /// Aspect ratio (width / height).
  final double ratio;
}

// ---------------------------------------------------------------------------
// GoldenSizedBox — SizedBox with Fibonacci dimensions
// ---------------------------------------------------------------------------

/// A SizedBox that uses Fibonacci spacing values.
///
/// Provides named constructors for common spacing patterns.
///
/// Example:
/// ```dart
/// GoldenSizedBox.vertical(space: FibonacciSpace.md)
/// GoldenSizedBox.horizontal(space: FibonacciSpace.lg)
/// ```
class GoldenSizedBox extends StatelessWidget {
  const GoldenSizedBox({
    super.key,
    this.width,
    this.height,
    this.child,
  });

  /// Creates vertical spacing using Fibonacci values.
  GoldenSizedBox.vertical({
    super.key,
    FibonacciSpace space = FibonacciSpace.md,
    this.child,
  })  : width = 0,
        height = space.value;

  /// Creates horizontal spacing using Fibonacci values.
  GoldenSizedBox.horizontal({
    super.key,
    FibonacciSpace space = FibonacciSpace.md,
    this.child,
  })  : width = space.value,
        height = 0;

  final double? width;
  final double? height;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: width, height: height, child: child);
  }
}

/// Fibonacci spacing values for consistent spacing.
enum FibonacciSpace {
  xs(MathematicalDesign.spaceXs),
  sm(MathematicalDesign.spaceSm),
  md(MathematicalDesign.spaceMd),
  lg(MathematicalDesign.spaceLg),
  xl(MathematicalDesign.spaceXl),
  xxl(MathematicalDesign.space2xl),
  xxxl(MathematicalDesign.space3xl),
  huge(MathematicalDesign.space4xl);

  const FibonacciSpace(this.value);

  /// Spacing value in pixels.
  final double value;
}

// ---------------------------------------------------------------------------
// GoldenPadding — Padding with Fibonacci values
// ---------------------------------------------------------------------------

/// Padding widget that uses Fibonacci spacing values.
///
/// Example:
/// ```dart
/// GoldenPadding(
///   all: FibonacciSpace.md,
///   child: MyWidget(),
/// )
/// GoldenPadding.symmetric(
///   horizontal: FibonacciSpace.lg,
///   vertical: FibonacciSpace.sm,
///   child: MyWidget(),
/// )
/// ```
class GoldenPadding extends StatelessWidget {
  const GoldenPadding({
    super.key,
    required this.child,
    FibonacciSpace? all,
    FibonacciSpace? horizontal,
    FibonacciSpace? vertical,
    FibonacciSpace? left,
    FibonacciSpace? top,
    FibonacciSpace? right,
    FibonacciSpace? bottom,
  })  : _left = left ?? (horizontal ?? all),
        _top = top ?? (vertical ?? all),
        _right = right ?? (horizontal ?? all),
        _bottom = bottom ?? (vertical ?? all);

  /// Creates symmetric padding.
  const GoldenPadding.symmetric({
    super.key,
    required this.child,
    FibonacciSpace? horizontal,
    FibonacciSpace? vertical,
  })  : _left = horizontal,
        _top = vertical,
        _right = horizontal,
        _bottom = vertical;

  final Widget child;
  final FibonacciSpace? _left;
  final FibonacciSpace? _top;
  final FibonacciSpace? _right;
  final FibonacciSpace? _bottom;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: _left?.value ?? 0,
        top: _top?.value ?? 0,
        right: _right?.value ?? 0,
        bottom: _bottom?.value ?? 0,
      ),
      child: child,
    );
  }
}
