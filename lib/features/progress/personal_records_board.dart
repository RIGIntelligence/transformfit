import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:transformfit/theme/digital_atelier.dart';

// ---------------------------------------------------------------------------
// Data model
// ---------------------------------------------------------------------------

class PersonalRecord {
  const PersonalRecord({
    required this.exercise,
    required this.weightKg,
    required this.dateAchieved,
    required this.previousWeightKg,
  });
  final String exercise;
  final double weightKg;
  final DateTime dateAchieved;
  final double previousWeightKg;

  double get improvementPct => previousWeightKg > 0
      ? ((weightKg - previousWeightKg) / previousWeightKg) * 100
      : 0;

  bool isRecent(DateTime now) => now.difference(dateAchieved).inDays <= 7;
}

List<PersonalRecord> generateMockPRData() {
  final now = DateTime.now();
  return [
    PersonalRecord(
      exercise: 'Bench Press',
      weightKg: 95,
      dateAchieved: now.subtract(const Duration(days: 2)),
      previousWeightKg: 90,
    ),
    PersonalRecord(
      exercise: 'Squat',
      weightKg: 140,
      dateAchieved: now.subtract(const Duration(days: 5)),
      previousWeightKg: 135,
    ),
    PersonalRecord(
      exercise: 'Deadlift',
      weightKg: 180,
      dateAchieved: now.subtract(const Duration(days: 12)),
      previousWeightKg: 170,
    ),
    PersonalRecord(
      exercise: 'Overhead Press',
      weightKg: 60,
      dateAchieved: now.subtract(const Duration(days: 20)),
      previousWeightKg: 57.5,
    ),
    PersonalRecord(
      exercise: 'Barbell Row',
      weightKg: 85,
      dateAchieved: now.subtract(const Duration(days: 8)),
      previousWeightKg: 80,
    ),
    PersonalRecord(
      exercise: 'Pull-Up',
      weightKg: 30, // weighted
      dateAchieved: now.subtract(const Duration(days: 3)),
      previousWeightKg: 25,
    ),
  ];
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final prDataProvider = Provider<List<PersonalRecord>>((ref) {
  return generateMockPRData();
});

// ---------------------------------------------------------------------------
// Widget
// ---------------------------------------------------------------------------

class PersonalRecordsBoard extends ConsumerWidget {
  const PersonalRecordsBoard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).extension<DigitalAtelierExtension>()!;
    final prs = ref.watch(prDataProvider);
    final now = DateTime.now();

    if (prs.isEmpty) return _EmptyState(t: t);

    return Semantics(
      label:
          'Personal records board. ${prs.length} records. '
          '${prs.where((pr) => pr.isRecent(now)).length} recent PRs.',
      child: Container(
        decoration: t.cardDecoration,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.emoji_events, color: t.accentPrimary, size: 22),
                const SizedBox(width: 8),
                Text('Personal Records', style: t.textTheme.h3),
              ],
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final crossCount = constraints.maxWidth > 600 ? 3 : 2;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossCount,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.4,
                  ),
                  itemCount: prs.length,
                  itemBuilder: (context, index) {
                    final pr = prs[index];
                    final isRecent = pr.isRecent(now);
                    return _PRCard(pr: pr, isRecent: isRecent, t: t);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// PR Card
// ---------------------------------------------------------------------------

class _PRCard extends StatelessWidget {
  const _PRCard({required this.pr, required this.isRecent, required this.t});

  final PersonalRecord pr;
  final bool isRecent;
  final DigitalAtelierExtension t;

  @override
  Widget build(BuildContext context) {
    final accentColor = isRecent
        ? const Color(0xFFFFD700) // gold
        : const Color(0xFFC0C0C0); // silver
    final daysAgo = DateTime.now().difference(pr.dateAchieved).inDays;
    final dateLabel = daysAgo == 0
        ? 'Today'
        : daysAgo == 1
        ? 'Yesterday'
        : '$daysAgo days ago';

    return Semantics(
      label:
          '${pr.exercise}: ${pr.weightKg.toStringAsFixed(0)} kg. '
          'Achieved $dateLabel ago. '
          'Improvement: ${pr.improvementPct.toStringAsFixed(1)}%.',
      button: true,
      child: GestureDetector(
        onTap: () => _showPRHistory(context, pr),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: t.surfaceInput,
            borderRadius: BorderRadius.circular(t.radiusMd),
            border: Border.all(
              color: isRecent
                  ? accentColor.withValues(alpha: 0.4)
                  : t.surfaceBorder,
              width: isRecent ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      pr.exercise,
                      style: t.textTheme.caption.copyWith(
                        color: t.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isRecent)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(t.radiusPill),
                      ),
                      child: Text(
                        'NEW',
                        style: TextStyle(
                          color: accentColor,
                          fontSize: 9,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${pr.weightKg.toStringAsFixed(0)} kg',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: accentColor,
                  height: 1.0,
                ),
              ),
              Row(
                children: [
                  Text(
                    dateLabel,
                    style: t.textTheme.caption.copyWith(fontSize: 10),
                  ),
                  const Spacer(),
                  if (pr.improvementPct > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: t.accentTertiary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(t.radiusPill),
                      ),
                      child: Text(
                        '+${pr.improvementPct.toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: t.accentTertiary,
                          fontSize: 10,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPRHistory(BuildContext context, PersonalRecord pr) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final t2 = Theme.of(ctx).extension<DigitalAtelierExtension>()!;
        return Container(
          decoration: t2.modalDecoration,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(pr.exercise, style: t2.textTheme.h2),
              const SizedBox(height: 8),
              Text(
                'PR: ${pr.weightKg.toStringAsFixed(0)} kg',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  color: t2.accentPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Achieved ${_formatDate(pr.dateAchieved)}',
                style: t2.textTheme.body,
              ),
              if (pr.improvementPct > 0) ...[
                const SizedBox(height: 4),
                Text(
                  'Improved by ${pr.improvementPct.toStringAsFixed(1)}% '
                  '(from ${pr.previousWeightKg.toStringAsFixed(0)} kg)',
                  style: t2.textTheme.body.copyWith(color: t2.accentTertiary),
                ),
              ],
              const SizedBox(height: 24),
              Text(
                'Full history will be shown when connected to workout data.',
                style: t2.textTheme.caption,
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(DateTime d) {
    const months = [
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
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
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
            Icon(Icons.emoji_events_outlined, color: t.textMuted, size: 40),
            const SizedBox(height: 12),
            Text(
              'No personal records yet',
              style: t.textTheme.body.copyWith(color: t.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
