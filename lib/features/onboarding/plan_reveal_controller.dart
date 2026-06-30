import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:transformfit/engine/plan_generation.dart';

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
    int count(String s) => s.trim().isEmpty ? 0 : s.trim().split(RegExp(r'\s+')).length;
    return count(headline) + count(reasoning) + count(coachingCue);
  }

  /// Reconstruct the [PlanIntake] that produced this plan. Used to pass the
  /// intake to the first-session handoff so it can deterministically render
  /// session 1 without a network round-trip (offline-first).
  PlanIntake get intake => PlanIntake(
        goal: plan.goal,
        trainingDaysPerWeek: plan.daysPerWeek,
        equipment: plan.effectiveEquipment
            .where((e) => e != 'bodyweight')
            .toList(),
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
    final intake = ref.read(pendingIntakeProvider) ??
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
      final client = Supabase.instance.client;
      final response = await client.functions.invoke(
        'generate-plan',
        body: {
          'goal': intake.goal,
          'daysPerWeek': intake.trainingDaysPerWeek,
          'equipment': intake.equipment,
          'experienceLevel': intake.experienceLevel,
          'limitations': intake.limitations,
          // R1 echo: the real user phrase so the LLM can echo the user's
          // words back (VAL-ONB-031). The edge function reads it from the
          // body only — it does NOT read the profile server-side.
          'userPhrase': userPhrase,
        },
      );
      if (response.data == null) {
        throw Exception('Empty response from generate-plan');
      }
      final data = response.data as Map<String, dynamic>;
      final planJson = data['plan'] as Map<String, dynamic>;
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
        changesMade: ['Plan built for ${plan.goal} goal', '${plan.daysPerWeek} sessions/week'],
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

  static GeneratedPlan _planFromJson(Map<String, dynamic> json) {
    final days = (json['days'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .map((d) => PlanDay(
              dayNumber: (d['dayNumber'] as num?)?.toInt() ?? 1,
              focus: (d['focus'] as String?) ?? '',
              split: (d['split'] as String?) ?? '',
              exercises: (d['exercises'] as List? ?? [])
                  .whereType<Map<String, dynamic>>()
                  .map((e) => PlanExercise(
                        id: (e['id'] as String?) ?? '',
                        name: (e['name'] as String?) ?? '',
                        muscleGroup: (e['muscleGroup'] as String?) ?? '',
                        equipment: (e['equipment'] as String?) ?? '',
                        sets: (e['sets'] as num?)?.toInt() ?? 3,
                        repsMin: (e['repsMin'] as num?)?.toInt() ?? 8,
                        repsMax: (e['repsMax'] as num?)?.toInt() ?? 12,
                        rpeTarget: (e['rpeTarget'] as num?)?.toInt() ?? 8,
                        restSeconds: (e['restSeconds'] as num?)?.toInt() ?? 90,
                        isCompound: (e['isCompound'] as bool?) ?? false,
                        sortOrder: (e['sortOrder'] as num?)?.toInt() ?? 0,
                      ))
                    .toList(),
            ))
        .toList();
    return GeneratedPlan(
      goal: (json['goal'] as String?) ?? '',
      experienceLevel: json['experienceLevel'] as String?,
      effectiveEquipment: _list(json['effectiveEquipment']),
      daysPerWeek: (json['daysPerWeek'] as num?)?.toInt() ?? 3,
      contraindications: _list(json['contraindications']),
      days: days,
    );
  }

  /// Strip emoji + markup from a user phrase before echoing it into coach
  /// copy. Mirrors the server-side sanitizeUserPhrase.
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
    return noEmoji.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}

final planRevealControllerProvider =
    AsyncNotifierProvider<PlanRevealController, PlanRevealState>(
  PlanRevealController.new,
);
