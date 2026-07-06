/// M4: Mental health resources — crisis support and wellness tools.
///
/// Pre-loaded resource directory for mental health support. Provides
/// categorized resources for crisis intervention, therapy access,
/// community support, and psychoeducation.
///
/// IMPORTANT DISCLAIMER:
/// This app is not a substitute for professional mental health care.
/// If you or someone you know is in crisis, contact emergency services
/// (911) or a crisis hotline immediately.
///
/// Pure Dart, deterministic — no I/O, no Flutter dependencies.
library;

// ── Resource Category ────────────────────────────────────────────────────

/// Category of mental health resource.
enum ResourceCategory {
  /// Immediate crisis intervention (suicide, self-harm, emergency).
  crisis,

  /// Professional therapy and counseling services.
  therapy,

  /// Peer support and community organizations.
  community,

  /// Educational content, self-help tools, and apps.
  education,
}

// ── MentalHealthResource ─────────────────────────────────────────────────

/// A mental health resource entry.
class MentalHealthResource {
  const MentalHealthResource({
    required this.name,
    required this.description,
    required this.category,
    this.phone,
    this.url,
    this.textNumber,
    this.availableHours,
    this.cost,
    this.isFree = false,
  });

  /// Resource name.
  final String name;

  /// Brief description of the service.
  final String description;

  /// Resource category.
  final ResourceCategory category;

  /// Phone number (null if text/online only).
  final String? phone;

  /// Website URL.
  final String? url;

  /// Text/SMS number for crisis text services.
  final String? textNumber;

  /// Hours of availability (null = 24/7).
  final String? availableHours;

  /// Cost information (null = varies).
  final String? cost;

  /// Whether the service is free.
  final bool isFree;

  /// Primary contact method label.
  String get contactLabel {
    if (phone != null) return 'Call $phone';
    if (textNumber != null) return 'Text $textNumber';
    if (url != null) return 'Visit website';
    return 'See description';
  }

  @override
  String toString() => 'MentalHealthResource($name, ${category.name})';
}

// ── Disclaimer ───────────────────────────────────────────────────────────

/// Standard disclaimer shown alongside all mental health resources.
const mentalHealthDisclaimer =
    'This app is not a substitute for professional mental health care. '
    'If you are in immediate danger or experiencing a mental health '
    'crisis, please contact emergency services (911) or a crisis '
    'hotline listed below. The resources provided are for informational '
    'purposes only and do not constitute medical advice.';

/// Crisis-specific warning text.
const crisisWarning =
    'If you or someone you know is thinking about suicide or self-harm, '
    'please reach out immediately. You are not alone, and help is '
    'available 24/7.';

// ── Pre-loaded Resources ─────────────────────────────────────────────────

/// Pre-loaded mental health resources.
class MentalHealthResources {
  MentalHealthResources._();

  // ── Crisis Resources ──────────────────────────────────────────────────

  static const suicidePreventionLifeline = MentalHealthResource(
    name: '988 Suicide & Crisis Lifeline',
    description:
        'Free, confidential 24/7 support for people in suicidal crisis '
        'or emotional distress. Call or text 988 to connect with a '
        'trained counselor.',
    category: ResourceCategory.crisis,
    phone: '988',
    url: 'https://988lifeline.org',
    availableHours: '24/7',
    isFree: true,
  );

  static const crisisTextLine = MentalHealthResource(
    name: 'Crisis Text Line',
    description:
        'Free 24/7 text-based crisis support. Text HOME to 741741 to '
        'connect with a trained crisis counselor.',
    category: ResourceCategory.crisis,
    textNumber: '741741',
    url: 'https://www.crisistextline.org',
    availableHours: '24/7',
    isFree: true,
  );

  static const samhsaHelpline = MentalHealthResource(
    name: 'SAMHSA National Helpline',
    description:
        'Free, confidential, 24/7 treatment referral and information '
        'service for substance abuse and mental health disorders.',
    category: ResourceCategory.crisis,
    phone: '1-800-662-4357',
    url: 'https://www.samhsa.gov/find-help/national-helpline',
    availableHours: '24/7',
    isFree: true,
  );

  static const trevorProject = MentalHealthResource(
    name: 'The Trevor Project',
    description:
        'Crisis intervention and suicide prevention services for '
        'LGBTQ+ young people under 25.',
    category: ResourceCategory.crisis,
    phone: '1-866-488-7386',
    textNumber: '678-678',
    url: 'https://www.thetrevorproject.org',
    availableHours: '24/7',
    isFree: true,
  );

  // ── Therapy Resources ─────────────────────────────────────────────────

  static const betterHelp = MentalHealthResource(
    name: 'BetterHelp',
    description:
        'Online therapy platform matching users with licensed therapists. '
        'Messaging, phone, and video sessions available.',
    category: ResourceCategory.therapy,
    url: 'https://www.betterhelp.com',
    cost: 'Subscription-based (financial aid available)',
    isFree: false,
  );

