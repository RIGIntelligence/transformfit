# TRANSFORMFIT DESIGN SYSTEM SPECIFICATION v3.0

> **Codename**: DigitalAtelier v3 — "Obsidian Forge"
> **Date**: 2026-07-06
> **Author**: RIG UI Designer + Design Agent
> **Status**: BINDING — All screen rewrites MUST conform to this spec
> **Based on**: Reverse-engineering of MacroFactor, Ladder, Whoop, Apple Fitness+, Fitbod, Hevy, Strong

---

## TABLE OF CONTENTS

1. [Design Philosophy](#1-design-philosophy)
2. [Competitive Analysis Summary](#2-competitive-analysis-summary)
3. [Color System](#3-color-system)
4. [Typography System](#4-typography-system)
5. [Spacing & Layout System](#5-spacing--layout-system)
6. [Elevation & Depth System](#6-elevation--depth-system)
7. [Component Library](#7-component-library)
8. [Navigation Architecture](#8-navigation-architecture)
9. [Screen-by-Screen Specifications](#9-screen-by-screen-specifications)
10. [Data Visualization](#10-data-visualization)
11. [Animation & Motion Design](#11-animation--motion-design)
12. [Accessibility Requirements](#12-accessibility-requirements)
13. [Dark Mode Excellence Standards](#13-dark-mode-excellence-standards)
14. [Iconography](#14-iconography)
15. [Haptic Feedback Map](#15-haptic-feedback-map)

---

## 1. DESIGN PHILOSOPHY

### Core Principle: "Confident Clarity"

TransformFit's design language merges the **data density of MacroFactor** with the **minimal elegance of Strong**, the **visual storytelling of Whoop**, and the **coaching warmth of Ladder**. The result is an app that feels like a premium coach in your pocket — never punishing, always guiding.

### Design Pillars (derived from competitive analysis)

| Pillar | Inspired By | Manifestation |
|--------|-------------|---------------|
| **Adherence-Neutral** | MacroFactor | No red bars, no shame colors for missed goals. Neutral/green only. |
| **Data-Dense but Scannable** | Whoop + MacroFactor | Every screen leads with ONE hero metric. Supporting data is secondary. |
| **Friction-Free Logging** | Strong + MacroFactor | Set logging takes ≤2 taps. Food logging is copy-forward, not search-forward. |
| **Coaching Presence** | Ladder + MacroFactor | Coach messages feel like a real person, not a chatbot. Typography has personality. |
| **Progress is Celebration** | Apple Fitness+ | Rings, streaks, and milestones use motion + haptics to reward consistency. |
| **Dark-First Luxury** | Whoop + Fitbod | Dark mode is the DEFAULT and ONLY mode. No light mode. The dark canvas is the brand. |

### Anti-Patterns (explicitly rejected)

- ❌ Red/yellow "failure" indicators for missed macros or workouts
- ❌ Gamification that feels childish (no cartoon mascots, no "LEVEL UP!" modals)
- ❌ Cluttered dashboards with 8+ metrics visible at once
- ❌ Generic Material Design components without brand personality
- ❌ Light mode as default or even as an option

---

## 2. COMPETITIVE ANALYSIS SUMMARY

### 2.1 MacroFactor — Nutrition Tracking + AI Coaching

**What they do well:**
- **Custom typography**: "Macro Sans" typeface designed by Pentagram — bold, precise, authoritative
- **Adherence-neutral design**: No red bars for over-eating, no shame UX. Neutral colors for all states.
- **Speed-first food logging**: Search → tap → done. Copy from previous days. Drag to reorder meals.
- **Weekly check-in flow**: Simple "check in" button recalibrates calorie targets. No guilt, just data.
- **Space-themed illustrations**: Adventurous, delightful onboarding and check-in visuals
- **Macro ring visualization**: Donut chart showing protein/carbs/fat as colored arcs

**Color palette (observed):**
- Background: `#0B0B0B` (near-black)
- Surface: `#1A1A1A` (dark charcoal)
- Text primary: `#FFFFFF`
- Text secondary: `#999999`
- Accent: `#FF6B35` (warm orange) and `#4ECDC4` (teal)
- Protein: `#4ECDC4` (teal), Carbs: `#FFD93D` (gold), Fat: `#FF6B6B` (coral)

**Typography:**
- Headlines: Macro Sans (custom), bold, 28-36px
- Body: Inter or similar geometric sans, 14-16px
- Data values: Tabular nums, 700 weight, 24-32px

**Navigation:** Bottom tab bar (5 tabs): Dashboard, Log, Check-in, Trends, Profile

**Unique patterns:**
- Food logger with inline calorie/macro preview
- Barcode scanner with instant macro fill
- Weekly check-in as a first-class screen (not buried)
- "Program adherence" as a percentage, not a pass/fail

---

### 2.2 Ladder — Workout Programming + Coaching

**What they do well:**
- **Program structure visualization**: Week view showing all planned workouts as color-coded cards
- **Workout card design**: Hero image + workout name + duration + muscle groups as pill tags
- **Exercise illustrations**: Clean vector illustrations showing muscle engagement, not photos
- **Timer/rest UI**: Large countdown timer with haptic feedback at 0:00
- **Coach messaging**: Conversational UI with coach avatar, personality-driven copy
- **Progress tracking**: Simple before/after comparison, volume-over-time charts

**Color palette (observed):**
- Background: `#0D0D0D` (near-black)
- Surface: `#1C1C1E` (iOS system dark)
- Accent: `#FF4D4D` (energetic red)
- Secondary accent: `#00D4AA` (mint green for progress)
- Text primary: `#FFFFFF`
- Text secondary: `#8E8E93`

**Typography:**
- Headlines: SF Pro Display (iOS native), semibold, 24-32px
- Body: SF Pro Text, regular, 15-17px
- Data: SF Mono for timer displays

**Navigation:** Bottom tab bar (4 tabs): Today, Programs, Progress, Profile

**Unique patterns:**
- Workout card with muscle group pills (e.g., "Chest • Triceps • Shoulders")
- Rest timer as a persistent bottom sheet during workouts
- Coach "nudge" messages that appear contextually
- Program week view as a horizontal scroll of day cards

---

### 2.3 Whoop — Recovery + Strain + Sleep

**What they do well:**
- **The Recovery Circle**: A single large ring (0-100%) that changes color: green (67-100%), yellow (34-66%), red (0-33%). This is the gold standard of single-metric visualization.
- **Strain meter**: A horizontal bar that fills throughout the day, with zones (light/moderate/high/max)
- **Sleep performance**: Circular progress with sleep stages as stacked arcs
- **Minimalist data presentation**: ONE number per screen, with drill-down on tap
- **Trend graphs**: Clean line charts with minimal axis labels, touch-to-inspect
- **Journal/mood tracking**: Simple daily check-in with binary/multiple-choice questions

**Color palette (official from Mobbin + brand guidelines):**
- Background: `#0B0B0B` (Cod Gray)
- Surface: `#1A1A1A`
- Text primary: `#FFFFFF`
- Text secondary: `#999999`
- Accent/Brand: `#FF0100` (signature red)
- Interactive focus: `#2360C5` (cerulean blue)
- Surface secondary: `#F3F5F9` (light mode only)
- Recovery green: `#00C853`
- Strain yellow: `#FFD600`
- Strain red: `#FF1744`

**Typography:**
- Hero: Proxima Nova, 700 weight, 32px / 110% line height
- Headings: system sans-serif, 700, 24px
- CTA: system sans-serif, 700, 20px
- Body: system sans-serif, 400, 16px
- Caption: system sans-serif, 400, 12px

**Navigation:** Bottom tab bar (4 tabs): Overview, Strain, Sleep, Coach

**Unique patterns:**
- Single-metric hero with color-coded ring
- Swipeable day navigation (left/right to see yesterday, last week)
- Biometric tiles: HRV, SpO2, Skin Temp as small data cards
- "Today" view as a vertical scroll of metric cards
- Journal as a morning ritual flow (not buried in settings)

---

### 2.4 Apple Fitness+ — Guided Workouts + Rings

**What they do well:**
- **Activity Rings**: Three concentric rings (Move/Exercise/Stand) with gradient fills. The most recognizable fitness UI element in the world.
- **Workout card carousel**: Horizontal scroll of workout cards with hero thumbnails
- **Trainer spotlight**: Large portrait photos of trainers with workout type overlay
- **Metrics overlay during workout**: Real-time heart rate, calories, elapsed time as floating HUD
- **Summary screen**: Celebratory animation showing ring completion + personal bests

**Color palette:**
- Move ring: `#FF2D55` (pink-red) → `#FF6482` gradient
- Exercise ring: `#2BFF3A` (green) → `#30D158` gradient
- Stand ring: `#00D4FF` (cyan) → `#5AC8FA` gradient
- Background: `#000000` (pure black)
- Surface: `#1C1C1E`
- Text: `#FFFFFF`

**Typography:**
- SF Pro Display for headlines
- SF Pro Rounded for workout names (friendly)
- SF Mono for metrics

**Navigation:** Tab bar with prominent center "Workout" button

**Unique patterns:**
- Ring completion celebration animation (confetti + haptic)
- Workout card with trainer photo + overlay gradient
- Real-time metric overlay during active workout
- "Stack" feature for queuing multiple workouts

---

### 2.5 Fitbod — AI Workout Generation

**What they do well:**
- **Muscle map visualization**: Anatomical body outline with muscle groups color-coded by recovery state (fresh/ recovering/fatigued)
- **Exercise recommendation cards**: Card per exercise showing target muscles, sets/reps, suggested weight
- **Set/rep logging**: Large number inputs with +/- buttons, swipe to complete set
- **Workout summary**: Volume chart + muscle engagement breakdown post-workout
- **Progress charts**: Clean line charts showing weight/volume progression per exercise

**Color palette (observed):**
- Background: `#121212` (Material dark)
- Surface: `#1E1E1E`
- Accent: `#4CAF50` (green for fresh muscles)
- Warning: `#FFC107` (yellow for recovering)
- Danger: `#F44336` (red for fatigued)
- Text primary: `#FFFFFF`
- Text secondary: `#B0B0B0`

**Typography:**
- Headlines: System sans, 600 weight, 20-28px
- Body: System sans, 400, 14-16px
- Data: Tabular nums, 500 weight, 18-24px

**Navigation:** Bottom tab (4 tabs): Workout, Exercises, Progress, Profile

**Unique patterns:**
- Muscle map as a visual "what to train today" selector
- AI-generated workout with editable exercise cards
- Exercise detail with muscle engagement diagram
- Post-workout summary with volume/muscle breakdown

---

### 2.6 Hevy — Workout Logging + Social

**What they do well:**
- **Active workout logger**: Exercise groups with collapsible set rows. Each row: set #, weight, reps, checkbox
- **Exercise library**: Searchable grid with muscle group filters and exercise type tabs
- **Social feed**: Workout posts showing exercises, volume, duration as a "workout card"
- **Progress photos**: Side-by-side comparison with date labels
- **Routine builder**: Drag-and-drop exercise ordering with supersets

**Color palette (observed):**
- Background: `#0D0D0D`
- Surface: `#1A1A1A`
- Accent: `#5B5BFF` (electric indigo)
- Success: `#4CAF50`
- Text primary: `#FFFFFF`
- Text secondary: `#888888`

**Typography:**
- Headlines: Inter, 700 weight, 20-28px
- Body: Inter, 400, 14-16px
- Data: Inter, 600, 16-20px

**Navigation:** Bottom tab (5 tabs): Home, Workout, Exercises, Social, Profile

**Unique patterns:**
- Set logging with inline weight/reps inputs (no modal)
- Exercise card with muscle group tags
- Social workout card showing exercises completed
- PR (personal record) badges on exercise rows

---

### 2.7 Strong — Minimal Workout Tracking

**What they do well:**
- **Set logging UX (the gold standard)**: Table-style layout. Each exercise is a section header. Under it: rows of [Set # | Previous | Weight | Reps | ✓]. Tap weight → numpad. Tap reps → numpad. Tap ✓ → done. This is the fastest logging UX in fitness.
- **Timer**: Auto-starts rest timer after completing a set. Shows as a subtle countdown in the exercise header.
- **History view**: Calendar dot view showing workout days. Tap a day → see that workout.
- **Exercise search**: Alphabetical list with search bar and muscle group filter tabs.
- **Clean minimal aesthetic**: No illustrations, no gradients, no fluff. Pure data.

**Color palette:**
- Background: `#FFFFFF` (light) / `#000000` (dark mode)
- Surface: `#F5F5F5` (light) / `#1C1C1E` (dark)
- Accent: `#4A90D9` (calm blue)
- Success: `#34C759` (green checkmark)
- Text primary: `#000000` / `#FFFFFF`
- Text secondary: `#8E8E93`
- Separator: `#E5E5EA` / `#38383A`

**Typography:**
- SF Pro Text throughout
- Headlines: 600, 17-20px
- Body: 400, 15-17px
- Data: 500, 16-18px with tabular nums
- Monospace for timer displays

**Navigation:** Bottom tab (4 tabs): Workout, Exercises, History, Profile

**Unique patterns:**
- Set logging table (the defining UX of the app)
- Auto-rest timer after set completion
- Previous performance shown inline (so you know what to beat)
- Workout duration timer in the nav bar during active workout
- "Copy workout" from history to today

---

## 3. COLOR SYSTEM

### 3.1 Primary Palette — "Obsidian Forge"

TransformFit is a **dark-only** app. There is no light mode. Every color is designed for dark backgrounds.

```dart
// ---- CORE CANVAS ----
static const Color canvas          = Color(0xFF0A0A0A);  // Main background
static const Color canvasDeep      = Color(0xFF050505);  // Deepest layer (modals, overlays)
static const Color canvasSubtle    = Color(0xFF0F0F0F);  // Slightly lifted from canvas

// ---- SURFACE SYSTEM (inspired by Whoop + MacroFactor) ----
static const Color surface         = Color(0xFF141414);  // Card backgrounds
static const Color surfaceElevated = Color(0xFF1C1C1C);  // Elevated cards, bottom sheets
static const Color surfacePressed  = Color(0xFF222222);  // Pressed/tapped state
static const Color surfaceBorder   = Color(0xFF262626);  // Subtle borders
static const Color surfaceGlass    = Color(0x14FFFFFF);  // Glass morphism (8% white)

// ---- TEXT HIERARCHY (inspired by Strong + Whoop) ----
static const Color textPrimary     = Color(0xFFF0EDE8);  // Warm white (not pure white — reduces eye strain)
static const Color textSecondary   = Color(0xFF8A8A8A);  // Muted labels
static const Color textTertiary    = Color(0xFF5A5A5A);  // Disabled/hint text
static const Color textInverse     = Color(0xFF0A0A0A);  // Text on light/accent backgrounds
```

### 3.2 Accent Colors — "The Forge Palette"

The primary accent remains orange (brand continuity) but the system is richer:

```dart
// ---- PRIMARY ACCENT ----
static const Color accent          = Color(0xFFF97316);  // Orange (brand primary)
static const Color accentMuted     = Color(0xFFB45309);  // Darker orange for subtle uses
static const Color accentGlow      = Color(0x33F97316);  // Orange at 20% for glows/shadows

// ---- SECONDARY ACCENTS ----
static const Color electric        = Color(0xFF8B5CF6);  // Violet (coaching/AI features)
static const Color electricMuted   = Color(0xFF6D28D9);  // Darker violet
static const Color mint            = Color(0xFF10B981);  // Emerald (progress/gains)
static const Color mintMuted       = Color(0xFF059669);  // Darker emerald
static const Color sky             = Color(0xFF3B82F6);  // Blue (data/info)
static const Color skyMuted        = Color(0xFF1D4ED8);  // Darker blue
static const Color coral           = Color(0xFFEF4444);  // Red (ONLY for critical safety alerts)
static const Color coralMuted      = Color(0xFFB91C1C);  // Darker red
```

### 3.3 Semantic Color Map

```dart
// ---- SEMANTIC COLORS (adherence-neutral!) ----
// POSITIVE: Used for achievements, progress, PRs
static const Color positive        = Color(0xFF10B981);  // Emerald green
static const Color positiveMuted   = Color(0xFF065F46);  // Dark emerald
static const Color positiveGlow    = Color(0x1A10B981);  // 10% emerald

// NEUTRAL: Used for "on track", expected, normal (NOT yellow/warning)
static const Color neutral         = Color(0xFFF97316);  // Orange = on track
static const Color neutralMuted    = Color(0xFF92400E);  // Dark orange

// INFO: Used for informational callouts, tips
static const Color info            = Color(0xFF3B82F6);  // Blue

// CAUTION: Used sparingly for injury risk, overtraining signals
static const Color caution         = Color(0xFFF59E0B);  // Amber (NOT for missed goals!)

// CRITICAL: Used ONLY for safety-critical alerts (injury, medical)
static const Color critical        = Color(0xFFEF4444);  // Red
// ⚠️ RULE: critical is NEVER used for missed workouts, over-eating, or low adherence.
```

### 3.4 Data Visualization Colors

```dart
// ---- MACRO COLORS (inspired by MacroFactor) ----
static const Color protein          = Color(0xFF06B6D4);  // Cyan
static const Color carbs            = Color(0xFFFBBF24);  // Amber/Gold
static const Color fat              = Color(0xFFF97316);  // Orange (brand-aligned)
static const Color fiber            = Color(0xFF10B981);  // Emerald
static const Color calories         = Color(0xFFF0EDE8);  // White (the "total")

// ---- BODY COMPOSITION COLORS ----
static const Color muscleMass       = Color(0xFF8B5CF6);  // Violet
static const Color bodyFat          = Color(0xFFF97316);  // Orange
static const Color weight           = Color(0xFFF0EDE8);  // White

// ---- WORKOUT COLORS ----
static const Color volume           = Color(0xFF3B82F6);  // Blue
static const Color intensity        = Color(0xFFEF4444);  // Red (high intensity is OK to be red)
static const Color duration         = Color(0xFF10B981);  // Emerald
static const Color personalRecord   = Color(0xFFFBBF24);  // Gold

// ---- WELLNESS COLORS (inspired by Whoop) ----
static const Color recovery         = Color(0xFF10B981);  // Green (high recovery)
static const Color recoveryMid      = Color(0xFFFBBF24);  // Amber (moderate)
static const Color recoveryLow      = Color(0xFFF97316);  // Orange (low — NOT red)
static const Color sleep            = Color(0xFF8B5CF6);  // Violet
static const Color stress           = Color(0xFF3B82F6);  // Blue
static const Color energy           = Color(0xFFF97316);  // Orange
```

### 3.5 Gradient Presets

```dart
// Hero gradient (CTAs, primary actions)
static const LinearGradient heroGradient = LinearGradient(
  colors: [Color(0xFFF97316), Color(0xFF8B5CF6)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

// Recovery gradient (recovery/sleep features)
static const LinearGradient recoveryGradient = LinearGradient(
  colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

// Progress gradient (achievements, gains)
static const LinearGradient progressGradient = LinearGradient(
  colors: [Color(0xFF10B981), Color(0xFF3B82F6)],
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
);

// Fire gradient (PRs, streaks)
static const LinearGradient fireGradient = LinearGradient(
  colors: [Color(0xFFF97316), Color(0xFFEF4444)],
  begin: Alignment.bottomCenter,
  end: Alignment.topCenter,
);

// Subtle surface gradient (card backgrounds)
static const LinearGradient surfaceGradient = LinearGradient(
  colors: [Color(0xFF141414), Color(0xFF1C1C1C)],
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
);
```

---

## 4. TYPOGRAPHY SYSTEM

### 4.1 Font Stack

| Role | Font | Weight | Usage |
|------|------|--------|-------|
| **Display / Coach Voice** | Playfair Display | 600-700 | Hero headlines, coach quotes, onboarding titles |
| **Heading** | Inter | 600-700 | Section headers, screen titles, card titles |
| **Body** | Inter | 400 | Paragraphs, descriptions, labels |
| **Data** | Inter (tabular) | 600-700 | Numbers, metrics, counters, timer displays |
| **Caption** | Inter | 400-500 | Timestamps, secondary labels, footnotes |
| **Mono** | JetBrains Mono | 400 | Code-like data (set numbers, timer MM:SS) |

### 4.2 Type Scale

```dart
// ---- DISPLAY (Playfair Display — Coach Voice) ----
static const TextStyle displayXL = TextStyle(
  fontFamily: 'Playfair',
  fontSize: 48,
  fontWeight: FontWeight.w700,
  height: 1.05,
  letterSpacing: -1.5,
  color: textPrimary,
);

static const TextStyle displayLarge = TextStyle(
  fontFamily: 'Playfair',
  fontSize: 36,
  fontWeight: FontWeight.w700,
  height: 1.1,
  letterSpacing: -1.0,
  color: textPrimary,
);

static const TextStyle displayMedium = TextStyle(
  fontFamily: 'Playfair',
  fontSize: 28,
  fontWeight: FontWeight.w600,
  height: 1.15,
  letterSpacing: -0.5,
  color: textPrimary,
);

// ---- HEADINGS (Inter) ----
static const TextStyle h1 = TextStyle(
  fontFamily: 'Inter',
  fontSize: 24,
  fontWeight: FontWeight.w700,
  height: 1.2,
  letterSpacing: -0.5,
  color: textPrimary,
);

static const TextStyle h2 = TextStyle(
  fontFamily: 'Inter',
  fontSize: 20,
  fontWeight: FontWeight.w600,
  height: 1.25,
  letterSpacing: -0.3,
  color: textPrimary,
);

static const TextStyle h3 = TextStyle(
  fontFamily: 'Inter',
  fontSize: 17,
  fontWeight: FontWeight.w600,
  height: 1.3,
  color: textPrimary,
);

// ---- BODY (Inter) ----
static const TextStyle bodyLarge = TextStyle(
  fontFamily: 'Inter',
  fontSize: 17,
  fontWeight: FontWeight.w400,
  height: 1.5,
  color: textPrimary,
);

static const TextStyle bodyMedium = TextStyle(
  fontFamily: 'Inter',
  fontSize: 15,
  fontWeight: FontWeight.w400,
  height: 1.5,
  color: textPrimary,
);

static const TextStyle bodySmall = TextStyle(
  fontFamily: 'Inter',
  fontSize: 13,
  fontWeight: FontWeight.w400,
  height: 1.4,
  color: textSecondary,
);

// ---- DATA (Inter Tabular) ----
static const TextStyle dataHero = TextStyle(
  fontFamily: 'Inter',
  fontSize: 56,
  fontWeight: FontWeight.w700,
  height: 1.0,
  letterSpacing: -2.0,
  fontFeatures: [FontFeature.tabularFigures()],
  color: textPrimary,
);

static const TextStyle dataLarge = TextStyle(
  fontFamily: 'Inter',
  fontSize: 32,
  fontWeight: FontWeight.w700,
  height: 1.1,
  letterSpacing: -0.5,
  fontFeatures: [FontFeature.tabularFigures()],
  color: textPrimary,
);

static const TextStyle dataMedium = TextStyle(
  fontFamily: 'Inter',
  fontSize: 24,
  fontWeight: FontWeight.w600,
  height: 1.2,
  fontFeatures: [FontFeature.tabularFigures()],
  color: textPrimary,
);

static const TextStyle dataSmall = TextStyle(
  fontFamily: 'Inter',
  fontSize: 18,
  fontWeight: FontWeight.w600,
  height: 1.3,
  fontFeatures: [FontFeature.tabularFigures()],
  color: textPrimary,
);

// ---- LABELS ----
static const TextStyle labelLarge = TextStyle(
  fontFamily: 'Inter',
  fontSize: 15,
  fontWeight: FontWeight.w600,
  height: 1.3,
  letterSpacing: 0.3,
  color: textPrimary,
);

static const TextStyle labelMedium = TextStyle(
  fontFamily: 'Inter',
  fontSize: 13,
  fontWeight: FontWeight.w500,
  height: 1.3,
  letterSpacing: 0.5,
  color: textSecondary,
);

static const TextStyle labelSmall = TextStyle(
  fontFamily: 'Inter',
  fontSize: 11,
  fontWeight: FontWeight.w500,
  height: 1.3,
  letterSpacing: 1.0,
  color: textTertiary,
);

// ---- SPECIAL ----
static const TextStyle timer = TextStyle(
  fontFamily: 'JetBrains Mono',
  fontSize: 48,
  fontWeight: FontWeight.w400,
  height: 1.0,
  letterSpacing: 2.0,
  color: textPrimary,
);

static const TextStyle accent = TextStyle(
  fontFamily: 'Inter',
  fontSize: 15,
  fontWeight: FontWeight.w600,
  color: accent,
);
```

### 4.3 Typography Rules

1. **ONE Playfair headline per screen** — The "coach voice" font is a premium accent, not a body font. Use it for the hero moment on each screen only.
2. **Tabular figures for ALL numbers** — Weight, reps, calories, macros, timers. Always use `FontFeature.tabularFigures()`.
3. **Max 3 font sizes per screen** — Don't mix display, h1, h2, h3 all on one screen. Pick a hierarchy and stick to it.
4. **Letter-spacing tightens as size increases** — Large text gets negative tracking, small text gets positive tracking.
5. **Line height: 1.5 for body, 1.1-1.2 for headings** — Body text needs breathing room; headlines should be tight.

---

## 5. SPACING & LAYOUT SYSTEM

### 5.1 Spacing Scale (4px base grid)

```dart
static const double s0  = 0;    // None
static const double s1  = 4;    // Tight (icon padding, inline spacing)
static const double s2  = 8;    // Compact (between related elements)
static const double s3  = 12;   // Default (card internal padding)
static const double s4  = 16;   // Standard (screen margins, card gaps)
static const double s5  = 20;   // Comfortable (between sections)
static const double s6  = 24;   // Generous (section dividers)
static const double s7  = 32;   // Spacious (hero sections)
static const double s8  = 40;   // Large (top padding for safe area)
static const double s9  = 48;   // XL (between major sections)
static const double s10 = 64;   // XXL (full-screen spacing)
static const double s11 = 80;   // Hero (landing/empty states)
static const double s12 = 96;   // Maximum (onboarding vertical spacing)
```

### 5.2 Screen Margins

```dart
static const double screenMarginHorizontal = 20;  // Standard horizontal margin
static const double screenMarginTop = 16;          // Below safe area
static const double screenMarginBottom = 16;       // Above bottom nav
static const double cardPadding = 16;              // Internal card padding
static const double cardGap = 12;                  // Between cards
```

### 5.3 Layout Grid

- **Single column** for all phone screens (no multi-column on mobile)
- **Card width**: `screenWidth - (2 * screenMarginHorizontal)`
- **Two-column grid** only for: exercise library grid, photo gallery
- **Horizontal scroll** for: workout day carousel, macro trend mini-charts

---

## 6. ELEVATION & DEPTH SYSTEM

### 6.1 Layer System (inspired by Whoop's minimal depth)

TransformFit uses **minimal shadows** and **subtle surface differentiation** instead of heavy Material elevation.

```
Layer 0: Canvas       (#0A0A0A) — Background
Layer 1: Surface       (#141414) — Cards, panels
Layer 2: Elevated      (#1C1C1C) — Bottom sheets, modals, popovers
Layer 3: Overlay       (#050505 at 80% opacity) — Modal backdrop
Layer 4: Glass         (white at 8%) — Floating elements, tooltips
```

### 6.2 Shadow System

```dart
// Subtle glow (default for cards)
static const List<BoxShadow> shadowSm = [
  BoxShadow(color: Color(0x0AF97316), blurRadius: 8, offset: Offset(0, 2)),
];

// Medium glow (elevated cards, active states)
static const List<BoxShadow> shadowMd = [
  BoxShadow(color: Color(0x14F97316), blurRadius: 16, offset: Offset(0, 4)),
];

// Strong glow (modals, hero elements)
static const List<BoxShadow> shadowLg = [
  BoxShadow(color: Color(0x1FF97316), blurRadius: 32, offset: Offset(0, 8)),
];

// No shadow (flat elements, list items)
static const List<BoxShadow> shadowNone = [];
```

### 6.3 Border Radius

```dart
static const double radiusXs  = 4;    // Tags, chips
static const double radiusSm  = 8;    // Buttons, inputs
static const double radiusMd  = 12;   // Cards, panels
static const double radiusLg  = 16;   // Large cards, modals
static const double radiusXl  = 24;   // Hero cards, bottom sheets
static const double radiusFull = 999; // Pills, avatars, circular elements
```

---

## 7. COMPONENT LIBRARY

### 7.1 Cards

#### TFCard (Standard Card)
```
┌──────────────────────────────────────┐
│ [Icon]  Title                 [Chevron] │
│         Description text               │
│         [Tag] [Tag] [Tag]              │
└──────────────────────────────────────┘
```
- Background: `surface` (#141414)
- Border: 1px `surfaceBorder` (#262626)
- Border radius: `radiusMd` (12px)
- Padding: `s4` (16px)
- Shadow: `shadowSm`

#### TFGlowingCard (Accent Card — for hero metrics)
```
┌──────────────────────────────────────┐
│  ╭─ gradient border glow ──────────╮ │
│  │                                 │ │
│  │   LABEL                         │ │
│  │   142g          ← dataHero      │ │
│  │   ▓▓▓▓▓▓▓░░░   ← progress bar  │ │
│  │   of 180g target                │ │
│  │                                 │ │
│  ╰─────────────────────────────────╯ │
└──────────────────────────────────────┘
```
- Background: `surface` with subtle gradient overlay
- Border: gradient from `accent` to `electric` (1px, animated on appear)
- Glow: `shadowMd` with accent tint
- Used for: hero metrics, macro rings, recovery score

#### TFSurfaceCard (Flat Card — for lists)
```
┌──────────────────────────────────────┐
│  Exercise Name              [PR badge] │
│  3 × 10 @ 80kg                       │
│  Last: 78kg × 10                     │
└──────────────────────────────────────┘
```
- Background: `surface` (#141414)
- Border: none
- Border radius: `radiusMd` (12px)
- Padding: `s3` (12px)
- Shadow: none

#### TFGlassCard (Glass Card — for overlays)
```
╭──────────────────────────────────────╮
│  ☁ Glass morphism effect             │
│  Background: 8% white + blur         │
│  Border: 1px surfaceBorder           │
╰──────────────────────────────────────╯
```
- Background: `Colors.white.withOpacity(0.08)` + backdrop blur
- Border: 1px `surfaceBorder`
- Border radius: `radiusLg` (16px)
- Used for: tooltips, floating info, overlays

### 7.2 Buttons

#### Primary Button (TFPrimaryButton)
```
┌─────────────────────────────────────┐
│           START WORKOUT             │
└─────────────────────────────────────┘
```
- Background: `accent` (#F97316)
- Text: `textInverse` (#0A0A0A), Inter 600, 15px
- Height: 52px
- Border radius: `radiusSm` (8px)
- Pressed: scale 0.97, brightness 0.9
- Disabled: 40% opacity

#### Secondary Button (TFSecondaryButton)
```
┌─────────────────────────────────────┐
│           VIEW DETAILS              │
└─────────────────────────────────────┘
```
- Background: `surface` (#141414)
- Border: 1px `surfaceBorder`
- Text: `textPrimary`, Inter 600, 15px
- Height: 52px
- Border radius: `radiusSm` (8px)

#### Ghost Button (TFGhostButton)
```
         Skip for now
```
- Background: transparent
- Text: `textSecondary`, Inter 500, 15px
- Height: 44px
- No border

#### Gradient Button (TFGradientButton)
```
┌═════════════════════════════════════┐
║        BEGIN TRANSFORMATION         ║
└═════════════════════════════════════┘
```
- Background: `heroGradient`
- Text: `textPrimary`, Inter 700, 16px
- Height: 56px
- Border radius: `radiusSm` (8px)
- Used for: primary CTAs in onboarding, plan reveal

#### Icon Button (TFIconButton)
```
  [←]  [⚙]  [+]  [⋯]
```
- Size: 44×44px (minimum touch target)
- Icon size: 24px
- Color: `textSecondary`
- Pressed: `textPrimary`

#### Pill Button (TFPillButton)
```
  ┌─────────┐
  │  Chest  │
  └─────────┘
```
- Background: `surface` (#141414)
- Border: 1px `surfaceBorder`
- Text: `textSecondary`, Inter 500, 13px
- Border radius: `radiusFull` (999px)
- Selected: background `accent`, text `textInverse`

### 7.3 Inputs

#### TFTextField
```
┌─────────────────────────────────────┐
│  Label                              │
│  ┌─────────────────────────────────┐│
│  │  Placeholder text               ││
│  └─────────────────────────────────┘│
│  Helper text                        │
└─────────────────────────────────────┘
```
- Background: `#151515`
- Border: 1px `surfaceBorder`
- Focused border: 1px `accent`
- Border radius: `radiusSm` (8px)
- Label: `labelMedium`, `textSecondary`
- Input text: `bodyMedium`, `textPrimary`
- Helper: `bodySmall`, `textTertiary`
- Error border: `critical`
- Error text: `critical`

#### TFNumberInput (for weight/reps)
```
    ┌─────────┐
    │   80    │
    │   kg    │
    └─────────┘
    [-]      [+]
```
- Large centered number: `dataLarge`
- Unit label below: `labelSmall`
- +/- buttons on sides: `TFIconButton` style
- Tap number → numpad keyboard

### 7.4 Navigation

#### Bottom Navigation Bar (TFBottomNav)
```
┌─────────────────────────────────────────┐
│  🏠      🏋️      ➕      📊      👤     │
│ Today  Workout  Log   Progress Profile  │
└─────────────────────────────────────────┘
```
- Background: `canvasDeep` (#050505) with glass blur
- Active icon: `accent` (#F97316)
- Inactive icon: `textTertiary` (#5A5A5A)
- Active label: `labelSmall`, `accent`
- Inactive label: `labelSmall`, `textTertiary`
- Center "+" button: `accent` background, 56px circle, elevated
- Height: 88px (including safe area)
- Border top: 1px `surfaceBorder`

#### Top App Bar (TFAppBar)
```
┌─────────────────────────────────────────┐
│  [←]    Screen Title            [⚙] [?] │
└─────────────────────────────────────────┘
```
- Background: transparent (scrolls behind content)
- Title: `h2`, `textPrimary`
- Icons: 24px, `textSecondary`
- Height: 56px
- Back button: `←` icon (not "Back" text)

#### Tab Bar (TFTabBar)
```
┌─────────────────────────────────────────┐
│  [Overview]  [Trends]  [Photos]  [Log]  │
│  ─────────                               │
└─────────────────────────────────────────┘
```
- Active tab: `textPrimary` + 2px `accent` underline
- Inactive tab: `textSecondary`
- Indicator: animated, 2px underline with accent color
- Height: 48px

### 7.5 Progress Indicators

#### TFProgressRing (inspired by Apple Fitness+ rings)
```
    ╭───╮
   ╱  87  ╲
  │  ╰──╯  │
   ╲      ╱
    ╰────╯
```
- Stroke width: 8px (outer), 6px (middle), 4px (inner)
- Gap between rings: 3px
- Background track: `surfaceBorder` at 30%
- Colors: `accent` (outer), `mint` (middle), `sky` (inner)
- Animation: sweep from 0 to value, 800ms ease-out
- Center: `dataMedium` value + `labelSmall` label

#### TFProgressBar (horizontal)
```
  ▓▓▓▓▓▓▓▓▓▓░░░░░░░░  65%
```
- Height: 6px
- Background: `surfaceBorder`
- Fill: `accent` (or semantic color)
- Border radius: `radiusFull`
- Animation: width grows from 0, 600ms ease-out

#### TFMetricTile (inspired by Whoop biometric tiles)
```
┌──────────┐
│  HRV     │
│  67 ms   │
│  ▲ +12%  │
└──────────┘
```
- Background: `surface`
- Border radius: `radiusMd`
- Padding: `s3`
- Label: `labelSmall`, `textTertiary`
- Value: `dataMedium`, `textPrimary`
- Delta: `labelSmall`, positive=`mint`, negative=`textSecondary` (never red)

### 7.6 Coach Components

#### TFCoachBubble (inspired by Ladder coach messaging)
```
  ┌─────────────────────────────────┐
  │  🧠 Coach                       │
  │                                 │
  │  "Your squat volume is trending │
  │   up. Keep the momentum — hit  │
  │   3×8 at 85kg today."          │
  │                                 │
  │  [Start Workout]  [Adjust]     │
  └─────────────────────────────────┘
```
- Background: `surfaceElevated` with left accent border (3px `electric`)
- Border radius: `radiusLg` (top-left radius: 4px for speech bubble effect)
- Avatar: 32px circle with gradient background
- Name: `labelLarge`, `electric`
- Message: `bodyMedium`, `textPrimary`
- Actions: `TFPillButton` row

#### TFSectionHeader
```
  TODAY'S FOCUS                  See All →
```
- Title: `h3`, `textPrimary`
- Action: `labelMedium`, `accent`
- Padding: horizontal `s4`, vertical `s2`

---

## 8. NAVIGATION ARCHITECTURE

### 8.1 Bottom Tab Structure (5 tabs)

```
┌─────────────────────────────────────────────────┐
│                                                 │
│              [Screen Content]                    │
│                                                 │
├─────────────────────────────────────────────────┤
│  🏠 Today  │  🏋️ Train  │  ➕  │  📊 Track  │  👤  │
└─────────────────────────────────────────────────┘
```

| Tab | Icon | Screen | Purpose |
|-----|------|--------|---------|
| **Today** | `home_filled` | `TodayScreen` | Daily dashboard, readiness, coach message |
| **Train** | `fitness_center` | `WorkoutHubScreen` | Active workout, exercise library, routines |
| **Log** (+) | `add_circle` | `QuickLogSheet` | Bottom sheet: quick log food/set/weight/mood |
| **Track** | `insights` | `ProgressHubScreen` | Trends, body composition, macros, photos |
| **Profile** | `person` | `ProfileScreen` | Settings, subscription, data export |

### 8.2 The "+" (Quick Log) Button

The center "+" button is **not a tab** — it opens a **bottom sheet** with quick-log options:

```
┌─────────────────────────────────────────┐
│  ═══ (drag handle)                      │
│                                         │
│  Quick Log                              │
│                                         │
│  🍽️  Log Food         🏋️  Log Set      │
│  ⚖️  Log Weight       😴  Log Sleep    │
│  💧  Log Water        🧠  Log Mood      │
│  📸  Log Photo        💊  Log Supplement│
│                                         │
└─────────────────────────────────────────┘
```

- Background: `surfaceElevated`
- Border radius: `radiusXl` (top corners only)
- Grid: 2 columns, each item is a card with icon + label
- Tap → navigates to the relevant logging screen/modal

### 8.3 Screen Hierarchy

```
/ (TodayScreen)
├── /workout (ActiveWorkoutScreen)
├── /exercises (ExerciseLibraryScreen)
├── /progress (ProgressScreen)
├── /composition (BodyCompositionScreen)
├── /trends (TrendsScreen)
├── /nutrition (NutritionDashboardScreen)
├── /wellness (WellnessDashboardScreen)
├── /gamification (GamificationDashboardScreen)
├── /coach (CoachCommandScreen)
├── /coach-chat (CoachChatScreen)
├── /debrief (DebriefScreen)
├── /proof (ProofCardScreen)
├── /profile (ProfileScreen)
├── /settings (SettingsScreen)
│   ├── /privacy-policy
│   ├── /terms
│   └── /data-export
├── /onboarding
│   ├── /landing
│   ├── /welcome
│   ├── /intake
│   ├── /plan-reveal
│   └── /handoff
└── /auth (AuthScreen)
```

---

## 9. SCREEN-BY-SCREEN SPECIFICATIONS

### 9.1 TodayScreen (Home Dashboard)

**Purpose**: The user's daily command center. Shows readiness, today's plan, coach message.

**Layout (top to bottom)**:
```
┌─────────────────────────────────────────┐
│  Good morning, [Name]           [⚙️]    │
│  Monday, July 6                         │
├─────────────────────────────────────────┤
│                                         │
│  ┌─────────────────────────────────┐    │
│  │  READINESS SCORE                │    │
│  │                                 │    │
│  │      ╭───────╮                  │    │
│  │     ╱   78    ╲    ← Ring      │    │
│  │    │   ╰───╯   │               │    │
│  │     ╲         ╱                 │    │
│  │      ╰───────╯                  │    │
│  │                                 │    │
│  │  Energy ████████░░  8/10        │    │
│  │  Sleep  ██████░░░░  6/10        │    │
│  │  Stress ██████████  10/10       │    │
│  │                                 │    │
│  │  [Adjust Readiness]             │    │
│  └─────────────────────────────────┘    │
│                                         │
│  ┌─────────────────────────────────┐    │
│  │  🧠 Coach                       │    │
│  │  "Solid recovery overnight.     │    │
│  │   Your squat volume is on       │    │
│  │   track — let's push 85kg       │    │
│  │   for 3×8 today."              │    │
│  │                                 │    │
│  │  [Start Workout]  [View Plan]   │    │
│  └─────────────────────────────────┘    │
│                                         │
│  TODAY'S PLAN                           │
│  ┌─────────────────────────────────┐    │
│  │  🏋️  Lower Body Power           │    │
│  │  Squat, RDL, Leg Press...       │    │
│  │  ~45 min  •  6 exercises        │    │
│  │  [Start]                        │    │
│  └─────────────────────────────────┘    │
│                                         │
│  QUICK STATS                            │
│  ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐  │
│  │Cal   │ │Prot  │ │Steps │ │Water │  │
│  │0     │ │0g    │ │0     │ │0L    │  │
│  │──────│ │──────│ │──────│ │──────│  │
│  │2200  │ │160g  │ │8000  │ │2.5L  │  │
│  └──────┘ └──────┘ └──────┘ └──────┘  │
│                                         │
│  [Log Food]  [Log Weight]  [Log Water]  │
│                                         │
└─────────────────────────────────────────┘
│  🏠    🏋️    ➕    📊    👤             │
└─────────────────────────────────────────┘
```

**Components used**: `TFAppBar`, `TFGlowingCard` (readiness), `TFCoachBubble`, `TFCard` (workout plan), `TFMetricTile` (quick stats), `TFProgressRing`, `TFPrimaryButton`, `TFBottomNav`

**Behavior**:
- Readiness ring animates on first appear (sweep from 0)
- Coach message loads async, shows shimmer while loading
- Quick stats update in real-time as user logs throughout the day
- Pull-to-refresh recalculates readiness
- Swipe left/right on readiness card to see yesterday/tomorrow

---

### 9.2 ActiveWorkoutScreen

**Purpose**: The in-workout experience. Log sets, track rest, see progress.

**Layout**:
```
┌─────────────────────────────────────────┐
│  [✕]  Lower Body Power      00:23:45   │
│       Day 12  •  Week 4                 │
├─────────────────────────────────────────┤
│                                         │
│  BARBELL BACK SQUAT                     │
│  Target: 3×8 @ 80kg                     │
│  ┌─────┬────────┬──────┬──────┬─────┐  │
│  │ Set │ Last   │ Weight│ Reps │  ✓  │  │
│  ├─────┼────────┼──────┼──────┼─────┤  │
│  │  1  │ 78×8   │ [80] │ [8]  │ [ ] │  │
│  │  2  │ 78×8   │ [  ] │ [  ] │ [ ] │  │
│  │  3  │ 78×8   │ [  ] │ [  ] │ [ ] │  │
│  └─────┴────────┴──────┴──────┴─────┘  │
│  + Add Set                              │
│                                         │
│  ─── Rest Timer ─────────────────────── │
│  ┌─────────────────────────────────┐    │
│  │          01:30                  │    │
│  │     ▓▓▓▓▓▓▓▓░░░░░░░░          │    │
│  │  [30s] [60s] [90s] [2:00] [+]  │    │
│  └─────────────────────────────────┘    │
│                                         │
│  ROMANIAN DEADLIFT                      │
│  Target: 3×10 @ 60kg                    │
│  (collapsed — tap to expand)            │
│                                         │
│  LEG PRESS                              │
│  Target: 3×12 @ 120kg                   │
│  (collapsed)                            │
│                                         │
├─────────────────────────────────────────┤
│  [+ Exercise]            [Finish Workout]│
└─────────────────────────────────────────┘
```

**Components used**: `TFTimerDisplay`, `TFSetLogTable`, `TFRestTimer`, `TFExerciseSection` (collapsible), `TFPrimaryButton` (Finish)

**Behavior**:
- Timer in app bar counts up during workout
- Set logging: tap weight → numpad overlay, tap reps → numpad overlay
- Checkmark tap → set complete, rest timer auto-starts
- Previous performance shown inline (from Strong pattern)
- PR badge appears when user beats previous best
- Exercise sections are collapsible (expanded = current exercise)
- "Finish Workout" → debrief screen

---

### 9.3 NutritionDashboardScreen

**Purpose**: Daily macro tracking with food logging.

**Layout**:
```
┌─────────────────────────────────────────┐
│  [←]  Nutrition          Today  [📅]    │
├─────────────────────────────────────────┤
│                                         │
│  ┌─────────────────────────────────┐    │
│  │      ╭───────╮                  │    │
│  │     ╱ 1,420  ╲    CALORIES     │    │
│  │    │  of 2200 │                  │    │
│  │     ╲  65%   ╱                  │    │
│  │      ╰───────╯                  │    │
│  │                                 │    │
│  │  Protein  ▓▓▓▓▓▓░░░░  98/160g  │    │
│  │  Carbs    ▓▓▓▓░░░░░░  120/250g │    │
│  │  Fat      ▓▓▓▓▓░░░░░  45/70g   │    │
│  │  Fiber    ▓▓▓░░░░░░░  12/30g   │    │
│  └─────────────────────────────────┘    │
│                                         │
│  MEALS                                  │
│  ┌─────────────────────────────────┐    │
│  │  Breakfast          420 cal     │    │
│  │  Oatmeal + protein shake        │    │
│  │  P:32g  C:58g  F:12g           │    │
│  └─────────────────────────────────┘    │
│  ┌─────────────────────────────────┐    │
│  │  Lunch              580 cal     │    │
│  │  Chicken rice bowl              │    │
│  │  P:42g  C:65g  F:18g           │    │
│  └─────────────────────────────────┘    │
│  ┌─────────────────────────────────┐    │
│  │  + Add Meal                     │    │
│  └─────────────────────────────────┘    │
│                                         │
│  [Log Food]  [Scan Barcode]  [Copy Yesterday]│
│                                         │
└─────────────────────────────────────────┘
```

**Components used**: `TFRingChart` (calories), `TFProgressBar` (macros), `TFMealCard`, `TFPrimaryButton`, `TFCameraButton` (barcode)

---

### 9.4 WellnessDashboardScreen

**Purpose**: Recovery, sleep, stress, mood tracking (inspired by Whoop).

**Layout**:
```
┌─────────────────────────────────────────┐
│  [←]  Wellness          Today  [📅]     │
├─────────────────────────────────────────┤
│                                         │
│  ┌─────────────────────────────────┐    │
│  │      ╭───────╮                  │    │
│  │     ╱   78    ╲    RECOVERY     │    │
│  │    │          │                  │    │
│  │     ╲        ╱     Good         │    │
│  │      ╰───────╯                  │    │
│  │                                 │    │
│  │  HRV: 67ms  •  RHR: 58bpm      │    │
│  │  Sleep: 7.2h  •  SpO2: 97%     │    │
│  └─────────────────────────────────┘    │
│                                         │
│  ┌──────────┐  ┌──────────┐             │
│  │ SLEEP    │  │ STRESS   │             │
│  │ 7.2h     │  │ Low      │             │
│  │ ▓▓▓▓▓▓░░ │  │ ▓▓░░░░░░ │             │
│  │ Quality  │  │ Score: 3 │             │
│  └──────────┘  └──────────┘             │
│                                         │
│  ┌──────────┐  ┌──────────┐             │
│  │ ENERGY   │  │ MOOD     │             │
│  │ 8/10     │  │ 😊 Good  │             │
│  │ ▓▓▓▓▓▓▓░ │  │ Today    │             │
│  │          │  │          │             │
│  └──────────┘  └──────────┘             │
│                                         │
│  WEEKLY TRENDS                          │
│  ┌─────────────────────────────────┐    │
│  │  Recovery  ▁▂▃▅▆▇█▇▆▅          │    │
│  │  Sleep     ▂▃▃▄▅▅▆▆▅▄          │    │
│  │  Stress    ▅▅▄▃▃▂▂▃▃▄          │    │
│  └─────────────────────────────────┘    │
│                                         │
│  [Log Mood]  [Log Sleep]  [Breathing]   │
│                                         │
└─────────────────────────────────────────┘
```

**Components used**: `TFProgressRing` (recovery), `TFMetricTile`, `TFSparkLine` (trends), `TFPrimaryButton`

---

### 9.5 ProgressScreen (Track Hub)

**Purpose**: Long-term progress tracking across all dimensions.

**Layout**:
```
┌─────────────────────────────────────────┐
│  [←]  Progress                          │
├─────────────────────────────────────────┤
│                                         │
│  [Overview]  [Body]  [Lifts]  [Photos]  │
│  ─────────                               │
│                                         │
│  OVERVIEW TAB                           │
│                                         │
│  WEIGHT TREND                           │
│  ┌─────────────────────────────────┐    │
│  │  82.5 kg                        │    │
│  │  ▲ -1.2 kg this week            │    │
│  │                                 │    │
│  │     ╲                           │    │
│  │      ╲____╱╲___╱╲___           │    │
│  │                       ╲___      │    │
│  │  Jun 1 ─────────────── Jul 6   │    │
│  └─────────────────────────────────┘    │
│                                         │
│  BODY COMPOSITION                       │
│  ┌──────────┐  ┌──────────┐             │
│  │ Muscle   │  │ Body Fat │             │
│  │ +0.8 kg  │  │ -0.5%    │             │
│  │ ▲ This   │  │ ▼ This   │             │
│  │ month    │  │ month    │             │
│  └──────────┘  └──────────┘             │
│                                         │
│  LIFT PROGRESS                          │
│  ┌─────────────────────────────────┐    │
│  │  Squat      120kg → 130kg ▲     │    │
│  │  Bench       80kg →  85kg ▲     │    │
│  │  Deadlift   140kg → 150kg ▲     │    │
│  │  OHP         50kg →  55kg ▲     │    │
│  └─────────────────────────────────┘    │
│                                         │
│  VOLUME THIS WEEK                       │
│  ┌─────────────────────────────────┐    │
│  │  ████████████░░░░░  42,500 kg   │    │
│  │  Target: 55,000 kg              │    │
│  └─────────────────────────────────┘    │
│                                         │
└─────────────────────────────────────────┘
```

---

### 9.6 CoachChatScreen

**Purpose**: Conversational AI coaching interface.

**Layout**:
```
┌─────────────────────────────────────────┐
│  [←]  Coach                    [⋯]      │
├─────────────────────────────────────────┤
│                                         │
│  ┌─────────────────────────────────┐    │
│  │  🧠 Coach                       │    │
│  │  How are you feeling after      │    │
│  │  yesterday's session?           │    │
│  └─────────────────────────────────┘    │
│                                         │
│         ┌──────────────────────────┐    │
│         │ Pretty good! Slight      │    │
│         │ soreness in my quads.    │    │
│         └──────────────────────────┘    │
│                                         │
│  ┌─────────────────────────────────┐    │
│  │  🧠 Coach                       │    │
│  │  That's expected — you hit a    │    │
│  │  new volume PR on squats.       │    │
│  │  Today I'd recommend upper body │    │
│  │  to let those recover.          │    │
│  │                                 │    │
│  │  [Show Upper Body Plan]         │    │
│  └─────────────────────────────────┘    │
│                                         │
│                                         │
├─────────────────────────────────────────┤
│  ┌─────────────────────────────┐ [Send] │
│  │  Type a message...          │        │
│  └─────────────────────────────┘        │
└─────────────────────────────────────────┘
```

---

### 9.7 ExerciseLibraryScreen

**Purpose**: Browse and search exercises.

**Layout**:
```
┌─────────────────────────────────────────┐
│  [←]  Exercises                         │
│  ┌─────────────────────────────────┐    │
│  │  🔍 Search exercises...         │    │
│  └─────────────────────────────────┘    │
│                                         │
│  [All] [Chest] [Back] [Legs] [Arms]     │
│  [Shoulders] [Core] [Cardio]            │
│                                         │
│  COMPOUND                               │
│  ┌─────────────────────────────────┐    │
│  │  Barbell Back Squat             │    │
│  │  Quads, Glutes, Hamstrings      │    │
│  │  [Compound] [Barbell]           │    │
│  └─────────────────────────────────┘    │
│  ┌─────────────────────────────────┐    │
│  │  Bench Press                    │    │
│  │  Chest, Triceps, Shoulders      │    │
│  │  [Compound] [Barbell]           │    │
│  └─────────────────────────────────┘    │
│                                         │
│  ISOLATION                              │
│  ┌─────────────────────────────────┐    │
│  │  Bicep Curl                     │    │
│  │  Biceps                         │    │
│  │  [Isolation] [Dumbbell]         │    │
│  └─────────────────────────────────┘    │
│                                         │
└─────────────────────────────────────────┘
```

---

### 9.8 DebriefScreen (Post-Workout)

**Purpose**: Reflect on workout, log RPE, satisfaction.

**Layout**:
```
┌─────────────────────────────────────────┐
│                                         │
│         Workout Complete! 🎉            │
│                                         │
│  ┌─────────────────────────────────┐    │
│  │  Lower Body Power               │    │
│  │  00:47:23  •  18 sets           │    │
│  │                                 │    │
│  │  Volume: 24,500 kg              │    │
│  │  ▲ +3,200 kg vs last session    │    │
│  │                                 │    │
│  │  PRs: Squat 130kg × 8          │    │
│  └─────────────────────────────────┘    │
│                                         │
│  How hard was this session?             │
│  RPE:  ████████░░  8/10                │
│                                         │
│  How satisfied are you?                 │
│  ┌────┐ ┌────┐ ┌────┐ ┌────┐ ┌────┐  │
│  │ 😫 │ │ 😕 │ │ 😐 │ │ 🙂 │ │ 🔥 │  │
│  └────┘ └────┘ └────┘ └────┘ └────┘  │
│                                         │
│  Any notes?                             │
│  ┌─────────────────────────────────┐    │
│  │  Felt strong today. Need to     │    │
│  │  work on hip mobility...        │    │
│  └─────────────────────────────────┘    │
│                                         │
│  [Save & Share]  [Save]  [Skip]         │
│                                         │
└─────────────────────────────────────────┘
```

---

### 9.9 Onboarding Flow

#### 9.9.1 LandingScreen
```
┌─────────────────────────────────────────┐
│                                         │
│                                         │
│         TransformFit                    │
│                                         │
│     "Your body, transformed."           │
│                                         │
│     [gradient hero illustration]        │
│                                         │
│                                         │
│  ┌─────────────────────────────────┐    │
│  │     BEGIN TRANSFORMATION        │    │
│  └─────────────────────────────────┘    │
│                                         │
│         Already have an account?        │
│              Sign In                    │
│                                         │
└─────────────────────────────────────────┘
```

#### 9.9.2 IntakeScreen (Multi-step)
```
Step 1: Goal Selection
┌─────────────────────────────────────────┐
│  What's your primary goal?              │
│                                         │
│  ┌─────────────┐  ┌─────────────┐      │
│  │  💪 Build   │  │  🔥 Lose    │      │
│  │  Muscle     │  │  Fat        │      │
│  └─────────────┘  └─────────────┘      │
│  ┌─────────────┐  ┌─────────────┐      │
│  │  ⚡ Get     │  │  🏃 General │      │
│  │  Stronger   │  │  Fitness    │      │
│  └─────────────┘  └─────────────┘      │
│                                         │
│  ● ○ ○ ○ ○  (progress dots)            │
│              [Next →]                   │
└─────────────────────────────────────────┘
```

Step 5: Plan Reveal
```
┌─────────────────────────────────────────┐
│                                         │
│     Your Plan is Ready                  │
│                                         │
│     [animated plan card reveal]         │
│                                         │
│  ┌─────────────────────────────────┐    │
│  │  4 days/week                    │    │
│  │  Upper/Lower Split              │    │
│  │  ~50 min sessions               │    │
│  │                                 │    │
│  │  Week 1: Foundation             │    │
│  │  Week 2: Build                  │    │
│  │  Week 3: Push                   │    │
│  │  Week 4: Deload                  │    │
│  └─────────────────────────────────┘    │
│                                         │
│  ┌─────────────────────────────────┐    │
│  │    START FIRST SESSION          │    │
│  └─────────────────────────────────┘    │
│                                         │
└─────────────────────────────────────────┘
```

---

### 9.10 GamificationDashboardScreen

**Purpose**: XP, levels, streaks, achievements.

**Layout**:
```
┌─────────────────────────────────────────┐
│  [←]  Achievements                      │
├─────────────────────────────────────────┤
│                                         │
│  ┌─────────────────────────────────┐    │
│  │  LEVEL 12                       │    │
│  │  ██████████████░░░░  1,420 XP   │    │
│  │  580 XP to Level 13             │    │
│  └─────────────────────────────────┘    │
│                                         │
│  ┌──────────┐  ┌──────────┐             │
│  │ 🔥       │  │ 💪       │             │
│  │ 12 days  │  │ 47       │             │
│  │ streak   │  │ workouts │             │
│  └──────────┘  └──────────┘             │
│                                         │
│  RECENT ACHIEVEMENTS                    │
│  ┌─────────────────────────────────┐    │
│  │  🏆 100 Club                    │    │
│  │  Completed 100 workouts         │    │
│  │  Unlocked 2 days ago            │    │
│  └─────────────────────────────────┘    │
│  ┌─────────────────────────────────┐    │
│  │  ⭐ Consistency King            │    │
│  │  30-day streak                  │    │
│  │  In progress: 12/30             │    │
│  └─────────────────────────────────┘    │
│                                         │
└─────────────────────────────────────────┘
```

---

### 9.11 TrendsScreen

**Purpose**: Long-term trend analysis.

**Layout**:
```
┌─────────────────────────────────────────┐
│  [←]  Trends                            │
├─────────────────────────────────────────┤
│                                         │
│  [Weight] [Volume] [Macros] [Sleep]     │
│  ────────                                │
│                                         │
│  WEIGHT TREND                           │
│  ┌─────────────────────────────────┐    │
│  │  Current: 82.5 kg               │    │
│  │  30-day change: -2.1 kg         │    │
│  │  Rate: -0.5 kg/week             │    │
│  │                                 │    │
│  │  [line chart with touch inspect] │    │
│  │                                 │    │
│  │  Predicted goal date: Aug 15    │    │
│  └─────────────────────────────────┘    │
│                                         │
│  RECOMMENDATION                         │
│  ┌─────────────────────────────────┐    │
│  │  🧠 "You're losing at the right │    │
│  │  rate. No changes needed."      │    │
│  └─────────────────────────────────┘    │
│                                         │
└─────────────────────────────────────────┘
```

---

## 10. DATA VISUALIZATION

### 10.1 Chart Types

| Chart | Use Case | Library | Style |
|-------|----------|---------|-------|
| **Ring Chart** | Calories, recovery, readiness | Custom Painter | 3 arcs, animated sweep |
| **Line Chart** | Weight, volume, sleep trends | fl_chart | Smooth curves, touch inspect |
| **Bar Chart** | Weekly volume, macro distribution | fl_chart | Rounded top corners, gradient fill |
| **Spark Line** | Inline trends in metric tiles | Custom Painter | Single color, no axis, minimal |
| **Stacked Bar** | Macro breakdown per meal | fl_chart | Protein/cyan, carbs/gold, fat/orange |
| **Area Chart** | Cumulative volume, step count | fl_chart | Gradient fill below line |

### 10.2 Chart Design Rules

1. **No axis labels by default** — Show values on touch/hover only
2. **Smooth curves** — Use `isCurved: true` for line charts, never straight segments
3. **Gradient fills** — Area charts use a gradient from line color to transparent
4. **Touch inspect** — All charts support touch-to-inspect with a vertical line + tooltip
5. **Minimal gridlines** — At most 3 horizontal reference lines, dashed, at 25%/50%/75%
6. **Color coding** — Use semantic colors from Section 3.4
7. **Animation** — Charts animate on first appear (600ms ease-out)
8. **Empty state** — Show a dotted line at target value with "No data yet" message

### 10.3 The Readiness Ring (TransformFit's signature visual)

Inspired by Whoop's recovery circle and Apple's activity rings:

```
        ╭──────────╮
      ╱   ╭────╮     ╲
    ╱    ╱  78   ╲     ╲
   │    │         │     │
   │    │  Ready  │     │
    ╲    ╲       ╱     ╱
      ╲   ╰────╯    ╱
        ╰──────────╯

  Outer ring:  Readiness (accent color, 8px stroke)
  Middle ring: Energy (mint, 6px stroke)  
  Inner ring:  Sleep quality (electric, 4px stroke)
```

- Background track: `surfaceBorder` at 30% opacity
- Fill: gradient from ring start color to end color
- Gap between rings: 3px
- Animation: 800ms sweep from 0° to target°
- Value color matches ring color at 100% opacity

---

## 11. ANIMATION & MOTION DESIGN

### 11.1 Timing Functions

```dart
// Standard easing (most transitions)
static const Curve easeOut = Curves.easeOut;        // Entering elements
static const Curve easeIn = Curves.easeIn;           // Exiting elements
static const Curve easeInOut = Curves.easeInOut;     // State changes

// Spring (for interactive/bouncy elements)
static const Curve spring = Curves.elasticOut;       // Celebrations, PRs
static const Curve springGentle = Curves.easeOutBack; // Subtle bounce

// Linear (for progress bars, timers)
static const Curve linear = Curves.linear;           // Timers, loading bars
```

### 11.2 Duration Scale

```dart
static const Duration micro    = Duration(milliseconds: 100);  // Button press feedback
static const Duration fast     = Duration(milliseconds: 200);  // Tab switches, toggles
static const Duration normal   = Duration(milliseconds: 350);  // Card transitions, reveals
static const Duration slow     = Duration(milliseconds: 600);  // Chart animations, ring sweeps
static const Duration epic     = Duration(milliseconds: 1200); // Celebrations, onboarding
```

### 11.3 Animation Map

| Element | Trigger | Animation | Duration | Curve |
|---------|---------|-----------|----------|-------|
| Card appear | Screen load | Fade in + slide up 20px | 350ms | easeOut |
| Ring/progress | Data load | Sweep from 0 to value | 800ms | easeOut |
| Button press | Tap | Scale to 0.97 | 100ms | easeIn |
| Tab switch | Tap | Fade + horizontal slide | 200ms | easeInOut |
| Set checkmark | Tap | Scale 0→1.2→1 + color fill | 300ms | spring |
| PR badge | Trigger | Scale 0→1 + glow pulse | 600ms | spring |
| Streak celebration | Milestone | Confetti + ring pulse + haptic | 1200ms | spring |
| Coach message | New message | Fade in + slide up from bottom | 350ms | easeOut |
| Number counter | Value change | Count up/down to target | 400ms | easeOut |
| Rest timer | Set complete | Expand from exercise header | 300ms | easeOut |
| Bottom sheet | "+" tap | Slide up from bottom | 350ms | easeOut |
| Skeleton loading | Async wait | Shimmer left-to-right | 1500ms | linear (loop) |

### 11.4 Haptic Feedback Map

| Action | Haptic Type | When |
|--------|-------------|------|
| Button tap | `HapticFeedback.lightImpact()` | Every tappable element |
| Set complete | `HapticFeedback.mediumImpact()` | Checkmark tapped |
| PR achieved | `HapticFeedback.heavyImpact()` | New personal record |
| Rest timer 0 | `HapticFeedback.heavyImpact()` × 3 | Timer reaches 0:00 |
| Ring complete | `HapticFeedback.heavyImpact()` | 100% on any ring |
| Level up | `HapticFeedback.heavyImpact()` + pattern | XP level milestone |
| Swipe gesture | `HapticFeedback.selectionClick()` | Swipe between days/tabs |
| Error | `HapticFeedback.vibrate()` | Validation failure |

---

## 12. ACCESSIBILITY REQUIREMENTS

### 12.1 Color Contrast

| Element | Minimum Ratio | Target Ratio |
|---------|---------------|--------------|
| Body text on background | 4.5:1 | 7:1 |
| Large text (≥18px) on background | 3:1 | 4.5:1 |
| Interactive elements | 3:1 against adjacent | 4.5:1 |
| Focus indicators | 3:1 against background | 4.5:1 |

**Verification**: All color combinations in Section 3 MUST pass WCAG AA. Use `textPrimary` (#F0EDE8) on `canvas` (#0A0A0A) = 17.8:1 ✓. Use `textSecondary` (#8A8A8A) on `surface` (#141414) = 5.2:1 ✓.

### 12.2 Touch Targets

- **Minimum touch target**: 44×44 points (iOS HIG) / 48×48 dp (Material)
- **Spacing between targets**: ≥8dp
- **All interactive elements** must have `Semantics` labels

### 12.3 Screen Reader Support

```dart
// Every image, icon, and chart must have semantics
Semantics(
  label: 'Recovery score: 78 out of 100. Good recovery.',
  child: TFProgressRing(value: 0.78, label: 'Recovery'),
);

// Every button must have a clear action label
Semantics(
  label: 'Start workout. Lower body power, 6 exercises, approximately 45 minutes.',
  button: true,
  child: TFPrimaryButton(text: 'Start Workout', onPressed: ...),
);
```

### 12.4 Dynamic Type Support

- All text must scale with system font size (up to 200%)
- Use `MediaQuery.textScaleFactor` to adjust layouts
- Data-hero text should scale down gracefully at very large sizes
- Cards should reflow to single-column at large text sizes

### 12.5 Reduced Motion

```dart
// Check for reduced motion preference
final reduceMotion = MediaQuery.of(context).disableAnimations;

// If true:
// - Skip all entrance animations
// - Replace sweep animations with instant state
// - Remove confetti/celebration effects
// - Keep functional animations (loading indicators)
```

### 12.6 Color Blindness

- Never use color alone to convey information
- Always pair color with: icon, text label, pattern, or position
- Recovery ring uses both color AND numeric value
- Macro bars use both color AND text label (P/C/F)
- PR badges use both color AND icon (⭐)

---

## 13. DARK MODE EXCELLENCE STANDARDS

TransformFit is **dark-only**. These standards ensure the dark experience is premium:

### 13.1 Surface Hierarchy

```
Canvas (#0A0A0A)        — Background, never used for cards
Surface (#141414)        — Card backgrounds, list items
Elevated (#1C1C1C)       — Bottom sheets, modals, popovers
Pressed (#222222)        — Active/pressed state of interactive elements
Border (#262626)         — Subtle separation between elements
Glass (8% white + blur)  — Floating overlays, tooltips
```

### 13.2 Text Hierarchy

```
Primary (#F0EDE8)    — Headlines, body text, data values
Secondary (#8A8A8A)  — Labels, descriptions, timestamps
Tertiary (#5A5A5A)   — Disabled text, placeholders, hints
Inverse (#0A0A0A)    — Text on accent-colored backgrounds
```

### 13.3 Dark Mode Rules

1. **Never use pure white (#FFFFFF) for text** — Use `textPrimary` (#F0EDE8) which is warm white, reducing eye strain
2. **Never use pure black (#000000) for backgrounds** — Use `canvas` (#0A0A0A) which has subtle warmth
3. **Borders must be subtle** — 1px, `surfaceBorder` color, never more visible than the content they separate
4. **Shadows must be tinted** — Use accent-tinted shadows (orange glow), not black shadows which are invisible on dark backgrounds
5. **Cards use surface color, not canvas** — There must be visible differentiation between card and background
6. **Accent color on dark backgrounds MUST meet 4.5:1 contrast** — Orange (#F97316) on dark surface (#141414) = 4.8:1 ✓
7. **Glass effects use white at ≤10% opacity** — Too much white washes out the dark aesthetic
8. **Images/videos should have subtle dark overlay** — 10-20% black overlay on media to blend with dark UI
9. **Status bar must be light** — `SystemUiOverlayStyle.light` for all screens
10. **No light mode, no toggle, no theme switch** — This is a design decision, not a preference

---

## 14. ICONOGRAPHY

### 14.1 Icon Set

Use **Material Symbols Rounded** (outlined style, 24px default):

| Category | Icons |
|----------|-------|
| Navigation | `home_filled`, `fitness_center`, `add_circle`, `insights`, `person` |
| Workout | `fitness_center`, `timer`, `repeat`, `check_circle`, `add`, `remove` |
| Nutrition | `restaurant`, `local_dining`, `water_drop`, `egg_alt`, `barcode_scanner` |
| Wellness | `bedtime`, `self_improvement`, `mood`, `monitor_heart`, `spa` |
| Progress | `trending_up`, `photo_camera`, `timeline`, `analytics` |
| Social | `share`, `favorite`, `comment`, `group` |
| Settings | `settings`, `logout`, `privacy_tip`, `description`, `download` |
| Navigation | `arrow_back`, `arrow_forward`, `close`, `more_vert`, `search` |

### 14.2 Icon Rules

- **Size**: 24px default, 20px in compact areas, 32px for hero icons
- **Color**: `textSecondary` for inactive, `accent` for active/featured
- **Weight**: Outlined (not filled) for inactive states, filled for active states
- **Touch target**: Minimum 44×44px even if icon is smaller

---

## 15. HAPTIC FEEDBACK MAP

| Screen | Action | Haptic | Purpose |
|--------|--------|--------|---------|
| **All** | Button tap | Light | Physical feedback for every tap |
| **Workout** | Set checkmark | Medium | Completion satisfaction |
| **Workout** | PR detected | Heavy | Celebration |
| **Workout** | Rest timer zero | Heavy ×3 | Attention grab |
| **Wellness** | Mood selection | Selection | Choice feedback |
| **Nutrition** | Food logged | Light | Confirmation |
| **Progress** | Chart touch inspect | Selection | Data point feedback |
| **Gamification** | Level up | Heavy + pattern | Major celebration |
| **Gamification** | Achievement unlock | Heavy | Reward |
| **Onboarding** | Goal selected | Medium | Commitment feedback |
| **Onboarding** | Plan revealed | Heavy + pattern | Anticipation → reveal |
| **Coach** | New message | Light | Notification |
| **General** | Pull-to-refresh | Light | Refresh feedback |
| **General** | Swipe gesture | Selection | Directional feedback |

---

## APPENDIX A: IMPLEMENTATION CHECKLIST

When implementing any screen, verify:

- [ ] All colors reference tokens from Section 3 (no hardcoded hex values)
- [ ] All text uses styles from Section 4 (no inline TextStyle)
- [ ] All spacing uses values from Section 5 (no arbitrary padding/margin)
- [ ] All border radius uses values from Section 6
- [ ] Components match patterns from Section 7
- [ ] Navigation follows architecture from Section 8
- [ ] Screen layout matches specification from Section 9
- [ ] Charts follow rules from Section 10
- [ ] Animations use timing from Section 11
- [ ] Accessibility requirements from Section 12 are met
- [ ] Dark mode rules from Section 13 are followed
- [ ] Icons from Section 14 are used
- [ ] Haptics from Section 15 are implemented

## APPENDIX B: TOKEN MIGRATION FROM V2

The v2 tokens (`DigitalAtelierTokens2`) map to v3 as follows:

| V2 Token | V3 Token | Change |
|----------|----------|--------|
| `background` (0xFF0A0A0A) | `canvas` | Renamed for clarity |
| `surface` (0xFF111111) | `surface` → `0xFF141414` | Slightly lighter for better card contrast |
| `surfaceElevated` (0xFF1A1A1A) | `surfaceElevated` → `0xFF1C1C1C` | Adjusted |
| `accentOrange` (0xFFF97316) | `accent` | Kept, expanded with muted/glow variants |
| `textPrimary` (0xFFF0EDE8) | `textPrimary` | Kept (warm white) |
| `success` (0xFF10B981) | `positive` + `mint` | Split into semantic + data viz |
| `warning` (0xFFF59E0B) | `caution` | Renamed to reduce alarm |
| `info` (0xFF3B82F6) | `sky` + `info` | Split into semantic + data viz |
| `calm` (0xFF6366F1) | `electric` | Renamed for clarity |
| `recovery` (0xFF8B5CF6) | `electric` | Merged with calm/violet |
| `cornerRadius` (4) | `radiusXs` (4) | Kept, expanded scale |

**New tokens to add**: `canvasDeep`, `canvasSubtle`, `surfacePressed`, `surfaceGlass`, `textTertiary`, `textInverse`, `accentMuted`, `accentGlow`, `protein`, `carbs`, `fat`, `fiber`, `calories`, `muscleMass`, `bodyFat`, `weight`, `volume`, `intensity`, `duration`, `personalRecord`, `recoveryMid`, `recoveryLow`, `sleep`, `stress`, `energy`, `electric`, `electricMuted`, `mint`, `mintMuted`, `sky`, `skyMuted`, `coral`, `coralMuted`, `fireGradient`, `surfaceGradient`

## APPENDIX C: COMPETITIVE DESIGN SCORECARD

| Criterion | MacroFactor | Ladder | Whoop | Apple Fitness+ | Fitbod | Hevy | Strong | **TransformFit Target** |
|-----------|------------|--------|-------|----------------|--------|------|--------|------------------------|
| Dark mode | ★★★★★ | ★★★★ | ★★★★★ | ★★★★★ | ★★★★ | ★★★★ | ★★★★ | ★★★★★ |
| Data density | ★★★★★ | ★★★ | ★★★★★ | ★★★ | ★★★★ | ★★★ | ★★★★ | ★★★★★ |
| Logging speed | ★★★★★ | ★★★ | ★★ | ★★ | ★★★ | ★★★★ | ★★★★★ | ★★★★★ |
| Visual polish | ★★★★ | ★★★★ | ★★★★★ | ★★★★★ | ★★★ | ★★★★ | ★★★ | ★★★★★ |
| Coaching | ★★★★★ | ★★★★★ | ★★★ | ★★★ | ★★★ | ★★ | ★ | ★★★★★ |
| Gamification | ★★ | ★★ | ★★ | ★★★★ | ★★ | ★★★ | ★ | ★★★★ |
| Accessibility | ★★★ | ★★★ | ★★★★ | ★★★★★ | ★★★ | ★★★ | ★★★★ | ★★★★★ |

**TransformFit target: Best-in-class across all dimensions.**

---

*This specification is binding law for all TransformFit screen implementations. Every pixel must conform.*
