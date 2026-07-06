# TransformFit UI Redesign Specification

> **Goal:** Transform TransformFit from "developer-built" to "designer-built" — matching the quality bar of Strong (4.9★ minimal), Whoop (data-viz-as-brand), and MacroFactor (Pentagram typography).
>
> **Scope:** Visual presentation only. All business logic, Riverpod providers, engines, and data models stay exactly as-is. Only the widget trees, layout, and styling change.

---

## Part 0: Design Principles

These six principles govern every screen. If a design decision conflicts with one of these, the principle wins.

### 0.1 One Thing Per Screen

Strong shows one exercise at a time. Whoop shows one metric. Overloading a screen with 5+ cards forces the user to scan instead of act.

**Rule:** Every screen has ONE hero element that takes ≥50% of the viewport. Everything else is secondary.

### 0.2 Data IS the Design

Whoop's recovery circle IS the brand. MacroFactor's macro ring IS the experience. Data visualization isn't decoration — it's the primary visual element.

**Rule:** On every data screen, the largest visual element must be a data visualization, not a card, header, or illustration.

### 0.3 Restrained Color

Strong uses black + white + one accent. We currently use orange everywhere — gradient decorations, tinted shadows, persona badges, accent text. This dilutes impact.

**Rule:** Orange (`accentPrimary`) appears in exactly 3 places per screen maximum:
1. The primary CTA button
2. The active navigation indicator
3. One optional accent (data highlight, live badge)

Everything else: white text, gray secondary text, surface-colored backgrounds.

### 0.4 Professional Typography

MacroFactor hired Pentagram. Their type scale is the product's identity. We currently mix Playfair and Inter inconsistently — titles use Playfair (serif), body uses Inter, data uses Inter with random weights.

**Rule:** Inter for everything except coach voice. Playfair only inside chat messages. One font for all UI chrome.

### 0.5 Whitespace is a Feature

Apple Fitness+ uses generous spacing. We're too dense — cards sit 12px apart with 16px padding. The result feels like a spreadsheet.

**Rule:** Breathing room is intentional. Screen margins: 20px. Section gaps: 24px. Card gaps: 16px. Card internal padding: 20px.

### 0.6 Purposeful Animation

Every animation must communicate state change, not just look cool. Our current `elevationLow` shadows have orange tint (`Color(0x1AF97316)`) — that's decorative, not communicative.

**Rule:** Animations exist only for:
- Loading → content transitions (skeleton → real data)
- State changes (set logged → rest timer starts)
- Progress feedback (ring fills, streak increments)

No bounce, no elastic overshoot, no celebration animations.

---

## Part 1: Design Token Changes

### File: `lib/theme/digital_atelier.dart`

The current `DigitalAtelierExtension` has a solid structure. We keep it but reassign values.

#### 1.1 Color System Overhaul

```
CURRENT → NEW

Background & Surface (unchanged — these are already clean):
  background:     0xFF0A0A0A  →  0xFF0A0A0A  (no change)
  surface:        0xFF111111  →  0xFF111111  (no change)
  surfaceElevated: 0xFF1A1A1A →  0xFF1A1A1A  (no change)
  surfaceInput:   0xFF151515  →  0xFF151515  (no change)
  surfaceBorder:  0xFF1E1E1E  →  0xFF1A1A1A  (subtler — borders nearly invisible)
  surfaceDivider: 0xFF252525  →  0xFF222222  (subtler)

Accent Colors (RESTRICT — reduce orange proliferation):
  accentPrimary:  0xFFF97316  →  0xFFF97316  (no change — CTA only)
  accentSecondary: 0xFF8B5CF6 →  0xFF8B5CF6  (no change — secondary CTA)
  accentTertiary: 0xFF10B981  →  0xFF10B981  (no change — success states only)
  accentDanger:   0xFFEF4444  →  0xFFEF4444  (no change)
  accentInfo:     0xFF3B82F6  →  0xFF3B82F6  (no change)

Text Colors:
  textPrimary:    0xFFF0EDE8  →  0xFFFFFFFF  (pure white — stronger contrast)
  textSecondary:  0xFF9CA3AF  →  0xFF9CA3AF  (no change)
  textMuted:      0xFF8B95A5  →  0xFF6B7280  (muted — push further back)
  textInverse:    0xFF0A0A0A  →  0xFF0A0A0A  (no change)

Semantic Colors:
  success:  0xFF10B981  (no change)
  warning:  0xFFF59E0B  (no change)
  recovery: 0xFF8B5CF6  (no change)
  calm:     0xFF6366F1  (no change)
```

#### 1.2 Remove All Gradient Presets

Delete from `DigitalAtelierTokens2`:
- `heroGradient` (orange → purple)
- `recoveryGradient` (blue → purple)
- `progressGradient` (green → blue)
- `heroGradientDecoration`
- `recoveryGradientDecoration`
- `progressGradientDecoration`

Delete from `DigitalAtelierTokens2`:
- `elevationLow` (orange-tinted shadow)
- `elevationMedium` (orange-tinted shadow)
- `elevationHigh` (orange-tinted shadow)

Replace with neutral elevation:
```dart
static const List<BoxShadow> elevationLow = [
  BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2)),
];
```

#### 1.3 Typography Scale

Restructure `TransformFitTextTheme` with clear naming:

