import 'package:flutter/material.dart';
import 'package:transformfit/theme/digital_atelier.dart';

/// Reusable section header with icon, title, and optional trailing action.
///
/// Animates in with a fade + slide when [animate] is true.
class TfSectionHeader extends StatefulWidget {
  const TfSectionHeader({
    super.key,
    required this.title,
    this.icon,
    this.trailing,
    this.onTrailingTap,
    this.trailingLabel,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    this.animate = true,
    this.animationDelay = Duration.zero,
    this.semanticLabel,
  });

  final String title;
  final IconData? icon;
  final IconData? trailing;
  final VoidCallback? onTrailingTap;
  final String? trailingLabel;
  final EdgeInsets padding;
  final bool animate;
  final Duration animationDelay;
  final String? semanticLabel;

  @override
  State<TfSectionHeader> createState() => _TfSectionHeaderState();
}

class _TfSectionHeaderState extends State<TfSectionHeader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _opacity = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    if (widget.animate) {
      Future.delayed(widget.animationDelay, () {
        if (mounted) _controller.forward();
      });
    } else {
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.semanticLabel ?? widget.title,
      header: true,
      child: FadeTransition(
        opacity: _opacity,
        child: SlideTransition(
          position: _slide,
          child: Padding(
            padding: widget.padding,
            child: Row(
              children: [
                if (widget.icon != null) ...[
                  Icon(
                    widget.icon,
                    size: 18,
                    color: DigitalAtelierTokens.accentOrange,
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    widget.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontFamily: DigitalAtelierTokens.dataFontFamily,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: DigitalAtelierTokens.textPrimary,
                        ),
                  ),
                ),
                if (widget.trailing != null)
                  Semantics(
                    label: widget.trailingLabel ?? 'Action',
                    button: true,
                    child: GestureDetector(
                      onTap: widget.onTrailingTap,
                      child: Icon(
                        widget.trailing,
                        size: 20,
                        color: DigitalAtelierTokens.textPrimary.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
