// Deviation Design System — no Flutter dependency (pure Dart enums + classes).

// ============================================================================
// TransformFit Deviation Design System
//
// Design rules derived from the 40 RIG Deviation Engines applied to push
// TransformFit to ±30σ design quality.
//
// Architecture:
//   - DeviationEngine        — enum of all 40 engines
//   - DesignRule             — a single rule derived from an engine
//   - DeviationDesignSystem  — the complete ruleset + scoring rubric
//
// Usage:
//   final rules = DeviationDesignSystem.rulesFor(DeviationEngine.quantumTunneling);
//   final score = DeviationDesignSystem.scoreScreen(screenRules);
// ============================================================================

/// All 40 RIG Deviation Engines mapped to design applications.
enum DeviationEngine {
  // === Physics Engines (State Deviation — ±30σ) ===
  quantumTunneling(31, 'Quantum Tunneling', '±30σ',
      'Cards bleed into each other, overlapping elements, depth layers'),
  pauliExclusion(32, 'Pauli Exclusion', '±30σ',
      'Every screen element must be visually unique'),
  casimirPressure(33, 'Casimir Pressure', '±30σ',
      'Whitespace creates tension and focus'),
  fineTuning(34, 'Fine-Tuning', '±30σ',
      'Every value mathematically justified — Fibonacci spacing, golden ratio proportions'),
  hawkingRadiation(35, 'Hawking Radiation', '±30σ',
      'Empty states emit valuable information'),
  speedOfLight(36, 'Speed of Light', '±30σ',
      'Animation speed follows physical laws — faster for small, slower for large'),
  absoluteZero(37, 'Absolute Zero', '±30σ',
      'Remove ALL unnecessary motion — animate only when meaningful'),
  phaseTransition(38, 'Phase Transition', '±30σ',
      'Dramatic state transitions at precise thresholds'),
  bellEntanglement(39, 'Bell Entanglement', '±30σ',
      'Connected elements respond to each other instantly'),
  vacuumFluctuation(40, 'Vacuum Fluctuation', '±30σ',
      'Even loading/empty states have subtle energy'),

  // === Cognitive Engines (Output Deviation — ±20σ) ===
  gravityEscape(1, 'Gravity Escape', '±20σ',
      'Break all layout conventions — vertical data viz, floating elements'),
  realityAnchor(2, 'Reality Anchor', '±20σ',
      'Ground truth: one-tap logging, zero-friction interaction'),
  feynmanXRay(3, 'Feynman X-Ray', '±20σ',
      'Reveal the underlying science — show formulas, algorithms, reasoning'),

  // === Nature Engines (Process Deviation — ±20σ) ===
  antColonyPheromone(21, 'Ant Colony Pheromone', '±20σ',
      'Navigation adapts to usage patterns — most-used first'),
  beeForaging(22, 'Bee Foraging', '±20σ',
      'Visual weight proportional to value — 60/25/15 attention split'),
  slimeMoldNetwork(23, 'Slime Mold Network', '±20σ',
      'Layouts self-optimize — cards reorder by user behavior');

  const DeviationEngine(
      this.number, this.name, this.sigma, this.description);

  final int number;
  final String name;
  final String sigma;
  final String description;
}

/// A single design rule derived from a deviation engine.
class DesignRule {
  const DesignRule({
    required this.engine,
    required this.rule,
    required this.check,
    required this.weight,
    this.examples = const [],
  });

  final DeviationEngine engine;
  final String rule;
  final String check;
  final double weight;
  final List<String> examples;
}

/// Complete deviation design system for TransformFit.
class DeviationDesignSystem {
  const DeviationDesignSystem._();

  // =========================================================================
  // Physics Engine Rules (±30σ)
  // =========================================================================

