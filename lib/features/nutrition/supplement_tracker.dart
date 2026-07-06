/// Evidence-based supplement tracking for TransformFit.
///
/// Contains a pre-loaded database of 20+ supplements with peer-reviewed
/// evidence ratings, interaction checks, and daily stack management.
///
/// Pure Dart, deterministic — no I/O, no Flutter dependencies.

enum EvidenceLevel {
  strong, // Multiple RCTs / meta-analyses support efficacy
  moderate, // At least one RCT or strong mechanistic evidence
  weak, // Anecdotal / limited studies / conflicting results
  none; // No credible evidence or debunked

  String toJson() => name;

  static EvidenceLevel fromJson(String json) {
    return EvidenceLevel.values.firstWhere(
      (e) => e.name == json,
      orElse: () => EvidenceLevel.none,
    );
  }
}

enum SupplementTiming {
  morning,
  preWorkout,
  postWorkout,
  withMeal,
  beforeBed,
  anytime;

  String toJson() => name;

  static SupplementTiming fromJson(String json) {
    return SupplementTiming.values.firstWhere(
      (e) => e.name == json,
      orElse: () => SupplementTiming.anytime,
    );
  }
}

class Supplement {
  final String name;
  final String dosage;
  final SupplementTiming timing;
  final EvidenceLevel evidenceLevel;
  final List<String> benefits;
  final List<String> interactions;
  final String? notes;

  const Supplement({
    required this.name,
    required this.dosage,
    required this.timing,
    required this.evidenceLevel,
    required this.benefits,
    this.interactions = const [],
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'dosage': dosage,
        'timing': timing.toJson(),
        'evidenceLevel': evidenceLevel.toJson(),
        'benefits': benefits,
        'interactions': interactions,
        'notes': notes,
      };

  factory Supplement.fromJson(Map<String, dynamic> json) => Supplement(
        name: json['name'] as String,
        dosage: json['dosage'] as String,
        timing: SupplementTiming.fromJson(json['timing'] as String),
        evidenceLevel:
            EvidenceLevel.fromJson(json['evidenceLevel'] as String),
        benefits:
            (json['benefits'] as List).map((b) => b as String).toList(),
        interactions: (json['interactions'] as List?)
                ?.map((i) => i as String)
                .toList() ??
            [],
        notes: json['notes'] as String?,
      );

  @override
  String toString() => '$name ($dosage) — ${evidenceLevel.name}';
}

class SupplementLog {
  final String supplementName;
  final DateTime timestamp;
  final String? dosageOverride;

  const SupplementLog({
    required this.supplementName,
    required this.timestamp,
    this.dosageOverride,
  });

  Map<String, dynamic> toJson() => {
        'supplementName': supplementName,
        'timestamp': timestamp.toIso8601String(),
        'dosageOverride': dosageOverride,
      };

  factory SupplementLog.fromJson(Map<String, dynamic> json) =>
      SupplementLog(
        supplementName: json['supplementName'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        dosageOverride: json['dosageOverride'] as String?,
      );
}

/// Manages the supplement database, logging, and interaction checks.
class SupplementTracker {
  final List<SupplementLog> _logs = [];

  // ---------------------------------------------------------------------------
  // Pre-loaded supplement database (20+ entries, evidence-rated)
  // ---------------------------------------------------------------------------

