# TransformFit — Production Design Packets (5 Critical Screens)

**Author**: TransformFit Design Lead
**Date**: 2026-07-07
**Status**: PRODUCTION-READY — binding for Flutter implementation
**Design System**: DigitalAtelier v3 "Obsidian Forge" (TRANSFORMFIT_DESIGN_SYSTEM_SPEC.md)
**PRD**: TRANSFORMFIT_PRD.md v1.0

---

## TABLE OF CONTENTS

1. [Screen 1: Landing Page](#screen-1-landing-page)
2. [Screen 2: Today Dashboard](#screen-2-today-dashboard)
3. [Screen 3: Active Workout Logger](#screen-3-active-workout-logger)
4. [Screen 4: Coach Chat](#screen-4-coach-chat)
5. [Screen 5: Progress Dashboard](#screen-5-progress-dashboard)

---

## SCREEN 1: LANDING PAGE

### 1.1 Product Objective

Convert a first-time visitor into an active user within 10 seconds. The landing page is the single highest-leverage conversion surface in the app. Every element must reduce friction between curiosity and commitment. No signup wall before plan reveal — the user experiences value before being asked for anything.

### 1.2 User Job-to-Be-Done

> "I just downloaded this app. Tell me in 5 seconds why I should care, and make it obvious what to do next."

The user is in evaluation mode. They have 3-5 fitness apps on their phone already. TransformFit must differentiate immediately: this is not another tracker, this is a coach that already knows what you need.

### 1.3 Screen Role in the App

- **Position**: First screen after App Store download. No auth gate.
- **Flow**: Landing → Intake (8 steps) → Plan Reveal → First Workout
- **Exit paths**: "Begin" (primary), "Sign in" (secondary), back/kill (leak)
- **Navigation**: No bottom nav, no top bar. Immersive full-screen experience.

### 1.4 User State & Emotional State

| Dimension | State |
|-----------|-------|
| **Cognitive load** | High — evaluating multiple apps simultaneously |
| **Emotional state** | Skeptical, curious, slightly anxious (fitness = vulnerability) |
| **Trust level** | Zero — no relationship yet |
| **Time budget** | ≤10 seconds before swipe-to-kill |
| **Physical context** | Scrolling App Store → tapping "Open" → this screen |

**Design implication**: No text-heavy explanations. The hero image does the emotional work. The headline does the intellectual work. The button does the conversion work.

### 1.5 Information Hierarchy

```
PRIORITY 1 (0-2s):  Hero image — emotional anchor, aspirational but grounded
PRIORITY 2 (2-4s):  Headline — "A coach who already noticed." (Playfair, displayLarge)
PRIORITY 3 (4-6s):  Subtitle — "Before you log a single rep, we built your plan." (Inter, bodyLarge)
PRIORITY 4 (6-8s):  CTA — "Begin" accent button (pulsing, impossible to miss)
PRIORITY 5 (8-10s): Secondary — "Sign in to existing account" (ghost button)
PRIORITY 6 (10s+):  Social proof — App Store rating, user count (barely visible)
```

**Visual scan path**: Center-vertical. Eye lands on headline → drops to button. No lateral scanning needed.

### 1.6 Component List

| Component | Spec | Token Reference |
|-----------|------|-----------------|
| `HeroImage` | `hero_workout.png`, full-screen, `BoxFit.cover` | Asset: `assets/images/hero_workout.png` |
| `DarkOverlay` | `Colors.black.withOpacity(0.70)`, full-screen `Container` | Canvas overlay |
| `HeadlineText` | Playfair Display, 36px, w700, `textPrimary`, center, `displayLarge` | §4.2 displayLarge |
| `SubtitleText` | Inter, 17px, w400, `textSecondary`, center, `bodyLarge` | §4.2 bodyLarge |
| `PrimaryCTA` | `TFGradientButton` — heroGradient, 56px height, full-width - 40px margin, `radiusSm` (8px) | §7.2 Gradient Button |
| `SecondaryCTA` | `TFGhostButton` — transparent bg, `textSecondary`, 44px height | §7.2 Ghost Button |
| `SocialProofRow` | Row: star icon + "4.8" + "•" + "12K+ athletes" + "•" + App Store badge | Custom Row |
| `SafeArea` | Top + bottom safe area padding | System |

### 1.7 Interaction States

| State | Visual | Haptic | Duration |
|-------|--------|--------|----------|
| **Default** | Button pulses gently (opacity 1.0 → 0.85 → 1.0, 1s cycle) | None | Continuous |
| **Hover/Focus** | Border glow: `accentGlow` shadow, `shadowMd` | None | — |
| **Pressed** | Scale 0.97, brightness 0.9 | `HapticFeedback.lightImpact()` | 100ms |
| **Released → Navigate** | Button contracts, fade out entire screen | `HapticFeedback.mediumImpact()` | 200ms |
| **Disabled** | 40% opacity (should never occur on this screen) | None | — |

**"Sign in" ghost button**: No pulse, no glow. Underline on tap. Text color: `textSecondary`.

### 1.8 Motion & Animation Guidance

| Element | Trigger | Animation | Duration | Curve | Start State | End State |
|---------|---------|-----------|----------|-------|-------------|-----------|
| Canvas | App open | Fade in from black | 300ms | `easeOut` | `Opacity 0` | `Opacity 1` |
| Hero image | 300ms after open | Fade in + scale 1.05 → 1.0 | 600ms | `easeOut` | Hidden, 5% scale | Visible, 100% |
| Headline | 600ms after open | Fade in + translateY 20px → 0 | 400ms | `easeOut` | Hidden, 20px below | Visible, 0px |
| Subtitle | 900ms after open | Fade in + translateY 20px → 0 | 400ms | `easeOut` | Hidden, 20px below | Visible, 0px |
| CTA button | 1200ms after open | Fade in + scale 0.95 → 1.0 | 400ms | `easeOut` | Hidden, 95% | Visible, 100% |
| CTA pulse | Continuous after appear | Opacity 1.0 → 0.85 → 1.0 | 1000ms | `easeInOut` (loop) | Full opacity | 85% opacity |
| Social proof | 1500ms after open | Fade in | 400ms | `easeOut` | Hidden | Visible |
| Screen exit | "Begin" tap | Fade out + scale 1.0 → 0.95 | 200ms | `easeIn` | Visible | Hidden |

**Reduced motion fallback**: If `MediaQuery.disableAnimations` is true, all elements appear instantly with no animation. Button pulse is replaced with a 2px accent border that remains static.

### 1.9 Empty / Loading / Error States

| State | Condition | Visual | Copy |
|-------|-----------|--------|------|
| **Loading (cold start)** | Asset preload in progress | Black canvas, shimmer placeholder for hero area | None |
| **Asset load failure** | `hero_workout.png` fails to load | Fallback: solid `canvas` (#0A0A0A) with subtle radial gradient from `accentGlow` center | Copy unchanged |
| **Network unavailable** | No connectivity at first open | No impact — screen is fully offline-capable (all assets local) | N/A |
| **Deep link error** | Invalid deep link lands here | Normal landing page behavior | N/A |

**Design rule**: This screen MUST work 100% offline. All assets are bundled in the APK/IPA. No network calls until the user taps "Begin."

### 1.10 Accessibility Notes

| Requirement | Implementation |
|-------------|---------------|
| **Semantic labels** | `Semantics(label: 'TransformFit. A coach who already noticed. Before you log a single rep, we built your plan.')` on the content column |
| **CTA semantics** | `Semantics(button: true, label: 'Begin. Start your TransformFit journey.')` |
| **Secondary semantics** | `Semantics(button: true, label: 'Sign in to existing account.')` |
| **Color contrast** | `textPrimary` (#F0EDE8) on 70% dark overlay over image = ≥12:1 ✓ |
| **CTA contrast** | `textInverse` (#0A0A0A) on `accent` (#F97316) = 4.8:1 ✓ |
| **Touch targets** | CTA: 56px height ≥ 44px ✓. Ghost button: 44px height ≥ 44px ✓ |
| **Dynamic type** | Headline scales to 200%. At >150%, subtitle and CTA stack vertically with increased spacing |
| **Screen reader** | Announces: "TransformFit landing page. Heading: A coach who already noticed. Button: Begin. Button: Sign in to existing account." |
| **Reduced motion** | All animations disabled. Elements appear instantly. Button pulse replaced with static accent border. |

### 1.11 Flutter Implementation Handoff

```dart
// Screen: LandingScreen
// Route: /onboarding/landing
// Widget: Scaffold(body: Stack)

class LandingScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reduceMotion = MediaQuery.disableAnimations(context);
    
    return Scaffold(
      backgroundColor: TFColors.canvas,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // P1: Hero image (cached, offline-first)
          Positioned.fill(
            child: CachedImage(
              asset: 'assets/images/hero_workout.png',
              fit: BoxFit.cover,
              fallback: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [TFColors.accentGlow, TFColors.canvas],
                  ),
                ),
              ),
            ),
          ),
          // Dark overlay
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.70)),
          ),
          // Content column
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: TFSpacing.s5),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 3),
                  // Headline
                  _AnimatedText(
                    delay: 600,
                    reduceMotion: reduceMotion,
                    child: Text(
                      'A coach who already noticed.',
                      style: TFType.displayLarge,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: TFSpacing.s3),
                  // Subtitle
                  _AnimatedText(
                    delay: 900,
                    reduceMotion: reduceMotion,
                    child: Text(
                      'Before you log a single rep, we built your plan.',
                      style: TFType.bodyLarge.copyWith(color: TFColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const Spacer(flex: 2),
                  // CTA
                  _AnimatedButton(
                    delay: 1200,
                    reduceMotion: reduceMotion,
                    child: TFGradientButton(
                      text: 'Begin',
                      onPressed: () => context.push('/onboarding/intake'),
                      height: 56,
                    ),
                  ),
                  const SizedBox(height: TFSpacing.s3),
                  // Secondary
                  _AnimatedText(
                    delay: 1500,
                    reduceMotion: reduceMotion,
                    child: TFGhostButton(
                      text: 'Sign in to existing account',
                      onPressed: () => context.push('/auth'),
                    ),
                  ),
                  const SizedBox(height: TFSpacing.s7),
                  // Social proof
                  _SocialProofRow(reduceMotion: reduceMotion),
                  const Spacer(flex: 1),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

**Key implementation notes:**
- Use `CachedImage` (or `precacheImage` in `initState`) for instant hero load
- Hero gradient (`heroGradient`) for the CTA: `LinearGradient(colors: [accent, electric])`
- Pulse animation: `AnimationController` with `repeat(reverse: true)`, driving `Opacity`
- All animations gated on `!reduceMotion`
- Route: `/onboarding/landing` — no bottom nav shell for this route

### 1.12 Visual Generation Prompts

#### Hero Image: `hero_workout.png`

| Attribute | Value |
|-----------|-------|
| **Format** | PNG, 1440×2560 (9:16 portrait) |
| **Prompt** | "Cinematic gym scene, dramatic orange and purple rim lighting, chalk dust particles in air, barbell on rack with plates, shallow depth of field, dark moody atmosphere, professional fitness photography, no people, no text, no logos. Aspect ratio 9:16." |
| **Negative prompt** | "People, faces, bodies, text, logos, watermarks, stock photo feel, bright lighting, cartoon, illustration, AI artifacts, six fingers" |
| **Mood** | Aspirational, calm power, premium, grounded |
| **Color palette** | Dominant: deep blacks (#0A0A0A-#141414). Accent: orange rim light (#F97316), purple backlight (#8B5CF6). Chalk: warm white particles. |
| **App location** | Landing screen full-bleed background |
| **Accessibility** | Decorative only — `Semantics(excludeFromSemantics: true)` |
| **Export notes** | Compress to <500KB for app bundle. Serve WebP on Android, PNG on iOS. |

#### Social Proof Badge (optional)

| Attribute | Value |
|-----------|-------|
| **Format** | SVG or PNG, 120×40 |
| **Prompt** | N/A — use App Store badge from Apple/Google brand guidelines |
| **Usage** | Below secondary CTA, `textSecondary` color, 60% opacity |

### 1.13 Safety & Proof Notes

| Rule | Status |
|------|--------|
| No medical claims | ✅ "A coach who already noticed" is aspirational, not medical |
| No body-shaming | ✅ No bodies shown, no before/after, no weight-loss language |
| No fake testimonials | ✅ User count and rating are placeholder — must be replaced with real data before launch |
| No dark patterns | ✅ No countdown timers, no "only 3 spots left!", no forced signup before value |
| Privacy | ✅ No data collected on this screen. No analytics events until "Begin" tap. |
| AI narration | ❌ Not applicable — this screen is fully deterministic, no AI involvement |

**Proof requirement**: Social proof numbers (rating, user count) must be sourced from real App Store data. Do not hardcode fake numbers.

### 1.14 Acceptance Criteria

- [ ] Hero image loads in <100ms from cache on second launch
- [ ] Headline visible within 1 second of screen open
- [ ] "Begin" button visible within 1.5 seconds of screen open
- [ ] Entire screen works offline (no network dependency)
- [ ] Tapping "Begin" navigates to `/onboarding/intake` with shared-axis transition (300ms)
- [ ] Tapping "Sign in" navigates to `/auth`
- [ ] Button pulse animation runs at 60fps on mid-range devices
- [ ] All text passes WCAG AA contrast (≥4.5:1 for body, ≥3:1 for large text)
- [ ] Screen reader announces headline, subtitle, and both buttons in correct order
- [ ] Reduced motion: all elements appear instantly, no animations
- [ ] No bottom nav, no top app bar visible
- [ ] Status bar: light content (`SystemUiOverlayStyle.light`)
- [ ] Tested on iPhone SE (smallest iOS) and Pixel 7a (reference Android)

---

## SCREEN 2: TODAY DASHBOARD

### 2.1 Product Objective

Give the user a single number (recovery score) that answers "How am I doing today?" and one clear action to take. This is the screen users see every day — it must feel alive, personalized, and never overwhelming. It is the daily heartbeat of the app.

### 2.2 User Job-to-Be-Done

> "I opened the app. Tell me what to do today in 3 seconds. Don't make me think."

The user is in "morning check" mode — they have 10-30 seconds between opening the app and deciding whether to train. The recovery score tells them if today is a push day, maintain day, or deload day. The action cards tell them what to do next.

### 2.3 Screen Role in the App

- **Position**: Default home screen. Tab 1 of 5 (Today).
- **Flow**: Today → Start Workout (active logger) | Log Mood (check-in sheet) | Coach Chat
- **Refresh**: Pull-to-refresh recalculates recovery score
- **Navigation**: Bottom nav visible. Top bar: greeting + settings icon.

### 2.4 User State & Emotional State

| Dimension | State |
|-----------|-------|
| **Cognitive load** | Low — glancing, not studying |
| **Emotional state** | Variable — could be motivated, tired, anxious, or neutral |
| **Trust level** | Moderate — has used app at least once |
| **Time budget** | 10-30 seconds (check-and-go) |
| **Physical context** | Morning, pre-workout, or between tasks |

**Design implication**: The recovery score must be readable without scrolling. The action must be tappable without scrolling. Everything below the fold is supplementary.

### 2.5 Information Hierarchy

```
PRIORITY 1 (0-1s):  Recovery circle — the ONE number (280px, centered, Inter 56px bold)
PRIORITY 2 (1-2s):  Zone label — "Push" / "Maintain" / "Deload" with color indicator
PRIORITY 3 (2-3s):  Action cards — Start Workout (primary), Log Mood, Coach Chat
PRIORITY 4 (3-5s):  Coach hint — one personalized line at bottom
PRIORITY 5 (5s+):   Quick stats (if scrolled) — calories, protein, steps, water
```

**Visual scan path**: Center-down. Eye locks on recovery number → reads zone → sees action cards.

### 2.6 Component List

| Component | Spec | Token Reference |
|-----------|------|-----------------|
| `TFAppBar` | "Good morning, [Name]" + date + settings gear | §7.4 Top App Bar |
| `RecoveryCircle` | 280px diameter, 8px stroke, gradient ring (recoveryLow → recoveryMid → recovery), score in `dataHero` (Inter 56px w700), zone label in `labelMedium` | §10.3 Readiness Ring |
| `ZoneLabel` | Colored dot + text. Push: `positive` (#10B981). Maintain: `neutral` (#F97316). Deload: `recoveryLow` (#F97316 muted) | §3.3 Semantic Colors |
| `ActionCard_StartWorkout` | `TFCard` with `fitness_center` icon, "Start Workout" label, accent left border | §7.1 TFCard |
| `ActionCard_LogMood` | `TFCard` with `mood` icon, "Log Mood" label, `electric` left border | §7.1 TFCard |
| `ActionCard_CoachChat` | `TFCard` with `chat` icon, "Coach Chat" label, `sky` left border | §7.1 TFCard |
| `CoachHint` | `TFCoachBubble` — compact, single line, Playfair 15px, no action buttons | §7.6 TFCoachBubble |
| `QuickStatsRow` | 4× `TFMetricTile` in horizontal scroll: Calories, Protein, Steps, Water | §7.5 TFMetricTile |
| `ShimmerLoader` | Skeleton for recovery circle + cards while data loads | §11.3 Skeleton loading |

### 2.7 Interaction States

| Element | State | Visual | Haptic |
|---------|-------|--------|--------|
| **Recovery circle** | Default | Animated ring + score | None |
| | Loading | Shimmer skeleton (1500ms loop) | None |
| | Error | Ring at 0, "Unable to calculate" in `textTertiary` | None |
| | Pull-to-refresh | Ring re-animates 0→new score | `HapticFeedback.lightImpact()` |
| **Action cards** | Default | Surface bg, icon + label | None |
| | Pressed | Scale 0.97, `surfacePressed` bg | `HapticFeedback.lightImpact()` |
| | Tapped → navigate | Slide left exit | `HapticFeedback.lightImpact()` |
| **Coach hint** | Default | TFCoachBubble, single line | None |
| | Tapped | Expand to full coach chat | `HapticFeedback.lightImpact()` |
| **Quick stats** | Default | Metric tiles in horizontal scroll | None |
| | Tapped | Navigate to detailed metric screen | `HapticFeedback.selectionClick()` |

### 2.8 Motion & Animation Guidance

| Element | Trigger | Animation | Duration | Curve |
|---------|---------|-----------|----------|-------|
| Greeting text | Screen appear | Fade in | 200ms | `easeOut` |
| Recovery circle | Data load | Ring sweep 0° → target° | 800ms | `easeOut` |
| Score number | Data load | Count up 0 → score | 800ms | `easeOut` (synced with ring) |
| Zone label | After ring completes | Fade in | 200ms | `easeOut` |
| Action card 1 | 100ms after zone | Fade in + slide up 20px | 350ms | `easeOut` |
| Action card 2 | 200ms after card 1 | Fade in + slide up 20px | 350ms | `easeOut` |
| Action card 3 | 300ms after card 2 | Fade in + slide up 20px | 350ms | `easeOut` |
| Coach hint | 400ms after card 3 | Fade in + slide up 20px | 350ms | `easeOut` |
| Pull-to-refresh | Pull gesture | Ring re-sweeps to new value | 800ms | `easeOut` |

**Reduced motion fallback**: Ring appears instantly at final value. Cards appear instantly. No count-up animation.

### 2.9 Empty / Loading / Error States

| State | Condition | Visual | Copy |
|-------|-----------|--------|------|
| **Loading** | First load, data fetching | Shimmer skeleton: circle placeholder + 3 card placeholders | None |
| **Empty (no workouts)** | User hasn't completed first workout | Ring at 0, gray track only | "Complete your first workout to see your recovery score" in `textTertiary`, `bodyMedium` |
| **Empty (no mood)** | No mood data yet | Mood card shows "—" | "Log your first mood to start tracking" |
| **Error (network)** | API failure on refresh | Last known data shown + snackbar | "Couldn't refresh — showing last known data" |
| **Error (calculation)** | Recovery algorithm fails | Ring at 0, zone hidden | "Recovery data unavailable — try again later" |
| **Offline** | No network | Last known data cached locally | Subtle "Offline" badge in app bar |

**Design rule**: Never show a blank screen. If ALL data is unavailable, show the empty state with the coach hint: "Welcome back. Let's start with a workout."

### 2.10 Accessibility Notes

| Requirement | Implementation |
|-------------|---------------|
| **Recovery circle semantics** | `Semantics(label: 'Recovery score: 78 out of 100. Maintaining zone.', value: '78')` |
| **Zone semantics** | `Semantics(label: 'Maintaining zone. Your training load is on track.')` |
| **Action cards** | Each card: `Semantics(button: true, label: 'Start Workout. Lower body power, 6 exercises.')` |
| **Coach hint** | `Semantics(label: 'Coach says: You\'ve been consistent this week. Keep it up.')` |
| **Color contrast** | Zone label text on canvas: ≥4.5:1 ✓. Score on canvas: 17.8:1 ✓ |
| **Touch targets** | Action cards: full-width, ≥56px height ✓ |
| **Dynamic type** | At >150%, recovery circle shrinks to 200px. Cards stack vertically. |
| **Screen reader** | Reads: "Today dashboard. Recovery score 78, maintaining. Button: Start Workout. Button: Log Mood. Button: Coach Chat. Coach says: [message]." |

### 2.11 Flutter Implementation Handoff

```dart
// Screen: TodayScreen
// Route: / (root of StatefulShellRoute)
// Widget: CustomScrollView with SliverList

class TodayScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final readiness = ref.watch(readinessProvider);
    final coachMessage = ref.watch(todayCoachMessageProvider);
    final userName = ref.watch(userNameProvider);
    
    return Scaffold(
      appBar: TFAppBar(
        title: 'Good morning, $userName',
        subtitle: DateFormat('EEEE, MMMM d').format(DateTime.now()),
        actions: [IconButton(icon: Icon(Icons.settings), onPressed: ...)],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(readinessProvider.future),
        child: CustomScrollView(
          slivers: [
            // Recovery circle
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: TFSpacing.s7, bottom: TFSpacing.s5),
                child: Center(
                  child: RecoveryCircle(
                    score: readiness.value?.score ?? 0,
                    zone: readiness.value?.zone,
                    isLoading: readiness.isLoading,
                    isEmpty: readiness.value?.score == null,
                  ),
                ),
              ),
            ),
            // Action cards
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: TFSpacing.s5),
                child: _ActionCards(staggerDelay: 100),
              ),
            ),
            // Coach hint
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(TFSpacing.s5, TFSpacing.s6, TFSpacing.s5, 0),
                child: CoachHintBubble(message: coachMessage.value),
              ),
            ),
            // Quick stats
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: TFSpacing.s6),
                child: QuickStatsRow(),
              ),
            ),
            // Bottom padding for nav
            SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }
}
```

**Key implementation notes:**
- Recovery circle uses `CustomPainter` with `AnimationController` (800ms)
- Ring gradient: `SweepGradient` starting from `recoveryLow` through `recoveryMid` to `recovery` (green)
- Zone colors: `Push` → `positive`, `Maintain` → `neutral`, `Deload` → `recoveryLow`
- Stagger animation: each card has increasing `delay` offset
- Pull-to-refresh triggers `ref.refresh(readinessProvider.future)`
- Coach message loads async — show shimmer until available

### 2.12 Visual Generation Prompts

#### Background Image: `hero_ai_coach.png` (optional, used as subtle bg)

| Attribute | Value |
|-----------|-------|
| **Format** | PNG, 1080×1920 |
| **Prompt** | "Abstract neural network silhouette, dark background (#0A0A0A), subtle orange (#F97316) and violet (#8B5CF6) glowing nodes connected by thin lines, extremely subtle, low opacity, used as background texture. No text, no people." |
| **Negative prompt** | "Bright, busy, text, people, faces, logos, high contrast" |
| **Mood** | Intelligent, calm, ambient |
| **App location** | Today screen background (optional, 85% dark overlay applied in code) |
| **Export notes** | <300KB. Optional — screen works without it. |

### 2.13 Safety & Proof Notes

| Rule | Status |
|------|--------|
| No medical claims | ✅ Recovery score is algorithmic, not diagnostic |
| Adherence-neutral | ✅ No red "you failed" indicators. Deload zone uses orange, not red. |
| AI narration boundary | ✅ Coach hint is LLM-generated but filtered through gate-safe. Deterministic code decides the zone; AI only narrates. |
| Privacy | ✅ Recovery data stays on-device unless user opts into sync |
| Data accuracy | ⚠️ Recovery score depends on wearable data quality. Handle missing HRV/sleep gracefully. |

### 2.14 Acceptance Criteria

- [ ] Recovery circle renders at 280px diameter with 8px stroke
- [ ] Ring animates 0→score over 800ms on screen load
- [ ] Zone label appears after ring animation completes
- [ ] 3 action cards are visible without scrolling on iPhone SE
- [ ] Tapping "Start Workout" navigates to active workout logger
- [ ] Tapping "Log Mood" opens mood check-in bottom sheet
- [ ] Tapping "Coach Chat" navigates to coach chat screen
- [ ] Coach hint shows personalized message (or fallback if AI unavailable)
- [ ] Pull-to-refresh re-calculates and re-animates recovery score
- [ ] Empty state (no workouts) shows instructional message
- [ ] Loading state shows shimmer skeleton
- [ ] All text passes WCAG AA contrast
- [ ] Screen reader announces score, zone, and all action buttons
- [ ] Reduced motion: ring appears instantly at final value, no stagger

---

## SCREEN 3: ACTIVE WORKOUT LOGGER

### 3.1 Product Objective

Enable the user to log a complete workout set in ≤2 taps (adjust weight/reps → tap "Log Set"). This is the highest-frequency, highest-stakes screen in the app. If logging is slow, users abandon the app mid-workout. Speed and clarity are non-negotiable.

### 3.2 User Job-to-Be-Done

> "I just finished a set. I need to log my weight and reps in 2 seconds, then rest. Don't make me think about anything except the next set."

The user is in "gym flow" mode — sweaty hands, distracted, possibly wearing gloves, phone on a bench or rack. Every tap must be large, forgiving, and fast. Cognitive load must be near zero.

### 3.3 Screen Role in the App

- **Position**: Modal/pushed screen from Today or Train tab. NOT in bottom nav.
- **Flow**: Today → Start Workout → Active Logger → Debrief (post-workout)
- **Exit paths**: "Finish Workout" (completes), back arrow (abandon confirmation), swipe-to-dismiss (blocked during active set)
- **Navigation**: No bottom nav. Custom top bar with exercise name + workout timer.

### 3.4 User State & Emotional State

| Dimension | State |
|-----------|-------|
| **Cognitive load** | Minimal — the app should think for them |
| **Emotional state** | Focused, effortful, possibly fatigued |
| **Trust level** | High — they're mid-workout, committed |
| **Time budget** | 2-5 seconds per set log |
| **Physical context** | Gym, sweaty hands, phone on bench, one-hand operation preferred |

**Design implication**: Touch targets are 48px minimum (not 44px). Weight/reps controls must be operable with one thumb. The "Log Set" button must be impossible to miss.

### 3.5 Information Hierarchy

```
PRIORITY 1 (0-1s):  Exercise name + set progress (where am I?)
PRIORITY 2 (1-2s):  Previous performance (what did I do last time?)
PRIORITY 3 (2-3s):  Weight and reps controls (what am I logging?)
PRIORITY 4 (3-5s):  "Log Set" button (confirm and advance)
PRIORITY 5 (5s+):   Rest timer (auto-starts after log)
PRIORITY 6 (5s+):   Coach message (slides up after each set)
```

**Visual scan path**: Top (exercise name) → center (controls) → bottom (log button). One vertical line, no lateral movement.

### 3.6 Component List

| Component | Spec | Token Reference |
|-----------|------|-----------------|
| `WorkoutAppBar` | [✕ close] + exercise name + workout timer (MM:SS:SS) | Custom AppBar |
| `ProgressDots` | Row of dots: filled (`accent`) = completed, empty (`surfaceBorder`) = remaining | Custom Row |
| `SetTable` | Strong-style: SET | PREVIOUS | WEIGHT | REPS | ✓ | Custom Table |
| `SetRow_Active` | Current set: accent left border, `surfaceElevated` bg | §7.1 TFSurfaceCard |
| `SetRow_Completed` | Faded: `surface` bg, green checkmark, muted text | §7.1 TFSurfaceCard |
| `SetRow_Upcoming` | Placeholder: `surface` bg, dashed numbers in `textTertiary` | §7.1 TFSurfaceCard |
| `NumberStepper_Weight` | Large number (Inter 32px w700) + [-] [+] buttons (48px targets) | §7.3 TFNumberInput |
| `NumberStepper_Reps` | Large number (Inter 32px w700) + [-] [+] buttons (48px targets) | §7.3 TFNumberInput |
| `LogSetButton` | Full-width accent, 56px height, text: "LOG SET — 82.5kg × 5 reps" | §7.2 Primary Button |
| `RestTimer` | Breathing badge: circle that pulses (1s cycle), countdown in JetBrains Mono 48px | §11.3 Rest timer |
| `CoachMessage` | Slide-up card: Playfair 15px, `electric` left border | §7.6 TFCoachBubble |
| `PRBadge` | Gold card: "NEW PR!" + confetti + previous vs new comparison | Custom |

### 3.7 Interaction States

| Element | State | Visual | Haptic | Duration |
|---------|-------|--------|--------|----------|
| **Weight [-]** | Tapped | Scale 0.95, number decrements | `HapticFeedback.lightImpact()` | 100ms |
| **Weight [+]** | Tapped | Scale 0.95, number increments | `HapticFeedback.lightImpact()` | 100ms |
| **Reps [-]** | Tapped | Scale 0.95, number decrements | `HapticFeedback.lightImpact()` | 100ms |
| **Reps [+]** | Tapped | Scale 0.95, number increments | `HapticFeedback.lightImpact()` | 100ms |
| **Number change** | Value update | Spring scale 1.0→1.05→1.0 | None | 200ms |
| **Log Set** | Tapped | Scale 0.97, then full-width success flash | `HapticFeedback.mediumImpact()` | 100ms press, 200ms flash |
| **Set row (new)** | After log | Slide in from right + green flash | None | 300ms slide, 200ms flash |
| **Rest timer** | Auto-start after log | Expands from header, circle pulses | None | 300ms expand |
| **Coach message** | After log | Slide up from bottom | `HapticFeedback.lightImpact()` | 350ms |
| **PR detected** | After log | Confetti + badge slide-down + screen flash | `HapticFeedback.heavyImpact()` | 1200ms |
| **Exercise nav** | ← → tapped | Slide transition between exercises | `HapticFeedback.selectionClick()` | 200ms |

### 3.8 Motion & Animation Guidance

| Element | Trigger | Animation | Duration | Curve |
|---------|---------|-----------|----------|-------|
| Exercise name | Screen appear | Fade in | 200ms | `easeOut` |
| Progress dots | Screen appear | Stagger fade (50ms each) | 200ms + stagger | `easeOut` |
| Set table rows | Screen appear | Stagger slide from right (100ms each) | 300ms + stagger | `easeOut` |
| Weight/Reps number | Value change | Scale spring 1.0→1.05→1.0 | 200ms | `Curves.easeOutBack` |
| Log Set button | Tap | Scale 0.97 → 1.0 | 100ms | `easeIn` |
| Set row (logged) | After log | Slide in from right (translateX: 50px→0) | 300ms | `easeOut` |
| Green flash | After log | Background flash positive → surface | 200ms | `easeOut` |
| Rest timer | Auto-start | Expand from 0 to full size | 300ms | `easeOut` |
| Timer circle | During rest | Breathing pulse (scale 1.0→1.05→1.0) | 1000ms | `easeInOut` (loop) |
| Coach message | After log | Slide up from bottom (translateY: 100px→0) + fade | 350ms | `easeOut` |
| PR confetti | PR detected | Particles explode from center | 1300ms | `spring` |
| PR badge | PR detected | Scale 0→1 + glow pulse | 600ms | `Curves.elasticOut` |
| PR comparison | After badge | Fade in: "95kg → 100kg (+5.3%)" | 400ms | `easeOut` |

**Reduced motion fallback**: No confetti, no particle effects. PR celebration shows a gold-bordered card that appears instantly. Rest timer circle is static. All other animations disabled.

### 3.9 Empty / Loading / Error States

| State | Condition | Visual | Copy |
|-------|-----------|--------|------|
| **Loading** | Workout data fetching | Skeleton: shimmer exercise name + shimmer rows | None |
| **Empty (no sets logged)** | First exercise, no sets yet | Table shows dashed placeholders | "Start your first set" in `textTertiary` below controls |
| **Previous = "—" ** | No history for this exercise | PREVIOUS column shows "—" in `textTertiary` | N/A |
| **Network error** | API failure during log | Set saved locally + snackbar | "Network error — sets saved locally" in `caution` snackbar |
| **Sync conflict** | Local data differs from server | Merge dialog on next sync | "Your local changes will be merged" |
| **Abandon workout** | Back button / swipe | Confirmation dialog | "Finish this workout?" with [Continue] [Save & Exit] [Discard] |
| **Pain safety mode** | User reports pain (from coach) | Red border on affected exercise, weight ceiling applied | "Reduced load — protecting [body part]" in `caution` |

**Design rule**: Sets are ALWAYS saved locally first (Drift/SQLite). Network sync is background. The user should never lose data.

### 3.10 Accessibility Notes

| Requirement | Implementation |
|-------------|---------------|
| **Exercise name** | `Semantics(header: true, label: 'Barbell Back Squat. Set 2 of 4.')` |
| **Set table** | `Semantics(label: 'Set log table. Set 1: 80kg, 5 reps, completed. Set 2: current set.')` |
| **Weight stepper** | `Semantics(label: 'Weight: 82.5 kilograms. Minus button. Plus button.')` |
| **Reps stepper** | `Semantics(label: 'Reps: 5. Minus button. Plus button.')` |
| **Log Set button** | `Semantics(button: true, label: 'Log set. 82.5 kilograms, 5 reps.')` |
| **Rest timer** | `Semantics(label: 'Rest timer. 1 minute 30 seconds remaining.', live: true)` |
| **Coach message** | `Semantics(label: 'Coach says: Good set. RPE 7. Keep the weight here.')` |
| **PR celebration** | `Semantics(label: 'New personal record! Squat: 100 kilograms. Previous best: 95 kilograms.')` + `HapticFeedback.heavyImpact()` |
| **Touch targets** | All steppers: 48×48dp ✓. Log button: 56px height ✓. Close button: 44×44dp ✓ |
| **Dynamic type** | At >150%, set table switches to card layout (each set as a card instead of table row) |

### 3.11 Flutter Implementation Handoff

```dart
// Screen: ActiveWorkoutScreen
// Route: /workout (pushed from Today or Train)
// Widget: Scaffold with custom body

