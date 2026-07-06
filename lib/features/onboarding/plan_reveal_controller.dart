import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:transformfit/engine/plan_generation.dart';

typedef PlanRevealRemoteInvoker =
    Future<Object?> Function(Map<String, Object?> body);

final planRevealRemoteInvokerProvider = Provider<PlanRevealRemoteInvoker>((
  ref,
) {
  return (body) async {
    final response = await Supabase.instance.client.functions.invoke(
      'generate-plan',
      body: body,
    );
    return response.data;
  };
});

/// Holds the intake the user actually entered, seeded by the intake screen
/// just before navigating to `/onboarding/plan-reveal`. The plan-reveal
/// controller reads its real [PlanIntake] from here instead of hardcoding a
/// default — the canonical data-carrying path (onboarding-data-flow.md,
/// "seeded Riverpod provider"). A null value means no intake has been seeded
/// yet (e.g. a deep link straight to plan-reveal); the controller then falls
/// back to a deterministic default and flags the result as a fallback.
///
/// Backed by a simple [Notifier] (Riverpod 6 — the legacy [StateProvider] was
/// removed). The intake screen calls `setIntake(...)` before navigating; the
/// controller reads via [pendingIntakeProvider].
class PendingIntake extends Notifier<PlanIntake?> {
  @override
  PlanIntake? build() => null;

  /// Seed the intake captured during the intake quiz. Ignored if [intake]
  /// is null (no-op) so callers can pass a nullable without branching.
  void setIntake(PlanIntake? intake) {
    state = intake;
  }

  /// Clear the transient onboarding intake after the first-session handoff
  /// starts the workout, so a later onboarding visit cannot reuse stale state.
  void clear() {
    state = null;
  }
}

final pendingIntakeProvider = NotifierProvider<PendingIntake, PlanIntake?>(
  PendingIntake.new,
);

/// Companion side-channel for the user's free-text "why now" phrase
/// (identity_anchor). [PlanIntake] has no field for it, and the edge function
/// reads it from the request body only (never the profile server-side), so the
/// intake screen seeds this provider immediately before navigating to
/// `/onboarding/plan-reveal`. The controller sends it as `userPhrase` and
/// echoes a sanitized copy for the Recognition beat (VAL-ONB-031/059).
class UserWhyNow extends Notifier<String?> {
  @override
  String? build() => null;

  void setPhrase(String? phrase) {
    state = phrase;
  }

  /// Clear the transient identity-anchor phrase after first-session handoff.
  void clear() {
    state = null;
  }
}

final userWhyNowProvider = NotifierProvider<UserWhyNow, String?>(
  UserWhyNow.new,
);

/// The state of the plan reveal screen.
class PlanRevealState {
  const PlanRevealState({
    required this.plan,
    required this.headline,
    required this.reasoning,
    required this.coachingCue,
    required this.changesMade,
    required this.isFallback,
    required this.modelUsed,
    this.echoedPhrase,
  });

  final GeneratedPlan plan;
  final String headline;
  final String reasoning;
  final String coachingCue;
  final List<String> changesMade;
  final bool isFallback;
  final String modelUsed;

  /// The user's echoed phrase, sanitized (emoji/markup stripped).
  final String? echoedPhrase;

  /// Total word count across headline + reasoning + coaching cue.
  int get wordCount {
    int count(String s) =>
        s.trim().isEmpty ? 0 : s.trim().split(RegExp(r'\s+')).length;
    return count(headline) + count(reasoning) + count(coachingCue);
  }

  /// Reconstruct the [PlanIntake] that produced this plan. Used to pass the
  /// intake to the first-session handoff so it can deterministically render
  /// session 1 without a network round-trip (offline-first).
  PlanIntake get intake => PlanIntake(
    goal: plan.goal,
    trainingDaysPerWeek: plan.daysPerWeek,
    equipment: plan.effectiveEquipment.where((e) => e != 'bodyweight').toList(),
    experienceLevel: plan.experienceLevel,
    limitations: plan.contraindications,
  );
}