  static const List<Supplement> database = [
    // === STRONG EVIDENCE ===
    Supplement(
      name: 'Creatine Monohydrate',
      dosage: '3-5g/day',
      timing: SupplementTiming.anytime,
      evidenceLevel: EvidenceLevel.strong,
      benefits: [
        'Increased muscle strength and power output',
        'Improved high-intensity exercise performance',
        'Enhanced muscle recovery',
        'Cognitive benefits (brain creatine stores)',
      ],
      notes: 'Most researched sports supplement. Loading phase optional.',
    ),
    Supplement(
      name: 'Whey Protein',
      dosage: '20-40g per serving',
      timing: SupplementTiming.postWorkout,
      evidenceLevel: EvidenceLevel.strong,
      benefits: [
        'Convenient high-quality protein source',
        'Fast absorption for post-workout recovery',
        'Supports muscle protein synthesis',
        'Rich in leucine (key mTOR activator)',
      ],
    ),
    Supplement(
      name: 'Caffeine',
      dosage: '3-6mg/kg body weight',
      timing: SupplementTiming.preWorkout,
      evidenceLevel: EvidenceLevel.strong,
      benefits: [
        'Improved endurance performance',
        'Enhanced focus and alertness',
        'Increased fat oxidation',
        'Reduced perceived exertion',
      ],
      notes: 'Tolerance develops; cycle 2-4 weeks off periodically.',
    ),
    Supplement(
      name: 'Vitamin D3',
      dosage: '1000-4000 IU/day',
      timing: SupplementTiming.withMeal,
      evidenceLevel: EvidenceLevel.strong,
      benefits: [
        'Bone health and calcium absorption',
        'Immune function support',
        'Muscle function optimization',
        'Mood regulation (especially in low-sunlight regions)',
      ],
      notes: 'Get blood levels tested. Many people are deficient.',
    ),
    Supplement(
      name: 'Omega-3 (EPA/DHA)',
      dosage: '2-3g combined EPA+DHA/day',
      timing: SupplementTiming.withMeal,
      evidenceLevel: EvidenceLevel.strong,
      benefits: [
        'Anti-inflammatory effects',
        'Cardiovascular health',
        'Joint health and recovery',
        'Brain health and cognitive function',
      ],
      notes: 'Fish oil or algae-based. Look for high EPA/DHA ratio.',
    ),

    // === MODERATE EVIDENCE ===
    Supplement(
      name: 'Magnesium (Glycinate/Citrate)',
      dosage: '200-400mg/day',
      timing: SupplementTiming.beforeBed,
      evidenceLevel: EvidenceLevel.moderate,
      benefits: [
        'Improved sleep quality',
        'Muscle relaxation and cramp prevention',
        'Stress and anxiety reduction',
        'Supports 300+ enzymatic reactions',
      ],
      notes: 'Glycinate for sleep, citrate for general use. Avoid oxide.',
    ),
    Supplement(
      name: 'Zinc',
      dosage: '15-30mg/day',
      timing: SupplementTiming.withMeal,
      evidenceLevel: EvidenceLevel.moderate,
      benefits: [
        'Immune system support',
        'Testosterone maintenance (if deficient)',
        'Wound healing',
        'Taste and smell function',
      ],
      interactions: ['Copper depletion with long-term high-dose use'],
      notes: 'Take with food to avoid nausea.',
    ),
    Supplement(
      name: 'Vitamin B12',
      dosage: '1000-2500mcg/day (cyanocobalamin)',
      timing: SupplementTiming.morning,
      evidenceLevel: EvidenceLevel.moderate,
      benefits: [
        'Energy metabolism',
        'Red blood cell formation',
        'Neurological function',
        'DNA synthesis',
      ],
      notes: 'Especially important for vegans/vegetarians.',
    ),
    Supplement(
      name: 'Ashwagandha (KSM-66)',
      dosage: '300-600mg/day',
      timing: SupplementTiming.morning,
      evidenceLevel: EvidenceLevel.moderate,
      benefits: [
        'Cortisol reduction',
        'Stress and anxiety management',
        'Modest strength gains in some studies',
        'Improved sleep quality',
      ],
      notes: 'KSM-66 is the most studied extract.',
    ),
    Supplement(
      name: 'Citrulline Malate',
      dosage: '6-8g/day',
      timing: SupplementTiming.preWorkout,
      evidenceLevel: EvidenceLevel.moderate,
      benefits: [
        'Improved blood flow (nitric oxide precursor)',
        'Reduced muscle soreness',
        'Enhanced exercise performance',
        'Ammonia detoxification',
      ],
    ),
    Supplement(
      name: 'Beta-Alanine',
      dosage: '3-6g/day (split doses)',
      timing: SupplementTiming.preWorkout,
      evidenceLevel: EvidenceLevel.moderate,
      benefits: [
        'Increased muscle carnosine',
        'Improved endurance in 1-4 min efforts',
        'Reduced fatigue in high-intensity exercise',
      ],
      notes: 'Causes harmless tingling (paresthesia). Split doses to reduce.',
    ),
    Supplement(
      name: 'Vitamin C',
      dosage: '250-500mg/day',
      timing: SupplementTiming.withMeal,
      evidenceLevel: EvidenceLevel.moderate,
      benefits: [
        'Antioxidant protection',
        'Immune support',
        'Collagen synthesis',
        'Iron absorption enhancement',
      ],
      notes: 'Mega-doses (>1g) have diminishing returns.',
    ),
    Supplement(
      name: 'Iron',
      dosage: '18-27mg/day (if deficient)',
      timing: SupplementTiming.withMeal,
      evidenceLevel: EvidenceLevel.moderate,
      benefits: [
        'Oxygen transport (hemoglobin)',
        'Energy production',
        'Cognitive function',
        'Immune support',
      ],
      interactions: ['Reduces absorption of zinc, calcium, and caffeine'],
      notes: 'Only supplement if blood tests confirm deficiency.',
    ),
    Supplement(
      name: 'Melatonin',
      dosage: '0.5-3mg',
      timing: SupplementTiming.beforeBed,
      evidenceLevel: EvidenceLevel.moderate,
      benefits: [
        'Circadian rhythm regulation',
        'Faster sleep onset',
        'Jet lag management',
      ],
      notes: 'Lower doses (0.5-1mg) often more effective than higher.',
    ),
    Supplement(
      name: 'Probiotics',
      dosage: '10-50 billion CFU/day',
      timing: SupplementTiming.morning,
      evidenceLevel: EvidenceLevel.moderate,
      benefits: [
        'Gut microbiome diversity',
        'Digestive health',
        'Immune modulation',
        'Reduced bloating',
      ],
      notes: 'Strain-specific benefits. Look for research-backed strains.',
    ),

    // === WEAK EVIDENCE ===
    Supplement(
      name: 'BCAAs (Branched-Chain Amino Acids)',
      dosage: '5-10g',
      timing: SupplementTiming.preWorkout,
      evidenceLevel: EvidenceLevel.weak,
      benefits: [
        'May reduce muscle soreness',
        'Can help if protein intake is insufficient',
      ],
      notes:
          'Redundant if adequate protein intake (>1.6g/kg). Whey already '
          'contains BCAAs.',
    ),
    Supplement(
      name: 'Glutamine',
      dosage: '5-10g/day',
      timing: SupplementTiming.postWorkout,
      evidenceLevel: EvidenceLevel.weak,
      benefits: [
        'Gut lining support',
        'May reduce muscle soreness in some studies',
      ],
      notes:
          'Not effective for muscle building in well-nourished individuals. '
          'Mainly useful for gut health.',
    ),
    Supplement(
      name: 'Testosterone Boosters (Tribulus, etc.)',
      dosage: 'Varies by product',
      timing: SupplementTiming.anytime,
      evidenceLevel: EvidenceLevel.weak,
      benefits: [
        'Minimal evidence for testosterone increase in healthy adults',
      ],
      notes:
          'Most studies show no significant testosterone increase. '
          'Save your money.',
    ),
    Supplement(
      name: 'CLA (Conjugated Linoleic Acid)',
      dosage: '3-6g/day',
      timing: SupplementTiming.withMeal,
      evidenceLevel: EvidenceLevel.weak,
      benefits: [
        'Very modest fat loss in some studies',
        'Potential body composition changes',
      ],
      notes: 'Effects are small and inconsistent. Diet + exercise dominate.',
    ),
    Supplement(
      name: 'HMB (β-Hydroxy β-Methylbutyrate)',
      dosage: '3g/day',
      timing: SupplementTiming.preWorkout,
      evidenceLevel: EvidenceLevel.weak,
      benefits: [
        'May reduce muscle protein breakdown',
        'Potentially useful for beginners or during caloric deficit',
      ],
      notes: 'Most beneficial for untrained individuals or during catabolic states.',
    ),

    // === NO EVIDENCE / DEBUNKED ===
    Supplement(
      name: 'Fat Burners (proprietary blends)',
      dosage: 'Varies',
      timing: SupplementTiming.anytime,
      evidenceLevel: EvidenceLevel.none,
      benefits: ['Placebo effect at best'],
      notes:
          'No legal supplement meaningfully increases fat burning. '
          'Caloric deficit is the only proven approach.',
    ),
    Supplement(
      name: 'Testosterone Precursors (DHEA, Andro)',
      dosage: 'Varies',
      timing: SupplementTiming.anytime,
      evidenceLevel: EvidenceLevel.none,
      benefits: [],
      notes: 'No evidence for muscle building. Potential side effects.',
    ),
  ];

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Log a supplement intake.
  void logSupplement({
    required String supplementName,
    DateTime? timestamp,
    String? dosageOverride,
  }) {
    _logs.add(SupplementLog(
      supplementName: supplementName,
      timestamp: timestamp ?? DateTime.now(),
      dosageOverride: dosageOverride,
    ));
  }

