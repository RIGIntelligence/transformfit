import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:transformfit/widgets/tf_progress_ring.dart';

// ---------------------------------------------------------------------------
// Wellness Dashboard — v4 Design System
//
// Recovery circle (240px) + 3 metric cards (Mood, Stress, Sleep).
// Each card: icon + value + trend arrow. 12px gap, no borders.
// ---------------------------------------------------------------------------

class WellnessDashboardScreen extends ConsumerStatefulWidget {
  const WellnessDashboardScreen({super.key});

  @override
  ConsumerState<WellnessDashboardScreen> createState() =>
      _WellnessDashboardScreenState();
}

class _WellnessDashboardScreenState
    extends ConsumerState<WellnessDashboardScreen> {
  // Demo state — in production these come from providers.
  final double _overallScore = 72;
  final String _overallZone = 'maintaining';

  final List<_MetricData> _metrics = const [
    _MetricData(
      title: 'Mood',
      icon: Icons.emoji_emotions_outlined,
      score: 78,
      color: Color(0xFF22C55E),
      trend: _TrendDirection.up,
    ),
    _MetricData(
      title: 'Stress',
      icon: Icons.self_improvement,
      score: 62,
      color: Color(0xFFF59E0B),
      trend: _TrendDirection.down,
    ),
    _MetricData(
      title: 'Sleep',
      icon: Icons.bedtime_outlined,
      score: 81,
      color: Color(0xFF3B82F6),
      trend: _TrendDirection.up,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Wellness dashboard screen',
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0A0A),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0A0A0A),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          leading: Semantics(
            label: 'Back',
            button: true,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).maybePop(),
              tooltip: 'Back',
            ),
          ),
          title: const Text(
            'Wellness',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const SizedBox(height: 16),

                // Hero: Wellness Ring — 240px centered
                _WellnessHero(
                  score: _overallScore,
                  zone: _overallZone,
                ),

                const SizedBox(height: 32),

                // 3 Metric Cards — 12px gap, no borders
                Row(
                  children: [
                    Expanded(child: _MetricCard(metric: _metrics[0])),
                    const SizedBox(width: 12),
                    Expanded(child: _MetricCard(metric: _metrics[1])),
                    const SizedBox(width: 12),
                    Expanded(child: _MetricCard(metric: _metrics[2])),
                  ],
                ),

                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Wellness Hero — 240px centered ring + score + zone + trend
// ---------------------------------------------------------------------------

class _WellnessHero extends StatelessWidget {
  const _WellnessHero({
    required this.score,
    required this.zone,
  });

  final double score;
  final String zone;

  static const double _ringSize = 240.0;

  @override
  Widget build(BuildContext context) {
    final zoneColor = _zoneColor(zone);

    return Semantics(
      label:
          'Overall wellness score: ${score.toStringAsFixed(0)} out of 100, zone: $zone',
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TfProgressRing(
              value: score / 100,
              size: _ringSize,
              strokeWidth: 10,
              label: score.toStringAsFixed(0),
              textStyle: TextStyle(
                fontFamily: 'Inter',
                fontSize: _ringSize * 0.2,
                fontWeight: FontWeight.w700,
                color: zoneColor,
                letterSpacing: -0.5,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
              semanticLabel: 'Wellness score ${score.toStringAsFixed(0)}',
            ),
            const SizedBox(height: 12),
            // Zone label — 15px, secondary color
            Text(
              _zoneLabel(zone).toUpperCase(),
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Color(0xFF8E8E93),
              ),
            ),
            const SizedBox(height: 4),
            // Trend
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
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: _trendColor(zone),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _zoneLabel(String zone) {
    switch (zone) {
      case 'thriving':
        return 'Thriving';
      case 'maintaining':
        return 'Maintaining';
      case 'recovering':
        return 'Recovering';
      case 'needsAttention':
        return 'Needs Attention';
      default:
        return zone;
    }
  }

  Color _zoneColor(String zone) {
    switch (zone) {
      case 'thriving':
        return const Color(0xFF30D158);
      case 'maintaining':
        return const Color(0xFF3B82F6);
      case 'recovering':
        return const Color(0xFFF59E0B);
      case 'needsAttention':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFFFF6B35);
    }
  }

  IconData _trendIcon(String zone) {
    switch (zone) {
      case 'thriving':
        return Icons.arrow_upward;
      case 'maintaining':
        return Icons.arrow_forward;
      case 'recovering':
      case 'needsAttention':
        return Icons.arrow_downward;
      default:
        return Icons.remove;
    }
  }

  Color _trendColor(String zone) {
    switch (zone) {
      case 'thriving':
        return const Color(0xFF30D158);
      case 'maintaining':
        return const Color(0xFF3B82F6);
      case 'recovering':
        return const Color(0xFFF59E0B);
      case 'needsAttention':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF8E8E93);
    }
  }

  String _trendText(String zone) {
    switch (zone) {
      case 'thriving':
        return 'Trending up';
      case 'maintaining':
        return 'Steady';
      case 'recovering':
        return 'Recovery mode';
      case 'needsAttention':
        return 'Needs focus';
      default:
        return 'No data';
    }
  }
}

// ---------------------------------------------------------------------------
// Metric Card — icon + value + trend arrow, no border
// ---------------------------------------------------------------------------

enum _TrendDirection { up, down, flat }

class _MetricData {
  const _MetricData({
    required this.title,
    required this.icon,
    required this.score,
    required this.color,
    required this.trend,
  });

  final String title;
  final IconData icon;
  final int score;
  final Color color;
  final _TrendDirection trend;
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.metric});

  final _MetricData metric;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${metric.title}: ${metric.score}',
      button: true,
      child: Material(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Icon(metric.icon, size: 28, color: metric.color),
                const SizedBox(height: 8),
                // Value
                Text(
                  '${metric.score}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                    height: 1.2,
                    fontFeatures: [FontFeature.tabularFigures()],
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                // Label
                Text(
                  metric.title,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF8E8E93),
                  ),
                ),
                const SizedBox(height: 8),
                // Trend arrow
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _trendIcon(metric.trend),
                      size: 12,
                      color: _trendColor(metric.trend),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      _trendLabel(metric.trend),
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: _trendColor(metric.trend),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _trendIcon(_TrendDirection dir) {
    switch (dir) {
      case _TrendDirection.up:
        return Icons.arrow_upward;
      case _TrendDirection.down:
        return Icons.arrow_downward;
      case _TrendDirection.flat:
        return Icons.remove;
    }
  }

  Color _trendColor(_TrendDirection dir) {
    switch (dir) {
      case _TrendDirection.up:
        return const Color(0xFF30D158);
      case _TrendDirection.down:
        return const Color(0xFFF59E0B);
      case _TrendDirection.flat:
        return const Color(0xFF8E8E93);
    }
  }

  String _trendLabel(_TrendDirection dir) {
    switch (dir) {
      case _TrendDirection.up:
        return 'Up';
      case _TrendDirection.down:
        return 'Down';
      case _TrendDirection.flat:
        return 'Flat';
    }
  }
}
