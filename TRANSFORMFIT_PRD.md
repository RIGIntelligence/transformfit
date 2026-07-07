# TransformFit — Product Requirements Document (PRD)

**Version:** 1.0
**Date:** July 6, 2026
**Author:** Mike Rodgers, RIG Intelligence Group
**Status:** Active Development

---

## 1. Executive Summary

TransformFit is an AI-powered fitness and wellness app that combines deterministic exercise science, LLM-backed conversational coaching, mental health integration, and wearable-driven adaptive intelligence in a single premium experience.

**The Problem:** No existing app combines all four pillars of health — physical training, nutrition, mental health, and behavioral coaching — in one cohesive experience. Users are forced to use 3-5 separate apps (Strong for logging, MacroFactor for nutrition, Whoop for recovery, Calm for mindfulness, a coach for accountability).

**The Solution:** TransformFit is the first app that treats the whole person. It's a coach, a tracker, a therapist, and a training partner — all in one beautifully designed, data-driven package.

**The Market:** $3.4B fitness app market growing to $33.6B by 2033. Target: 8,200 installs in first 6 months, $2,400/month revenue at month 6.

---

## 2. Design Philosophy

### Core Principle: "One Metric. One Action. Zero Noise."

Every screen in TransformFit follows one rule: **show the user ONE thing that matters, give them ONE action to take, and remove everything else.**

This is borrowed from:
- **Whoop**: Recovery circle IS the brand. One number tells you everything.
- **Strong**: The set table IS the workout. Log button IS the action.
- **MacroFactor**: The macro ring IS the nutrition. Food log IS the tracking.
- **Ladder**: The workout card IS the plan. Start button IS the action.

### Design Pillars

| Pillar | Inspired By | Manifestation |
|--------|-------------|---------------|
| **Adherence-Neutral** | MacroFactor | No red bars, no shame colors for missed goals. Neutral/green only. |
| **Data-Dense but Scannable** | Whoop + MacroFactor | Every screen leads with ONE hero metric. Supporting data is secondary. |
| **Friction-Free Logging** | Strong + MacroFactor | Set logging takes ≤2 taps. Food logging is copy-forward, not search-forward. |
| **Coaching Presence** | Ladder + MacroFactor | Coach messages feel like a real person, not a chatbot. |
| **Progress is Celebration** | Apple Fitness+ | Rings, streaks, and milestones use motion + haptics to reward consistency. |
| **Dark-First Luxury** | Whoop + Fitbod | Dark mode is the DEFAULT and ONLY mode. The dark canvas is the brand. |

### Anti-Patterns (Explicitly Rejected)

- ❌ Red/yellow "failure" indicators for missed macros or workouts
- ❌ Gamification that feels childish (no cartoon mascots, no "LEVEL UP!" modals)
- ❌ Cluttered dashboards with 8+ metrics visible at once
- ❌ Generic Material Design components without brand personality
- ❌ Light mode as default or even as an option
- ❌ Text-heavy screens without visual hierarchy
- ❌ Cards with borders (use surface color contrast instead)
- ❌ Orange used everywhere (accent is for CTAs only)

---

## 3. Visual Design System

### 3.1 Color Palette

```
Background:     #0A0A0A  (near-black canvas)
Surface:        #141414  (cards, containers)
Surface Elevated: #1C1C1C  (modals, sheets, bottom nav)
Surface Input:  #1C1C1C  (text fields, inputs)

Text Primary:   #FFFFFF  (pure white — headlines, body, data)
Text Secondary: #8E8E93  (iOS gray — captions, labels)
Text Tertiary:  #48484A  (muted — timestamps, metadata)

Accent:         #FF6B35  (warm orange — CTAs ONLY, max 2 per screen)
Success:        #30D158  (iOS green — completed sets, achievements)
Warning:        #FFD60A  (iOS yellow — caution states)
Error:          #FF453A  (iOS red — errors only, NOT for missed goals)
Info:           #0A84FF  (iOS blue — data, links)

Recovery Green: #30D158  (readiness 80-100)
Recovery Yellow:#FFD60A  (readiness 50-79)
Recovery Red:   #FF453A  (readiness 0-49)
```

