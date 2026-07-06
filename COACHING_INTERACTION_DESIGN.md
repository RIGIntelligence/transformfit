# TransformFit Coaching Interaction Design

> **Version:** 1.0 — M8 LLM Coaching
> **Author:** RIG Creative Director
> **Status:** Implementation spec — binding for all coaching UI work
> **Dependencies:** `digital_atelier.dart`, `persona_system.dart`, `expertise_personas.dart`, `coach_signal.dart`

---

## 1. Design Philosophy

TransformFit's coach is **not a chatbot**. It is a coach that happens to live in your phone. Every interaction must pass three tests:

1. **Would a real coach say this?** — No "As an AI..." hedging, no "I'm here to help!" pleasantries.
2. **Does it contain data?** — Every message must reference a specific number, trend, or observation. Doctrine L1-7: no generic encouragement.
3. **Does it earn the next action?** — Every message ends with a concrete next step, not a question.

The coach has **two voices**:
- **Micro-voice** — Short, in-context coaching moments during active training (set logging, rest timer, PR celebrations). These are deterministic CoachSignal outputs rendered through the persona template system.
- **Macro-voice** — Conversational, data-rich responses in the coach chat. These use the LLM narration layer with deterministic CoachSignal as the backbone (Doctrine: deterministic backbone, LLM narration on top).

---

## 2. Interaction Flows — Second-by-Second

All timings reference the Digital Atelier v3 Fibonacci animation tokens:

| Token | Duration | Use |
|-------|----------|-----|
| `durationFast` | 100ms (F5) | Micro-interactions, button press, haptic sync |
| `durationNormal` | 200ms (F6) | Number counters, emoji scale, highlights |
| `durationSlow` | 500ms (F7) | Card reveals, PR badge slide, emphasis |
| `durationCelebration` | 1300ms (F8) | Confetti, PR explosion, achievement unlock |
| `animVerySlow` | 800ms | Score circles, breathing timer, dramatic reveals |
| `animHero` | 2100ms | Hero image transitions, full-screen reveals |

Curves:
| Token | Curve | Use |
|-------|-------|-----|
| `curveDefault` | `easeOutCubic` | Arrivals, deceleration, settling |
| `curveBounce` | `elasticOut` | Celebrations, PR badges, achievements only |
| `curveSlide` | `easeOutQuart` | Screen transitions, chat message slides |

---

### 2.1 Scenario 1 — First-Time User Opens App (Day Zero)

**Workflow ID:** `day_0_activation`
**Persona:** Motivator (high intensity)
**Tone-Arc Phase:** Days 0–7 (80% directive / 20% supportive)

```
T+0.000s  App launches. Dark canvas (#0A0A0A) fills screen.
          No splash screen. The darkness IS the canvas.

T+0.300s  Hero image (assets/hero_workout.png) slides in from bottom.
          Animation: TranslateTransition, 500ms, easeOutQuart.
          Offset: (0, +40) → (0, 0). Opacity: 0 → 1.

T+0.600s  Title fades in.
          Text: "A coach who already noticed"
          Style: Playfair, 28sp, w600, #FFFFFF
          Animation: FadeTransition, 300ms, easeOutCubic.

T+0.900s  Subtitle fades in.
          Text: "Before you log a single rep, we built your plan"
          Style: Inter, 14sp, w400, #9CA3AF
          Animation: FadeTransition, 300ms, easeOutCubic.

T+1.200s  Readiness circle animates in.
          Animation: 0 → score over 800ms, easeOutCubic.
          Ring color: accentPrimary (#F97316) at 0-49, success (#10B981) at 50-79,
          accentTertiary (#10B981) at 80-100.
          Center text: score number animates with AnimatedSwitcher (200ms).
          Below circle: "READINESS" label in dataLabel style.

T+1.500s  "Begin" button appears.
          Style: Pill (radiusPill), accentPrimary background, #0A0A0A text,
          Inter 16sp w600, 48px height, horizontal padding 32px.
          Animation: Gentle pulse — scale 1.0 → 1.02 → 1.0, 1000ms cycle,
          Curves.easeInOut. Repeats 3 times then holds at 1.0.
          Shadow: elevationMedium with accentPrimary tint (0x14F97316).

T+2.000s  User taps "Begin".
          TAP FEEDBACK:
            - Haptic: HapticFeedback.mediumImpact()
            - Button: scale 1.0 → 0.95 over 100ms (durationFast, easeOutCubic)
            - Then: scale 0.95 → 1.0 over 200ms (durationNormal, easeOutCubic)

T+2.200s  Screen transition to intake flow.
          Animation: Shared axis vertical, 300ms, easeOutQuart.
          Current screen slides up + fades (opacity 1 → 0).
          Intake screen slides up from below (offset +30 → 0) + fades in.
```

**Fallback (no readiness data yet):**
The readiness circle shows a pulsing "?" in the center with text "Let's find out" below. The circle ring is surfaceBorder color. After intake, the circle animates to the computed score.

---

### 2.2 Scenario 2 — User Logs a Set (Active Session)

**Workflow ID:** `live_session_guidance`
**Persona:** Analyst (normal intensity) — switches to Challenger if coasting detected
**Tone-Arc Phase:** Context-dependent