class ActiveWorkoutScreen extends ConsumerStatefulWidget {
  final String workoutId;
  
  @override
  ConsumerState<ActiveWorkoutScreen> createState() => _ActiveWorkoutState();
}

class _ActiveWorkoutState extends ConsumerState<ActiveWorkoutScreen> {
  late WorkoutTimerController _timerController;
  
  @override
  Widget build(BuildContext context) {
    final workout = ref.watch(activeWorkoutProvider(widget.workoutId));
    final currentExercise = ref.watch(currentExerciseProvider);
    final restTimer = ref.watch(restTimerProvider);
    
    return PopScope(
      canPop: false, // Block back during active set
      onPopInvoked: (_) => _showAbandonDialog(context),
      child: Scaffold(
        backgroundColor: TFColors.canvas,
        body: SafeArea(
          child: Column(
            children: [
              // Top bar: close + exercise name + timer
              _WorkoutAppBar(
                onClose: () => _showAbandonDialog(context),
                exerciseName: currentExercise.name,
                timer: _timerController.displayTime,
              ),
              // Progress dots
              ProgressDots(
                total: currentExercise.targetSets,
                completed: currentExercise.completedSets,
              ),
              // Set table (scrollable)
              Expanded(
                child: SetTable(
                  sets: currentExercise.sets,
                  currentSetIndex: currentExercise.currentSetIndex,
                ),
              ),
              // Weight/Reps steppers
              _StepperControls(
                weight: currentExercise.currentWeight,
                reps: currentExercise.currentReps,
                onWeightChange: (v) => ref.read(currentExerciseProvider.notifier).setWeight(v),
                onRepsChange: (v) => ref.read(currentExerciseProvider.notifier).setReps(v),
              ),
              // Log Set button
              Padding(
                padding: const EdgeInsets.all(TFSpacing.s5),
                child: _LogSetButton(
                  weight: currentExercise.currentWeight,
                  reps: currentExercise.currentReps,
                  onPressed: () => _logSet(context, ref),
                ),
              ),
              // Rest timer (conditional)
              if (restTimer.isActive)
                _RestTimerBadge(controller: restTimer),
              // Coach message (conditional)
              if (currentExercise.lastCoachMessage != null)
                _CoachMessageSlideUp(message: currentExercise.lastCoachMessage!),
            ],
          ),
        ),
      ),
    );
  }
  
