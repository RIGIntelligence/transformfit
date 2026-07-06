import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:transformfit/theme/digital_atelier.dart';

// ---------------------------------------------------------------------------
// Data model
// ---------------------------------------------------------------------------

/// A single body composition measurement.
class BodyCompMeasurement {
  const BodyCompMeasurement({
    required this.date,
    required this.weightKg,
    required this.bodyFatPercent,
    required this.leanMassKg,
  });

  final DateTime date;
  final double weightKg;
  final double bodyFatPercent;
  final double leanMassKg;
}

/// Generates mock body composition data over 12 weeks.
List<BodyCompMeasurement> generateMockBodyCompData() {
  final now = DateTime.now();
  final rng = math.Random(42);
  final data = <BodyCompMeasurement>[];

  for (var w = 11; w >= 0; w--) {
    final date = now.subtract(Duration(days: w * 7));
    final weight = 82.0 - w * 0.3 + (rng.nextDouble() - 0.5) * 0.8;
    final bf = 18.0 - w * 0.2 + (rng.nextDouble() - 0.5) * 0.4;
    final lean = weight * (1 - bf / 100);
    data.add(BodyCompMeasurement(
      date: date,
      weightKg: weight,
      bodyFatPercent: bf,
      leanMassKg: lean,
    ));
  }

  return data;
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final bodyCompDataProvider = Provider<List<BodyCompMeasurement>>((ref) {
  return generateMockBodyCompData();
});

// ---------------------------------------------------------------------------
// Widget
// ---------------------------------------------------------------------------

class BodyCompTrendsChart extends ConsumerStatefulWidget {
  const BodyCompTrendsChart({super.key});

  @override
  ConsumerState<BodyCompTrendsChart> createState() =>
      _BodyCompTrendsChartState();
}

class _BodyCompTrendsChartState extends ConsumerState<BodyCompTrendsChart> {
  bool _showWeight = true;
  bool _showBodyFat = true;
  bool _showLeanMass = true;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<DigitalAtelierExtension>()!;
    final data = ref.watch(bodyCompDataProvider);

    if (data.isEmpty) return _EmptyState(t: t);

    // Compute Y-axis ranges for weight/lean (left) and body fat (right).
    final weights = data.map((d) => d.weightKg).toList();
    final fats = data.map((d) => d.bodyFatPercent).toList();
    final leans = data.map((d) => d.leanMassKg).toList();

    final weightMin = weights.reduce(math.min) - 2;
    final weightMax = weights.reduce(math.max) + 2;
    final fatMin = (fats.reduce(math.min) - 2).clamp(0.0, double.infinity);
    final fatMax = fats.reduce(math.max) + 2;

    return Semantics(
      label:
          'Body composition trends chart. Weight, body fat, and lean mass '
          'over 12 weeks.',
      child: Container(
        decoration: t.cardDecoration,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Body Composition', style: t.textTheme.h3),
            const SizedBox(height: 4),
            Text('Weight, body fat %, lean mass over 12 weeks',
                style: t.textTheme.caption),
            const SizedBox(height: 12),
            _Legend(
              showWeight: _showWeight,
              showBodyFat: _showBodyFat,
              showLeanMass: _showLeanMass,
              onWeightToggle: () => setState(() => _showWeight = !_showWeight),
              onBodyFatToggle: () =>
                  setState(() => _showBodyFat = !_showBodyFat),
              onLeanMassToggle: () =>
                  setState(() => _showLeanMass = !_showLeanMass),
              t: t,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 220,
              child: LineChart(
                LineChartData(
                  minY: weightMin,
                  maxY: weightMax,
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) => t.surfaceElevated,
                      tooltipBorderRadius: BorderRadius.circular(t.radiusSm),
                      getTooltipItems: (spots) {
                        return spots.map((spot) {
                          final idx = spot.x.toInt();
                          if (idx < 0 || idx >= data.length) {
                            return null;
                          }
                          final pt = data[idx];
                          String label;
                          Color color;
                          if (spot.barIndex == 0) {
                            label =
                                'Weight: ${pt.weightKg.toStringAsFixed(1)} kg';
                            color = t.accentPrimary;
                          } else if (spot.barIndex == 1) {
                            label =
                                'Body Fat: ${pt.bodyFatPercent.toStringAsFixed(1)}%';
                            color = t.accentInfo;
                          } else {
                            label =
                                'Lean: ${pt.leanMassKg.toStringAsFixed(1)} kg';
                            color = t.accentTertiary;
                          }
                          return LineTooltipItem(
                            label,
                            TextStyle(
                              color: color,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          );
                        }).toList();
                      },
                    ),
                    handleBuiltInTouches: true,
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 2,
                    getDrawingHorizontalLine: (_) =>
                        FlLine(color: t.surfaceBorder, strokeWidth: 0.5),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 44,
                        interval: 2,
                        getTitlesWidget: (value, _) => Text(
                          '${value.toStringAsFixed(0)}',
                          style: t.textTheme.caption,
                        ),
                      ),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: _showBodyFat,
                        reservedSize: 44,
                        interval: ((fatMax - fatMin) / 4).ceilToDouble().clamp(
                              1,
                              double.infinity,
                            ),
                        getTitlesWidget: (value, _) => Text(
                          '${value.toStringAsFixed(0)}%',
                          style: t.textTheme.caption.copyWith(
                            color: t.accentInfo.withValues(alpha: 0.7),
                          ),
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
                          if (idx.isOdd) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              '${data[idx].date.month}/${data[idx].date.day}',
                              style: t.textTheme.caption,
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  lineBarsData: [
                    // Weight line
                    if (_showWeight)
                      _buildLine(
                        data,
                        (d) => d.weightKg,
                        t.accentPrimary,
                      ),
                    // Body fat line (scaled to weight axis range for overlay)
                    if (_showBodyFat)
                      _buildLine(
                        data,
                        (d) => _scaleToRange(
                          d.bodyFatPercent,
                          fatMin,
                          fatMax,
                          weightMin,
                          weightMax,
                        ),
                        t.accentInfo,
                      ),
                    // Lean mass line
                    if (_showLeanMass)
                      _buildLine(
                        data,
                        (d) => d.leanMassKg,
                        t.accentTertiary,
                      ),
                  ],
                ),
                duration: t.durationNormal,
              ),
            ),
            const SizedBox(height: 12),
            _SummaryRow(data: data, t: t),
          ],
        ),
      ),
    );
  }

  /// Scales [value] from range [fromMin..fromMax] to [toMin..toMax].
  static double _scaleToRange(
    double value,
    double fromMin,
    double fromMax,
    double toMin,
    double toMax,
  ) {
    if (fromMax == fromMin) return toMin;
    return toMin + (value - fromMin) / (fromMax - fromMin) * (toMax - toMin);
  }

  LineChartBarData _buildLine(
    List<BodyCompMeasurement> data,
    double Function(BodyCompMeasurement) selector,
    Color color,
  ) {
    final spots = <FlSpot>[];
    for (var i = 0; i < data.length; i++) {
      spots.add(FlSpot(i.toDouble(), selector(data[i])));
    }

    return LineChartBarData(
      spots: spots,
      isCurved: true,
      curveSmoothness: 0.3,
      color: color,
      barWidth: 2.5,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
          radius: 3,
          color: color,
        ),
      ),
      belowBarData: BarAreaData(show: false),
    );
  }
}

