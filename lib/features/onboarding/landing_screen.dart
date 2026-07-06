import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:transformfit/theme/digital_atelier.dart';
import 'package:transformfit/widgets/transformfit_brand_mark.dart';

// ---------------------------------------------------------------------------
// MoT1 — Acquisition to first belief.
//
// Cinematic landing surface. Conveys the coach-specific value claim with a
// typewriter animation, staggered feature cards, animated readiness ring,
// particle background, and a coach persona preview bubble.
// ---------------------------------------------------------------------------

class LandingScreen extends ConsumerWidget {
  const LandingScreen({super.key});

  // ── Copy (unchanged semantics) ────────────────────────────────────────
  static const _valueClaim =
      'A coach who already noticed you — and adjusted the plan before your '
      'first rep.';
  static const _readinessPreviewBody =
      'Tomorrow it checks how you slept, how your body feels, and what you '
      'have available — then reshapes today so you can actually do it.';
  static const _featureReadiness = 'Readiness-adjusted daily plan';
  static const _featureCoachVoice = 'Coach-voice narration, not notifications';
  static const _featureProgression = 'Progression that reacts to your body';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const _LandingBody();
  }
}

// ── Private body so we can use TickerProviderStateMixin ──────────────────

class _LandingBody extends StatefulWidget {
  const _LandingBody();

  @override
  State<_LandingBody> createState() => _LandingBodyState();
}