  Future<void> _logSet(BuildContext context, WidgetRef ref) async {
    HapticFeedback.mediumImpact();
    
    // Save locally first (Drift)
    await ref.read(workoutLogProvider.notifier).logSet(
      exerciseId: currentExercise.id,
      weight: currentExercise.currentWeight,
      reps: currentExercise.currentReps,
    );
    
    // Check for PR
    if (isNewPR) {
      _showPRCelebration(context);
    }
    
    // Start rest timer
    ref.read(restTimerProvider.notifier).start(duration: currentExercise.restDuration);
    
    // Queue coach message (async, AI-generated)
    ref.read(coachMessageQueueProvider.notifier).queuePostSetMessage();
    
    // Background sync to Supabase
    ref.read(syncProvider.notifier).syncWorkoutLog();
  }
}
```

**Key implementation notes:**
- `PopScope(canPop: false)` prevents accidental back during workout
- Sets saved to Drift (local SQLite) FIRST, synced to Supabase in background
- Weight stepper: increment by 2.5kg (configurable per exercise)
- Reps stepper: increment by 1
- Number animation: `TweenAnimationBuilder<double>` with `Curves.easeOutBack`
- Rest timer: `AnimationController` with `repeat(reverse: true)` for breathing effect
- PR detection: compare logged set against `personalRecordsProvider`
- Confetti: use `confetti_widget` package or custom `CustomPainter`
- `HapticFeedback` calls at every interaction point

### 3.12 Visual Generation Prompts

No hero images needed for this screen — it's a pure data/interaction screen. The visual richness comes from motion, haptics, and the PR celebration.

#### PR Confetti Particles

| Attribute | Value |
|-----------|-------|
| **Format** | Programmatic (CustomPainter or confetti_widget) |
| **Colors** | `accent` (#F97316), `personalRecord` (#FBBF24/gold), `mint` (#10B981) |
| **Behavior** | 50-80 particles, explode from center of Log Set button, gravity-affected, 1300ms duration |
| **Shapes** | Mix of circles (60%) and rectangles (40%) |
| **Accessibility** | Disabled when `MediaQuery.disableAnimations` is true |

### 3.13 Safety & Proof Notes

| Rule | Status |
|------|--------|
| Data integrity | ✅ Sets saved locally first. Never lost due to network issues. |
| Pain safety mode | ✅ If coach detects pain signals, weight ceiling is applied deterministically (not by AI) |
| No medical claims | ✅ Coach messages like "RPE 7, keep the weight here" are coaching, not medical advice |
| One-hand operation | ✅ All critical actions (steppers, log button) reachable with right thumb |
| Gym environment | ✅ High contrast, large text, large touch targets for low-visibility conditions |
| Timer accuracy | ✅ Rest timer uses `Stopwatch` (monotonic clock), not `DateTime.now()` |
| Offline-first | ✅ Full workout logging works without network. Sync on reconnect. |

### 3.14 Acceptance Criteria

- [ ] Exercise name and progress dots visible at top
- [ ] Set table shows all sets with previous data, current set highlighted
- [ ] Weight stepper: 48px touch targets, increments by 2.5kg
- [ ] Reps stepper: 48px touch targets, increments by 1
- [ ] Number animation on value change (200ms spring)
- [ ] "Log Set" button: 56px height, full-width, accent color
- [ ] After log: set row slides in from right (300ms), green flash (200ms)
- [ ] Rest timer auto-starts after log, breathing circle pulses
- [ ] Coach message slides up after each set (350ms)
- [ ] PR detection: confetti + haptic + badge + comparison
- [ ] All data saved locally first (Drift/SQLite)
- [ ] Network error shows "saved locally" snackbar, no data loss
- [ ] Back button shows abandon confirmation dialog
- [ ] Screen reader announces set numbers, weights, reps, and completion status
- [ ] Reduced motion: no confetti, no particle effects, instant state transitions
- [ ] Works one-handed with right thumb on iPhone SE

---

## SCREEN 4: COACH CHAT

### 4.1 Product Objective

Create the emotional core of TransformFit: a conversational relationship between the user and their AI coach. The chat must feel like texting a real person — not interacting with a chatbot. This screen is where trust is built, maintained, and deepened over weeks and months.

### 4.2 User Job-to-Be-Done

> "I want to talk to my coach like I'd text a real trainer. Ask a question, get a straight answer, feel understood."

The user is in "relationship" mode — they want to feel heard, get advice, and move on. They don't want to see confidence scores, source citations, or AI disclaimers. They want a human-like exchange with a knowledgeable coach.

### 4.3 Screen Role in the App

- **Position**: Tab 3 of 5 (Coach). Also accessible from Today dashboard and post-workout.
- **Flow**: Coach Chat → (internal) Quick actions trigger workout/nutrition/recovery screens
- **Persistence**: Full conversation history persisted. Scroll position maintained.
- **Navigation**: Top bar: "Coach" + settings. Bottom nav visible.

### 4.4 User State & Emotional State

| Dimension | State |
|-----------|-------|
| **Cognitive load** | Low-moderate — conversational, not analytical |
| **Emotional state** | Variable — could be seeking motivation, asking a question, venting, or celebrating |
| **Trust level** | High — ongoing relationship |
| **Time budget** | 30 seconds to 5 minutes per session |
| **Physical context** | Post-workout, evening, or between activities |

**Design implication**: The chat must feel warm, personal, and responsive. Typing indicator is critical — it creates the illusion of a human on the other end. Messages must be easy to read with clear visual distinction between coach and user.

### 4.5 Information Hierarchy

```
PRIORITY 1 (0-1s):  Latest coach message (left-aligned, Playfair, surface bg)
PRIORITY 2 (1-2s):  Quick action chips (if contextual: "How am I doing?", "What's next?")
PRIORITY 3 (2-3s):  Input field (pill shape, always visible at bottom)
PRIORITY 4 (3s+):   Message history (scrollable, newest at bottom)
```

**Visual scan path**: Bottom-up. Latest message → input field → (if needed) scroll up for history.

### 4.6 Component List

| Component | Spec | Token Reference |
|-----------|------|-----------------|
| `CoachAppBar` | "Coach" title + persona indicator dot + settings icon | §7.4 Top App Bar |
| `CoachBubble` | Left-aligned, `surface` bg (#141414), 16px radius, Playfair 17px w400, max-width 80% | §7.6 TFCoachBubble variant |
| `UserBubble` | Right-aligned, `accent` bg (#F97316), 16px radius, Inter 17px w400, `textInverse` text, max-width 80% | Custom |
| `TimestampLabel` | 13px, `textTertiary`, below each message, center-aligned for coach, right-aligned for user | §4.2 labelSmall |
| `TypingIndicator` | 3 dots, persona color, bounce animation (800ms cycle) | Custom |
| `QuickActionChips` | Horizontal scroll of `TFPillButton`: "How am I doing?", "What's next?", "Adjust my plan" | §7.2 Pill Button |
| `ChatInput` | Pill shape, `surfaceInput` (#1C1C1C) bg, Inter 15px, send button with `accent` | §7.3 TFTextField variant |
| `MessageListView` | `ListView.builder` with reverse: true, auto-scroll to bottom on new message | Flutter standard |
| `ShimmerTyping` | 3-dot bounce while AI is generating | Custom |

### 4.7 Interaction States

| Element | State | Visual | Haptic |
|---------|-------|--------|--------|
| **Coach bubble** | Default | Surface bg, Playfair text | None |
| | Long-press | Copy to clipboard + snackbar "Copied" | `HapticFeedback.lightImpact()` |
| **User bubble** | Default | Accent bg, white text | None |
| | Long-press | Copy to clipboard | `HapticFeedback.lightImpact()` |
| **Quick action chip** | Default | Surface bg, `textSecondary` text | None |
| | Tapped | Scale 0.97, sends chip text as message | `HapticFeedback.lightImpact()` |
| | Selected (sent) | Accent bg, white text, disappears after send | None |
| **Chat input** | Empty | Pill, placeholder "Ask your coach anything" | None |
| | Focused | Accent border (1px) | None |
| | With text | Send button appears (accent circle) | None |
| **Send button** | Default | Accent circle, white arrow | None |
| | Tapped | Scale 0.9, message sends | `HapticFeedback.lightImpact()` |
| | Disabled (empty) | 40% opacity, no tap response | None |
| **Typing indicator** | Active | 3 dots bounce in sequence | None |
| | After 5s timeout | Fallback: "Coach is thinking..." | None |
| | After 15s timeout | Error: "Coach is taking longer than usual" | None |

### 4.8 Motion & Animation Guidance

| Element | Trigger | Animation | Duration | Curve |
|---------|---------|-----------|----------|-------|
| New message (coach) | Message received | Slide up from bottom + fade in | 300ms | `easeOut` |
| New message (user) | Message sent | Slide up from bottom + fade in | 300ms | `easeOut` |
| Typing indicator | AI generating | 3 dots bounce in sequence (translateY: 0→-6px→0) | 800ms | `easeInOut` (loop) |
| Quick action chips | Screen appear | Stagger fade from left (100ms each) | 200ms + stagger | `easeOut` |
| Input focus | Tap input | Border color transitions to accent | 200ms | `easeInOut` |
| Send button | Text entered | Scale 0→1 + fade in | 200ms | `easeOut` |
| Message list scroll | New message | Auto-scroll to bottom | 300ms | `easeOut` |
| Persona color dot | Persona change | Color crossfade | 400ms | `easeInOut` |

**Reduced motion fallback**: Messages appear instantly. Typing indicator is static (text: "Coach is typing..."). No bounce animation.

### 4.9 Empty / Loading / Error States

| State | Condition | Visual | Copy |
|-------|-----------|--------|------|
| **Empty (first visit)** | No messages yet | Centered coach avatar + greeting | "Ask your coach anything" in `textSecondary`, `bodyLarge` |
| **Loading (AI generating)** | Waiting for response | Typing indicator (3 bouncing dots) | None |
| **Timeout (5s)** | AI slow to respond | Typing indicator continues + subtle text | "Coach is thinking..." in `textTertiary` |
| **Error (AI offline)** | LLM API unavailable | Last message shown + error card | "Coach is offline — try again later" in `caution` snackbar |
| **Error (rate limit)** | Too many messages | Input disabled temporarily | "Slow down — your coach needs a moment" in `textTertiary` |
| **Network error** | No connectivity | Messages queue locally | "Messages will send when you're back online" in `textTertiary` |
| **Unsafe request** | User asks for medical advice | Coach redirects | "I can't give medical advice, but here's what the evidence says about training with [condition]." |

**Design rule**: The chat NEVER shows confidence scores, source counts, or "AI-generated" disclaimers in the message bubbles. These break the coaching illusion. Safety filtering happens silently in the background.

### 4.10 Accessibility Notes

| Requirement | Implementation |
|-------------|---------------|
| **Coach message** | `Semantics(label: 'Coach says: ${message}. ${timestamp}')` |
| **User message** | `Semantics(label: 'You said: ${message}. ${timestamp}')` |
| **Typing indicator** | `Semantics(label: 'Coach is typing', live: true)` |
| **Quick action chips** | Each chip: `Semantics(button: true, label: 'Quick action: ${chipText}')` |
| **Input field** | `Semantics(textField: true, label: 'Type a message to your coach')` |
| **Send button** | `Semantics(button: true, label: 'Send message')` |
| **Color contrast** | User bubble: `textInverse` (#0A0A0A) on `accent` (#F97316) = 4.8:1 ✓ |
| | Coach bubble: `textPrimary` (#F0EDE8) on `surface` (#141414) = 15.2:1 ✓ |
| **Touch targets** | Send button: 44×44dp ✓. Chips: 44px height ✓ |
| **Dynamic type** | Bubbles expand vertically. Max-width stays at 80%. Input field height adjusts. |
| **Screen reader** | Announces new messages automatically via `Semantics(live: true)` on the message list |

### 4.11 Flutter Implementation Handoff

```dart
// Screen: CoachChatScreen
// Route: /coach (Tab 3) or /coach-chat (pushed)
// Widget: Column with Expanded ListView + input bar

class CoachChatScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<CoachChatScreen> createState() => _CoachChatState();
}

class _CoachChatState extends ConsumerState<CoachChatScreen> {
  final _scrollController = ScrollController();
  final _inputController = TextEditingController();
  
  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(coachMessagesProvider);
    final isTyping = ref.watch(coachTypingProvider);
    final persona = ref.watch(coachPersonaProvider);
    
    return Scaffold(
      appBar: TFAppBar(
        title: 'Coach',
        leading: _PersonaDot(color: persona.color),
        actions: [IconButton(icon: Icon(Icons.settings), onPressed: ...)],
      ),
      body: Column(
        children: [
          // Message list
          Expanded(
            child: messages.isEmpty
                ? _EmptyState() // "Ask your coach anything"
                : ListView.builder(
                    controller: _scrollController,
                    reverse: true, // Newest at bottom
                    padding: const EdgeInsets.symmetric(
                      horizontal: TFSpacing.s4,
                      vertical: TFSpacing.s3,
                    ),
                    itemCount: messages.length + (isTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (isTyping && index == 0) {
                        return _TypingIndicator(color: persona.color);
                      }
                      final msg = messages[messages.length - 1 - (isTyping ? index : index - (isTyping ? 1 : 0))];
                      return msg.isCoach
                          ? _CoachBubble(message: msg)
                          : _UserBubble(message: msg);
                    },
                  ),
          ),
          // Quick action chips (conditional)
          if (messages.isNotEmpty && _shouldShowChips(messages))
            _QuickActionChips(
              chips: ['How am I doing?', 'What\'s next?', 'Adjust my plan'],
              onTap: (chip) => _sendChipMessage(chip),
            ),
          // Input bar
          _ChatInputBar(
            controller: _inputController,
            onSend: () => _sendMessage(),
          ),
        ],
      ),
    );
  }
  
  void _sendMessage() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    
    HapticFeedback.lightImpact();
    ref.read(coachMessagesProvider.notifier).sendUserMessage(text);
    _inputController.clear();
    
    // Trigger AI response
    ref.read(coachTypingProvider.notifier).setTyping(true);
    ref.read(coachStreamProvider.notifier).stream(text);
    
    // Auto-scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        0, // reverse: true, so 0 is the bottom
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }
}

