import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:transformfit/theme/digital_atelier.dart';

// ---------------------------------------------------------------------------
// Data model
// ---------------------------------------------------------------------------

class CoachMessage {
  const CoachMessage({
    required this.text,
    required this.isFromCoach,
    required this.timestamp,
    this.persona,
    this.confidence,
    this.sourceCount,
  });

  final String text;
  final bool isFromCoach;
  final DateTime timestamp;
  final String? persona;
  final double? confidence;
  final int? sourceCount;
}

// ---------------------------------------------------------------------------
// State provider (Riverpod 3.x Notifier)
// ---------------------------------------------------------------------------

final chatMessagesProvider =
    NotifierProvider<_ChatMessagesNotifier, List<CoachMessage>>(
  _ChatMessagesNotifier.new,
);

class _ChatMessagesNotifier extends Notifier<List<CoachMessage>> {
  @override
  List<CoachMessage> build() {
    return [
      CoachMessage(
        text:
            'Welcome back. Today counts if the work matches your energy. '
            'How are you feeling?',
        isFromCoach: true,
        timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
        persona: 'motivator',
        confidence: 0.82,
        sourceCount: 3,
      ),
    ];
  }

  void add(CoachMessage message) => state = [...state, message];

  /// Simulate older messages for pull-to-refresh.
  Future<void> loadOlder() async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    final older = <CoachMessage>[
      CoachMessage(
        text: 'Readiness is set. The target is 7 RPE. Earn the last set.',
        isFromCoach: true,
        timestamp: DateTime.now().subtract(const Duration(hours: 3)),
        persona: 'challenger',
        confidence: 0.87,
        sourceCount: 3,
      ),
      CoachMessage(
        text: 'I did 3 sets of bench and 2 sets of rows.',
        isFromCoach: false,
        timestamp: DateTime.now().subtract(
          const Duration(hours: 3, minutes: 1),
        ),
      ),
      CoachMessage(
        text:
            'Volume is tracking the progression corridor. '
            'Next session the bar moves — data says you are ready.',
        isFromCoach: true,
        timestamp: DateTime.now().subtract(
          const Duration(hours: 3, minutes: 2),
        ),
        persona: 'analyst',
        confidence: 0.86,
        sourceCount: 3,
      ),
    ];
    state = [...older, ...state];
  }
}

// ---------------------------------------------------------------------------
// Quick-action chip definitions
// ---------------------------------------------------------------------------

const _quickActions = <_QuickAction>[
  _QuickAction(icon: Icons.trending_up, label: 'How am I doing?'),
  _QuickAction(icon: Icons.restaurant, label: 'What should I eat?'),
  _QuickAction(icon: Icons.self_improvement, label: 'I feel stressed'),
  _QuickAction(icon: Icons.fitness_center, label: 'Start workout'),
];

class _QuickAction {
  const _QuickAction({required this.icon, required this.label});
  final IconData icon;
  final String label;
}

// ---------------------------------------------------------------------------
// Coach persona metadata
// ---------------------------------------------------------------------------

class _PersonaMeta {
  const _PersonaMeta(this.initial, this.color);
  final String initial;
  final Color color;
}

const _personaMeta = <String, _PersonaMeta>{
  'motivator': _PersonaMeta('M', Color(0xFFF97316)),
  'analyst': _PersonaMeta('A', Color(0xFF3B82F6)),
  'challenger': _PersonaMeta('C', Color(0xFFEF4444)),
  'zen': _PersonaMeta('Z', Color(0xFF10B981)),
};

IconData _personaIcon(String? persona) => switch (persona) {
      'motivator' => Icons.local_fire_department,
      'analyst' => Icons.insights,
      'challenger' => Icons.speed,
      'zen' => Icons.spa,
      _ => Icons.psychology,
    };

String _personaRole(String persona) => switch (persona) {
      'motivator' => 'Momentum builder',
      'analyst' => 'Pattern interpreter',
      'challenger' => 'Standard-raiser',
      'zen' => 'Recovery stabilizer',
      _ => 'AI coach',
    };