  /// Get today's supplement log.
  List<SupplementLog> getDailyStack({DateTime? date}) {
    final target = date ?? DateTime.now();
    return _logs.where((log) {
      return log.timestamp.year == target.year &&
          log.timestamp.month == target.month &&
          log.timestamp.day == target.day;
    }).toList();
  }

  /// Get all logs.
  List<SupplementLog> get allLogs => List.unmodifiable(_logs);

  /// Look up a supplement in the database by name (case-insensitive).
  Supplement? lookup(String name) {
    final lower = name.toLowerCase();
    for (final s in database) {
      if (s.name.toLowerCase() == lower) return s;
    }
    // Partial match
    for (final s in database) {
      if (s.name.toLowerCase().contains(lower)) return s;
    }
    return null;
  }

  /// Get the evidence rating for a supplement name.
  EvidenceLevel getEvidenceRating(String supplementName) {
    final supp = lookup(supplementName);
    return supp?.evidenceLevel ?? EvidenceLevel.none;
  }

  /// Check for interactions between supplements in the daily stack.
  ///
  /// Returns a list of human-readable interaction warnings.
  List<String> checkInteractions({DateTime? date}) {
    final stack = getDailyStack(date: date);
    final stackNames = stack.map((l) => l.supplementName).toList();
    final warnings = <String>[];

    // Collect all interaction strings from stack supplements
    final stackSupps = <Supplement>[];
    for (final name in stackNames) {
      final supp = lookup(name);
      if (supp != null) stackSupps.add(supp);
    }

    // Check known interactions
    for (final supp in stackSupps) {
      for (final interaction in supp.interactions) {
        warnings.add('${supp.name}: $interaction');
      }
    }

    // Specific known interaction pairs
    final hasZinc = stackNames.any(
      (n) => n.toLowerCase().contains('zinc'),
    );
    final hasIron = stackNames.any(
      (n) => n.toLowerCase().contains('iron'),
    );
    final hasCaffeine = stackNames.any(
      (n) => n.toLowerCase().contains('caffeine'),
    );
    final hasMelatonin = stackNames.any(
      (n) => n.toLowerCase().contains('melatonin'),
    );

    if (hasZinc && hasIron) {
      warnings.add(
        'Zinc + Iron: Compete for absorption. Take at different times.',
      );
    }
    if (hasCaffeine && hasIron) {
      warnings.add(
        'Caffeine + Iron: Caffeine reduces iron absorption. '
        'Separate by 1-2 hours.',
      );
    }
    if (hasCaffeine && hasMelatonin) {
      warnings.add(
        'Caffeine + Melatonin: Opposing effects. '
        'Do not take melatonin within 6 hours of caffeine.',
      );
    }

    return warnings;
  }

  /// Get supplements filtered by evidence level.
  List<Supplement> getByEvidenceLevel(EvidenceLevel level) {
    return database.where((s) => s.evidenceLevel == level).toList();
  }

  /// Get recommended starter stack (strong evidence only).
  List<Supplement> getStarterStack() {
    return database
        .where((s) => s.evidenceLevel == EvidenceLevel.strong)
        .toList();
  }

  /// Clear all logs.
  void clearLogs() => _logs.clear();
}
