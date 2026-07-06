import 'package:transformfit/features/coaching/coach_signal.dart';
import 'package:transformfit/features/session/models.dart';
import 'package:transformfit/features/session/session_controller.dart';

const rigSystemsEngineeringSourceIds = [
  'src_jake_execution_harness',
  'src_rig_market_studio_bms_bands',
  'src_rig_archon_bms_node_mapping',
  'src_transformfit_coach_command_center',
];

enum RigBuildMode { a1, a2, a3, a4 }

enum RigDiamond { d1, d2, d3 }

enum RigProcessStep {
  intent,
  question,
  research,
  solution,
  quality,
  proof,
  integrate,
}

extension RigBuildModeLabels on RigBuildMode {
  String get id => switch (this) {
    RigBuildMode.a1 => 'A1',
    RigBuildMode.a2 => 'A2',
    RigBuildMode.a3 => 'A3',
    RigBuildMode.a4 => 'A4',
  };
}

extension RigDiamondLabels on RigDiamond {
  String get id => switch (this) {
    RigDiamond.d1 => 'D1',
    RigDiamond.d2 => 'D2',
    RigDiamond.d3 => 'D3',
  };

  String get label => switch (this) {
    RigDiamond.d1 => 'D1 Operational',
    RigDiamond.d2 => 'D2 Engineering',
    RigDiamond.d3 => 'D3 Brand quality',
  };
}

extension RigProcessStepLabels on RigProcessStep {
  String get id => switch (this) {
    RigProcessStep.intent => 'I',
    RigProcessStep.question => 'Q',
    RigProcessStep.research => 'R',
    RigProcessStep.solution => 'S',
    RigProcessStep.quality => 'Q2',
    RigProcessStep.proof => 'P',
    RigProcessStep.integrate => 'I2',
  };

  String get label => switch (this) {
    RigProcessStep.intent => 'Intent',
    RigProcessStep.question => 'Question',
    RigProcessStep.research => 'Research',
    RigProcessStep.solution => 'Solution',
    RigProcessStep.quality => 'Quality',
    RigProcessStep.proof => 'Proof',
    RigProcessStep.integrate => 'Integrate',
  };
}

class RigBuildModeArchetype {
  const RigBuildModeArchetype({
    required this.mode,
    required this.label,
    required this.bmsRange,
    required this.decisionPath,
    required this.guardrail,
    required this.productUse,
  });

  final RigBuildMode mode;
  final String label;
  final String bmsRange;
  final String decisionPath;
  final String guardrail;
  final String productUse;
}

class RigDiamondCell {
  const RigDiamondCell({
    required this.diamond,
    required this.step,
    required this.mode,
    required this.coordinate,
    required this.job,
    required this.exitGate,
  });

  final RigDiamond diamond;
  final RigProcessStep step;
  final RigBuildMode mode;
  final String coordinate;
  final String job;
  final String exitGate;
}

class RigSystemsEngineeringSnapshot {
  const RigSystemsEngineeringSnapshot({
    required this.bmsScore,
    required this.selectedArchetype,
    required this.dominantDiamond,
    required this.currentStep,
    required this.coordinate,
    required this.escalationRule,
    required this.killSwitch,
    required this.archetypes,
    required this.tripleDoubleDiamondCells,
    required this.sourceIds,
  });

  final double bmsScore;
  final RigBuildModeArchetype selectedArchetype;
  final RigDiamond dominantDiamond;
  final RigProcessStep currentStep;
  final String coordinate;
  final String escalationRule;
  final String killSwitch;
  final List<RigBuildModeArchetype> archetypes;
  final List<RigDiamondCell> tripleDoubleDiamondCells;
  final List<String> sourceIds;

  String get bmsLabel => bmsScore.toStringAsFixed(2);

  String get semanticLabel =>
      'RIG systems engineering, ${selectedArchetype.label}, BMS $bmsLabel, '
      '$coordinate. ${selectedArchetype.decisionPath}';

  Iterable<RigDiamondCell> cellsForDiamond(RigDiamond diamond) {
    return tripleDoubleDiamondCells.where((cell) => cell.diamond == diamond);
  }
}