// ---------------------------------------------------------------------------
// Legend with toggles
// ---------------------------------------------------------------------------

class _Legend extends StatelessWidget {
  const _Legend({
    required this.showWeight,
    required this.showBodyFat,
    required this.showLeanMass,
    required this.onWeightToggle,
    required this.onBodyFatToggle,
    required this.onLeanMassToggle,
    required this.t,
  });

  final bool showWeight;
  final bool showBodyFat;
  final bool showLeanMass;
  final VoidCallback onWeightToggle;
  final VoidCallback onBodyFatToggle;
  final VoidCallback onLeanMassToggle;
  final DigitalAtelierExtension t;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _LegendChip(
          label: 'Weight',
          color: t.accentPrimary,
          active: showWeight,
          onTap: onWeightToggle,
        ),
        const SizedBox(width: 8),
        _LegendChip(
          label: 'Body Fat',
          color: t.accentInfo,
          active: showBodyFat,
          onTap: onBodyFatToggle,
        ),
        const SizedBox(width: 8),
        _LegendChip(
          label: 'Lean Mass',
          color: t.accentTertiary,
          active: showLeanMass,
          onTap: onLeanMassToggle,
        ),
      ],
    );
  }
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({
    required this.label,
    required this.color,
    required this.active,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<DigitalAtelierExtension>()!;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: active
              ? color.withValues(alpha: 0.15)
              : t.surface.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(t.radiusPill),
          border: Border.all(
            color: active ? color : t.surfaceBorder,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: active ? color : t.textMuted,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: t.textTheme.caption.copyWith(
                color: active ? color : t.textMuted,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Summary row
// ---------------------------------------------------------------------------

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.data, required this.t});
  final List<BodyCompMeasurement> data;
  final DigitalAtelierExtension t;

  @override
  Widget build(BuildContext context) {
    final first = data.first;
    final last = data.last;
    final weightDelta = last.weightKg - first.weightKg;
    final fatDelta = last.bodyFatPercent - first.bodyFatPercent;
    final leanDelta = last.leanMassKg - first.leanMassKg;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _DeltaMetric('Weight', weightDelta, 'kg', t),
        _DeltaMetric('Body Fat', fatDelta, '%', t),
        _DeltaMetric('Lean Mass', leanDelta, 'kg', t),
      ],
    );
  }
}

class _DeltaMetric extends StatelessWidget {
  const _DeltaMetric(this.label, this.delta, this.unit, this.t);
  final String label;
  final double delta;
  final String unit;
  final DigitalAtelierExtension t;

  @override
  Widget build(BuildContext context) {
    final isNegative = delta < 0;
    final color = isNegative ? t.accentTertiary : t.accentPrimary;
    final arrow = isNegative ? '↓' : '↑';
    final sign = isNegative ? '' : '+';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$arrow $sign${delta.toStringAsFixed(1)} $unit',
          style: t.textTheme.dataSmall.copyWith(color: color),
        ),
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
            Icons.monitor_weight_outlined;
            Icon(Icons.monitor_weight_outlined, color: t.textMuted, size: 40),
            const SizedBox(height: 12),
            Text(
              'No body composition data yet',
              style: t.textTheme.body.copyWith(color: t.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
