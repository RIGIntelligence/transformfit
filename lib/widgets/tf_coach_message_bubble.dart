import 'package:flutter/material.dart';
import 'package:transformfit/theme/digital_atelier.dart';

/// Chat bubble for AI coach messages with typing indicator, persona avatar,
/// and slide-in animation.
class TfCoachMessageBubble extends StatefulWidget {
  const TfCoachMessageBubble({
    super.key,
    required this.message,
    this.avatarUrl,
    this.avatarFallbackIcon = Icons.auto_awesome,
    this.isTyping = false,
    this.isFromUser = false,
    this.animationDuration = const Duration(milliseconds: 400),
    this.semanticLabel,
  });

  final String message;
  final String? avatarUrl;
  final IconData avatarFallbackIcon;
  final bool isTyping;
  final bool isFromUser;
  final Duration animationDuration;
  final String? semanticLabel;

  @override
  State<TfCoachMessageBubble> createState() => _TfCoachMessageBubbleState();
}

class _TfCoachMessageBubbleState extends State<TfCoachMessageBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset(widget.isFromUser ? 0.3 : -0.3, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _fadeAnimation = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isUser = widget.isFromUser;

    return Semantics(
      label: widget.semanticLabel ??
          (widget.isTyping
              ? 'Coach is typing'
              : 'Coach message: ${widget.message}'),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              mainAxisAlignment:
                  isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (!isUser) _buildAvatar(),
                if (!isUser) const SizedBox(width: 10),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isUser
                          ? DigitalAtelierTokens.accentOrange
                          : const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isUser ? 16 : 4),
                        bottomRight: Radius.circular(isUser ? 4 : 16),
                      ),
                      border: isUser
                          ? null
                          : Border.all(
                              color: DigitalAtelierTokens.accentOrange
                                  .withValues(alpha: 0.15),
                              width: 1,
                            ),
                    ),
                    child: widget.isTyping
                        ? _TypingIndicator(
                            color: isUser
                                ? DigitalAtelierTokens.background
                                : DigitalAtelierTokens.textPrimary,
                          )
                        : Text(
                            widget.message,
                            style: TextStyle(
                              fontFamily:
                                  isUser
                                      ? DigitalAtelierTokens.dataFontFamily
                                      : DigitalAtelierTokens
                                          .coachVoiceFontFamily,
                              fontSize: isUser ? 14 : 15,
                              height: 1.4,
                              color: isUser
                                  ? DigitalAtelierTokens.background
                                  : DigitalAtelierTokens.textPrimary,
                            ),
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

  Widget _buildAvatar() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: DigitalAtelierTokens.accentOrange.withValues(alpha: 0.2),
        border: Border.all(
          color: DigitalAtelierTokens.accentOrange.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: widget.avatarUrl != null
          ? ClipOval(
              child: Image.network(
                widget.avatarUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Icon(
                  widget.avatarFallbackIcon,
                  size: 16,
                  color: DigitalAtelierTokens.accentOrange,
                ),
              ),
            )
          : Icon(
              widget.avatarFallbackIcon,
              size: 16,
              color: DigitalAtelierTokens.accentOrange,
            ),
    );
  }
}

/// Animated three-dot typing indicator.
class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator({required this.color});

  final Color color;

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final delay = i * 0.2;
            final t = (_controller.value + delay) % 1.0;
            final opacity = (t < 0.5 ? t * 2 : (1 - t) * 2).clamp(0.2, 1.0);
            return Padding(
              padding: EdgeInsets.only(right: i < 2 ? 5 : 0),
              child: Opacity(
                opacity: opacity,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.color,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