const rigBuildModeArchetypes = [
  RigBuildModeArchetype(
    mode: RigBuildMode.a1,
    label: 'A1 deterministic',
    bmsRange: 'BMS 0.75-1.00',
    decisionPath: 'Rules, tests, gates, and local data decide.',
    guardrail: 'No model in the decision path; unknown escalates.',
    productUse:
        'Safety stops, proof checks, ship gates, and exact workout math.',
  ),
  RigBuildModeArchetype(
    mode: RigBuildMode.a2,
    label: 'A2 hybrid typed',
    bmsRange: 'BMS 0.45-0.74',
    decisionPath: 'Typed assistance supports a deterministic shell.',
    guardrail: 'Strict schema, bounded retry, source trace, and gate review.',
    productUse: 'Plan adjustment, nutrition framing, and coach explanation.',
  ),
  RigBuildModeArchetype(
    mode: RigBuildMode.a3,
    label: 'A3 agent bounded',
    bmsRange: 'BMS 0.25-0.44',
    decisionPath: 'A bounded loop proposes options until criteria are met.',
    guardrail: 'Fixed scope, iteration cap, and human-readable kill switch.',
    productUse: 'New user ambiguity, program design, and recovery tradeoffs.',
  ),
  RigBuildModeArchetype(
    mode: RigBuildMode.a4,
    label: 'A4 LLM agent free',
    bmsRange: 'BMS 0.00-0.24',
    decisionPath: 'Exploration is allowed only as a draft, never an action.',
    guardrail: 'Hard cap, explicit approval before external or high-risk use.',
    productUse: 'Brand exploration, novel coach concepts, and unproven flows.',
  ),
];

RigSystemsEngineeringSnapshot buildRigSystemsEngineeringSnapshot(
  SessionState state,
) {
  final score = _bmsScoreForState(state);
  final archetype = rigArchetypeForBms(score);
  final diamond = _dominantDiamondForState(state);
  final step = _currentStepForState(state);

  return RigSystemsEngineeringSnapshot(
    bmsScore: score,
    selectedArchetype: archetype,
    dominantDiamond: diamond,
    currentStep: step,
    coordinate: 'L4-${diamond.id}-${archetype.mode.id}-${step.id}',
    escalationRule: _escalationRule(archetype.mode),
    killSwitch: _killSwitchForState(state, archetype.mode),
    archetypes: rigBuildModeArchetypes,
    tripleDoubleDiamondCells: buildTripleDoubleDiamondCells(archetype.mode),
    sourceIds: rigSystemsEngineeringSourceIds,
  );
}

RigBuildModeArchetype rigArchetypeForBms(double bmsScore) {
  if (bmsScore >= 0.75) return rigBuildModeArchetypes[0];
  if (bmsScore >= 0.45) return rigBuildModeArchetypes[1];
  if (bmsScore >= 0.25) return rigBuildModeArchetypes[2];
  return rigBuildModeArchetypes[3];
}

List<RigDiamondCell> buildTripleDoubleDiamondCells(RigBuildMode activeMode) {
  return [
    for (final diamond in RigDiamond.values)
      for (final step in RigProcessStep.values)
        RigDiamondCell(
          diamond: diamond,
          step: step,
          mode: _modeForDiamondStep(diamond, step, activeMode),
          coordinate:
              'L4-${diamond.id}-${_modeForDiamondStep(diamond, step, activeMode).id}-${step.id}',
          job: _jobForDiamondStep(diamond, step),
          exitGate: _exitGateForStep(step),
        ),
  ];
}