**Usage Rules:**
- Accent (#FF6B35) appears on a maximum of 2 elements per screen
- All other elements use text colors on surface backgrounds
- Recovery colors are used ONLY for the recovery circle, nowhere else
- No gradients except the recovery circle ring

### 3.2 Typography

```
Font Family: Inter (all text except coach messages)
Coach Font:  Playfair Display (coach messages only)

Scale:
  Hero:     Inter 34px/1.0 Bold    (readiness score, PR numbers)
  H1:       Inter 28px/1.2 Semibold (screen titles)
  H2:       Inter 22px/1.3 Semibold (section headers)
  H3:       Inter 17px/1.3 Medium   (card titles)
  Body:     Inter 17px/1.5 Regular  (body text)
  Caption:  Inter 15px/1.4 Regular  (secondary text)
  Micro:    Inter 13px/1.3 Regular  (labels, badges)
  Coach:    Playfair 17px/1.4 Medium (coach messages only)

Data Typography (tabular figures enabled):
  Data XL:  Inter 56px/1.0 Bold    (recovery score in circle)
  Data LG:  Inter 34px/1.0 Bold    (macro numbers)
  Data MD:  Inter 24px/1.0 Semibold (metric values)
  Data SM:  Inter 17px/1.0 Medium   (inline data)
```

### 3.3 Spacing

```
Grid: 8px base unit

Scale: 4, 8, 12, 16, 20, 24, 32, 40, 48, 64

Named Constants:
  Screen Margin: 20px (left/right padding on all screens)
  Card Gap:      12px (gap between cards)
  Section Gap:   32px (gap between sections)
  Element Gap:   8px  (gap between elements within a card)
```

### 3.4 Components

**Card:**
- Background: surface (#141414)
- Border: NONE (use surface color contrast)
- Border radius: 12px
- Padding: 16px
- Shadow: none (depth via color contrast)

**Button (Primary):**
- Background: accent (#FF6B35)
- Text: #FFFFFF, Inter 17px Semibold
- Height: 50px
- Border radius: 12px
- Full-width on mobile
- Haptic: medium impact on tap

**Button (Secondary):**
- Background: surface (#141414)
- Text: textSecondary (#8E8E93), Inter 17px Medium
- Height: 50px
- Border radius: 12px
- Border: 1px surfaceBorder (#1E1E1E)

**Input:**
- Background: surfaceInput (#1C1C1C)
- Border: NONE when unfocused, 1px accent when focused
- Border radius: 10px
- Height: 48px
- Text: textPrimary (#FFFFFF)

**Chip:**
- Background: surface (#141414)
- Border: 1px surfaceBorder (#1E1E1E)
- Border radius: pill (999px)
- Padding: 8px 16px
- Text: textSecondary (#8E8E93), Inter 15px Medium
- Selected: accent background, white text

**Bottom Navigation:**
- Height: 56px
- Background: canvasDeep (#050505) with glass blur
- Icons only (no labels)
- Active: accent (#FF6B35) icon + 6px accent dot below
- Inactive: textTertiary (#48484A) icon
- Touch target: 44px minimum
- Tabs: Home, Workout, Coach, Profile

**Recovery Circle:**
- Diameter: 280px (home), 240px (wellness)
- Stroke width: 8px
- Ring: gradient from red (#FF453A) → yellow (#FFD60A) → green (#30D158)
- Score: Inter 56px Bold, white, centered
- Zone label: Inter 15px, textSecondary, below score
- Animation: fill from 0 to score over 800ms

**Macro Ring:**
- Diameter: 200px
- 3 arcs: Protein (#0A84FF), Carbs (#FFD60A), Fat (#FF453A)
- Center: calorie number, Inter 34px Bold
- Below: "of 2,400 kcal" in textSecondary
- Animation: fill from 0 to current over 600ms

---

## 4. Screen-by-Screen Specifications

### 4.1 Landing Screen (First Impression)

**Purpose:** Convert visitor to user in ≤10 seconds.

**Layout:**
```
┌─────────────────────────────────┐
│                                 │
│   [Hero Image: hero_workout.png │
│    full-screen background       │
│    with 70% dark overlay]       │
│                                 │
│   ┌───────────────────────────┐ │
│   │ "A coach who already      │ │
│   │  noticed."                │ │
│   │                           │ │
│   │  Inter 28px, white        │ │
│   │                           │ │
│   │ "Before you log a single  │ │
│   │  rep, we built your plan."│ │
│   │                           │ │
│   │  Inter 17px, #8E8E93      │ │
│   │                           │ │
│   │  ┌─────────────────────┐  │ │
│   │  │     BEGIN           │  │ │
│   │  │  (accent button)    │  │ │
│   │  └─────────────────────┘  │ │
│   │                           │ │
│   │  Sign in to existing      │ │
│   │  account                  │ │
│   │  (ghost button)           │ │
│   └───────────────────────────┘ │
│                                 │
└─────────────────────────────────┘
```

**Behavior:**
- Hero image loads instantly (pre-cached in assets)
- Title fades in at 0.3s
- Subtitle fades in at 0.6s
- Button pulses gently (1s cycle) to draw attention
- Tap "Begin" → button contracts (100ms haptic) → slide to intake
- No navigation bar visible
- No status bar (immersive)

**Content:**
- Headline: "A coach who already noticed."
- Subtitle: "Before you log a single rep, we built your plan."
- CTA: "Begin" (accent button)
- Secondary: "Sign in to existing account" (ghost button)

### 4.2 Intake Flow (8 Steps, ~2 Minutes)

**Purpose:** Gather enough data to build a personalized week-one plan.

**Steps:**
1. **Goals** — Multi-select: Build Strength, Get Fitter, Lose Fat, Build Muscle, Improve Mobility, Train for Sport
2. **Schedule** — Select days per week: 2, 3, 4, 5, 6
3. **Equipment** — Multi-select: Bodyweight, Dumbbells, Barbell, Kettlebells, Resistance Bands, Machines, Cables, Pull-up Bar
4. **Experience** — Select: Beginner, Intermediate, Advanced
5. **Injuries** — Optional multi-select: None, Knee, Back, Shoulder, Wrist, Hip, Ankle
6. **Returning** — Optional: Are you returning from a break? (Yes/No + duration)
7. **Doctor Clearance** — Optional: Has a doctor cleared you? (Yes/No/NA)
8. **Consent** — Data usage consent + privacy policy link

**Design:**
- Progress indicator: "Step 3 of 8" with animated dots
- Each step is a single question with large tappable options
- Back button always visible
- Next button disabled until selection made
- Questions animate in from bottom (300ms)
- No paywall, no signup required until plan reveal

### 4.3 Plan Reveal (The "Wow" Moment)

**Purpose:** Show the user their personalized plan and make them feel the app already knows them.

**Layout:**
```
┌─────────────────────────────────┐
│                                 │
│  [Coach avatar with persona]    │
│                                 │
│  "Based on your goals,          │
│   equipment, and schedule,      │
│   here's your first week."      │
│                                 │
│  ┌───────────────────────────┐  │
│  │  Week 1 Plan              │  │
│  │  ─────────────────        │  │
│  │  Mon: Push Day (45 min)   │  │
│  │  Tue: Rest                │  │
│  │  Wed: Pull Day (45 min)   │  │
│  │  Thu: Rest                │  │
│  │  Fri: Legs (50 min)       │  │
│  │  Sat: Rest                │  │
│  │  Sun: Rest                │  │
│  └───────────────────────────┘  │
│                                 │
│  ┌─────────────────────────┐    │
│  │   START MY FIRST WORKOUT│    │
│  │   (accent button)       │    │
│  └─────────────────────────┘    │
│                                 │
└─────────────────────────────────┘
```

**Behavior:**
- Plan appears with staggered animation (each day slides in, 100ms delay)
- Coach message is personalized to their goals
- "Start My First Workout" button is the only CTA
- Tapping it goes directly to the workout (no signup wall)

### 4.4 Home Screen (Daily Hub)

**Purpose:** Show ONE number that tells the user how they're doing today.

**Layout:**
```
┌─────────────────────────────────┐
│  [hero_ai_coach.png background  │
│   with 85% dark overlay]        │
│                                 │
│         ┌─────────┐             │
│        /   78      \            │
│       /   RECOVERY  \           │
│       \             /           │
│        \           /            │
│         └─────────┘             │
│     ● Maintaining               │
│                                 │
│  ┌──────────┐ ┌──────────┐     │
│  │ 🏋️ Start │ │ 😊 Log   │     │
│  │ Workout  │ │ Mood     │     │
│  └──────────┘ └──────────┘     │
│  ┌──────────┐                  │
│  │ 💬 Coach │                  │
│  │ Chat     │                  │
│  └──────────┘                  │
│                                 │
│  ┌─────────────────────────┐   │
│  │ "You've been consistent │   │
│  │  this week. Keep it up."│   │
│  │  — Your Coach           │   │
│  └─────────────────────────┘   │
│                                 │
│  [Home] [Workout] [Coach] [Profile] │
└─────────────────────────────────┘
```

**Behavior:**
- Recovery circle animates from 0 to score (800ms)
- 3 action cards below: Start Workout (orange), Log Mood (purple), Coach Chat (blue)
- Coach hint at bottom: one line, personalized
- Pull-to-refresh to update recovery score
- No section headers, no weekly summary (moved to Progress tab)

### 4.5 Workout Logger (The Core Experience)

**Purpose:** Log a set in ≤2 taps. Show previous data for reference.

**Layout:**
```
┌─────────────────────────────────┐
│  ← Barbell Back Squat       →   │
│  Set 2 of 4    ●●○○              │
│                                 │
│  SET  PREV   WEIGHT  REPS   ✓   │
│  1    80kg   80kg    5     ✅   │
│  2    80kg   82.5kg  5     ☐   │
│  3    80kg   —       —     ☐   │
│  4    80kg   —       —     ☐   │
│                                 │
│       ┌─────┐                   │
│       │82.5 │                   │
│       │ kg  │                   │
│  [-]  └─────┘  [+]              │
│       ┌─────┐                   │
│       │  5  │                   │
│       │reps │                   │
│  [-]  └─────┘  [+]              │
│                                 │
│  ┌─────────────────────────┐   │
│  │        LOG SET          │   │
│  │    82.5kg × 5 reps      │   │
│  └─────────────────────────┘   │
│                                 │
│  Sets: 1/4  Vol: 400kg  0:32   │
└─────────────────────────────────┘
```

**Behavior:**
- Exercise name at top with prev/next arrows
- Progress dots: filled = completed, empty = remaining
- Set table: Strong-style with previous data in muted text
- Current set highlighted with accent left border
- +/- buttons: 48px touch targets, haptic light impact
- Number animation on change (200ms spring curve)
- "Log Set" button: full-width, accent, 56px height
- After logging: row slides in from right (300ms), green flash (200ms)
- Rest timer starts automatically (breathing badge in bottom bar)
- Coach message slides up: "Good set. RPE 7. Keep the weight here."
- PR celebration: confetti + haptic heavy impact + "NEW PR!" badge
- Pain safety mode: red border, weight ceiling, RPE capped at 6

### 4.6 Coach Chat (The Relationship)

**Purpose:** Feel like texting a real coach, not chatting with a bot.

**Layout:**
```
┌─────────────────────────────────┐
│  Coach                    ⚙️    │
│                                 │
│  ┌─────────────────────────┐   │
│  │ Hey. I noticed you've   │   │
│  │ been pushing hard this  │   │
│  │ week. How are you       │   │
│  │ feeling?                │   │
│  │           2:34 PM       │   │
│  └─────────────────────────┘   │
│                                 │
│         ┌──────────────────┐   │
│         │ Feeling strong.  │   │
│         │ Ready to go.     │   │
│         │ 2:35 PM          │   │
│         └──────────────────┘   │
│                                 │
│  ┌─────────────────────────┐   │
│  │ Good. Your readiness is │   │
│  │ 78 — you're in the      │   │
│  │ maintain zone. Today's  │   │
│  │ workout is set at RPE 7 │   │
│  │ to match your energy.   │   │
│  │           2:35 PM       │   │
│  └─────────────────────────┘   │
│                                 │
│  [How am I doing?] [What's next?]│
│                                 │
│  ┌──────────────────────┐ [→] │
│  │ Type a message...    │     │
│  └──────────────────────┘     │
│                                 │
│  [Home] [Workout] [Coach] [Profile] │
└─────────────────────────────────┘
```

**Behavior:**
- Coach messages: left-aligned, surface bg, 16px radius, Playfair font
- User messages: right-aligned, accent bg, 16px radius, Inter font
- Timestamps: 13px, textTertiary, below each message
- Typing indicator: 3 dots with persona color, 800ms
- Quick action chips: horizontal scroll above input
- Input: pill shape, surfaceInput bg, send button with accent
- Messages slide up from bottom (300ms)
- No confidence badges, no source counts (keep it clean)

**Coach Personas (6 voices):**

| Persona | Color | Voice Style | Example |
|---------|-------|-------------|---------|
| Motivator | Orange | Warm, encouraging | "You showed up. That's the hardest part." |
| Analyst | Blue | Data-driven, precise | "Your volume is 12% above your 4-week average." |
| Challenger | Red | Direct, high-bar | "That was RPE 6. You have more in you." |
| Zen | Purple | Calm, recovery-focused | "Recovery is training too. Honor the rest day." |
| Strength Coach | — | Evidence-based | "Evidence says 2-3 RIR is optimal for hypertrophy." |
| Neuroscientist | — | Protocol-focused | "Morning light exposure will improve your sleep tonight." |

### 4.7 Wellness Dashboard (Mental Health Hub)

**Purpose:** Show ONE number for overall wellness + 3 supporting metrics.

**Layout:**
```
┌─────────────────────────────────┐
│  [hero_mindfulness.png bg       │
│   with 85% dark overlay]        │
│                                 │
│         ┌─────────┐             │
│        /   72      \            │
│       /  WELLNESS   \           │
│       \             /           │
│        \           /            │
│         └─────────┘             │
│     ● Maintaining               │
│                                 │
│  ┌──────────┐ ┌──────────┐     │
│  │ 😊 Mood  │ │ 😰 Stress│     │
│  │   7/10   │ │   4/10   │     │
│  │  ↑ +0.5  │ │  ↓ -1.0  │     │
│  └──────────┘ └──────────┘     │
│  ┌──────────┐                  │
│  │ 😴 Sleep │                  │
│  │   8/10   │                  │
│  │  → same  │                  │
│  └──────────┘                  │
│                                 │
│  [Home] [Workout] [Coach] [Profile] │
└─────────────────────────────────┘
```

**Behavior:**
- Wellness circle animates from 0 to score (800ms)
- 3 metric cards: Mood, Stress, Sleep
- Each card: icon + value + trend arrow
- Tap card → detailed view with history
- Pull-to-refresh

### 4.8 Nutrition Dashboard (Macro Tracking)

**Purpose:** Show ONE number (calories) + 3 macros.

**Layout:**
```
┌─────────────────────────────────┐
│  [hero_nutrition.png bg         │
│   with 85% dark overlay]        │
│                                 │
│         ┌─────────┐             │
│        /  1,847    \            │
│       /   KCAL      \           │
│       \   of 2,400  /           │
│        \           /            │
│         └─────────┘             │
│                                 │
│  ┌──────────┐ ┌──────────┐     │
│  │ Protein  │ │ Carbs    │     │
│  │ 142g/180g│ │ 180g/250g│     │
│  │ ████░░   │ │ ███░░░   │     │
│  └──────────┘ └──────────┘     │
│  ┌──────────┐                  │
│  │ Fat      │                  │
│  │ 58g/75g  │                  │
│  │ ████░░   │                  │
│  └──────────┘                  │
│                                 │
│  Today's Food Log               │
│  ─────────────────              │
│  Breakfast: Oatmeal    420 kcal │
│  Lunch: Chicken Bowl   680 kcal │
│  Snack: Protein Shake  240 kcal │
│  Dinner: —             —        │
│                                 │
│         [+ Add Meal]            │
│                                 │
│  [Home] [Workout] [Coach] [Profile] │
└─────────────────────────────────┘
```

**Behavior:**
- Macro ring animates from 0 to current (600ms)
- 3 macro cards with progress bars
- Food log below with copy-forward from previous days
- "+ Add Meal" FAB button
- Barcode scanner for quick logging

### 4.9 Progress Dashboard (Charts & Data)

**Purpose:** Show progress over time with swipeable charts.

**Layout:**
```
┌─────────────────────────────────┐
│  Progress                       │
│  [Strength] [Volume] [Recovery] │
│                                 │
│  ┌─────────────────────────┐   │
│  │  ╭──────╮               │   │
│  │ ╱  1RM   ╲              │   │
│  │╱   Trend  ╲             │   │
│  │            ╲             │   │
│  │  Jan  Feb  Mar  Apr     │   │
│  └─────────────────────────┘   │
│                                 │
│  Current: 100kg (+5kg this month)│
│  PR: 105kg (Mar 15)             │
│                                 │
│  ┌─────────────────────────┐   │
│  │  Workout Heatmap         │   │
│  │  █████░░████████░░███░░  │   │
│  │  ██████████████████████  │   │
│  │  ░░████░░████░░████░░░░  │   │
│  └─────────────────────────┘   │
│                                 │
│  [Home] [Workout] [Coach] [Profile] │
└─────────────────────────────────┘
```

**Behavior:**
- Swipe between chart views (Strength, Volume, Recovery)
- Charts animate on first appearance
- Tap data points for details
- Pull-to-refresh

---

## 5. Interaction Flows

### 5.1 First-Time User (Day Zero)

```
0.0s  — App opens, dark canvas fades in
0.3s  — Hero image slides in from bottom
0.6s  — Title fades in: "A coach who already noticed"
0.9s  — Subtitle fades in: "Before you log a single rep, we built your plan"
1.2s  — Recovery circle animates in (0→score, 800ms)
1.5s  — "Begin" button pulses gently (1s cycle)
2.0s  — User taps "Begin"
2.1s  — Button contracts (100ms), haptic click
2.2s  — Screen transitions to intake (shared axis, 300ms)
...   — 8 intake steps (~2 minutes total)
...   — Plan reveal with staggered animation
...   — User taps "Start My First Workout"
...   — Workout logger opens with pre-filled exercises
```

### 5.2 Set Logging (Core Loop)

```
0.0s  — User taps "+" on weight stepper
0.05s — Number counter animates (200ms spring curve)
0.1s  — Haptic light impact
0.2s  — User taps "+" on reps stepper
0.25s — Number counter animates (200ms spring curve)
0.3s  — Haptic light impact
0.5s  — User taps "Log Set" button
0.55s — Button contracts (100ms), haptic medium impact
0.6s  — Set row slides in from right (300ms ease-out)
0.7s  — Green flash on the row (200ms)
0.8s  — Rest timer starts automatically (breathing circle appears)
0.9s  — Coach message slides up: "Good set. RPE 7. Keep the weight here."
1.2s  — Quick action chips appear: "Increase weight", "Same weight", "Decrease"
1.5s  — Rest timer pulses (1s breathing cycle)
```

### 5.3 PR Celebration

```
0.0s  — User logs a new PR (e.g., 100kg squat)
0.05s — Haptic heavy impact
0.1s  — Screen flashes white (100ms)
0.2s  — Confetti particles explode from the log button (1300ms)
0.3s  — PR badge slides down from top (500ms spring)
0.5s  — "NEW PR!" text scales up (300ms elastic)
0.8s  — Previous PR shown as comparison: "95kg → 100kg (+5.3%)"
1.0s  — Coach message: "That's a 5kg PR. You earned that."
1.3s  — Share button appears
1.5s  — Confetti fades out
2.0s  — Return to normal workout state
```

### 5.4 Daily Wellness Check-In

```
0.0s  — App opens, recovery circle animates (0→score, 800ms)
0.5s  — "How are you feeling?" prompt appears
0.8s  — 5 emoji buttons fade in (staggered 100ms): 😊 😐 😔 😤 😴
1.0s  — User taps 😊
1.1s  — Emoji scales up (200ms), haptic click
1.2s  — "What's your energy like?" slider appears
1.5s  — User slides to 7/10
1.6s  — Slider thumb pulses (100ms)
1.8s  — "Any soreness?" body map appears
2.0s  — User taps "Lower back"
2.1s  — Body part highlights (200ms)
2.3s  — "Got it. Adjusting your workout." appears
2.5s  — Recovery circle updates (300ms animation)
2.8s  — "Today's plan" card slides in with adjusted workout
```

---

## 6. Feature Specifications

### 6.1 AI Coaching System

**Architecture:** 3-layer system
1. **Deterministic Engine** — Progression algorithms, readiness calculations, plan generation
2. **LLM Narration Layer** — Natural language enrichment of deterministic decisions
3. **Safety Filter** — Gate-safe checks, banned terms, medical disclaimers

**Coach Personas:** 6 distinct voices that adapt over 30 days
- Week 1-2: 80% directive, 20% collaborative
- Week 3-4: 50% directive, 50% collaborative
- Month 2+: 20% directive, 80% collaborative

**Proactive Coaching:**
- After workout: "Good session. Volume is up 8% this week."
- After mood check-in: "I noticed your stress is elevated. Consider a lighter session."
- Streak at risk: "You've trained 5 days straight. Today's a rest day."
- PR achieved: "That's a 5kg PR. You earned that."

### 6.2 Readiness System

**Inputs:**
- HRV (from wearable or manual)
- Sleep quality (1-10)
- Mood score (1-10)
- Soreness level (1-10)
- Training load (7-day volume)

**Output:** Readiness score 0-100 with zone:
- 80-100: Push (green) — increase volume/intensity
- 50-79: Maintain (yellow) — keep current load
- 0-49: Deload (red) — reduce volume by 30-50%

**Behavior:**
- Readiness affects workout recommendations
- Low readiness → lighter alternatives suggested
- High readiness → progression opportunities highlighted

### 6.3 Gamification

**XP System:**
- Workout completed: 50 XP
- Set logged: 5 XP
- Mood logged: 10 XP
- Nutrition logged: 10 XP
- PR achieved: 25 XP
- Streak day: 15 XP

**Achievements:** 50+ across categories
- First workout, 7-day streak, 30-day streak, 100 workouts
- First PR, 10 PRs, bodyweight bench press
- 7-day mood streak, wellness score 80+

**Streaks:**
- Workout streak, mood streak, nutrition streak
- Grace days: 2 per week (configurable)
- Streak only breaks if consecutive misses > grace days

### 6.4 Nutrition Tracking

**Macro Tracking:**
- Protein, carbs, fat with daily targets
- Calorie target based on TDEE and goals
- Macro ring visualization (donut chart)
- Food log with copy-forward from previous days

**Barcode Scanner:**
- Scan food barcodes for instant logging
- Integration with food database (100+ common foods)
- Manual entry fallback

**Meal Planning:**
- 5 pre-built plans: High Protein, Balanced, Cut, Bulk, Vegetarian
- Custom meal creation
- Macro breakdown per meal

### 6.5 Mental Health Integration

**Daily Check-In:**
- Mood: 1-10 with emoji selector
- Energy: 1-10 slider
- Stress: 1-10 slider
- Soreness: body map selection
- Optional journal entry

**Mindfulness:**
- 10 guided meditation sessions (3-15 minutes)
- Breathing exercises with visual guide
- Body scan sessions

**Burnout Detection:**
- Combines training load + mood + sleep
- Alerts when burnout risk is high
- Recommends deload or rest day

### 6.6 Exercise Library

**Content:**
- 114 exercises with instructions, form cues, common mistakes
- 8 exercise images (squat, bench, deadlift, pull-up, plank, kettlebell, overhead press, yoga)
- Search by name, muscle group, equipment
- Filter by difficulty, type

**Exercise Cards:**
- 64x64 image thumbnail
- Exercise name, primary muscles
- Tap for full detail with instructions

---

## 7. Technical Architecture

### 7.1 Frontend

- **Framework:** Flutter 3.44+
- **State Management:** Riverpod
- **Navigation:** GoRouter with StatefulShellRoute
- **Local Database:** Drift (SQLite)
- **Design System:** DigitalAtelier v4

### 7.2 Backend

- **Database:** Supabase (PostgreSQL)
- **Auth:** Supabase Auth
- **Edge Functions:** 5 functions (coach-stream, generate-plan, post-session-analysis, auth-before-user-created, whoami)
- **Realtime:** Supabase Realtime for live data

### 7.3 AI/ML

- **LLM:** OpenAI-compatible API (configurable endpoint)
- **Fallback:** Deterministic coaching when LLM unavailable
- **Safety:** Gate-safe filter on all LLM outputs

### 7.4 Integrations

- **Wearables:** HealthKit (iOS), Health Connect (Android)
- **Analytics:** Custom event system (batch, offline support)
- **Crash Reporting:** Sentry stub (ready for real SDK)
- **Push Notifications:** Smart scheduler (max 3/day)

---

## 8. Success Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| User Acquisition | 8,200 installs in 6 months | App Store + Firebase |
| Day-1 Retention | 42% | Firebase Analytics |
| Day-7 Retention | 22% | Firebase Analytics |
| Day-30 Retention | 11% | Firebase Analytics |
| Free-to-Paid Conversion | 6.8% | Stripe |
| App Store Rating | 4.6/5.0 | App Store |
| Monthly Revenue (M6) | $2,400 | Stripe |
| NPS Score | +38 | In-app survey |
| Time to PMF | 3 iterations (9 months) | Sean Ellis test |

---

## 9. Competitive Positioning

| Feature | TransformFit | MacroFactor | Whoop | Strong | Ladder |
|---------|-------------|-------------|-------|--------|--------|
| AI Coaching | ✅ 6 personas | ❌ | ❌ | ❌ | ❌ |
| Mental Health | ✅ Full suite | ❌ | ❌ | ❌ | ❌ |
| Nutrition | ✅ Macro tracking | ✅ Best-in-class | ❌ | ❌ | ❌ |
| Workout Logging | ✅ Strong-style | ❌ | ❌ | ✅ Best-in-class | ✅ |
| Recovery Score | ✅ Whoop-style | ❌ | ✅ Best-in-class | ❌ | ❌ |
| Behavioral Repair | ✅ Unique | ❌ | ❌ | ❌ | ❌ |
| Exercise Library | ✅ 114 exercises | ❌ | ❌ | ❌ | ❌ |
| Gamification | ✅ XP + achievements | ❌ | ❌ | ❌ | ❌ |
| Wearable Integration | ✅ HealthKit/Connect | ❌ | ✅ Hardware-locked | ❌ | ❌ |

**Unique Position:** Only app combining AI coaching + mental health + nutrition + workout logging + recovery scoring in one cohesive experience.

---

## 10. Launch Plan

### Phase 1: MVP (Current)
- Core workout logging
- AI coaching (deterministic)
- Basic wellness tracking
- Exercise library
- Web + Android builds

### Phase 2: Polish (Weeks 1-4)
- Design system v4 implementation
- Hero imagery integration
- Recovery circle as brand element
- Macro ring for nutrition
- Coach chat refinement

### Phase 3: Growth (Weeks 5-8)
- Social features (share, challenges)
- Camera form check (ML)
- Push notifications
- Crash reporting
- Analytics backend

### Phase 4: Scale (Weeks 9-12)
- iOS native build
- App Store launch
- Product Hunt launch
- Reddit/HN launch
- Influencer outreach

---

## Appendix A: Higgsfield Imagery

17 cinematic images generated via Higgsfield AI:

| Image | Description | Usage |
|-------|-------------|-------|
| hero_workout.png | Dramatic gym, orange/purple lighting | Landing screen background |
| hero_ai_coach.png | Neural network silhouette | Home screen background |
| hero_mindfulness.png | Blue/purple ambient, breathing | Wellness dashboard background |
| hero_nutrition.png | Dark marble meal prep | Nutrition dashboard background |
| hero_gamification.png | Golden trophies, XP particles | Gamification background |
| hero_sleep.png | Luxury dark bedroom | Sleep/recovery background |
| hero_barbell.png | Chalk dust, dramatic light | App bar texture |
| hero_app_mockup.png | Floating phone, holographic | Marketing materials |
| hero_app_store.png | 3-screen mockup | App Store listing |
| exercise_squat.png | Dramatic gym, orange rim light | Exercise library |
| exercise_bench_press.png | Overhead lighting | Exercise library |
| exercise_deadlift.png | Side lighting, chalk dust | Exercise library |
| exercise_pullup.png | Purple backlighting | Exercise library |
| exercise_plank.png | Low-angle, warm orange | Exercise library |
| exercise_kettlebell.png | Orange backlighting | Exercise library |
| exercise_yoga.png | Blue/purple ambient | Exercise library |
| exercise_overhead_press.png | Top-down lighting | Exercise library |

## Appendix B: Design Documents

- `TRANSFORMFIT_DESIGN_SYSTEM_SPEC.md` — 1,942 lines, full design system
- `DESIGN_SYSTEM_V4.md` — 1,359 lines, binding v4 spec
- `UI_REDESIGN_SPEC.md` — 50KB, screen-by-screen redesign
- `COMPETITIVE_DESIGN_COMPARISON.md` — Side-by-side with competitors
- `COACHING_INTERACTION_DESIGN.md` — 1,115 lines, second-by-second flows
- `COMPETITIVE_ANALYSIS_100.md` — 100-feature gap analysis
- `USER_PANEL_REPORT.md` — 100 scenarios tested
- `UX_UI_AUDIT_REPORT.md` — 20 priority fixes
- `MIROFISH_PREDICTION_REPORT.md` — Market success predictions
- `TRANSFORMFIT-1000X-UPGRADE-PLAN.md` — Master architecture plan

## Appendix C: Mathematical Design Formulas

- **Golden Ratio (φ = 1.618):** Typography scale, card aspect ratios, layout proportions
- **Fibonacci Sequence:** Spacing (3,5,8,13,21,34,55), font sizes, border radius, animation durations
- **Modular Scale (1.25 ratio):** Typography hierarchy
- **8-Point Grid:** All spacing multiples of 8
- **Rule of Thirds:** Hero 2/3, supporting 1/3
- **Bee Foraging:** Visual attention allocation (60/25/15)

## Appendix D: Deviation Engine Applications

40 RIG Deviation Engines applied to design:
- **Physics (31-40):** Quantum tunneling, Pauli exclusion, Casimir pressure, fine-tuning, Hawking radiation, speed of light, absolute zero, phase transition, Bell entanglement, vacuum fluctuation
- **Cognitive (01-20):** Gravity escape, reality anchor, Feynman X-ray
- **Nature (21-30):** Ant colony, bee foraging, slime mold

---

*This PRD is the single source of truth for TransformFit. Every design decision, feature, and interaction should be traceable back to this document.*