  static const List<DesignRule> quantumTunnelingRules = [
    DesignRule(
      engine: DeviationEngine.quantumTunneling,
      rule: 'Hero images extend beyond card boundaries',
      check: 'Hero image has overflow: visible and extends ≥8px past card edge',
      weight: 3.0,
      examples: [
        'Hero image bleeds past card borderRadius',
        'Recovery circle overlaps hero image with depth layering',
        'Progress ring sits on top of hero with shadow for depth',
      ],
    ),
    DesignRule(
      engine: DeviationEngine.quantumTunneling,
      rule: 'Cards have overlapping depth layers',
      check: 'At least one card pair overlaps by ≥4px with z-index separation',
      weight: 2.5,
      examples: [
        'Metric card overlaps section header',
        'Floating badge extends beyond parent card',
      ],
    ),
  ];

  static const List<DesignRule> pauliExclusionRules = [
    DesignRule(
      engine: DeviationEngine.pauliExclusion,
      rule: 'Every card on screen has distinct visual treatment',
      check: 'No two cards share identical radius + shadow + accent combination',
      weight: 3.0,
      examples: [
        'Recovery card: pill radius + no shadow + purple accent',
        'Workout card: md radius + low shadow + orange accent',
        'Nutrition card: lg radius + medium shadow + green accent',
      ],
    ),
  ];

  static const List<DesignRule> casimirPressureRules = [
    DesignRule(
      engine: DeviationEngine.casimirPressure,
      rule: 'Negative space draws eye to hero element',
      check: 'Hero section has ≥48px vertical whitespace above and below',
      weight: 2.5,
      examples: [
        'Recovery circle surrounded by constrained whitespace',
        'CTA button has 32px minimum clearance on all sides',
      ],
    ),
    DesignRule(
      engine: DeviationEngine.casimirPressure,
      rule: 'Whitespace creates tension around interactive elements',
      check: 'Interactive elements have ≥16px breathing room',
      weight: 2.0,
    ),
  ];

  static const List<DesignRule> fineTuningRules = [
    DesignRule(
      engine: DeviationEngine.fineTuning,
      rule: 'All spacing uses Fibonacci sequence',
      check: 'Spacing values are from set {1, 2, 3, 5, 8, 13, 21, 34, 55, 89}',
      weight: 3.0,
      examples: [
        'spaceXs=3, spaceSm=5, spaceMd=8, spaceLg=13, spaceXl=21, spaceXxl=34, spaceXxxl=55, spaceHuge=89',
      ],
    ),
    DesignRule(
      engine: DeviationEngine.fineTuning,
      rule: 'All proportions use golden ratio (φ ≈ 1.618)',
      check: 'Card aspect ratios, section splits follow φ',
      weight: 2.5,
      examples: [
        'Hero section = 61.8% of viewport, rest = 38.2%',
        'Primary data value is 1.618× the size of secondary label',
      ],
    ),
  ];

  static const List<DesignRule> hawkingRadiationRules = [
    DesignRule(
      engine: DeviationEngine.hawkingRadiation,
      rule: 'Empty workout state shows motivational quote + suggested exercise',
      check: 'EmptyState widget contains quote text and action suggestion',
      weight: 2.0,
      examples: [
        'No workouts: "Your body hears everything your mind says." + "Start with a 5-min warm-up"',
        'No nutrition: "Fuel the machine." + "Log your first meal"',
      ],
    ),
    DesignRule(
      engine: DeviationEngine.hawkingRadiation,
      rule: 'Empty states emit information, not void',
      check: 'No blank/empty screens without informational content',
      weight: 2.5,
    ),
  ];

  static const List<DesignRule> speedOfLightRules = [
    DesignRule(
      engine: DeviationEngine.speedOfLight,
      rule: 'Animation duration scales with element size',
      check: 'Small elements ≤150ms, medium ≤300ms, large ≤500ms, celebration ≤1500ms',
      weight: 2.0,
      examples: [
        'Icon rotation: 100ms',
        'Card expand: 300ms',
        'Screen transition: 500ms',
        'PR celebration: 1500ms',
      ],
    ),
  ];

  static const List<DesignRule> absoluteZeroRules = [
    DesignRule(
      engine: DeviationEngine.absoluteZero,
      rule: 'Only animate when it communicates meaning',
      check: 'No decorative-only animations — every animation conveys state change',
      weight: 2.5,
      examples: [
        'Score number animates on change (meaningful)',
        'Recovery ring fills on load (meaningful)',
        'No idle floating/pulsing decorative elements',
      ],
    ),
  ];

