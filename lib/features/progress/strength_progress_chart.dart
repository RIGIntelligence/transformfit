import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:transformfit/theme/digital_atelier.dart';

// ---------------------------------------------------------------------------
// Mock data
// ---------------------------------------------------------------------------

class OneRMDataPoint {
  const OneRMDataPoint({required this.date, required this.weightKg});
  final DateTime date;
  final double weightKg;
}

class ExerciseStrengthSeries {
  const ExerciseStrengthSeries({
    required this.exerciseName,
    required this.color,
    required this.points,
  });
  final String exerciseName;
  final Color color;
  final List<OneRMDataPoint> points;
}

List<ExerciseStrengthSeries> generateMockStrengthData() {
  final now = DateTime.now();
  final rng = math.Random(42);

  ExerciseStrengthSeries build(
    String name,
    Color color,
    double base,
    double weeklyGain,
  ) {
    final pts = <OneRMDataPoint>[];
    for (var w = 11; w >= 0; w--) {
      final date = now.subtract(Duration(days: w * 7));
      final noise = (rng.nextDouble() - 0.5) * 4;
      final weight = base + (11 - w) * weeklyGain + noise;
      pts.add(OneRMDataPoint(date: date, weightKg: weight));
    }
    return ExerciseStrengthSeries(
      exerciseName: name,
      color: color,
      points: pts,
    );
  }

  return [
    build('Bench Press', const Color(0xFFF97316), 80, 1.2),
    build('Squat', const Color(0xFF8B5CF6), 100, 1.8),
    build('Deadlift', const Color(0xFF10B981), 120, 2.0),
  ];
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final strengthSeriesProvider = Provider<List<ExerciseStrengthSeries>>((ref) {
  return generateMockStrengthData();
});

// ---------------------------------------------------------------------------
// Widget
// ---------------------------------------------------------------------------

class StrengthProgressChart extends ConsumerStatefulWidget {
  const StrengthProgressChart({super.key});

  @override
  ConsumerState<StrengthProgressChart> createState() =>
      _StrengthProgressChartState();
}

class _StrengthProgressChartState extends ConsumerState<StrengthProgressChart> {
  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<DigitalAtelierExtension>()!;
    final seriesList = ref.watch(strengthSeriesProvider);

    if (seriesList.isEmpty || seriesList.every((s) => s.points.isEmpty)) {
      return _EmptyState(t: t);
    }

    // Compute global Y range.
    final allWeights = seriesList
        .expand((s) => s.points)
        .map((p) => p.weightKg)
        .toList();
    final minY = (allWeights.reduce(math.min) - 5).floorToDouble();
    final maxY = (allWeights.reduce(math.max) + 5).ceilToDouble();
    final dates = seriesList.first.points.map((p) => p.date).toList();

    return Semantics(
      label:
          'Estimated one rep max progress chart. '
          '${seriesList.map((s) => '${s.exerciseName}: latest ${s.points.last.weightKg.toStringAsFixed(0)} kg').join(', ')}.',
      child: Container(
        decoration: t.cardDecoration,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Strength Progress', style: t.textTheme.h3),
            const SizedBox(height: 4),
            Text('Estimated 1RM over 12 weeks', style: t.textTheme.caption),
            const SizedBox(height: 16),
            SizedBox(
              height: 220,
              child: LineChart(
                LineChartData(
                  minY: minY,
                  maxY: maxY,
                  clipData: const FlClipData.all(),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: ((maxY - minY) / 4).ceilToDouble(),
                    getDrawingHorizontalLine: (_) =>
                        FlLine(color: t.surfaceBorder, strokeWidth: 0.5),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 44,
                        interval: ((maxY - minY) / 4).ceilToDouble(),
                        getTitlesWidget: (value, _) => Text(
                          '${value.toInt()} kg',
                          style: t.textTheme.caption,
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: math
                            .max(1, (dates.length / 4))
                            .floorToDouble(),
                        getTitlesWidget: (value, _) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= dates.length) {
                            return const SizedBox.shrink();
                          }
                          final d = dates[idx];
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
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) => t.surfaceElevated,
                      tooltipBorderRadius: BorderRadius.circular(t.radiusSm),
                      getTooltipItems: (spots) => spots.map((spot) {
                        final s = seriesList[spot.barIndex];
                        return LineTooltipItem(
                          '${s.exerciseName}\n${spot.y.toStringAsFixed(1)} kg',
                          TextStyle(
                            color: s.color,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        );
                      }).toList(),
                    ),
                    handleBuiltInTouches: true,
                    touchCallback: (event, response) {
                      setState(() {
                        _touchedIndex = response?.lineBarSpots?.first.spotIndex;
                      });
                    },
                  ),
                  lineBarsData: [
                    for (final s in seriesList)
                      LineChartBarData(
                        spots: [
                          for (var i = 0; i < s.points.length; i++)
                            FlSpot(i.toDouble(), s.points[i].weightKg),
                        ],
                        isCurved: true,
                        curveSmoothness: 0.35,
                        color: s.color,
                        barWidth: 2.5,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, _, _, _) => FlDotCirclePainter(
                            radius: _touchedIndex == spot.x.toInt() ? 5 : 3,
                            color: s.color,
                            strokeWidth: 0,
                          ),
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [
                              s.color.withValues(alpha: 0.25),
                              s.color.withValues(alpha: 0.0),
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
            _Legend(seriesList: seriesList),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Legend
// ---------------------------------------------------------------------------

class _Legend extends StatelessWidget {
  const _Legend({required this.seriesList});
  final List<ExerciseStrengthSeries> seriesList;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<DigitalAtelierExtension>()!;
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        for (final s in seriesList)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: s.color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                s.exerciseName,
                style: t.textTheme.caption.copyWith(color: t.textSecondary),
              ),
            ],
          ),
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
            Icon(Icons.show_chart, color: t.textMuted, size: 40),
            const SizedBox(height: 12),
            Text(
              'No strength data yet',
              style: t.textTheme.body.copyWith(color: t.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
