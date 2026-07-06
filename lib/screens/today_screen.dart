import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:transformfit/app_providers.dart';
import 'package:transformfit/config/runtime_flags.dart';
import 'package:transformfit/dev/visual_smoke_state.dart';
import 'package:transformfit/features/behavior/behavioral_repair_loop.dart';
import 'package:transformfit/features/auth/auth_controller.dart';
import 'package:transformfit/features/coaching/coach_signal.dart';
import 'package:transformfit/features/coaching/dai_interface.dart';
import 'package:transformfit/features/session/local_session_cleanup.dart';
import 'package:transformfit/features/session/models.dart';
import 'package:transformfit/features/session/session_controller.dart';
import 'package:transformfit/navigation/auth_state.dart';
import 'package:transformfit/theme/digital_atelier.dart';

class TodayScreen extends ConsumerStatefulWidget {
  const TodayScreen({super.key});

  @override
  ConsumerState<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends ConsumerState<TodayScreen> {
  static const _sorenessOptions = ['hips', 'ankles', 'shoulders', 'back'];

  bool _signingOut = false;
  bool _syncingWearable = false;
  int _energyLevel = 7;
  int _sleepQuality = 7;
  Set<String> _selectedSoreness = {'hips', 'ankles'};
  String? _hydratedReadinessEntryId;
  int _debriefRpe = 6;
  int _debriefSatisfaction = 4;
  int _setWeightKg = 0;
  int _setReps = 10;
  int _setRpe = 6;
  int _nutritionProteinGrams = 120;
  final TextEditingController _exerciseController = TextEditingController(
    text: 'Warm-up reset',
  );
  final TextEditingController _nextFocusController = TextEditingController(
    text: 'Build from clean controlled reps.',
  );
  final TextEditingController _painNotesController = TextEditingController(
    text: 'No sharp pain today.',
  );

  List<String> get _selectedSorenessMap {
    final supported = _sorenessOptions.where(_selectedSoreness.contains);
    final unsupported = _selectedSoreness.where(
      (area) => !_sorenessOptions.contains(area),
    );
    return [...supported, ...unsupported];
  }

  bool _needsReadinessHydration(SessionState state) {
    final readiness = state.readinessEntry;
    if (readiness == null) return _hydratedReadinessEntryId != null;
    return state.activeSession == null &&
        _hydratedReadinessEntryId != readiness.id;
  }

  void _hydrateReadinessControls(SessionState state) {
    final readiness = state.readinessEntry;
    if (readiness == null) {
      _hydratedReadinessEntryId = null;
      return;
    }
    if (state.activeSession != null ||
        _hydratedReadinessEntryId == readiness.id) {
      return;
    }

    _hydratedReadinessEntryId = readiness.id;
    _energyLevel = readiness.energyLevel;
    _sleepQuality = readiness.sleepQuality;
    _selectedSoreness = readiness.sorenessMap.toSet();
  }

  @override
  void initState() {
    super.initState();
    _hydrateReadinessControls(ref.read(sessionStateProvider));
    ref.listenManual<SessionState>(sessionStateProvider, (_, next) {
      if (!_needsReadinessHydration(next)) return;
      setState(() => _hydrateReadinessControls(next));
    });
  }

  void _changeEnergyLevel(int delta) {
    setState(() {
      _energyLevel = (_energyLevel + delta).clamp(1, 10);
    });
  }

  void _changeSleepQuality(int delta) {
    setState(() {
      _sleepQuality = (_sleepQuality + delta).clamp(1, 10);
    });
  }

  void _toggleSorenessArea(String area) {
    setState(() {
      final next = {..._selectedSoreness};
      if (next.contains(area)) {
        next.remove(area);
      } else {
        next.add(area);
      }
      _selectedSoreness = next;
    });
  }

  void _submitReadinessCheckIn() {
    final controller = ref.read(sessionControllerProvider);
    if (controller.state.activeSession != null) return;
    final currentReadiness = controller.state.readinessEntry;
    controller.submitReadiness(
      energyLevel: _energyLevel,
      sleepQuality: _sleepQuality,
      sorenessMap: _selectedSorenessMap,
      hrv:
          currentReadiness?.hrv ??
          controller.state.wearableSignal?.heartRateVariabilityMs,
    );
  }

  void _changeDebriefRpe(int delta) {
    setState(() {
      _debriefRpe = (_debriefRpe + delta).clamp(1, 10);
    });
  }

  void _changeDebriefSatisfaction(int delta) {
    setState(() {
      _debriefSatisfaction = (_debriefSatisfaction + delta).clamp(1, 5);
    });
  }

  void _changeSetWeightKg(int delta) {
    setState(() {
      _setWeightKg = (_setWeightKg + (delta * 5)).clamp(0, 300);
    });
  }

  void _changeSetReps(int delta) {
    setState(() {
      _setReps = (_setReps + delta).clamp(1, 50);
    });
  }

  void _changeSetRpe(int delta) {
    setState(() {
      _setRpe = (_setRpe + delta).clamp(1, 10);
    });
  }

  void _changeNutritionProtein(int delta) {
    setState(() {
      _nutritionProteinGrams = (_nutritionProteinGrams + (delta * 15)).clamp(
        60,
        220,
      );
    });
  }

  void _changeExerciseName() {
    setState(() {});
  }

  void _applyNextSet() {
    final controller = ref.read(sessionControllerProvider);
    final active = controller.state.activeSession;
    if (active == null) return;

    final historyTopSet = _topWeightedSet(controller.state.history);
    final liveTopSet = _topWeightedSetIncludingActive(
      history: controller.state.history,
      active: active,
    );

    final step = historyTopSet == null
        ? null
        : _nextWarmupStepForSession(topSet: historyTopSet.set, session: active);
    if (step != null) {
      setState(() {
        _exerciseController.text = historyTopSet!.set.exerciseName;
        _setWeightKg = step.weightKg;
        _setReps = step.reps;
        _setRpe = step.rpe;
      });
      return;
    }

    final topSet = liveTopSet ?? historyTopSet;
    if (topSet == null) return;
    final target = _nextTargetForTopSet(
      topSet.set,
      volumeMultiplier: active.volumeMultiplier,
    );
    setState(() {
      _exerciseController.text = topSet.set.exerciseName;
      _setWeightKg = target.targetWeightKg;
      _setReps = target.targetReps;
      _setRpe = (topSet.set.rpe ?? _setRpe).clamp(1, 10).toInt();
    });
  }

  void _startTodaySession() {
    final controller = ref.read(sessionControllerProvider);
    if (controller.state.activeSession != null) return;
    if (controller.state.readinessEntry == null) {
      _submitReadinessCheckIn();
    }
    controller.startSession();
  }

  void _completeRecoveryAction(_RecoveryAction action) {
    final controller = ref.read(sessionControllerProvider);
    if (controller.state.activeSession != null ||
        controller.state.history.isNotEmpty) {
      return;
    }
    if (controller.state.readinessEntry == null) {
      _submitReadinessCheckIn();
    }
    controller.startSession();
    final active = controller.state.activeSession;
    if (active == null) return;

    controller.logSet(
      exerciseName: action.exerciseName,
      setNumber: active.loggedSets.length + 1,
      durationSeconds: action.durationSeconds,
      rpe: action.rpe,
    );
    controller.endSession(notes: action.sessionNotes);
    controller.submitDebrief(
      perceivedExertion: action.rpe,
      satisfaction: 4,
      painNotes: action.painNotes,
      whatWorked: action.whatWorked,
      whatToChange: action.whatToChange,
      nextSessionFocus: action.nextSessionFocus,
    );
  }

  void _logWorkoutSet() {
    final controller = ref.read(sessionControllerProvider);
    final active = controller.state.activeSession;
    if (active == null) return;
    final exerciseName = _exerciseController.text.trim();
    if (!_canLogWorkoutSet(exerciseName)) return;
    controller.logSet(
      exerciseName: exerciseName,
      setNumber: active.loggedSets.length + 1,
      weightKg: _setWeightKg == 0 ? null : _setWeightKg.toDouble(),
      reps: _setReps,
      rpe: _setRpe,
    );
  }

  void _undoLastWorkoutSet() {
    ref.read(sessionControllerProvider).removeLastSet();
  }

  void _finishTodaySession() {
    final controller = ref.read(sessionControllerProvider);
    if (controller.state.activeSession == null) return;
    final nextFocus = _nextFocusController.text.trim();
    final painNotes = _painNotesController.text.trim();
    controller.endSession(notes: 'Completed readiness-adjusted session.');
    controller.submitDebrief(
      perceivedExertion: _debriefRpe,
      satisfaction: _debriefSatisfaction,
      painNotes: painNotes.isEmpty ? null : painNotes,
      whatWorked: 'Kept the appointment and adjusted load.',
      whatToChange: 'Use today log to tune the next warm-up.',
      nextSessionFocus: nextFocus.isEmpty
          ? 'Build from clean controlled reps.'
          : nextFocus,
    );
  }

  void _createNutritionTarget() {
    ref
        .read(sessionControllerProvider)
        .setNutritionTarget(
          targetType: 'protein',
          label: 'Protein target',
          dailyTarget: _nutritionProteinGrams.toDouble(),
          unit: 'g/day',
        );
  }

  Future<void> _syncWearableFromAdapter() async {
    if (_syncingWearable) return;
    setState(() => _syncingWearable = true);
    try {
      final signal = await ref
          .read(wearableSyncAdapterProvider)
          .readDailySignal();
      ref.read(sessionControllerProvider).setWearableSignal(signal);
    } finally {
      if (mounted) setState(() => _syncingWearable = false);
    }
  }

  void _clearWearableSignal() {
    ref.read(sessionControllerProvider).clearWearableSignal();
  }

  Future<void> _signOut() async {
    if (_signingOut) return;
    setState(() => _signingOut = true);
    try {
      if (transformfitDemoMode) {
        ref
            .read(sessionControllerProvider)
            .restore(buildVisualSmokeSessionState());
        ref
            .read(authGuardStateProvider)
            .setStatus(AuthGuardStatus.authenticatedWithProfile);
        return;
      }
      try {
        await ref.read(authFacadeProvider).signOut();
      } catch (error) {
        debugPrint('signOut failed before local cleanup: ${error.runtimeType}');
      }
      await ref.read(localSessionCleanerProvider).clear();
      // Remote auth streams are the happy path; this keeps offline sign-out
      // fail-closed if no signedOut event arrives.
      ref
          .read(authGuardStateProvider)
          .setStatus(AuthGuardStatus.unauthenticated);
    } finally {
      if (mounted) setState(() => _signingOut = false);
    }
  }

  @override
  void dispose() {
    _exerciseController.dispose();
    _nextFocusController.dispose();
    _painNotesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final coachSignal = ref.watch(coachSignalProvider);
    final daiInterface = ref.watch(daiInterfaceProvider);
    final repairLoop = ref.watch(behavioralRepairLoopProvider);
    final sessionState = ref.watch(sessionStateProvider);
    final theme = Theme.of(context);
    final canStartSession = sessionState.activeSession == null;
    final hasLiveSession = sessionState.activeSession != null;
    final startSessionLabel = canStartSession
        ? 'Start today session'
        : 'Session already live';
    final startSessionText = canStartSession ? 'Start session' : 'Session live';

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 900;
            final sessionPlan = _SessionPlanPanel(state: sessionState);
            final readiness = _ReadinessPanel(
              state: sessionState,
              energyLevel: _energyLevel,
              sleepQuality: _sleepQuality,
              sorenessOptions: _sorenessOptions,
              selectedSoreness: _selectedSoreness,
              onEnergyChanged: _changeEnergyLevel,
              onSleepChanged: _changeSleepQuality,
              onSorenessToggled: _toggleSorenessArea,
              onSubmit: _submitReadinessCheckIn,
            );
            final recovery = _RecoveryPanel(
              state: sessionState,
              onRecoveryAction: _completeRecoveryAction,
            );
            final nutrition = _NutritionTargetPanel(
              state: sessionState,
              proteinGrams: _nutritionProteinGrams,
              onProteinChanged: _changeNutritionProtein,
              onCreateTarget: _createNutritionTarget,
            );
            final proof = _ProofPanel(state: sessionState);
            final liveDemoCommand =
                transformfitDemoMode && sessionState.activeSession != null
                ? _LiveDemoCommandPanel(
                    state: sessionState,
                    exerciseController: _exerciseController,
                    setWeightKg: _setWeightKg,
                    setReps: _setReps,
                    setRpe: _setRpe,
                    onApplyNextSet: _applyNextSet,
                    onLogWorkoutSet: _logWorkoutSet,
                    onFinishSession: _finishTodaySession,
                  )
                : null;
            final activationCorridor = _ActivationCorridorPanel(
              state: sessionState,
              coachSignal: coachSignal,
              dai: daiInterface,
              repair: repairLoop,
              onStartSession: _startTodaySession,
            );

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: wide ? 40 : 20,
                vertical: wide ? 32 : 20,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _TodayHeader(
                        coachSignal: coachSignal,
                        liveCommand: liveDemoCommand,
                      ),
                      const SizedBox(height: 16),
                      activationCorridor,
                      const SizedBox(height: 16),
                      _DaiInterfacePanel(
                        dai: daiInterface,
                        syncingWearable: _syncingWearable,
                        onSyncWearable: _syncWearableFromAdapter,
                        onClearWearableSignal: _clearWearableSignal,
                      ),
                      const SizedBox(height: 16),
                      _BehaviorRepairPanel(repair: repairLoop),
                      const SizedBox(height: 24),
                      if (wide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 6, child: sessionPlan),
                            const SizedBox(width: 16),
                            Expanded(flex: 4, child: readiness),
                          ],
                        )
                      else
                        Column(
                          children: [
                            sessionPlan,
                            const SizedBox(height: 16),
                            readiness,
                          ],
                        ),
                      const SizedBox(height: 16),
                      _SessionLoopPanel(
                        state: sessionState,
                        exerciseController: _exerciseController,
                        setWeightKg: _setWeightKg,
                        setReps: _setReps,
                        setRpe: _setRpe,
                        debriefRpe: _debriefRpe,
                        debriefSatisfaction: _debriefSatisfaction,
                        nextFocusController: _nextFocusController,
                        painNotesController: _painNotesController,
                        onSetWeightChanged: _changeSetWeightKg,
                        onSetRepsChanged: _changeSetReps,
                        onSetRpeChanged: _changeSetRpe,
                        onExerciseChanged: _changeExerciseName,
                        onDebriefRpeChanged: _changeDebriefRpe,
                        onDebriefSatisfactionChanged:
                            _changeDebriefSatisfaction,
                        onApplyNextSet: _applyNextSet,
                        onLogWorkoutSet: _logWorkoutSet,
                        onUndoLastSet: _undoLastWorkoutSet,
                        onFinishSession: _finishTodaySession,
                      ),
                      const SizedBox(height: 16),
                      nutrition,
                      const SizedBox(height: 16),
                      if (wide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: recovery),
                            const SizedBox(width: 16),
                            Expanded(child: proof),
                          ],
                        )
                      else
                        Column(
                          children: [
                            recovery,
                            const SizedBox(height: 16),
                            proof,
                          ],
                        ),
                      const SizedBox(height: 24),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          Semantics(
                            button: true,
                            enabled: canStartSession,
                            label: startSessionLabel,
                            excludeSemantics: true,
                            child: ElevatedButton(
                              onPressed: canStartSession
                                  ? _startTodaySession
                                  : null,
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(172, 48),
                                tapTargetSize: MaterialTapTargetSize.padded,
                                visualDensity: VisualDensity.standard,
                              ),
                              child: Text(startSessionText),
                            ),
                          ),
                          Semantics(
                            button: true,
                            label: 'Open profile',
                            child: OutlinedButton(
                              onPressed: () => context.go('/profile'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: theme.colorScheme.onSurface,
                                side: BorderSide(
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.24,
                                  ),
                                ),
                                minimumSize: const Size(148, 48),
                                tapTargetSize: MaterialTapTargetSize.padded,
                                visualDensity: VisualDensity.standard,
                              ),
                              child: const Text('Open profile'),
                            ),
                          ),
                          Semantics(
                            button: true,
                            label: 'Open proof card',
                            child: OutlinedButton.icon(
                              onPressed: () => context.go('/proof'),
                              icon: const Icon(Icons.ios_share),
                              label: const Text('Proof card'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: theme.colorScheme.onSurface,
                                side: BorderSide(
                                  color: theme.colorScheme.primary.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                                minimumSize: const Size(148, 48),
                                tapTargetSize: MaterialTapTargetSize.padded,
                                visualDensity: VisualDensity.standard,
                              ),
                            ),
                          ),
                          Semantics(
                            button: true,
                            label: 'Open coach command',
                            child: OutlinedButton.icon(
                              onPressed: () => context.go('/coach'),
                              icon: const Icon(Icons.psychology_alt_outlined),
                              label: const Text('Coach'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: theme.colorScheme.onSurface,
                                side: BorderSide(
                                  color: theme.colorScheme.primary.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                                minimumSize: const Size(136, 48),
                                tapTargetSize: MaterialTapTargetSize.padded,
                                visualDensity: VisualDensity.standard,
                              ),
                            ),
                          ),
                          Semantics(
                            button: true,
                            label: 'Open progress',
                            child: OutlinedButton.icon(
                              onPressed: () => context.go('/progress'),
                              icon: const Icon(Icons.insights_outlined),
                              label: const Text('Progress'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: theme.colorScheme.onSurface,
                                side: BorderSide(
                                  color: theme.colorScheme.primary.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                                minimumSize: const Size(148, 48),
                                tapTargetSize: MaterialTapTargetSize.padded,
                                visualDensity: VisualDensity.standard,
                              ),
                            ),
                          ),
                          Semantics(
                            button: true,
                            label: 'Open composition trust',
                            child: OutlinedButton.icon(
                              onPressed: () => context.go('/composition'),
                              icon: const Icon(Icons.verified_user_outlined),
                              label: const Text('Composition'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: theme.colorScheme.onSurface,
                                side: BorderSide(
                                  color: theme.colorScheme.primary.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                                minimumSize: const Size(156, 48),
                                tapTargetSize: MaterialTapTargetSize.padded,
                                visualDensity: VisualDensity.standard,
                              ),
                            ),
                          ),
                          if (hasLiveSession)
                            Semantics(
                              button: true,
                              label: 'Open live workout logger',
                              child: OutlinedButton.icon(
                                onPressed: () => context.go('/workout'),
                                icon: const Icon(Icons.fitness_center),
                                label: const Text('Live logger'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: theme.colorScheme.onSurface,
                                  side: BorderSide(
                                    color: theme.colorScheme.primary.withValues(
                                      alpha: 0.72,
                                    ),
                                  ),
                                  minimumSize: const Size(152, 48),
                                  tapTargetSize: MaterialTapTargetSize.padded,
                                  visualDensity: VisualDensity.standard,
                                ),
                              ),
                            ),
                          Semantics(
                            button: true,
                            label: 'Sign out',
                            child: TextButton(
                              onPressed: _signingOut ? null : _signOut,
                              style: TextButton.styleFrom(
                                minimumSize: const Size(116, 48),
                                tapTargetSize: MaterialTapTargetSize.padded,
                                visualDensity: VisualDensity.standard,
                              ),
                              child: _signingOut
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('Sign out'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const _QuickAccessSection(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _QuickAccessSection extends StatelessWidget {
  const _QuickAccessSection();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Quick access section',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Access',
            style: TextStyle(
              fontFamily: DigitalAtelierTokens.coachVoiceFontFamily,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: DigitalAtelierTokens.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _QuickAccessCard(
            icon: Icons.chat_bubble_outline,
            title: 'Coach Chat',
            subtitle: 'Talk to your AI coach',
            accentColor: const Color(0xFFF97316),
            onTap: () => context.go('/coach-chat'),
          ),
          const SizedBox(height: 10),
          _QuickAccessCard(
            icon: Icons.spa_outlined,
            title: 'Wellness',
            subtitle: 'Mood, stress, sleep & mindfulness',
            accentColor: const Color(0xFF8B5CF6),
            onTap: () => context.go('/wellness'),
          ),
          const SizedBox(height: 10),
          _QuickAccessCard(
            icon: Icons.restaurant_outlined,
            title: 'Nutrition',
            subtitle: 'Macros, water & supplements',
            accentColor: const Color(0xFF10B981),
            onTap: () => context.go('/nutrition'),
          ),
          const SizedBox(height: 10),
          _QuickAccessCard(
            icon: Icons.emoji_events_outlined,
            title: 'Achievements',
            subtitle: 'Level, streaks & milestones',
            accentColor: const Color(0xFFF59E0B),
            onTap: () => context.go('/gamification'),
          ),
          const SizedBox(height: 10),
          _QuickAccessCard(
            icon: Icons.fitness_center,
            title: 'Exercise Library',
            subtitle: '110 exercises with form cues',
            accentColor: const Color(0xFF3B82F6),
            onTap: () => context.go('/exercises'),
          ),
        ],
      ),
    );
  }
}

class _QuickAccessCard extends StatelessWidget {
  const _QuickAccessCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Open $title',
      button: true,
      child: Material(
        color: DigitalAtelierTokens2.surface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: DigitalAtelierTokens2.surfaceBorder,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: accentColor, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: DigitalAtelierTokens.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: DigitalAtelierTokens.textPrimary
                              .withValues(alpha: 0.5),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
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

class _TodayHeader extends StatelessWidget {
  const _TodayHeader({required this.coachSignal, this.liveCommand});

  final CoachSignal coachSignal;
  final Widget? liveCommand;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final compactLiveDemo = liveCommand != null && transformfitDemoMode;

    return _Panel(
      padding: EdgeInsets.all(compactLiveDemo ? 16 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            image: true,
            label: 'TransformFitAI logo',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.asset(
                'assets/brand/transformfitai-logo-original.jpg',
                width: compactLiveDemo ? 148 : 210,
                fit: BoxFit.contain,
              ),
            ),
          ),
          SizedBox(height: compactLiveDemo ? 14 : 24),
          Semantics(
            header: true,
            label: 'Today heading',
            child: Text('Today', style: theme.textTheme.headlineMedium),
          ),
          SizedBox(height: compactLiveDemo ? 8 : 12),
          Semantics(
            label: 'Coach note',
            child: Text(
              coachSignal.coachNote,
              style: theme.textTheme.bodyLarge,
            ),
          ),
          if (liveCommand != null) ...[
            SizedBox(height: compactLiveDemo ? 12 : 18),
            liveCommand!,
          ],
          if (compactLiveDemo) ...[
            const SizedBox(height: 12),
            Semantics(
              container: true,
              label:
                  '${coachSignal.observationLabel}: ${coachSignal.observation}',
              child: Text(
                '${coachSignal.observationLabel}: ${coachSignal.observation}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.78),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 18),
            Semantics(
              container: true,
              label: coachSignal.semanticLabel,
              child: ExcludeSemantics(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _CoachTracePill(
                      icon: Icons.psychology_alt_outlined,
                      label: coachSignal.personaLabel,
                    ),
                    _CoachTracePill(
                      icon: Icons.verified_outlined,
                      label: coachSignal.confidenceLabel,
                    ),
                    _CoachTracePill(
                      icon: Icons.source_outlined,
                      label: coachSignal.sourceTraceLabel,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            _CoachObservation(
              label: coachSignal.observationLabel,
              value: coachSignal.observation,
            ),
          ],
        ],
      ),
    );
  }
}

class _DaiInterfacePanel extends StatelessWidget {
  const _DaiInterfacePanel({
    required this.dai,
    required this.syncingWearable,
    required this.onSyncWearable,
    required this.onClearWearableSignal,
  });

  final DaiInterface dai;
  final bool syncingWearable;
  final VoidCallback onSyncWearable;
  final VoidCallback onClearWearableSignal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final connected = dai.wearableInsight.connected;

    return Semantics(
      container: true,
      label: dai.semanticLabel,
      child: _Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        header: true,
                        label: 'DAI interface',
                        child: Text(
                          'DAI interface',
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        dai.title,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _StatusPill(label: dai.confidenceLabel),
              ],
            ),
            const SizedBox(height: 14),
            _CoachObservation(label: 'DAI command', value: dai.primaryCommand),
            const SizedBox(height: 12),
            Text(dai.rationale, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _CoachTracePill(
                  icon: Icons.watch_outlined,
                  label: dai.wearableInsight.statusLabel,
                ),
                _CoachTracePill(
                  icon: Icons.speed_outlined,
                  label: dai.wearableInsight.modifierLabel,
                ),
                _CoachTracePill(
                  icon: Icons.source_outlined,
                  label: dai.sourceTraceLabel,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _DaiDataRow(
              label: 'Wearable status',
              value: dai.wearableInsight.detail,
            ),
            const SizedBox(height: 8),
            _DaiDataRow(
              label: 'Readiness modifier',
              value: dai.wearableInsight.modifierLabel,
            ),
            const SizedBox(height: 12),
            Text(
              dai.boundary,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.74),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                Semantics(
                  button: true,
                  enabled: !syncingWearable,
                  label: 'Sync wearable data',
                  excludeSemantics: true,
                  child: FilledButton.icon(
                    onPressed: syncingWearable ? null : onSyncWearable,
                    icon: const Icon(Icons.sync),
                    label: Text(
                      syncingWearable
                          ? 'Syncing wearable'
                          : connected
                          ? 'Refresh wearable'
                          : 'Connect wearable',
                    ),
                  ),
                ),
                if (connected)
                  Semantics(
                    button: true,
                    label: 'Clear wearable signal',
                    excludeSemantics: true,
                    child: OutlinedButton.icon(
                      onPressed: onClearWearableSignal,
                      icon: const Icon(Icons.link_off),
                      label: const Text('Clear wearable'),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivationCorridorPanel extends StatelessWidget {
  const _ActivationCorridorPanel({
    required this.state,
    required this.coachSignal,
    required this.dai,
    required this.repair,
    required this.onStartSession,
  });

  final SessionState state;
  final CoachSignal coachSignal;
  final DaiInterface dai;
  final BehavioralRepairLoop repair;
  final VoidCallback onStartSession;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final active = state.activeSession;
    final hasDebrief = state.lastDebrief != null;
    final primary = active != null
        ? 'Open the live logger'
        : hasDebrief
        ? 'Review progress'
        : 'Start the first set';
    final why = active != null
        ? 'A session is already live. Keep the logger one tap away and finish with a debrief.'
        : state.readinessEntry == null
        ? 'The app still needs today readiness before it can tune load, rest, and coaching.'
        : dai.rationale;
    final next = active != null
        ? 'Log the next clean working set, then finish the debrief.'
        : hasDebrief
        ? 'Open progress, confirm the proof, then set the next session focus.'
        : 'Submit readiness if needed, then start the session.';

    return Semantics(
      container: true,
      excludeSemantics: true,
      label: 'Activation corridor. $primary. Why: $why Next: $next',
      child: _Panel(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Activation corridor',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(primary, style: theme.textTheme.headlineSmall),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _StatusPill(
                  label: active != null
                      ? 'Live'
                      : hasDebrief
                      ? 'Proof saved'
                      : 'First action',
                ),
              ],
            ),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 760;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _ActivationCell(
                      width: wide
                          ? (constraints.maxWidth - 24) / 3
                          : constraints.maxWidth,
                      label: 'What to do now',
                      value: primary,
                      icon: Icons.bolt_outlined,
                    ),
                    _ActivationCell(
                      width: wide
                          ? (constraints.maxWidth - 24) / 3
                          : constraints.maxWidth,
                      label: 'Why it changed',
                      value: why,
                      icon: Icons.psychology_alt_outlined,
                    ),
                    _ActivationCell(
                      width: wide
                          ? (constraints.maxWidth - 24) / 3
                          : constraints.maxWidth,
                      label: 'Next after that',
                      value: next,
                      icon: Icons.route_outlined,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                Semantics(
                  button: true,
                  label: active == null
                      ? 'Start session from activation corridor'
                      : 'Open live logger from activation corridor',
                  excludeSemantics: true,
                  child: ElevatedButton.icon(
                    key: const ValueKey('activation_corridor_primary_action'),
                    onPressed: active == null
                        ? onStartSession
                        : () => context.go('/workout'),
                    icon: Icon(
                      active == null ? Icons.play_arrow : Icons.fitness_center,
                    ),
                    label: Text(
                      active == null ? 'Start session' : 'Live logger',
                    ),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(154, 50),
                      tapTargetSize: MaterialTapTargetSize.padded,
                      visualDensity: VisualDensity.standard,
                    ),
                  ),
                ),
                Semantics(
                  button: true,
                  label: 'Open coach from activation corridor',
                  excludeSemantics: true,
                  child: OutlinedButton.icon(
                    key: const ValueKey('activation_corridor_coach_action'),
                    onPressed: () => context.go('/coach'),
                    icon: const Icon(Icons.psychology_alt_outlined),
                    label: const Text('Coach'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.onSurface,
                      side: BorderSide(
                        color: theme.colorScheme.primary.withValues(alpha: 0.5),
                      ),
                      minimumSize: const Size(124, 50),
                      tapTargetSize: MaterialTapTargetSize.padded,
                      visualDensity: VisualDensity.standard,
                    ),
                  ),
                ),
                Semantics(
                  button: true,
                  label: 'Open proof from activation corridor',
                  excludeSemantics: true,
                  child: TextButton.icon(
                    key: const ValueKey('activation_corridor_proof_action'),
                    onPressed: () => context.go('/proof'),
                    icon: const Icon(Icons.verified_outlined),
                    label: const Text('Proof'),
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.onSurface,
                      minimumSize: const Size(116, 50),
                      tapTargetSize: MaterialTapTargetSize.padded,
                      visualDensity: VisualDensity.standard,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${coachSignal.personaLabel} coach. ${repair.safetyBoundary}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.76),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivationCell extends StatelessWidget {
  const _ActivationCell({
    required this.width,
    required this.label,
    required this.value,
    required this.icon,
  });

  final double width;
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: width,
      child: Container(
        constraints: const BoxConstraints(minHeight: 132),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF151515),
          border: Border.all(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: theme.colorScheme.primary, size: 20),
            const SizedBox(height: 10),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(value, style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _DaiDataRow extends StatelessWidget {
  const _DaiDataRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(value, style: theme.textTheme.bodyMedium),
      ],
    );
  }
}

class _BehaviorRepairPanel extends StatelessWidget {
  const _BehaviorRepairPanel({required this.repair});

  final BehavioralRepairLoop repair;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      container: true,
      excludeSemantics: true,
      label: repair.semanticLabel,
      child: _Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(child: _SectionTitle('Behavior repair')),
                const SizedBox(width: 12),
                _StatusPill(label: repair.confidenceLabel),
              ],
            ),
            const SizedBox(height: 10),
            Text(repair.headline, style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _CoachTracePill(
                  icon: Icons.route_outlined,
                  label: repair.mode.label,
                ),
                _CoachTracePill(
                  icon: Icons.source_outlined,
                  label: repair.sourceTraceLabel,
                ),
              ],
            ),
            const SizedBox(height: 14),
            _CoachObservation(label: 'Need', value: repair.emotionalNeed),
            const SizedBox(height: 10),
            _DaiDataRow(label: 'Friction', value: repair.friction),
            const SizedBox(height: 10),
            _DaiDataRow(label: 'Next repair', value: repair.repairAction),
            const SizedBox(height: 10),
            _DaiDataRow(label: 'Proof', value: repair.proof),
            const SizedBox(height: 10),
            Text(
              repair.safetyBoundary,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.74),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveDemoCommandPanel extends StatelessWidget {
  const _LiveDemoCommandPanel({
    required this.state,
    required this.exerciseController,
    required this.setWeightKg,
    required this.setReps,
    required this.setRpe,
    required this.onApplyNextSet,
    required this.onLogWorkoutSet,
    required this.onFinishSession,
  });

  final SessionState state;
  final TextEditingController exerciseController;
  final int setWeightKg;
  final int setReps;
  final int setRpe;
  final VoidCallback onApplyNextSet;
  final VoidCallback onLogWorkoutSet;
  final VoidCallback onFinishSession;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final active = state.activeSession;
    final setCount = active?.loggedSets.length ?? 0;
    final canFinish = setCount > 0;
    final historyTopSet = _topWeightedSet(state.history);
    final liveTopSet = _topWeightedSetIncludingActive(
      history: state.history,
      active: active,
    );
    final warmupStep = active != null && historyTopSet != null
        ? _nextWarmupStepForSession(topSet: historyTopSet.set, session: active)
        : null;
    final cueTopSet = active != null && warmupStep == null
        ? liveTopSet
        : historyTopSet;
    final nextTarget = warmupStep == null && cueTopSet != null
        ? _nextTargetForTopSet(
            cueTopSet.set,
            volumeMultiplier: active?.volumeMultiplier,
          )
        : null;
    final cueTitle = warmupStep != null
        ? 'Next warm-up ${warmupStep.order}'
        : cueTopSet != null
        ? 'Next working set'
        : 'Sample set';
    final cueDetail = warmupStep != null && cueTopSet != null
        ? '${cueTopSet.set.exerciseName} · '
              '${_formatWarmupStep(warmupStep.weightKg.toDouble(), warmupStep.reps)} · '
              'RPE ${warmupStep.rpe}'
        : cueTopSet != null && nextTarget != null
        ? '${cueTopSet.set.exerciseName} · ${nextTarget.target} · '
              '${nextTarget.cue}'
        : 'Sample workout is ready.';
    final exerciseName = exerciseController.text.trim();
    final canLog = _canLogWorkoutSet(exerciseName);
    final weightLabel = setWeightKg == 0
        ? 'bodyweight'
        : '${_formatNumber(setWeightKg.toDouble())} kg';
    final loadedSummary = canLog
        ? 'Loaded: $exerciseName · $weightLabel x $setReps · RPE $setRpe'
        : 'Next set is ready to stage.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.34),
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const _StatusPill(label: 'Sample workout'),
              Semantics(
                label: 'Sample workout cue: $cueTitle, $cueDetail',
                child: ExcludeSemantics(
                  child: Text(
                    cueTitle,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            cueDetail,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            loadedSummary,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.78),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Semantics(
                button: true,
                enabled: cueTopSet != null,
                label: 'Apply sample next set',
                excludeSemantics: true,
                child: FilledButton.icon(
                  onPressed: cueTopSet == null ? null : onApplyNextSet,
                  icon: const Icon(Icons.route),
                  label: const Text('Apply sample set'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(156, 48),
                    tapTargetSize: MaterialTapTargetSize.padded,
                    visualDensity: VisualDensity.standard,
                  ),
                ),
              ),
              Semantics(
                button: true,
                enabled: canLog,
                label: 'Log sample set',
                excludeSemantics: true,
                child: OutlinedButton.icon(
                  onPressed: canLog ? onLogWorkoutSet : null,
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Log sample set'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.onSurface,
                    side: BorderSide(
                      color: theme.colorScheme.primary.withValues(alpha: 0.72),
                    ),
                    minimumSize: const Size(150, 48),
                    tapTargetSize: MaterialTapTargetSize.padded,
                    visualDensity: VisualDensity.standard,
                  ),
                ),
              ),
              Semantics(
                button: true,
                enabled: canFinish,
                label: 'Finish sample debrief',
                excludeSemantics: true,
                child: TextButton.icon(
                  onPressed: canFinish ? onFinishSession : null,
                  icon: const Icon(Icons.flag_outlined),
                  label: const Text('Finish debrief'),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.onSurface,
                    minimumSize: const Size(150, 48),
                    tapTargetSize: MaterialTapTargetSize.padded,
                    visualDensity: VisualDensity.standard,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CoachTracePill extends StatelessWidget {
  const _CoachTracePill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      constraints: const BoxConstraints(minHeight: 34, maxWidth: 220),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.12),
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child, this.padding = const EdgeInsets.all(16)});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.12),
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: Theme.of(context).textTheme.titleMedium);
  }
}

class _CoachObservation extends StatelessWidget {
  const _CoachObservation({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        border: Border(
          left: BorderSide(color: theme.colorScheme.primary, width: 3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(value, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _SessionLoopPanel extends StatelessWidget {
  const _SessionLoopPanel({
    required this.state,
    required this.exerciseController,
    required this.setWeightKg,
    required this.setReps,
    required this.setRpe,
    required this.debriefRpe,
    required this.debriefSatisfaction,
    required this.nextFocusController,
    required this.painNotesController,
    required this.onSetWeightChanged,
    required this.onSetRepsChanged,
    required this.onSetRpeChanged,
    required this.onExerciseChanged,
    required this.onDebriefRpeChanged,
    required this.onDebriefSatisfactionChanged,
    required this.onApplyNextSet,
    required this.onLogWorkoutSet,
    required this.onUndoLastSet,
    required this.onFinishSession,
  });

  final SessionState state;
  final TextEditingController exerciseController;
  final int setWeightKg;
  final int setReps;
  final int setRpe;
  final int debriefRpe;
  final int debriefSatisfaction;
  final TextEditingController nextFocusController;
  final TextEditingController painNotesController;
  final ValueChanged<int> onSetWeightChanged;
  final ValueChanged<int> onSetRepsChanged;
  final ValueChanged<int> onSetRpeChanged;
  final VoidCallback onExerciseChanged;
  final ValueChanged<int> onDebriefRpeChanged;
  final ValueChanged<int> onDebriefSatisfactionChanged;
  final VoidCallback onApplyNextSet;
  final VoidCallback onLogWorkoutSet;
  final VoidCallback onUndoLastSet;
  final VoidCallback onFinishSession;

  @override
  Widget build(BuildContext context) {
    final active = state.activeSession;
    final debrief = state.lastDebrief;
    final historyTopSet = _topWeightedSet(state.history);
    final liveTopSet = _topWeightedSetIncludingActive(
      history: state.history,
      active: active,
    );
    final warmupStep = active != null && historyTopSet != null
        ? _nextWarmupStepForSession(topSet: historyTopSet.set, session: active)
        : null;
    final cueTopSet = active != null && warmupStep == null
        ? liveTopSet
        : historyTopSet;
    final canLogWorkoutSet = _canLogWorkoutSet(exerciseController.text);
    final lastSession = active == null && debrief != null
        ? _sessionForDebrief(state.history, debrief.sessionId)
        : null;
    final theme = Theme.of(context);
    final title = active != null
        ? 'Session live'
        : debrief != null
        ? 'Debrief saved'
        : 'Ready to start';
    final detail = active != null
        ? 'Readiness is locked. Log each working set, then finish with a debrief.'
        : debrief != null
        ? 'Next focus: ${debrief.nextSessionFocus ?? 'keep the appointment'}'
        : 'Tap Start session to create readiness, open the workout log, and begin the debrief loop.';

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      label: 'Session loop status, $title',
                      child: Text(title, style: theme.textTheme.titleMedium),
                    ),
                    const SizedBox(height: 6),
                    Text(detail, style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _StatusPill(
                label: active != null
                    ? _setCountLabel(active.loggedSets.length)
                    : '${state.history.length} done',
              ),
            ],
          ),
          if (lastSession != null) ...[
            const SizedBox(height: 14),
            _CompletedSessionSummary(session: lastSession),
            if (debrief?.painNotes != null) ...[
              const SizedBox(height: 12),
              Semantics(
                container: true,
                excludeSemantics: true,
                label: 'Pain check: ${debrief!.painNotes!}',
                child: _CoachObservation(
                  label: 'Pain check',
                  value: debrief.painNotes!,
                ),
              ),
            ],
          ],
          if (active != null) ...[
            const SizedBox(height: 14),
            _WorkoutSetControls(
              exerciseController: exerciseController,
              weightKg: setWeightKg,
              reps: setReps,
              rpe: setRpe,
              onWeightChanged: onSetWeightChanged,
              onRepsChanged: onSetRepsChanged,
              onRpeChanged: onSetRpeChanged,
              onExerciseChanged: onExerciseChanged,
            ),
            if (cueTopSet != null) ...[
              const SizedBox(height: 12),
              _LiveNextSetCue(
                topSet: cueTopSet.set,
                warmupStep: warmupStep,
                volumeMultiplier: active.volumeMultiplier,
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                if (cueTopSet != null)
                  Semantics(
                    button: true,
                    label: 'Apply next set',
                    excludeSemantics: true,
                    child: FilledButton.icon(
                      onPressed: onApplyNextSet,
                      icon: const Icon(Icons.route),
                      label: const Text('Apply next set'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(160, 48),
                        tapTargetSize: MaterialTapTargetSize.padded,
                        visualDensity: VisualDensity.standard,
                      ),
                    ),
                  ),
                Semantics(
                  button: true,
                  enabled: canLogWorkoutSet,
                  label: 'Log workout set',
                  excludeSemantics: true,
                  child: OutlinedButton.icon(
                    onPressed: canLogWorkoutSet ? onLogWorkoutSet : null,
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text('Log workout set'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.onSurface,
                      side: BorderSide(
                        color: theme.colorScheme.primary.withValues(
                          alpha: 0.72,
                        ),
                      ),
                      minimumSize: const Size(154, 48),
                      tapTargetSize: MaterialTapTargetSize.padded,
                      visualDensity: VisualDensity.standard,
                    ),
                  ),
                ),
                Semantics(
                  button: true,
                  enabled: active.loggedSets.isNotEmpty,
                  label: 'Undo last set',
                  excludeSemantics: true,
                  child: TextButton.icon(
                    onPressed: active.loggedSets.isEmpty ? null : onUndoLastSet,
                    icon: const Icon(Icons.undo),
                    label: const Text('Undo last set'),
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.onSurface,
                      minimumSize: const Size(146, 48),
                      tapTargetSize: MaterialTapTargetSize.padded,
                      visualDensity: VisualDensity.standard,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _LoggedSetLedger(session: active),
            const SizedBox(height: 14),
            _DebriefControls(
              rpe: debriefRpe,
              satisfaction: debriefSatisfaction,
              nextFocusController: nextFocusController,
              painNotesController: painNotesController,
              onRpeChanged: onDebriefRpeChanged,
              onSatisfactionChanged: onDebriefSatisfactionChanged,
            ),
            const SizedBox(height: 14),
            Semantics(
              button: true,
              enabled: active.loggedSets.isNotEmpty,
              label: 'Finish and debrief',
              excludeSemantics: true,
              child: ElevatedButton(
                onPressed: active.loggedSets.isEmpty ? null : onFinishSession,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(154, 48),
                  tapTargetSize: MaterialTapTargetSize.padded,
                  visualDensity: VisualDensity.standard,
                ),
                child: const Text('Finish and debrief'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LiveNextSetCue extends StatelessWidget {
  const _LiveNextSetCue({
    required this.topSet,
    required this.warmupStep,
    required this.volumeMultiplier,
  });

  final LoggedSet topSet;
  final _WarmupStep? warmupStep;
  final double? volumeMultiplier;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final step = warmupStep;
    final nextTarget = step == null
        ? _nextTargetForTopSet(topSet, volumeMultiplier: volumeMultiplier)
        : null;
    final title = step == null
        ? 'Next working set'
        : 'Next warm-up ${step.order}';
    final detail = step == null
        ? '${topSet.exerciseName} · ${nextTarget!.target} · ${nextTarget.cue}'
        : '${topSet.exerciseName} · '
              '${_formatWarmupStep(step.weightKg.toDouble(), step.reps)} · '
              'RPE ${step.rpe}';
    final semanticLabel = step == null
        ? 'Next working set: ${topSet.exerciseName}, '
              '${nextTarget!.spokenTarget}. ${nextTarget.spokenCue}.'
        : 'Next warm-up ${step.order}: ${topSet.exerciseName}, '
              '${step.weightKg} kilograms for ${step.reps} reps, '
              'RPE ${step.rpe}.';

    return Semantics(
      container: true,
      excludeSemantics: true,
      label: semanticLabel,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF151515),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.48),
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.route, color: theme.colorScheme.primary, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(detail, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompletedSessionSummary extends StatelessWidget {
  const _CompletedSessionSummary({required this.session});

  final WorkoutSession session;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalVolume = session.totalVolume ?? 0;
    final setLabel = _setCountLabel(session.totalSets);
    final volumeLabel = totalVolume > 0
        ? '${_formatNumber(totalVolume)} kg'
        : '--';
    final spokenVolume = totalVolume > 0
        ? '${_formatNumber(totalVolume)} kilograms'
        : 'volume not recorded';
    final lastSet = session.loggedSets.isEmpty ? null : session.loggedSets.last;
    final metrics = lastSet == null ? const <String>[] : _setMetrics(lastSet);
    final spokenMetrics = lastSet == null
        ? ''
        : ', ${_setMetrics(lastSet, spoken: true).join(', ')}';
    final semanticDetails = lastSet == null
        ? 'Last session: $setLabel, $spokenVolume.'
        : 'Last session: $setLabel, $spokenVolume, '
              '${lastSet.exerciseName}$spokenMetrics.';

    return Semantics(
      container: true,
      excludeSemantics: true,
      label: semanticDetails,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Last session',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                setLabel,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _CompletedSessionMetric(label: 'Volume', value: volumeLabel),
          if (lastSet != null) ...[
            const SizedBox(height: 10),
            Text(lastSet.exerciseName, style: theme.textTheme.bodyLarge),
            const SizedBox(height: 5),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                for (final metric in metrics)
                  Text(
                    metric,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.72,
                      ),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _CompletedSessionMetric extends StatelessWidget {
  const _CompletedSessionMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _WorkoutSetControls extends StatelessWidget {
  const _WorkoutSetControls({
    required this.exerciseController,
    required this.weightKg,
    required this.reps,
    required this.rpe,
    required this.onWeightChanged,
    required this.onRepsChanged,
    required this.onRpeChanged,
    required this.onExerciseChanged,
  });

  final TextEditingController exerciseController;
  final int weightKg;
  final int reps;
  final int rpe;
  final ValueChanged<int> onWeightChanged;
  final ValueChanged<int> onRepsChanged;
  final ValueChanged<int> onRpeChanged;
  final VoidCallback onExerciseChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Workout log',
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          key: const ValueKey('today_exercise_field'),
          controller: exerciseController,
          onChanged: (_) => onExerciseChanged(),
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: 'Exercise',
            filled: true,
            fillColor: const Color(0xFF151515),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
          ),
        ),
        const SizedBox(height: 10),
        _ScoreStepper(
          label: 'Weight',
          semanticLabel: 'Set weight',
          value: weightKg,
          enabled: true,
          minValue: 0,
          maxValue: 300,
          semanticStep: 5,
          valueLabel: '$weightKg kg',
          decreaseTooltip: 'Decrease set weight',
          increaseTooltip: 'Increase set weight',
          onChanged: onWeightChanged,
        ),
        const SizedBox(height: 10),
        _ScoreStepper(
          label: 'Reps',
          semanticLabel: 'Set reps',
          value: reps,
          enabled: true,
          maxValue: 50,
          valueLabel: '$reps reps',
          decreaseTooltip: 'Decrease set reps',
          increaseTooltip: 'Increase set reps',
          onChanged: onRepsChanged,
        ),
        const SizedBox(height: 10),
        _ScoreStepper(
          label: 'Set RPE',
          value: rpe,
          enabled: true,
          valueLabel: '$rpe/10',
          decreaseTooltip: 'Decrease set RPE',
          increaseTooltip: 'Increase set RPE',
          onChanged: onRpeChanged,
        ),
      ],
    );
  }
}

class _LoggedSetLedger extends StatelessWidget {
  const _LoggedSetLedger({required this.session});

  final WorkoutSession session;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sets = session.loggedSets;
    final totalVolume = session.totalVolume ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Logged sets',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              totalVolume > 0 ? '${_formatNumber(totalVolume)} kg' : '--',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (sets.isEmpty)
          Text(
            'No sets logged yet',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
            ),
          )
        else
          Column(
            children: [
              for (final set in sets) ...[
                _LoggedSetRow(set: set),
                if (set != sets.last)
                  Divider(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                    height: 12,
                  ),
              ],
            ],
          ),
      ],
    );
  }
}

class _LoggedSetRow extends StatelessWidget {
  const _LoggedSetRow({required this.set});

  final LoggedSet set;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final metrics = _setMetrics(set);

    return Semantics(
      label:
          'Logged set ${set.setNumber}: ${set.exerciseName}, ${metrics.join(', ')}',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 34,
            child: Text(
              '#${set.setNumber}',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(set.exerciseName, style: theme.textTheme.bodyLarge),
                const SizedBox(height: 5),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    for (final metric in metrics)
                      Text(
                        metric,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.72,
                          ),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DebriefControls extends StatelessWidget {
  const _DebriefControls({
    required this.rpe,
    required this.satisfaction,
    required this.nextFocusController,
    required this.painNotesController,
    required this.onRpeChanged,
    required this.onSatisfactionChanged,
  });

  final int rpe;
  final int satisfaction;
  final TextEditingController nextFocusController;
  final TextEditingController painNotesController;
  final ValueChanged<int> onRpeChanged;
  final ValueChanged<int> onSatisfactionChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Debrief inputs',
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        _ScoreStepper(
          label: 'RPE',
          semanticLabel: 'Debrief RPE',
          value: rpe,
          enabled: true,
          valueLabel: '$rpe/10',
          decreaseTooltip: 'Decrease debrief RPE',
          increaseTooltip: 'Increase debrief RPE',
          onChanged: onRpeChanged,
        ),
        const SizedBox(height: 10),
        _ScoreStepper(
          label: 'Satisfaction',
          semanticLabel: 'Debrief satisfaction',
          value: satisfaction,
          enabled: true,
          maxValue: 5,
          valueLabel: '$satisfaction/5',
          decreaseTooltip: 'Decrease debrief satisfaction',
          increaseTooltip: 'Increase debrief satisfaction',
          onChanged: onSatisfactionChanged,
        ),
        const SizedBox(height: 10),
        TextField(
          key: const ValueKey('today_pain_notes_field'),
          controller: painNotesController,
          minLines: 1,
          maxLines: 2,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: 'Pain check',
            filled: true,
            fillColor: const Color(0xFF151515),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          key: const ValueKey('today_next_focus_field'),
          controller: nextFocusController,
          minLines: 1,
          maxLines: 2,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            labelText: 'Next focus',
            filled: true,
            fillColor: const Color(0xFF151515),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
          ),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.12),
        border: Border.all(color: theme.colorScheme.primary),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SessionPlanPanel extends StatelessWidget {
  const _SessionPlanPanel({required this.state});

  final SessionState state;

  @override
  Widget build(BuildContext context) {
    final readiness = state.readinessEntry;
    final warmupDetail = _warmupDetail(readiness?.sorenessMap);
    final strengthDetail = _strengthDetail(readiness?.zone);
    final closeoutDetail = _closeoutDetail(state);

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('Session plan'),
          const SizedBox(height: 14),
          _PlanRow(index: '01', title: 'Warm-up reset', detail: warmupDetail),
          _PlanRow(
            index: '02',
            title: 'Strength block',
            detail: strengthDetail,
          ),
          _PlanRow(index: '03', title: 'Closeout', detail: closeoutDetail),
        ],
      ),
    );
  }

  static String _warmupDetail(List<String>? sorenessMap) {
    if (sorenessMap == null) {
      return 'Check energy, sleep, and soreness before loading.';
    }
    if (sorenessMap.isEmpty) {
      return '6 min tissue prep, then ramp cleanly into working sets.';
    }
    return '6 min focus: ${sorenessMap.join(', ')} before loading.';
  }

  static String _strengthDetail(String? zone) {
    switch (zone) {
      case 'push':
        return 'Use full intent. Add load only while reps stay crisp.';
      case 'maintain':
        return 'Hold the plan. Controlled tempo, stop at 2 RIR.';
      case 'deload':
        return 'Reduce load, keep range clean, leave more in reserve.';
      case 'rest':
        return 'Replace loading with recovery work and walking.';
      default:
        return 'Readiness will choose push, maintain, or deload.';
    }
  }

  static String _closeoutDetail(SessionState state) {
    final debrief = state.lastDebrief;
    if (debrief != null) {
      return 'Saved focus: ${debrief.nextSessionFocus ?? 'repeat clean reps'}.';
    }
    final active = state.activeSession;
    if (active != null) {
      return '${_setCountLabel(active.loggedSets.length)} logged. Finish with a debrief.';
    }
    return 'Log one win and one form cue for tomorrow.';
  }
}

class _PlanRow extends StatelessWidget {
  const _PlanRow({
    required this.index,
    required this.title,
    required this.detail,
  });

  final String index;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
              border: Border.all(color: theme.colorScheme.primary),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              index,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.bodyLarge),
                const SizedBox(height: 3),
                Text(detail, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NutritionTargetPanel extends StatelessWidget {
  const _NutritionTargetPanel({
    required this.state,
    required this.proteinGrams,
    required this.onProteinChanged,
    required this.onCreateTarget,
  });

  final SessionState state;
  final int proteinGrams;
  final ValueChanged<int> onProteinChanged;
  final VoidCallback onCreateTarget;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final target = state.nutritionTarget;
    final status = target == null ? 'Needed for activation' : 'Target saved';
    final display = target?.targetDisplay ?? '$proteinGrams g/day';
    final sourceCount =
        target?.sourceIds.length ?? NutritionTarget.defaultSourceIds.length;
    final safetyNote =
        target?.safetyNote ??
        'This is not medical nutrition advice. Adjust with a qualified professional for medical needs.';

    return _Panel(
      child: Semantics(
        container: true,
        explicitChildNodes: true,
        label: target == null
            ? 'Nutrition target not created. Protein target $display.'
            : 'Nutrition target saved. ${target.label} $display.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(child: _SectionTitle('Nutrition target')),
                const SizedBox(width: 12),
                _StatusPill(label: status),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'Protein target',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            _ScoreStepper(
              label: 'Daily protein',
              semanticLabel: 'Daily protein target',
              value: proteinGrams,
              enabled: true,
              minValue: 60,
              maxValue: 220,
              semanticStep: 15,
              valueLabel: '$proteinGrams g',
              decreaseTooltip: 'Decrease protein target',
              increaseTooltip: 'Increase protein target',
              onChanged: onProteinChanged,
            ),
            if (target != null) ...[
              const SizedBox(height: 12),
              _NutritionTargetSummary(target: target),
            ],
            const SizedBox(height: 12),
            Text(
              safetyNote,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.70),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Semantics(
                  button: true,
                  label: target == null
                      ? 'Create nutrition target'
                      : 'Update nutrition target',
                  excludeSemantics: true,
                  child: FilledButton.icon(
                    onPressed: onCreateTarget,
                    icon: const Icon(Icons.restaurant_menu),
                    label: Text(
                      target == null
                          ? 'Create nutrition target'
                          : 'Update target',
                    ),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(196, 48),
                      tapTargetSize: MaterialTapTargetSize.padded,
                      visualDensity: VisualDensity.standard,
                    ),
                  ),
                ),
                Semantics(
                  label: 'Nutrition target source trace, $sourceCount sources',
                  child: ExcludeSemantics(
                    child: Text(
                      '$sourceCount source trace',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NutritionTargetSummary extends StatelessWidget {
  const _NutritionTargetSummary({required this.target});

  final NutritionTarget target;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.48),
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${target.label}: ${target.targetDisplay}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadinessPanel extends StatelessWidget {
  const _ReadinessPanel({
    required this.state,
    required this.energyLevel,
    required this.sleepQuality,
    required this.sorenessOptions,
    required this.selectedSoreness,
    required this.onEnergyChanged,
    required this.onSleepChanged,
    required this.onSorenessToggled,
    required this.onSubmit,
  });

  final SessionState state;
  final int energyLevel;
  final int sleepQuality;
  final List<String> sorenessOptions;
  final Set<String> selectedSoreness;
  final ValueChanged<int> onEnergyChanged;
  final ValueChanged<int> onSleepChanged;
  final ValueChanged<String> onSorenessToggled;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final readiness = state.readinessEntry;
    final zone = readiness?.zone;
    final multiplier =
        state.activeSession?.volumeMultiplier ??
        (zone == null ? null : _volumeMultiplierForZone(zone));

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('Readiness'),
          const SizedBox(height: 14),
          _ReadinessCheckInControls(
            enabled: state.activeSession == null,
            energyLevel: energyLevel,
            sleepQuality: sleepQuality,
            sorenessOptions: sorenessOptions,
            selectedSoreness: selectedSoreness,
            onEnergyChanged: onEnergyChanged,
            onSleepChanged: onSleepChanged,
            onSorenessToggled: onSorenessToggled,
            onSubmit: onSubmit,
          ),
          const SizedBox(height: 14),
          _MetricStrip(
            label: 'Readiness',
            value: readiness?.score.toString() ?? '--',
            color: _zoneColor(zone),
          ),
          const SizedBox(height: 10),
          _MetricStrip(
            label: 'Zone',
            value: _zoneLabel(zone),
            color: _zoneColor(zone),
          ),
          const SizedBox(height: 10),
          _MetricStrip(
            label: 'Soreness',
            value: _sorenessLabel(readiness?.sorenessMap),
            color: const Color(0xFFFFB86B),
          ),
          const SizedBox(height: 10),
          _MetricStrip(
            label: 'Load target',
            value: multiplier == null ? '--' : '${(multiplier * 100).round()}%',
            color: const Color(0xFF7AA2F7),
          ),
        ],
      ),
    );
  }

  static Color _zoneColor(String? zone) {
    switch (zone) {
      case 'push':
        return const Color(0xFF73C991);
      case 'maintain':
        return const Color(0xFF7AA2F7);
      case 'deload':
      case 'rest':
        return const Color(0xFFFFB86B);
      default:
        return const Color(0xFF8A8A8A);
    }
  }

  static String _zoneLabel(String? zone) {
    switch (zone) {
      case 'push':
        return 'Push';
      case 'maintain':
        return 'Maintain';
      case 'deload':
        return 'Deload';
      case 'rest':
        return 'Rest';
      default:
        return 'No check-in';
    }
  }

  static String _sorenessLabel(List<String>? sorenessMap) {
    if (sorenessMap == null) return '--';
    if (sorenessMap.isEmpty) return 'Clear';
    return '${sorenessMap.length} areas';
  }

  static double _volumeMultiplierForZone(String zone) {
    switch (zone) {
      case 'push':
        return 1.10;
      case 'maintain':
        return 1.00;
      case 'deload':
        return 0.65;
      case 'rest':
        return 0.00;
      default:
        return 1.00;
    }
  }
}

class _ReadinessCheckInControls extends StatelessWidget {
  const _ReadinessCheckInControls({
    required this.enabled,
    required this.energyLevel,
    required this.sleepQuality,
    required this.sorenessOptions,
    required this.selectedSoreness,
    required this.onEnergyChanged,
    required this.onSleepChanged,
    required this.onSorenessToggled,
    required this.onSubmit,
  });

  final bool enabled;
  final int energyLevel;
  final int sleepQuality;
  final List<String> sorenessOptions;
  final Set<String> selectedSoreness;
  final ValueChanged<int> onEnergyChanged;
  final ValueChanged<int> onSleepChanged;
  final ValueChanged<String> onSorenessToggled;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ScoreStepper(
          label: 'Energy',
          value: energyLevel,
          enabled: enabled,
          decreaseTooltip: 'Decrease energy',
          increaseTooltip: 'Increase energy',
          onChanged: onEnergyChanged,
        ),
        const SizedBox(height: 10),
        _ScoreStepper(
          label: 'Sleep',
          value: sleepQuality,
          enabled: enabled,
          decreaseTooltip: 'Decrease sleep',
          increaseTooltip: 'Increase sleep',
          onChanged: onSleepChanged,
        ),
        const SizedBox(height: 12),
        Text(
          'Soreness map',
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: sorenessOptions
              .map(
                (area) => Semantics(
                  button: true,
                  enabled: enabled,
                  selected: selectedSoreness.contains(area),
                  label: 'Toggle $area soreness',
                  child: FilterChip(
                    label: Text(area),
                    selected: selectedSoreness.contains(area),
                    onSelected: enabled ? (_) => onSorenessToggled(area) : null,
                    materialTapTargetSize: MaterialTapTargetSize.padded,
                    visualDensity: VisualDensity.standard,
                    selectedColor: theme.colorScheme.primary.withValues(
                      alpha: 0.22,
                    ),
                    checkmarkColor: theme.colorScheme.primary,
                    side: BorderSide(
                      color: selectedSoreness.contains(area)
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface.withValues(alpha: 0.18),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: Semantics(
            button: true,
            enabled: enabled,
            label: 'Save check-in',
            excludeSemantics: true,
            child: OutlinedButton.icon(
              onPressed: enabled ? onSubmit : null,
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Save check-in'),
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.onSurface,
                side: BorderSide(
                  color: theme.colorScheme.primary.withValues(alpha: 0.72),
                ),
                minimumSize: const Size(154, 48),
                tapTargetSize: MaterialTapTargetSize.padded,
                visualDensity: VisualDensity.standard,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ScoreStepper extends StatelessWidget {
  const _ScoreStepper({
    required this.label,
    required this.value,
    required this.enabled,
    required this.decreaseTooltip,
    required this.increaseTooltip,
    required this.onChanged,
    this.minValue = 1,
    this.maxValue = 10,
    this.semanticStep = 1,
    this.semanticLabel,
    this.valueLabel,
  });

  final String label;
  final String? semanticLabel;
  final int value;
  final bool enabled;
  final String decreaseTooltip;
  final String increaseTooltip;
  final ValueChanged<int> onChanged;
  final int minValue;
  final int maxValue;
  final int semanticStep;
  final String? valueLabel;

  String _semanticValueFor(int nextValue) {
    final display = valueLabel;
    if (display == null || display.contains('/')) {
      return '$nextValue out of $maxValue';
    }
    if (display.endsWith(' kg')) return '$nextValue kilograms';
    if (display.endsWith(' reps')) return '$nextValue reps';
    return nextValue.toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canDecrease = enabled && value > minValue;
    final canIncrease = enabled && value < maxValue;
    final nextValue = (value + semanticStep).clamp(minValue, maxValue);
    final previousValue = (value - semanticStep).clamp(minValue, maxValue);

    return Semantics(
      container: true,
      excludeSemantics: true,
      enabled: enabled,
      label: semanticLabel ?? label,
      value: _semanticValueFor(value),
      increasedValue: canIncrease ? _semanticValueFor(nextValue) : null,
      decreasedValue: canDecrease ? _semanticValueFor(previousValue) : null,
      onIncrease: canIncrease ? () => onChanged(1) : null,
      onDecrease: canDecrease ? () => onChanged(-1) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF151515),
          border: Border.all(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.12),
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Expanded(
              child: ExcludeSemantics(
                child: Text(label, style: theme.textTheme.bodyMedium),
              ),
            ),
            IconButton(
              tooltip: decreaseTooltip,
              onPressed: canDecrease ? () => onChanged(-1) : null,
              icon: const Icon(Icons.remove),
            ),
            SizedBox(
              width: 56,
              child: ExcludeSemantics(
                child: Text(
                  valueLabel ?? '$value/10',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            IconButton(
              tooltip: increaseTooltip,
              onPressed: canIncrease ? () => onChanged(1) : null,
              icon: const Icon(Icons.add),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricStrip extends StatelessWidget {
  const _MetricStrip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        border: Border.all(color: color.withValues(alpha: 0.55)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: theme.textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecoveryPanel extends StatelessWidget {
  const _RecoveryPanel({required this.state, required this.onRecoveryAction});

  final SessionState state;
  final ValueChanged<_RecoveryAction> onRecoveryAction;

  @override
  Widget build(BuildContext context) {
    final cue = _recoveryCueFor(state.readinessEntry);
    final bailCue = _bailRecoveryCueFor(state);
    final action = _recoveryActionFor(state);
    final theme = Theme.of(context);

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('Recovery cue'),
          const SizedBox(height: 12),
          if (bailCue != null) ...[
            Semantics(
              container: true,
              excludeSemantics: true,
              label: bailCue.semanticLabel,
              child: _CoachObservation(
                label: bailCue.label,
                value: bailCue.value,
              ),
            ),
            const SizedBox(height: 12),
          ],
          Semantics(
            container: true,
            excludeSemantics: true,
            label: cue.semanticLabel,
            child: _CoachObservation(label: cue.label, value: cue.value),
          ),
          if (action != null) ...[
            const SizedBox(height: 12),
            Semantics(
              button: true,
              label: action.semanticLabel,
              excludeSemantics: true,
              child: FilledButton.icon(
                onPressed: () => onRecoveryAction(action),
                icon: const Icon(Icons.self_improvement),
                label: Text(action.buttonLabel),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(190, 48),
                  foregroundColor: theme.colorScheme.onPrimary,
                  tapTargetSize: MaterialTapTargetSize.padded,
                  visualDensity: VisualDensity.standard,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

_RecoveryCue? _bailRecoveryCueFor(SessionState state, {DateTime? now}) {
  if (state.activeSession != null || state.history.isNotEmpty) {
    return null;
  }
  final readiness = state.readinessEntry;
  if (readiness == null) {
    return null;
  }
  final checkedAt = readiness.createdAt ?? readiness.date;
  final elapsed = (now ?? DateTime.now()).difference(checkedAt);
  if (elapsed < const Duration(hours: 4)) {
    return null;
  }

  return const _RecoveryCue(
    label: 'Bail recovery',
    value:
        'You already checked in. Do one 8-minute reset now: 4 min walk, 4 min mobility, then tap Start session.',
  );
}

class _RecoveryCue {
  const _RecoveryCue({required this.label, required this.value});

  final String label;
  final String value;

  String get semanticLabel => '$label: $value';
}

class _RecoveryAction {
  const _RecoveryAction({
    required this.buttonLabel,
    required this.semanticLabel,
    required this.exerciseName,
    required this.durationSeconds,
    required this.rpe,
    required this.sessionNotes,
    required this.painNotes,
    required this.whatWorked,
    required this.whatToChange,
    required this.nextSessionFocus,
  });

  final String buttonLabel;
  final String semanticLabel;
  final String exerciseName;
  final int durationSeconds;
  final int rpe;
  final String sessionNotes;
  final String painNotes;
  final String whatWorked;
  final String whatToChange;
  final String nextSessionFocus;
}

_RecoveryAction? _recoveryActionFor(SessionState state, {DateTime? now}) {
  if (state.activeSession != null ||
      state.history.isNotEmpty ||
      state.lastDebrief != null) {
    return null;
  }
  final readiness = state.readinessEntry;
  if (readiness == null) {
    return null;
  }

  if (readiness.sorenessMap.length >= 3 ||
      readiness.zone == 'deload' ||
      readiness.zone == 'rest') {
    return const _RecoveryAction(
      buttonLabel: 'Log 12-min mobility',
      semanticLabel: 'Log 12-minute mobility reset',
      exerciseName: 'Mobility reset',
      durationSeconds: 720,
      rpe: 3,
      sessionNotes: 'Completed 12-minute mobility reset.',
      painNotes: 'Recovery-safe mobility only; no loaded pain work.',
      whatWorked: 'Kept the training appointment without loading sore tissue.',
      whatToChange: 'Re-check soreness before the next loaded session.',
      nextSessionFocus: 'Resume with mobility first and no loaded pain.',
    );
  }

  if (_bailRecoveryCueFor(state, now: now) != null) {
    return const _RecoveryAction(
      buttonLabel: 'Save today with 8-min reset',
      semanticLabel: 'Save today with 8-minute recovery reset',
      exerciseName: 'Recovery reset',
      durationSeconds: 480,
      rpe: 3,
      sessionNotes: 'Completed 8-minute recovery reset.',
      painNotes: 'No loaded work; monitor pain before the next session.',
      whatWorked: 'Converted the delayed check-in into a low-bar reset.',
      whatToChange:
          'Start earlier or use the reset button before the window closes.',
      nextSessionFocus: 'Return with clean controlled reps.',
    );
  }

  return null;
}

_RecoveryCue _recoveryCueFor(ReadinessEntry? readiness) {
  if (readiness == null) {
    return const _RecoveryCue(
      label: 'Recovery cue',
      value:
          'Check energy, sleep, and soreness first. High soreness becomes mobility, walking, and no loaded pain.',
    );
  }

  final sorenessMap = readiness.sorenessMap;
  if (sorenessMap.isEmpty) {
    return const _RecoveryCue(
      label: 'Green tissue',
      value: 'No sore areas logged. Six-minute warm-up, then crisp sets.',
    );
  }

  final areas = _formatSorenessAreas(sorenessMap);
  final soreVerb = sorenessMap.length == 1 ? 'is' : 'are';
  if (sorenessMap.length >= 3 ||
      readiness.zone == 'deload' ||
      readiness.zone == 'rest') {
    return _RecoveryCue(
      label: 'DOMS wall',
      value:
          '$areas $soreVerb sore. That is normal after hard training. '
          'Recovery-safe alternative: 12 min mobility, 20 min walk, no loaded pain.',
    );
  }

  return _RecoveryCue(
    label: 'Soreness watch',
    value:
        '$areas $soreVerb sore. Six min targeted prep, controlled load, '
        'and stop two reps before form changes.',
  );
}

String _formatSorenessAreas(List<String> sorenessMap) {
  if (sorenessMap.length == 1) {
    return sorenessMap.single;
  }
  if (sorenessMap.length == 2) {
    return '${sorenessMap.first} and ${sorenessMap.last}';
  }
  return '${sorenessMap.take(sorenessMap.length - 1).join(', ')}, '
      'and ${sorenessMap.last}';
}

class _ProofPanel extends StatelessWidget {
  const _ProofPanel({required this.state});

  final SessionState state;

  @override
  Widget build(BuildContext context) {
    final active = state.activeSession;
    final debrief = state.lastDebrief;
    final todayStatus = active != null
        ? 'Session live'
        : debrief != null
        ? 'Debrief saved'
        : 'Not started';

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('Activation proof'),
          const SizedBox(height: 14),
          _ProofRow(
            label: 'Completed sessions',
            value: state.history.length.toString(),
          ),
          _ProofRow(label: 'Today status', value: todayStatus),
          _ProofRow(
            label: 'Pain check',
            value: debrief?.painNotes ?? 'Not logged',
          ),
          _ProofRow(
            label: 'Nutrition target',
            value: state.nutritionTarget?.targetDisplay ?? 'Not created',
          ),
          _ProofRow(
            label: 'Forward hook',
            value:
                debrief?.nextSessionFocus ?? 'Tomorrow adapts from today log',
          ),
          const SizedBox(height: 6),
          _TrainingPulse(history: state.history),
          _TopSetCue(history: state.history),
          const SizedBox(height: 6),
          _RecentSessions(history: state.history),
        ],
      ),
    );
  }
}

class _TrainingPulse extends StatelessWidget {
  const _TrainingPulse({required this.history});

  final List<WorkoutSession> history;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sessionCount = history.length;
    final setCount = history.fold<int>(
      0,
      (total, session) => total + session.totalSets,
    );
    final totalVolume = history.fold<double>(
      0,
      (total, session) => total + (session.totalVolume ?? 0),
    );
    final sessionLabel = sessionCount == 1
        ? '1 session'
        : '$sessionCount sessions';
    final setLabel = _setCountLabel(setCount);
    final volumeLabel = totalVolume > 0
        ? '${_formatNumber(totalVolume)} kg'
        : '--';
    final spokenVolume = totalVolume > 0
        ? '${_formatNumber(totalVolume)} kilograms'
        : 'volume not recorded';

    return Semantics(
      container: true,
      excludeSemantics: true,
      label: 'Training pulse: $sessionLabel, $setLabel, $spokenVolume.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Training pulse',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 18,
            runSpacing: 10,
            children: [
              _PulseMetric(label: 'Sessions', value: sessionLabel),
              _PulseMetric(label: 'Sets', value: setLabel),
              _PulseMetric(label: 'Volume', value: volumeLabel),
            ],
          ),
        ],
      ),
    );
  }
}

class _PulseMetric extends StatelessWidget {
  const _PulseMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: 116,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _TopSetCue extends StatelessWidget {
  const _TopSetCue({required this.history});

  final List<WorkoutSession> history;

  @override
  Widget build(BuildContext context) {
    final topSet = _topWeightedSet(history);
    if (topSet == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final metrics = _setMetrics(topSet.set).join(' · ');
    final spokenMetrics = _setMetrics(topSet.set, spoken: true).join(', ');
    final nextTarget = _nextTargetForTopSet(topSet.set);
    final warmupRamp = _warmupRampForTopSet(topSet.set);

    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            container: true,
            excludeSemantics: true,
            label:
                'Top set: ${topSet.set.exerciseName}, $spokenMetrics, '
                'session ${topSet.sessionNumber}.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Top set',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        topSet.set.exerciseName,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'From session ${topSet.sessionNumber}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  metrics,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Semantics(
            container: true,
            excludeSemantics: true,
            label:
                'Next target: ${topSet.set.exerciseName}, '
                '${nextTarget.spokenTarget}. ${nextTarget.spokenCue}.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Next target',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${nextTarget.target} · ${nextTarget.cue}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Semantics(
            container: true,
            excludeSemantics: true,
            label:
                'Warm-up ramp: ${topSet.set.exerciseName}, '
                '${warmupRamp.spoken}.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Warm-up ramp',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  warmupRamp.display,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentSessions extends StatelessWidget {
  const _RecentSessions({required this.history});

  final List<WorkoutSession> history;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final recent = history.reversed.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent sessions',
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        if (recent.isEmpty)
          Text(
            'No sessions yet',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
            ),
          )
        else
          Column(
            children: [
              for (var i = 0; i < recent.length; i += 1) ...[
                _RecentSessionRow(
                  session: recent[i],
                  sessionNumber: history.length - i,
                ),
                if (i != recent.length - 1)
                  Divider(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                    height: 14,
                  ),
              ],
            ],
          ),
      ],
    );
  }
}

class _RecentSessionRow extends StatelessWidget {
  const _RecentSessionRow({required this.session, required this.sessionNumber});

  final WorkoutSession session;
  final int sessionNumber;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalVolume = session.totalVolume ?? 0;
    final setLabel = _setCountLabel(session.totalSets);
    final volumeLabel = totalVolume > 0
        ? '${_formatNumber(totalVolume)} kg'
        : '--';
    final spokenVolume = totalVolume > 0
        ? '${_formatNumber(totalVolume)} kilograms'
        : 'volume not recorded';
    final lastSet = session.loggedSets.isEmpty ? null : session.loggedSets.last;
    final spokenMetrics = lastSet == null
        ? 'no logged sets'
        : '${lastSet.exerciseName}, '
              '${_setMetrics(lastSet, spoken: true).join(', ')}';

    return Semantics(
      container: true,
      excludeSemantics: true,
      label:
          'Session $sessionNumber: $setLabel, $spokenVolume, $spokenMetrics.',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 74,
            child: Text(
              'Session $sessionNumber',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lastSet?.exerciseName ?? 'No logged sets',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$setLabel | $volumeLabel',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProofRow extends StatelessWidget {
  const _ProofRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

WorkoutSession? _sessionForDebrief(
  List<WorkoutSession> history,
  String sessionId,
) {
  for (final session in history.reversed) {
    if (session.id == sessionId) {
      return session;
    }
  }
  return history.isEmpty ? null : history.last;
}

class _TopWeightedSet {
  const _TopWeightedSet({required this.set, required this.sessionNumber});

  final LoggedSet set;
  final int sessionNumber;
}

_TopWeightedSet? _topWeightedSet(List<WorkoutSession> history) {
  _TopWeightedSet? best;

  for (var i = 0; i < history.length; i += 1) {
    final sessionNumber = i + 1;
    for (final set in history[i].loggedSets) {
      if (!set.completed || set.weightKg == null || set.reps == null) {
        continue;
      }

      final candidate = _TopWeightedSet(set: set, sessionNumber: sessionNumber);
      if (_isBetterTopSet(candidate, best)) {
        best = candidate;
      }
    }
  }

  return best;
}

bool _canLogWorkoutSet(String exerciseName) {
  final normalized = exerciseName.trim().toLowerCase();
  return normalized.isNotEmpty && normalized != 'warm-up reset';
}

_TopWeightedSet? _topWeightedSetIncludingActive({
  required List<WorkoutSession> history,
  required WorkoutSession? active,
}) {
  var best = _topWeightedSet(history);
  if (active == null) {
    return best;
  }

  final activeSessionNumber = history.length + 1;
  for (final set in active.loggedSets) {
    if (!set.completed || set.weightKg == null || set.reps == null) {
      continue;
    }

    final candidate = _TopWeightedSet(
      set: set,
      sessionNumber: activeSessionNumber,
    );
    if (_isBetterTopSet(candidate, best)) {
      best = candidate;
    }
  }

  return best;
}

bool _isBetterTopSet(_TopWeightedSet candidate, _TopWeightedSet? current) {
  if (current == null) {
    return true;
  }

  final candidateWeight = candidate.set.weightKg!;
  final currentWeight = current.set.weightKg!;
  if (candidateWeight != currentWeight) {
    return candidateWeight > currentWeight;
  }

  final candidateReps = candidate.set.reps!;
  final currentReps = current.set.reps!;
  if (candidateReps != currentReps) {
    return candidateReps > currentReps;
  }

  if (candidate.sessionNumber != current.sessionNumber) {
    return candidate.sessionNumber > current.sessionNumber;
  }

  return candidate.set.setNumber > current.set.setNumber;
}

class _NextTarget {
  const _NextTarget({
    required this.target,
    required this.spokenTarget,
    required this.cue,
    required this.spokenCue,
    required this.targetWeightKg,
    required this.targetReps,
  });

  final String target;
  final String spokenTarget;
  final String cue;
  final String spokenCue;
  final int targetWeightKg;
  final int targetReps;
}

_NextTarget _nextTargetForTopSet(LoggedSet set, {double? volumeMultiplier}) {
  final weight = set.weightKg!;
  final reps = set.reps!;
  final deloadMultiplier =
      volumeMultiplier != null && volumeMultiplier > 0 && volumeMultiplier < 1;
  final targetWeight = deloadMultiplier
      ? _roundToPlateStep(weight * volumeMultiplier)
      : weight;
  final canAddRep = (set.rpe == null || set.rpe! <= 7) && reps < 50;
  final targetReps = deloadMultiplier ? reps : (canAddRep ? reps + 1 : reps);
  final targetWeightKg = targetWeight.round().clamp(0, 300).toInt();
  final formattedWeight = _formatNumber(targetWeight);
  final target =
      '$formattedWeight kg x $targetReps ${targetReps == 1 ? 'rep' : 'reps'}';
  final spokenTarget =
      '$formattedWeight kilograms for $targetReps '
      '${targetReps == 1 ? 'rep' : 'reps'}';

  if (deloadMultiplier) {
    final percent = (volumeMultiplier * 100).round();
    return _NextTarget(
      target: target,
      spokenTarget: spokenTarget,
      cue: 'Deload to $percent% today',
      spokenCue: 'Deload to $percent percent today before adding load',
      targetWeightKg: targetWeightKg,
      targetReps: targetReps,
    );
  }

  if (canAddRep) {
    return _NextTarget(
      target: target,
      spokenTarget: spokenTarget,
      cue: 'Add 1 rep before load',
      spokenCue: 'Add one rep before adding load',
      targetWeightKg: targetWeightKg,
      targetReps: targetReps,
    );
  }

  return _NextTarget(
    target: target,
    spokenTarget: spokenTarget,
    cue: 'Repeat clean before load',
    spokenCue: 'Repeat it cleanly before adding load',
    targetWeightKg: targetWeightKg,
    targetReps: targetReps,
  );
}

class _WarmupStep {
  const _WarmupStep({
    required this.order,
    required this.weightKg,
    required this.reps,
    required this.rpe,
  });

  final int order;
  final int weightKg;
  final int reps;
  final int rpe;
}

class _WarmupRamp {
  const _WarmupRamp({
    required this.display,
    required this.spoken,
    required this.steps,
  });

  final String display;
  final String spoken;
  final List<_WarmupStep> steps;
}

_WarmupRamp _warmupRampForTopSet(LoggedSet set, {double? volumeMultiplier}) {
  final targetWeight =
      volumeMultiplier != null && volumeMultiplier > 0 && volumeMultiplier < 1
      ? _roundToPlateStep(set.weightKg! * volumeMultiplier)
      : set.weightKg!;
  final firstWeight = _roundToPlateStep(targetWeight * 0.5);
  final secondWeight = _roundToPlateStep(targetWeight * 0.75);
  final first = _formatWarmupStep(firstWeight, 8);
  final second = _formatWarmupStep(secondWeight, 5);
  final spokenFirst = _formatWarmupStep(firstWeight, 8, spoken: true);
  final spokenSecond = _formatWarmupStep(secondWeight, 5, spoken: true);

  return _WarmupRamp(
    display: '$first · $second',
    spoken: '$spokenFirst, then $spokenSecond',
    steps: [
      _WarmupStep(
        order: 1,
        weightKg: firstWeight.round().clamp(0, 300).toInt(),
        reps: 8,
        rpe: 4,
      ),
      _WarmupStep(
        order: 2,
        weightKg: secondWeight.round().clamp(0, 300).toInt(),
        reps: 5,
        rpe: 5,
      ),
    ],
  );
}

_WarmupStep? _nextWarmupStepForSession({
  required LoggedSet topSet,
  required WorkoutSession session,
}) {
  final ramp = _warmupRampForTopSet(
    topSet,
    volumeMultiplier: session.volumeMultiplier,
  );
  for (final step in ramp.steps) {
    final alreadyLogged = session.loggedSets.any(
      (logged) =>
          logged.completed &&
          logged.exerciseName == topSet.exerciseName &&
          logged.weightKg != null &&
          logged.weightKg!.round() == step.weightKg &&
          logged.reps == step.reps,
    );
    if (!alreadyLogged) {
      return step;
    }
  }
  return null;
}

double _roundToPlateStep(double value) {
  final rounded = (value / 5).round() * 5.0;
  if (rounded <= 0) {
    return value;
  }
  return rounded;
}

String _formatWarmupStep(double weightKg, int reps, {bool spoken = false}) {
  final formattedWeight = _formatNumber(weightKg);
  final repLabel = reps == 1 ? 'rep' : 'reps';
  return spoken
      ? '$formattedWeight kilograms for $reps $repLabel'
      : '$formattedWeight kg x $reps $repLabel';
}

List<String> _setMetrics(LoggedSet set, {bool spoken = false}) {
  final metrics = <String>[];
  if (set.weightKg != null && set.reps != null) {
    final weight = _formatNumber(set.weightKg!);
    metrics.add(
      spoken
          ? '$weight kilograms for ${set.reps} reps'
          : '$weight kg x ${set.reps} reps',
    );
  } else if (set.reps != null) {
    metrics.add('${set.reps} reps');
  } else if (set.durationSeconds != null) {
    final minutes = set.durationSeconds! / 60;
    metrics.add(
      spoken
          ? '${_formatNumber(minutes)} minutes'
          : '${_formatNumber(minutes)} min',
    );
  }
  if (set.rpe != null) {
    metrics.add('RPE ${set.rpe}');
  }
  if (metrics.isEmpty) {
    metrics.add('Logged');
  }
  return metrics;
}

String _setCountLabel(int count) => count == 1 ? '1 set' : '$count sets';

String _formatNumber(double value) {
  if (value == value.roundToDouble()) {
    return value.toInt().toString();
  }
  return value.toStringAsFixed(1);
}
