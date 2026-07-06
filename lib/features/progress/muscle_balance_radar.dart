import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:transformfit/theme/digital_atelier.dart';

// ---------------------------------------------------------------------------
// Data model
// ---------------------------------------------------------------------------

class MuscleVolume {
  const MuscleVolume({required this.muscle, required this.volumeFraction});
  final String muscle;
  final double volumeFraction; // 0.0 – 1.0 (relative to target)
}

List<MuscleVolume> generateMockMuscleData() {
  return const [
    MuscleVolume(muscle: 'Chest', volumeFraction: 0.85),
    MuscleVolume(muscle: 'Back', volumeFraction: 0.92),
    MuscleVolume(muscle: 'Shoulders', volumeFraction: 0.70),
    MuscleVolume(muscle: 'Arms', volumeFraction: 0.78),
    MuscleVolume(muscle: 'Core', volumeFraction: 0.55),
    MuscleVolume(muscle: 'Quads', volumeFraction: 0.95),
    MuscleVolume(muscle: 'Hamstrings', volumeFraction: 0.62),
    MuscleVolume(muscle: 'Glutes', volumeFraction: 0.80),
  ];
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final muscleDataProvider = Provider<List<MuscleVolume>>((ref) {
  return generateMockMuscleData();
});

// ---------------------------------------------------------------------------
// Widget
// ---------------------------------------------------------------------------

class MuscleBalanceRadar extends ConsumerWidget {
  const MuscleBalanceRadar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).extension<DigitalAtelierExtension>()!;
    final data = ref.watch(muscleDataProvider);

    if (data.isEmpty) return _EmptyState(t: t);

    final avgVolume =
        data.map((d) => d.volumeFraction).reduce((a, b) => a + b) / data.length;

    return Semantics(
      label:
          'Muscle balance radar chart. '
          '${data.map((d) => '${d.muscle}: ${(d.volumeFraction * 100).toStringAsFixed(0)}%').join(', ')}. '
          'Average coverage: ${(avgVolume * 100).toStringAsFixed(0)}%.',
      child: Container(
        decoration: t.cardDecoration,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Muscle Balance', style: t.textTheme.h3),
            const SizedBox(height: 4),
            Text(
              'Volume coverage vs target · avg ${(avgVolume * 100).toStringAsFixed(0)}%',
              style: t.textTheme.caption,
            ),
            const SizedBox(height: 16),
            Center(
              child: SizedBox(
                width: 260,
                height: 260,
                child: CustomPaint(
                  painter: _RadarPainter(
                    data: data,
                    fillColor: t.accentPrimary.withValues(alpha: 0.30),
                    borderColor: t.accentPrimary,
                    gridColor: t.surfaceBorder,
                    labelColor: t.textSecondary,
                    mutedColor: t.textMuted,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// CustomPainter
// ---------------------------------------------------------------------------

class _RadarPainter extends CustomPainter {
  _RadarPainter({
    required this.data,
    required this.fillColor,
    required this.borderColor,
    required this.gridColor,
    required this.labelColor,
    required this.mutedColor,
  });

  final List<MuscleVolume> data;
  final Color fillColor;
  final Color borderColor;
  final Color gridColor;
  final Color labelColor;
  final Color mutedColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 32;
    final n = data.length;
    final angleStep = 2 * math.pi / n;
    final gridPaint = Paint()
      ..color = gridColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    // Draw concentric grid rings (20%, 40%, 60%, 80%, 100%).
    for (var ring = 1; ring <= 5; ring++) {
      final r = radius * ring / 5;
      final path = Path();
      for (var i = 0; i < n; i++) {
        final angle = -math.pi / 2 + i * angleStep;
        final x = center.dx + r * math.cos(angle);
        final y = center.dy + r * math.sin(angle);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
      canvas.drawPath(path, gridPaint);
    }

    // Draw axis lines.
    for (var i = 0; i < n; i++) {
      final angle = -math.pi / 2 + i * angleStep;
      canvas.drawLine(
        center,
        Offset(
          center.dx + radius * math.cos(angle),
          center.dy + radius * math.sin(angle),
        ),
        gridPaint,
      );
    }

    // Draw data polygon.
    final dataPath = Path();
    for (var i = 0; i < n; i++) {
      final angle = -math.pi / 2 + i * angleStep;
      final r = radius * data[i].volumeFraction.clamp(0.0, 1.0);
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);
      if (i == 0) {
        dataPath.moveTo(x, y);
      } else {
        dataPath.lineTo(x, y);
      }
    }
    dataPath.close();

    canvas.drawPath(
      dataPath,
      Paint()
        ..color = fillColor
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      dataPath,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Draw data points and labels.
    for (var i = 0; i < n; i++) {
      final angle = -math.pi / 2 + i * angleStep;
      final r = radius * data[i].volumeFraction.clamp(0.0, 1.0);
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);

      // Point dot.
      canvas.drawCircle(Offset(x, y), 4, Paint()..color = borderColor);

      // Label.
      final labelR = radius + 18;
      final lx = center.dx + labelR * math.cos(angle);
      final ly = center.dy + labelR * math.sin(angle);
      final tp = TextPainter(
        text: TextSpan(
          text: data[i].muscle,
          style: TextStyle(
            color: labelColor,
            fontSize: 11,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      var dx = lx - tp.width / 2;
      var dy = ly - tp.height / 2;
      // Nudge labels at edges.
      if (lx < center.dx - radius / 2) dx = lx - tp.width;
      if (lx > center.dx + radius / 2) dx = lx;
      if (ly < center.dy - radius) dy = ly - tp.height / 2;
      if (ly > center.dy + radius) dy = ly - tp.height / 2;
      tp.paint(canvas, Offset(dx, dy));
    }
  }

  @override
  bool shouldRepaint(covariant _RadarPainter old) => data != old.data;
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.t});
  final DigitalAtelierExtension t;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: t.cardDecoration,
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.radar, color: t.textMuted, size: 40),
            const SizedBox(height: 12),
            Text(
              'No muscle data yet',
              style: t.textTheme.body.copyWith(color: t.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
