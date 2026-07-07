import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:transformfit/theme/digital_atelier.dart';

// ---------------------------------------------------------------------------
// MoT1 — Acquisition to first belief.
//
// Cinematic landing surface. Full-screen hero background, staggered fade-in
// headline → subtitle → CTA, no scrolling required. Immersive.
// ---------------------------------------------------------------------------

class LandingScreen extends ConsumerWidget {
  const LandingScreen({super.key});

  // ── Copy ───────────────────────────────────────────────────────────────
  static const _headline = 'A coach who already noticed.';
  static const _subtitle =
      'Before you log a single rep, we built your plan.';

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
  // Staggered fade-in controllers
  late final AnimationController _titleCtrl;
  late final AnimationController _subtitleCtrl;
  late final AnimationController _ctaCtrl;

  // CTA pulse
  late final AnimationController _pulseCtrl;

  bool _animationsInitialized = false;
  bool _reducedMotion = false;

  @override
  void initState() {
    super.initState();
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

    // ── Title fade-in (300ms) ──
    _titleCtrl = AnimationController(
      vsync: this,
      duration: t.resolvedDuration(const Duration(milliseconds: 300), context),
    );
    if (_reducedMotion) {
      _titleCtrl.value = 1.0;
    } else {
      _titleCtrl.forward();
    }

    // ── Subtitle fade-in (600ms, starts after title) ──
    _subtitleCtrl = AnimationController(
      vsync: this,
      duration: t.resolvedDuration(const Duration(milliseconds: 600), context),
    );
    if (_reducedMotion) {
      _subtitleCtrl.value = 1.0;
    } else {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _subtitleCtrl.forward();
      });
    }

    // ── CTA fade-in (900ms, starts after subtitle) ──
    _ctaCtrl = AnimationController(
      vsync: this,
      duration: t.resolvedDuration(const Duration(milliseconds: 900), context),
    );
    if (_reducedMotion) {
      _ctaCtrl.value = 1.0;
    } else {
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) _ctaCtrl.forward();
      });
    }

    // ── CTA pulse (1s cycle, infinite) ──
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: t.resolvedDuration(const Duration(milliseconds: 1000), context),
    );
    if (!_reducedMotion) {
      // Start pulse after CTA appears
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) _pulseCtrl.repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _subtitleCtrl.dispose();
    _ctaCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  // ── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final h = size.height;

    return Scaffold(
      body: Stack(
        children: [
          // ── Layer 0: Hero workout background image ──
          SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: Image.asset(
              'assets/imagery/hero_workout.png',
              fit: BoxFit.cover,
              cacheWidth: 1080,
              cacheHeight: 1920,
            ),
          ),

          // ── Layer 1: Dark overlay (70% opacity) ──
          Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.black.withValues(alpha: 0.70),
          ),

          // ── Layer 2: Content ──
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  SizedBox(height: h * 0.22),

                  // ── Headline: fade in 300ms ──
                  FadeTransition(
                    opacity: _titleCtrl,
                    child: Semantics(
                      header: true,
                      label: 'Headline',
                      excludeSemantics: true,
                      child: Text(
                        LandingScreen._headline,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Subtitle: fade in 600ms ──
                  FadeTransition(
                    opacity: _subtitleCtrl,
                    child: Semantics(
                      label: 'Subtitle',
                      excludeSemantics: true,
                      child: Text(
                        LandingScreen._subtitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 17,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF8E8E93),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),

                  const Spacer(),

                  // ── CTA: fade in 900ms, then pulse ──
                  FadeTransition(
                    opacity: _ctaCtrl,
                    child: _buildBeginButton(context),
                  ),

                  const SizedBox(height: 16),

                  // ── Sign in ghost button ──
                  FadeTransition(
                    opacity: _ctaCtrl,
                    child: Center(
                      child: Semantics(
                        button: true,
                        label: 'Sign in to existing account',
                        excludeSemantics: true,
                        child: TextButton(
                          onPressed: () => context.go('/auth'),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF8E8E93),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                          child: const Text(
                            'Sign in to existing account',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: MediaQuery.of(context).padding.bottom + 32),
                ],
              ),
            ),
          ),
        ],
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
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF6B35)
                    .withValues(alpha: 0.15 + 0.25 * glow),
                blurRadius: 16 + 12 * glow,
                spreadRadius: 2 + 3 * glow,
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: () => context.go('/onboarding/welcome'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B35),
              foregroundColor: Colors.black,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Begin',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),
        );
      },
    );
  }
}