  static const talkspace = MentalHealthResource(
    name: 'Talkspace',
    description:
        'Online therapy with licensed therapists via text, audio, and '
        'video messaging. Insurance may cover costs.',
    category: ResourceCategory.therapy,
    url: 'https://www.talkspace.com',
    cost: 'Subscription-based (insurance accepted)',
    isFree: false,
  );

  static const openPathCollective = MentalHealthResource(
    name: 'Open Path Collective',
    description:
        'Affordable therapy network. Sessions range from \$30-\$80 with '
        'a one-time \$65 lifetime membership fee.',
    category: ResourceCategory.therapy,
    url: 'https://openpathcollective.org',
    cost: '\$30-\$80 per session + \$65 membership',
    isFree: false,
  );

  // ── Community Resources ───────────────────────────────────────────────

  static const nami = MentalHealthResource(
    name: 'NAMI (National Alliance on Mental Illness)',
    description:
        'The largest grassroots mental health organization. Offers '
        'support groups, education programs, and advocacy for people '
        'affected by mental illness.',
    category: ResourceCategory.community,
    phone: '1-800-950-6264',
    url: 'https://www.nami.org',
    availableHours: 'M-F 10am-10pm ET',
    isFree: true,
  );

  static const mentalHealthAmerica = MentalHealthResource(
    name: 'Mental Health America',
    description:
        'Community-based nonprofit dedicated to addressing mental health '
        'needs. Free online screening tools and local resource finder.',
    category: ResourceCategory.community,
    url: 'https://www.mhanational.org',
    isFree: true,
  );

  static const dbsAlliance = MentalHealthResource(
    name: 'Depression and Bipolar Support Alliance',
    description:
        'Peer-led support groups for people living with depression and '
        'bipolar disorder. Online and in-person meetings available.',
    category: ResourceCategory.community,
    url: 'https://www.dbsalliance.org',
    isFree: true,
  );

  // ── Education Resources ───────────────────────────────────────────────

  static const headspace = MentalHealthResource(
    name: 'Headspace',
    description:
        'Guided meditation and mindfulness app. Evidence-based programs '
        'for stress, sleep, focus, and anxiety.',
    category: ResourceCategory.education,
    url: 'https://www.headspace.com',
    cost: 'Subscription (free basics available)',
    isFree: false,
  );

  static const calm = MentalHealthResource(
    name: 'Calm',
    description:
        'Meditation, sleep stories, breathing exercises, and relaxation '
        'tools for stress and anxiety management.',
    category: ResourceCategory.education,
    url: 'https://www.calm.com',
    cost: 'Subscription (free basics available)',
    isFree: false,
  );

  static const woebot = MentalHealthResource(
    name: 'Woebot',
    description:
        'AI-powered mental health chatbot using CBT techniques. '
        'Evidence-based mood tracking and coping tools.',
    category: ResourceCategory.education,
    url: 'https://woebothealth.com',
    isFree: true,
  );

  static const mindful = MentalHealthResource(
    name: 'Mindful.org',
    description:
        'Free articles, guides, and practices for mindfulness and '
        'meditation. Science-backed content for mental wellness.',
    category: ResourceCategory.education,
    url: 'https://www.mindful.org',
    isFree: true,
  );

  // ── Collections ───────────────────────────────────────────────────────

  /// All crisis resources.
  static const List<MentalHealthResource> crisisResources = [
    suicidePreventionLifeline,
    crisisTextLine,
    samhsaHelpline,
    trevorProject,
  ];

  /// All therapy resources.
  static const List<MentalHealthResource> therapyResources = [
    betterHelp,
    talkspace,
    openPathCollective,
  ];

  /// All community resources.
  static const List<MentalHealthResource> communityResources = [
    nami,
    mentalHealthAmerica,
    dbsAlliance,
  ];

  /// All education resources.
  static const List<MentalHealthResource> educationResources = [
    headspace,
    calm,
    woebot,
    mindful,
  ];

  /// All resources combined.
  static const List<MentalHealthResource> all = [
    ...crisisResources,
    ...therapyResources,
    ...communityResources,
    ...educationResources,
  ];

  /// Get resources filtered by category.
  static List<MentalHealthResource> getByCategory(ResourceCategory category) {
    return all.where((r) => r.category == category).toList();
  }

  /// Get only free resources.
  static List<MentalHealthResource> getFreeResources() {
    return all.where((r) => r.isFree).toList();
  }

  /// Get resources by name search (case-insensitive).
  static List<MentalHealthResource> search(String query) {
    final lower = query.toLowerCase();
    return all
        .where(
          (r) =>
              r.name.toLowerCase().contains(lower) ||
              r.description.toLowerCase().contains(lower),
        )
        .toList();
  }
}