```
T+0.000s  User taps '+' on weight stepper.
          Weight value animates: old → new, 200ms, durationNormal.
          Animation: AnimatedSwitcher with SlideTransition (offset Y: +8 → 0).
          Number style: Inter, 24sp, w700, #FFFFFF.
          Stepper button: scale 1.0 → 0.9 → 1.0, 100ms total.

T+0.050s  Haptic: HapticFeedback.lightImpact().
          Timing synced to the spring curve peak.

T+0.200s  User taps '+' on reps stepper.
          Same animation as weight stepper.
          Number style: Inter, 24sp, w700, #FFFFFF.

T+0.250s  Haptic: HapticFeedback.lightImpact().

T+0.500s  User taps "Log Set" button.
          Button style: Pill, accentPrimary, 48px height.
          Button: scale 1.0 → 0.95 over 100ms.
          Haptic: HapticFeedback.mediumImpact().

T+0.600s  Set row slides in from right edge.
          Animation: TranslateTransition, 300ms, easeOutQuart.
          Offset: (+screenWidth, 0) → (0, 0).
          Row style: surface (#111111), radiusMd (5px), padding 12px.
          Contains: "Set N — {weight}kg × {reps} — RPE {rpe}"

T+0.700s  Green flash on the set row.
          Animation: Background color flash, surface → success (#10B981) → surface.
          Duration: 200ms total (80ms green, 120ms fade back).
          Implementation: AnimatedContainer or ColorTween.

T+0.800s  Rest timer appears automatically.
          Animation: FadeTransition + scale from 0.8 → 1.0, 300ms, easeOutCubic.
          Timer style: Breathing circle — diameter pulses 40px → 44px → 40px
          over 4000ms (inhale 2s, exhale 2s), Curves.easeInOut.
          Timer text: seconds remaining, Inter 14sp w500, textSecondary.
          Position: Below the set row, centered.

T+0.900s  Coach message slides up below the rest timer.
          Animation: TranslateTransition, 300ms, easeOutQuart.
          Offset: (0, +20) → (0, 0). Opacity: 0 → 1.
          Style: Playfair, 16sp, w400, #FFFFFF. Italic.
          Background: surfaceGlass(opacity: 0.06), radiusMd, padding 12px.
          Left border: 2px accentPrimary (persona indicator).
          Content: CoachSignal.coachNote — deterministic, <=60 words.

T+1.200s  Quick action chips appear below coach message.
          Animation: Staggered fade-in, 100ms between each, easeOutCubic.
          Chips: "Increase weight" | "Same weight" | "Decrease"
          Style: Pill, surfaceElevated background, surfaceBorder outline,
          Inter 13sp w500, textSecondary. Height 36px.
          Active chip: accentPrimary border + text.
          On tap: accentPrimary haptic (lightImpact), chip scales 0.95 → 1.0.

T+1.500s  Rest timer continues breathing cycle.
          If rest timer reaches 0: haptic heavyImpact, timer ring flashes
          accentPrimary twice (200ms each), then "Ready" text replaces timer.
```

