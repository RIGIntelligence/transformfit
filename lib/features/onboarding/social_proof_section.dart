/// M5: Social proof testimonial cards for the landing screen.
///
/// Swipeable horizontal list of testimonial cards with avatars,
/// quotes, names, and roles. Uses DigitalAtelier tokens.
library;

import 'package:flutter/material.dart';
import 'package:transformfit/theme/digital_atelier.dart';

// ── Testimonial Model ────────────────────────────────────────────────────

/// A user testimonial with avatar, quote, and metadata.
class Testimonial {
  const Testimonial({
    required this.name,
    required this.role,
    required this.quote,
    this.avatarInitials,
    this.rating = 5,
  });

  final String name;
  final String role;
  final String quote;
  final String? avatarInitials;
  final int rating;

  /// Default testimonials for the app.
  static const List<Testimonial> defaults = [
    Testimonial(
      name: 'Sarah K.',
      role: 'Lost 12kg in 4 months',
      quote: 'The coach adjusted my plan when I was tired — I didn\'t even have to think. Down 12kg and stronger than ever.',
      avatarInitials: 'SK',
      rating: 5,
    ),
    Testimonial(
      name: 'Marcus T.',
      role: 'Intermediate lifter',
      quote: 'I\'d been stuck at the same bench for a year. The progression logic broke my plateau in 3 weeks.',
      avatarInitials: 'MT',
      rating: 5,
    ),
    Testimonial(
      name: 'Priya R.',
      role: 'Busy professional',
      quote: 'I only have 45 minutes, 3 days a week. The plan is tight, no wasted sets, and I\'m still making gains.',
      avatarInitials: 'PR',
      rating: 5,
    ),
    Testimonial(
      name: 'James L.',
      role: 'Beginner, 6 months in',
      quote: 'Never knew where to start. The onboarding walked me through everything. Now I walk into the gym with a plan.',
      avatarInitials: 'JL',
      rating: 5,
    ),
  ];
}

// ── Social Proof Section Widget ──────────────────────────────────────────

/// Swipeable horizontal list of testimonial cards.
///
/// Each card shows a user avatar (initials), quote, name, and role.
/// Cards have a subtle gradient background.
class SocialProofSection extends StatelessWidget {
  const SocialProofSection({
    super.key,
    this.testimonials = Testimonial.defaults,
  });

  final List<Testimonial> testimonials;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<DigitalAtelierExtension>()!;
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth * 0.78;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('From people like you', style: t.textTheme.h3),
        SizedBox(height: t.spaceXs),
        Text(
          '${testimonials.length * 120}+ users building better habits',
          style: t.textTheme.bodySmall,
        ),
        SizedBox(height: t.spaceLg),

        // Swipeable cards
        SizedBox(
          height: 180,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: t.spaceLg),
            itemCount: testimonials.length,
            separatorBuilder: (_, _) => SizedBox(width: t.spaceMd),
            itemBuilder: (context, index) {
              return _TestimonialCard(
                testimonial: testimonials[index],
                width: cardWidth,
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Testimonial Card ─────────────────────────────────────────────────────

class _TestimonialCard extends StatelessWidget {
  const _TestimonialCard({
    required this.testimonial,
    required this.width,
  });

  final Testimonial testimonial;
  final double width;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<DigitalAtelierExtension>()!;

    return Container(
      width: width,
      padding: EdgeInsets.all(t.spaceLg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(t.radiusLg),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            t.surfaceElevated,
            t.surface,
          ],
        ),
        border: Border.all(color: t.surfaceBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: avatar + stars
          Row(
            children: [
              // Avatar circle with initials
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [t.accentPrimary, t.accentSecondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Text(
                    testimonial.avatarInitials ?? testimonial.name.substring(0, 2).toUpperCase(),
                    style: TextStyle(
                      color: t.textInverse,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              SizedBox(width: t.spaceSm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      testimonial.name,
                      style: t.textTheme.body.copyWith(fontWeight: FontWeight.w600),
                    ),
                    Text(testimonial.role, style: t.textTheme.caption),
                  ],
                ),
              ),
              // Star rating
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (i) => Icon(
                  Icons.star,
                  size: 12,
                  color: i < testimonial.rating
                      ? t.accentPrimary
                      : t.surfaceBorder,
                )),
              ),
            ],
          ),

          SizedBox(height: t.spaceMd),

          // Quote
          Expanded(
            child: Text(
              '"${testimonial.quote}"',
              style: t.textTheme.bodySmall.copyWith(
                fontStyle: FontStyle.italic,
                height: 1.5,
                color: t.textSecondary,
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
