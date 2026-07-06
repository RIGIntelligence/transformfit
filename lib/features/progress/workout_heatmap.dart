import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:transformfit/theme/digital_atelier.dart';

// ---------------------------------------------------------------------------
// Mock data — 52 weeks × 7 days of workout counts
// ---------------------------------------------------------------------------

Map<DateTime, int> generateMockHeatmapData() {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final rng = math.Random(123);
  final map = <DateTime, int>{};
  for (var d = 364; d >= 0; d--) {
    final date = today.subtract(Duration(days: d));
    // ~60% chance of workout, higher on weekdays.
    final weekday = date.weekday;
    final chance = weekday <= 5 ? 0.65 : 0.30;
    final count = rng.nextDouble() < chance ? (rng.nextInt(2) + 1) : 0;
    map[date] = count;
  }
  return map;
}

final heatmapDataProvider = Provider<Map<DateTime, int>>((ref) {
  return generateMockHeatmapData();
});

// ---------------------------------------------------------------------------
// Widget
// ---------------------------------------------------------------------------

class WorkoutHeatmap extends ConsumerWidget {
  const WorkoutHeatmap({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).extension<DigitalAtelierExtension>()!;
    final data = ref.watch(heatmapDataProvider);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Count total workout days.
    final workoutDays = data.values.where((v) => v > 0).length;
    final currentStreak = _currentStreak(data, today);

    return Semantics(
      label:
          'Workout contribution heatmap. '
          '$workoutDays workout days in the past year. '
          'Current streak: $currentStreak days.',
      child: Container(
        decoration: t.cardDecoration,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Activity', style: t.textTheme.h3),
                      const SizedBox(height: 4),
                      Text(
                        '$workoutDays workout days · $currentStreak day streak',
                        style: t.textTheme.caption,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Semantics(
                label: 'Heatmap grid showing 52 weeks of activity',
                child: CustomPaint(
                  size: const Size(52 * 14 + 32, 7 * 14 + 24),
                  painter: _HeatmapPainter(
                    data: data,
                    today: today,
                    emptyColor: t.surfaceInput,
                    activeColor: t.accentPrimary,
                    todayBorder: t.accentPrimary,
                    textMuted: t.textMuted,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _LegendRow(t: t),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// CustomPainter
// ---------------------------------------------------------------------------

class _HeatmapPainter extends CustomPainter {
  _HeatmapPainter({
    required this.data,
    required this.today,
    required this.emptyColor,
    required this.activeColor,
    required this.todayBorder,
    required this.textMuted,
  });

  final Map<DateTime, int> data;
  final DateTime today;
  final Color emptyColor;
  final Color activeColor;
  final Color todayBorder;
  final Color textMuted;

  static const _cellSize = 12.0;
  static const _gap = 2.0;
  static const _leftPad = 32.0;
  static const _topPad = 20.0;
  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  static const _dayLabels = ['M', '', 'W', '', 'F', '', ''];

  @override
  void paint(Canvas canvas, Size size) {
    final cellPaint = Paint()..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Day labels (Mon, Wed, Fri).
    for (var day = 0; day < 7; day++) {
      if (_dayLabels[day].isEmpty) continue;
      final tp = TextPainter(
        text: TextSpan(
          text: _dayLabels[day],
          style: TextStyle(color: textMuted, fontSize: 10, fontFamily: 'Inter'),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(0, _topPad + day * (_cellSize + _gap) + (_cellSize - 10) / 2),
      );
    }

    // Compute the start date (52 weeks ago from the most recent Sunday).
    final startOfWeek = today.subtract(Duration(days: today.weekday % 7));
    final startDate = startOfWeek.subtract(const Duration(days: 51 * 7));

    // Month labels track when month changes.
    var lastMonth = -1;

    for (var week = 0; week < 52; week++) {
      final weekStart = startDate.add(Duration(days: week * 7));
      for (var day = 0; day < 7; day++) {
        final date = weekStart.add(Duration(days: day));
        final count = data[date] ?? 0;
        final x = _leftPad + week * (_cellSize + _gap);
        final y = _topPad + day * (_cellSize + _gap);
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, _cellSize, _cellSize),
          const Radius.circular(2),
        );

        if (count == 0) {
          cellPaint.color = emptyColor;
        } else {
          final intensity = math.min(count / 2.0, 1.0);
          cellPaint.color = Color.lerp(
            activeColor.withValues(alpha: 0.3),
            activeColor,
            intensity,
          )!;
        }
        canvas.drawRRect(rect, cellPaint);

        // Today highlight.
        if (date == today) {
          borderPaint.color = todayBorder;
          canvas.drawRRect(rect, borderPaint);
        }
      }

      // Month label on first week of a new month.
      final monthDate = weekStart;
      if (monthDate.month != lastMonth) {
        lastMonth = monthDate.month;
        final tp = TextPainter(
          text: TextSpan(
            text: _months[monthDate.month - 1],
            style: TextStyle(
              color: textMuted,
              fontSize: 10,
              fontFamily: 'Inter',
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(_leftPad + week * (_cellSize + _gap), 0));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _HeatmapPainter old) =>
      data != old.data || today != old.today;
}

// ---------------------------------------------------------------------------
// Legend
// ---------------------------------------------------------------------------

class _LegendRow extends StatelessWidget {
  const _LegendRow({required this.t});
  final DigitalAtelierExtension t;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('Less', style: t.textTheme.caption),
        const SizedBox(width: 4),
        for (var i = 0; i < 4; i++) ...[
          Container(
            width: 12,
            height: 12,
            margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(
              color: i == 0
                  ? t.surfaceInput
                  : Color.lerp(
                      t.accentPrimary.withValues(alpha: 0.3),
                      t.accentPrimary,
                      i / 3.0,
                    ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
        const SizedBox(width: 4),
        Text('More', style: t.textTheme.caption),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

int _currentStreak(Map<DateTime, int> data, DateTime today) {
  var streak = 0;
  var date = today;
  while (true) {
    final count = data[date] ?? 0;
    if (count == 0) break;
    streak++;
    date = date.subtract(const Duration(days: 1));
  }
  return streak;
}
