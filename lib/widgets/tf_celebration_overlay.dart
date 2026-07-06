import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:transformfit/theme/digital_atelier.dart';

/// Confetti / particle celebration overlay for PRs, achievements, milestones.
///
/// Show with [showCelebrationOverlay] and it auto-removes after [duration].
class TfCelebrationOverlay extends StatefulWidget {
  const TfCelebrationOverlay({
    super.key,
    required this.onComplete,
    this.duration = const Duration(seconds: 3),
    this.particleCount = 60,
    this.colors,
  });

  final VoidCallback onComplete;
  final Duration duration;
  final int particleCount;
  final List<Color>? colors;

  @override
  State<TfCelebrationOverlay> createState() => _TfCelebrationOverlayState();
}

class _TfCelebrationOverlayState extends State<TfCelebrationOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) widget.onComplete();
      });

    final rng = math.Random();
    final palette = widget.colors ??
        [
          DigitalAtelierTokens.accentOrange,
          const Color(0xFFFBBF24),
          const Color(0xFF30A46C),
          const Color(0xFF3B82F6),
          const Color(0xFFE5484D),
          const Color(0xFFA78BFA),
        ];

    _particles = List.generate(widget.particleCount, (_) {
      return _Particle(
        x: 0.5 + (rng.nextDouble() - 0.5) * 0.4,
        y: 1.0,
        vx: (rng.nextDouble() - 0.5) * 0.6,
        vy: -(0.4 + rng.nextDouble() * 0.6),
        color: palette[rng.nextInt(palette.length)],
        size: 4 + rng.nextDouble() * 6,
        rotation: rng.nextDouble() * math.pi * 2,
        rotationSpeed: (rng.nextDouble() - 0.5) * 4,
        shape: _ParticleShape.values[rng.nextInt(_ParticleShape.values.length)],
      );
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          size: Size.infinite,
          painter: _CelebrationPainter(
            particles: _particles,
            progress: _controller.value,
          ),
        );
      },
    );
  }
}

enum _ParticleShape { circle, square, line }

class _Particle {
  _Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
    required this.size,
    required this.rotation,
    required this.rotationSpeed,
    required this.shape,
  });

  final double x, y, vx, vy;
  final Color color;
  final double size;
  double rotation;
  final double rotationSpeed;
  final _ParticleShape shape;
}

class _CelebrationPainter extends CustomPainter {
  _CelebrationPainter({
    required this.particles,
    required this.progress,
  });

  final List<_Particle> particles;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final t = progress;
      // Gravity + velocity
      final px = (p.x + p.vx * t) * size.width;
      final py = (p.y + p.vy * t + 0.5 * 0.8 * t * t) * size.height;
      final opacity = (1.0 - t).clamp(0.0, 1.0);
      final angle = p.rotation + p.rotationSpeed * t;

      canvas.save();
      canvas.translate(px, py);
      canvas.rotate(angle);

      final paint = Paint()..color = p.color.withValues(alpha: opacity);

      switch (p.shape) {
        case _ParticleShape.circle:
          canvas.drawCircle(Offset.zero, p.size / 2, paint);
          break;
        case _ParticleShape.square:
          canvas.drawRect(
            Rect.fromCenter(
              center: Offset.zero,
              width: p.size,
              height: p.size,
            ),
            paint,
          );
          break;
        case _ParticleShape.line:
          final linePaint = Paint()
            ..color = p.color.withValues(alpha: opacity)
            ..strokeWidth = 2
            ..strokeCap = StrokeCap.round;
          canvas.drawLine(
            Offset(-p.size, 0),
            Offset(p.size, 0),
            linePaint,
          );
          break;
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_CelebrationPainter old) =>
      old.progress != progress;
}

/// Convenience: show celebration as an overlay entry.
OverlayEntry showCelebrationOverlay(
  BuildContext context, {
  Duration duration = const Duration(seconds: 3),
  int particleCount = 60,
  List<Color>? colors,
}) {
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => Positioned.fill(
      child: IgnorePointer(
        child: TfCelebrationOverlay(
          duration: duration,
          particleCount: particleCount,
          colors: colors,
          onComplete: () => entry.remove(),
        ),
      ),
    ),
  );
  Overlay.of(context).insert(entry);
  return entry;
}
