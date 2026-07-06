# TransformFit Design System V4 — "Obsidian Forge"

> **Codename**: Obsidian Forge v4.0
> **Date**: 2026-07-06
> **Author**: RIG UI Designer + Design Studio
> **Status**: BINDING — All screen rewrites MUST conform to this spec
> **Supersedes**: TRANSFORMFIT_DESIGN_SYSTEM_SPEC.md (v3), UI_REDESIGN_SPEC.md
> **Based on**: Reverse-engineering of Ladder, MacroFactor, Whoop, Strong, Apple Fitness+

---

## TABLE OF CONTENTS

1. [Design Philosophy](#1-design-philosophy)
2. [Color System](#2-color-system)
3. [Typography System](#3-typography-system)
4. [Spacing & Grid System](#4-spacing--grid-system)
5. [Elevation & Depth System](#5-elevation--depth-system)
6. [Component Library](#6-component-library)
7. [Navigation Architecture](#7-navigation-architecture)
8. [Screen-by-Screen Specifications](#8-screen-by-screen-specifications)
9. [Imagery Integration](#9-imagery-integration)
10. [Data Visualization](#10-data-visualization)
11. [Animation & Motion Design](#11-animation--motion-design)
12. [Accessibility](#12-accessibility)
13. [Anti-Patterns](#13-anti-patterns)
14. [Token Map for Dart Implementation](#14-token-map-for-dart-implementation)

---

## 1. DESIGN PHILOSOPHY

### Core Principle: "One Metric. One Action. Zero Noise."

TransformFit is a premium fitness app that earns its place on the home screen by being **fast to use** and **beautiful to look at**. Every screen has ONE hero element. Every interaction takes ≤2 taps. Every visual choice is intentional.

### What We're Building Toward

| App | What We Take From Them |
|-----|----------------------|
| **Ladder** | Clean white cards on dark background. Coach messaging that feels personal. Premium typography with generous spacing. |
| **MacroFactor** | Adherence-neutral design (no shame). Hero ring as primary visualization. Speed-first logging. |
| **Whoop** | Recovery circle IS the brand. Single metric per screen. Minimal UI, maximum data. Black + white + one accent. |
| **Strong** | One exercise at a time. Set table IS the screen. Log button is the only CTA. Zero decoration. |

### Design Pillars

1. **Restrained Color** — Orange appears in exactly 3 places per screen: CTA button, active nav dot, one optional accent. Everything else: white text, gray secondary, surface backgrounds.

2. **Data IS the Design** — The largest visual element on every data screen is a data visualization (ring, chart, metric). Not a card, not a header, not an illustration.

3. **One Thing Per Screen** — Every screen has ONE hero element taking ≥50% of viewport. Supporting content is secondary and scannable.

4. **Professional Typography** — Inter for everything except coach voice. Playfair ONLY inside chat messages. One font family for all UI chrome.

5. **Whitespace is a Feature** — 20px screen margins. 12px card gaps. 32px section gaps. The negative space creates hierarchy.

6. **Purposeful Animation** — Animations exist ONLY for: loading→content transitions, state changes (set logged→rest timer), and progress feedback (ring fills). No bounce, no elastic, no celebration.

### Anti-Patterns (Explicitly Rejected)

- ❌ Red/yellow "failure" indicators for missed macros or workouts
- ❌ Gamification that feels childish (no cartoon mascots, no "LEVEL UP!" modals)
- ❌ Cluttered dashboards with 8+ metrics visible at once
- ❌ Generic Material Design components without brand personality
- ❌ Light mode as default or even as an option
- ❌ Orange gradient decorations, orange-tinted shadows, orange accent text everywhere
- ❌ Playfair serif on non-coach UI elements
- ❌ Shimmer loading skeletons (use simple spinner)
- ❌ PR celebration animations (use haptic + color flash)
- ❌ Breathing/rest timer animations (use simple countdown)

---

## 2. COLOR SYSTEM

### 2.1 Primary Palette

TransformFit is **dark-only**. No light mode. Every color is designed for dark backgrounds.

```
┌─────────────────────────────────────────────────────────────┐
│  CANVAS & SURFACE                                           │
│                                                             │
│  ████████  Background       #0A0A0A  (pure dark canvas)     │
│  ████████  Surface          #141414  (card backgrounds)     │
│  ████████  Surface Elevated #1C1C1C  (elevated cards, nav)  │
│  ████████  Surface Input    #1A1A1A  (form fields)          │
│  ████████  Surface Border   #222222  (subtle dividers)       │
│  ████████  Canvas Deep      #050505  (modals, overlays)      │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│  TEXT HIERARCHY                                             │
│                                                             │
│  ████████  Text Primary     #FFFFFF  (pure white)            │
│  ████████  Text Secondary   #8E8E93  (iOS gray — labels)    │
│  ████████  Text Tertiary    #48484A  (disabled, hints)       │
│  ████████  Text Inverse     #0A0A0A  (text on accent bg)    │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│  ACCENT — RESTRAINED                                        │
│                                                             │
│  ████████  Accent (CTA only) #FF6B35  (warm orange)         │
│  ████████  Success           #30D158  (iOS green)           │
│  ████████  Warning           #FFD60A  (iOS yellow)          │
│  ████████  Error             #FF453A  (iOS red)             │
│  ████████  Info              #0A84FF  (iOS blue)            │
└─────────────────────────────────────────────────────────────┘
```

### 2.2 Accent Usage Rules

**Orange (#FF6B35) appears in EXACTLY these places and nowhere else:**

1. **Primary CTA button** — the one action button on each screen
2. **Active navigation indicator** — the 4px dot below the active tab icon
3. **One optional accent per screen** — a data highlight, a live badge, or a progress ring fill

**If a screen has no CTA, orange appears in 0 places.** This is correct.

### 2.3 Semantic Color Map

```
POSITIVE (achievements, progress, PRs):
  Primary:    #30D158  (iOS green)
  Background: #30D158 at 12% opacity for glow/tinted surfaces

NEUTRAL (on track, expected, normal):
  Primary:    #FFFFFF  (white — neutral means "fine", not colored)

INFO (informational callouts, tips):
  Primary:    #0A84FF  (iOS blue)

CAUTION (injury risk, overtraining — NOT for missed goals):
  Primary:    #FFD60A  (iOS yellow)

CRITICAL (safety-critical alerts ONLY — injury, medical):
  Primary:    #FF453A  (iOS red)
  ⚠️ RULE: Critical is NEVER used for missed workouts, over-eating, or low adherence.
```

### 2.4 Data Visualization Colors

```
MACRO COLORS (MacroFactor-inspired):
  Protein:   #06B6D4  (cyan)
  Carbs:     #FBBF24  (amber/gold)
  Fat:       #FF6B35  (orange — brand-aligned, the ONE accent use)
  Calories:  #FFFFFF  (white — the "total")

WORKOUT COLORS:
  Volume:        #0A84FF  (blue)
  Intensity:     #FF453A  (red — high intensity is OK to be red)
  Duration:      #30D158  (green)
  Personal Record: #FFD60A  (gold)

WELLNESS COLORS (Whoop-inspired):
  Recovery High:    #30D158  (green)
  Recovery Mid:     #FFD60A  (amber)
  Recovery Low:     #FF6B35  (orange — NOT red)
  Sleep:            #0A84FF  (blue)
  Stress:           #8E8E93  (gray)
```

### 2.5 Gradient Policy

**No gradients on cards, buttons, or backgrounds.** Gradients are permitted ONLY on:

1. **Progress ring strokes** — single-color to slightly lighter variant
2. **Hero imagery overlays** — black-to-transparent for text legibility over photos

```
// Ring gradient example (recovery ring):
LinearGradient(
  colors: [#30D158, #34C759],  // subtle green-to-brighter-green
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
)
```

---

## 3. TYPOGRAPHY SYSTEM

### 3.1 Font Stack

| Role | Font | Weight | Usage |
|------|------|--------|-------|
| **Everything UI** | Inter | 400–700 | All chrome, navigation, cards, buttons, labels, data |
| **Coach Voice** | Playfair Display | 500 | Coach chat messages ONLY — nothing else |
| **Data Numbers** | Inter (tabular figures) | 600–700 | Scores, weights, reps, timers, metrics |

**Rule:** If it's not inside a coach chat bubble, it's Inter. No exceptions.

### 3.2 Type Scale

```
┌─────────────────────────────────────────────────────────────────┐
│  HERO — Inter 34px / line-height 1.0 / Bold (700)              │
│  Usage: Readiness score number inside ring                      │
│  Example: "82"                                                  │
│                                                                 │
│  H1 — Inter 28px / line-height 1.2 / Semibold (600)            │
│  Usage: Screen titles ("Today", "Workout", "Coach")             │
│  Example: "Today"                                               │
│                                                                 │
│  H2 — Inter 22px / line-height 1.3 / Semibold (600)            │
│  Usage: Section headers ("Today's Plan", "Macros")              │
│  Example: "Today's Log"                                         │
│                                                                 │
│  H3 — Inter 17px / line-height 1.3 / Medium (500)              │
│  Usage: Card titles, exercise names, meal names                 │
│  Example: "Goblet Squat"                                        │
│                                                                 │
│  BODY — Inter 17px / line-height 1.5 / Regular (400)           │
│  Usage: Body text, descriptions, paragraphs                    │
│  Example: "Complete 4 sets of 8 reps at moderate weight."       │
│                                                                 │
│  CAPTION — Inter 15px / line-height 1.4 / Regular (400)        │
│  Usage: Secondary text, timestamps, descriptions                │
│  Color: #8E8E93 (textSecondary)                                 │
│  Example: "2 min ago"                                           │
│                                                                 │
│  MICRO — Inter 13px / line-height 1.3 / Regular (400)          │
│  Usage: Labels, tags, metadata, unit labels                     │
│  Color: #8E8E93 or #48484A                                     │
│  Example: "kg", "reps", "SETS"                                  │
│                                                                 │
│  COACH — Playfair 17px / line-height 1.4 / Medium (500)        │
│  Usage: Coach chat messages ONLY                                │
│  Example: "Peak — go hard today. Earn the last set."            │
└─────────────────────────────────────────────────────────────────┘
```

### 3.3 Data Typography (Tabular Figures)

All numeric data values use Inter with `fontFeatures: [FontFeature.tabularFigures()]` for aligned columns.

```
DATA HERO — Inter 34px / Bold (700) / tabular / height 1.0
  Usage: Recovery score, calorie count, large metrics
  Example: "82", "1,847"

DATA MEDIUM — Inter 22px / Semibold (600) / tabular / height 1.0
  Usage: Secondary metrics, set weights, reps
  Example: "40 kg", "12 reps"

DATA SMALL — Inter 15px / Medium (500) / tabular / height 1.0
  Usage: Inline data, table cells, small metrics
  Example: "RPE 7", "3 sets"
```

### 3.4 Text Color Rules

| Context | Color Token | Value |
|---------|------------|-------|
| Primary text (titles, body) | textPrimary | #FFFFFF |
| Secondary text (labels, captions) | textSecondary | #8E8E93 |
| Tertiary text (hints, disabled) | textTertiary | #48484A |
| Text on orange CTA | textInverse | #FFFFFF |
| Coach messages | textPrimary | #FFFFFF |

---

## 4. SPACING & GRID SYSTEM

### 4.1 Base Grid: 8px

All spacing is on an **8px grid**. Fine adjustments use 4px. No Fibonacci. No arbitrary values.

```
4   — fine adjustment, icon-to-label gap
8   — tight gap, inline spacing
12  — card gap (between cards)
16  — card internal padding, element gap
20  — screen margin (horizontal)
24  — comfortable gap
32  — section gap (between sections)
40  — large section break
48  — hero element margin
64  — maximum breathing room
```

### 4.2 Named Layout Constants

```
screenMargin:   20px  — horizontal padding on all screens
cardGap:        12px  — gap between adjacent cards
sectionGap:     32px  — gap between major sections
cardPadding:    16px  — internal card padding (all sides)
inputPadding:   16px horizontal, 14px vertical
```

### 4.3 Border Radius

```
radiusSm:     8px   — input fields, small elements
radiusMd:     12px  — cards, containers (DEFAULT)
radiusLg:     16px  — modals, bottom sheets
radiusPill:   999px — chips, buttons (fully rounded)
```

**Why 12px for cards:** The current 5px (Fibonacci) is too sharp — looks like Material Design defaults. 12px matches Ladder/MacroFactor quality. It's rounded enough to feel premium but not bubbly.

---

## 5. ELEVATION & DEPTH SYSTEM

### 5.1 Shadow Philosophy

**No colored shadows. No orange-tinted shadows.** All shadows are neutral black.

```
elevationNone:    []                                    — flat cards (default)
elevationLow:     [BoxShadow(0x0A000000, blur: 8,  y: 2)]  — subtle lift
elevationMedium:  [BoxShadow(0x14000000, blur: 16, y: 4)]  — elevated cards
elevationHigh:    [BoxShadow(0x1F000000, blur: 32, y: 8)]  — modals, sheets
```

### 5.2 Depth Hierarchy

```
Layer 0: Background    #0A0A0A  — the canvas
Layer 1: Surface       #141414  — cards, containers (no shadow)
Layer 2: Elevated      #1C1C1C  — active states, pressed (no shadow)
Layer 3: Input         #1A1A1A  — form fields (no shadow)
Layer 4: Modal         #1C1C1C  — bottom sheets, modals (elevationHigh)
```

**Key insight:** We differentiate layers by **surface color**, not shadows. A card on #141414 over #0A0A0A background is already "elevated" — no shadow needed. This matches Whoop and Strong.

---

## 6. COMPONENT LIBRARY

### 6.1 Cards

```dart
// Standard card — the default
BoxDecoration(
  color: surface,           // #141414
  borderRadius: BorderRadius.circular(12),
  // NO border. NO shadow.
)

// Elevated card — for active/pressed states
BoxDecoration(
  color: surfaceElevated,   // #1C1C1C
  borderRadius: BorderRadius.circular(12),
  // NO border. NO shadow.
)
```

**Rules:**
- Cards never have borders
- Cards never have shadows (depth comes from surface color contrast)
- Card internal padding: 16px all sides
- Cards never use orange for anything except a CTA inside them

### 6.2 Buttons

```dart
// PRIMARY CTA — the only orange element on screen
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: accentPrimary,    // #FF6B35
    foregroundColor: textPrimary,      // #FFFFFF
    minimumSize: Size(double.infinity, 50),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    textStyle: TextStyle(
      fontFamily: 'Inter',
      fontSize: 17,
      fontWeight: FontWeight.w600,
    ),
    elevation: 0,
  ),
)

// SECONDARY BUTTON — surface bg, white text
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: surface,          // #141414
    foregroundColor: textPrimary,      // #FFFFFF
    minimumSize: Size(double.infinity, 50),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    elevation: 0,
  ),
)

// TEXT BUTTON — no background
TextButton(
  style: TextButton.styleFrom(
    foregroundColor: textSecondary,    // #8E8E93
    textStyle: TextStyle(
      fontFamily: 'Inter',
      fontSize: 15,
      fontWeight: FontWeight.w500,
    ),
  ),
)
```

### 6.3 Input Fields

```dart
InputDecoration(
  filled: true,
  fillColor: surfaceInput,             // #1A1A1A
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: BorderSide.none,       // NO border when unfocused
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: BorderSide(color: surfaceBorder),  // subtle border on focus
  ),
  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  hintStyle: TextStyle(color: textTertiary),
)
```

**Rule:** Input fields NEVER have orange focus borders. Focus state uses `surfaceBorder` (#222222).

### 6.4 Chips

```dart
// Standard chip
Container(
  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  decoration: BoxDecoration(
    color: surface,                    // #141414
    borderRadius: BorderRadius.circular(999),  // pill shape
  ),
  child: Text('Label', style: microStyle),
)

// Selected chip (rare — only for active filter)
Container(
  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  decoration: BoxDecoration(
    color: surfaceElevated,            // #1C1C1C
    borderRadius: BorderRadius.circular(999),
  ),
  child: Text('Label', style: microStyle.copyWith(color: textPrimary)),
)
```

### 6.5 Bottom Navigation Bar

```
Height: 56px
Background: #050505 (canvasDeep)
Icons: 4, no labels
Active: white icon + 4px orange (#FF6B35) dot below
Inactive: #48484A icon, no dot
No border on top edge
```

**Tabs:**
| Tab | Icon (inactive) | Icon (active) | Route |
|-----|-----------------|---------------|-------|
| Home | `Icons.home_outlined` | `Icons.home` | `/` |
| Workout | `Icons.fitness_center_outlined` | `Icons.fitness_center` | `/workout` |
| Coach | `Icons.chat_bubble_outline` | `Icons.chat_bubble` | `/coach-chat` |
| Profile | `Icons.person_outline` | `Icons.person` | `/profile` |

### 6.6 Dividers

```dart
Divider(
  color: surfaceBorder,    // #222222
  height: 1,
  thickness: 1,
)
```

### 6.7 Progress Ring (TfProgressRing)

```
Stroke width: 8px
Background track: surface (#141414) at 100% opacity
Fill: accentPrimary (#FF6B35) for default, semantic color for context
Size: context-dependent (see screen specs)
Center content: data typography (hero or dataMedium)
```

---

## 7. NAVIGATION ARCHITECTURE

### 7.1 Bottom Tab Bar

4 tabs. No labels. Active dot indicator.

```
┌─────────────────────────────────────────┐
│                                         │
│              [SCREEN CONTENT]            │
│                                         │
├─────────────────────────────────────────┤
│  🏠        🏋️        💬        👤      │
│  ●                                       │
└─────────────────────────────────────────┘
   Home    Workout    Coach    Profile
```

### 7.2 Screen Stack

```
Home (/)
├── Readiness ring (hero)
├── 3 action cards (Workout, Coach, Wellness)
└── Coach hint (single italic line)

Workout (/workout)
├── Start workout → Active Workout Screen
│   ├── Exercise name + set progress
│   ├── Set table
│   ├── Value steppers
│   └── Log button + rest timer
└── Exercise library (secondary)

Coach (/coach-chat)
├── Chat messages (coach + user bubbles)
├── Quick action chips
└── Input bar

Profile (/profile)
├── User info
├── Nutrition dashboard (secondary)
├── Wellness dashboard (secondary)
├── Progress dashboard (secondary)
└── Settings
```

---

## 8. SCREEN-BY-SCREEN SPECIFICATIONS

### 8.1 Home Screen

**File:** `lib/screens/home_screen.dart`
**Inspiration:** Whoop home — one massive ring + 3 compact cards

```
┌─────────────────────────────────────┐
│                                     │
│  Today                    (h1)      │  ← 20px margin, 24px top padding
│                                     │
│                                     │
│                                     │
│         ┌───────────┐               │
│         │           │               │
│         │    82     │               │  ← Readiness Ring
│         │           │               │     280px diameter
│         └───────────┘               │     Stroke: zone-colored
│         Peak                        │     Score: HERO typography
│                                     │     Label: MICRO uppercase
│                                     │
│                                     │
│  ┌────────┐ ┌────────┐ ┌────────┐  │
│  │   ▶    │ │   ●    │ │   ◉    │  │  ← 3 Action Cards
│  │Workout │ │ Coach  │ │Wellness│  │     Equal width, 12px gap
│  └────────┘ └────────┘ └────────┘  │     Surface bg, 12px radius
│                                     │     Icon 24px + label CAPTION
│                                     │
│  Peak — go hard today. Earn the     │  ← Coach Hint
│  last set.                          │     Playfair 15px, italic
│                                     │     textSecondary color
│                                     │     Max 1 line, ellipsis
└─────────────────────────────────────┘
```

**Layout Details:**
- **Header**: "Today" in H1, 20px horizontal margin
- **Readiness Ring**: Centered, 280px diameter, uses `TfProgressRing`. Stroke color = zone color (green/amber/orange). Score number in HERO typography centered inside. Zone label ("Peak", "Maintaining", "Recovering") in MICRO uppercase below ring. Ring takes ~45% of viewport.
- **Action Cards**: Three `Expanded` containers in a `Row`, 12px gap. Each: surface background, 12px radius, 16px padding. Icon (24px, textSecondary) + label (CAPTION). Tap navigates.
- **Coach Hint**: Single line of italic Playfair text. textSecondary color. "Peak — go hard today. Earn the last set." Only shown if coach has sent a message.

**What to Remove from Current:**
| Element | Action | Reason |
|---------|--------|--------|
| `ReadinessScoreCard` wrapper | Remove | Replace with bare ring (no card) |
| `TodaysPlanCard` | Merge into "Workout" action card | One-tap navigation |
| `CoachInsightCard` | Reduce to single line | Not a card — just text |
| `QuickActionsRow` (4 items) | Reduce to 3 | Remove Mood/Water (merge into Wellness) |
| `WeeklySummaryCard` | Move to Progress | Not today-relevant |
| Shimmer loading skeleton | Remove | Use `CircularProgressIndicator` |

---

### 8.2 Active Workout Logger

**File:** `lib/features/workout/active_workout_screen.dart`
**Inspiration:** Strong — minimal, fast, one exercise at a time

```
┌─────────────────────────────────────┐
│                                     │
│  ← Goblet Squat           (h1)     │  ← Exercise name, left-aligned
│  Set 3 of 4              (CAPTION) │  ← Set progress, muted
│                                     │
│  ┌─────────────────────────────────┐│
│  │  SET    WEIGHT    REPS          ││  ← Table header
│  │  ─────────────────────────────  ││     MICRO uppercase, textTertiary
│  │  1      40 kg     8             ││  ← Logged sets
│  │  2      40 kg     8             ││     DATA SMALL, textTertiary
│  │  3      __ kg     __            ││  ← Current set (editable)
│  │                                 ││     DATA MEDIUM, textPrimary
│  └─────────────────────────────────┘│
│                                     │
│      40 kg                8 reps    │  ← Value display (large, tappable)
│      ▼  ▲                 ▼  ▲     │     DATA HERO + unit label
│                                     │
│  Previous: 40kg × 8 @ RPE 7        │  ← Reference text
│                            (CAPTION)│     textSecondary
│                                     │
│  ┌─────────────────────────────────┐│
│  │          LOG SET                ││  ← Full-width CTA
│  └─────────────────────────────────┘│     accentPrimary bg, white text
│                                     │     50px height, 12px radius
│                                     │
│  ⏱ 1:30 rest                       │  ← Rest timer (after log)
│                  (DATA MEDIUM)      │     Inline, with "Skip" text button
└─────────────────────────────────────┘
```

**Layout Details:**
- **Exercise Header**: Exercise name in H1, left-aligned. "Set 3 of 4" in CAPTION, textSecondary, below name.
- **Set Table**: Full width, no card wrapper. Header row: MICRO uppercase, textTertiary. Logged rows: DATA SMALL, textTertiary. Current row: DATA MEDIUM, textPrimary. Divider between header and rows.
- **Value Steppers**: Two large controls side by side. Weight on left, reps on right. Each shows: value (DATA HERO), unit (MICRO, textSecondary), -/+ buttons (44px touch targets, surface bg, 12px radius).
- **Previous Reference**: "Previous: 40kg × 8 @ RPE 7" in CAPTION, textSecondary. Only if previous data exists.
- **Log Button**: Full width, 50px height, accentPrimary bg, white text, 12px radius. Below steppers with 16px gap. On tap: log set, start rest timer, advance counter.
- **Rest Timer**: Inline below log button. Countdown in DATA MEDIUM. "Skip" as TEXT BUTTON. No animation — number decrement.

**What to Remove from Current:**
| Element | Action | Reason |
|---------|--------|--------|
| Exercise name TextField | Read-only (tap to edit) | Distracting during logging |
| Preset chips (4) | Move to overflow menu (⋮) | Overwhelming |
| Coach insight card | Remove entirely | Distracting during workout |
| RPE column in table | Move to tap-to-edit on log | Simplify table |
| Rest column in table | Remove from table | Show inline timer after log |
| PR celebration animation | Remove | Haptic + brief color flash |
| Orange-tinted shadows | Remove | Surface color differentiation |
| Breathing animation on timer | Remove | Simple countdown |

---

### 8.3 Coach Chat

**File:** `lib/features/coaching/coach_chat_screen.dart`
**Inspiration:** Ladder — clean bubbles, minimal metadata, warm

```
┌─────────────────────────────────────┐
│  Coach                      (h1)    │  ← AppBar: just "Coach"
│                                     │
│  ┌─────────────────────────┐        │
│  │ Welcome back. Today     │        │  ← Coach bubble
│  │ counts if the work      │        │     Left-aligned, max 80% width
│  │ matches your energy.    │        │     Surface bg, 12px radius
│  │ How are you feeling?    │        │     COACH typography (Playfair)
│  └─────────────────────────┘        │     16px padding
│  2 min ago                 (CAPTION)│  ← Timestamp, textSecondary
│                                     │
│            ┌────────────────────┐   │
│            │ I feel great let's │   │  ← User bubble
│            │ go                 │   │     Right-aligned, max 80% width
│            └────────────────────┘   │     accentPrimary bg, white text
│                                     │     12px radius, 16px padding
│                                     │
│  ┌─────────────────────────────┐    │  ← Quick actions
│  │ How am I doing? | What      │    │     Horizontal scroll chips
│  │ should I eat? | ...         │    │     Surface bg, pill shape
│  └─────────────────────────────┘    │     Above input, 8px gap
│                                     │
│  ┌─────────────────────────────┐    │  ← Input bar
│  │  Type a message...       ▶  │    │     SurfaceInput bg, pill shape
│  └─────────────────────────────┘    │     Send: circle, accentPrimary bg
└─────────────────────────────────────┘
```

**Layout Details:**
- **AppBar**: "Coach" in H1. No persona badge. No role subtitle. No avatar.
- **Coach Bubble**: Container, surface bg, 12px radius, max 80% width, left-aligned. Text in COACH typography (Playfair 17px). Padding 16px. No icon, no badge, no metadata.
- **User Bubble**: Container, accentPrimary bg, 12px radius, max 80% width, right-aligned. Text in BODY, white. Padding 16px.
- **Timestamp**: Below each message group. CAPTION style, textSecondary. Relative time.
- **Typing Indicator**: Three dots pulsing sequentially. Surface bg, coach alignment. `AnimatedOpacity`, staggered 200ms.
- **Quick Actions**: Horizontal `ListView` of chips. Icon (16px, textSecondary) + label (CAPTION). Surface bg, pill shape.
- **Input Bar**: Container, surfaceInput bg, pill radius. TextField with hint "Type a message...". Send button: 44px circle, accentPrimary bg, white arrow icon.

**What to Remove from Current:**
| Element | Action | Reason |
|---------|--------|--------|
| Persona badge (initial + color) | Remove | Coach is one voice |
| Confidence label ("82%") | Remove | Not actionable |
| Source count ("3 sources") | Remove | Clutter |
| Observation card | Remove | Not conversational |
| Next action card | Remove | Move to quick actions |
| Persona name in AppBar | Remove | Just "Coach" |
| Animated chip stagger | Remove | Instant is better |
| Send button bounce | Remove | Haptic feedback is enough |

---

### 8.4 Wellness Dashboard

**File:** `lib/features/wellness/wellness_dashboard_screen.dart`
**Inspiration:** Whoop recovery — one massive number + 3 compact metrics

```
┌─────────────────────────────────────┐
│  Wellness                   (h1)    │  ← AppBar
│                                     │
│                                     │
│         ┌───────────┐               │
│         │           │               │
│         │    72     │               │  ← Wellness Ring
│         │           │               │     280px diameter
│         └───────────┘               │     Zone-colored stroke
│         Maintaining        (MICRO)  │     Score: HERO typography
│         ↗ Trending up    (CAPTION)  │     Zone: MICRO uppercase
│                                     │     Trend: CAPTION + arrow
│                                     │
│                                     │
│  ┌────────┐ ┌────────┐ ┌────────┐  │
│  │   😊   │ │   🧘   │ │   😴   │  │  ← 3 Metric Cards
│  │   78   │ │   62   │ │   81   │  │     Equal width, 12px gap
│  │  Mood  │ │ Stress │ │ Sleep  │  │     Icon + DATA MEDIUM score
│  └────────┘ └────────┘ └────────┘  │     Label: CAPTION
│                                     │
└─────────────────────────────────────┘
```

**Layout Details:**
- **Wellness Ring**: 280px diameter, `TfProgressRing`. Stroke = zone color (green/amber/orange). Score in HERO centered. Zone label ("Maintaining") in MICRO uppercase below. Trend arrow: "↗ Trending up" in CAPTION, success color if positive.
- **Metric Cards**: Three `Expanded` in `Row`, 12px gap. Surface bg, 12px radius. Icon (28px) + score (DATA MEDIUM) + label (CAPTION). Tap opens detail sheet.

**What to Remove from Current:**
| Element | Action | Reason |
|---------|--------|--------|
| 5 module cards | Reduce to 3 | Mood, Stress, Sleep are core |
| Mindfulness module | Move to settings | Not daily-use |
| Burnout Risk module | Move to settings | Background calculation |
| Recommendations card | Move to coach chat | Coach surfaces these |
| Linear progress bars | Replace with ring | Data-viz, not decoration |

---

### 8.5 Nutrition Dashboard

**File:** `lib/features/nutrition/nutrition_dashboard_screen.dart`
**Inspiration:** MacroFactor — macro ring hero, food log below, FAB to add

```
┌─────────────────────────────────────┐
│  Nutrition                  (h1)    │  ← AppBar
│                                     │
│         ┌───────────┐               │
│         │  1,847    │               │  ← Calorie Ring
│         │  / 2,200  │               │     200px diameter
│         │  kcal     │               │     White stroke (calories = white)
│         └───────────┘               │     Number: DATA HERO
│                                     │     Remaining: CAPTION
│                                     │
│  ┌────────┐ ┌────────┐ ┌────────┐  │
│  │   P    │ │   C    │ │   F    │  │  ← 3 Macro Cards
│  │ 120g   │ │ 180g   │ │  55g   │  │     Letter: DATA MEDIUM
│  │ ████░░ │ │ ███░░░ │ │ ████░░ │  │     Grams: DATA SMALL
│  └────────┘ └────────┘ └────────┘  │     Mini bar: 4px, colored fill
│                                     │
│  Today's Log               (h2)    │  ← Section header
│  ┌─────────────────────────────────┐│
│  │ Breakfast          450 kcal     ││  ← Food log entries
│  │ ─────────────────────────────── ││     Meal name: H3
│  │ Lunch              550 kcal     ││     Calories: DATA SMALL, right
│  │ ─────────────────────────────── ││     Divider between entries
│  │ Snack              200 kcal     ││
│  └─────────────────────────────────┘│
│                                     │
│                           ┌────┐    │  ← FAB
│                           │ +  │    │     accentPrimary bg
│                           └────┘    │     56px circle
└─────────────────────────────────────┘
```

**Macro Color Mapping:**
- Protein: #06B6D4 (cyan)
- Carbs: #FBBF24 (amber)
- Fat: #FF6B35 (orange — brand-aligned)

---

### 8.6 Progress Dashboard

**File:** `lib/features/progress/progress_dashboard_screen.dart`
**Inspiration:** Whoop — single chart per view, swipe between

```
┌─────────────────────────────────────┐
│  Progress                   (h1)    │  ← AppBar
│                                     │
│  ┌─────────────────────────────────┐│
│  │                                 ││
│  │        [CHART AREA]             ││  ← Hero chart
│  │                                 ││     70% viewport height
│  │                                 ││     Animated transitions
│  └─────────────────────────────────┘│
│                                     │
│  ┌────────┐ ┌────────┐ ┌────────┐  │
│  │  +8%   │ │   12   │ │  2,450 │  │  ← 3 Stats
│  │ Volume │ │  PRs   │ │  Sets  │  │     DATA MEDIUM + CAPTION
│  └────────┘ └────────┘ └────────┘  │     Updates per page
│                                     │
│         ● ● ○ ○ ○                   │  ← Page indicator
│                                     │     5 dots, active = accentPrimary
└─────────────────────────────────────┘

Swipe: Strength → Volume → Recovery → PRs → Overview
```

**Layout Details:**
- **Chart Pager**: `PageView`, one chart per page, 70% viewport. 300ms ease-out transitions.
- **Stats Row**: 3 `Expanded` containers. Value (DATA MEDIUM) + label (CAPTION). Updates on page change.
- **Page Indicator**: 5 dots centered. Active: accentPrimary, 8px. Inactive: textTertiary, 6px.

---

## 9. IMAGERY INTEGRATION

### 9.1 Available Assets

17 Higgsfield images at `assets/imagery/`:

**Exercise Illustrations (8):**
- `exercise_overhead_press.png`
- `exercise_kettlebell.png`
- `exercise_yoga.png`
- `exercise_plank.png`
- `exercise_pullup.png`
- `exercise_deadlift.png`
- `exercise_bench_press.png`
- `exercise_squat.png`

**Hero Images (9):**
- `hero_app_store.png`
- `hero_ai_coach.png`
- `hero_sleep.png`
- `hero_gamification.png`
- `hero_nutrition.png`
- `hero_barbell.png`
- `hero_app_mockup.png`
- `hero_mindfulness.png`
- `hero_workout.png`

### 9.2 Imagery Usage Rules

1. **Exercise illustrations** appear in:
   - Workout cards (Ladder-style: illustration + exercise name + sets)
   - Exercise library detail screens
   - Active workout screen (small, next to exercise name — optional)

2. **Hero images** appear in:
   - Onboarding screens (full-bleed with gradient overlay)
   - Empty states (muted, background)
   - Settings/about screens

3. **NEVER on the main 4 tab screens** — Home, Workout, Coach, Profile are data-first. No decorative imagery on primary screens.

4. **Image treatment:**
   - Always on dark background
   - No rounded corners on images (they're decorative, not interactive)
   - Opacity: 100% for exercise illustrations, 40-60% for hero background images
   - No borders, no shadows on images

---

## 10. DATA VISUALIZATION

### 10.1 Ring Widget (TfProgressRing)

The ring is TransformFit's signature visual element (Whoop-style).

```
SPECIFICATIONS:
  Stroke width: 8px
  Background track: surface (#141414)
  Fill color: context-dependent (see below)
  Size: 200px (nutrition), 280px (home/wellness)
  Center content: number in HERO or DATA HERO typography
  Below center: label in MICRO or CAPTION

CONTEXT-SPECIFIC COLORS:
  Readiness ring:  zone-colored (green/amber/orange gradient)
  Wellness ring:   zone-colored (green/amber/orange gradient)
  Calorie ring:    white (#FFFFFF) stroke
  Macro rings:     protein/cyan, carbs/amber, fat/orange
```

### 10.2 Charts

Charts use these rules:
- Background: transparent (sits on surface card)
- Grid lines: surfaceBorder (#222222) at 50% opacity
- Axis labels: MICRO typography, textTertiary
- Data lines: 2px stroke, context color
- Touch-to-inspect: shows value in DATA SMALL tooltip
- No chart borders

### 10.3 Set Table

The set table is Strong-style — the defining workout UX.

```
┌──────────────────────────────────┐
│  SET    WEIGHT    REPS    ✓      │  ← Header: MICRO, textTertiary
│  ──────────────────────────────  │
│  1      40 kg     8       ✓     │  ← Logged: DATA SMALL, textTertiary
│  2      40 kg     8       ✓     │     Checkmark in success (#30D158)
│  3      __ kg     __      ○     │  ← Current: DATA MEDIUM, textPrimary
│  4      __ kg     __      ○     │  ← Upcoming: DATA SMALL, textTertiary
└──────────────────────────────────┘
```

---

## 11. ANIMATION & MOTION DESIGN

### 11.1 Allowed Animations

| Animation | Duration | Curve | Usage |
|-----------|----------|-------|-------|
| Page transition | 300ms | easeOutCubic | Screen push/pop |
| Tab switch | 200ms | easeOut | Bottom nav |
| Content fade-in | 200ms | easeOut | Loading → content |
| Value change | 150ms | easeOut | Number increment |
| Ring fill | 500ms | easeOutCubic | Progress ring on load |
| Rest timer tick | 0ms | — | Instant number update |

### 11.2 Removed Animations

| Animation | Why Removed |
|-----------|-------------|
| Shimmer loading skeleton | Replace with `CircularProgressIndicator` |
| PR celebration (elastic) | Replace with haptic + brief color flash |
| Rest timer breathing | Not communicative — just distracting |
| Quick action chip stagger | Instant is better |
| Send button bounce | Haptic feedback is sufficient |
| Orange-tinted shadow elevation | Decorative, not communicative |

### 11.3 Transition Rules

- **Screen push:** `CupertinoPageRoute` (slide from right, 300ms)
- **Modal bottom sheet:** `showModalBottomSheet` with `DraggableScrollableSheet`
- **Tab change:** `AnimatedSwitcher` with `FadeTransition` (200ms)
- **Data update:** No animation — instant value change (haptic for confirmation)

### 11.4 Haptic Feedback Map

| Action | Haptic Type |
|--------|-------------|
| Log set | `HapticFeedback.mediumImpact()` |
| Complete workout | `HapticFeedback.heavyImpact()` |
| Tap navigation | `HapticFeedback.lightImpact()` |
| Error/validation | `HapticFeedback.vibrate()` |
| PR achieved | `HapticFeedback.heavyImpact()` + brief success color flash |

---

## 12. ACCESSIBILITY

### 12.1 Dynamic Type

All text styles support scaling via `TransformFitTextTheme(scale: factor)`. The scale factor multiplies font sizes while preserving line heights and spacing ratios.

### 12.2 Color Contrast

| Combination | Ratio | WCAG |
|-------------|-------|------|
| White (#FFFFFF) on Surface (#141414) | 15.4:1 | AAA |
| Secondary (#8E8E93) on Surface (#141414) | 5.2:1 | AA |
| Tertiary (#48484A) on Surface (#141414) | 2.8:1 | Fail — decorative only |
| Orange (#FF6B35) on Surface (#141414) | 5.1:1 | AA |
| White (#FFFFFF) on Orange (#FF6B35) | 3.6:1 | AA Large only |

**Rule:** `textTertiary` (#48484A) is used ONLY for decorative/disabled text, never for essential information.

### 12.3 Reduced Motion

```dart
Duration resolvedDuration(Duration duration, BuildContext context) {
  final disableAnimations =
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;
  return disableAnimations ? Duration.zero : duration;
}
```

---

## 13. ANTI-PATTERNS

### Things That Will Get Your PR Rejected

1. **Orange anywhere except CTA / nav dot / one accent** — gradient decorations, tinted shadows, accent text styling, icon colors
2. **Playfair on non-coach elements** — titles, buttons, labels, navigation
3. **Borders on cards** — use surface color contrast instead
4. **More than 3 cards visible on Home** — ring + 3 action cards + coach hint is the maximum
5. **More than 1 chart visible on Progress** — PageView with swipe, not stacked charts
6. **Shimmer/skeleton loading** — use `CircularProgressIndicator`
7. **Elastic/bounce animations** — no overshoot, no spring
8. **Gradient backgrounds** — no gradients on cards, buttons, or backgrounds
9. **Colored shadows** — all shadows are neutral black
10. **Labels on bottom nav** — icons only

---

## 14. TOKEN MAP FOR DART IMPLEMENTATION

### 14.1 Color Tokens → `DigitalAtelierExtension`

```dart
factory DigitalAtelierExtension.standard() => const DigitalAtelierExtension(
  // Canvas & Surface
  background:       Color(0xFF0A0A0A),
  surface:          Color(0xFF141414),    // was 0xFF111111
  surfaceElevated:  Color(0xFF1C1C1C),    // was 0xFF1A1A1A
  surfaceInput:     Color(0xFF1A1A1A),    // was 0xFF151515
  surfaceBorder:    Color(0xFF222222),    // was 0xFF1E1E1E
  surfaceDivider:   Color(0xFF222222),    // was 0xFF252525
  canvasDeep:       Color(0xFF050505),    // unchanged

  // Accent (RESTRAINED)
  accentPrimary:    Color(0xFFFF6B35),    // was 0xFFF97316 — warmer
  accentSecondary:  Color(0xFF0A84FF),    // was 0xFF8B5CF6 — now info blue
  accentTertiary:   Color(0xFF30D158),    // was 0xFF10B981 — iOS green
  accentDanger:     Color(0xFFFF453A),    // was 0xFFEF4444 — iOS red
  accentInfo:       Color(0xFF0A84FF),    // was 0xFF3B82F6 — iOS blue

  // Text
  textPrimary:      Color(0xFFFFFFFF),    // was 0xFFF0EDE8 — pure white
  textSecondary:    Color(0xFF8E8E93),    // was 0xFF9CA3AF — iOS gray
  textMuted:        Color(0xFF48484A),    // was 0xFF8B95A5 — darker
  textInverse:      Color(0xFFFFFFFF),    // was 0xFF0A0A0A — white on accent

  // Semantic
  success:          Color(0xFF30D158),    // was 0xFF10B981 — iOS green
  warning:          Color(0xFFFFD60A),    // was 0xFFF59E0B — iOS yellow
  recovery:         Color(0xFF30D158),    // was 0xFF8B5CF6 — now green
  calm:             Color(0xFF0A84FF),    // was 0xFF6366F1 — now blue

  // Spacing (8px grid — REPLACES Fibonacci)
  spaceXs:   4.0,     // was 3.0
  spaceSm:   8.0,     // was 5.0
  spaceMd:   12.0,    // was 8.0
  spaceLg:   16.0,    // was 13.0
  spaceXl:   20.0,    // was 21.0
  spaceXxl:  24.0,    // was 34.0
  spaceXxxl: 32.0,    // was 55.0
  spaceHuge: 64.0,    // was 89.0

  // Radius (rounded — REPLACES Fibonacci)
  radiusSm:    8.0,     // was 3.0
  radiusMd:    12.0,    // was 5.0
  radiusLg:    16.0,    // was 8.0
  radiusXl:    20.0,    // was 13.0
  radiusPill:  999.0,   // was 21.0

  // Animation (unchanged)
  durationFast:        Duration(milliseconds: 100),
  durationNormal:      Duration(milliseconds: 200),
  durationSlow:        Duration(milliseconds: 500),
  durationCelebration: Duration(milliseconds: 1300),
  curveDefault:        Curves.easeOutCubic,
  curveBounce:         Curves.elasticOut,     // celebration only
  curveSlide:          Curves.easeOutQuart,
);
```

### 14.2 Layout Constants

```dart
static const double screenMargin = 20.0;   // was 21.0 (fib)
static const double cardGap = 12.0;        // was 13.0 (fib)
static const double sectionGap = 32.0;     // was 34.0 (fib)
```

### 14.3 Typography Tokens → `TransformFitTextTheme`

```dart
class TransformFitTextTheme {
  const TransformFitTextTheme({this.scale = 1.0});
  final double scale;

  TextStyle _scaled(TextStyle style) {
    if (scale == 1.0) return style;
    return style.copyWith(fontSize: (style.fontSize ?? 16) * scale);
  }

  // HERO — Readiness score inside ring
  TextStyle get hero => _scaled(const TextStyle(
    fontFamily: 'Inter',
    fontSize: 34,
    fontWeight: FontWeight.w700,
    height: 1.0,
    color: Color(0xFFFFFFFF),
    fontFeatures: [FontFeature.tabularFigures()],
  ));

  // H1 — Screen titles
  TextStyle get h1 => _scaled(const TextStyle(
    fontFamily: 'Inter',
    fontSize: 28,
    fontWeight: FontWeight.w600,
    height: 1.2,
    color: Color(0xFFFFFFFF),
  ));

  // H2 — Section headers
  TextStyle get h2 => _scaled(const TextStyle(
    fontFamily: 'Inter',
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: Color(0xFFFFFFFF),
  ));

  // H3 — Card titles, exercise names
  TextStyle get h3 => _scaled(const TextStyle(
    fontFamily: 'Inter',
    fontSize: 17,
    fontWeight: FontWeight.w500,
    height: 1.3,
    color: Color(0xFFFFFFFF),
  ));

  // BODY — Body text
  TextStyle get body => _scaled(const TextStyle(
    fontFamily: 'Inter',
    fontSize: 17,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: Color(0xFFFFFFFF),
  ));

  // CAPTION — Secondary text
  TextStyle get caption => _scaled(const TextStyle(
    fontFamily: 'Inter',
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: Color(0xFF8E8E93),
  ));

  // MICRO — Labels, tags, metadata
  TextStyle get micro => _scaled(const TextStyle(
    fontFamily: 'Inter',
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.3,
    color: Color(0xFF8E8E93),
  ));

  // COACH — Coach messages only (Playfair)
  TextStyle get coachVoice => _scaled(const TextStyle(
    fontFamily: 'Playfair',
    fontSize: 17,
    fontWeight: FontWeight.w500,
    height: 1.4,
    color: Color(0xFFFFFFFF),
  ));

  // DATA HERO — Large numbers in rings
  TextStyle get dataLarge => _scaled(const TextStyle(
    fontFamily: 'Inter',
    fontSize: 34,
    fontWeight: FontWeight.w700,
    height: 1.0,
    color: Color(0xFFFFFFFF),
    fontFeatures: [FontFeature.tabularFigures()],
  ));

  // DATA MEDIUM — Secondary metrics
  TextStyle get dataMedium => _scaled(const TextStyle(
    fontFamily: 'Inter',
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 1.0,
    color: Color(0xFFFFFFFF),
    fontFeatures: [FontFeature.tabularFigures()],
  ));

  // DATA SMALL — Inline data, table cells
  TextStyle get dataSmall => _scaled(const TextStyle(
    fontFamily: 'Inter',
    fontSize: 15,
    fontWeight: FontWeight.w500,
    height: 1.0,
    color: Color(0xFFFFFFFF),
    fontFeatures: [FontFeature.tabularFigures()],
  ));

  // Legacy aliases (backward compat — map to new names)
  TextStyle get display => h1;
  TextStyle get bodySmall => caption;
}
```

### 14.4 Spacing → `MathematicalDesign` Updates

The `MathematicalDesign` class should be updated to remove Fibonacci references and use the 8px grid. Alternatively, the `DigitalAtelierExtension` spacing tokens override the values. The recommended approach:

```dart
// In mathematical_design.dart — add 8px grid constants alongside Fibonacci
// The DigitalAtelierExtension.standard() factory already overrides the values
// so MathematicalDesign serves as documentation only.
```

### 14.5 What Changes in `digital_atelier.dart`

| Field | Old Value | New Value | Reason |
|-------|-----------|-----------|--------|
| `surface` | `0xFF111111` | `0xFF141414` | Slightly lighter, matches Ladder |
| `surfaceElevated` | `0xFF1A1A1A` | `0xFF1C1C1C` | Better contrast with surface |
| `surfaceInput` | `0xFF151515` | `0xFF1A1A1A` | Cleaner input field bg |
| `surfaceBorder` | `0xFF1E1E1E` | `0xFF222222` | More visible subtle border |
| `accentPrimary` | `0xFFF97316` | `0xFFFF6B35` | Warmer, more premium orange |
| `accentSecondary` | `0xFF8B5CF6` | `0xFF0A84FF` | Info blue instead of purple |
| `accentTertiary` | `0xFF10B981` | `0xFF30D158` | iOS green, more natural |
| `accentDanger` | `0xFFEF4444` | `0xFFFF453A` | iOS red |
| `accentInfo` | `0xFF3B82F6` | `0xFF0A84FF` | iOS blue |
| `textPrimary` | `0xFFF0EDE8` | `0xFFFFFFFF` | Pure white, stronger contrast |
| `textSecondary` | `0xFF9CA3AF` | `0xFF8E8E93` | iOS gray, warmer |
| `textMuted` | `0xFF8B95A5` | `0xFF48484A` | Push further back |
| `textInverse` | `0xFF0A0A0A` | `0xFFFFFFFF` | White on orange CTA |
| `success` | `0xFF10B981` | `0xFF30D158` | iOS green |
| `warning` | `0xFFF59E0B` | `0xFFFFD60A` | iOS yellow |
| `recovery` | `0xFF8B5CF6` | `0xFF30D158` | Recovery = green, not purple |
| `calm` | `0xFF6366F1` | `0xFF0A84FF` | Calm = blue |
| `spaceXs` | `3.0` | `4.0` | 8px grid |
| `spaceSm` | `5.0` | `8.0` | 8px grid |
| `spaceMd` | `8.0` | `12.0` | 8px grid |
| `spaceLg` | `13.0` | `16.0` | 8px grid |
| `spaceXl` | `21.0` | `20.0` | 8px grid |
| `spaceXxl` | `34.0` | `24.0` | 8px grid |
| `spaceXxxl` | `55.0` | `32.0` | 8px grid |
| `spaceHuge` | `89.0` | `64.0` | 8px grid |
| `radiusSm` | `3.0` | `8.0` | More rounded |
| `radiusMd` | `5.0` | `12.0` | Card radius, premium feel |
| `radiusLg` | `8.0` | `16.0` | Modals |
| `radiusXl` | `13.0` | `20.0` | Large containers |
| `radiusPill` | `21.0` | `999.0` | Fully rounded pill |

### 14.6 New Text Style: `hero`

Add to `TransformFitTextTheme`:

```dart
TextStyle get hero => _scaled(const TextStyle(
  fontFamily: 'Inter',
  fontSize: 34,
  fontWeight: FontWeight.w700,
  height: 1.0,
  color: Color(0xFFFFFFFF),
  fontFeatures: [FontFeature.tabularFigures()],
));
```

This is the readiness score number inside the ring. It's distinct from `dataLarge` only in naming — they share the same specs. The `hero` name is semantically clearer for ring center usage.

### 14.7 Legacy Backward Compatibility

The `DigitalAtelierExtension` has legacy getters (`displayLarge`, `headlineLarge`, `titleLarge`, `bodyLarge`, `bodyMedium`, `bodySmall`, `labelLarge`, `dataValue`, `dataLabel`, `accent`). Update their mappings:

```dart
TextStyle get displayLarge => textTheme.hero;        // was textTheme.display
TextStyle get displayMedium => textTheme.h1;         // was display.copyWith(36)
TextStyle get headlineLarge => textTheme.h1;         // unchanged mapping
TextStyle get headlineMedium => textTheme.h2;        // unchanged mapping
TextStyle get titleLarge => textTheme.h3;            // unchanged mapping
TextStyle get titleMedium => textTheme.body;         // unchanged mapping
TextStyle get bodyLarge => textTheme.body;            // unchanged mapping
TextStyle get bodyMedium => textTheme.caption;        // was bodySmall
TextStyle get bodySmall => textTheme.micro;           // was caption
TextStyle get labelLarge => textTheme.h3.copyWith(fontWeight: FontWeight.w600);
TextStyle get dataValue => textTheme.dataLarge;       // unchanged
TextStyle get dataLabel => textTheme.micro;           // was caption
TextStyle get accent => textTheme.body.copyWith(
  color: accentPrimary,
  fontWeight: FontWeight.w600,
);
```

### 14.8 Elevation Presets

Remove orange-tinted shadows from `DigitalAtelierTokens2`:

```dart
// REPLACE these (currently orange-tinted):
static const List<BoxShadow> elevationLow = [
  BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, 2)),
];

static const List<BoxShadow> elevationMedium = [
  BoxShadow(color: Color(0x1F000000), blurRadius: 16, offset: Offset(0, 4)),
];

static const List<BoxShadow> elevationHigh = [
  BoxShadow(color: Color(0x29000000), blurRadius: 32, offset: Offset(0, 8)),
];
```

---

## APPENDIX A: SCREEN CHECKLIST

Use this checklist when implementing each screen:

- [ ] ONE hero element takes ≥50% of viewport
- [ ] Orange appears in ≤3 places (CTA, nav dot, optional accent)
- [ ] All text is Inter except coach messages (Playfair)
- [ ] No borders on cards (use surface color contrast)
- [ ] No gradients on cards/buttons/backgrounds
- [ ] No colored shadows (all shadows are neutral black)
- [ ] Spacing follows 8px grid (4, 8, 12, 16, 20, 24, 32, 40, 48, 64)
- [ ] Screen margin is 20px horizontal
- [ ] Card gap is 12px
- [ ] Section gap is 32px
- [ ] Card radius is 12px
- [ ] Button height is 50px
- [ ] Bottom nav has 4 icons, no labels, 56px height
- [ ] Loading uses `CircularProgressIndicator`, not shimmer
- [ ] No bounce/elastic animations
- [ ] Data values use tabular figures
- [ ] Accessibility: Dynamic Type supported, contrast ratios pass

---

## APPENDIX B: COMPETITIVE REFERENCE

| Feature | Whoop | MacroFactor | Ladder | Strong | TransformFit V4 |
|---------|-------|-------------|--------|--------|-----------------|
| Hero metric | Recovery circle | Macro ring | Workout card | Set table | Readiness ring |
| Color accent | Red only | Orange + teal | Red | Blue | Orange (restrained) |
| Typography | Proxima Nova | Custom (Pentagram) | SF Pro | SF Pro | Inter + Playfair |
| Card style | No cards | Clean cards | Photo cards | No cards | Surface cards, no border |
| Navigation | 4 tabs | 5 tabs | 4 tabs | 4 tabs | 4 tabs, no labels |
| Dark mode | Default only | Default only | Default | Optional | Default only |
| Animations | Minimal | Moderate | Moderate | None | Purposeful only |

---

*This spec is binding. Every screen rewrite must conform. PRs that violate these rules will be rejected.*
