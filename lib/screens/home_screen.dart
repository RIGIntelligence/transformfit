import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:transformfit/app_providers.dart';
import 'package:transformfit/features/session/models.dart';
import 'package:transformfit/features/session/session_controller.dart';
import 'package:transformfit/theme/digital_atelier.dart';
import 'package:transformfit/widgets/tf_progress_ring.dart';

/// Clean home screen — replaces the god-widget TodayScreen for the home tab.
///
/// 5 compact cards, each a separate widget:
///   1. ReadinessScoreCard
///   2. TodaysPlanCard
///   3. CoachInsightCard
///   4. QuickActionsRow
///   5. WeeklySummaryCard
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionStateProvider);

    return Semantics(
      label: 'Today home screen',
      child: RefreshIndicator(
        color: DigitalAtelierTokens.accentOrange,
        backgroundColor: DigitalAtelierTokens2.surfaceElevated,
        onRefresh: () async {
          // Refresh will be wired to a real data reload once the
          // persistence layer is connected.
          await Future<void>.delayed(const Duration(milliseconds: 400));
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            const SliverToBoxAdapter(child: _HomeHeader()),
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: DigitalAtelierTokens2.s4,
              ),
              sliver: SliverList.list(
                children: [
                  const SizedBox(height: DigitalAtelierTokens2.s3),
                  ReadinessScoreCard(readiness: session.readinessEntry),
                  const SizedBox(height: DigitalAtelierTokens2.s3),
                  TodaysPlanCard(session: session),
                  const SizedBox(height: DigitalAtelierTokens2.s3),
                  const CoachInsightCard(),
                  const SizedBox(height: DigitalAtelierTokens2.s3),
                  const QuickActionsRow(),
                  const SizedBox(height: DigitalAtelierTokens2.s3),
                  WeeklySummaryCard(history: session.history),
                  const SizedBox(height: DigitalAtelierTokens2.s7),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DigitalAtelierTokens2.s4,
        DigitalAtelierTokens2.s5,
        DigitalAtelierTokens2.s4,
        DigitalAtelierTokens2.s2,
      ),
      child: Semantics(
        header: true,
        label: 'Today heading',
        child: Text(
          'Today',
          style: DigitalAtelierTokens2.headlineLarge.copyWith(
            color: DigitalAtelierTokens.textPrimary,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 1. Readiness Score
// ---------------------------------------------------------------------------

class ReadinessScoreCard extends StatelessWidget {
  const ReadinessScoreCard({super.key, required this.readiness});

  final ReadinessEntry? readiness;

  @override
  Widget build(BuildContext context) {
    final score = readiness?.score;
    final zone = readiness?.zone;

    return _HomeCard(
      semanticLabel: score != null
          ? 'Readiness score: $score, zone: ${zone ?? "unknown"}'
          : 'Readiness not yet checked',
      child: Row(
        children: [
          score != null
              ? TfProgressRing(
                  value: score / 100,
                  size: 80,
                  strokeWidth: 8,
                  label: '$score',
                  semanticLabel: 'Readiness $score percent',
                )
              : const SizedBox(
                  width: 80,
                  height: 80,
                  child: Center(
                    child: Icon(
                      Icons.help_outline,
                      size: 36,
                      color: Color(0xFFA0A0A0),
                    ),
                  ),
                ),
          const SizedBox(width: DigitalAtelierTokens2.s4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  score != null ? 'Readiness' : 'Check In',
                  style: DigitalAtelierTokens2.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  zone != null ? _zoneLabel(zone) : 'Tap to start your day',
                  style: DigitalAtelierTokens2.bodySmall,
                ),
              ],
            ),
          ),
          Semantics(
            label: 'Start readiness check',
            button: true,
            child: SizedBox(
              height: 44,
              width: 44,
              child: IconButton(
                icon: const Icon(Icons.chevron_right),
                color: DigitalAtelierTokens.accentOrange,
                onPressed: () {
                  // Navigate to readiness flow
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _zoneLabel(String zone) {
    switch (zone) {
      case 'peak':
        return 'Peak — go hard today';
      case 'moderate':
        return 'Moderate — steady work';
      case 'deload':
        return 'Deload — keep it light';
      default:
        return zone;
    }
  }
}

// ---------------------------------------------------------------------------
// 2. Today's Plan
// ---------------------------------------------------------------------------

class TodaysPlanCard extends StatelessWidget {
  const TodaysPlanCard({super.key, required this.session});

  final SessionState session;

  @override
  Widget build(BuildContext context) {
    final hasActive = session.activeSession != null;
    final plan = session.activeSessionPlan;

    return _HomeCard(
      semanticLabel: hasActive
          ? 'Active session in progress'
          : 'Today\'s workout plan',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasActive ? Icons.play_circle : Icons.event_note,
                color: DigitalAtelierTokens.accentOrange,
                size: 20,
              ),
              const SizedBox(width: DigitalAtelierTokens2.s2),
              Text(
                hasActive ? 'Session In Progress' : 'Today\'s Plan',
                style: DigitalAtelierTokens2.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: DigitalAtelierTokens2.s2),
          Text(
            hasActive
                ? '${plan.length} exercises queued. Pick up where you left off.'
                : 'No active session. Start when you\'re ready.',
            style: DigitalAtelierTokens2.bodyMedium.copyWith(
              color: const Color(0xFFA0A0A0),
            ),
          ),
          const SizedBox(height: DigitalAtelierTokens2.s3),
          SizedBox(
            width: double.infinity,
            child: Semantics(
              label: hasActive ? 'Resume workout' : 'Start workout',
              button: true,
              child: ElevatedButton(
                onPressed: () => context.push('/workout'),
                child: Text(hasActive ? 'Resume' : 'Start Workout'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 3. Coach Insight
// ---------------------------------------------------------------------------

class CoachInsightCard extends ConsumerWidget {
  const CoachInsightCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signal = ref.watch(coachSignalProvider);

    return _HomeCard(
      semanticLabel: signal.semanticLabel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome,
                color: DigitalAtelierTokens.accentOrange,
                size: 18,
              ),
              const SizedBox(width: DigitalAtelierTokens2.s2),
              Text(
                '${signal.personaLabel} Coach',
                style: DigitalAtelierTokens2.labelLarge.copyWith(
                  color: DigitalAtelierTokens.accentOrange,
                ),
              ),
              const Spacer(),
              Text(
                signal.confidenceLabel,
                style: DigitalAtelierTokens2.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: DigitalAtelierTokens2.s2),
          Text(
            signal.coachNote,
            style: DigitalAtelierTokens2.bodyMedium,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 4. Quick Actions
// ---------------------------------------------------------------------------

class QuickActionsRow extends StatelessWidget {
  const QuickActionsRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Quick actions',
      child: Row(
        children: [
          Expanded(
            child: _QuickAction(
              icon: Icons.mood,
              label: 'Mood',
              semanticLabel: 'Log mood',
              onTap: () {},
            ),
          ),
          const SizedBox(width: DigitalAtelierTokens2.s2),
          Expanded(
            child: _QuickAction(
              icon: Icons.water_drop,
              label: 'Water',
              semanticLabel: 'Log water intake',
              onTap: () {},
            ),
          ),
          const SizedBox(width: DigitalAtelierTokens2.s2),
          Expanded(
            child: _QuickAction(
              icon: Icons.fitness_center,
              label: 'Workout',
              semanticLabel: 'Start workout',
              onTap: () => context.push('/workout'),
            ),
          ),
          const SizedBox(width: DigitalAtelierTokens2.s2),
          Expanded(
            child: _QuickAction(
              icon: Icons.chat_bubble_outline,
              label: 'Coach',
              semanticLabel: 'Open coach chat',
              onTap: () => context.push('/coach-chat'),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
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
      child: SizedBox(
        height: 44,
        child: Material(
          color: DigitalAtelierTokens2.surfaceElevated,
          borderRadius: BorderRadius.circular(DigitalAtelierTokens2.radiusMd),
          child: InkWell(
            borderRadius: BorderRadius.circular(DigitalAtelierTokens2.radiusMd),
            onTap: onTap,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 20, color: DigitalAtelierTokens.accentOrange),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: DigitalAtelierTokens2.bodySmall.copyWith(fontSize: 10),
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
// 5. Weekly Summary
// ---------------------------------------------------------------------------

class WeeklySummaryCard extends StatelessWidget {
  const WeeklySummaryCard({super.key, required this.history});

  final List<WorkoutSession> history;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final thisWeek = history.where((s) {
      return s.startedAt.isAfter(weekStart);
    }).length;

    // Simple streak count — consecutive days with a completed session.
    int streak = 0;
    for (final session in history.reversed) {
      if (session.endedAt != null && session.loggedSets.isNotEmpty) {
        streak++;
      } else {
        break;
      }
    }

    return _HomeCard(
      semanticLabel: '$thisWeek workouts this week, $streak day streak',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
            value: '$thisWeek',
            label: 'This Week',
            semanticLabel: '$thisWeek workouts this week',
          ),
          Container(width: 1, height: 32, color: DigitalAtelierTokens2.surfaceBorder),
          _StatItem(
            value: '$streak',
            label: 'Streak',
            semanticLabel: '$streak day streak',
          ),
          Container(width: 1, height: 32, color: DigitalAtelierTokens2.surfaceBorder),
          const _StatItem(
            value: '—',
            label: 'XP',
            semanticLabel: 'XP progress coming soon',
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.value,
    required this.label,
    required this.semanticLabel,
  });

  final String value;
  final String label;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      child: Column(
        children: [
          Text(
            value,
            style: DigitalAtelierTokens2.dataValue.copyWith(fontSize: 24),
          ),
          const SizedBox(height: 2),
          Text(label, style: DigitalAtelierTokens2.dataLabel),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared card wrapper
// ---------------------------------------------------------------------------

class _HomeCard extends StatelessWidget {
  const _HomeCard({required this.child, required this.semanticLabel});

  final Widget child;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      container: true,
      child: Container(
        padding: const EdgeInsets.all(DigitalAtelierTokens2.s4),
        decoration: DigitalAtelierTokens2.elevatedDecoration,
        child: child,
      ),
    );
  }
}