// ---------------------------------------------------------------------------
// Screen widget
// ---------------------------------------------------------------------------

class CoachChatScreen extends ConsumerStatefulWidget {
  const CoachChatScreen({super.key});

  @override
  ConsumerState<CoachChatScreen> createState() => _CoachChatScreenState();
}

class _CoachChatScreenState extends ConsumerState<CoachChatScreen>
    with TickerProviderStateMixin {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  bool _isCoachTyping = false;
  String _currentPersona = 'motivator';

  // Typing indicator animation controller.
  late final AnimationController _typingAnimCtrl;

  // Quick-action chip stagger animation.
  late final AnimationController _chipAnimCtrl;

  // Send-button press animation.
  late final AnimationController _sendAnimCtrl;

  // Live message announcement for screen readers.
  String _a11yAnnouncement = '';

  @override
  void initState() {
    super.initState();
    _typingAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _chipAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _sendAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.85,
      upperBound: 1.0,
    )..value = 1.0;
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _typingAnimCtrl.dispose();
    _chipAnimCtrl.dispose();
    _sendAnimCtrl.dispose();
    super.dispose();
  }

  // -- Send logic -----------------------------------------------------------

  void _send(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    ref.read(chatMessagesProvider.notifier).add(CoachMessage(
      text: trimmed,
      isFromCoach: false,
      timestamp: DateTime.now(),
    ));
    _inputController.clear();
    _focusNode.requestFocus();
    _scrollToBottom();

    setState(() => _isCoachTyping = true);

    // Simulate coach response after a short delay.
    Future<void>.delayed(const Duration(seconds: 1, milliseconds: 500), () {
      if (!mounted) return;
      final response = _simulateCoachResponse(trimmed);
      ref.read(chatMessagesProvider.notifier).add(response);
      setState(() {
        _isCoachTyping = false;
        _currentPersona = response.persona ?? _currentPersona;
      });
      _a11yAnnouncement = 'Coach says: ${response.text}';
      _scrollToBottom();
    });
  }

  CoachMessage _simulateCoachResponse(String userText) {
    final lower = userText.toLowerCase();
    String persona = 'motivator';
    double confidence = 0.82;
    int sourceCount = 3;

    if (lower.contains('eat') || lower.contains('nutrition')) {
      persona = 'analyst';
      confidence = 0.88;
      return CoachMessage(
        text:
            'Nutrition data is outside the session engine, but here is what '
            'the pattern shows: protein at 1.6 g per kg supports recovery on '
            'training days. Water intake above 2 litres is the easiest win.',
        isFromCoach: true,
        timestamp: DateTime.now(),
        persona: persona,
        confidence: confidence,
        sourceCount: sourceCount,
      );
    }

    if (lower.contains('stressed') || lower.contains('stress')) {
      persona = 'zen';
      confidence = 0.90;
      return CoachMessage(
        text:
            'Stress changes the recovery budget. Today counts if the work '
            'stays light: a walk, mobility, or a shortened session. '
            'Recovery is not passive — it is where the body integrates.',
        isFromCoach: true,
        timestamp: DateTime.now(),
        persona: persona,
        confidence: confidence,
        sourceCount: 2,
      );
    }

    if (lower.contains('workout') || lower.contains('start')) {
      persona = 'motivator';
      confidence = 0.78;
      return CoachMessage(
        text:
            'Ready to move. Start with a 30-second readiness check so '
            'today can match energy, sleep, and soreness. '
            'The first set is the whole game.',
        isFromCoach: true,
        timestamp: DateTime.now(),
        persona: persona,
        confidence: confidence,
        sourceCount: 3,
      );
    }

    if (lower.contains('how') && lower.contains('doing')) {
      persona = 'analyst';
      confidence = 0.86;
      return CoachMessage(
        text:
            'The ledger shows consistent effort. Volume trend is positive. '
            'Recovery windows are within range. The data says: keep going, '
            'and trust the next session.',
        isFromCoach: true,
        timestamp: DateTime.now(),
        persona: persona,
        confidence: confidence,
        sourceCount: 3,
      );
    }

    // Default challenger-flavored fallback.
    persona = 'challenger';
    confidence = 0.80;
    return CoachMessage(
      text:
          'The next move is the one in front of you. '
          'Log a set, track the data, and let the plan earn the next step.',
      isFromCoach: true,
      timestamp: DateTime.now(),
      persona: persona,
      confidence: confidence,
      sourceCount: 2,
    );
  }

  Future<void> _scrollToBottom() async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  // -- Build ----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatMessagesProvider);
    final theme = Theme.of(context);
    final meta = _personaMeta[_currentPersona] ??
        const _PersonaMeta('M', DigitalAtelierTokens.accentOrange);

    return Semantics(
      label: 'AI coach chat screen',
      child: Scaffold(
        backgroundColor: DigitalAtelierTokens.background,
        appBar: _buildAppBar(theme, meta),
        body: Column(
          children: [
            // Message list
            Expanded(
              child: Semantics(
                label: 'Message list',
                child: RefreshIndicator(
                  color: DigitalAtelierTokens.accentOrange,
                  backgroundColor: DigitalAtelierTokens.background,
                  onRefresh: () =>
                      ref.read(chatMessagesProvider.notifier).loadOlder(),
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    itemCount: messages.length + (_isCoachTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == messages.length && _isCoachTyping) {
                        return _TypingIndicatorBubble(
                          animCtrl: _typingAnimCtrl,
                          persona: _currentPersona,
                        );
                      }
                      final msg = messages[index];
                      return _MessageBubble(message: msg);
                    },
                  ),
                ),
              ),
            ),
            // A11y live region for new messages.
            Semantics(
              liveRegion: true,
              label: _a11yAnnouncement,
              child: const SizedBox.shrink(),
            ),
            // Quick-action chips
            _buildQuickActions(),
            // Input row
            _buildInputRow(theme),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme, _PersonaMeta meta) {
    return AppBar(
      backgroundColor: DigitalAtelierTokens.background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: Semantics(
        label: 'Back',
        button: true,
        child: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: DigitalAtelierTokens.textPrimary,
          ),
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: 'Back',
        ),
      ),
      title: Semantics(
        label: 'Current persona: $_currentPersona',
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: meta.color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                meta.initial,
                style: TextStyle(
                  fontFamily: DigitalAtelierTokens.coachVoiceFontFamily,
                  color: meta.color,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${_currentPersona[0].toUpperCase()}${_currentPersona.substring(1)} coach',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontFamily: DigitalAtelierTokens.coachVoiceFontFamily,
                      fontSize: 17,
                      color: DigitalAtelierTokens.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _personaRole(_currentPersona),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: DigitalAtelierTokens.textPrimary.withValues(
                        alpha: 0.5,
                      ),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      centerTitle: true,
      actions: [
        Semantics(
          label: 'Switch persona',
          button: true,
          child: IconButton(
            icon: Icon(_personaIcon(_currentPersona), color: meta.color),
            onPressed: () {
              // Cycle persona for demo purposes.
              setState(() {
                const personas = [
                  'motivator',
                  'analyst',
                  'challenger',
                  'zen',
                ];
                final idx = personas.indexOf(_currentPersona);
                _currentPersona = personas[(idx + 1) % personas.length];
              });
            },
            tooltip: 'Switch persona',
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return AnimatedBuilder(
      animation: _chipAnimCtrl,
      builder: (context, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _quickActions.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                // Stagger: each chip appears 100ms after the previous.
                final stagger = (index * 0.15).clamp(0.0, 1.0);
                final t = (_chipAnimCtrl.value - stagger).clamp(0.0, 1.0);
                final opacity = Curves.easeOut.transform(t);
                final slide = (1.0 - Curves.easeOut.transform(t)) * 16;

                return Opacity(
                  opacity: opacity,
                  child: Transform.translate(
                    offset: Offset(0, slide),
                    child: _QuickActionChip(
                      action: _quickActions[index],
                      onTap: () => _send(_quickActions[index].label),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildInputRow(ThemeData theme) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
        child: Row(
          children: [
            // Text input
            Expanded(
              child: Semantics(
                label: 'Message input',
                textField: true,
                child: TextField(
                  controller: _inputController,
                  focusNode: _focusNode,
                  style: const TextStyle(
                    fontFamily: DigitalAtelierTokens.dataFontFamily,
                    color: DigitalAtelierTokens.textPrimary,
                    fontSize: 15,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Ask your coach…',
                    hintStyle: TextStyle(
                      fontFamily: DigitalAtelierTokens.dataFontFamily,
                      color: DigitalAtelierTokens.textPrimary.withValues(
                        alpha: 0.35,
                      ),
                      fontSize: 15,
                    ),
                    filled: true,
                    fillColor: const Color(0xFF151515),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        DigitalAtelierTokens.cornerRadius,
                      ),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        DigitalAtelierTokens.cornerRadius,
                      ),
                      borderSide: const BorderSide(
                        color: DigitalAtelierTokens.accentOrange,
                        width: 1,
                      ),
                    ),
                  ),
                  textInputAction: TextInputAction.send,
                  onSubmitted: _send,
                  minLines: 1,
                  maxLines: 4,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Send button with press animation
            Semantics(
              label: 'Send message',
              button: true,
              child: GestureDetector(
                onTapDown: (_) => _sendAnimCtrl.reverse(),
                onTapUp: (_) {
                  _sendAnimCtrl.forward();
                  _send(_inputController.text);
                },
                onTapCancel: () => _sendAnimCtrl.forward(),
                child: ScaleTransition(
                  scale: _sendAnimCtrl,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: DigitalAtelierTokens.accentOrange,
                      borderRadius: BorderRadius.circular(
                        DigitalAtelierTokens.cornerRadius,
                      ),
                    ),
                    child: const Icon(
                      Icons.arrow_upward_rounded,
                      color: DigitalAtelierTokens.background,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Message bubble widget
// ---------------------------------------------------------------------------

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final CoachMessage message;

  @override
  Widget build(BuildContext context) {
    final isCoach = message.isFromCoach;
    final meta = isCoach
        ? (_personaMeta[message.persona] ??
            const _PersonaMeta('M', DigitalAtelierTokens.accentOrange))
        : null;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: Curves.easeOut.transform(value),
          child: Transform.translate(
            offset: Offset(0, (1.0 - Curves.easeOut.transform(value)) * 20),
            child: child,
          ),
        );
      },
      child: Semantics(
        label: isCoach
            ? 'Coach message: ${message.text}'
            : 'You said: ${message.text}',
        child: GestureDetector(
          onLongPress: () {
            Clipboard.setData(ClipboardData(text: message.text));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Message copied',
                  style: TextStyle(
                    fontFamily: DigitalAtelierTokens.dataFontFamily,
                    color: DigitalAtelierTokens.textPrimary,
                  ),
                ),
                backgroundColor: const Color(0xFF1A1A1A),
                duration: const Duration(seconds: 2),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              mainAxisAlignment:
                  isCoach ? MainAxisAlignment.start : MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (isCoach) ...[
                  // Persona avatar
                  Semantics(
                    label: '${message.persona ?? 'Coach'} avatar',
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: meta!.color.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        meta.initial,
                        style: TextStyle(
                          fontFamily: DigitalAtelierTokens.coachVoiceFontFamily,
                          color: meta.color,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                // Bubble content
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isCoach
                          ? meta!.color.withValues(alpha: 0.10)
                          : const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(
                        DigitalAtelierTokens.cornerRadius,
                      ).copyWith(
                        bottomLeft: isCoach
                            ? const Radius.circular(0)
                            : Radius.circular(
                                DigitalAtelierTokens.cornerRadius,
                              ),
                        bottomRight: isCoach
                            ? Radius.circular(
                                DigitalAtelierTokens.cornerRadius,
                              )
                            : const Radius.circular(0),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Message text
                        Text(
                          message.text,
                          style: TextStyle(
                            fontFamily: isCoach
                                ? DigitalAtelierTokens.coachVoiceFontFamily
                                : DigitalAtelierTokens.dataFontFamily,
                            color: DigitalAtelierTokens.textPrimary,
                            fontSize: 15,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Meta row: timestamp + confidence + source badge
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _formatTime(message.timestamp),
                              style: TextStyle(
                                fontFamily: DigitalAtelierTokens.dataFontFamily,
                                color: DigitalAtelierTokens.textPrimary
                                    .withValues(alpha: 0.35),
                                fontSize: 11,
                              ),
                            ),
                            if (isCoach && message.confidence != null) ...[
                              const SizedBox(width: 8),
                              Text(
                                '${(message.confidence! * 100).round()}% confidence',
                                style: TextStyle(
                                  fontFamily:
                                      DigitalAtelierTokens.dataFontFamily,
                                  color: meta!.color.withValues(alpha: 0.6),
                                  fontSize: 10,
                                ),
                              ),
                            ],
                            if (isCoach &&
                                message.sourceCount != null &&
                                message.sourceCount! > 0) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: meta!.color.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: Text(
                                  '${message.sourceCount} src',
                                  style: TextStyle(
                                    fontFamily:
                                        DigitalAtelierTokens.dataFontFamily,
                                    color: meta.color.withValues(alpha: 0.7),
                                    fontSize: 9,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                if (!isCoach) const SizedBox(width: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

// ---------------------------------------------------------------------------
// Typing indicator (3 bouncing dots)
// ---------------------------------------------------------------------------

class _TypingIndicatorBubble extends StatelessWidget {
  const _TypingIndicatorBubble({
    required this.animCtrl,
    required this.persona,
  });

  final AnimationController animCtrl;
  final String persona;

  @override
  Widget build(BuildContext context) {
    final meta = _personaMeta[persona] ??
        const _PersonaMeta('M', DigitalAtelierTokens.accentOrange);

    return Semantics(
      label: 'Coach is typing',
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: meta.color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                meta.initial,
                style: TextStyle(
                  fontFamily: DigitalAtelierTokens.coachVoiceFontFamily,
                  color: meta.color,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: meta.color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(
                  DigitalAtelierTokens.cornerRadius,
                ).copyWith(bottomLeft: const Radius.circular(0)),
              ),
              child: AnimatedBuilder(
                animation: animCtrl,
                builder: (context, _) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(3, (i) {
                      // Phase offset each dot by 0.25.
                      final phase = (animCtrl.value + i * 0.25) % 1.0;
                      final dy = -6.0 *
                          (phase < 0.5
                              ? Curves.easeOut.transform(phase * 2)
                              : Curves.easeIn.transform((1.0 - phase) * 2));
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: Transform.translate(
                          offset: Offset(0, dy),
                          child: Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: meta.color.withValues(alpha: 0.6),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      );
                    }),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Quick-action chip
// ---------------------------------------------------------------------------

class _QuickActionChip extends StatelessWidget {
  const _QuickActionChip({required this.action, required this.onTap});

  final _QuickAction action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Quick action: ${action.label}',
      button: true,
      child: SizedBox(
        height: 44, // Minimum touch target
        child: Material(
          color: const Color(0xFF151515),
          borderRadius: BorderRadius.circular(
            DigitalAtelierTokens.cornerRadius,
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(
              DigitalAtelierTokens.cornerRadius,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    action.icon,
                    size: 16,
                    color: DigitalAtelierTokens.accentOrange,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    action.label,
                    style: const TextStyle(
                      fontFamily: DigitalAtelierTokens.dataFontFamily,
                      color: DigitalAtelierTokens.textPrimary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
