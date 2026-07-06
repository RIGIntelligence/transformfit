import 'package:flutter/material.dart';
import 'package:transformfit/theme/digital_atelier.dart';

/// Calm-quality smooth progress bar for onboarding.
///
/// Shows step X of N with smooth animation and gradient fill.
///
/// Usage:
///   AnimatedProgressBar(
///     currentStep: 2,
///     totalSteps: 5,
///     stepLabels: ['Welcome', 'Goals', 'Body', 'Preferences', 'Plan'],
///   )
class AnimatedProgressBar extends StatefulWidget {
  const AnimatedProgressBar({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    this.stepLabels,
    this.animate = true,
  })  : assert(currentStep >= 0),
        assert(totalSteps > 0);

  /// Current step (0-indexed).
  final int currentStep;

  /// Total number of steps.
  final int totalSteps;

  /// Optional labels for each step. Length must match [totalSteps].
  final List<String>? stepLabels;

  /// Whether to animate transitions.
  final bool animate;

  @override
  State<AnimatedProgressBar> createState() => _AnimatedProgressBarState();
}

class _AnimatedProgressBarState extends State<AnimatedProgressBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late double _previousProgress;
  late double _targetProgress;

  @override
  void initState() {
    super.initState();
    _previousProgress = 0;
    _targetProgress = _computeProgress();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedProgressBar old) {
    super.didUpdateWidget(old);
    if (old.currentStep != widget.currentStep) {
      _previousProgress = _targetProgress;
      _targetProgress = _computeProgress();
      _controller.forward(from: 0);
    }
  }

  double _computeProgress() {
    if (widget.totalSteps <= 1) return 1.0;
    return widget.currentStep / (widget.totalSteps - 1);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<DigitalAtelierExtension>()!;

    return AnimatedBuilder(
      animation: CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
      builder: (context, _) {
        final animatedProgress =
            _previousProgress + (_targetProgress - _previousProgress) * _controller.value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Step counter
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Step ${widget.currentStep + 1} of ${widget.totalSteps}',
                  style: t.textTheme.caption.copyWith(
                    color: t.textSecondary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  '${(animatedProgress * 100).round()}%',
                  style: t.textTheme.caption.copyWith(
                    color: t.accentPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            SizedBox(height: t.spaceSm),

            // Progress bar
            _GradientProgressBar(
              progress: animatedProgress,
              gradient: LinearGradient(
                colors: [t.accentPrimary, t.accentSecondary],
              ),
              trackColor: t.surfaceBorder,
              height: 8,
              borderRadius: t.radiusPill,
            ),

            // Step labels
            if (widget.stepLabels != null) ...[
              SizedBox(height: t.spaceMd),
              _StepLabels(
                labels: widget.stepLabels!,
                currentStep: widget.currentStep,
                progress: animatedProgress,
              ),
            ],
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Gradient progress bar
// ---------------------------------------------------------------------------

class _GradientProgressBar extends StatelessWidget {
  const _GradientProgressBar({
    required this.progress,
    required this.gradient,
    required this.trackColor,
    required this.height,
    required this.borderRadius,
  });

  final double progress;
  final LinearGradient gradient;
  final Color trackColor;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        return Container(
          height: height,
          decoration: BoxDecoration(
            color: trackColor,
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              width: w * progress.clamp(0.0, 1.0),
              height: height,
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(borderRadius),
                boxShadow: [
                  BoxShadow(
                    color: gradient.colors.first.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Step labels — appear as you progress
// ---------------------------------------------------------------------------

class _StepLabels extends StatelessWidget {
  const _StepLabels({
    required this.labels,
    required this.currentStep,
    required this.progress,
  });

  final List<String> labels;
  final int currentStep;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<DigitalAtelierExtension>()!;

    return Row(
      children: List.generate(labels.length, (index) {
        final isCompleted = index < currentStep;
        final isCurrent = index == currentStep;

        return Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Dot indicator
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: isCurrent ? 10 : 6,
                height: isCurrent ? 10 : 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted
                      ? t.accentPrimary
                      : isCurrent
                          ? t.accentSecondary
                          : t.surfaceBorder,
                  border: isCurrent
                      ? Border.all(
                          color: t.accentSecondary.withValues(alpha: 0.3),
                          width: 3,
                        )
                      : null,
                ),
              ),
              SizedBox(height: t.spaceXs),

              // Label — fades in as step is approached
              AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: isCompleted || isCurrent ? 1.0 : 0.4,
                child: Text(
                  labels[index],
                  style: t.textTheme.caption.copyWith(
                    fontSize: 10,
                    color: isCurrent ? t.textPrimary : t.textMuted,
                    fontWeight:
                        isCurrent ? FontWeight.w600 : FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
