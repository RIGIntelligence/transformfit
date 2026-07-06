import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:transformfit/theme/digital_atelier.dart';

// ---------------------------------------------------------------------------
// Mock data
// ---------------------------------------------------------------------------

class WeeklyVolume {
  const WeeklyVolume({required this.weekStart, required this.volumeKg});
  final DateTime weekStart;
  final double volumeKg;
}

List<WeeklyVolume> generateMockVolumeData() {
  final now = DateTime.now();
  final rng = math.Random(77);
  final data = <WeeklyVolume>[];
  for (var w = 11; w >= 0; w--) {
    final date = now.subtract(Duration(days: w * 7));
    final base = 18000 + (11 - w) * 600;
    final noise = (rng.nextDouble() - 0.5) * 3000;
    data.add(WeeklyVolume(weekStart: date, volumeKg: base + noise));
  }
  return data;
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final volumeDataProvider = Provider<List<WeeklyVolume>>((ref) {
  return generateMockVolumeData();
});

// ---------------------------------------------------------------------------
// Widget
// ---------------------------------------------------------------------------

class VolumeChart extends ConsumerWidget {
  const VolumeChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).extension<DigitalAtelierExtension>()!;
    final data = ref.watch(volumeDataProvider);

    if (data.isEmpty) return _EmptyState(t: t);

    final maxVol = data.map((d) => d.volumeKg).reduce(math.max);
    final interval = ((maxVol / 4) / 1000).ceil() * 1000.0;

    // Compute trend line (simple linear regression).
    final n = data.length;
    final xMean = (n - 1) / 2.0;
    final yMean = data.map((d) => d.volumeKg).reduce((a, b) => a + b) / n;
    var ssXY = 0.0, ssXX = 0.0;
    for (var i = 0; i < n; i++) {
      ssXY += (i - xMean) * (data[i].volumeKg - yMean);
      ssXX += (i - xMean) * (i - xMean);
    }
    final slope = ssXY / ssXX;
    final intercept = yMean - slope * xMean;

    return Semantics(
      label:
          'Weekly training volume chart. 12 week view. '
          'Latest week: ${data.last.volumeKg.toStringAsFixed(0)} kg.',
      child: Container(
        decoration: t.cardDecoration,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Weekly Volume', style: t.textTheme.h3),
            const SizedBox(height: 4),
            Text('Sets × weight × reps per week', style: t.textTheme.caption),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxVol * 1.1,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => t.surfaceElevated,
                      tooltipBorderRadius: BorderRadius.circular(t.radiusSm),
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final week = data[group.x];
                        return BarTooltipItem(
                          '${_weekLabel(week)}\n${_formatKg(week.volumeKg)}',
                          TextStyle(
                            color: group.x == data.length - 1
                                ? t.accentTertiary
                                : t.textSecondary,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: interval,
                    getDrawingHorizontalLine: (_) =>
                        FlLine(color: t.surfaceBorder, strokeWidth: 0.5),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 52,
                        interval: interval,
                        getTitlesWidget: (value, _) => Text(
                          '${(value / 1000).toStringAsFixed(0)}k',
                          style: t.textTheme.caption,
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, _) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= data.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              'W${idx + 1}',
                              style: t.textTheme.caption,
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  barGroups: [
                    for (var i = 0; i < data.length; i++)
                      BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: data[i].volumeKg,
                            color: i == data.length - 1
                                ? t.accentTertiary
                                : t.accentTertiary.withValues(alpha: 0.35),
                            width: 14,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4),
                            ),
                          ),
                        ],
                      ),
                  ],
                  extraLinesData: ExtraLinesData(
                    horizontalLines: [],
                    extraLinesOnTop: true,
                  ),
                ),
                duration: t.durationNormal,
              ),
            ),
            const SizedBox(height: 8),
            _TrendLine(slope: slope, intercept: intercept, data: data, t: t),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Trend line indicator
// ---------------------------------------------------------------------------

class _TrendLine extends StatelessWidget {
  const _TrendLine({
    required this.slope,
    required this.intercept,
    required this.data,
    required this.t,
  });

  final double slope;
  final double intercept;
  final List<WeeklyVolume> data;
  final DigitalAtelierExtension t;

  @override
  Widget build(BuildContext context) {
    final trending = slope > 100
        ? 'Trending up'
        : slope < -100
        ? 'Trending down'
        : 'Holding steady';
    final arrow = slope > 100
        ? Icons.trending_up
        : slope < -100
        ? Icons.trending_down
        : Icons.trending_flat;
    final color = slope > 100
        ? t.accentTertiary
        : slope < -100
        ? t.accentDanger
        : t.textMuted;

    return Row(
      children: [
        Icon(arrow, color: color, size: 18),
        const SizedBox(width: 6),
        Text(
          '$trending · ${_formatKg(intercept + slope * (data.length - 1))} this week',
          style: t.textTheme.caption.copyWith(color: color),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

String _weekLabel(WeeklyVolume w) => '${w.weekStart.month}/${w.weekStart.day}';

String _formatKg(double v) {
  if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k kg';
  return '${v.toStringAsFixed(0)} kg';
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
            Icon(Icons.bar_chart, color: t.textMuted, size: 40),
            const SizedBox(height: 12),
            Text(
              'No volume data yet',
              style: t.textTheme.body.copyWith(color: t.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
