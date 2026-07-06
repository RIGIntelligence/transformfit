import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


// ============================================================================
// Coach Chat Screen — v4 Design System
//
// Clean message bubbles, no metadata, Playfair for coach voice,
// pill-shaped input with quick-action chips.
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

  late final AnimationController _typingAnimCtrl;

  String _a11yAnnouncement = '';

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
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _typingAnimCtrl.dispose();
    super.dispose();
  }

  List<_QuickAction> get _currentQuickActions {
    if (_postWorkout) return _postWorkoutActions;
    if (_lowReadiness) return _recoveryActions;
    if (_streakAtRisk) return _streakActions;
    return _defaultQuickActions;
  }

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

    final lower = trimmed.toLowerCase();
    if (lower.contains('workout') || lower.contains('finished')) {
      _postWorkout = true;
    }
    if (lower.contains('stressed') || lower.contains('tired') ||
        lower.contains('exhausted')) {
      _lowReadiness = true;
    }

    setState(() => _isCoachTyping = true);

    Future<void>.delayed(const Duration(seconds: 1, milliseconds: 500), () {
      if (!mounted) return;
      final response = _simulateCoachResponse(trimmed);
      ref.read(chatMessagesProvider.notifier).add(response);
      setState(() {
        _isCoachTyping = false;
        _currentPersona = response.persona ?? _currentPersona;
      });

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

    return Semantics(
      label: 'AI coach chat screen',
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0A0A),
        resizeToAvoidBottomInset: true,
        appBar: _buildAppBar(),
        body: Column(
          children: [
            // Message list
            Expanded(
              child: messages.isEmpty
                  ? _buildEmptyState()
                  : _buildMessageList(messages),
            ),
            // A11y live region
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

  // -- App bar — just "Coach" -----------------------------------------------

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF0A0A0A),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: Semantics(
        label: 'Back',
        button: true,
        child: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: 'Back',
        ),
      ),
      title: const Text(
        'Coach',
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      centerTitle: true,
    );
  }

  // -- Empty state ----------------------------------------------------------

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF141414),
              ),
              child: const Icon(
                Icons.chat_bubble_outline,
                color: Color(0xFF8E8E93),
                size: 36,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Your coach is ready',
              style: TextStyle(
                fontFamily: 'Playfair',
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Ask anything or start a workout',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: _defaultQuickActions
                  .map((a) => _QuickActionChip(
                        action: a,
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
      color: const Color(0xFFFF6B35),
      backgroundColor: const Color(0xFF0A0A0A),
      onRefresh: () => ref.read(chatMessagesProvider.notifier).loadOlder(),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        itemCount: messages.length + (_isCoachTyping ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == messages.length && _isCoachTyping) {
            return _TypingIndicator(animCtrl: _typingAnimCtrl);
          }
          final msg = messages[index];

          if (msg.isFromCoach) {
            return _CoachBubble(message: msg);
          }
          return _UserBubble(message: msg);
        },
      ),
    );
  }

  // -- Quick actions --------------------------------------------------------

  Widget _buildQuickActions() {
    final actions = _currentQuickActions;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: SizedBox(
        height: 44,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: actions.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            return _QuickActionChip(
              action: actions[index],
              onTap: () => _send(actions[index].label),
            );
          },
        ),
      ),
    );
  }

  // -- Input area — pill shape, surfaceInput bg, accent send button ---------

  Widget _buildInputArea() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Text input — pill-shaped, surfaceInput bg
            Expanded(
              child: Semantics(
                label: 'Message input',
                textField: true,
                child: TextField(
                  controller: _inputController,
                  focusNode: _focusNode,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: Colors.white,
                    fontSize: 15,
                    height: 1.4,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: TextStyle(
                      fontFamily: 'Inter',
                      color: Colors.white.withValues(alpha: 0.3),
                      fontSize: 15,
                    ),
                    filled: true,
                    fillColor: const Color(0xFF1C1C1C),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(999),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(999),
                      borderSide: const BorderSide(
                        color: Color(0xFF1E1E1E),
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
            // Send button — accent primary
            Semantics(
              label: 'Send message',
              button: true,
              child: GestureDetector(
                onTap: () => _send(_inputController.text),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF6B35),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_upward_rounded,
                    color: Colors.white,
                    size: 22,
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
// Coach bubble — left-aligned, surface bg, 16px radius, Playfair font
// ---------------------------------------------------------------------------

class _CoachBubble extends StatelessWidget {
  const _CoachBubble({required this.message});

  final CoachMessage message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Coach message: ${message.text}',
      child: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onLongPress: () {
                Clipboard.setData(ClipboardData(text: message.text));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text(
                      'Message copied',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: Colors.white,
                      ),
                    ),
                    backgroundColor: const Color(0xFF1C1C1C),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.8,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF141414),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  message.text,
                  style: const TextStyle(
                    fontFamily: 'Playfair',
                    color: Colors.white,
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
              ),
            ),
            // Timestamp — 13px, tertiary color
            Padding(
              padding: const EdgeInsets.only(left: 4, top: 4, bottom: 8),
              child: Text(
                _formatTime(message.timestamp),
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: Color(0xFF48484A),
                  fontSize: 13,
                ),
              ),
            ),
          ],
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
// User bubble — right-aligned, accent bg, 16px radius, Inter font
// ---------------------------------------------------------------------------

class _UserBubble extends StatelessWidget {
  const _UserBubble({required this.message});

  final CoachMessage message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'You said: ${message.text}',
      child: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            GestureDetector(
              onLongPress: () {
                Clipboard.setData(ClipboardData(text: message.text));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text(
                      'Message copied',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: Colors.white,
                      ),
                    ),
                    backgroundColor: const Color(0xFF1C1C1C),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.8,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B35),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  message.text,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: Colors.white,
                    fontSize: 15,
                    height: 1.45,
                  ),
                ),
              ),
            ),
            // Timestamp — 13px, tertiary color
            Padding(
              padding: const EdgeInsets.only(right: 4, top: 4, bottom: 8),
              child: Text(
                _formatTime(message.timestamp),
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: Color(0xFF48484A),
                  fontSize: 13,
                ),
              ),
            ),
          ],
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
// Typing indicator — 3 pulsing dots, left-aligned
// ---------------------------------------------------------------------------

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator({required this.animCtrl});

  final AnimationController animCtrl;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Coach is typing',
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF141414),
                borderRadius: BorderRadius.circular(16),
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
                            decoration: const BoxDecoration(
                              color: Color(0xFF48484A),
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
// Quick-action chip — surface bg, pill shape
// ---------------------------------------------------------------------------

class _QuickActionChip extends StatelessWidget {
  const _QuickActionChip({
    required this.action,
    required this.onTap,
  });

  final _QuickAction action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Quick action: ${action.label}',
      button: true,
      child: SizedBox(
        height: 44,
        child: Material(
          color: const Color(0xFF141414),
          borderRadius: BorderRadius.circular(999),
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              onTap();
            },
            borderRadius: BorderRadius.circular(999),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(action.icon, size: 16, color: const Color(0xFF8E8E93)),
                  const SizedBox(width: 6),
                  Text(
                    action.label,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      color: Colors.white,
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