class _LandingBodyState extends State<_LandingBody>
    with TickerProviderStateMixin {
  // Gradient shift
  late final AnimationController _gradientCtrl;
  late final Animation<double> _gradientAnim;

  // Typewriter
  late final AnimationController _typewriterCtrl;
  late final Animation<int> _typewriterCharCount;

  // Feature cards stagger
  late final AnimationController _cardsCtrl;

  // Readiness ring
  late final AnimationController _ringCtrl;
  late final Animation<double> _ringAnim;

  // Begin button pulse
  late final AnimationController _pulseCtrl;

  // Coach bubble
  late final AnimationController _bubbleCtrl;

  // Particle drift (continuous)
  late final AnimationController _particleCtrl;

  // Scroll controller for parallax
  final ScrollController _scrollCtrl = ScrollController();
  double _scrollOffset = 0;

  bool _animationsInitialized = false;
  bool _reducedMotion = false;

  @override
  void initState() {
    super.initState();
    // Parallax listener
    _scrollCtrl.addListener(() {
      setState(() => _scrollOffset = _scrollCtrl.offset);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_animationsInitialized) return;
    _animationsInitialized = true;

    final t = Theme.of(context).extension<DigitalAtelierExtension>() ??
        DigitalAtelierExtension.standard();
    _reducedMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    // ── Gradient (infinite, 8s cycle) ──
    _gradientCtrl = AnimationController(
      vsync: this,
      duration: t.resolvedDuration(const Duration(seconds: 8), context),
    );
    if (!_reducedMotion) {
      _gradientCtrl.repeat(reverse: true);
    }
    _gradientAnim = CurvedAnimation(
      parent: _gradientCtrl,
      curve: t.resolvedCurve(Curves.easeInOut, context),
    );

    // ── Typewriter (3s forward, then stay) ──
    _typewriterCtrl = AnimationController(
      vsync: this,
      duration: t.resolvedDuration(const Duration(milliseconds: 3000), context),
    );
    if (_reducedMotion) {
      _typewriterCtrl.value = 1.0;
    } else {
      _typewriterCtrl.forward();
    }
    _typewriterCharCount = StepTween(
      begin: 0,
      end: LandingScreen._valueClaim.length,
    ).animate(CurvedAnimation(
      parent: _typewriterCtrl,
      curve: Curves.easeOut,
    ));

    // ── Feature cards (1.2s forward) ──
    _cardsCtrl = AnimationController(
      vsync: this,
      duration: t.resolvedDuration(const Duration(milliseconds: 1200), context),
    );
    if (_reducedMotion) {
      _cardsCtrl.value = 1.0;
    } else {
      _cardsCtrl.forward();
    }

    // ── Readiness ring (2s forward) ──
    _ringCtrl = AnimationController(
      vsync: this,
      duration: t.resolvedDuration(const Duration(milliseconds: 2000), context),
    );
    if (_reducedMotion) {
      _ringCtrl.value = 1.0;
    } else {
      _ringCtrl.forward();
    }
    _ringAnim = CurvedAnimation(
      parent: _ringCtrl,
      curve: t.resolvedCurve(Curves.easeOutCubic, context),
    );

    // ── Pulse (infinite 1.8s) ──
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: t.resolvedDuration(const Duration(milliseconds: 1800), context),
    );
    if (!_reducedMotion) {
      _pulseCtrl.repeat(reverse: true);
    }

    // ── Coach bubble (0.8s forward) ──
    _bubbleCtrl = AnimationController(
      vsync: this,
      duration: t.resolvedDuration(const Duration(milliseconds: 800), context),
    );
    if (_reducedMotion) {
      _bubbleCtrl.value = 1.0;
    } else {
      _bubbleCtrl.forward();
    }

    // ── Particles (continuous 60fps-ish, 10s cycle) ──
    _particleCtrl = AnimationController(
      vsync: this,
      duration: t.resolvedDuration(const Duration(seconds: 10), context),
    );
    if (!_reducedMotion) {
      _particleCtrl.repeat();
    }
  }

  @override
  void dispose() {
    _gradientCtrl.dispose();
    _typewriterCtrl.dispose();
    _cardsCtrl.dispose();
    _ringCtrl.dispose();
    _pulseCtrl.dispose();
    _bubbleCtrl.dispose();
    _particleCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  // ── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final w = size.width;
    final h = size.height;
    final isCompact = w < 400;

    return Scaffold(
      body: Stack(
        children: [
          // ── Layer 0: Animated gradient background (parallax slower) ──
          AnimatedBuilder(
            animation: _gradientAnim,
            builder: (ctx, _) {
              final t = _gradientAnim.value;
              return Transform.translate(
                offset: Offset(0, -_scrollOffset * 0.15),
                child: Container(
                  width: double.infinity,
                  height: h + 100,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color.lerp(
                          const Color(0xFFF97316),
                          const Color(0xFF7C3AED),
                          t,
                        )!,
                        Color.lerp(
                          const Color(0xFF7C3AED),
                          const Color(0xFFF97316),
                          t,
                        )!,
                      ],
                      stops: const [0.0, 1.0],
                    ),
                  ),
                ),
              );
            },
          ),

          // ── Layer 1: Dark overlay to keep text readable ──
          Transform.translate(
            offset: Offset(0, -_scrollOffset * 0.12),
            child: Container(
              width: double.infinity,
              height: h + 100,
              color: DigitalAtelierTokens.background.withValues(alpha: 0.82),
            ),
          ),

          // ── Layer 2: Particles (parallax slower) ──
          AnimatedBuilder(
            animation: _particleCtrl,
            builder: (ctx, _) {
              return Transform.translate(
                offset: Offset(0, -_scrollOffset * 0.08),
                child: CustomPaint(
                  size: Size(w, h + 100),
                  painter: _ParticlePainter(
                    progress: _particleCtrl.value,
                    seed: 42,
                  ),
                ),
              );
            },
          ),

          // ── Layer 3: Content (normal scroll speed) ──
          SafeArea(
            child: SingleChildScrollView(
              controller: _scrollCtrl,
              padding: EdgeInsets.symmetric(
                horizontal: isCompact ? 20 : 28,
                vertical: 28,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Brand mark
                  TransformFitBrandMark(width: isCompact ? 150 : 180),
                  SizedBox(height: h * 0.035),

                  // ── Typewriter value claim ──
                  Semantics(
                    header: true,
                    label: 'Coach value claim',
                    excludeSemantics: true,
                    child: AnimatedBuilder(
                      animation: _typewriterCharCount,
                      builder: (ctx, _) {
                        final text = LandingScreen._valueClaim
                            .substring(0, _typewriterCharCount.value);
                        return Text(
                          text,
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium!
                              .copyWith(
                                fontFamily:
                                    DigitalAtelierTokens.coachVoiceFontFamily,
                                fontSize: isCompact ? 30 : 40,
                              ),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: h * 0.04),

                  // ── Readiness score ring ──
                  Semantics(
                    label: 'Readiness preview',
                    excludeSemantics: true,
                    child: _buildReadinessSection(context, w),
                  ),
                  SizedBox(height: h * 0.04),

                  // ── Coach persona preview bubble ──
                  Semantics(
                    label: 'Coach preview',
                    excludeSemantics: true,
                    child: _buildCoachBubble(context, w),
                  ),
                  SizedBox(height: h * 0.04),

                  // ── Feature stack heading ──
                  Semantics(
                    header: true,
                    label: 'Feature stack heading',
                    excludeSemantics: true,
                    child: Text(
                      'What you get',
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(
                            fontFamily:
                                DigitalAtelierTokens.coachVoiceFontFamily,
                          ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Staggered feature cards ──
                  Semantics(
                    label: 'Feature stack',
                    excludeSemantics: true,
                    container: true,
                    child: Column(
                      children: [
                        _buildStaggeredCard(
                          index: 0,
                          icon: Icons.speed,
                          text: LandingScreen._featureReadiness,
                        ),
                        const SizedBox(height: 12),
                        _buildStaggeredCard(
                          index: 1,
                          icon: Icons.record_voice_over,
                          text: LandingScreen._featureCoachVoice,
                        ),
                        const SizedBox(height: 12),
                        _buildStaggeredCard(
                          index: 2,
                          icon: Icons.trending_up,
                          text: LandingScreen._featureProgression,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: h * 0.05),

                  // ── Pulsing Begin button ──
                  Semantics(
                    button: true,
                    label: 'Begin onboarding',
                    excludeSemantics: true,
                    child: _buildBeginButton(context),
                  ),
                  const SizedBox(height: 16),

                  // ── Sign in link ──
                  Center(
                    child: Semantics(
                      button: true,
                      label: 'Sign in to existing account',
                      excludeSemantics: true,
                      child: TextButton(
                        onPressed: () => context.go('/auth'),
                        child: const Text('Sign in'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Readiness ring section ─────────────────────────────────────────────

  Widget _buildReadinessSection(BuildContext context, double screenW) {
    final ringSize = screenW < 400 ? 100.0 : 120.0;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Ring
        AnimatedBuilder(
          animation: _ringAnim,
          builder: (ctx, _) {
            return CustomPaint(
              size: Size(ringSize, ringSize),
              painter: _ReadinessRingPainter(
                progress: _ringAnim.value,
                targetScore: 78,
              ),
            );
          },
        ),
        const SizedBox(width: 20),
        // Description card
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF151515),
              borderRadius:
                  BorderRadius.circular(DigitalAtelierTokens.cornerRadius),
              border: Border.all(
                color: DigitalAtelierTokens.accentOrange.withValues(alpha: 0.4),
                width: 1,
              ),
            ),
            child: Text(
              LandingScreen._readinessPreviewBody,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
      ],
    );
  }

  // ── Coach persona bubble ──────────────────────────────────────────────

  Widget _buildCoachBubble(BuildContext context, double screenW) {
    return AnimatedBuilder(
      animation: _bubbleCtrl,
      builder: (ctx, child) {
        final rawT = _bubbleCtrl.value;
        final t = CurvedAnimation(
          parent: AlwaysStoppedAnimation<double>(rawT),
          curve: Curves.elasticOut,
        ).value;
        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - t)),
            child: child,
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: DigitalAtelierTokens.accentOrange.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar circle
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFF97316),
                    Color(0xFF7C3AED),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF97316).withValues(alpha: 0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Coach',
                    style: TextStyle(
                      fontFamily: DigitalAtelierTokens.coachVoiceFontFamily,
                      color: DigitalAtelierTokens.accentOrange,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '"I see you slept 5 hours last night. Let\'s swap '
                    'today\'s heavy set for volume work — you\'ll still '
                    'progress, and your joints will thank you."',
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          fontFamily: DigitalAtelierTokens.coachVoiceFontFamily,
                          fontStyle: FontStyle.italic,
                          height: 1.5,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Staggered feature card ────────────────────────────────────────────

  Widget _buildStaggeredCard({
    required int index,
    required IconData icon,
    required String text,
  }) {
    // Each card appears after a delay based on its index
    final delay = index * 0.25; // 0, 0.25, 0.5 normalized
    return AnimatedBuilder(
      animation: _cardsCtrl,
      builder: (ctx, child) {
        // Stagger: compute per-card t
        final raw = _cardsCtrl.value;
        final t = ((raw - delay) / (1.0 - delay)).clamp(0.0, 1.0);
        final curved = CurvedAnimation(
          parent: AlwaysStoppedAnimation<double>(t),
          curve: Curves.easeOutCubic,
        ).value;
        return Opacity(
          opacity: curved,
          child: Transform.translate(
            offset: Offset(0, 40 * (1 - curved)),
            child: child,
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF151515),
          borderRadius:
              BorderRadius.circular(DigitalAtelierTokens.cornerRadius),
          border: Border.all(
            color: DigitalAtelierTokens.accentOrange.withValues(alpha: 0.25),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: DigitalAtelierTokens.accentOrange),
            const SizedBox(width: 14),
            Expanded(
              child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
            ),
          ],
        ),
      ),
    );
  }

  // ── Pulsing Begin button ──────────────────────────────────────────────

  Widget _buildBeginButton(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (ctx, _) {
        final glow = _pulseCtrl.value;
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(DigitalAtelierTokens.cornerRadius),
            boxShadow: [
              BoxShadow(
                color: DigitalAtelierTokens.accentOrange
                    .withValues(alpha: 0.15 + 0.25 * glow),
                blurRadius: 16 + 12 * glow,
                spreadRadius: 2 + 3 * glow,
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: () => context.go('/onboarding/welcome'),
            style: ElevatedButton.styleFrom(
              backgroundColor: DigitalAtelierTokens.accentOrange,
              foregroundColor: DigitalAtelierTokens.background,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(DigitalAtelierTokens.cornerRadius),
              ),
            ),
            child: Text(
              'Begin',
              style: TextStyle(
                fontFamily: DigitalAtelierTokens.dataFontFamily,
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: DigitalAtelierTokens.background,
              ),
            ),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Custom painters
// ═══════════════════════════════════════════════════════════════════════════

/// Floating particle dots in the background.
class _ParticlePainter extends CustomPainter {
  _ParticlePainter({
    required this.progress,
    required this.seed,
  });

  final double progress; // 0..1 repeating
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(seed);
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < 35; i++) {
      final baseX = rng.nextDouble() * size.width;
      final baseY = rng.nextDouble() * size.height;
      final speed = 0.3 + rng.nextDouble() * 0.7;
      final radius = 1.2 + rng.nextDouble() * 2.0;
      final phase = rng.nextDouble();

      // Each particle drifts upward at its own speed, wrapping
      final dy = (progress * speed * size.height * 0.3 + phase * size.height) %
          size.height;
      final dx = math.sin(progress * math.pi * 2 + phase * math.pi * 2) * 12;

      final x = baseX + dx;
      final y = baseY - dy;
      final opacity = 0.12 + 0.18 * math.sin(progress * math.pi * 2 + phase);

      paint.color = Colors.white.withValues(alpha: opacity.clamp(0.05, 0.35));
      canvas.drawCircle(Offset(x, y % size.height), radius, paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.progress != progress;
}

/// Animated readiness ring with a numeric score in the center.
class _ReadinessRingPainter extends CustomPainter {
  _ReadinessRingPainter({
    required this.progress,
    required this.targetScore,
  });

  final double progress; // 0..1
  final int targetScore;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;

    // Track (dark ring)
    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF2A2A2A);
    canvas.drawCircle(center, radius, trackPaint);

    // Progress arc
    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..shader = const SweepGradient(
        colors: [
          Color(0xFFF97316),
          Color(0xFFFF8C42),
          Color(0xFF7C3AED),
        ],
        startAngle: -math.pi / 2,
        endAngle: math.pi * 1.5,
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    final sweep = progress * (targetScore / 100) * 2 * math.pi;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweep,
      false,
      arcPaint,
    );

    // Glow at the leading edge
    if (progress > 0.01) {
      final angle = -math.pi / 2 + sweep;
      final glowCenter = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      final glowPaint = Paint()
        ..color = const Color(0xFFF97316).withValues(alpha: 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(glowCenter, 5, glowPaint);
    }

    // Score text
    final displayedScore = (targetScore * progress).round();
    final tp = TextPainter(
      text: TextSpan(
        text: '$displayedScore',
        style: TextStyle(
          fontFamily: DigitalAtelierTokens.dataFontFamily,
          fontSize: size.width * 0.28,
          fontWeight: FontWeight.w700,
          color: DigitalAtelierTokens.textPrimary,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    tp.paint(
      canvas,
      Offset(center.dx - tp.width / 2, center.dy - tp.height / 2),
    );

    // Label below score
    const label = 'READY';
    final lp = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          fontFamily: DigitalAtelierTokens.dataFontFamily,
          fontSize: size.width * 0.1,
          fontWeight: FontWeight.w500,
          color: DigitalAtelierTokens.textPrimary.withValues(alpha: 0.5),
          letterSpacing: 2,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    lp.paint(
      canvas,
      Offset(center.dx - lp.width / 2, center.dy + tp.height * 0.35),
    );
  }

  @override
  bool shouldRepaint(_ReadinessRingPainter old) => old.progress != progress;
}
