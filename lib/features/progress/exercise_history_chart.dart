import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:transformfit/theme/digital_atelier.dart';

// ---------------------------------------------------------------------------
// Data model
// ---------------------------------------------------------------------------

/// A single exercise volume data point for one week.
class ExerciseVolumePoint {
  const ExerciseVolumePoint({
    required this.weekStart,
    required this.volumeKg,
    required this.sets,
    required this.reps,
    required this.weightKg,
  });

  final DateTime weekStart;
  final double volumeKg; // sets × reps × weight
  final int sets;
  final int reps;
  final double weightKg;
}

/// Generates mock exercise volume data for a specific exercise over 12 weeks.
List<ExerciseVolumePoint> generateMockExerciseData({
  required String exerciseName,
}) {
  final now = DateTime.now();
  // Deterministic seed from exercise name.
  final seed = exerciseName.codeUnits.fold<int>(
    0,
    (sum, c) => sum + c,
  );
  final rng = math.Random(seed);
  final data = <ExerciseVolumePoint>[];

  for (var w = 11; w >= 0; w--) {
    final date = now.subtract(Duration(days: w * 7));
    final sets = 3 + rng.nextInt(2); // 3–4 sets
    final reps = 6 + rng.nextInt(6); // 6–11 reps
    final weight = 40.0 + (11 - w) * 2.5 + (rng.nextDouble() - 0.5) * 5;
    data.add(ExerciseVolumePoint(
      weekStart: date,
      volumeKg: sets * reps * weight,
      sets: sets,
      reps: reps,
      weightKg: weight,
    ));
  }

  return data;
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final exerciseVolumeProvider =
    Provider.family<List<ExerciseVolumePoint>, String>((ref, exerciseName) {
  return generateMockExerciseData(exerciseName: exerciseName);
});

// ---------------------------------------------------------------------------
// Widget
// ---------------------------------------------------------------------------

class ExerciseHistoryChart extends ConsumerStatefulWidget {
  const ExerciseHistoryChart({
    super.key,
    required this.exerciseName,
  });

  final String exerciseName;

  @override
  ConsumerState<ExerciseHistoryChart> createState() =>
      _ExerciseHistoryChartState();
}

class _ExerciseHistoryChartState extends ConsumerState<ExerciseHistoryChart> {
  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<DigitalAtelierExtension>()!;
    final data = ref.watch(exerciseVolumeProvider(widget.exerciseName));

    if (data.isEmpty) return _EmptyState(t: t, name: widget.exerciseName);

    final maxVol = data.map((d) => d.volumeKg).reduce(math.max);
    final interval = ((maxVol / 4) / 1000).ceil() * 1000.0;

    final spots = <FlSpot>[];
    for (var i = 0; i < data.length; i++) {
      spots.add(FlSpot(i.toDouble(), data[i].volumeKg));
    }

    return Semantics(
      label:
          '${widget.exerciseName} volume chart. 12 week view. '
          'Latest: ${data.last.volumeKg.toStringAsFixed(0)} kg.',
      child: Container(
        decoration: t.cardDecoration,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.exerciseName, style: t.textTheme.h3),
            const SizedBox(height: 4),
            Text(
              'Volume over 12 weeks (sets × reps × weight)',
              style: t.textTheme.caption,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 220,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: maxVol * 1.15,
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) => t.surfaceElevated,
                      tooltipBorderRadius: BorderRadius.circular(t.radiusSm),
                      getTooltipItems: (spots) {
                        return spots.map((spot) {
                          final idx = spot.x.toInt();
                          final pt = data[idx];
                          final date =
                              '${pt.weekStart.month}/${pt.weekStart.day}';
                          return LineTooltipItem(
                            '$date\n'
                            '${pt.sets}×${pt.reps} @ '
                            '${pt.weightKg.toStringAsFixed(1)}kg\n'
                            '${pt.volumeKg.toStringAsFixed(0)} kg total',
                            TextStyle(
                              color: t.accentPrimary,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          );
                        }).toList();
                      },
                    ),
                    touchCallback: (event, response) {
                      setState(() {
                        if (event is FlLongPressEnd || !event.isInterestedForInteractions) {
                          _touchedIndex = null;
                        } else {
                          _touchedIndex =
                              response?.lineBarSpots?.first.spotIndex;
                        }
                      });
                    },
                    handleBuiltInTouches: true,
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
                          // Show every other label to avoid crowding.
                          if (idx.isOdd) return const SizedBox.shrink();
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
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      curveSmoothness: 0.3,
                      color: t.accentPrimary,
                      barWidth: 2.5,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, _, __, ___) {
                          final isTouched =
                              _touchedIndex == spot.x.toInt();
                          return FlDotCirclePainter(
                            radius: isTouched ? 5 : 3,
                            color: t.accentPrimary,
                            strokeWidth: isTouched ? 2 : 0,
                            strokeColor: t.textPrimary,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            t.accentPrimary.withValues(alpha: 0.3),
                            t.accentPrimary.withValues(alpha: 0.0),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                  extraLinesData: ExtraLinesData(
                    horizontalLines: [],
                    extraLinesOnTop: false,
                  ),
                ),
                duration: t.durationNormal,
              ),
            ),
            if (_touchedIndex != null &&
                _touchedIndex! >= 0 &&
                _touchedIndex! < data.length) ...[
              const SizedBox(height: 12),
              _DetailRow(point: data[_touchedIndex!], t: t),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Detail row shown on tap
// ---------------------------------------------------------------------------

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.point, required this.t});

  final ExerciseVolumePoint point;
  final DigitalAtelierExtension t;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: t.glassDecoration,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _Metric('Sets', '${point.sets}', t),
          _Metric('Reps', '${point.reps}', t),
          _Metric('Weight', '${point.weightKg.toStringAsFixed(1)} kg', t),
          _Metric('Volume', '${point.volumeKg.toStringAsFixed(0)} kg', t),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric(this.label, this.value, this.t);
  final String label;
  final String value;
  final DigitalAtelierExtension t;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: t.textTheme.dataSmall),
        const SizedBox(height: 2),
        Text(label, style: t.textTheme.caption),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.t, required this.name});
  final DigitalAtelierExtension t;
  final String name;

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
              'No history for $name yet',
              style: t.textTheme.body.copyWith(color: t.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
