import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:transformfit/theme/digital_atelier.dart';
import 'package:transformfit/widgets/tf_progress_ring.dart';

// ---------------------------------------------------------------------------
// Wellness Dashboard — Whoop-inspired recovery hero + 3 compact metrics
//
// Recovery circle (50% viewport) + Mood/Stress/Sleep cards + mini sparklines.
// No module grid, no burnout detector, no recommendations card.
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
      sparkline: [65, 70, 68, 72, 75, 74, 78],
    ),
    _MetricData(
      title: 'Stress',
      icon: Icons.self_improvement,
      score: 62,
      color: Color(0xFFF59E0B),
      trend: _TrendDirection.down,
      sparkline: [70, 68, 65, 60, 63, 61, 62],
    ),
    _MetricData(
      title: 'Sleep',
      icon: Icons.bedtime_outlined,
      score: 81,
      color: Color(0xFF3B82F6),
      trend: _TrendDirection.up,
      sparkline: [72, 75, 78, 76, 80, 79, 81],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Wellness dashboard screen',
      child: Scaffold(
        backgroundColor: DigitalAtelierTokens.background,
        appBar: AppBar(
          backgroundColor: DigitalAtelierTokens.background,
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              final heroSize = (constraints.maxHeight * 0.5).clamp(180.0, 320.0);

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 16),

                    // Hero: Wellness Ring
                    _WellnessHero(
                      score: _overallScore,
                      zone: _overallZone,
                      size: heroSize,
                    ),

                    const SizedBox(height: 32),

                    // 3 Metric Cards
                    Row(
                      children: _metrics
                          .map((m) => Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                  ),
                                  child: _MetricCard(metric: m),
                                ),
                              ))
                          .toList(),
                    ),

                    const SizedBox(height: 48),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Wellness Hero — centered ring + score + zone + trend
// ---------------------------------------------------------------------------

class _WellnessHero extends StatelessWidget {
  const _WellnessHero({
    required this.score,
    required this.zone,
    required this.size,
  });

  final double score;
  final String zone;
  final double size;

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
              size: size,
              strokeWidth: 10,
              label: score.toStringAsFixed(0),
              textStyle: TextStyle(
                fontFamily: 'Inter',
                fontSize: size * 0.2,
                fontWeight: FontWeight.w700,
                color: zoneColor,
                letterSpacing: -0.5,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
              semanticLabel: 'Wellness score ${score.toStringAsFixed(0)}',
            ),
            const SizedBox(height: 12),
            // Zone label
            Text(
              _zoneLabel(zone).toUpperCase(),
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.0,
                height: 1.2,
                color: Color(0xFF6B7280),
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
        return const Color(0xFF10B981);
      case 'maintaining':
        return const Color(0xFF3B82F6);
      case 'recovering':
        return const Color(0xFFF59E0B);
      case 'needsAttention':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFFF97316);
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
        return const Color(0xFF10B981);
      case 'maintaining':
        return const Color(0xFF3B82F6);
      case 'recovering':
        return const Color(0xFFF59E0B);
      case 'needsAttention':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF6B7280);
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
// Metric Card — icon + score + trend arrow + mini sparkline
// ---------------------------------------------------------------------------

enum _TrendDirection { up, down, flat }

class _MetricData {
  const _MetricData({
    required this.title,
    required this.icon,
    required this.score,
    required this.color,
    required this.trend,
    required this.sparkline,
  });

  final String title;
  final IconData icon;
  final int score;
  final Color color;
  final _TrendDirection trend;
  final List<int> sparkline;
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
        color: DigitalAtelierTokens2.surface,
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
                // Score
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
                    color: Color(0xFF9CA3AF),
                  ),
                ),
                const SizedBox(height: 8),
                // Mini sparkline
                SizedBox(
                  height: 20,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: _SparklinePainter(
                      values: metric.sparkline,
                      color: metric.color,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
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
        return const Color(0xFF10B981);
      case _TrendDirection.down:
        return const Color(0xFFF59E0B);
      case _TrendDirection.flat:
        return const Color(0xFF6B7280);
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

// ---------------------------------------------------------------------------
// Mini Sparkline Painter — 7 dots connected by a line
// ---------------------------------------------------------------------------

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({required this.values, required this.color});

  final List<int> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final paint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final minVal = values.reduce((a, b) => a < b ? a : b).toDouble();
    final maxVal = values.reduce((a, b) => a > b ? a : b).toDouble();
    final range = (maxVal - minVal).clamp(1.0, double.infinity);

    final points = <Offset>[];
    for (var i = 0; i < values.length; i++) {
      final x = (i / (values.length - 1)) * size.width;
      final y = size.height -
          ((values[i] - minVal) / range) * size.height;
      points.add(Offset(x, y));
    }

    // Draw line
    if (points.length > 1) {
      final path = Path()..moveTo(points[0].dx, points[0].dy);
      for (var i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
      canvas.drawPath(path, paint);
    }

    // Draw dots
    for (final point in points) {
      canvas.drawCircle(point, 2, dotPaint);
    }
  }

  @override
  bool shouldRepaint(_SparklinePainter old) =>
      old.values != values || old.color != color;
}
