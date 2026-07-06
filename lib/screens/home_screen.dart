import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:transformfit/app_providers.dart';
import 'package:transformfit/features/session/models.dart';
import 'package:transformfit/features/session/session_controller.dart';
import 'package:transformfit/theme/digital_atelier.dart';
import 'package:transformfit/widgets/tf_progress_ring.dart';
import 'package:transformfit/widgets/hero_background.dart';

/// Home screen — Whoop-inspired single-hero layout.
///
/// One massive readiness ring (60% viewport) + 3 compact action cards +
/// one-line coach hint. No section headers, no weekly summary, no shimmer.
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
        color: DigitalAtelierTokens.accentOrange,
        backgroundColor: DigitalAtelierTokens2.surfaceElevated,
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenHeight = constraints.maxHeight;
        final heroSize = (screenHeight * 0.6).clamp(200.0, 400.0);

        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Padding(
                padding: EdgeInsets.only(top: 24, bottom: 24),
                child: Text('Today', style: _Tokens._h1),
              ),

              // Hero: Readiness Ring
              _ReadinessHero(
                readiness: session.readinessEntry,
                size: heroSize,
              ),

              const SizedBox(height: 24),

              // 3 Action Cards
              _ActionCards(),

              const SizedBox(height: 16),

              // Coach Hint
              const _CoachHint(),

              const SizedBox(height: 48),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Design tokens shorthand (avoids repeated extension lookups in stateless code)
// ---------------------------------------------------------------------------

abstract class _Tokens {
  static const _h1 = TextStyle(
    fontFamily: 'Inter',
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.2,
    color: Colors.white,
  );

  static const _dataLarge = TextStyle(
    fontFamily: 'Inter',
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    height: 1.1,
    fontFeatures: [FontFeature.tabularFigures()],
    color: Colors.white,
  );

  static const _label = TextStyle(
    fontFamily: 'Inter',
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.0,
    height: 1.2,
    color: Color(0xFF6B7280),
  );

  static const _bodySmall = TextStyle(
    fontFamily: 'Inter',
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: Color(0xFF9CA3AF),
  );

  static const _coachHint = TextStyle(
    fontFamily: 'Playfair',
    fontSize: 14,
    fontWeight: FontWeight.w500,
    fontStyle: FontStyle.italic,
    height: 1.4,
    color: Color(0xFF9CA3AF),
  );
}

// ---------------------------------------------------------------------------
// Readiness Hero — centered ring + score + zone label + trend arrow
// ---------------------------------------------------------------------------

class _ReadinessHero extends StatelessWidget {
  const _ReadinessHero({required this.readiness, required this.size});

  final ReadinessEntry? readiness;
  final double size;

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
            // Ring
            score != null
                ? TfProgressRing(
                    value: score / 100,
                    size: size,
                    strokeWidth: 10,
                    label: '$score',
                    textStyle: _Tokens._dataLarge.copyWith(
                      fontSize: size * 0.2,
                    ),
                    semanticLabel: 'Readiness $score percent',
                  )
                : SizedBox(
                    width: size,
                    height: size,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.help_outline,
                            size: size * 0.25,
                            color: const Color(0xFF6B7280),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Check In',
                            style: _Tokens._bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),

            const SizedBox(height: 12),

            // Zone label
            if (zone != null)
              Text(
                _zoneLabel(zone).toUpperCase(),
                style: _Tokens._label,
              ),

            // Trend arrow
            if (score != null) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _trendIcon(zone),
                    size: 14,
                    color: _trendColor(zone),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _trendText(zone),
                    style: _Tokens._bodySmall.copyWith(
                      color: _trendColor(zone),
                    ),
                  ),
                ],
              ),
            ],
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

  IconData _trendIcon(String? zone) {
    switch (zone) {
      case 'peak':
        return Icons.arrow_upward;
      case 'moderate':
        return Icons.arrow_forward;
      case 'deload':
        return Icons.arrow_downward;
      default:
        return Icons.remove;
    }
  }

  Color _trendColor(String? zone) {
    switch (zone) {
      case 'peak':
        return const Color(0xFF10B981);
      case 'moderate':
        return const Color(0xFF3B82F6);
      case 'deload':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF6B7280);
    }
  }

  String _trendText(String? zone) {
    switch (zone) {
      case 'peak':
        return 'Trending up';
      case 'moderate':
        return 'Steady';
      case 'deload':
        return 'Recovery mode';
      default:
        return 'No trend data';
    }
  }
}

// ---------------------------------------------------------------------------
// Action Cards — 3 equal-width cards in a Row
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
              label: 'Workout',
              semanticLabel: 'Start workout',
              onTap: () => context.push('/workout'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _ActionCard(
              icon: Icons.mood,
              label: 'Log Mood',
              semanticLabel: 'Log mood',
              onTap: () {},
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _ActionCard(
              icon: Icons.chat_bubble_outline,
              label: 'Coach Chat',
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
    required this.label,
    required this.semanticLabel,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      button: true,
      child: Material(
        color: DigitalAtelierTokens2.surface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 24, color: const Color(0xFF9CA3AF)),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Coach Hint — single italic line from last coach message
// ---------------------------------------------------------------------------

class _CoachHint extends ConsumerWidget {
  const _CoachHint();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signal = ref.watch(coachSignalProvider);

    if (signal.coachNote.isEmpty) return const SizedBox.shrink();

    return Semantics(
      label: 'Coach hint: ${signal.coachNote}',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text(
          signal.coachNote,
          style: _Tokens._coachHint,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
