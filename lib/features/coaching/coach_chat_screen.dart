import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:transformfit/theme/digital_atelier.dart';

// ============================================================================
// Coach Chat Screen — MacroFactor / Ladder / Whoop-quality
//
// Rich coaching UI with persona-aware cards, proactive suggestions,
// animated quick actions, and premium input area.
// ============================================================================

// ---------------------------------------------------------------------------
// Data model (API surface preserved)
// ---------------------------------------------------------------------------

class CoachMessage {
  const CoachMessage({
    required this.text,
    required this.isFromCoach,
    required this.timestamp,
    this.persona,
    this.confidence,
    this.sourceCount,
    this.observation,
    this.nextAction,
    this.isSuggestion = false,
  });

  final String text;
  final bool isFromCoach;
  final DateTime timestamp;
  final String? persona;
  final double? confidence;
  final int? sourceCount;
  final String? observation;
  final String? nextAction;
  final bool isSuggestion;
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
        observation: 'Sleep quality was 85% last night',
        nextAction: 'Complete a readiness check before your session',
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
        observation: 'Three consecutive sessions at 7+ RPE',
        nextAction: 'Push for a PR on the primary compound lift',
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

class _QuickAction {
  const _QuickAction({required this.icon, required this.label});
  final IconData icon;
  final String label;
}

const _defaultQuickActions = <_QuickAction>[
  _QuickAction(icon: Icons.trending_up, label: 'How am I doing?'),
  _QuickAction(icon: Icons.restaurant, label: 'What should I eat?'),
  _QuickAction(icon: Icons.self_improvement, label: 'I feel stressed'),
  _QuickAction(icon: Icons.fitness_center, label: 'Start workout'),
];

const _postWorkoutActions = <_QuickAction>[
  _QuickAction(icon: Icons.reviews, label: 'Review my session'),
  _QuickAction(icon: Icons.arrow_forward, label: "What's next?"),
  _QuickAction(icon: Icons.trending_up, label: 'How am I doing?'),
];

const _recoveryActions = <_QuickAction>[
  _QuickAction(icon: Icons.hotel, label: 'I need recovery'),
  _QuickAction(icon: Icons.wb_sunny_outlined, label: 'Light work today'),
  _QuickAction(icon: Icons.self_improvement, label: 'I feel stressed'),
];

const _streakActions = <_QuickAction>[
  _QuickAction(icon: Icons.local_fire_department, label: 'Keep my streak'),
  _QuickAction(icon: Icons.bolt, label: 'Quick session'),
  _QuickAction(icon: Icons.fitness_center, label: 'Start workout'),
];

// ---------------------------------------------------------------------------
// Coach persona metadata
// ---------------------------------------------------------------------------

class _PersonaMeta {
  const _PersonaMeta({
    required this.initial,
    required this.color,
    required this.name,
    required this.role,
    required this.icon,
  });
  final String initial;
  final Color color;
  final String name;
  final String role;
  final IconData icon;
}

_PersonaMeta _metaFor(String? persona) {
  // Use extension tokens for persona colors to avoid hardcoded values.
  return switch (persona) {
    'motivator' => const _PersonaMeta(
        initial: 'M',
        color: DigitalAtelierTokens.accentOrange,
        name: 'Motivator',
        role: 'Momentum builder',
        icon: Icons.local_fire_department,
      ),
    'analyst' => const _PersonaMeta(
        initial: 'A',
        color: DigitalAtelierTokens2.info,
        name: 'Analyst',
        role: 'Pattern interpreter',
        icon: Icons.insights,
      ),
    'challenger' => const _PersonaMeta(
        initial: 'C',
        color: DigitalAtelierTokens.errorText,
        name: 'Challenger',
        role: 'Standard-raiser',
        icon: Icons.speed,
      ),
    'zen' => _PersonaMeta(
        initial: 'Z',
        color: DigitalAtelierTokens2.recovery,
        name: 'Zen',
        role: 'Recovery stabilizer',
        icon: Icons.spa,
      ),
    _ => const _PersonaMeta(
        initial: 'C',
        color: DigitalAtelierTokens.accentOrange,
        name: 'Coach',
        role: 'AI coach',
        icon: Icons.psychology,
      ),
  };
}

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

  // Track if we're in a post-workout context.
  bool _postWorkout = false;
  bool _lowReadiness = false;
  final bool _streakAtRisk = false;

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
      lowerBound: 0.9,
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

