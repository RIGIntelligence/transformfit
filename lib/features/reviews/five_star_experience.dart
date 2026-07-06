library;

import 'package:transformfit/features/coaching/coach_signal.dart';
import 'package:transformfit/features/session/models.dart';
import 'package:transformfit/features/session/session_controller.dart';

const fiveStarExperienceSourceIds = [
  'src_apple_hig_ratings_reviews',
  'src_apple_storekit_review_limits',
  'src_google_play_in_app_review_api',
  'src_transformfit_five_star_experience_bar',
];

const fiveStarExperienceCriteria = [
  FiveStarExperienceCriterion(
    id: 'criterion-first-value',
    label: 'First value',
    standard:
        'A new user can complete onboarding, start, and log one clean set without needing a tutorial.',
    kpi: 'time_to_first_logged_set_under_3_minutes',
  ),
  FiveStarExperienceCriterion(
    id: 'criterion-live-logger',
    label: 'Live logger',
    standard:
        'The active workout keeps previous-set context, rest pacing, and the next set target visible under fatigue.',
    kpi: 'set_logging_task_success_95_percent',
  ),
  FiveStarExperienceCriterion(
    id: 'criterion-coach-trust',
    label: 'Coach trust',
    standard:
        'Every coach recommendation explains the observed signal, the next action, the boundary, and its source trace.',
    kpi: 'coach_trust_score_90_percent',
  ),
  FiveStarExperienceCriterion(
    id: 'criterion-safety',
    label: 'Safety',
    standard:
        'Pain, low readiness, and nutrition risk always suppress progression pressure and route to repair.',
    kpi: 'zero_unsafe_progression_prompts',
  ),
  FiveStarExperienceCriterion(
    id: 'criterion-adaptation',
    label: 'Adaptation',
    standard:
        'The plan adapts to actual logged work, readiness, nutrition context, and adherence without moralizing misses.',
    kpi: 'weekly_plan_explanation_coverage_100_percent',
  ),
  FiveStarExperienceCriterion(
    id: 'criterion-proof',
    label: 'Proof',
    standard:
        'Progress is shown as kept promises, completed sets, recovery wins, and comeback evidence, not appearance pressure.',
    kpi: 'proof_card_created_after_first_week',
  ),
  FiveStarExperienceCriterion(
    id: 'criterion-native',
    label: 'Native feel',
    standard:
        'iOS and Android paths honor platform navigation, review prompts, accessibility, privacy, and performance norms.',
    kpi: 'crash_free_sessions_99_8_percent',
  ),
  FiveStarExperienceCriterion(
    id: 'criterion-offline',
    label: 'Offline reliability',
    standard:
        'A gym-floor session can start, log, recover, and finish without network dependency.',
    kpi: 'offline_session_completion_100_percent',
  ),
  FiveStarExperienceCriterion(
    id: 'criterion-privacy',
    label: 'Privacy',
    standard:
        'Health, body, nutrition, and wearable data stay minimized, explainable, exportable, and user-controlled.',
    kpi: 'privacy_boundary_visible_on_sensitive_surfaces',
  ),
  FiveStarExperienceCriterion(
    id: 'criterion-review-moment',
    label: 'Review moment',
    standard:
        'A store-rating request is only eligible after value is earned, during a natural break, and never after pain or frustration.',
    kpi: 'ethical_review_prompt_eligibility_100_percent',
  ),
];

enum FiveStarExperienceStatus {
  buildValue,
  holdDuringTask,
  holdForSafety,
  completeActivation,
  repairExperience,
  readyNaturalBreak,
}

extension FiveStarExperienceStatusLabel on FiveStarExperienceStatus {
  String get label => switch (this) {
    FiveStarExperienceStatus.buildValue => 'Build value',
    FiveStarExperienceStatus.holdDuringTask => 'Do not ask yet',
    FiveStarExperienceStatus.holdForSafety => 'Safety hold',
    FiveStarExperienceStatus.completeActivation => 'Activation incomplete',
    FiveStarExperienceStatus.repairExperience => 'Repair first',
    FiveStarExperienceStatus.readyNaturalBreak => 'Eligible at a natural break',
  };
}

class FiveStarExperienceCriterion {
  const FiveStarExperienceCriterion({
    required this.id,
    required this.label,
    required this.standard,
    required this.kpi,
  });

  final String id;
  final String label;
  final String standard;
  final String kpi;
}

class FiveStarExperienceMoment {
  const FiveStarExperienceMoment({
    required this.status,
    required this.headline,
    required this.rationale,
    required this.nextAction,
    required this.safetyBoundary,
    required this.completedSessions,
    required this.completedSets,
    required this.sourceIds,
    this.lastSatisfaction,
  });

  final FiveStarExperienceStatus status;
  final String headline;
  final String rationale;
  final String nextAction;
  final String safetyBoundary;
  final int completedSessions;
  final int completedSets;
  final int? lastSatisfaction;
  final List<String> sourceIds;

  bool get isStoreReviewEligible =>
      status == FiveStarExperienceStatus.readyNaturalBreak;

  String get statusLabel => status.label;

  String get sourceTraceLabel =>
      '${sourceIds.length} ${sourceIds.length == 1 ? 'source' : 'sources'}';

  String get metricLabel =>
      '$completedSessions ${completedSessions == 1 ? 'session' : 'sessions'}, '
      '$completedSets ${completedSets == 1 ? 'set' : 'sets'}';

