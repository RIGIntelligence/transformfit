import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:transformfit/theme/digital_atelier.dart';
import 'package:transformfit/widgets/tf_loading_skeleton.dart';

// ---------------------------------------------------------------------------
// Wellness dashboard screen — unified view of all wellness modules.
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

  // Loading state — set to true during data fetch.
  bool _isLoading = false;

  final List<_WellnessModule> _modules = const [
    _WellnessModule(
      title: 'Mood',
      icon: Icons.emoji_emotions_outlined,
      status: 'Good',
      score: 78,
      color: Color(0xFF22C55E),
      description: '4-day streak · Trending up',
    ),
    _WellnessModule(
      title: 'Stress',
      icon: Icons.self_improvement,
      status: 'Moderate',
      score: 62,
      color: Color(0xFFF59E0B),
      description: 'HRV-based · Recovery zone',
    ),
    _WellnessModule(
      title: 'Sleep',
      icon: Icons.bedtime_outlined,
      status: 'Good',
      score: 81,
      color: Color(0xFF3B82F6),
      description: '7.5h avg · 1 disturbance',
    ),
    _WellnessModule(
      title: 'Mindfulness',
      icon: Icons.spa_outlined,
      status: 'Active',
      score: 65,
      color: Color(0xFF8B5CF6),
      description: '3 sessions this week',
    ),
    _WellnessModule(
      title: 'Burnout Risk',
      icon: Icons.local_fire_department_outlined,
      status: 'Low',
      score: 22,
      color: Color(0xFF10B981),
      description: 'Load within safe range',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
              icon: const Icon(Icons.arrow_back,
                  color: DigitalAtelierTokens.textPrimary),
              onPressed: () => Navigator.of(context).maybePop(),
              tooltip: 'Back',
            ),
          ),
          title: Text(
            'Wellness',
            style: theme.textTheme.titleLarge?.copyWith(
              fontFamily: DigitalAtelierTokens.coachVoiceFontFamily,
              color: DigitalAtelierTokens.textPrimary,
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: _isLoading
              ? TfLoadingSkeleton.dashboard()
              : LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 600;
              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: wide ? 40 : 20,
                  vertical: 20,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _WellnessScoreHeader(
                          score: _overallScore,
                          zone: _overallZone,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Modules',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: DigitalAtelierTokens.textPrimary,
                            fontFamily:
                                DigitalAtelierTokens.coachVoiceFontFamily,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ..._modules.map(
                          (module) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _WellnessModuleCard(
                              module: module,
                              onTap: () => _showModuleDetail(context, module),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        _RecommendationsCard(),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _showModuleDetail(BuildContext context, _WellnessModule module) {
    showModalBottomSheet(
      context: context,
      backgroundColor: DigitalAtelierTokens2.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Semantics(
        label: '${module.title} detail',
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(module.icon, color: module.color, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    module.title,
                    style: TextStyle(
                      color: DigitalAtelierTokens.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      fontFamily: DigitalAtelierTokens.coachVoiceFontFamily,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: module.color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${module.score}/100',
                      style: TextStyle(
                        color: module.color,
                        fontWeight: FontWeight.w700,
                        fontFamily: DigitalAtelierTokens.dataFontFamily,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                module.description,
                style: TextStyle(
                  color:
                      DigitalAtelierTokens.textPrimary.withValues(alpha: 0.7),
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: module.score / 100,
                backgroundColor:
                    DigitalAtelierTokens.textPrimary.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation(module.color),
                borderRadius: BorderRadius.circular(4),
                minHeight: 6,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DigitalAtelierTokens.accentOrange,
                    foregroundColor: DigitalAtelierTokens.background,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                          DigitalAtelierTokens.cornerRadius),
                    ),
                  ),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Wellness score header
// ---------------------------------------------------------------------------

class _WellnessScoreHeader extends StatelessWidget {
  const _WellnessScoreHeader({required this.score, required this.zone});

  final double score;
  final String zone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final zoneColor = _zoneColor(zone);

    return Semantics(
      label: 'Overall wellness score: ${score.toStringAsFixed(0)} out of 100, zone: $zone',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: DigitalAtelierTokens2.surface,
          borderRadius:
              BorderRadius.circular(DigitalAtelierTokens.cornerRadius * 2),
          border: Border.all(
            color: DigitalAtelierTokens2.surfaceBorder,
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              'Wellness Score',
              style: theme.textTheme.titleSmall?.copyWith(
                color:
                    DigitalAtelierTokens.textPrimary.withValues(alpha: 0.6),
                fontFamily: DigitalAtelierTokens.dataFontFamily,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              score.toStringAsFixed(0),
              style: TextStyle(
                fontFamily: DigitalAtelierTokens.coachVoiceFontFamily,
                fontSize: 64,
                fontWeight: FontWeight.w700,
                color: zoneColor,
                height: 1,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: zoneColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                zone[0].toUpperCase() + zone.substring(1),
                style: TextStyle(
                  color: zoneColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  fontFamily: DigitalAtelierTokens.dataFontFamily,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: score / 100,
                backgroundColor:
                    DigitalAtelierTokens.textPrimary.withValues(alpha: 0.08),
                valueColor: AlwaysStoppedAnimation(zoneColor),
                minHeight: 8,
              ),
            ),
          ],
        ),
      ),
    );
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
        return DigitalAtelierTokens.accentOrange;
    }
  }
}

// ---------------------------------------------------------------------------
// Wellness module card
// ---------------------------------------------------------------------------

class _WellnessModule {
  const _WellnessModule({
    required this.title,
    required this.icon,
    required this.status,
    required this.score,
    required this.color,
    required this.description,
  });

  final String title;
  final IconData icon;
  final String status;
  final int score;
  final Color color;
  final String description;
}

class _WellnessModuleCard extends StatelessWidget {
  const _WellnessModuleCard({required this.module, this.onTap});

  final _WellnessModule module;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${module.title}: ${module.status}, score ${module.score}',
      button: true,
      child: Material(
        color: DigitalAtelierTokens2.surface,
        borderRadius:
            BorderRadius.circular(DigitalAtelierTokens.cornerRadius * 2),
        child: InkWell(
          onTap: onTap,
          borderRadius:
              BorderRadius.circular(DigitalAtelierTokens.cornerRadius * 2),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius:
                  BorderRadius.circular(DigitalAtelierTokens.cornerRadius * 2),
              border: Border.all(
                color: DigitalAtelierTokens2.surfaceBorder,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: module.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(module.icon, color: module.color, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        module.title,
                        style: TextStyle(
                          color: DigitalAtelierTokens.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        module.description,
                        style: TextStyle(
                          color: DigitalAtelierTokens.textPrimary
                              .withValues(alpha: 0.5),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      module.status,
                      style: TextStyle(
                        color: module.color,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: 60,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: module.score / 100,
                          backgroundColor: DigitalAtelierTokens.textPrimary
                              .withValues(alpha: 0.08),
                          valueColor: AlwaysStoppedAnimation(module.color),
                          minHeight: 4,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right,
                  color: DigitalAtelierTokens.textPrimary
                      .withValues(alpha: 0.3),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Recommendations card
// ---------------------------------------------------------------------------

class _RecommendationsCard extends StatelessWidget {
  final List<String> _recommendations = const [
    'Sleep quality is a bottleneck. Aim for 8+ hours tonight.',
    'Stress levels are elevated — try a 5-minute breathing exercise.',
    'Physical wellness is a strength (78/100). Maintain this.',
  ];

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Wellness recommendations',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: DigitalAtelierTokens2.surface,
          borderRadius:
              BorderRadius.circular(DigitalAtelierTokens.cornerRadius * 2),
          border: Border.all(
            color: DigitalAtelierTokens2.surfaceBorder,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb_outline,
                    color: DigitalAtelierTokens.accentOrange, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Recommendations',
                  style: TextStyle(
                    color: DigitalAtelierTokens.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: DigitalAtelierTokens.coachVoiceFontFamily,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._recommendations.map(
              (r) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: DigitalAtelierTokens.accentOrange,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        r,
                        style: TextStyle(
                          color: DigitalAtelierTokens.textPrimary
                              .withValues(alpha: 0.75),
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