  // -- Context-aware quick actions ------------------------------------------

  List<_QuickAction> get _currentQuickActions {
    if (_postWorkout) return _postWorkoutActions;
    if (_lowReadiness) return _recoveryActions;
    if (_streakAtRisk) return _streakActions;
    return _defaultQuickActions;
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

    // Detect context from user input.
    final lower = trimmed.toLowerCase();
    if (lower.contains('workout') || lower.contains('finished')) {
      _postWorkout = true;
    }
    if (lower.contains('stressed') || lower.contains('tired') ||
        lower.contains('exhausted')) {
      _lowReadiness = true;
    }

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

      // Proactive suggestion after certain contexts.
      if (_postWorkout) {
        Future<void>.delayed(const Duration(milliseconds: 800), () {
          if (!mounted) return;
          ref.read(chatMessagesProvider.notifier).add(CoachMessage(
            text: 'Great session. Your volume increased 8% this week.',
            isFromCoach: true,
            timestamp: DateTime.now(),
            persona: 'analyst',
            confidence: 0.91,
            sourceCount: 4,
            observation: 'Volume progression on track',
            nextAction: 'Prioritize protein intake in the next 2 hours',
            isSuggestion: true,
          ));
          setState(() {});
          _scrollToBottom();
        });
      }

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
        observation: 'Current protein intake estimated at 1.2 g/kg',
        nextAction: 'Aim for 40g protein in your next meal',
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
        observation: 'Elevated cortisol likely from poor sleep',
        nextAction: 'Try 10 minutes of guided breathing',
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
        nextAction: 'Begin with dynamic warm-up',
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
        observation: 'Weekly volume up 6% vs last week',
        nextAction: 'Maintain current intensity for 2 more sessions',
      );
    }

    if (lower.contains('recovery') || lower.contains('light')) {
      persona = 'zen';
      confidence = 0.88;
      return CoachMessage(
        text:
            'Smart call. Active recovery — walking, mobility, breathwork — '
            'preserves the adaptation signal without draining the tank. '
            'Come back stronger tomorrow.',
        isFromCoach: true,
        timestamp: DateTime.now(),
        persona: persona,
        confidence: confidence,
        sourceCount: 2,
        observation: 'Recovery score trending down over 48 hours',
        nextAction: '20 min walk + 10 min stretching',
      );
    }

    if (lower.contains('streak') || lower.contains('keep')) {
      persona = 'motivator';
      confidence = 0.85;
      return CoachMessage(
        text:
            'The streak is the proof you show up. A 15-minute session counts. '
            'Consistency beats intensity every time.',
        isFromCoach: true,
        timestamp: DateTime.now(),
        persona: persona,
        confidence: confidence,
        sourceCount: 2,
        observation: 'Current streak: 12 days',
        nextAction: 'Quick bodyweight circuit — 15 min is enough',
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
      nextAction: 'Log your last session or start a new one',
    );
  }

  Future<void> _scrollToBottom() async {
    await Future<void>.delayed(const Duration(milliseconds: 80));
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  // -- Build ----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatMessagesProvider);
    final meta = _metaFor(_currentPersona);

    return Semantics(
      label: 'AI coach chat screen',
      child: Scaffold(
        backgroundColor: DigitalAtelierTokens.background,
        appBar: _buildAppBar(meta),
        body: Column(
          children: [
            // Message list
            Expanded(
              child: messages.isEmpty
                  ? _buildEmptyState(meta)
                  : _buildMessageList(messages),
            ),
            // A11y live region for new messages.
            Semantics(
              liveRegion: true,
              label: _a11yAnnouncement,
              child: const SizedBox.shrink(),
            ),
            // Quick-action chips
            _buildQuickActions(),
            // Input area
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  // -- App bar --------------------------------------------------------------

  PreferredSizeWidget _buildAppBar(_PersonaMeta meta) {
    return AppBar(
      backgroundColor: DigitalAtelierTokens.background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: Semantics(
        label: 'Back',
        button: true,
        child: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: DigitalAtelierTokens.textPrimary,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: 'Back',
        ),
      ),
      title: Semantics(
        label: 'Current persona: ${meta.name}',
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Persona avatar with colored ring
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: meta.color, width: 1.5),
                color: meta.color.withValues(alpha: 0.15),
              ),
              alignment: Alignment.center,
              child: Icon(meta.icon, color: meta.color, size: 18),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${meta.name} coach',
                    style: const TextStyle(
                      fontFamily: DigitalAtelierTokens.coachVoiceFontFamily,
                      fontSize: 17,
                      color: DigitalAtelierTokens.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: meta.color,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        meta.role,
                        style: TextStyle(
                          fontFamily: DigitalAtelierTokens.dataFontFamily,
                          color: DigitalAtelierTokens.textPrimary
                              .withValues(alpha: 0.5),
                          fontSize: 11,
                        ),
                      ),
                    ],
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
            icon: Icon(Icons.swap_horiz, color: meta.color, size: 22),
            onPressed: () {
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
              // Re-animate chips for the new persona.
              _chipAnimCtrl.reset();
              _chipAnimCtrl.forward();
            },
            tooltip: 'Switch persona',
          ),
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  // -- Empty state ----------------------------------------------------------

  Widget _buildEmptyState(_PersonaMeta meta) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Large persona icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: meta.color.withValues(alpha: 0.12),
                border: Border.all(
                  color: meta.color.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Icon(meta.icon, color: meta.color, size: 36),
            ),
            const SizedBox(height: 24),
            Text(
              'Your coach is ready',
              style: const TextStyle(
                fontFamily: DigitalAtelierTokens.coachVoiceFontFamily,
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: DigitalAtelierTokens.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Ask anything or start a workout',
              style: TextStyle(
                fontFamily: DigitalAtelierTokens.dataFontFamily,
                fontSize: 14,
                color: DigitalAtelierTokens.textPrimary.withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            // Quick action chips in the empty state
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: _defaultQuickActions
                  .map((a) => _QuickActionChip(
                        action: a,
                        personaColor: meta.color,
                        onTap: () => _send(a.label),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  // -- Message list ---------------------------------------------------------

  Widget _buildMessageList(List<CoachMessage> messages) {
    return RefreshIndicator(
      color: DigitalAtelierTokens.accentOrange,
      backgroundColor: DigitalAtelierTokens.background,
      onRefresh: () => ref.read(chatMessagesProvider.notifier).loadOlder(),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        itemCount: messages.length + (_isCoachTyping ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == messages.length && _isCoachTyping) {
            return _TypingIndicator(
              animCtrl: _typingAnimCtrl,
              persona: _currentPersona,
            );
          }
          final msg = messages[index];

          // Insert a "Coach suggests..." divider before suggestion cards.
          if (msg.isSuggestion && msg.isFromCoach) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 8, top: 4),
                  child: Row(
                    children: [
                      Icon(Icons.auto_awesome,
                          size: 14,
                          color: _metaFor(msg.persona).color
                              .withValues(alpha: 0.6)),
                      const SizedBox(width: 6),
                      Text(
                        'Coach suggests…',
                        style: TextStyle(
                          fontFamily: DigitalAtelierTokens.dataFontFamily,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.8,
                          color: _metaFor(msg.persona).color
                              .withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                _CoachMessageCard(message: msg),
                const SizedBox(height: 12),
              ],
            );
          }

          if (msg.isFromCoach) {
            return _CoachMessageCard(message: msg);
          }
          return _UserMessageBubble(message: msg);
        },
      ),
    );
  }

  // -- Quick actions --------------------------------------------------------

  Widget _buildQuickActions() {
    final actions = _currentQuickActions;
    final meta = _metaFor(_currentPersona);

    return AnimatedBuilder(
      animation: _chipAnimCtrl,
      builder: (context, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: actions.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final stagger = (index * 0.12).clamp(0.0, 1.0);
                final t = (_chipAnimCtrl.value - stagger).clamp(0.0, 1.0);
                final opacity = Curves.easeOutCubic.transform(t);
                final slide = (1.0 - Curves.easeOutCubic.transform(t)) * 20;

                return Opacity(
                  opacity: opacity,
                  child: Transform.translate(
                    offset: Offset(0, slide),
                    child: _QuickActionChip(
                      action: actions[index],
                      personaColor: meta.color,
                      onTap: () => _send(actions[index].label),
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

  // -- Input area -----------------------------------------------------------

  Widget _buildInputArea() {
    final meta = _metaFor(_currentPersona);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Voice input button (UI only)
            Semantics(
              label: 'Voice input',
              button: true,
              child: Container(
                width: 44,
                height: 44,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  color: DigitalAtelierTokens2.surface,
                  borderRadius:
                      BorderRadius.circular(DigitalAtelierTokens2.radiusPill),
                  border: Border.all(
                    color: DigitalAtelierTokens2.surfaceBorder,
                    width: 1,
                  ),
                ),
                child: IconButton(
                  icon: Icon(Icons.mic_none_rounded,
                      color: DigitalAtelierTokens.textPrimary
                          .withValues(alpha: 0.5),
                      size: 20),
                  onPressed: () {
                    // Voice input placeholder — not yet functional.
                    HapticFeedback.lightImpact();
                  },
                  tooltip: 'Voice input',
                ),
              ),
            ),
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
                    height: 1.4,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Ask your coach…',
                    hintStyle: TextStyle(
                      fontFamily: DigitalAtelierTokens.dataFontFamily,
                      color: DigitalAtelierTokens.textPrimary
                          .withValues(alpha: 0.3),
                      fontSize: 15,
                    ),
                    filled: true,
                    fillColor: DigitalAtelierTokens2.surface,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        DigitalAtelierTokens2.radiusPill,
                      ),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        DigitalAtelierTokens2.radiusPill,
                      ),
                      borderSide: BorderSide(
                        color: meta.color.withValues(alpha: 0.5),
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
            const SizedBox(width: 10),
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
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: meta.color,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: meta.color.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.arrow_upward_rounded,
                      color: DigitalAtelierTokens.background,
                      size: 22,
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
// Coach message card — rich, full-width, persona-colored
// ---------------------------------------------------------------------------

class _CoachMessageCard extends StatelessWidget {
  const _CoachMessageCard({required this.message});

  final CoachMessage message;

  @override
  Widget build(BuildContext context) {
    final meta = _metaFor(message.persona);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: Curves.easeOut.transform(value),
          child: Transform.translate(
            offset: Offset(0, (1.0 - Curves.easeOut.transform(value)) * 16),
            child: child,
          ),
        );
      },
      child: Semantics(
        label: 'Coach message: ${message.text}',
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
                backgroundColor: DigitalAtelierTokens2.surfaceElevated,
                duration: const Duration(seconds: 2),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: DigitalAtelierTokens2.surface,
              borderRadius:
                  BorderRadius.circular(DigitalAtelierTokens2.radiusMd),
              border: Border(
                left: BorderSide(color: meta.color, width: 3),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Persona header row
                  Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: meta.color.withValues(alpha: 0.15),
                        ),
                        child: Icon(meta.icon, color: meta.color, size: 14),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        meta.name,
                        style: TextStyle(
                          fontFamily: DigitalAtelierTokens.dataFontFamily,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: meta.color,
                        ),
                      ),
                      const Spacer(),
                      // Confidence badge
                      if (message.confidence != null) ...[
                        _ConfidenceBadge(
                          confidence: message.confidence!,
                          color: meta.color,
                        ),
                      ],
                      if (message.sourceCount != null &&
                          message.sourceCount! > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: meta.color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(
                              DigitalAtelierTokens2.radiusSm,
                            ),
                          ),
                          child: Text(
                            '${message.sourceCount} sources',
                            style: TextStyle(
                              fontFamily: DigitalAtelierTokens.dataFontFamily,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: meta.color.withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Message body — Playfair for coach voice
                  Text(
                    message.text,
                    style: const TextStyle(
                      fontFamily: DigitalAtelierTokens.coachVoiceFontFamily,
                      color: DigitalAtelierTokens.textPrimary,
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),

                  // Observation + Next action structured sub-sections
                  if (message.observation != null ||
                      message.nextAction != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: meta.color.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(
                          DigitalAtelierTokens2.radiusSm,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (message.observation != null) ...[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.visibility_outlined,
                                    size: 14,
                                    color: meta.color.withValues(alpha: 0.7)),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    message.observation!,
                                    style: TextStyle(
                                      fontFamily:
                                          DigitalAtelierTokens.dataFontFamily,
                                      fontSize: 12,
                                      color: DigitalAtelierTokens.textPrimary
                                          .withValues(alpha: 0.7),
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (message.observation != null &&
                              message.nextAction != null)
                            const SizedBox(height: 8),
                          if (message.nextAction != null) ...[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.arrow_forward_rounded,
                                    size: 14,
                                    color: meta.color),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    message.nextAction!,
                                    style: TextStyle(
                                      fontFamily:
                                          DigitalAtelierTokens.dataFontFamily,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: meta.color.withValues(alpha: 0.9),
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 8),
                  // Timestamp
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      fontFamily: DigitalAtelierTokens.dataFontFamily,
                      color: DigitalAtelierTokens.textPrimary
                          .withValues(alpha: 0.3),
                      fontSize: 11,
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

  static String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

// ---------------------------------------------------------------------------
// Confidence badge
// ---------------------------------------------------------------------------

class _ConfidenceBadge extends StatelessWidget {
  const _ConfidenceBadge({required this.confidence, required this.color});

  final double confidence;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final pct = (confidence * 100).round();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(DigitalAtelierTokens2.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_outline, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            '$pct% confident',
            style: TextStyle(
              fontFamily: DigitalAtelierTokens.dataFontFamily,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// User message bubble
// ---------------------------------------------------------------------------

class _UserMessageBubble extends StatelessWidget {
  const _UserMessageBubble({required this.message});

  final CoachMessage message;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: Curves.easeOut.transform(value),
          child: Transform.translate(
            offset: Offset(0, (1.0 - Curves.easeOut.transform(value)) * 12),
            child: child,
          ),
        );
      },
      child: Semantics(
        label: 'You said: ${message.text}',
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
                backgroundColor: DigitalAtelierTokens2.surfaceElevated,
                duration: const Duration(seconds: 2),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    decoration: BoxDecoration(
                      color: DigitalAtelierTokens2.surfaceElevated,
                      borderRadius: BorderRadius.circular(
                        DigitalAtelierTokens2.radiusMd,
                      ).copyWith(
                        bottomRight: const Radius.circular(4),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          message.text,
                          style: const TextStyle(
                            fontFamily: DigitalAtelierTokens.dataFontFamily,
                            color: DigitalAtelierTokens.textPrimary,
                            fontSize: 15,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _formatTime(message.timestamp),
                          style: TextStyle(
                            fontFamily: DigitalAtelierTokens.dataFontFamily,
                            color: DigitalAtelierTokens.textPrimary
                                .withValues(alpha: 0.3),
                            fontSize: 11,
                          ),
                        ),
                      ],
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

  static String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

// ---------------------------------------------------------------------------
// Typing indicator — 3 dots with persona color, phase-offset bounce
// ---------------------------------------------------------------------------

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator({
    required this.animCtrl,
    required this.persona,
  });

  final AnimationController animCtrl;
  final String persona;

  @override
  Widget build(BuildContext context) {
    final meta = _metaFor(persona);

    return Semantics(
      label: 'Coach is typing',
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Mini persona avatar
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: meta.color.withValues(alpha: 0.15),
              ),
              child: Icon(meta.icon, color: meta.color, size: 14),
            ),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: DigitalAtelierTokens2.surface,
                borderRadius: BorderRadius.circular(
                  DigitalAtelierTokens2.radiusMd,
                ),
                border: Border(
                  left: BorderSide(
                    color: meta.color.withValues(alpha: 0.4),
                    width: 2,
                  ),
                ),
              ),
              child: AnimatedBuilder(
                animation: animCtrl,
                builder: (context, _) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(3, (i) {
                      final phase = (animCtrl.value + i * 0.3) % 1.0;
                      final dy = -5.0 *
                          (phase < 0.5
                              ? Curves.easeOut.transform(phase * 2)
                              : Curves.easeIn
                                  .transform((1.0 - phase) * 2));
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
// Quick-action chip — persona-aware
// ---------------------------------------------------------------------------

class _QuickActionChip extends StatelessWidget {
  const _QuickActionChip({
    required this.action,
    required this.onTap,
    required this.personaColor,
  });

  final _QuickAction action;
  final VoidCallback onTap;
  final Color personaColor;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Quick action: ${action.label}',
      button: true,
      child: SizedBox(
        height: 44, // Minimum touch target
        child: Material(
          color: DigitalAtelierTokens2.surface,
          borderRadius:
              BorderRadius.circular(DigitalAtelierTokens2.radiusPill),
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              onTap();
            },
            borderRadius:
                BorderRadius.circular(DigitalAtelierTokens2.radiusPill),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                borderRadius:
                    BorderRadius.circular(DigitalAtelierTokens2.radiusPill),
                border: Border.all(
                  color: DigitalAtelierTokens2.surfaceBorder,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(action.icon, size: 16, color: personaColor),
                  const SizedBox(width: 6),
                  Text(
                    action.label,
                    style: const TextStyle(
                      fontFamily: DigitalAtelierTokens.dataFontFamily,
                      color: DigitalAtelierTokens.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
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