```dart
// NEW Typography Scale — Inter-dominant

// Screen title — the biggest text on a screen
// Usage: AppBar title, hero metric label
static const TextStyle h1 = TextStyle(
  fontFamily: 'Inter',
  fontSize: 24,
  fontWeight: FontWeight.w600,
  height: 1.2,
  color: textPrimary,
);

// Section header — major section within a screen
// Usage: "Today's Plan", "Macros", "Progress"
static const TextStyle h2 = TextStyle(
  fontFamily: 'Inter',
  fontSize: 18,
  fontWeight: FontWeight.w500,
  height: 1.3,
  color: textPrimary,
);

// Card title — within a card or group
// Usage: Exercise name, metric label
static const TextStyle h3 = TextStyle(
  fontFamily: 'Inter',
  fontSize: 16,
  fontWeight: FontWeight.w600,
  height: 1.3,
  color: textPrimary,
);

// Body text — primary reading
static const TextStyle body = TextStyle(
  fontFamily: 'Inter',
  fontSize: 15,
  fontWeight: FontWeight.w400,
  height: 1.5,
  color: textPrimary,
);

// Body small — secondary text, descriptions
static const TextStyle bodySmall = TextStyle(
  fontFamily: 'Inter',
  fontSize: 13,
  fontWeight: FontWeight.w400,
  height: 1.4,
  color: textSecondary,
);

// Label — uppercase labels, tags, badges
static const TextStyle label = TextStyle(
  fontFamily: 'Inter',
  fontSize: 11,
  fontWeight: FontWeight.w600,
  letterSpacing: 1.0,
  height: 1.2,
  color: textMuted,
);

// Data display — large numeric values (scores, weights, reps)
// Uses tabular figures for aligned columns
static const TextStyle dataLarge = TextStyle(
  fontFamily: 'Inter',
  fontSize: 32,
  fontWeight: FontWeight.w700,
  letterSpacing: -0.5,
  height: 1.1,
  fontFeatures: [FontFeature.tabularFigures()],
  color: textPrimary,
);

// Data medium — secondary numeric values
static const TextStyle dataMedium = TextStyle(
  fontFamily: 'Inter',
  fontSize: 20,
  fontWeight: FontWeight.w700,
  letterSpacing: -0.3,
  height: 1.2,
  fontFeatures: [FontFeature.tabularFigures()],
  color: textPrimary,
);

// Data small — inline numbers (set counts, reps, small metrics)
static const TextStyle dataSmall = TextStyle(
  fontFamily: 'Inter',
  fontSize: 14,
  fontWeight: FontWeight.w600,
  fontFeatures: [FontFeature.tabularFigures()],
  color: textPrimary,
);

// Coach voice — ONLY used inside chat message bubbles
static const TextStyle coachVoice = TextStyle(
  fontFamily: 'Playfair',
  fontSize: 16,
  fontWeight: FontWeight.w500,
  height: 1.5,
  color: textPrimary,
);
```

#### 1.4 Spacing Scale Update

```dart
// Current → New (slightly more generous)
spaceXs:   4   →  4    (unchanged)
spaceSm:   8   →  8    (unchanged)
spaceMd:   12  →  16   (was 12, now 16 — more breathing room)
spaceLg:   16  →  20   (was 16, now 20 — screen margins)
spaceXl:   24  →  24   (unchanged — section gaps)
spaceXxl:  32  →  32   (unchanged)
spaceXxxl: 48  →  48   (unchanged)
spaceHuge: 64  →  64   (unchanged)

// NEW: Named aliases for clarity
static const double screenMargin = 20;  // horizontal padding on all screens
static const double cardGap = 16;       // gap between cards
static const double sectionGap = 24;    // gap between sections
static const double cardPadding = 20;   // internal card padding
```

#### 1.5 Component Presets Update

```dart
// Card — NO border, just surface background
BoxDecoration get cardDecoration => BoxDecoration(
  color: surface,
  borderRadius: BorderRadius.circular(radiusMd),
  // NO border — use elevation/surface color to distinguish
);

// Card elevated — slightly lighter surface
BoxDecoration get cardElevated => BoxDecoration(
  color: surfaceElevated,
  borderRadius: BorderRadius.circular(radiusMd),
);

// Input field
BoxDecoration get inputDecoration => BoxDecoration(
  color: surfaceInput,
  borderRadius: BorderRadius.circular(radiusSm),
);

// Chip — pill shaped, surface bg
BoxDecoration get chipDecoration => BoxDecoration(
  color: surface,
  borderRadius: BorderRadius.circular(radiusPill),
);
```

---

## Part 2: Screen-by-Screen Redesign

### 2.1 Home Screen (Today)

**File:** `lib/screens/home_screen.dart`

#### Current State (What's Wrong)

- 5 vertically stacked cards: ReadinessScoreCard, TodaysPlanCard, CoachInsightCard, QuickActionsRow, WeeklySummaryCard
- Each card has: icon + title + body + optional action row
- Cards use `_HomeCard` wrapper with surface bg + border + shadow
- Quick action icons are orange (4 orange icons in a row)
- Weekly summary has 3 stat columns with dividers
- Layout is scrollable but all content is above the fold only if viewport is tall

**Problems:** Too many cards. No hero element. Orange everywhere. No data visualization.

#### Target Design

**Inspiration:** Whoop home screen — one massive recovery circle + 3 compact action cards.

#### New Layout

```
┌─────────────────────────────┐
│  Today                      │  ← h1, 20px margin, 24px top padding
│                             │
│                             │
│       ┌───────────┐         │
│       │           │         │
│       │   82      │         │  ← Hero: Readiness Ring (60% viewport)
│       │           │         │     TfProgressRing, size=200, strokeWidth=10
│       └───────────┘         │     Score in dataLarge (32px)
│       Peak                  │  ← Zone label in label style (uppercase, muted)
│                             │
│                             │
│  ┌──────┐ ┌──────┐ ┌──────┐│
│  │  ▶   │ │  ●   │ │  ◉   ││  ← 3 Action Cards (equal width, 16px gap)
│  │Work  │ │Coach │ │Well  ││     Each: icon + label, surface bg, no border
│  │out   │ │      │ │ness  ││     Tap navigates to that section
│  └──────┘ └──────┘ └──────┘│
│                             │
│  Coach: "Peak — go hard     │  ← Coach insight (single line, italic, muted)
│  today. Earn the last set." │     Playfair 14px, textSecondary
│                             │
└─────────────────────────────┘
```

#### What to Remove

