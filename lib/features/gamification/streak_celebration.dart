import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:transformfit/theme/digital_atelier.dart';

/// Streak milestones that trigger the celebration overlay.
const List<int> kStreakMilestones = [3, 7, 14, 30, 60, 100];

/// Duolingo-style streak celebration overlay.
///
/// Usage:
///   StreakCelebration.show(context, streakDays: 7);
///   // or wrap your scaffold:
///   StreakCelebrationOverlay(streakDays: 7, onDismiss: () {})
class StreakCelebration extends StatefulWidget {
  const StreakCelebration({
    super.key,
    required this.streakDays,
    this.onDismiss,
    this.onShare,
  });

  final int streakDays;
  final VoidCallback? onDismiss;
  final VoidCallback? onShare;

  /// Show the celebration as a full-screen modal overlay.
  static Future<void> show(
    BuildContext context, {
    required int streakDays,
    VoidCallback? onShare,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'streak-celebration',
      barrierColor: Colors.black87,
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, _, _) => StreakCelebration(
        streakDays: streakDays,
        onDismiss: () => Navigator.of(context).pop(),
        onShare: onShare,
      ),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: CurvedAnimation(
            parent: animation,
            curve: Curves.elasticOut,
          ),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
    );
  }

  @override
  State<StreakCelebration> createState() => _StreakCelebrationState();
}

class _StreakCelebrationState extends State<StreakCelebration>
    with TickerProviderStateMixin {
  late final AnimationController _textController;
  late final AnimationController _particleController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.2), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 40),
    ]).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeOutCubic,
    ));

    _textController.forward();
    _particleController.forward();
  }

  @override
  void dispose() {
    _textController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<DigitalAtelierExtension>()!;

    return Material(
      color: Colors.transparent,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Confetti & fire particles
          AnimatedBuilder(
            animation: _particleController,
            builder: (context, _) => CustomPaint(
              painter: _CelebrationPainter(
                progress: _particleController.value,
                accentColor: t.accentPrimary,
                secondaryColor: t.accentSecondary,
              ),
            ),
          ),

          // Content
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Fire emoji
                AnimatedBuilder(
                  animation: _textController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Text(
                        '🔥',
                        style: TextStyle(fontSize: widget.streakDays >= 30 ? 80 : 64),
                      ),
                    );
                  },
                ),
                SizedBox(height: t.spaceXl),

                // Streak number
                AnimatedBuilder(
                  animation: _textController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Text(
                        '${widget.streakDays}',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 72,
                          fontWeight: FontWeight.w800,
                          color: t.accentPrimary,
                          height: 1.0,
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(height: t.spaceSm),

                // Headline
                Text(
                  'day streak!',
                  style: t.textTheme.h1.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: t.spaceXs),

                // Subtitle
                Text(
                  _milestoneMessage(widget.streakDays),
                  style: t.textTheme.body.copyWith(color: t.textSecondary),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: t.spaceXxl),

                // Share button
                _StreakButton(
                  label: 'Share Streak',
                  icon: Icons.share,
                  color: t.accentPrimary,
                  onPressed: widget.onShare,
                ),
                SizedBox(height: t.spaceMd),

                // Dismiss
                TextButton(
                  onPressed: widget.onDismiss,
                  child: Text(
                    'Keep Going!',
                    style: t.textTheme.body.copyWith(color: t.textMuted),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _milestoneMessage(int days) {
    if (days >= 100) return "Incredible! You're in the elite 1%. 💎";
    if (days >= 60) return "Two months strong! Unstoppable. 💪";
    if (days >= 30) return "A full month! You've built a habit. 🏆";
    if (days >= 14) return "Two weeks! The habit is forming. ⚡";
    if (days >= 7) return "One week! You're building momentum. 🚀";
    return "Keep it up! Consistency is key. ✨";
  }
}

class _StreakButton extends StatelessWidget {
  const _StreakButton({
    required this.label,
    required this.icon,
    required this.color,
    this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
        textStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Particle effects — confetti + fire emojis
// ---------------------------------------------------------------------------

class _CelebrationPainter extends CustomPainter {
  _CelebrationPainter({
    required this.progress,
    required this.accentColor,
    required this.secondaryColor,
  });

  final double progress;
  final Color accentColor;
  final Color secondaryColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    // Generate 40 confetti particles
    for (int i = 0; i < 40; i++) {
      final seed = i * 7 + 3;
      final rng = math.Random(seed);

      // Each particle starts from center-top and falls/expands outward
      final startX = size.width * (0.2 + rng.nextDouble() * 0.6);
      final startY = size.height * 0.3;

      // Trajectory: drift outward and down
      final driftX = (rng.nextDouble() - 0.5) * size.width * 0.8;
      final driftY = rng.nextDouble() * size.height * 0.5 + 50;

      final x = startX + driftX * progress;
      final y = startY + driftY * progress;

      // Rotation and fade
      final rotation = progress * (2 + rng.nextDouble() * 4);
      final opacity = (1.0 - progress).clamp(0.0, 1.0);

      final colors = [accentColor, secondaryColor, const Color(0xFFF59E0B)];
      final color = colors[i % 3].withValues(alpha: opacity);

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);

      final rect = Rect.fromCenter(
        center: Offset.zero,
        width: 6 + rng.nextDouble() * 4,
        height: 3 + rng.nextDouble() * 3,
      );

      final paint = Paint()..color = color;
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(1)),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_CelebrationPainter old) => progress != old.progress;
}