/// Controller that calls the `generate-plan` edge function and surfaces the
/// result. On any failure, falls back to the local deterministic engine and
/// flags the state as a fallback (never a silent template).
class PlanRevealController extends AsyncNotifier<PlanRevealState> {
  @override
  Future<PlanRevealState> build() async {
    // Read the ACTUAL intake the user entered. The intake screen seeds
    // [pendingIntakeProvider] immediately before navigating here (see
    // IntakeScreen._finish). This is the single source of truth — there is
    // no hardcoded default intake anymore (onboarding-data-flow.md,
    // Controller & Test Authenticity). A null value only occurs on a deep
    // link straight to plan-reveal with no prior intake; in that case we
    // fall back to a deterministic default and flag the result as a fallback.
    final intake =
        ref.read(pendingIntakeProvider) ??
        const PlanIntake(
          goal: 'get_fitter',
          trainingDaysPerWeek: 3,
          equipment: ['bodyweight'],
          experienceLevel: 'intermediate',
        );

    // The user's "why now" phrase (identity anchor) for the LLM to echo
    // (VAL-ONB-031 / VAL-ONB-059). Sent in the request body as userPhrase;
    // the edge function sanitizes + echoes it inside its narrative. We keep
    // a local sanitized copy for the Recognition beat so the screen can
    // render it even when the network path returns an LLM-less fallback.
    final String? userPhrase = ref.read(pendingIntakeProvider) == null
        ? null
        : _localWhyNow(ref);
    final String? echoed = userPhrase == null
        ? null
        : _sanitizeUserPhrase(userPhrase);

    final fallbackIntake = intake;

    try {
      final responseData = await ref.read(planRevealRemoteInvokerProvider)({
        'goal': intake.goal,
        'daysPerWeek': intake.trainingDaysPerWeek,
        'equipment': intake.equipment,
        'experienceLevel': intake.experienceLevel,
        'limitations': intake.limitations,
        // R1 echo: the real user phrase so the LLM can echo the user's
        // words back (VAL-ONB-031). The edge function reads it from the
        // body only — it does NOT read the profile server-side.
        'userPhrase': userPhrase,
      });
      if (responseData == null) {
        throw Exception('Empty response from generate-plan');
      }
      final data = _requiredPlanObject(responseData, 'generate-plan response');
      final planJson = _requiredPlanObject(data['plan'], 'generate-plan plan');
      final plan = _planFromJson(planJson);
      return PlanRevealState(
        plan: plan,
        headline: _str(data['headline']),
        reasoning: _str(data['reasoning']),
        coachingCue: _str(data['coaching_cue']),
        changesMade: _list(data['changes_made']),
        isFallback: data['is_fallback'] == true,
        modelUsed: _str(data['model_used']),
        // The generate-plan response does NOT carry a discrete echoed_phrase
        // field; the echo lives inside the LLM-written reasoning. We surface
        // the user's own sanitized phrase for the Recognition beat.
        echoedPhrase: echoed,
      );
    } catch (_) {
      // Edge function unavailable: fall back to the local deterministic engine
      // and flag it honestly (VAL-ONB-058: surfaced fallback, never silent).
      final plan = generatePlan(fallbackIntake);
      return PlanRevealState(
        plan: plan,
        headline: 'Your first week is ready.',
        reasoning:
            'Built ${plan.daysPerWeek} days of training around your inputs. '
            'The full plan is below.',
        coachingCue: 'Start with session one and show up consistently.',
        changesMade: [
          'Plan built for ${plan.goal} goal',
          '${plan.daysPerWeek} sessions/week',
        ],
        isFallback: true,
        modelUsed: 'deterministic',
        echoedPhrase: echoed,
      );
    }
  }

  /// The raw "why now" phrase the user entered, if any. Pulled from
  /// [pendingIntakeProvider] via the fact that we cannot store the phrase on
  /// [PlanIntake] (it has no whyNow field) — so we keep a tiny side channel
  /// through a companion provider the intake screen also seeds.
  static String? _localWhyNow(Ref ref) => ref.read(userWhyNowProvider);

  static String _str(dynamic v) => (v is String && v.isNotEmpty) ? v : '';
  static List<String> _list(dynamic v) =>
      (v is List) ? v.whereType<String>().toList() : const [];

  static GeneratedPlan _planFromJson(Map<String, Object?> json) {
    final dayValues = _requiredPlanList(json['days'], 'plan.days');
    if (dayValues.isEmpty) {
      throw const FormatException('plan.days must include at least one day');
    }
    final days = <PlanDay>[];
    for (var dayIndex = 0; dayIndex < dayValues.length; dayIndex++) {
      final dayPath = 'plan.days[$dayIndex]';
      final d = _requiredPlanObject(dayValues[dayIndex], dayPath);
      final exerciseValues = _requiredPlanList(
        d['exercises'],
        '$dayPath.exercises',
      );
      if (exerciseValues.isEmpty) {
        throw FormatException('$dayPath.exercises must include exercises');
      }
      final exercises = <PlanExercise>[];
      for (
        var exerciseIndex = 0;
        exerciseIndex < exerciseValues.length;
        exerciseIndex++
      ) {
        final exercisePath = '$dayPath.exercises[$exerciseIndex]';
        final e = _requiredPlanObject(
          exerciseValues[exerciseIndex],
          exercisePath,
        );
        final repsMin = _requiredPlanInt(
          e['repsMin'],
          '$exercisePath.repsMin',
          min: 1,
        );
        final repsMax = _requiredPlanInt(
          e['repsMax'],
          '$exercisePath.repsMax',
          min: repsMin,
        );
        exercises.add(
          PlanExercise(
            id: _requiredPlanString(e['id'], '$exercisePath.id'),
            name: _requiredPlanString(e['name'], '$exercisePath.name'),
            muscleGroup: _requiredPlanString(
              e['muscleGroup'],
              '$exercisePath.muscleGroup',
            ),
            equipment: _requiredPlanString(
              e['equipment'],
              '$exercisePath.equipment',
            ),
            sets: _requiredPlanInt(e['sets'], '$exercisePath.sets', min: 1),
            repsMin: repsMin,
            repsMax: repsMax,
            rpeTarget: _requiredPlanInt(
              e['rpeTarget'],
              '$exercisePath.rpeTarget',
              min: 1,
              max: 10,
            ),
            restSeconds: _requiredPlanInt(
              e['restSeconds'],
              '$exercisePath.restSeconds',
              min: 1,
            ),
            isCompound: _requiredPlanBool(
              e['isCompound'],
              '$exercisePath.isCompound',
            ),
            sortOrder: _requiredPlanInt(
              e['sortOrder'],
              '$exercisePath.sortOrder',
              min: 0,
            ),
          ),
        );
      }
      days.add(
        PlanDay(
          dayNumber: _requiredPlanInt(
            d['dayNumber'],
            '$dayPath.dayNumber',
            min: 1,
          ),
          focus: _requiredPlanString(d['focus'], '$dayPath.focus'),
          split: _requiredPlanString(d['split'], '$dayPath.split'),
          exercises: exercises,
        ),
      );
    }
    final rawExperienceLevel = json['experienceLevel'];
    if (rawExperienceLevel != null && rawExperienceLevel is! String) {
      throw const FormatException('plan.experienceLevel must be a string');
    }
    final experienceLevel = rawExperienceLevel as String?;
    return GeneratedPlan(
      goal: _requiredPlanString(json['goal'], 'plan.goal'),
      experienceLevel: experienceLevel,
      effectiveEquipment: _requiredPlanStringList(
        json['effectiveEquipment'],
        'plan.effectiveEquipment',
        requireNonEmpty: true,
      ),
      daysPerWeek: _requiredPlanInt(
        json['daysPerWeek'],
        'plan.daysPerWeek',
        min: 1,
        max: 7,
      ),
      contraindications: _optionalPlanStringList(
        json['contraindications'],
        'plan.contraindications',
      ),
      days: days,
    );
  }