| Current Element | Action | Reason |
|---|---|---|
| `ReadinessScoreCard` wrapper | Remove | Replace with bare ring (no card) |
| `TodaysPlanCard` | Merge into action card "Workout" | One-tap navigation |
| `CoachInsightCard` | Reduce to single line | Not a card — just a text line |
| `QuickActionsRow` (4 items) | Reduce to 3 items | Remove "Mood" and "Water" (merge into wellness) |
| `WeeklySummaryCard` | Move to Progress tab | Not today-relevant |
| Shimmer loading skeleton | Remove | Use simple spinner |

#### Widget Decomposition

```
HomeScreen (ConsumerWidget)
├── _HomeHeader                  // "Today" — keep as-is but use h1 style
├── _ReadinessHero               // NEW: centered ring + score + zone label
├── _ActionCards                  // NEW: 3 equal-width cards in a Row
│   ├── _ActionCard("Workout", Icons.fitness_center, → /workout)
│   ├── _ActionCard("Coach", Icons.chat_bubble_outline, → /coach-chat)
│   └── _ActionCard("Wellness", Icons.favorite_outline, → /wellness)
└── _CoachHint                   // NEW: single italic line from last coach message
```

#### Key Details

- **ReadinessHero**: The ring takes 60% of viewport height. Use `LayoutBuilder` to compute size. Score number is `dataLarge` style, centered inside ring. Zone label below ring in `label` style (uppercase, muted).
- **ActionCards**: Three containers in a `Row` with `Expanded`. Each has: icon (24px, `textSecondary`), label (`bodySmall`). Surface background, `radiusMd` corners. No border. Tap navigates via `context.push`.
- **CoachHint**: Single `Text` widget. Style: `bodySmall` with `fontStyle: FontStyle.italic`. Uses Playfair font. Max 1 line with ellipsis. Only shown if coach has sent a message.

---

### 2.2 Workout Logger

**File:** `lib/features/workout/active_workout_screen.dart`

#### Current State (What's Wrong)

- Exercise name as `TextField` with orange focus border
- Preset chips row (Warm-up, Previous, Plan, Swap) — 4 orange-outlined chips
- Set table: 6 columns (SET, WT, REPS, RPE, REST, LOG) with orange "Log" buttons
- +/- stepper controls for weight/reps/rpe with orange icons
- Coach insight card at bottom
- Rest countdown timer with breathing animation
- PR celebration with `AnimationController`
- Sticky bottom bar with pain safety + finish session

**Problems:** Too much chrome. 6-column table is dense. Orange everywhere. Coach insight during workout is distracting. Preset chips overwhelm.

#### Target Design

**Inspiration:** Strong app — minimal, fast, one exercise at a time.

#### New Layout

```
┌─────────────────────────────┐
│  ← Goblet Squat             │  ← Exercise name (h1, left-aligned)
│  Set 3 of 4                 │  ← Set progress (bodySmall, muted)
│                             │
│  ┌─────────────────────────┐│
│  │  SET   WEIGHT   REPS    ││  ← Table header (label style, uppercase)
│  │  ───────────────────── ││
│  │  1     40 kg    8       ││  ← Logged sets (dataSmall, muted)
│  │  2     40 kg    8       ││
│  │  3     __ kg    __      ││  ← Current set (dataMedium, white, editable)
│  └─────────────────────────┘│
│                             │
│  ┌─────────────────────────┐│
│  │  40 kg          8 reps  ││  ← Current values (large, tappable)
│  │  ▼  ▲           ▼  ▲   ││     Tapping value opens number input
│  └─────────────────────────┘│
│                             │
│  Previous: 40kg × 8 @ RPE 7│  ← Muted reference text (bodySmall)
│                             │
│  ┌─────────────────────────┐│
│  │      LOG SET            ││  ← Full-width CTA (accentPrimary bg, white text)
│  └─────────────────────────┘│     56px height, radiusPill
│                             │
│  ⏱ 1:30 rest               │  ← Rest timer (if active, inline below button)
└─────────────────────────────┘
```

#### What to Remove

| Current Element | Action | Reason |
|---|---|---|
| Exercise name `TextField` | Make read-only (tap to edit) | Distracting during set logging |
| Preset chips (Warm-up, Previous, Plan, Swap) | Move to overflow menu (⋮) | Overwhelming during workout |
| Coach insight card | Remove entirely | Distracting during workout |
| RPE column in table | Keep but simplify | Move to tap-to-edit on log |
| Rest column in table | Remove from table | Show inline timer after log |
| PR celebration animation | Remove | Replace with subtle haptic + color flash |
| Orange-tinted shadows | Remove | Use surface color differentiation |
| Breathing animation on rest timer | Remove | Use simple countdown number |

#### Widget Decomposition

```
ActiveWorkoutScreen (ConsumerStatefulWidget)
├── _ExerciseHeader              // Exercise name (h1) + set progress (bodySmall)
├── _SetTable                    // Full-width set log table
│   ├── _TableHeader             // SET | WEIGHT | REPS (label style)
│   └── _SetRows                 // Logged sets (muted) + current set (white)
├── _ValueSteppers               // Large weight/reps controls
├── _PreviousSetReference        // "Previous: 40kg × 8 @ RPE 7" — muted text
├── _LogButton                   // Full-width "LOG SET" CTA
└── _RestTimer                   // Inline countdown (shown after log)
```

#### Key Details

- **SetTable**: Full width, no card wrapper. Header row uses `label` style (uppercase, muted). Logged sets use `dataSmall` with `textMuted` color. Current set row uses `dataMedium` with `textPrimary` color. Use `Divider` between sets (not grid lines).
- **ValueSteppers**: Two large controls side by side. Each shows: value (dataLarge), unit label (bodySmall), -/+ buttons (44px touch targets, surface bg). Weight on left, reps on right. No RPE stepper on main screen (move to log dialog).
- **LogButton**: Full width, 56px height, `accentPrimary` background, white text, `radiusPill`. Below the steppers with 16px gap. On tap: log set, start rest timer, advance set counter.
- **RestTimer**: Appears inline below log button. Shows countdown (dataMedium), "Skip" text button (textSecondary). No animation — just number decrement.
- **PreviousSetReference**: Single line of muted text below steppers. "Previous: {weight}kg × {reps} @ RPE {rpe}". Only shown if previous data exists. Uses `bodySmall` style.
- **Overflow Menu**: Three-dot menu in AppBar for: Warm-up set, Apply previous, Apply plan target, Technique swap, Pain report, Finish session.