**Coasting Detection Override:**
If `_classifyEffortRisk` returns `coasting` (3+ sets, avg RPE ≤ 5):
- Coach persona switches to Challenger
- Coach message changes to coasting signal
- Left border color changes to accentDanger (#EF4444)
- Quick actions change to: "Go heavier" | "Add a set" | "I'm done"
- Haptic: HapticFeedback.heavyImpact() on message appearance

---

### 2.3 Scenario 3 — User Opens Coach Chat

**Workflow ID:** Context-dependent (resolved by `buildCoachSignal`)
**Persona:** Dynamic (resolved by `selectPersona`)
**Tone-Arc Phase:** Context-dependent

```
T+0.000s  Chat screen slides in from right.
          Animation: Shared axis horizontal, 300ms, easeOutQuart.
          Background: background (#0A0A0A).

T+0.100s  Last 3 messages fade in (staggered).
          Animation: FadeTransition, 200ms each, 100ms stagger, easeOutCubic.
          Message order: oldest → newest, bottom-aligned.

T+0.400s  Typing indicator appears.
          Style: 3 dots, 6px diameter each, persona accent color.
          Animation: Sequential pulse — dot 1 scales 0.5 → 1.0 → 0.5,
          400ms each, staggered 130ms. Loop until message arrives.
          Position: Left-aligned coach bubble area.

T+0.800s  Coach message slides up.
          Animation: TranslateTransition, 300ms, easeOutQuart.
          Offset: (0, +16) → (0, 0).
          Style: Playfair, 16sp, w400, #FFFFFF.
          Bubble: surfaceGlass(opacity: 0.06), radiusMd (5px).
          Left border: 2px persona color.
          Max width: 85% of screen width.
          Content: CoachSignal rendered through persona template.
          Word limit: 60 words max (Doctrine L1-7).

T+1.200s  Quick action chips appear.
          Animation: Staggered slide-in from left, 200ms each, 100ms stagger.
          Style: Same as Scenario 2 chips.
          Content: Context-dependent — derived from CoachSignal.nextAction
          plus 1-2 complementary actions.

T+1.500s  User taps a quick action chip.
          User message slides in from right: 200ms, easeOutQuart.
          Style: Inter, 15sp, w400, #FFFFFF.
          Bubble: accentPrimary with 12% opacity, radiusMd.
          Right-aligned, max width 80%.

T+1.700s  Typing indicator reappears.
          Duration: 500ms minimum (feels natural), up to 2000ms for complex responses.

T+2.200s  Coach response slides up.
          If response contains rich content (readiness score, bullet points):
            - Score circle: AnimatedSwitcher, 500ms, easeOutCubic
            - Bullet points: Staggered fade-in, 200ms each, easeOutCubic
            - Recommendation: Final element, 300ms, with accentPrimary left border

T+3.000s  Quick actions update.
          Previous chips fade out (200ms), new chips fade in (200ms).
          Content: "Tell me more" | "Adjust my plan" | "Thanks"
```

**Message Streaming (LLM narration):**
When the LLM is streaming a response:
1. Typing indicator shows for 500ms minimum
2. First tokens appear as a growing text block (no per-character animation)
3. Text style: Playfair, 16sp, w400, #FFFFFF
4. Cursor blink: 500ms on/off cycle, accentPrimary color
5. On stream complete: cursor disappears, message bubble finalizes
6. If stream takes >5s: show "Thinking..." text below the typing dots

---

### 2.4 Scenario 4 — PR Celebration

**Workflow ID:** `pr_celebration` (new workflow, triggered by session controller)
**Persona:** Motivator (high intensity) + active expertise persona voice
**Trigger:** `newLoad > previousPR * 1.0` for any exercise

```
T+0.000s  User logs a set that exceeds the previous PR.
          Detection: Session controller compares logged weight against
          exercise PR history.

T+0.050s  Haptic: HapticFeedback.heavyImpact().
          This is the ONLY heavy haptic in the workout flow.
          Must feel distinct from all other feedback.

T+0.100s  Screen flash.
          Animation: Full-screen white overlay, opacity 0 → 0.3 → 0.
          Duration: 100ms total (40ms up, 60ms down).
          Implementation: Stack with AnimatedOpacity.

T+0.200s  Confetti explosion from the "Log Set" button origin.
          Particles: 40-60 particles, 4px × 8px rectangles.
          Colors: accentPrimary, accentSecondary, accentTertiary, success.
          Physics: Random velocity (200-600px/s), gravity (-400px/s²),
          rotation (0-720°), fade (1.0 → 0.0 over 1300ms).
          Animation duration: 1300ms (durationCelebration), easeOut.
          Implementation: CustomPainter with AnimationController.

T+0.300s  PR badge slides down from top of screen.
          Animation: TranslateTransition, 500ms, elasticOut (curveBounce).
          Offset: (0, -100) → (0, 0).
          Badge style: accentPrimary background, radiusLg (8px), padding 16px.
          Content: "🏆 NEW PR" in Inter 14sp w700, #0A0A0A.
          Position: Top center, 60px from top.

T+0.500s  PR text scales up.
          Text: "{exercise name}" in Playfair 24sp w600, #FFFFFF.
          Animation: ScaleTransition, 300ms, elasticOut.
          Scale: 0.5 → 1.0.

T+0.800s  Comparison line appears.
          Text: "{oldPR}kg → {newPR}kg (+{percent}%)"
          Style: Inter, 16sp, w500.
          Old PR: textSecondary (#9CA3AF), strikethrough.
          Arrow: accentPrimary.
          New PR: #FFFFFF, w700.
          Percent: success (#10B981).
          Animation: FadeTransition, 300ms, easeOutCubic.

T+1.000s  Coach message appears.
          Animation: TranslateTransition, 300ms, easeOutQuart.
          Style: Playfair, 18sp, w500, #FFFFFF. Italic.
          Content: Persona-specific PR message (see Section 3).
          Must reference: the exact weight, the exact improvement,
          and one specific observation (e.g., "RPE 8 — you had more").

T+1.300s  Share button appears.
          Animation: FadeTransition + scale 0.8 → 1.0, 300ms, easeOutCubic.
          Style: Pill, surfaceElevated, accentPrimary text, Inter 14sp w600.
          Icon: share icon (20px) + "Share" text.

T+1.500s  Confetti fades out.
          All remaining particle opacities → 0.

T+2.000s  PR badge and comparison fade out.
          Animation: FadeTransition, 500ms, easeOutCubic.
          Rest timer reappears if applicable.
          Normal workout state resumes.
```

**PR Celebration Sound Design:**
- No sound by default (respect silent mode)
- If sound enabled: short "whoosh" + "click" on the heavy haptic
- Sound file: `assets/sounds/pr_celebration.mp3` (200ms, <50KB)

---

### 2.5 Scenario 5 — Daily Wellness Check-In

**Workflow ID:** `wellness_checkin` (triggers on app open if no check-in today)
**Persona:** Context-dependent (typically Motivator early, Zen if fatigue detected)

```
T+0.000s  App opens. Recovery circle animates in.
          Animation: 0 → score over 800ms, easeOutCubic.
          Circle: Same as Scenario 1 readiness circle.
          If no previous data: Shows "—% " with surfaceBorder ring.

T+0.500s  "How are you feeling?" prompt appears.
          Style: Playfair, 20sp, w500, #FFFFFF.
          Animation: FadeTransition, 300ms, easeOutCubic.

T+0.800s  5 emoji buttons fade in (staggered).
          Emojis: 😊 😐 😔 😤 😴
          Animation: FadeTransition, 200ms each, 100ms stagger.
          Button style: 56px × 56px, surfaceElevated background,
          radiusLg (8px). Emoji: 28sp.
          Spacing: 12px between buttons.

T+1.000s  User taps an emoji.
          TAP FEEDBACK:
            - Selected emoji: scale 1.0 → 1.3 → 1.1, 200ms, elasticOut.
            - Other emojis: opacity 1.0 → 0.3, 200ms, easeOutCubic.
            - Haptic: HapticFeedback.lightImpact().
            - Selected button: accentPrimary border (2px), 200ms fade.

T+1.200s  "What's your energy like?" slider appears.
          Animation: TranslateTransition, 300ms, easeOutQuart.
          Offset: (0, +20) → (0, 0).
          Label: Inter, 16sp, w500, #FFFFFF.
          Slider: Custom slider, 0-10 scale.
            Track: surfaceBorder, 4px height, radiusPill.
            Active track: accentPrimary, 4px height.
            Thumb: 24px circle, accentPrimary, elevationMedium.
            Value label: Inter, 14sp, w700, #FFFFFF, above thumb.

T+1.500s  User slides to a value.
          On drag: thumb follows finger, active track updates.
          Haptic: HapticFeedback.selectionTick() at each integer step.
          On release: thumb pulses (scale 1.0 → 1.1 → 1.0, 100ms).

T+1.800s  "Any soreness?" body map appears.
          Animation: FadeTransition, 300ms, easeOutCubic.
          Body map: Simplified anterior/posterior silhouette.
            Style: SVG paths, surfaceBorder stroke, transparent fill.
            Tappable regions: Head, Neck, Shoulders, Chest, Upper back,
            Lower back, Arms, Core, Hips, Quads, Hamstrings, Calves.
            Each region: 44px minimum touch target.
          Below map: "Tap where it hurts — or skip" in textSecondary.

T+2.000s  User taps a body part.
          TAP FEEDBACK:
            - Highlighted region: accentDanger (#EF4444) fill, 20% opacity.
            - Animation: FadeTransition, 200ms, easeOutCubic.
            - Haptic: HapticFeedback.lightImpact().
            - Region label appears below: "Lower back" in Inter 14sp w500,
              accentDanger text.

T+2.300s  "Got it. Adjusting your workout." appears.
          Style: Playfair, 16sp, w400, textSecondary. Italic.
          Animation: FadeTransition, 200ms, easeOutCubic.
          Below: Loading indicator — accentPrimary ring spinner, 20px.

T+2.500s  Recovery circle updates.
          Animation: Old score → new score, 300ms, easeOutCubic.
          Color may shift (e.g., from success to warning if soreness detected).

T+2.800s  "Today's plan" card slides in.
          Animation: TranslateTransition, 500ms, easeOutQuart.
          Offset: (0, +40) → (0, 0).
          Card style: surface (#111111), radiusMd, padding 16px,
          elevationMedium.
          Content:
            - Title: "Today's Plan" in Inter 14sp w600, textSecondary.
            - Workout name: Playfair 20sp w500, #FFFFFF.
            - Duration: Inter 14sp w400, textSecondary.
            - Adjustment note: Inter 13sp w400, accentPrimary.
              E.g., "Reduced load on lower body — soreness noted."
            - "Start" button: Pill, accentPrimary, 48px.
```

**Skip Flow:**
If user taps "Skip" at any point:
- Current step fades out (200ms)
- Next step fades in (200ms)
- No data recorded for skipped step
- Final plan uses defaults for skipped inputs

---

## 3. Coach Voice Scripts — All Personas

Every message must pass `coachSignalCopyIsGateSafe()` — no banned terms, no emoji, no generic encouragement, no body-shaming language. Every message must contain a data token (Doctrine L1-7, L1-8).

### 3.1 Motivator (Orange — `#F97316`)

**Role:** Momentum builder. Notices effort, celebrates consistency, not intensity.

**Session Start:**
1. "Readiness {score} and {sessions} sessions logged. Momentum is building — today keeps the chain going."
2. "You showed up. That's the hardest part. Readiness is {score} — the plan matches your energy."
3. "Session {count} in the ledger. Each one is a promise kept. Today adds another."
4. "The gap between where you started and where you are is {sessions} sessions wide. That's real."
5. "Readiness {score}. The plan is built. All you have to do is start."

**Mid-Session:**
6. "{volume}kg moved so far. Effort is showing up in the numbers."
7. "That set was clean. RPE {rpe}. Trust the process — the data is tracking."
8. "{sets} sets logged. You're past the hardest part — the momentum is yours now."
9. "RPE {rpe} on the last set. Controlled effort. That's how progress compounds."
10. "Halfway there. {volume}kg and counting. Keep the quality high."

**Session End:**
11. "Session complete. {sessions} promises kept. That consistency is the whole game."
12. "{volume}kg across {sets} sets. Done. Rest is where the work integrates."
13. "Another session in the ledger. The gap between you and your goal just got smaller."
14. "Clean session. RPE averaged {rpe}. You showed up and did the work."
15. "Session {count} logged. Your future self is thanking you right now."

**Recovery:**
16. "{soreness} sore areas today. A recovery walk counts — momentum stays."
17. "Readiness {score}. Recovery is not a step back — it's how the chain holds."
18. "Low energy today. A walk, water, sleep — that's the work. Session {count} still counts."
19. "The body is asking for rest. Listening is not quitting. Come back stronger."
20. "Recovery day. {sessions} sessions this week. The rhythm is set."

**Stall (missed days):**
21. "No session in {days} days. The restart is small: one set, logged."
22. "{days} days away. The chain is not broken — it's paused. One set restarts it."
23. "The gap is {days} days. That's okay. The next session is the only one that matters."
24. "Readiness is not the issue — restarting is. Log one set today. That's the whole goal."
25. "Your last session was {days} days ago. The plan is still here. Start small."

### 3.2 Analyst (Blue — `#3B82F6`)

**Role:** Pattern interpreter. Cites trends, surfaces anomalies, uses precise numbers.

**Session Start:**
1. "Readiness {score}. Last session hit {volume}kg — baseline is set."
2. "Your 4-week volume average is {avg}kg. Today's target: match or beat by 5%."
3. "Readiness {score}, sleep {sleep}/10. The data suggests a {zone} effort session."
4. "{sessions} sessions in the last 14 days. Frequency is tracking the program."
5. "RPE trend: last 3 sessions averaged {avgRPE}. The progression corridor is holding."

**Mid-Session:**
6. "RPE {rpe} on the last set. Trend is tracking the progression corridor."
7. "{volume}kg logged. Volume per set is {avg}kg — consistent with the plan."
8. "Set {n}: RPE {rpe}, {weight}kg × {reps}. The data point is clean."
9. "RPE {rpe} at {weight}kg. If RPE drops below 7 next set, increase by 2.5kg."
10. "Current pace: {volume}kg in {sets} sets. Projected session volume: {proj}kg."

**Session End:**
11. "Volume: {volume}kg across {sessions} sessions. The data shows a clean upward path."
12. "Session averaged RPE {rpe}. That's within the target corridor of 7-8."
13. "{sets} sets, {volume}kg. Volume is {delta}% {'above' if positive / 'below' if negative} your 4-week average."
14. "Progression: {exercise} up {delta}kg from last week. RPE held at {rpe}."
15. "Session {count} complete. Total volume to date: {total}kg. Trend: upward."

**Recovery:**
16. "{soreness} sore areas, readiness {score}. Recovery is within normal range."
17. "Readiness dropped {delta} points from yesterday. Sleep was {sleep}/10. Adjust accordingly."
18. "HRV trend: declining over 3 days. A recovery session is the data-driven choice."
19. "Soreness in {area}. This is consistent with the volume spike on {date}. Expected."
20. "Readiness {score}, sleep {sleep}/10. The numbers say light session or rest."

**Stall (missed days):**
21. "Gap of {days} days detected. Pattern suggests recalibration, not restart."
22. "Last session: {days} days ago. Volume was {volume}kg. Resume at 80% to avoid DOMS."
23. "{days} days off. Your pre-stall average was {avg}kg. Re-entry at {target}kg is optimal."
24. "Frequency dropped from {before}/week to {after}/week. The data says restart today."
25. "Session gap: {days} days. The regression risk is low if you log today."

### 3.3 Challenger (Red — `#EF4444`)

**Role:** Standard-raiser. Direct, evidence-led, confronts without shame.

**Session Start:**
1. "Readiness {score}. The target is {rpe} RPE. Earn the last set."
2. "Readiness {score}, fatigue safe. Today is not a coasting day."
3. "You said you wanted to hit {target}. Today's readiness says you can."
4. "{sessions} sessions this week. The standard is {target}/week. One more."
5. "RPE averaged {avgRPE} last session. That's below the target. Today, be honest."

**Mid-Session:**
6. "{volume}kg logged. Is this the standard you set, or the one you settled for?"
7. "RPE {rpe}. That was comfortable. The next set should not be."
8. "{sets} sets done, RPE averaging {avg}. The plan calls for {target} RPE. Adjust."
9. "That set was RPE {rpe}. You have more in you — the data proves it."
10. "Volume is {delta}% below your last session at this point. Close the gap."

**Session End:**
11. "{sessions} sessions done. Next week the bar moves — data says you are ready."
12. "Session averaged RPE {rpe}. That's the standard. Hold it."
13. "{volume}kg logged. That's a {delta}% increase from last week. Earned, not given."
14. "Clean session. RPE {rpe}, {sets} sets. The standard held."
15. "Session {count}. The gap between your goal and your last PR is {delta}kg. Closing."

**Recovery:**
16. "{soreness} sore areas. Recovery is not optional — it is how the standard holds."
17. "Readiness {score}. Today's standard is rest. Come back ready to earn it."
18. "Low readiness. The smart move is recovery. The standard does not require suffering."
19. "Fatigue is high. A recovery session protects tomorrow's standard."
20. "The body is asking for rest. Ignoring it costs more than one day."

**Stall (missed days):**
21. "{days} days off. The standard does not lower — it waits. Log the next set."
22. "The gap is {days} days. Every day after this makes the restart harder. Today."
23. "You set a goal of {target}. {days} days of silence. The standard is still there."
24. "{days} days away. The restart is one set. Not a perfect session. One set."
25. "The standard you set on day 1 is still the standard. {days} days is enough rest."

### 3.4 Zen (Purple — `#8B5CF6`)

**Role:** Recovery stabilizer. Calm, quality-first, sustainability-focused.

**Session Start:**
1. "Readiness {score}. Today is about quality of movement, not quantity."
2. "Readiness {score}. The body is asking for presence, not performance."
3. "Today's session is built for recovery. Move well, breathe deeply."
4. "{soreness} sore areas noted. The plan adjusts — quality over volume."
5. "Readiness {score}. Breathe. The weight will be there tomorrow."

**Mid-Session:**
6. "RPE {rpe}. Breathe into the effort. Form first, load second."
7. "{volume}kg moved. The body is working. Honor the pace."
8. "RPE {rpe}. That's the right effort for today. Stay here."
9. "Set {n} done. The breath is steady. The form is clean. Continue."
10. "The weight feels heavy today. That's data, not failure. Adjust and continue."

**Session End:**
11. "Session done. {sessions} in the ledger. Rest is where the work integrates."
12. "{volume}kg moved with intention. The body will remember the quality."
13. "Clean session. RPE {rpe}. The work was honest. Now rest."
14. "Session {count}. The quality was high. That matters more than the numbers."
15. "Done. Breathe. The session is complete. Recovery starts now."

**Recovery:**
16. "{soreness} sore areas. A walk, water, sleep — recovery is training."
17. "Readiness {score}. Your body is telling you something. Let's listen."
18. "Low energy. The body is asking for gentleness. Honor it."
19. "Recovery is not passive. It is where adaptation happens. Rest well."
20. "Readiness {score}. A gentle walk today will serve you better than a hard session."

**Stall (missed days):**
21. "{days} days away. Return gently. The body remembers."
22. "The pause was necessary. When you're ready, start with movement, not intensity."
23. "{days} days of rest. The body has been healing. Resume with kindness."
24. "The gap is {days} days. There is no guilt here. Start when the body says yes."
25. "Your last session was {days} days ago. The rhythm will return. One gentle set."

### 3.5 Strength Coach (Nippard-style — `#10B981` accentTertiary)

**Expertise overlay:** `ExpertisePersona.strengthCoach`
**Combines with:** Any core persona (typically Analyst or Challenger)

**Progressive Overload:**
1. "Based on your last 3 sessions, increase bench by 2.5kg. RPE has been 6-7 — the data supports it."
2. "Squat volume is up 12% this month. RPE trending down. You're getting stronger."
3. "Your deadlift has progressed 5kg over 4 sessions while RPE held at 7. Clean progressive overload."
4. "Bench press: last 3 sessions averaged RPE 6.5 at {weight}kg. Time to move to {next}kg."
5. "Volume this mesocycle: {volume}kg. That's {delta}% above last mesocycle. Deload is due in {days} days."

**Form & Technique:**
6. "Your squat depth has improved 15% this month. The mobility work is paying off."
7. "Squat depth check: last set was parallel. Aim for below parallel next set."
8. "Bench press bar path was clean on set 3. The arch and leg drive are dialed in."
9. "Deadlift lockout was solid. The hip hinge timing is improving session over session."
10. "Overhead press: bar path drifted forward on the last rep. Cue: elbows under the bar."

**RPE Calibration:**
11. "RPE 7 at {weight}kg. That's 2-3 RIR. Evidence says that's the hypertrophy sweet spot."
12. "Last set was RPE 8. You have 1-2 reps in reserve. That's where growth happens."
13. "RPE averaged {avg} across all sets. That's autoregulation working as intended."
14. "Set 1: RPE 6. Set 2: RPE 7. Set 3: RPE 8. Clean RPE ladder — the fatigue is accumulating naturally."
15. "RPE {rpe} at {weight}kg. If RPE drops below 7 next session, increase load by 2.5kg."

**Deload & Periodization:**
16. "Deload week. Reduce volume by 40-60%. The adaptation happens during the recovery."
17. "4th week of this mesocycle. Deload protocol: same exercises, 50% volume, RPE 5-6."
18. "Volume has been accumulating for 3 weeks. This week is the supercompensation phase."
19. "Post-deload: your baseline strength should show a 2-5% improvement. Test next session."
20. "Mesocycle complete. Volume increased 15% over 4 weeks. Deload, then rebuild."

**Exercise Selection:**
21. "Compound lifts first. Squat, bench, row — the foundation. Isolation after."
22. "Your squat is your strongest lift. Program it first when energy is highest."
23. "Bench press and overhead press are both pushing movements. Space them 48 hours apart."
24. "Deadlift frequency: 1-2x per week is optimal for your training age."
25. "Add a hip hinge accessory after squat days. Romanian deadlift at RPE 7."

### 3.6 Neuroscientist (Huberman-style — `#6366F1` accentSecondary → calm)

**Expertise overlay:** `ExpertisePersona.neuroscientist`
**Combines with:** Any core persona (typically Analyst or Zen)

**Dopamine & Motivation:**
1. "Exercise triggers dopamine release that lasts 2-4 hours post-workout. You're building a motivation cycle."
2. "The effort itself is the reward signal. Your brain is learning that hard work pays off — that's neuroplasticity."
3. "Consistency builds dopamine baseline. Three sessions this week means your motivation system is stabilizing."
4. "The 'wanting' system (dopamine) drives you to start. The 'liking' system (opioid) rewards you after. Both are active today."
5. "Morning training sets your dopamine tone for the entire day. You chose the optimal window."

**Circadian Rhythm & Timing:**
6. "Morning light exposure will improve your sleep quality tonight. Get 10 minutes of sunlight before your workout."
7. "Training within 4 hours of waking aligns with your cortisol peak. This is the optimal performance window."
8. "Late evening training can delay sleep onset by 30-60 minutes. Morning sessions are circadian-optimal."
9. "Your body temperature peaks at 2-6 PM. If you can train in that window, performance will be highest."
10. "Consistent wake time is the anchor for your entire circadian rhythm. Training time follows from there."

**Recovery & Parasympathetic:**
11. "Your HRV suggests elevated sympathetic nervous system activity. A physiological sigh will help: double inhale, long exhale."
12. "Post-workout: 5 minutes of box breathing (4-4-4-4) activates parasympathetic recovery."
13. "Cold exposure after training may reduce inflammation by 15-20%. Wait 4 hours if hypertrophy is the goal."
14. "Sleep is when BDNF release peaks. 7-9 hours tonight will consolidate today's motor learning."
15. "The parasympathetic system needs activation after intense training. Slow breathing between sets helps."

**Focus & Intensity:**
16. "Visual focus on a fixed point during heavy sets improves force output by 5-10%. Look at a spot on the wall."
17. "Narrowing your visual field (tunnel focus) activates the sympathetic nervous system. Use it for heavy sets only."
18. "Between sets: broaden your visual field (panoramic vision) to activate recovery. Alternate focus modes."
19. "Music at 120-140 BPM synchronizes with optimal movement cadence. It's a performance tool, not just entertainment."
20. "The pre-set breath: big inhale, brace, execute. This is the Valsalva maneuver — it protects the spine and maximizes force."

**Neuroplasticity & Learning:**
21. "Motor learning consolidates during sleep. Practice the movement pattern today, sleep on it, and it will feel easier tomorrow."
22. "Variety in exercise selection drives neuroplasticity. Your brain adapts to novel movement patterns faster."
23. "The 'feel' of the muscle working (mind-muscle connection) is a real neural phenomenon. It improves with practice."
24. "Interleaved practice (mixing exercises) improves long-term motor learning more than blocked practice."
25. "After 3 sessions, the movement pattern is being encoded. By session 10, it will feel automatic."

**Stress & Mental Health:**
26. "Exercise is the most potent acute intervention for anxiety. The neurochemical shift happens within 20 minutes."
27. "BDNF (brain-derived neurotrophic factor) increases with aerobic exercise. It's fertilizer for the brain."
28. "The post-exercise mood boost is not just endorphins — it's serotonin, norepinephrine, and endocannabinoids working together."
29. "Regular training reduces baseline cortisol by 15-25% over 8 weeks. You're building stress resilience."
30. "The discomfort of a hard set trains your brain to tolerate discomfort elsewhere. That's transfer learning."

---

## 4. Animation Timing Specifications

### 4.1 Timing Table (Fibonacci-Based)

| Element | Duration | Curve | Trigger |
|---------|----------|-------|---------|
| Button press (scale) | 100ms (F5) | easeOutCubic | onTapDown |
| Button release (scale) | 200ms (F6) | easeOutCubic | onTapUp |
| Number counter | 200ms (F6) | easeOutCubic | value change |
| Emoji scale | 200ms (F6) | elasticOut | selection |
| Body part highlight | 200ms (F6) | easeOutCubic | selection |
| Screen flash (PR) | 100ms (F5) | linear | PR detected |
| Coach message slide | 300ms (F7*) | easeOutQuart | message ready |
| User message slide | 200ms (F6) | easeOutQuart | send |
| Quick action stagger | 200ms (F6) each | easeOutCubic | message appear |
| Set row slide-in | 300ms (F7*) | easeOutQuart | set logged |
| Green flash | 200ms (F6) | easeOutCubic | set logged |
| Rest timer appear | 300ms (F7*) | easeOutCubic | set logged |
| Rest timer breathe | 4000ms | easeInOut | continuous |
| Typing indicator | 400ms/dot | easeInOut | continuous |
| Score circle | 800ms (F8*) | easeOutCubic | screen open |
| PR badge slide | 500ms (F8*) | elasticOut | PR detected |
| PR text scale | 300ms (F7*) | elasticOut | PR detected |
| Confetti | 1300ms (F8) | easeOut | PR detected |
| Card slide-in | 500ms (F8*) | easeOutQuart | data ready |
| Chat screen transition | 300ms (F7*) | easeOutQuart | navigation |
| Page transition | 300ms (F7*) | easeOutQuart | navigation |

*Note: Where the codebase uses `durationSlow` (500ms) for emphasis and `durationNormal` (200ms) for standard transitions, the 300ms value is `animMedium` from MathematicalDesign.

### 4.2 Stagger Patterns

**Message list stagger:** 100ms between each message
**Quick action chip stagger:** 100ms between each chip
**Emoji button stagger:** 100ms between each emoji
**Bullet point stagger:** 200ms between each point
**Wellness step stagger:** 300ms between each question

### 4.3 Spring Curves (Celebration Only)

```dart
// PR badge — elastic bounce
Curves.elasticOut

// Achievement unlock — elastic bounce
Curves.elasticOut

// Emoji selection — soft bounce
Curves.easeOutBack  // overshoot by ~10%
```

All other animations use `easeOutCubic` (curveDefault) or `easeOutQuart` (curveSlide).

---

## 5. Haptic Feedback Map

### 5.1 Haptic Inventory

| Event | Haptic Type | Timing | Notes |
|-------|-------------|--------|-------|
| Stepper tap (+/-) | `lightImpact()` | On press | Every weight/rep change |
| Button press | `mediumImpact()` | On tap | "Log Set", "Begin", "Start" |
| Set logged | `mediumImpact()` | On tap | Synced with button contract |
| Quick action chip tap | `lightImpact()` | On tap | Chip selection |
| Emoji selection | `lightImpact()` | On tap | Wellness check-in |
| Slider tick | `selectionTick()` | At integer | Energy slider |
| PR detected | `heavyImpact()` | T+50ms | Only heavy haptic in app |
| Rest timer complete | `heavyImpact()` | At 0s | Distinct from PR |
| Error state | `vibrate()` | On error | Network error, save failure |
| Swipe to dismiss | `lightImpact()` | On swipe | Dismiss coach message |

### 5.2 Haptic Rules

1. **Never more than one haptic per 100ms.** If multiple events fire within 100ms, only the highest-severity haptic triggers.
2. **PR heavyImpact is sacred.** It must feel distinct from every other haptic. Never reuse `heavyImpact` for non-PR events except rest timer completion.
3. **Respect system settings.** If the user has haptics disabled in system settings, all haptics are silently skipped. Use `HapticFeedback.canVibrate()` to check.
4. **No haptic during typing indicator.** The typing dots are visual-only.

### 5.3 Flutter Implementation

```dart
// Import
import 'package:flutter/services.dart';

// Stepper tap
HapticFeedback.lightImpact();

// Button press / Set logged
HapticFeedback.mediumImpact();

// PR celebration
HapticFeedback.heavyImpact();

// Slider tick
HapticFeedback.selectionTick();

// Error
HapticFeedback.vibrate();
```

---

## 6. Sound Design Notes

### 6.1 Sound Policy

**Default: Silent.** TransformFit respects the device's silent mode. Sound is opt-in via Settings → Sound.

### 6.2 Sound Assets (If Enabled)

| Event | Sound | Duration | Volume | Notes |
|-------|-------|----------|--------|-------|
| Set logged | `set_click.mp3` | 80ms | 0.4 | Subtle mechanical click |
| PR celebration | `pr_whoosh.mp3` | 200ms | 0.6 | Ascending whoosh + click |
| Rest timer complete | `timer_chime.mp3` | 150ms | 0.3 | Soft chime, not alarming |
| Coach message arrive | `message_pop.mp3` | 60ms | 0.2 | Barely audible pop |
| Error | `error_tone.mp3` | 120ms | 0.3 | Low tone, not harsh |

### 6.3 Sound Rules

1. **Check silent mode first.** Use `AudioSession` to detect if the device is in silent mode.
2. **No sound during typing.** Typing indicators are visual-only.
3. **No repetitive sounds.** If the user is tapping the stepper rapidly (>2 taps/second), suppress the click sound after the first tap.
4. **Volume scales with system.** Never override system volume.

---

## 7. Error State Interactions

### 7.1 Network Error (LLM Unavailable)

**Trigger:** LLM request fails or times out (>10s).

```
T+0.000s  Typing indicator disappears.
T+0.200s  Coach message appears using deterministic fallback.
          Style: Same as normal coach message.
          Content: CoachSignal.deterministicDecision (the deterministic backbone).
          Badge: Small "offline" chip in textSecondary, bottom-right of bubble.
          Text: "offline" in Inter 10sp w400, textMuted.
T+0.500s  Quick actions appear as normal.
          The user can still interact — the deterministic backbone is always available.
```

**If user sends a message while offline:**
```
T+0.000s  User message slides in.
T+0.300s  Typing indicator appears (500ms).
T+0.800s  Coach responds with deterministic fallback.
          Content: Pre-computed persona template based on current session state.
          Badge: "offline" chip visible.
T+1.000s  A subtle banner appears at top of chat:
          "Coach is in offline mode. Responses are based on your data."
          Style: surfaceElevated, textSecondary, Inter 12sp w400.
          Banner: Dismissible, auto-hides after 5s.
```

### 7.2 Save Failure (Set Log Fails)

**Trigger:** Database write fails after "Log Set" tap.

```
T+0.000s  User taps "Log Set".
T+0.050s  Button contracts (normal animation).
T+0.100s  Haptic: HapticFeedback.mediumImpact().
T+0.200s  Save attempt begins.
T+0.500s  Save fails.
          Button: Returns to normal state.
          Error indicator: Red underline beneath the set row.
          Animation: accentDanger underline slides in from left, 300ms.
          Toast: "Set couldn't be saved. Tap to retry."
            Style: surfaceElevated, accentDanger left border, radiusMd.
            Position: Bottom of screen, above input area.
            Animation: SlideTransition from bottom, 300ms, easeOutQuart.
            Auto-dismiss: 5s.
T+0.800s  Haptic: HapticFeedback.vibrate().
```

**Retry flow:**
- User taps the toast or the set row
- Save attempt retries
- On success: Green flash (normal), toast disappears
- On failure: Toast reappears with "Still couldn't save. Check your connection."

### 7.3 Empty State (No Data)

**Trigger:** User opens coach chat with no session history.

```
Coach message:
"Welcome. This is where your coach lives.
Start by completing a readiness check — it takes 30 seconds.
That gives me enough to start building your plan."

Quick actions: "Start readiness check" | "Tell me about the app"
```

### 7.4 Stale Data (No Recent Activity)

**Trigger:** Last session >7 days ago.

```
Coach message:
"Your last session was {days} days ago.
The plan is still here. Start with a light session — the body remembers.
Readiness check first, then we pick up where we left off."

Quick actions: "Start readiness check" | "What did I miss?" | "Adjust my plan"
```

---

## 8. Edge Case Flows

### 8.1 Low Battery (<20%)

**Behavior:** No special UI changes. The coaching system does not check battery state. However:
- Disable confetti particle animation (GPU-intensive)
- Reduce typing indicator from 3 dots to 1 dot pulsing
- Skip the screen flash on PR (keep haptic + badge + message)

**Rationale:** Battery anxiety is the user's concern. The app should not add to it with warnings or reduced functionality. Just be lighter.

### 8.2 Slow Network (>3s LLM Response)

```
T+0.000s  Typing indicator appears.
T+3.000s  If no response yet: Typing indicator text changes to "Thinking..."
           Style: Inter, 12sp, w400, textMuted.
T+5.000s  If no response yet: Show deterministic fallback.
           Coach message: CoachSignal.deterministicDecision.
           Badge: "offline" chip.
           Background: The LLM request continues in the background.
T+8.000s  If LLM response arrives late: Message updates in place.
           Animation: AnimatedSwitcher, 300ms, easeOutCubic.
           Badge: "offline" chip fades out.
```

### 8.3 No Readiness Data (Skip Flow)

```
User skipped readiness check.
Coach message:
"Readiness check skipped. I'll build today's session on defaults.
You can always check in later — the data helps me coach better."

Quick actions: "Start with defaults" | "Actually, let me check in"
```

### 8.4 Pain Reported (Safety Guardrail)

**Workflow ID:** `pain_or_injury_guardrail`
**Persona:** Zen (always, regardless of other context)
**Confidence:** 0.91

```
Coach message:
"Pain was reported last session: '{painNote}'.
Today's plan is conservative: stop at sharp pain, reduce load,
use a pain-free variation. No load increase until the next set is pain-free."

Quick actions: "Show pain-free alternatives" | "I'm feeling better" | "Skip today"

Left border: accentDanger (#EF4444), 2px.
Message background: surfaceGlass with 4% accentDanger tint.
```

**If user taps "I'm feeling better":**
```
Coach message:
"Good to hear. Start with the same weight as last session.
If the first set is pain-free, you can proceed normally.
Stop immediately if pain returns."

Quick actions: "Start session" | "I'll do a light session"
```

### 8.5 Coasting Detected (Low RPE, High Readiness)

**Workflow ID:** `coasting_or_overreaching`
**Persona:** Challenger (always)
**Confidence:** 0.84

```
Coach message:
"{sets} sets logged, averaging RPE {avgRPE}/10.
That's below the target. Raise intent or close the session cleanly.
The data says you have more in you."

Quick actions: "Go heavier" | "Add a set" | "I'm done"

Left border: accentDanger (#EF4444), 2px.
```

### 8.6 Overreaching Detected (Volume Spike >60%)

**Workflow ID:** `coasting_or_overreaching`
**Persona:** Challenger
**Confidence:** 0.87

```
Coach message:
"Volume jumped from {prev}kg to {current}kg.
That's a {delta}% increase — more than the safe threshold.
Hold the next session steady so progress compounds without recovery debt."

Quick actions: "Hold volume next time" | "I planned this" | "Show my trend"
```

### 8.7 App Backgrounded During Active Session

**Behavior:**
- Rest timer continues counting (using `IsolateNameServer` or background timer)
- If app returns after >30 minutes: Show a "Welcome back" coach message
- Coach message: "You've been away for {minutes} minutes. The rest timer continued. Ready to resume?"
- Quick actions: "Resume" | "End session"

### 8.8 Multiple Rapid Taps (Debounce)

**Behavior:**
- Stepper taps: Debounce at 100ms. Only the last tap in a 100ms window is processed.
- "Log Set" button: Disable for 500ms after first tap. Show a subtle opacity reduction (0.6) during cooldown.
- Quick action chips: Disable for 300ms after tap. Same opacity treatment.

### 8.9 Screen Rotation During Animation

**Behavior:**
- All animations use `AnimatedBuilder` tied to `AnimationController` — they survive rotation.
- Confetti particles: Reset position on rotation (new coordinate system).
- Chat messages: `ListView.builder` with `key: ValueKey(message.id)` preserves scroll position.
- Coach bubble max-width: Recalculated as 85% of new screen width.

---

## 9. Accessibility

### 9.1 Semantic Labels

Every interactive element has a `Semantics` widget with:
- `label`: Descriptive text (e.g., "Log set, 80kg for 10 reps")
- `button: true` for tappable elements
- `liveRegion: true` for coach messages (announced by screen reader)

### 9.2 Reduced Motion

If `MediaQuery.disableAnimations` is true:
- All animations are instant (0ms)
- Confetti is replaced with a static PR badge
- Typing indicator is replaced with "Coach is typing..." text
- Breathing circle is static
- Haptics are preserved (they are not visual motion)

### 9.3 Font Scaling

All text uses the Digital Atelier text theme with `MediaQuery.textScaleFactor`:
- Minimum readable size: 12sp (after scaling)
- Coach messages: Playfair, 16sp base (scales to user preference)
- Data values: Inter, 32sp base (scales, but capped at 48sp to prevent layout breakage)

### 9.4 Color Contrast

All text passes WCAG AA on the dark background (#0A0A0A):
- #FFFFFF on #0A0A0A: 19.3:1 ✓
- #9CA3AF on #0A0A0A: 7.1:1 ✓
- #8B95A5 on #0A0A0A: 5.9:1 ✓
- Persona accent colors are used for borders and indicators, never as sole text color on dark backgrounds.

---

## 10. Implementation Notes

### 10.1 Widget Architecture

```
lib/features/coaching/
├── widgets/
│   ├── coach_bubble.dart          — Message bubble with persona border
│   ├── typing_indicator.dart      — 3-dot breathing indicator
│   ├── quick_action_chips.dart    — Staggered chip row
│   ├── readiness_circle.dart      — Animated score circle
│   ├── pr_celebration.dart        — Confetti + badge overlay
│   ├── rest_timer.dart            — Breathing circle timer
│   ├── set_log_row.dart           — Animated set entry
│   ├── wellness_checkin.dart      — Emoji + slider + body map
│   └── body_map.dart              — SVG tappable body silhouette
├── screens/
│   ├── coach_chat_screen.dart     — Full chat interface
│   └── wellness_screen.dart       — Daily check-in flow
├── animations/
│   ├── confetti_painter.dart      — CustomPainter for particles
│   ├── stagger_animation.dart     — Reusable stagger helper
│   └── breathing_animation.dart   — Circle pulse controller
└── utils/
    └── haptic_manager.dart        — Debounced haptic dispatch
```

### 10.2 State Management

```dart
// Coach messages: Riverpod Notifier (existing)
final chatMessagesProvider = NotProvider<List<CoachMessage>>(...);

// Active persona: Derived from PersonaSelection (existing)
final activePersonaProvider = Provider<PersonaSelection>((ref) {
  final ctx = ref.watch(personaContextProvider);
  return selectPersona(ctx);
});

// Typing state: simple StateProvider
final isTypingProvider = StateProvider<bool>((ref) => false);

// PR detection: Derived from session state
final isPRProvider = Provider<bool>((ref) {
  final session = ref.watch(activeSessionProvider);
  return session?.lastLoggedSet?.isPR ?? false;
});
```

### 10.3 Performance Budget

| Metric | Target | Notes |
|--------|--------|-------|
| First meaningful paint | <500ms | Coach bubble visible |
| Set log response | <100ms | Haptic + animation start |
| PR detection | <50ms | In-memory comparison |
| Chat scroll | 60fps | ListView.builder with keys |
| Confetti frame rate | 30fps | Reduced particle count on low-end |
| LLM response display | <200ms after arrival | Stream tokens directly |

---

## 11. Doctrine Compliance Checklist

Every coaching interaction must pass these doctrine laws:

- [ ] **L1-2:** Persona is one of Motivator/Analyst/Challenger/Expertise
- [ ] **L1-3:** Tone-arc directive share matches day-since-start phase
- [ ] **L1-7:** Message contains specific data token (number, trend, observation)
- [ ] **L1-8:** No generic encouragement ("You got this!", "Crush it!", etc.)
- [ ] **L1-10:** Coach audits its own stance (meta-cognition: persona adjusts with readiness/fatigue)
- [ ] **L2-5:** No body-shaming language
- [ ] **L2-7:** Confront without shame (Challenger is direct, not cruel)
- [ ] **L-SEC:** No medical advice, no supplement recommendations, no diagnosis
- [ ] **copy_safety:** Passes `coachSignalCopyIsGateSafe()` (no banned terms, no emoji)
- [ ] **data_token:** Message contains at least one reference to user data
- [ ] **source_trace:** CoachSignal has ≥3 source IDs
- [ ] **ux_trace:** CoachSignal has ≥2 UX principle IDs

---

*Document ends. This is the implementation spec for TransformFit's premium coaching experience. Every pixel, every haptic, every word is intentional.*
