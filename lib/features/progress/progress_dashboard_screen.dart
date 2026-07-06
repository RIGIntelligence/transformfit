import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// StateProvider is in riverpod core, re-exported by flutter_riverpod 3.x
import 'package:transformfit/features/progress/personal_records_board.dart';
import 'package:transformfit/features/progress/recovery_trend_chart.dart';
import 'package:transformfit/features/progress/strength_progress_chart.dart';
import 'package:transformfit/features/progress/volume_chart.dart';
import 'package:transformfit/features/progress/workout_heatmap.dart';
import 'package:transformfit/features/progress/muscle_balance_radar.dart';
import 'package:transformfit/theme/digital_atelier.dart';

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class ProgressDashboardScreen extends ConsumerStatefulWidget {
  const ProgressDashboardScreen({super.key});

  @override
  ConsumerState<ProgressDashboardScreen> createState() =>
      _ProgressDashboardScreenState();
}

class _ProgressDashboardScreenState
    extends ConsumerState<ProgressDashboardScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _tabs = [
    Tab(text: 'Overview'),
    Tab(text: 'Strength'),
    Tab(text: 'Volume'),
    Tab(text: 'Recovery'),
    Tab(text: 'PRs'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    // In production this would invalidate data providers.
    await Future<void>.delayed(const Duration(milliseconds: 600));
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<DigitalAtelierExtension>()!;

    return Scaffold(
      backgroundColor: t.background,
      appBar: AppBar(
        backgroundColor: t.background,
        surfaceTintColor: Colors.transparent,
        title: Text('Progress', style: t.textTheme.h2),
        bottom: TabBar(
          controller: _tabController,
          tabs: _tabs,
          labelColor: t.accentPrimary,
          unselectedLabelColor: t.textMuted,
          indicatorColor: t.accentPrimary,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: const TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          unselectedLabelStyle: const TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
          isScrollable: true,
          tabAlignment: TabAlignment.start,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _OverviewTab(onRefresh: _onRefresh),
          _StrengthTab(onRefresh: _onRefresh),
          _VolumeTab(onRefresh: _onRefresh),
          _RecoveryTab(onRefresh: _onRefresh),
          _PRTab(onRefresh: _onRefresh),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Overview tab
// ---------------------------------------------------------------------------

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.onRefresh});
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<DigitalAtelierExtension>()!;
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: t.accentPrimary,
      child: ListView(
        padding: EdgeInsets.all(t.spaceLg),
        children: [
          _SectionHeader(title: 'This Week', t: t),
          SizedBox(height: t.spaceSm),
          const StrengthProgressChart(),
          SizedBox(height: t.spaceLg),
          const WorkoutHeatmap(),
          SizedBox(height: t.spaceLg),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth > 600;
              if (wide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Expanded(child: MuscleBalanceRadar()),
                    SizedBox(width: t.spaceLg),
                    const Expanded(child: RecoveryTrendChart()),
                  ],
                );
              }
              return Column(
                children: [
                  const MuscleBalanceRadar(),
                  SizedBox(height: t.spaceLg),
                  const RecoveryTrendChart(),
                ],
              );
            },
          ),
          SizedBox(height: t.spaceLg),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Strength tab
// ---------------------------------------------------------------------------

class _StrengthTab extends StatelessWidget {
  const _StrengthTab({required this.onRefresh});
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<DigitalAtelierExtension>()!;
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: t.accentPrimary,
      child: ListView(
        padding: EdgeInsets.all(t.spaceLg),
        children: [
          const StrengthProgressChart(),
          SizedBox(height: t.spaceLg),
          const MuscleBalanceRadar(),
          SizedBox(height: t.spaceLg),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Volume tab
// ---------------------------------------------------------------------------

class _VolumeTab extends StatelessWidget {
  const _VolumeTab({required this.onRefresh});
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<DigitalAtelierExtension>()!;
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: t.accentPrimary,
      child: ListView(
        padding: EdgeInsets.all(t.spaceLg),
        children: [
          const VolumeChart(),
          SizedBox(height: t.spaceLg),
          const WorkoutHeatmap(),
          SizedBox(height: t.spaceLg),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Recovery tab
// ---------------------------------------------------------------------------

class _RecoveryTab extends StatelessWidget {
  const _RecoveryTab({required this.onRefresh});
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<DigitalAtelierExtension>()!;
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: t.accentPrimary,
      child: ListView(
        padding: EdgeInsets.all(t.spaceLg),
        children: [
          const RecoveryTrendChart(),
          SizedBox(height: t.spaceLg),
          const WorkoutHeatmap(),
          SizedBox(height: t.spaceLg),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// PRs tab
// ---------------------------------------------------------------------------

class _PRTab extends StatelessWidget {
  const _PRTab({required this.onRefresh});
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<DigitalAtelierExtension>()!;
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: t.accentPrimary,
      child: ListView(
        padding: EdgeInsets.all(t.spaceLg),
        children: [
          const PersonalRecordsBoard(),
          SizedBox(height: t.spaceLg),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section header
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.t});
  final String title;
  final DigitalAtelierExtension t;

  @override
  Widget build(BuildContext context) {
    return Text(title, style: t.textTheme.h3);
  }
}