---

### 2.3 Coach Chat

**File:** `lib/features/coaching/coach_chat_screen.dart`

#### Current State (What's Wrong)

- Messages rendered as full-width cards with: persona badge, confidence label, source count, observation, next action
- Each coach message is 100-200px tall with metadata
- Quick action chips animated with stagger
- Typing indicator exists but is crude
- User messages are simple bubbles (good)
- AppBar shows persona initial + name + role

**Problems:** Messages are research reports, not chat. Confidence badges and source counts are noise. Persona indicators are distracting. Chat should feel like texting a friend who happens to be smart.

#### Target Design

**Inspiration:** Ladder coaching chat — clean bubbles, minimal metadata, warm.

#### New Layout

```
┌─────────────────────────────┐
│  Coach                      │  ← AppBar: just "Coach", no persona badge
│                             │
│  ┌─────────────────────┐    │
│  │ Welcome back. Today  │    │  ← Coach bubble: left-aligned
│  │ counts if the work   │    │     Surface bg, radiusMd, 20px max width 80%
│  │ matches your energy. │    │     Playfair 16px (coach voice font)
│  │ How are you feeling? │    │
│  └─────────────────────┘    │
│  2 min ago                  │  ← Timestamp (bodySmall, muted)
│                             │
│             ┌──────────────┐│
│             │ I feel great ││  ← User bubble: right-aligned
│             │ let's go     ││     accentPrimary bg, white text, radiusMd
│             └──────────────┘│
│                             │
│  ┌─────────────────────┐    │
│  │  ●  ●  ●            │    │  ← Typing indicator (3 pulsing dots)
│  └─────────────────────┘    │
│                             │
│  ┌─────────────────────────┐│  ← Quick actions: horizontal scroll
│  │ How am I doing? | What  ││     Chips with icons, surface bg
│  │ should I eat? | ...     ││     Above input bar
│  └─────────────────────────┘│
│  ┌─────────────────────────┐│
│  │  Type a message...   ▶  ││  ← Input bar: sticky bottom
│  └─────────────────────────┘│     SurfaceInput bg, radiusPill
└─────────────────────────────┘
```

#### What to Remove

| Current Element | Action | Reason |
|---|---|---|
| Persona badge (initial + color) | Remove from message | Coach is one voice |
| Confidence label ("82%") | Remove | Distracting, not actionable |
| Source count ("3 sources") | Remove | Clutter |
| Observation card | Remove | Not conversational |
| Next action card | Remove | Move to quick actions |
| Persona name in AppBar | Remove | Just "Coach" |
| Persona role subtitle | Remove | Not needed |
| Animated chip stagger | Remove | Instant is better |
| Send button bounce animation | Remove | Haptic feedback is enough |

#### Widget Decomposition

```
CoachChatScreen (ConsumerStatefulWidget)
├── AppBar                        // Simple: "Coach" title, no persona
├── _MessageList                  // Scrollable message area
│   ├── _CoachBubble              // Left-aligned, surface bg, Playfair font
│   ├── _UserBubble               // Right-aligned, accentPrimary bg
│   └── _Timestamp                // Below each message, muted, small
├── _TypingIndicator              // 3 pulsing dots (when coach is "typing")
├── _QuickActions                 // Horizontal scroll chips
└── _InputBar                     // Sticky bottom, pill-shaped input
```

#### Key Details

- **CoachBubble**: `Container` with `surface` background, `radiusMd` corners, max width 80% of screen. Text uses `coachVoice` style (Playfair 16px). Padding: 16px. No icon, no badge, no metadata.
- **UserBubble**: `Container` with `accentPrimary` background, `radiusMd` corners, max width 80%. Text uses `body` style, white color.
- **Timestamp**: `Text` widget below each message group. Style: `bodySmall` (13px, muted). Shows relative time ("2 min ago", "Yesterday").
- **TypingIndicator**: Three dots that pulse sequentially. Surface background, same alignment as coach bubble. Uses `AnimatedOpacity` on each dot (staggered 200ms).
- **QuickActions**: Horizontal `ListView` of chips. Each chip: icon (16px, textSecondary) + label (bodySmall). Surface background, `radiusPill`. Above input bar with 8px gap.
- **InputBar**: `Container` with `surfaceInput` background, `radiusPill` corners. `TextField` inside with hint "Type a message...". Send button: circular, `accentPrimary` background, white arrow icon. 44px touch target.

---

### 2.4 Wellness Dashboard

**File:** `lib/features/wellness/wellness_dashboard_screen.dart`

#### Current State (What's Wrong)

- Wellness score header: full-width card with score (64px Playfair), zone badge, progress bar
- 5 module cards: Mood, Stress, Sleep, Mindfulness, Burnout Risk — each with icon, status, score bar
- Recommendations card at bottom
- Uses `TfLoadingSkeleton` for loading state

**Problems:** Too many modules. No hero visualization. Linear progress bars aren't data-viz. Burnout Risk is a settings item, not a dashboard item.

#### Target Design

**Inspiration:** Whoop recovery circle — one massive number + 3 compact metrics.

#### New Layout

```
┌─────────────────────────────┐
│  Wellness                   │  ← AppBar: "Wellness", h1 style
│                             │
│                             │
│       ┌───────────┐         │
│       │           │         │
│       │   72      │         │  ← Hero: Wellness Ring (50% viewport)
│       │           │         │     TfProgressRing, zone-colored stroke
│       └───────────┘         │     Score in dataLarge
│       Maintaining           │  ← Zone label (label style, uppercase)
│       ↗ Trending up         │  ← Trend arrow + text (bodySmall)
│                             │
│                             │
│  ┌──────┐ ┌──────┐ ┌──────┐│
│  │  😊  │ │  🧘  │ │  😴  ││  ← 3 Metric Cards
│  │ 78   │ │ 62   │ │ 81   ││     Each: emoji/icon + score
│  │ Mood │ │Stress│ │Sleep ││     Label below, dataMedium score
│  └──────┘ └──────┘ └──────┘│
│                             │
│  ┌─────────────────────────┐│
│  │ 7-day trend: ●●●●●●●   ││  ← Mini sparkline per metric
│  └─────────────────────────┘│     (optional — can be v2)
│                             │
└─────────────────────────────┘
```

