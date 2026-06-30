import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:transformfit/engine/plan_generation.dart';

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
    // The default intake; in a full implementation this would be read from
    // the persisted profile. For M2 the reveal runs immediately after intake
    // and the profile has been written by the intake screen.
    const intake = PlanIntake(
      goal: 'get_fitter',
      trainingDaysPerWeek: 3,
      equipment: ['bodyweight'],
      experienceLevel: 'intermediate',
    );

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
        echoedPhrase: data['echoed_phrase'] is String
            ? _sanitizeUserPhrase(data['echoed_phrase'] as String)
            : null,
      );
    } catch (_) {
      // Edge function unavailable: fall back to the local deterministic engine
      // and flag it honestly (VAL-ONB-058: surfaced fallback, never silent).
      final plan = generatePlan(intake);
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
      );
    }
  }

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
