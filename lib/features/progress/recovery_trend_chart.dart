import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:transformfit/theme/digital_atelier.dart';

// ---------------------------------------------------------------------------
// Mock data
// ---------------------------------------------------------------------------

class ReadinessPoint {
  const ReadinessPoint({required this.date, required this.score});
  final DateTime date;
  final double score; // 0–100
}

List<ReadinessPoint> generateMockReadinessData() {
  final now = DateTime.now();
  final rng = math.Random(33);
  final data = <ReadinessPoint>[];
  var current = 72.0;
  for (var d = 29; d >= 0; d--) {
    final date = now.subtract(Duration(days: d));
    current += (rng.nextDouble() - 0.45) * 8;
    current = current.clamp(30, 100);
    data.add(ReadinessPoint(date: date, score: current));
  }
  return data;
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final readinessDataProvider = Provider<List<ReadinessPoint>>((ref) {
  return generateMockReadinessData();
});

// ---------------------------------------------------------------------------
// Widget
// ---------------------------------------------------------------------------

class RecoveryTrendChart extends ConsumerWidget {
  const RecoveryTrendChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).extension<DigitalAtelierExtension>()!;
    final data = ref.watch(readinessDataProvider);

    if (data.isEmpty) return _EmptyState(t: t);

    final currentScore = data.last.score;
    final weekAgoScore = data.length >= 7
        ? data[data.length - 7].score
        : currentScore;
    final delta = currentScore - weekAgoScore;

    final trendLabel = delta > 3
        ? 'Improving'
        : delta < -3
        ? 'Declining'
        : 'Stable';
    final trendIcon = delta > 3
        ? Icons.arrow_upward
        : delta < -3
        ? Icons.arrow_downward
        : Icons.remove;
    final trendColor = delta > 3
        ? t.accentTertiary
        : delta < -3
        ? t.accentDanger
        : t.textMuted;

    // Zone thresholds.
    const pushThreshold = 75.0;
    const deloadThreshold = 45.0;

    return Semantics(
      label:
          'Recovery trend chart. Current readiness score: '
          '${currentScore.toStringAsFixed(0)} out of 100. '
          'Trend: $trendLabel.',
      child: Container(
        decoration: t.cardDecoration,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Recovery', style: t.textTheme.h3),
            const SizedBox(height: 4),
            Text('Readiness score · 30 days', style: t.textTheme.caption),
            const SizedBox(height: 16),

            // Current score display.
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  currentScore.toStringAsFixed(0),
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 48,
                    fontWeight: FontWeight.w700,
                    color: _scoreColor(currentScore, t),
                    height: 1.0,
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(trendIcon, color: trendColor, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        trendLabel,
                        style: t.textTheme.caption.copyWith(color: trendColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            SizedBox(
              height: 180,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: 100,
                  clipData: const FlClipData.all(),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 7,
                        getTitlesWidget: (value, _) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= data.length) {
                            return const SizedBox.shrink();
                          }
                          final d = data[idx].date;
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              '${d.month}/${d.day}',
                              style: t.textTheme.caption,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) => t.surfaceElevated,
                      tooltipBorderRadius: BorderRadius.circular(t.radiusSm),
                      getTooltipItems: (spots) => spots.map((spot) {
                        final d = data[spot.x.toInt()];
                        return LineTooltipItem(
                          '${d.date.month}/${d.date.day}\n${spot.y.toStringAsFixed(0)}',
                          TextStyle(
                            color: _scoreColor(spot.y, t),
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  extraLinesData: ExtraLinesData(
                    horizontalLines: [
                      HorizontalLine(
                        y: pushThreshold,
                        color: t.accentTertiary.withValues(alpha: 0.3),
                        strokeWidth: 1,
                        dashArray: [6, 4],
                        label: HorizontalLineLabel(
                          show: true,
                          alignment: Alignment.topRight,
                          style: TextStyle(
                            color: t.accentTertiary.withValues(alpha: 0.6),
                            fontSize: 9,
                            fontFamily: 'Inter',
                          ),
                          labelResolver: (_) => 'Push zone',
                        ),
                      ),
                      HorizontalLine(
                        y: deloadThreshold,
                        color: t.accentDanger.withValues(alpha: 0.3),
                        strokeWidth: 1,
                        dashArray: [6, 4],
                        label: HorizontalLineLabel(
                          show: true,
                          alignment: Alignment.bottomRight,
                          style: TextStyle(
                            color: t.accentDanger.withValues(alpha: 0.6),
                            fontSize: 9,
                            fontFamily: 'Inter',
                          ),
                          labelResolver: (_) => 'Deload zone',
                        ),
                      ),
                    ],
                    extraLinesOnTop: false,
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        for (var i = 0; i < data.length; i++)
                          FlSpot(i.toDouble(), data[i].score),
                      ],
                      isCurved: true,
                      curveSmoothness: 0.3,
                      color: _scoreColor(currentScore, t),
                      barWidth: 2.5,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            _scoreColor(currentScore, t).withValues(alpha: 0.2),
                            _scoreColor(currentScore, t).withValues(alpha: 0.0),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            _ZoneLegend(t: t),
          ],
        ),
      ),
    );
  }

  Color _scoreColor(double score, DigitalAtelierExtension t) {
    if (score >= 75) return t.accentTertiary;
    if (score >= 45) return t.warning;
    return t.accentDanger;
  }
}

// ---------------------------------------------------------------------------
// Zone legend
// ---------------------------------------------------------------------------

class _ZoneLegend extends StatelessWidget {
  const _ZoneLegend({required this.t});
  final DigitalAtelierExtension t;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _zoneChip('Push', t.accentTertiary, t),
        const SizedBox(width: 12),
        _zoneChip('Maintain', t.warning, t),
        const SizedBox(width: 12),
        _zoneChip('Deload', t.accentDanger, t),
      ],
    );
  }

  Widget _zoneChip(String label, Color color, DigitalAtelierExtension t) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: t.textTheme.caption),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.t});
  final DigitalAtelierExtension t;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: t.cardDecoration,
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.battery_charging_full, color: t.textMuted, size: 40),
            const SizedBox(height: 12),
            Text(
              'No recovery data yet',
              style: t.textTheme.body.copyWith(color: t.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