#### What to Remove

| Current Element | Action | Reason |
|---|---|---|
| 5 module cards | Reduce to 3 | Mood, Stress, Sleep are core |
| Mindfulness module | Move to settings | Not daily-use |
| Burnout Risk module | Move to settings | Background calculation |
| Recommendations card | Move to coach chat | Coach should surface these |
| Section header "Modules" | Remove | Not needed |
| Loading skeleton | Replace with spinner | Simpler |

#### Widget Decomposition

```
WellnessDashboardScreen (ConsumerStatefulWidget)
├── AppBar                        // "Wellness" — h1 style
├── _WellnessHero                 // Centered ring + score + zone + trend
├── _MetricCards                  // 3 equal-width cards in a Row
│   ├── _MetricCard("Mood", 78, moodIcon)
│   ├── _MetricCard("Stress", 62, stressIcon)
│   └── _MetricCard("Sleep", 81, sleepIcon)
└── _MiniSparklines               // Optional: 7-day trend dots per metric
```

#### Key Details

- **WellnessHero**: Ring uses `TfProgressRing` at 50% viewport height. Stroke color matches zone (green/blue/yellow/red). Score number centered inside in `dataLarge`. Zone label below in `label` style. Trend arrow: "↗ Trending up" in `bodySmall` with `success` color if positive, `warning` if negative.
- **MetricCards**: Three `Expanded` containers in a `Row` with 16px gaps. Each card: icon (28px, colored), score (dataMedium), label (bodySmall). Surface background, `radiusMd` corners, no border. Tap opens detail sheet.
- **MiniSparklines**: Optional v2. 7 dots per metric showing daily values. Uses `CustomPaint` with 7 circles.

---

### 2.5 Nutrition Dashboard

**File:** `lib/features/nutrition/nutrition_dashboard_screen.dart`

#### Current State (What's Wrong)

- Macro targets card: full-width with calories, protein, carbs, fat bars
- Meals logged card: icon + progress
- Water intake card: icon + progress + add button
- Supplements card: icon + progress
- Quick add section: 3 buttons (water, meal, supplement)
- Quick meal/supplement bottom sheets

**Problems:** Macro ring is buried. Supplement tracking isn't a dashboard item. Water tracker is separate from macros. Too many cards.

#### Target Design

**Inspiration:** MacroFactor — macro ring hero, food log below, FAB to add.

#### New Layout

```
┌─────────────────────────────┐
│  Nutrition                  │  ← AppBar: "Nutrition", h1 style
│                             │
│       ┌───────────┐         │
│       │  1,847    │         │  ← Hero: Calorie Ring (centered)
│       │  / 2,200  │         │     Large calorie number (dataLarge)
│       │  kcal     │         │     Remaining below (bodySmall)
│       └───────────┘         │
│                             │
│  ┌──────┐ ┌──────┐ ┌──────┐│
│  │ P    │ │ C    │ │ F    ││  ← 3 Macro Cards (compact)
│  │120g  │ │180g  │ │55g   ││     Each: letter + grams + mini bar
│  │████░░│ │███░░░│ │████░░││
│  └──────┘ └──────┘ └──────┘│
│                             │
│  Today's Log                │  ← Section header (h2)
│  ┌─────────────────────────┐│
│  │ Breakfast    450 kcal   ││  ← Food log entries (scrollable)
│  │ Lunch        550 kcal   ││     Each: meal type + calories
│  │ Snack        200 kcal   ││     Divider between items
│  │ ...                     ││
│  └─────────────────────────┘│
│                             │
│                    ┌──┐     │  ← FAB: floating action button
│                    │+ │     │     accentPrimary bg, white +
│                    └──┘     │     Opens quick-add sheet
└─────────────────────────────┘
```

#### What to Remove

| Current Element | Action | Reason |
|---|---|---|
| `_MacroTargetsCard` | Split into ring + 3 mini cards | Hero + compact |
| `_NutritionStatusCard` (Meals) | Merge into food log | Redundant |
| `_NutritionStatusCard` (Water) | Integrate into calorie ring | Single metric |
| `_NutritionStatusCard` (Supplements) | Move to settings | Not daily dashboard |
| `_QuickAddButtons` section | Replace with FAB | Cleaner |
| "Quick Add" section header | Remove | FAB replaces |

#### Widget Decomposition

```
NutritionDashboardScreen (ConsumerWidget)
├── AppBar                        // "Nutrition" — h1 style
├── _CalorieHero                  // Centered calorie ring + remaining
├── _MacroCards                   // 3 compact macro cards (P, C, F)
├── _TodaysLog                    // Section header + scrollable food log
│   ├── _LogEntry("Breakfast", 450)
│   ├── _LogEntry("Lunch", 550)
│   └── _LogEntry("Snack", 200)
└── _QuickAddFAB                  // Floating action button (bottom-right)
```

#### Key Details

- **CalorieHero**: `TfProgressRing` centered, size 160. Stroke represents % of target consumed. Inside: calorie number (dataLarge), "/ 2,200" (bodySmall), "kcal" (label). Background of ring: `surface`. Stroke color: `accentPrimary` if under target, `accentDanger` if over.
- **MacroCards**: Three `Expanded` containers in a `Row`. Each: letter (P/C/F in `dataMedium`), grams (dataSmall), mini progress bar (4px height, `accentPrimary` fill). Surface background, `radiusMd` corners.
- **TodaysLog**: `ListView` of meal entries. Each entry: meal type name (h3), calories (dataSmall, right-aligned). Divider between entries. Empty state: "No meals logged yet" (bodySmall, centered).
- **QuickAddFAB**: `FloatingActionButton` with `accentPrimary` background. White `+` icon. Opens bottom sheet with: Log Meal, Log Water, Log Supplement options.

