import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:transformfit/theme/digital_atelier.dart';

/// Tracks how the coach adapts its style over 30 days.
///
/// The coach persona evolves from highly directive (beginner-friendly) to
/// collaborative (autonomous user) as the user builds consistency.
///
/// Usage:
///   CoachPersonalityEvolution(currentDay: 18)
class CoachPersonalityEvolution extends StatelessWidget {
  const CoachPersonalityEvolution({
    super.key,
    required this.currentDay,
    this.history,
  }) : assert(currentDay >= 0 && currentDay <= 30);

  /// Current day in the 30-day coaching journey (0–30).
  final int currentDay;

  /// Optional historical persona data. If null, a simulated curve is used.
  final List<PersonaSnapshot>? history;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<DigitalAtelierExtension>()!;
    final data = history ?? _simulateEvolution();
    final currentPersona = PersonaSnapshot.atDay(currentDay);

    return Container(
      decoration: t.cardDecoration,
      padding: EdgeInsets.all(t.spaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.psychology, color: t.accentSecondary, size: 20),
              SizedBox(width: t.spaceSm),
              Text('Coach Evolution', style: t.textTheme.h3),
            ],
          ),
          SizedBox(height: t.spaceLg),

          // Current persona indicator
          _CurrentPersonaCard(persona: currentPersona),
          SizedBox(height: t.spaceLg),

          // Timeline visualization
          SizedBox(
            height: 120,
            child: CustomPaint(
              size: const Size(double.infinity, 120),
              painter: _EvolutionTimelinePainter(
                data: data,
                currentDay: currentDay,
                directiveColor: t.accentPrimary,
                collaborativeColor: t.accentSecondary,
                trackColor: t.surfaceBorder,
                textMuted: t.textMuted,
              ),
            ),
          ),
          SizedBox(height: t.spaceMd),

          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _LegendItem(color: t.accentPrimary, label: 'Directive'),
              _LegendItem(color: t.accentSecondary, label: 'Collaborative'),
            ],
          ),
          SizedBox(height: t.spaceLg),

          // Phase markers
          _PhaseRow(currentDay: currentDay),
        ],
      ),
    );
  }

  List<PersonaSnapshot> _simulateEvolution() {
    return List.generate(31, (day) => PersonaSnapshot.atDay(day));
  }
}

// ---------------------------------------------------------------------------
// Data model
// ---------------------------------------------------------------------------

/// A snapshot of the coach persona at a specific day.
class PersonaSnapshot {
  const PersonaSnapshot({
    required this.day,
    required this.directiveShare,
    required this.persona,
    required this.description,
  });

  final int day;
  final double directiveShare; // 0.0–1.0
  final CoachPersona persona;
  final String description;

  /// Compute the persona for a given day using the adaptive curve.
  /// Starts at 80% directive → 20% directive over 30 days.
  factory PersonaSnapshot.atDay(int day) {
    final t = (day / 30).clamp(0.0, 1.0);
    // Ease-out cubic: starts fast, slows down
    final eased = 1 - math.pow(1 - t, 3).toDouble();
    final directiveShare = 0.8 - (0.6 * eased); // 0.8 → 0.2

    final persona = CoachPersona.fromDirectiveShare(directiveShare);
    return PersonaSnapshot(
      day: day,
      directiveShare: directiveShare,
      persona: persona,
      description: persona.description,
    );
  }
}

/// The 4 coaching persona phases.
enum CoachPersona {
  drillSergeant(
    label: 'Drill Sergeant',
    iconData: Icons.military_tech,
    threshold: 0.65,
    description:
        'Clear instructions, specific targets, minimal questions. '
        '"Do 3 sets of 10 reps at 60kg."',
  ),
  mentor(
    label: 'Mentor',
    iconData: Icons.school,
    threshold: 0.45,
    description:
        'Guided with reasoning. Explains the why behind choices. '
        '"Try 60kg — here\'s why it fits your goal."',
  ),
  collaborator(
    label: 'Collaborator',
    iconData: Icons.handshake,
    threshold: 0.30,
    description:
        'Asks for input, offers options. You decide. '
        '"Want to go heavier or add a set?"',
  ),
  advisor(
    label: 'Advisor',
    iconData: Icons.lightbulb_outline,
    threshold: 0.0,
    description:
        'Available when asked. Trusts your judgment. '
        '"I\'m here if you need me."',
  );

  const CoachPersona({
    required this.label,
    required this.iconData,
    required this.threshold,
    required this.description,
  });

  final String label;
  final IconData iconData;
  final double threshold;
  final String description;

  static CoachPersona fromDirectiveShare(double share) {
    if (share >= 0.65) return CoachPersona.drillSergeant;
    if (share >= 0.45) return CoachPersona.mentor;
    if (share >= 0.30) return CoachPersona.collaborator;
    return CoachPersona.advisor;
  }
}

// ---------------------------------------------------------------------------
// Current persona card
// ---------------------------------------------------------------------------