  static const List<DesignRule> phaseTransitionRules = [
    DesignRule(
      engine: DeviationEngine.phaseTransition,
      rule: 'Dramatic state transitions at precise thresholds',
      check: 'Readiness state changes trigger full-screen color/animation shift',
      weight: 3.0,
      examples: [
        'Readiness crosses maintain→deload: screen shifts to blue tint',
        'PR achieved: explosive celebration animation + color burst',
        'Streak broken: dramatic fade + recovery prompt',
      ],
    ),
  ];

  static const List<DesignRule> bellEntanglementRules = [
    DesignRule(
      engine: DeviationEngine.bellEntanglement,
      rule: 'Connected elements respond to each other instantly',
      check: 'State change in one widget triggers visual response in related widgets',
      weight: 2.5,
      examples: [
        'Mood check-in changes → recovery circle color shifts',
        'Set logged → progress bar animates immediately',
        'Nutrition logged → macro rings update in real-time',
      ],
    ),
  ];

  static const List<DesignRule> vacuumFluctuationRules = [
    DesignRule(
      engine: DeviationEngine.vacuumFluctuation,
      rule: 'Loading/empty states have subtle energy',
      check: 'Skeleton loaders pulse with accent color, empty states have subtle motion',
      weight: 2.0,
      examples: [
        'Skeleton cards pulse with accentPrimary at 0.3 opacity',
        'Empty state background has subtle gradient animation',
      ],
    ),
  ];

  // =========================================================================
  // Cognitive Engine Rules (±20σ)
  // =========================================================================

  static const List<DesignRule> gravityEscapeRules = [
    DesignRule(
      engine: DeviationEngine.gravityEscape,
      rule: 'Break conventional fitness app layout conventions',
      check: 'At least one non-standard layout pattern per screen',
      weight: 2.0,
      examples: [
        'Vertical scrolling data visualization instead of horizontal carousels',
        'Floating action elements instead of fixed bottom bar',
        'Non-standard navigation patterns',
      ],
    ),
  ];

  static const List<DesignRule> realityAnchorRules = [
    DesignRule(
      engine: DeviationEngine.realityAnchor,
      rule: 'One-tap actions for core workflows',
      check: 'Workout logging, mood check-in, coach access require ≤2 taps',
      weight: 2.5,
      examples: [
        'One-tap workout start from home screen',
        'Zero-friction mood slider (no modal)',
        'Instant coach response (pre-loaded suggestions)',
      ],
    ),
  ];

  static const List<DesignRule> feynmanXRayRules = [
    DesignRule(
      engine: DeviationEngine.feynmanXRay,
      rule: 'Design reveals underlying science',
      check: 'Data screens show formulas/algorithm explanations on tap',
      weight: 2.0,
      examples: [
        'Readiness score shows formula: R = (HRV + Sleep + Strain) / 3',
        'Progression algorithm explained: "Adding 2.5kg because you hit 3×8 last week"',
        'Coach recommendation shows reasoning chain',
      ],
    ),
  ];

  // =========================================================================
  // Nature Engine Rules (±20σ)
  // =========================================================================

  static const List<DesignRule> antColonyPheromoneRules = [
    DesignRule(
      engine: DeviationEngine.antColonyPheromone,
      rule: 'Navigation adapts to usage patterns',
      check: 'Most-used features appear first in nav/lists',
      weight: 2.0,
      examples: [
        'Exercise library sorts by recency + frequency',
        'Bottom nav items reorder based on usage analytics',
      ],
    ),
  ];

  static const List<DesignRule> beeForagingRules = [
    DesignRule(
      engine: DeviationEngine.beeForaging,
      rule: 'Visual weight proportional to value (60/25/15 split)',
      check: 'Hero element gets ≥50% of visual attention on each screen',
      weight: 2.5,
      examples: [
        'Home screen: Recovery circle = 60%, Workout card = 25%, Quick stats = 15%',
        'Workout screen: Active exercise = 60%, Next exercise = 25%, Timer = 15%',
      ],
    ),
  ];