---

### 2.6 Exercise Library

**File:** `lib/features/exercise_library/exercise_library_screen.dart`

#### Current State (What's Wrong)

- Search bar with orange focus border
- 3 filter chip groups (Muscle, Equipment, Difficulty) in horizontal scroll
- Results count
- Exercise cards with: icon + name + muscles + difficulty badge + chevron
- Detail bottom sheet with: name, muscles, difficulty, instructions

**Problems:** Filter chips are overwhelming. Cards have borders. Too much metadata per item.

#### Target Design

**Inspiration:** Strong app — search bar, flat list, tap for detail.

#### New Layout

```
┌─────────────────────────────┐
│  Exercises                  │  ← AppBar: "Exercises", h1 style
│  ┌─────────────────────────┐│
│  │ 🔍 Search exercises...  ││  ← Search bar (sticky, surfaceInput bg)
│  └─────────────────────────┘│
│                             │
│  CHEST (3)                  │  ← Section header (label style, uppercase)
│  ─────────────────────────  │
│  Bench Press                │  ← Exercise name (h3)
│  Barbell · Compound         │  ← Metadata (bodySmall)
│  ─────────────────────────  │
│  Incline Dumbbell Press     │
│  Dumbbell · Compound        │
│  ─────────────────────────  │
│                             │
│  BACK (4)                   │
│  ─────────────────────────  │
│  Barbell Row                │
│  Barbell · Compound         │
│  ─────────────────────────  │
│  ...                        │
└─────────────────────────────┘
```

#### What to Remove

| Current Element | Action | Reason |
|---|---|---|
| Filter chips (3 groups) | Remove from UI | Search handles it |
| Results count | Remove | Section headers show count |
| Card borders | Replace with dividers | Cleaner |
| Difficulty badge | Remove from list | Show in detail only |
| Chevron icon | Remove | Tap target is entire row |

#### Widget Decomposition

```
ExerciseLibraryScreen (ConsumerStatefulWidget)
├── AppBar                        // "Exercises" — h1 style
├── _SearchBar                    // Sticky search input
└── _GroupedExerciseList          // Section headers + exercise rows
    ├── _SectionHeader("Chest (3)")  // label style, uppercase
    ├── _ExerciseRow                   // name (h3) + metadata (bodySmall)
    ├── _Divider
    ├── _ExerciseRow
    └── ...
```

#### Key Details

- **SearchBar**: `TextField` with `surfaceInput` background, `radiusPill` corners. Search icon prefix (textMuted). No orange focus border — use `surfaceDivider` on focus. Placeholder: "Search exercises...".
- **GroupedExerciseList**: Exercises grouped by primary muscle group. Section headers use `label` style (uppercase, muted). Count in parentheses. Uses `SliverList` with `SliverPersistentHeader` for sticky section headers.
- **ExerciseRow**: Full-width `InkWell`. Name in `h3`, metadata line below in `bodySmall` (equipment · type). No card, no border — just a divider below. 56px min height for touch target.
- **Detail**: Push navigation (not bottom sheet) to a detail screen. Shows: name (h1), primary muscles (tags), secondary muscles (tags), instructions (body), difficulty (label).

---

### 2.7 Progress Dashboard

**File:** `lib/features/progress/progress_dashboard_screen.dart`

#### Current State (What's Wrong)

- 5 tabs: Overview, Strength, Volume, Recovery, PRs
- Tab bar with orange active indicator
- Each tab has 1-3 charts stacked vertically
- Overview tab has 4 charts: StrengthProgressChart, WorkoutHeatmap, MuscleBalanceRadar, RecoveryTrendChart

**Problems:** Too many tabs. Too many charts per tab. Tab bar is visual clutter. Charts compete for attention.

#### Target Design

**Inspiration:** Whoop — single chart per view, swipe between.

#### New Layout

```
┌─────────────────────────────┐
│  Progress                   │  ← AppBar: "Progress", h1 style
│                             │
│  ┌─────────────────────────┐│
│  │                         ││
│  │    [CHART AREA]         ││  ← Hero chart (70% viewport)
│  │                         ││     Animated transition between views
│  │                         ││
│  └─────────────────────────┘│
│                             │
│  ┌──────┐ ┌──────┐ ┌──────┐│  ← Stats below chart
│  │ +8%  │ │ 12   │ │ 2,450││     3 key metrics for current view
│  │Volume│ │PRs   │ │Total ││     dataMedium + bodySmall
│  │      │ │      │ │Sets  ││
│  └──────┘ └──────┘ └──────┘│
│                             │
│  ● ● ○ ○ ○                 │  ← Page indicator (5 dots)
│                             │     Current view highlighted
└─────────────────────────────┘

Swipe left/right to navigate: Strength → Volume → Recovery → PRs → Overview
```

#### What to Remove

| Current Element | Action | Reason |
|---|---|---|
| TabBar | Replace with swipe + dot indicator | Cleaner, more focus |
| Multiple charts per view | One chart per view | "One thing per screen" |
| Section headers within tabs | Remove | Chart is self-explanatory |

#### Widget Decomposition

```
ProgressDashboardScreen (ConsumerStatefulWidget)
├── AppBar                        // "Progress" — h1 style
├── _ChartPager                   // PageView with 5 charts
│   ├── _StrengthView             // StrengthProgressChart (hero)
│   ├── _VolumeView               // VolumeChart (hero)
│   ├── _RecoveryView             // RecoveryTrendChart (hero)
│   ├── _PRsView                  // PersonalRecordsBoard (hero)
│   └── _OverviewView             // WorkoutHeatmap (hero)
├── _StatsRow                     // 3 key metrics for current view
└── _PageIndicator                // 5 dots
```

#### Key Details