bool rigSystemsCopyIsGateSafe(RigSystemsEngineeringSnapshot snapshot) {
  final copy = [
    snapshot.selectedArchetype.label,
    snapshot.selectedArchetype.decisionPath,
    snapshot.selectedArchetype.guardrail,
    snapshot.selectedArchetype.productUse,
    snapshot.coordinate,
    snapshot.escalationRule,
    snapshot.killSwitch,
    for (final archetype in snapshot.archetypes)
      '${archetype.label} ${archetype.decisionPath} ${archetype.guardrail}',
    for (final cell in snapshot.tripleDoubleDiamondCells)
      '${cell.diamond.label} ${cell.step.label} ${cell.job} ${cell.exitGate}',
  ].join(' ').toLowerCase();
  const blocked = [
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

double _bmsScoreForState(SessionState state) {
  if (hasReportedPain(state.lastDebrief?.painNotes)) return 0.88;

  var score = 0.22;
  if (state.readinessEntry != null) score += 0.18;
  if (state.wearableSignal != null) score += 0.14;
  if (state.nutritionTarget != null) score += 0.12;
  if (_completedSessions(state).isNotEmpty) score += 0.16;
  if (state.activeSession != null) score += 0.06;
  if (state.lastDebrief != null) score += 0.06;
  return score.clamp(0.0, 0.94);
}

RigDiamond _dominantDiamondForState(SessionState state) {
  if (state.activeSession != null) return RigDiamond.d1;
  if (state.history.isNotEmpty || state.readinessEntry != null) {
    return RigDiamond.d2;
  }
  return RigDiamond.d3;
}

RigProcessStep _currentStepForState(SessionState state) {
  if (hasReportedPain(state.lastDebrief?.painNotes)) {
    return RigProcessStep.quality;
  }
  if (state.readinessEntry == null) return RigProcessStep.intent;
  if (state.nutritionTarget == null) return RigProcessStep.question;
  if (state.history.isEmpty) return RigProcessStep.research;
  if (state.activeSession != null) return RigProcessStep.solution;
  return RigProcessStep.proof;
}

RigBuildMode _modeForDiamondStep(
  RigDiamond diamond,
  RigProcessStep step,
  RigBuildMode activeMode,
) {
  if (step == RigProcessStep.proof || step == RigProcessStep.integrate) {
    return RigBuildMode.a1;
  }
  if (diamond == RigDiamond.d1 && step == RigProcessStep.solution) {
    return RigBuildMode.a1;
  }
  if (diamond == RigDiamond.d3 && step == RigProcessStep.intent) {
    return RigBuildMode.a3;
  }
  if (step == RigProcessStep.quality) return RigBuildMode.a2;
  return activeMode;
}

String _jobForDiamondStep(RigDiamond diamond, RigProcessStep step) {
  return switch ((diamond, step)) {
    (RigDiamond.d1, RigProcessStep.intent) => 'Name the next user action.',
    (RigDiamond.d1, RigProcessStep.question) => 'Find the operational blocker.',
    (RigDiamond.d1, RigProcessStep.research) => 'Inspect local session state.',
    (RigDiamond.d1, RigProcessStep.solution) =>
      'Choose the safest action path.',
    (RigDiamond.d1, RigProcessStep.quality) =>
      'Check readiness and pain bounds.',
    (RigDiamond.d1, RigProcessStep.proof) => 'Record the action trace.',
    (RigDiamond.d1, RigProcessStep.integrate) => 'Persist the next state.',
    (RigDiamond.d2, RigProcessStep.intent) => 'Map the product mechanism.',
    (RigDiamond.d2, RigProcessStep.question) =>
      'Expose the engineering unknown.',
    (RigDiamond.d2, RigProcessStep.research) => 'Read source and test context.',
    (RigDiamond.d2, RigProcessStep.solution) =>
      'Patch the smallest viable slice.',
    (RigDiamond.d2, RigProcessStep.quality) => 'Run deterministic checks.',
    (RigDiamond.d2, RigProcessStep.proof) =>
      'Seal command and artifact evidence.',
    (RigDiamond.d2, RigProcessStep.integrate) => 'Wire the verified path.',
    (RigDiamond.d3, RigProcessStep.intent) => 'Name the emotional job.',
    (RigDiamond.d3, RigProcessStep.question) => 'Pressure-test trust language.',
    (RigDiamond.d3, RigProcessStep.research) =>
      'Trace brand and safety inputs.',
    (RigDiamond.d3, RigProcessStep.solution) => 'Shape the user-facing moment.',
    (RigDiamond.d3, RigProcessStep.quality) => 'Reject generic or unsafe copy.',
    (RigDiamond.d3, RigProcessStep.proof) => 'Record the claim boundary.',
    (RigDiamond.d3, RigProcessStep.integrate) => 'Ship only approved surfaces.',
  };
}

String _exitGateForStep(RigProcessStep step) {
  return switch (step) {
    RigProcessStep.intent => 'Intent clear',
    RigProcessStep.question => 'Unknowns named',
    RigProcessStep.research => 'Source or state read',
    RigProcessStep.solution => 'Mechanism selected',
    RigProcessStep.quality => 'Gate checked',
    RigProcessStep.proof => 'ProofPacket ready',
    RigProcessStep.integrate => 'State integrated',
  };
}

String _escalationRule(RigBuildMode mode) {
  return switch (mode) {
    RigBuildMode.a1 => 'A1 unknown escalates to A3.1 human review.',
    RigBuildMode.a2 => 'A2 schema failure escalates to A3 bounded review.',
    RigBuildMode.a3 => 'A3 loop stops at cap or routes to human review.',
    RigBuildMode.a4 => 'A4 stays draft-only until explicitly approved.',
  };
}

String _killSwitchForState(SessionState state, RigBuildMode mode) {
  if (hasReportedPain(state.lastDebrief?.painNotes)) {
    return 'Stop loaded progression until pain-free variation is selected.';
  }
  if (mode == RigBuildMode.a4) {
    return 'No external action, no prescription, no launch claim.';
  }
  return 'Block action when source, state, or safety boundary is missing.';
}

List<WorkoutSession> _completedSessions(SessionState state) {
  return state.history
      .where(
        (session) => session.endedAt != null && session.loggedSets.isNotEmpty,
      )
      .toList(growable: false);
}