  static Map<String, Object?> _requiredPlanObject(Object? value, String path) {
    if (value is! Map) {
      throw FormatException('$path must be an object');
    }
    return Map<String, Object?>.from(value);
  }

  static List<Object?> _requiredPlanList(Object? value, String path) {
    if (value is! List) {
      throw FormatException('$path must be a list');
    }
    return value.cast<Object?>();
  }

  static String _requiredPlanString(Object? value, String path) {
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('$path must be a non-empty string');
    }
    return value.trim();
  }

  static int _requiredPlanInt(
    Object? value,
    String path, {
    required int min,
    int? max,
  }) {
    if (value is! num || value.isNaN || value.isInfinite) {
      throw FormatException('$path must be a finite number');
    }
    final parsed = value.toInt();
    if (parsed != value || parsed < min || (max != null && parsed > max)) {
      final ceiling = max == null ? '' : ' and <= $max';
      throw FormatException('$path must be >= $min$ceiling');
    }
    return parsed;
  }

  static bool _requiredPlanBool(Object? value, String path) {
    if (value is! bool) {
      throw FormatException('$path must be a boolean');
    }
    return value;
  }

  static List<String> _requiredPlanStringList(
    Object? value,
    String path, {
    bool requireNonEmpty = false,
  }) {
    final items = _optionalPlanStringList(value, path);
    if (requireNonEmpty && items.isEmpty) {
      throw FormatException('$path must include at least one value');
    }
    return items;
  }

  static List<String> _optionalPlanStringList(Object? value, String path) {
    if (value == null) return const [];
    final values = _requiredPlanList(value, path);
    return [
      for (var index = 0; index < values.length; index++)
        _requiredPlanString(values[index], '$path[$index]'),
    ];
  }

  /// Strip emoji + markup + question marks from a user phrase before echoing it
  /// into coach copy. Mirrors the server-side sanitizeUserPhrase.
  static String _sanitizeUserPhrase(String raw) {
    final noEmoji = raw
        .replaceAll(RegExp(r'[\u{1F600}-\u{1F64F}]', unicode: true), '')
        .replaceAll(RegExp(r'[\u{1F300}-\u{1F5FF}]', unicode: true), '')
        .replaceAll(RegExp(r'[\u{1F680}-\u{1F6FF}]', unicode: true), '')
        .replaceAll(RegExp(r'[\u{1F1E0}-\u{1F1FF}]', unicode: true), '')
        .replaceAll(RegExp(r'[\u{2600}-\u{26FF}]', unicode: true), '')
        .replaceAll(RegExp(r'[\u{2700}-\u{27BF}]', unicode: true), '')
        .replaceAll(RegExp(r'[\u{FE00}-\u{FE0F}]', unicode: true), '')
        .replaceAll(RegExp(r'[\u{1F900}-\u{1F9FF}]', unicode: true), '')
        .replaceAll(RegExp(r'[\u{200D}\u{20E3}\u{FE0F}]', unicode: true), '')
        .replaceAll(RegExp(r'<[^>]*>'), '');
    return noEmoji
        .replaceAll(RegExp(r'\?'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}

final planRevealControllerProvider =
    AsyncNotifierProvider<PlanRevealController, PlanRevealState>(
      PlanRevealController.new,
    );