class _CurrentPersonaCard extends StatelessWidget {
  const _CurrentPersonaCard({required this.persona});
  final PersonaSnapshot persona;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<DigitalAtelierExtension>()!;
    final color = Color.lerp(
      t.accentPrimary,
      t.accentSecondary,
      1.0 - persona.directiveShare,
    )!;

    return Container(
      padding: EdgeInsets.all(t.spaceMd),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(t.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(persona.persona.iconData, color: color, size: 20),
              SizedBox(width: t.spaceSm),
              Text(
                persona.persona.label,
                style: t.textTheme.h3.copyWith(color: color),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: t.spaceSm,
                  vertical: t.spaceXs,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(t.radiusPill),
                ),
                child: Text(
                  'Day ${persona.day}',
                  style: t.textTheme.caption.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: t.spaceSm),
          Text(persona.description, style: t.textTheme.bodySmall),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Timeline painter
// ---------------------------------------------------------------------------

class _EvolutionTimelinePainter extends CustomPainter {
  _EvolutionTimelinePainter({
    required this.data,
    required this.currentDay,
    required this.directiveColor,
    required this.collaborativeColor,
    required this.trackColor,
    required this.textMuted,
  });

  final List<PersonaSnapshot> data;
  final int currentDay;
  final Color directiveColor;
  final Color collaborativeColor;
  final Color trackColor;
  final Color textMuted;

  @override
  void paint(Canvas canvas, Size size) {
    final padding = 20.0;
    final chartW = size.width - padding * 2;
    final chartH = size.height - 30;

    // Background track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawLine(
      Offset(padding, chartH),
      Offset(size.width - padding, chartH),
      trackPaint,
    );

    // Draw the directive-share curve
    final path = Path();
    for (int i = 0; i < data.length; i++) {
      final x = padding + (i / 30) * chartW;
      final y = chartH - (data[i].directiveShare * chartH);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    // Gradient fill under curve
    final fillPath = Path.from(path)
      ..lineTo(size.width - padding, chartH)
      ..lineTo(padding, chartH)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          directiveColor.withValues(alpha: 0.3),
          directiveColor.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, chartH));
    canvas.drawPath(fillPath, fillPaint);

    // Stroke
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..shader = LinearGradient(
        colors: [directiveColor, collaborativeColor],
      ).createShader(Rect.fromLTWH(0, 0, size.width, chartH));
    canvas.drawPath(path, strokePaint);

    // Current day marker
    final markerX = padding + (currentDay / 30) * chartW;
    final markerY =
        chartH - (PersonaSnapshot.atDay(currentDay).directiveShare * chartH);

    // Vertical line
    canvas.drawLine(
      Offset(markerX, markerY),
      Offset(markerX, chartH),
      Paint()
        ..color = directiveColor.withValues(alpha: 0.3)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke,
    );

    // Dot
    canvas.drawCircle(
      Offset(markerX, markerY),
      6,
      Paint()..color = directiveColor,
    );
    canvas.drawCircle(
      Offset(markerX, markerY),
      3,
      Paint()..color = Colors.white,
    );

    // Day labels
    const labels = [0, 7, 14, 21, 30];
    for (final day in labels) {
      final x = padding + (day / 30) * chartW;
      final tp = TextPainter(
        text: TextSpan(
          text: 'D$day',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 10,
            color: textMuted,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, chartH + 8));
    }
  }

  @override
  bool shouldRepaint(_EvolutionTimelinePainter old) =>
      currentDay != old.currentDay;
}

// ---------------------------------------------------------------------------
// Supporting widgets
// ---------------------------------------------------------------------------

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<DigitalAtelierExtension>()!;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        SizedBox(width: t.spaceXs),
        Text(label, style: t.textTheme.caption),
      ],
    );
  }
}

class _PhaseRow extends StatelessWidget {
  const _PhaseRow({required this.currentDay});
  final int currentDay;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<DigitalAtelierExtension>()!;
    const phases = [
      _PhaseMarker(label: 'Onboarding', day: 0, icon: Icons.flag),
      _PhaseMarker(label: 'Building', day: 10, icon: Icons.construction),
      _PhaseMarker(label: 'Growing', day: 20, icon: Icons.trending_up),
      _PhaseMarker(label: 'Autonomy', day: 30, icon: Icons.auto_awesome),
    ];

    return Row(
      children: phases.map((phase) {
        final isActive = currentDay >= phase.day;
        final isCurrent =
            currentDay >= phase.day && currentDay < phase.day + 10;
        return Expanded(
          child: Column(
            children: [
              Icon(
                phase.icon,
                size: 16,
                color: isCurrent
                    ? t.accentPrimary
                    : isActive
                        ? t.accentSecondary
                        : t.textMuted,
              ),
              SizedBox(height: t.spaceXs),
              Text(
                phase.label,
                style: t.textTheme.caption.copyWith(
                  color: isCurrent ? t.accentPrimary : t.textMuted,
                  fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _PhaseMarker {
  const _PhaseMarker({
    required this.label,
    required this.day,
    required this.icon,
  });

  final String label;
  final int day;
  final IconData icon;
}