// Coach bubble
class _CoachBubble extends StatelessWidget {
  final ChatMessage message;
  
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.80),
        padding: const EdgeInsets.all(TFSpacing.s4),
        decoration: BoxDecoration(
          color: TFColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message.text, style: TFType.bodyMedium.copyWith(fontFamily: 'Playfair')),
            const SizedBox(height: TFSpacing.s1),
            Text(message.timestamp, style: TFType.labelSmall),
          ],
        ),
      ),
    );
  }
}

// User bubble
class _UserBubble extends StatelessWidget {
  final ChatMessage message;
  
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.80),
        padding: const EdgeInsets.all(TFSpacing.s4),
        decoration: BoxDecoration(
          color: TFColors.accent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(message.text, style: TFType.bodyMedium.copyWith(color: TFColors.textInverse)),
            const SizedBox(height: TFSpacing.s1),
            Text(message.timestamp, style: TFType.labelSmall.copyWith(color: TFColors.textInverse.withOpacity(0.6))),
          ],
        ),
      ),
    );
  }
}
```

**Key implementation notes:**
- `ListView.builder(reverse: true)` — newest messages at bottom, natural scroll
- Typing indicator uses `AnimationController` with `repeat` for dot bounce sequence
- AI response streamed via SSE from Supabase Edge Function (`coach-stream`)
- Gate-safe filter applied to ALL AI outputs before rendering
- Messages persisted to Drift (local) + Supabase (remote)
- Quick action chips: horizontal `SingleChildScrollView` with `Row` of `TFPillButton`
- Input bar: `Container` with `TextField` + send `IconButton`, fixed at bottom
- Persona color changes the typing indicator dot color and app bar accent

### 4.12 Visual Generation Prompts

#### Coach Avatar (optional)

| Attribute | Value |
|-----------|-------|
| **Format** | PNG, 128×128 |
| **Prompt** | "Minimalist abstract avatar, circular, gradient from orange (#F97316) to violet (#8B5CF6), subtle neural network pattern inside, no face, no text. Dark background." |
| **Negative prompt** | "Face, person, realistic, text, logo, complex details" |
| **Mood** | Intelligent, warm, trustworthy |
| **App location** | Coach chat header (optional), empty state |
| **Export notes** | <50KB. Simple gradient circle works as fallback. |

### 4.13 Safety & Proof Notes

| Rule | Status |
|------|--------|
| No medical advice | ✅ Gate-safe filter blocks: diagnosis, treatment, medication, injury recovery claims |
| No injury advice | ✅ If user reports pain: "I'd recommend checking with a healthcare provider. In the meantime, I can adjust your workout to avoid [body part]." |
| AI boundary | ✅ Coach never claims to be human. But doesn't announce "I'm an AI" unprompted either. |
| Deterministic vs AI | ✅ Workout numbers (weights, reps, progression) come from deterministic engine. AI narrates around them. |
| Content filtering | ✅ All AI outputs pass through gate-safe before rendering. Blocked messages show fallback: "I can't help with that, but I'm here for your training questions." |
| Privacy | ✅ Chat history stored locally. Synced to Supabase only if user opts in. |

### 4.14 Acceptance Criteria

- [ ] Messages display as clean bubbles (no cards, no borders)
- [ ] Coach bubbles: left-aligned, surface bg, 16px radius, Playfair font
- [ ] User bubbles: right-aligned, accent bg, 16px radius, Inter font, white text
- [ ] Timestamps: 13px, textTertiary, below each message
- [ ] Typing indicator: 3 dots with persona color, 800ms bounce cycle
- [ ] Quick action chips: horizontal scroll above input
- [ ] Input: pill shape, surfaceInput bg, send button with accent
- [ ] New messages slide up from bottom (300ms)
- [ ] Empty state: "Ask your coach anything"
- [ ] Error state: "Coach is offline — try again later"
- [ ] Long-press on any message copies to clipboard
- [ ] All text passes WCAG AA contrast
- [ ] Screen reader announces messages in order with speaker attribution
- [ ] Reduced motion: no slide animations, typing indicator is static text
- [ ] Messages persist across app restarts

---

## SCREEN 5: PROGRESS DASHBOARD

### 5.1 Product Objective

Show the user their long-term progress across strength, volume, recovery, and personal records. This screen answers: "Is what I'm doing actually working?" It must be motivating without being punitive — progress is celebration, never punishment.

### 5.2 User Job-to-Be-Done

> "I want to see if I'm getting stronger, fitter, and healthier over time. Show me the trends, not just today's numbers."

The user is in "reflection" mode — they're stepping back from day-to-day logging to see the bigger picture. They want to feel proud of their progress and understand what's working.

### 5.3 Screen Role in the App

- **Position**: Tab 4 of 5 (Track / Progress).
- **Flow**: Progress → (tabs) Strength | Volume | Recovery | PRs
- **Drill-down**: Tap any chart → detailed view with data table
- **Navigation**: Top bar: "Progress" + date range selector. Bottom nav visible.

### 5.4 User State & Emotional State

| Dimension | State |
|-----------|-------|
| **Cognitive load** | Moderate — reviewing data, making comparisons |
| **Emotional state** | Reflective, seeking validation, possibly anxious about plateaus |
| **Trust level** | High — established user with workout history |
| **Time budget** | 1-5 minutes (deeper engagement than Today) |
| **Physical context** | Evening, rest day, or post-workout review |

**Design implication**: Charts must be legible at a glance. Trends must be explained (not just shown). Plateaus must be framed neutrally — "consistent" not "stalled."

### 5.5 Information Hierarchy

```
PRIORITY 1 (0-1s):  Tab bar — Strength | Volume | Recovery | PRs (which view am I in?)
PRIORITY 2 (1-3s):  Hero chart — the primary trend line with current value
PRIORITY 3 (3-5s):  Summary stats — current value, delta, PR
PRIORITY 4 (5-8s):  Heatmap — 52-week workout consistency grid
PRIORITY 5 (8s+):   PR board — recent personal records as gold cards
```

**Visual scan path**: Top (tabs) → center (chart) → below chart (stats) → scroll (heatmap, PRs).

### 5.6 Component List

| Component | Spec | Token Reference |
|-----------|------|-----------------|
| `TFTabBar` | 4 tabs: Strength, Volume, Recovery, PRs. Active: `textPrimary` + 2px `accent` underline | §7.4 Tab Bar |
| `LineChart` | `fl_chart` LineChart, smooth curves, orange gradient fill below line, touch-to-inspect | §10.1-10.2 Chart specs |
| `ChartTooltip` | Vertical line + value tooltip on touch | Custom |
| `SummaryStats` | Row: Current value + delta (▲/▼) + PR value | §7.5 TFMetricTile |
| `HeatmapGrid` | GitHub-style 52-week grid, intensity from `surface` to `positive` | Custom Painter |
| `PRCard` | Gold-bordered card: exercise name + weight + date + comparison | §7.1 TFGlowingCard variant |
| `DateRangeSelector` | Chips: 1M | 3M | 6M | 1Y | All | §7.2 Pill Button |
| `EmptyState` | Centered illustration + "Complete more workouts to see your progress" | Custom |

### 5.7 Interaction States

| Element | State | Visual | Haptic |
|---------|-------|--------|--------|
| **Tab** | Active | `textPrimary` + 2px `accent` underline | `HapticFeedback.selectionClick()` |
| | Inactive | `textSecondary`, no underline | None |
| | Tapping | Crossfade between tab content | `HapticFeedback.selectionClick()` |
| **Chart** | Default | Animated line + gradient fill | None |
| | Touch inspect | Vertical line + tooltip with value + date | `HapticFeedback.selectionClick()` |
| | Drag | Tooltip follows finger | `HapticFeedback.selectionClick()` per data point |
| **Date range chip** | Selected | Accent bg, white text | `HapticFeedback.lightImpact()` |
| | Unselected | Surface bg, secondary text | None |
| **Heatmap cell** | Tapped | Tooltip: "Week of [date]: [X] workouts" | `HapticFeedback.lightImpact()` |
| **PR card** | Tapped | Expand to full PR detail view | `HapticFeedback.lightImpact()` |
| **Chart (empty)** | No data | Dotted line at target + "No data yet" | None |

### 5.8 Motion & Animation Guidance

| Element | Trigger | Animation | Duration | Curve |
|---------|---------|-----------|----------|-------|
| Tab content | Tab switch | Fade + horizontal slide (direction matches tab position) | 200ms | `easeInOut` |
| Line chart | First appear | Line draws from left to right | 600ms | `easeOut` |
| Gradient fill | After line draws | Fill fades in below line | 400ms | `easeOut` (starts at 200ms into line draw) |
| Chart tooltip | Touch | Fade in + scale 0.9→1.0 | 150ms | `easeOut` |
| Summary stats | Tab appear | Fade in + slide up 10px | 300ms | `easeOut` |
| Heatmap | First appear | Grid fills from top-left to bottom-right (staggered) | 800ms total | `easeOut` |
| PR cards | Tab appear | Stagger slide from bottom (150ms each) | 350ms + stagger | `easeOut` |
| Date range change | Chip tap | Chart crossfades to new data | 300ms | `easeInOut` |

**Reduced motion fallback**: Charts appear instantly at final state. No draw animation. Heatmap appears fully populated. PR cards appear instantly.

### 5.9 Empty / Loading / Error States

| State | Condition | Visual | Copy |
|-------|-----------|--------|------|
| **Loading** | Data fetching | Shimmer: chart area + stats placeholder | None |
| **Empty (no workouts)** | User has no workout history | Chart area: dotted line at target + centered message | "Complete more workouts to see your progress" in `textSecondary` |
| **Empty (few workouts)** | <5 data points | Chart renders with limited points + dashed trend line | "More data will make your trends clearer" in `textTertiary` |
| **Error (data load)** | API failure | Last known data shown + snackbar | "Couldn't load latest data — showing cached" |
| **No PRs yet** | PRs tab, no records | Empty gold card area | "Log your first PR to see it here" in `textSecondary` |
| **Plateau detected** | Flat trend (0% change over 30d) | Normal chart + neutral coach message | "Consistent progress — your body is adapting" (not "stalled") |

**Design rule**: NEVER use red or negative language for plateaus. "Consistent" is the default framing. If the trend is genuinely declining, use `textSecondary` (muted) — never `critical` (red).

### 5.10 Accessibility Notes

| Requirement | Implementation |
|-------------|---------------|
| **Chart semantics** | `Semantics(label: 'Squat 1RM trend chart. Current: 100kg. Trend: increasing over 3 months.')` |
| **Chart data points** | Each visible point: `Semantics(label: 'March 15: 95kg')` (on touch inspect) |
| **Tab bar** | Each tab: `Semantics(button: true, label: 'Strength tab', selected: true/false)` |
| **Heatmap** | `Semantics(label: '52-week workout heatmap. Current streak: 12 weeks.')` |
| **PR card** | `Semantics(label: 'Personal record. Squat: 100kg. Set on March 15. Previous: 95kg.')` |
| **Color contrast** | Chart line: `accent` (#F97316) on `surface` (#141414) = 4.8:1 ✓ |
| | Gradient fill: from `accent` at 20% opacity to transparent — decorative only, data is in the line |
| **Touch targets** | Tabs: 48px height ✓. Date chips: 44px height ✓. PR cards: full-width ✓ |
| **Dynamic type** | Chart labels scale down at >150% to avoid overlap. Stats reflow to vertical stack. |
| **Screen reader** | "Progress dashboard. Tab: Strength selected. Squat 1RM chart. Current value: 100 kilograms. Trend: increased 5 kilograms this month. Personal record: 105 kilograms on March 15." |

### 5.11 Flutter Implementation Handoff

```dart
// Screen: ProgressScreen
// Route: /progress (Tab 4) or /track
// Widget: NestedScrollView with TabBarView

class ProgressScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<ProgressScreen> createState() => _ProgressState();
}

class _ProgressState extends ConsumerState<ProgressScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TFAppBar(
        title: 'Progress',
        bottom: TFTabBar(
          controller: _tabController,
          tabs: ['Strength', 'Volume', 'Recovery', 'PRs'],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _StrengthTab(),
          _VolumeTab(),
          _RecoveryTab(),
          _PRTab(),
        ],
      ),
    );
  }
}

// Strength tab
class _StrengthTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedRange = ref.watch(dateRangeProvider);
    final strengthData = ref.watch(strengthTrendProvider(selectedRange));
    
    return ListView(
      padding: const EdgeInsets.all(TFSpacing.s5),
      children: [
        // Date range selector
        _DateRangeChips(
          selected: selectedRange,
          onChanged: (range) => ref.read(dateRangeProvider.notifier).state = range,
        ),
        const SizedBox(height: TFSpacing.s5),
        // Hero chart
        _StrengthChart(
          data: strengthData.value,
          isLoading: strengthData.isLoading,
        ),
        const SizedBox(height: TFSpacing.s4),
        // Summary stats
        _SummaryStats(
          current: strengthData.value?.current,
          delta: strengthData.value?.delta,
          pr: strengthData.value?.personalRecord,
        ),
        const SizedBox(height: TFSpacing.s7),
        // Heatmap
        _SectionHeader(title: 'WORKOUT CONSISTENCY'),
        const SizedBox(height: TFSpacing.s3),
        _HeatmapGrid(data: ref.watch(heatmapProvider).value),
        const SizedBox(height: TFSpacing.s7),
        // PR board
        _SectionHeader(title: 'RECENT PRs'),
        const SizedBox(height: TFSpacing.s3),
        _PRBoard(prs: ref.watch(recentPRsProvider).value),
      ],
    );
  }
}

