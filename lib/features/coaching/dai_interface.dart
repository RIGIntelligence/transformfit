library;

import 'package:transformfit/features/coaching/coach_signal.dart';
import 'package:transformfit/features/session/session_controller.dart';
import 'package:transformfit/features/wearables/wearable_signal.dart';

class DaiInterface {
  const DaiInterface({
    required this.workflowId,
    required this.title,
    required this.primaryCommand,
    required this.rationale,
    required this.boundary,
    required this.coachSignal,
    required this.wearableInsight,
    required this.confidence,
    required this.sourceIds,
  });

  final String workflowId;
  final String title;
  final String primaryCommand;
  final String rationale;
  final String boundary;
  final CoachSignal coachSignal;
  final WearableReadinessInsight wearableInsight;
  final double confidence;
  final List<String> sourceIds;

  String get confidenceLabel => '${(confidence * 100).round()}% confidence';

  String get sourceTraceLabel =>
      '${sourceIds.length} ${sourceIds.length == 1 ? 'source' : 'sources'}';

  String get semanticLabel =>
      'DAI interface $title, $primaryCommand, $confidenceLabel. '
      '${wearableInsight.statusLabel}. $rationale $boundary';
}

DaiInterface buildDaiInterface(SessionState state) {
  final coachSignal = buildCoachSignal(state);
  final wearableInsight = buildWearableReadinessInsight(
    state.wearableSignal,
    readiness: state.readinessEntry,
  );
  final sourceIds = _uniqueSourceIds([
    ...coachSignal.sourceIds,
    ...wearableInsight.sourceIds,
  ]);
  final confidence =
      (coachSignal.confidence * 0.62) + (wearableInsight.confidence * 0.38);

  if (coachSignal.workflowId == 'pain_or_injury_guardrail') {
    return DaiInterface(
      workflowId: 'dai_pain_override',
      title: 'Daily Adaptive Intelligence',
      primaryCommand: coachSignal.nextAction,
      rationale:
          'Pain context overrides wearable readiness and blocks automatic load increases.',
      boundary:
          'Use pain-free variations and seek qualified care for sharp, worsening, or unusual symptoms.',
      coachSignal: coachSignal,
      wearableInsight: wearableInsight,
      confidence: confidence.clamp(0, 1),
      sourceIds: sourceIds,
    );
  }

  if (wearableInsight.status == 'recovery_bias') {
    return DaiInterface(
      workflowId: 'dai_wearable_recovery_bias',
      title: 'Daily Adaptive Intelligence',
      primaryCommand: wearableInsight.primaryAdjustment,
      rationale:
          'DAI is weighting wearable recovery context with readiness before allowing progression.',
      boundary:
          'Wearable signals are context only; the user can edit the plan or ignore the suggestion.',
      coachSignal: coachSignal,
      wearableInsight: wearableInsight,
      confidence: confidence.clamp(0, 1),
      sourceIds: sourceIds,
    );
  }

  if (!wearableInsight.connected) {
    final permissionNeeded = wearableInsight.status == 'permission_needed';
    final syncUnavailable = wearableInsight.status == 'sync_unavailable';
    return DaiInterface(
      workflowId: 'dai_wearable_connect',
      title: 'Daily Adaptive Intelligence',
      primaryCommand: permissionNeeded
          ? 'Grant wearable permission'
          : 'Connect wearable context',
      rationale: permissionNeeded
          ? 'DAI is using readiness, workout history, and coach workflow until wearable permission is granted.'
          : syncUnavailable
          ? 'DAI is using manual readiness because wearable sync is unavailable.'
          : 'DAI is currently using readiness, workout history, and coach workflow state.',
      boundary: permissionNeeded || syncUnavailable
          ? 'No wearable metric changes training until opt-in sync succeeds.'
          : 'HealthKit and Health Connect data remain opt-in and source-traced before they affect training.',
      coachSignal: coachSignal,
      wearableInsight: wearableInsight,
      confidence: confidence.clamp(0, 1),
      sourceIds: sourceIds,
    );
  }

  return DaiInterface(
    workflowId: 'dai_coach_blend',
    title: 'Daily Adaptive Intelligence',
    primaryCommand: coachSignal.nextAction,
    rationale:
        'DAI blends the coach workflow with wearable recovery context and logged training proof.',
    boundary:
        'The coach remains editable and conservative when data is incomplete.',
    coachSignal: coachSignal,
    wearableInsight: wearableInsight,
    confidence: confidence.clamp(0, 1),
    sourceIds: sourceIds,
  );
}

bool daiInterfaceCopyIsGateSafe(DaiInterface dai) {
  final copy = [
    dai.workflowId,
    dai.title,
    dai.primaryCommand,
    dai.rationale,
    dai.boundary,
  ].join(' ').toLowerCase();
  const blocked = [
    'beast mode',
    'burn fat',
    'diagnose',
    'no excuses',
    'punish',
    'shame',
    'weight loss',
  ];
  final emoji = RegExp('[\u{1F300}-\u{1F9FF}]', unicode: true);
  return blocked.every((term) => !copy.contains(term)) && !emoji.hasMatch(copy);
}

List<String> _uniqueSourceIds(List<String> sourceIds) {
  final seen = <String>{};
  return sourceIds.where(seen.add).toList(growable: false);
}
