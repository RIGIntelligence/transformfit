import 'package:flutter/material.dart';
import 'package:transformfit/theme/digital_atelier.dart';
import 'package:transformfit/widgets/tf_shimmer_loading.dart';

/// Reusable loading skeleton with shimmer effect for cards and lists.
///
/// Provides pre-built skeletons for common UI patterns:
/// - [TfLoadingSkeleton.card] — single card skeleton
/// - [TfLoadingSkeleton.list] — list of card skeletons
/// - [TfLoadingSkeleton.dashboard] — dashboard grid skeleton
///
/// Usage:
///   if (isLoading) TfLoadingSkeleton.card()
class TfLoadingSkeleton extends StatelessWidget {
  const TfLoadingSkeleton({
    super.key,
    required this.child,
  });

  /// Single card skeleton with avatar, title, and body lines.
  factory TfLoadingSkeleton.card({Key? key}) {
    return TfLoadingSkeleton(
      key: key,
      child: const _SkeletonCard(),
    );
  }

  /// List of [count] card skeletons (default 3).
  factory TfLoadingSkeleton.list({Key? key, int count = 3}) {
    return TfLoadingSkeleton(
      key: key,
      child: _SkeletonList(count: count),
    );
  }

  /// Dashboard grid skeleton with metric cards and a chart placeholder.
  factory TfLoadingSkeleton.dashboard({Key? key}) {
    return TfLoadingSkeleton(
      key: key,
      child: const _SkeletonDashboard(),
    );
  }

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<DigitalAtelierExtension>()!;

    return Semantics(
      label: 'Loading content',
      liveRegion: true,
      child: Padding(
        padding: EdgeInsets.all(t.spaceLg),
        child: child,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private skeleton shapes
// ---------------------------------------------------------------------------

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<DigitalAtelierExtension>()!;

    return Container(
      padding: EdgeInsets.all(t.spaceLg),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(t.radiusMd),
        border: Border.all(color: t.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: avatar + title
          Row(
            children: [
              TfShimmerAvatar(size: 40),
              SizedBox(width: t.spaceMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TfShimmerBox(width: 140, height: 14),
                    SizedBox(height: t.spaceXs),
                    TfShimmerBox(width: 100, height: 10),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: t.spaceLg),
          // Body lines
          const TfShimmerBox(height: 14),
          SizedBox(height: t.spaceSm),
          const TfShimmerBox(height: 14),
          SizedBox(height: t.spaceSm),
          TfShimmerBox(width: 180, height: 14),
        ],
      ),
    );
  }
}

class _SkeletonList extends StatelessWidget {
  const _SkeletonList({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<DigitalAtelierExtension>()!;

    return Column(
      children: [
        for (int i = 0; i < count; i++) ...[
          const _SkeletonCard(),
          if (i < count - 1) SizedBox(height: t.spaceMd),
        ],
      ],
    );
  }
}

class _SkeletonDashboard extends StatelessWidget {
  const _SkeletonDashboard();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<DigitalAtelierExtension>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header skeleton
        TfShimmerBox(width: 120, height: 20),
        SizedBox(height: t.spaceLg),

        // Metric cards row
        Row(
          children: [
            Expanded(child: _MetricSkeleton()),
            SizedBox(width: t.spaceMd),
            Expanded(child: _MetricSkeleton()),
          ],
        ),
        SizedBox(height: t.spaceLg),

        // Chart placeholder
        Container(
          height: 180,
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: BorderRadius.circular(t.radiusMd),
            border: Border.all(color: t.surfaceBorder),
          ),
          child: const Center(
            child: TfShimmerBox(width: 120, height: 120),
          ),
        ),
        SizedBox(height: t.spaceLg),

        // Another card
        const _SkeletonCard(),
      ],
    );
  }
}

class _MetricSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<DigitalAtelierExtension>()!;

    return Container(
      padding: EdgeInsets.all(t.spaceLg),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(t.radiusMd),
        border: Border.all(color: t.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TfShimmerBox(width: 60, height: 10),
          SizedBox(height: t.spaceSm),
          TfShimmerBox(width: 48, height: 24),
          SizedBox(height: t.spaceXs),
          TfShimmerBox(width: 80, height: 10),
        ],
      ),
    );
  }
}