// Line chart widget using fl_chart
class _StrengthChart extends StatelessWidget {
  final List<StrengthDataPoint>? data;
  final bool isLoading;
  
  @override
  Widget build(BuildContext context) {
    if (isLoading) return _ChartShimmer();
    if (data == null || data!.isEmpty) return _ChartEmpty();
    
    return SizedBox(
      height: 240,
      child: LineChart(
        LineChartData(
          lineBarsData: [
            LineChartBarData(
              spots: data!.map((d) => FlSpot(d.date.millisecondsSinceEpoch.toDouble(), d.value)).toList(),
              isCurved: true,
              color: TFColors.accent,
              barWidth: 2,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    TFColors.accent.withOpacity(0.3),
                    TFColors.accent.withOpacity(0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) => _DateLabel(value),
              ),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: _calculateInterval(data!),
            getDrawingHorizontalLine: (value) => FlLine(
              color: TFColors.surfaceBorder,
              strokeWidth: 0.5,
              dashArray: [4, 4],
            ),
          ),
          borderData: FlBorderData(show: false),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => TFColors.surfaceElevated,
              getTooltipItems: (spots) => spots.map((spot) {
                return LineTooltipItem(
                  '${spot.y.toStringAsFixed(1)}kg',
                  TFType.dataSmall.copyWith(color: TFColors.textPrimary),
                );
              }).toList(),
            ),
            touchSpotThreshold: 20,
          ),
        ),
        duration: Duration(milliseconds: 600), // Animation
        curve: Curves.easeOut,
      ),
    );
  }
}