- **ChartPager**: `PageView` with `PageScrollPhysics`. Each page is a full-screen chart area. Charts take 70% of viewport. Animated transitions between pages (300ms ease-out).
- **StatsRow**: 3 `Expanded` containers showing the most relevant metrics for the current chart view. Each: value (dataMedium) + label (bodySmall). Updates when page changes.
- **PageIndicator**: 5 dots centered below stats. Active dot: `accentPrimary`, 8px. Inactive dots: `textMuted`, 6px. Animated transition on page change.

---

### 2.8 Bottom Navigation

#### Current State

- 5 tabs with icons + labels
- Active tab: orange icon + orange label
- Inactive: gray icon + gray label

#### Target Design

**Inspiration:** Strong — 4 icons, no labels, active dot indicator.

#### New Layout

```
┌─────────────────────────────┐
│                             │
│         [content]           │
│                             │
├─────────────────────────────┤
│  🏠     🏋️     💬     👤    │  ← 4 tabs, no labels
│  ●                        │     Active tab has dot below icon
└─────────────────────────────┘

Tabs: Home | Workout | Coach | Profile
Wellness merges into Home (replaces "Mood" and "Water" quick actions)
```

#### Tab Definitions

| Tab | Icon | Route | Notes |
|---|---|---|---|
| Home | `Icons.home_outlined` / `Icons.home` | `/` | Readiness + actions + coach hint |
| Workout | `Icons.fitness_center` | `/workout` | Active workout or start |
| Coach | `Icons.chat_bubble_outline` / `Icons.chat_bubble` | `/coach-chat` | Chat interface |
| Profile | `Icons.person_outline` / `Icons.person` | `/profile` | Settings, nutrition, wellness, progress |

#### What to Remove

| Current Element | Action | Reason |
|---|---|---|
| Wellness tab | Merge into Home + Profile | Not a top-level tab |
| Text labels | Remove | Icons are sufficient |
| Orange active icon | Change to white icon + orange dot | Cleaner |

#### Key Details

- **Active Indicator**: 4px orange dot centered below active icon. Animated position change (200ms ease-out).
- **Icon States**: Inactive: `textMuted` color. Active: `textPrimary` (white). No orange icons.
- **Background**: `surface` color, no border on top. Uses `BottomNavigationBar` with `type: BottomNavigationBarType.fixed`.

---

## Part 3: Animation Rules

### 3.1 Allowed Animations

| Animation | Duration | Curve | Usage |
|---|---|---|---|
| Page transition | 300ms | `easeOutCubic` | Screen push/pop |
| Tab switch | 200ms | `easeOut` | Bottom nav, tab bar |
| Content fade-in | 200ms | `easeOut` | Skeleton → real data |
| Value change | 150ms | `easeOut` | Number increment/decrement |
| Ring fill | 500ms | `easeOutCubic` | Progress ring on load |
| Rest timer tick | 0ms | — | Instant number update |

### 3.2 Removed Animations

| Animation | Why Removed |
|---|---|
| Shimmer loading skeleton | Replace with simple `CircularProgressIndicator` |
| PR celebration (1500ms elastic) | Replace with haptic feedback + brief color flash |
| Rest timer breathing (4s repeat) | Not communicative — just distracting |
| Quick action chip stagger (800ms) | Instant is better — chips should appear immediately |
| Send button bounce (120ms) | Haptic feedback is sufficient |
| Orange-tinted shadow elevation | Not an animation, but decorative — remove |

### 3.3 Transition Rules

- **Screen push:** `CupertinoPageRoute` (slide from right, 300ms)
- **Modal bottom sheet:** `showModalBottomSheet` with `DraggableScrollableSheet`
- **Tab change:** `AnimatedSwitcher` with `FadeTransition` (200ms)
- **Data update:** No animation — instant value change (haptic feedback for confirmation)

---

## Part 4: Component Library Updates

### 4.1 Cards

**Current:** Surface bg + border + orange-tinted shadow
**New:** Surface bg only, no border, no shadow

```dart
// NEW card decoration
BoxDecoration(
  color: t.surface,
  borderRadius: BorderRadius.circular(t.radiusMd),
)
```

### 4.2 Buttons

**Current:** ElevatedButton with accentPrimary bg
**New:** Same, but:

```dart
// Primary CTA button
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: t.accentPrimary,
    foregroundColor: t.textInverse,
    minimumSize: const Size(double.infinity, 56),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(t.radiusPill),
    ),
    textStyle: TextStyle(
      fontFamily: 'Inter',
      fontSize: 16,
      fontWeight: FontWeight.w600,
    ),
  ),
  onPressed: onPressed,
  child: Text(label),
)
```

### 4.3 Input Fields

**Current:** Surface bg + border + orange focus border
**New:** Surface bg + subtle border + no orange focus

```dart
InputDecoration(
  filled: true,
  fillColor: t.surfaceInput,
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(t.radiusSm),
    borderSide: BorderSide.none,
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(t.radiusSm),
    borderSide: BorderSide(color: t.surfaceDivider),
  ),
  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
)
```

### 4.4 Dividers

```dart
// Full-width divider between list items
Divider(
  color: t.surfaceDivider,
  height: 1,
  indent: 20,
  endIndent: 20,
)
```

### 4.5 Section Headers

```dart
// Section header within a screen
Padding(
  padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
  child: Text(
    title,
    style: t.textTheme.h2, // Inter 18px medium
  ),
)
```

---

## Part 5: Implementation Checklist

### Phase 1: Design Tokens (1-2 hours)

- [ ] Update `DigitalAtelierExtension.standard()` with new color values
- [ ] Remove gradient presets from `DigitalAtelierTokens2`
- [ ] Remove orange-tinted shadow presets
- [ ] Add new typography scale (`h1`, `h2`, `h3`, `body`, `bodySmall`, `label`, `dataLarge`, `dataMedium`, `dataSmall`, `coachVoice`)
- [ ] Add spacing aliases (`screenMargin`, `cardGap`, `sectionGap`, `cardPadding`)
- [ ] Update component presets (card without border, etc.)

### Phase 2: Bottom Navigation (30 min)

