import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:transformfit/features/session/models.dart';
import 'package:transformfit/features/session/session_controller.dart';

import 'package:transformfit/widgets/tf_progress_ring.dart';
import 'package:transformfit/widgets/hero_background.dart';

/// Home screen — v4 Design System.
///
/// Recovery circle (280px) + 3 action cards + pull-to-refresh.
/// No section headers, no weekly summary, no shimmer loading.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionStateProvider);

    return Semantics(
      label: 'Today home screen',
      child: Stack(
        children: [
          // Hero AI coach background with dark overlay.
          const HeroBackground(
            assetPath: 'assets/imagery/hero_ai_coach.png',
            overlayOpacity: 0.85,
            cacheWidth: 800,
            cacheHeight: 600,
          ),
          RefreshIndicator(
            color: const Color(0xFFFF6B35),
            backgroundColor: const Color(0xFF1C1C1C),
            onRefresh: () async {
              await Future<void>.delayed(const Duration(milliseconds: 400));
            },
            child: _buildContent(context, session),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, SessionState session) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),

          // Hero: Readiness Ring — 280px centered
          _ReadinessHero(readiness: session.readinessEntry),

          const SizedBox(height: 24),

          // 3 Action Cards — 12px gap
          _ActionCards(),

          const SizedBox(height: 48),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Readiness Hero — 280px centered ring + score + zone label
// ---------------------------------------------------------------------------

class _ReadinessHero extends StatelessWidget {
  const _ReadinessHero({required this.readiness});

  final ReadinessEntry? readiness;

  static const double _ringSize = 280.0;

  @override
  Widget build(BuildContext context) {
    final score = readiness?.score;
    final zone = readiness?.zone;

    return Semantics(
      label: score != null
          ? 'Readiness score: $score, zone: ${zone ?? "unknown"}'
          : 'Readiness not yet checked',
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ring — 280px
            score != null
                ? TfProgressRing(
                    value: score / 100,
                    size: _ringSize,
                    strokeWidth: 10,
                    label: '$score',
                    textStyle: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 56,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    semanticLabel: 'Readiness $score percent',
                  )
                : SizedBox(
                    width: _ringSize,
                    height: _ringSize,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.help_outline,
                            size: _ringSize * 0.25,
                            color: const Color(0xFF8E8E93),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Check In',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 15,
                              color: Color(0xFF8E8E93),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

            const SizedBox(height: 12),

            // Zone label — Inter 15px, secondary color
            if (zone != null)
              Text(
                _zoneLabel(zone).toUpperCase(),
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF8E8E93),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _zoneLabel(String zone) {
    switch (zone) {
      case 'peak':
        return 'Peak';
      case 'moderate':
        return 'Moderate';
      case 'deload':
        return 'Deload';
      default:
        return zone;
    }
  }
}

// ---------------------------------------------------------------------------
// Action Cards — 3 cards with 12px gap, no border, surface bg
// ---------------------------------------------------------------------------

class _ActionCards extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Quick actions',
      child: Row(
        children: [
          Expanded(
            child: _ActionCard(
              icon: Icons.fitness_center,
              iconColor: const Color(0xFFFF6B35),
              label: 'Start Workout',
              subtitle: 'Begin session',
              semanticLabel: 'Start workout',
              onTap: () => context.push('/workout'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _ActionCard(
              icon: Icons.mood,
              iconColor: const Color(0xFF8B5CF6),
              label: 'Log Mood',
              subtitle: 'Track feelings',
              semanticLabel: 'Log mood',
              onTap: () {},
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _ActionCard(
              icon: Icons.chat_bubble_outline,
              iconColor: const Color(0xFF3B82F6),
              label: 'Coach Chat',
              subtitle: 'Get guidance',
              semanticLabel: 'Open coach chat',
              onTap: () => context.push('/coach-chat'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.subtitle,
    required this.semanticLabel,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String subtitle;
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      button: true,
      child: Material(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 24, color: iconColor),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF8E8E93),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