// Heatmap grid (GitHub-style)
class _HeatmapGrid extends StatelessWidget {
  final List<HeatmapWeek>? data;
  
  @override
  Widget build(BuildContext context) {
    if (data == null || data!.isEmpty) return _HeatmapEmpty();
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: CustomPaint(
        size: Size(data!.length * 14.0, 7 * 14.0), // 14px per cell
        painter: _HeatmapPainter(
          weeks: data!,
          colors: [
            TFColors.surface,        // 0 workouts
            TFColors.positiveGlow,   // 1 workout
            TFColors.positiveMuted,  // 2 workouts
            TFColors.positive,       // 3+ workouts
          ],
        ),
      ),
    );
  }
}
```

**Key implementation notes:**
- `fl_chart` package for line charts — `LineChart` with `isCurved: true`
- Gradient fill: `BarAreaData` with `LinearGradient` from accent 30% to transparent
- Touch inspect: `LineTouchData` with custom tooltip
- Heatmap: `CustomPainter` with grid of rounded rectangles, color intensity based on workout count
- PR cards: `TFGlowingCard` with gold gradient border (`fireGradient`)
- Tab animation: `TabController` with `vsync` for smooth transitions
- Date range state: `StateProvider<DateRange>` for cross-tab consistency
- Data providers: use `AsyncNotifierProvider` for each data source with caching

### 5.12 Visual Generation Prompts

No hero images needed — this screen's visual richness comes from data visualization, charts, and the heatmap.

#### PR Card Gradient (programmatic)

| Attribute | Value |
|-----------|-------|
| **Format** | Flutter gradient (LinearGradient) |
| **Colors** | `personalRecord` (#FBBF24/gold) → `accent` (#F97316/orange) |
| **Direction** | Top-left to bottom-right |
| **Usage** | Border glow on PR cards, 1px gradient border |
| **Effect** | Subtle gold shimmer that makes PR cards feel premium |

#### Empty State Illustration (optional)

| Attribute | Value |
|-----------|-------|
| **Format** | SVG or PNG, 200×200 |
| **Prompt** | "Minimalist line chart illustration, single ascending line with subtle glow, dark background (#0A0A0A), orange accent (#F97316), abstract data visualization, no text, no axes. Clean, modern." |
| **Negative prompt** | "Complex, busy, text, labels, axes, people, realistic" |
| **Mood** | Encouraging, forward-looking |
| **App location** | Empty state in progress dashboard |
| **Export notes** | <30KB. Use as `SvgPicture.asset` or `CustomPaint`. |

### 5.13 Safety & Proof Notes

| Rule | Status |
|------|--------|
| No punitive framing | ✅ Plateaus shown as "consistent," not "stalled." Declining trends use muted colors, never red. |
| Body-neutral copy | ✅ No "you're getting fatter" or "you lost muscle." Weight trends are informational, not judgmental. |
| Adherence-neutral | ✅ Missed workout weeks show as lighter heatmap cells, not red warning cells. |
| PR accuracy | ✅ PRs calculated from deterministic data (logged sets). Never fabricated or approximated. |
| Share cards | ✅ If user shares progress, the card shows real data only. No inflated numbers. |
| Privacy | ✅ Progress data visible only to the user. No social feed. Sharing is opt-in per card. |

### 5.14 Acceptance Criteria

- [ ] Tab bar renders 4 tabs: Strength, Volume, Recovery, PRs
- [ ] Active tab: textPrimary + 2px accent underline, animated indicator
- [ ] Line chart: smooth curves, orange gradient fill, 600ms draw animation
- [ ] Chart supports touch-to-inspect with value tooltip
- [ ] Summary stats: current value, delta (▲/▼ with color), PR value
- [ ] Date range selector: 1M, 3M, 6M, 1Y, All chips
- [ ] Changing date range re-fetches data and re-animates chart
- [ ] Heatmap: 52-week grid, intensity from surface to positive (green)
- [ ] Heatmap cells tappable with tooltip showing week + count
- [ ] PR cards: gold-bordered, show exercise + weight + date + comparison
- [ ] Empty state: "Complete more workouts to see your progress"
- [ ] Loading state: shimmer skeleton for chart + stats area
- [ ] Error state: cached data shown + snackbar
- [ ] All text passes WCAG AA contrast
- [ ] Screen reader announces chart data, tab selection, and PR details
- [ ] Reduced motion: charts appear instantly, no draw animation
- [ ] Tested with 0 data points, 5 data points, and 100+ data points

---

## APPENDIX: CROSS-SCREEN CONSISTENCY CHECKLIST

| Rule | Landing | Today | Workout | Coach | Progress |
|------|---------|-------|---------|-------|----------|
| Dark-only canvas (#0A0A0A) | ✅ | ✅ | ✅ | ✅ | ✅ |
| ONE Playfair headline per screen | ✅ Headline | ✅ Coach hint | ✅ Coach message | ✅ Coach bubbles | ❌ None (data screen) |
| Max 3 font sizes per screen | ✅ | ✅ | ✅ | ✅ | ✅ |
| Accent color ≤2 elements per screen | ✅ CTA + pulse | ✅ Start Workout + ring | ✅ Log Set + progress dots | ✅ User bubble + send | ✅ Chart line + active tab |
| All touch targets ≥44px | ✅ | ✅ | ✅ (48px) | ✅ | ✅ |
| WCAG AA contrast | ✅ | ✅ | ✅ | ✅ | ✅ |
| Reduced motion support | ✅ | ✅ | ✅ | ✅ | ✅ |
| Empty state defined | ✅ | ✅ | ✅ | ✅ | ✅ |
| Error state defined | ✅ | ✅ | ✅ | ✅ | ✅ |
| Loading state defined | ✅ | ✅ | ✅ | ✅ | ✅ |
| Haptic feedback mapped | ✅ | ✅ | ✅ | ✅ | ✅ |
| Screen reader semantics | ✅ | ✅ | ✅ | ✅ | ✅ |

---

## APPENDIX: DESIGN SYSTEM TOKEN QUICK REFERENCE

### Colors (from §3)
```
canvas:          #0A0A0A    surface:         #141414
surfaceElevated: #1C1C1C    surfaceBorder:   #262626
textPrimary:     #F0EDE8    textSecondary:   #8A8A8A
textTertiary:    #5A5A5A    textInverse:     #0A0A0A
accent:          #F97316    electric:        #8B5CF6
mint:            #10B981    sky:             #3B82F6
positive:        #10B981    neutral:         #F97316
caution:         #F59E0B    critical:        #EF4444
```

### Typography (from §4)
```
displayLarge:    Playfair 36px w700     — Hero headlines (1 per screen)
h1:              Inter 24px w700        — Screen titles
h2:              Inter 20px w600        — Section headers
h3:              Inter 17px w600        — Card titles
bodyLarge:       Inter 17px w400        — Body text
bodyMedium:      Inter 15px w400        — Secondary text
labelMedium:     Inter 13px w500        — Labels
dataHero:        Inter 56px w700 tab    — Recovery score
dataLarge:       Inter 32px w700 tab    — Macro numbers
dataMedium:      Inter 24px w600 tab    — Metric values
```

### Spacing (from §5)
```
s1: 4px    s2: 8px     s3: 12px    s4: 16px
s5: 20px   s6: 24px    s7: 32px    s8: 40px
```

### Radius (from §6)
```
radiusXs: 4px    radiusSm: 8px    radiusMd: 12px
radiusLg: 16px   radiusXl: 24px   radiusFull: 999px
```

### Animation Durations (from §11)
```
micro:  100ms    fast: 200ms    normal: 350ms
slow:   600ms    epic: 1200ms
```

---

*This document is binding for all TransformFit screen implementations. Every pixel must conform to TRANSFORMFIT_DESIGN_SYSTEM_SPEC.md. Every interaction must serve the user's next healthy action.*