- [ ] Reduce from 5 tabs to 4
- [ ] Remove text labels
- [ ] Add dot indicator for active tab
- [ ] Change active icon color from orange to white
- [ ] Merge wellness into home and profile

### Phase 3: Home Screen (1-2 hours)

- [ ] Remove WeeklySummaryCard, TodaysPlanCard, CoachInsightCard
- [ ] Create `_ReadinessHero` widget (centered ring, 60% viewport)
- [ ] Create `_ActionCards` widget (3 equal-width cards)
- [ ] Create `_CoachHint` widget (single italic line)
- [ ] Update spacing to use new tokens

### Phase 4: Workout Logger (2-3 hours)

- [ ] Remove preset chips row
- [ ] Remove coach insight card
- [ ] Simplify set table (3 columns: Set, Weight, Reps)
- [ ] Create `_ValueSteppers` widget (large weight/reps controls)
- [ ] Create `_PreviousSetReference` widget (muted text)
- [ ] Create `_LogButton` widget (full-width CTA)
- [ ] Create `_RestTimer` widget (inline countdown)
- [ ] Move warm-up/previous/swap to overflow menu

### Phase 5: Coach Chat (1-2 hours)

- [ ] Remove persona badges, confidence labels, source counts
- [ ] Simplify AppBar to just "Coach"
- [ ] Update message bubbles (coach: surface bg + Playfair, user: accentPrimary bg)
- [ ] Add timestamps below messages
- [ ] Update typing indicator (3 pulsing dots)
- [ ] Simplify quick action chips

### Phase 6: Wellness Dashboard (1 hour)

- [ ] Reduce from 5 modules to 3 (Mood, Stress, Sleep)
- [ ] Create `_WellnessHero` widget (centered ring + zone + trend)
- [ ] Create `_MetricCards` widget (3 equal-width cards)
- [ ] Remove recommendations card
- [ ] Remove loading skeleton

### Phase 7: Nutrition Dashboard (1-2 hours)

- [ ] Create `_CalorieHero` widget (centered calorie ring)
- [ ] Create `_MacroCards` widget (3 compact P/C/F cards)
- [ ] Create `_TodaysLog` widget (scrollable food log)
- [ ] Create `_QuickAddFAB` widget
- [ ] Remove supplement and water cards from dashboard

### Phase 8: Exercise Library (1 hour)

- [ ] Remove filter chips
- [ ] Group exercises by muscle section
- [ ] Replace card layout with flat list + dividers
- [ ] Change detail from bottom sheet to push navigation

### Phase 9: Progress Dashboard (1-2 hours)

- [ ] Replace TabBar with PageView + dot indicator
- [ ] One chart per view (70% viewport)
- [ ] Add stats row below chart
- [ ] Add animated page transitions

---

## Part 6: File Change Summary

| File | Change Type | Scope |
|---|---|---|
| `lib/theme/digital_atelier.dart` | Modify | Tokens, typography, colors, spacing |
| `lib/screens/home_screen.dart` | Rewrite | New layout, 3 widgets instead of 5 |
| `lib/features/workout/active_workout_screen.dart` | Major refactor | Simplify table, remove chrome |
| `lib/features/coaching/coach_chat_screen.dart` | Major refactor | Clean chat, remove metadata |
| `lib/features/wellness/wellness_dashboard_screen.dart` | Rewrite | Hero ring + 3 cards |
| `lib/features/nutrition/nutrition_dashboard_screen.dart` | Rewrite | Calorie ring + food log |
| `lib/features/exercise_library/exercise_library_screen.dart` | Modify | Flat list, no filters |
| `lib/features/progress/progress_dashboard_screen.dart` | Rewrite | PageView, one chart per view |
| Bottom navigation (router/nav file) | Modify | 4 tabs, no labels |

---

## Part 7: What Stays the Same

These elements are already good and should NOT change:

- **Business logic**: All Riverpod providers, engines, controllers, models
- **Data models**: `CoachMessage`, `WorkoutPlanExercise`, `LoggedSet`, `Macros`, `Exercise`, etc.
- **Navigation routing**: `go_router` paths and structure
- **Dark theme base**: `background: 0xFF0A0A0A` is excellent
- **Surface hierarchy**: `surface` → `surfaceElevated` → `surfaceInput` is clean
- **Semantic colors**: `success`, `warning`, `recovery`, `calm` are well-chosen
- **Font families**: Inter + Playfair pairing is good (we just use them more intentionally)
- **Spacing base unit**: 4px is correct
- **Border radius values**: `radiusSm(8)`, `radiusMd(12)`, `radiusLg(16)`, `radiusPill(999)` are fine
- **Animation durations**: `durationFast(150)`, `durationNormal(300)`, `durationSlow(500)` are fine

---

## Part 8: Design Anti-Patterns to Avoid

1. **Don't use Playfair for UI chrome.** Playfair is for coach voice only. All titles, headers, labels, and navigation use Inter.

2. **Don't use orange for non-CTA elements.** Orange is for: primary button, active nav dot, one optional accent per screen. Not for: icons, badges, shadows, borders, focus states.

3. **Don't use borders on cards.** Cards are distinguished by surface color, not borders. The background is 0xFF0A0A0A, surface is 0xFF111111 — that's enough contrast.

4. **Don't show more than one chart per screen.** If a screen needs multiple charts, use PageView with swipe navigation.

5. **Don't use gradients.** Solid colors only. Gradients are decorative, not functional.

6. **Don't use loading skeletons.** Use a centered `CircularProgressIndicator` or just show content immediately.

7. **Don't animate decorative elements.** No bounces, no elastic overshoot, no breathing animations. Animate only state transitions.

8. **Don't show metadata during active tasks.** During a workout: no coach insights, no preset chips, no celebration animations. Just the set logger.

9. **Don't use tooltips or badges in chat.** Confidence scores, source counts, and persona indicators are internal metadata. The user doesn't need them.

10. **Don't overload the home screen.** One hero metric + 3 action cards + one text line. That's it.