  String get semanticLabel =>
      'Trust milestone, $statusLabel, $headline. $rationale Next: $nextAction. $safetyBoundary';
}

FiveStarExperienceMoment buildFiveStarExperienceMoment(SessionState state) {
  final completed = _completedSessions(state);
  final completedSets = completed.fold<int>(
    0,
    (total, session) => total + session.completedSets,
  );
  final lastDebrief = state.lastDebrief;
  final painReported = hasReportedPain(lastDebrief?.painNotes);

  if (state.activeSession != null) {
    return FiveStarExperienceMoment(
      status: FiveStarExperienceStatus.holdDuringTask,
      headline: 'Keep the live task uninterrupted',
      rationale:
          'A live workout is in progress, so the only valuable action is logging the next set or finishing cleanly.',
      nextAction: 'Finish the live session first',
      safetyBoundary:
          'Never interrupt a set, timer, debrief, or recovery decision with a store-rating request.',
      completedSessions: completed.length,
      completedSets: completedSets,
      lastSatisfaction: lastDebrief?.satisfaction,
      sourceIds: fiveStarExperienceSourceIds,
    );
  }

  if (painReported) {
    return FiveStarExperienceMoment(
      status: FiveStarExperienceStatus.holdForSafety,
      headline: 'Resolve safety before praise',
      rationale:
          'The latest debrief includes pain context, so trust is earned by adapting the plan before any rating moment.',
      nextAction: 'Choose a pain-free variation',
      safetyBoundary:
          'Pain, injury, or unsafe nutrition context blocks review prompts and progression pressure.',
      completedSessions: completed.length,
      completedSets: completedSets,
      lastSatisfaction: lastDebrief?.satisfaction,
      sourceIds: fiveStarExperienceSourceIds,
    );
  }

  if (completed.length < 2 || completedSets < 6) {
    return FiveStarExperienceMoment(
      status: FiveStarExperienceStatus.buildValue,
      headline: 'Earn two proof-backed sessions',
      rationale:
          'The app should create real training value before it earns the right to ask for public feedback.',
      nextAction: 'Complete two sessions with at least six clean sets',
      safetyBoundary:
          'No review request before meaningful use, task success, and a natural break.',
      completedSessions: completed.length,
      completedSets: completedSets,
      lastSatisfaction: lastDebrief?.satisfaction,
      sourceIds: fiveStarExperienceSourceIds,
    );
  }

  if (state.readinessEntry == null || state.nutritionTarget == null) {
    return FiveStarExperienceMoment(
      status: FiveStarExperienceStatus.completeActivation,
      headline: 'Close the activation loop',
      rationale:
          'Readiness and nutrition context are still incomplete, so the experience is not fully personalized yet.',
      nextAction: state.readinessEntry == null
          ? 'Capture readiness before the next session'
          : 'Create one safe nutrition target',
      safetyBoundary:
          'Only ask after the user has seen the complete workout, recovery, nutrition, and proof loop.',
      completedSessions: completed.length,
      completedSets: completedSets,
      lastSatisfaction: lastDebrief?.satisfaction,
      sourceIds: fiveStarExperienceSourceIds,
    );
  }

  if (lastDebrief == null || lastDebrief.satisfaction < 4) {
    return FiveStarExperienceMoment(
      status: FiveStarExperienceStatus.repairExperience,
      headline: 'Repair the last session first',
      rationale:
          'A missing or low-satisfaction debrief means the product should learn and improve before any rating moment.',
      nextAction: 'Ask what to adjust for the next session',
      safetyBoundary:
          'No sentiment gating, no leading question, and no custom request for only positive ratings.',
      completedSessions: completed.length,
      completedSets: completedSets,
      lastSatisfaction: lastDebrief?.satisfaction,
      sourceIds: fiveStarExperienceSourceIds,
    );
  }

  return FiveStarExperienceMoment(
    status: FiveStarExperienceStatus.readyNaturalBreak,
    headline: 'Value has been earned',
    rationale:
        'Training proof, readiness context, nutrition context, and a positive debrief are present.',
    nextAction: 'Use the native review flow after the session recap',
    safetyBoundary:
        'Use platform-native review APIs, respect quota limits, and never condition the prompt on promised stars.',
    completedSessions: completed.length,
    completedSets: completedSets,
    lastSatisfaction: lastDebrief.satisfaction,
    sourceIds: fiveStarExperienceSourceIds,
  );
}

bool fiveStarExperienceCopyIsGateSafe(FiveStarExperienceMoment moment) {
  final copy = [
    moment.headline,
    moment.rationale,
    moment.nextAction,
    moment.safetyBoundary,
    moment.statusLabel,
  ].join(' ').toLowerCase();
  const blocked = [
    '5 stars',
    'five stars',
    'beast mode',
    'burn fat',
    'diagnose',
    'do you love',
    'give us',
    'no excuses',
    'punish',
    'rate us',
    'shame',
    'weight loss',
  ];
  final emoji = RegExp('[\u{1F300}-\u{1F9FF}]', unicode: true);
  return blocked.every((term) => !copy.contains(term)) && !emoji.hasMatch(copy);
}

List<WorkoutSession> _completedSessions(SessionState state) {
  return state.history
      .where((session) => session.endedAt != null && session.completedSets > 0)
      .toList(growable: false);
}