  static const List<DesignRule> slimeMoldNetworkRules = [
    DesignRule(
      engine: DeviationEngine.slimeMoldNetwork,
      rule: 'Dashboard cards reorder based on user behavior',
      check: 'Dashboard card order is dynamic, not hardcoded',
      weight: 2.0,
      examples: [
        'Most-interacted card floats to top position',
        'Recently used features appear first',
      ],
    ),
  ];

  // =========================================================================
  // Complete Ruleset
  // =========================================================================

  /// All design rules across all 16 applied engines.
  static final List<DesignRule> allRules = [
    ...quantumTunnelingRules,
    ...pauliExclusionRules,
    ...casimirPressureRules,
    ...fineTuningRules,
    ...hawkingRadiationRules,
    ...speedOfLightRules,
    ...absoluteZeroRules,
    ...phaseTransitionRules,
    ...bellEntanglementRules,
    ...vacuumFluctuationRules,
    ...gravityEscapeRules,
    ...realityAnchorRules,
    ...feynmanXRayRules,
    ...antColonyPheromoneRules,
    ...beeForagingRules,
    ...slimeMoldNetworkRules,
  ];

  /// Rules for a specific engine.
  static List<DesignRule> rulesFor(DeviationEngine engine) {
    return allRules.where((r) => r.engine == engine).toList();
  }

  /// All engines that have been applied to the design system.
  static List<DeviationEngine> get appliedEngines =>
      DeviationEngine.values.where((e) => rulesFor(e).isNotEmpty).toList();

  // =========================================================================
  // Scoring
  // =========================================================================

  /// Maximum possible score (sum of all rule weights).
  static double get maxScore =>
      allRules.fold<double>(0, (sum, r) => sum + r.weight);

  /// Score a screen against all rules.
  /// Returns a map of engine → score (0.0–1.0 per rule).
  static DesignScore scoreScreen(Map<DeviationEngine, double> engineScores) {
    double totalEarned = 0;
    double totalPossible = 0;

    for (final rule in allRules) {
      totalPossible += rule.weight;
      final engineScore = engineScores[rule.engine] ?? 0;
      totalEarned += rule.weight * engineScore;
    }

    final double normalized = totalPossible > 0
        ? (totalEarned / totalPossible * 100).clamp(0.0, 100.0)
        : 0.0;

    return DesignScore(
      raw: totalEarned,
      max: totalPossible,
      normalized: normalized,
      engineScores: engineScores,
    );
  }

  /// Quality tier based on normalized score.
  static QualityTier tierFor(double normalizedScore) {
    if (normalizedScore >= 90) return QualityTier.sigma30;
    if (normalizedScore >= 85) return QualityTier.publicFacing;
    if (normalizedScore >= 80) return QualityTier.internal;
    if (normalizedScore >= 70) return QualityTier.acceptable;
    if (normalizedScore >= 50) return QualityTier.needsWork;
    return QualityTier.reject;
  }
}

/// Score result for a screen.
class DesignScore {
  const DesignScore({
    required this.raw,
    required this.max,
    required this.normalized,
    required this.engineScores,
  });

  final double raw;
  final double max;
  final double normalized;
  final Map<DeviationEngine, double> engineScores;

  QualityTier get tier => DeviationDesignSystem.tierFor(normalized);

  @override
  String toString() =>
      'DesignScore(${normalized.toStringAsFixed(1)}/100, tier=$tier)';
}

/// Quality tiers for design scoring.
enum QualityTier {
  reject('Reject', '<50σ — Does not meet minimum bar'),
  needsWork('Needs Work', '50-69σ — Significant gaps'),
  acceptable('Acceptable', '70-79σ — Meets basic requirements'),
  internal('Internal', '80-84σ — Good enough for internal use'),
  publicFacing('Public Facing', '85-89σ — Ship-ready quality'),
  sigma30('±30σ', '90+σ — Exceptional, deviation-engine quality');

  const QualityTier(this.label, this.description);

  final String label;
  final String description;
}
