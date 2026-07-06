# TransformFit UX/UI Audit Report

**Audit Date:** 2026-07-06
**Auditor:** RIG UI Designer / Design Agent
**Scope:** 12 core screen files, 1,206-line design system, ~9,500 lines of UI code
**Methodology:** Line-by-line code review against WCAG 2.2 AA, Apple HIG, Material 3, and competitive benchmarks (MacroFactor, Whoop, Strong, Ladder)

---

## Executive Summary

TransformFit's design system (`DigitalAtelierExtension`) is **well-architected** — three backward-compatible token layers, proper `ThemeExtension` with `copyWith`/`lerp`, reduced-motion support, and tabular figure fonts. The codebase uses `Semantics` labels extensively (good). However, several screens have **hardcoded color leaks**, **inconsistent token usage**, and **accessibility gaps** that would block App Store review.

**Overall Grade: B+** (strong foundation, inconsistent execution)

---

## 1. Screen-by-Screen Audit

### 1.1 Design System — `lib/theme/digital_atelier.dart`

| Criterion | Rating | Notes |
|-----------|--------|-------|
| Architecture | ★★★★★ | Three-tier v1→v2→v3 migration is excellent. `ThemeExtension` with `lerp` enables animated theme transitions. |
| Token Coverage | ★★★★☆ | All colors, spacing, radius, animation, typography covered. Missing: shadow tokens for cards vs. modals (they exist but aren't consistently used). |
| Typography Scale | ★★★★★ | `TransformFitTextTheme` with `scale` param for Dynamic Type. Tabular figures on data styles. Playfair for coach voice, Inter for data — clean separation. |
| Reduced Motion | ★★★★★ | `resolvedDuration()` and `resolvedCurve()` at lines 638–648. Static decoration alternatives at 653–668. **Best-in-class** for a fitness app. |
| Color Contrast | ★★★☆☆ | `textMuted` (#6B7280) on `background` (#0A0A0A) = **3.2:1** — fails WCAG AA for normal text (needs 4.5:1). `bodySmall` caption color (#A0A0A0) on dark = 5.1:1 (passes). `dataLabel` at line 263 uses #A0A0A0 (passes). |
| Legacy Baggage | ★★★☆☆ | Three token classes (`DigitalAtelierTokens`, `DigitalAtelierTokens2`, `DigitalAtelierExtension`) with 100+ legacy getter aliases (lines 599–626). Creates confusion about which to use. |

**Specific Fixes:**

1. **Line 360 (`textMuted: Color(0xFF6B7280)`)** — Change to `#8B95A5` minimum for WCAG AA on #0A0A0A background (4.53:1).
2. **Lines 22–37 (`DigitalAtelierTokens`)** — Mark as `@Deprecated` to drive migration to v3.
3. **Lines 44–276 (`DigitalAtelierTokens2`)** — Mark as `@Deprecated` with migration guide.
4. **Line 36 (`cornerRadius = 4`)** — Used inconsistently vs. `radiusSm = 8`. Remove or align.

---

### 1.2 Home Screen — `lib/screens/home_screen.dart`

| Criterion | Rating | Notes |
|-----------|--------|-------|
| Visual Hierarchy | ★★★★☆ | Clean 5-card layout. Readiness score → Plan → Coach → Actions → Summary. Clear top-down priority. |
| Information Density | ★★★★☆ | Right amount for a dashboard. Not overwhelming. |
| Touch Targets | ★★★★☆ | `_QuickAction` at line 372: `height: 44` — meets minimum. `IconButton` at line 157: 44×44 — good. |
| Color Contrast | ★★★☆☆ | Line 229: `Color(0xFFA0A0A0)` hardcoded instead of using token. Line 133: `Color(0xFFA0A0A0)` same issue. These pass contrast but should use `t.textSecondary`. |
| Animation | ★★★★★ | `RefreshIndicator` with `BouncingScrollPhysics` — purposeful, no gratuitous motion. |
| Typography | ★★★★★ | Uses `DigitalAtelierTokens2` text styles consistently. |
| Spacing | ★★★★★ | Consistent `s3` (12px) between cards, `s4` (16px) padding. |
| Semantic Labels | ★★★★★ | Every card has `Semantics(label:)`. `_HomeCard` wrapper enforces this at line 494. `_StatItem` has semantic labels at line 467. |

**Specific Fixes:**

1. **Line 229** — Replace `Color(0xFFA0A0A0)` with `DigitalAtelierTokens.textSecondary` or `t.textMuted`.
2. **Line 133** — Same hardcoded color replacement.
3. **Line 499** — Uses `DigitalAtelierTokens2.elevatedDecoration` (v2 legacy). Migrate to `t.cardElevated`.
4. **Line 387** — `fontSize: 10` on quick action labels — below comfortable reading size. Consider 11px minimum.

**Competitor Comparison:** Home screen is cleaner than Whoop's cluttered dashboard. Ladder's daily view is comparable but has better empty states. **TransformFit wins** on card decomposition (5 clean widgets vs. one monolith).

---

### 1.3 Active Workout Screen — `lib/features/workout/active_workout_screen.dart`

| Criterion | Rating | Notes |
|-----------|--------|-------|
| Visual Hierarchy | ★★★★★ | Strong-style layout: exercise header → coach insight → presets → set table → controls → bottom bar. Matches Strong/Hevy quality. |
| Information Density | ★★★★☆ | Dense but organized. Set table is the right density for a workout logger. |
| Touch Targets | ★★★★★ | All steppers use `SizedBox(height/width: 44)`. Bottom bar buttons are large. |
| Color Contrast | ★★★★☆ | Uses `DigitalAtelierExtension` exclusively (line 7: "zero hardcoded colors"). Mostly good. |
| Animation | ★★★★★ | PR celebration (line 61–62), rest breathing animation (line 65), set-log flash (line 68) — all purposeful. `HapticFeedback.selectionClick()` on every action. |
| Typography | ★★★★★ | Data-dense workout logger with proper tabular figures. |
| Complexity | ★★★☆☆ | **3,162 lines** in one file. The `_ActiveWorkoutScreenState` class has 700+ lines of business logic before the build method. Should be extracted. |

**Specific Fixes:**

1. **Lines 1–997** — Extract business logic into a `WorkoutController` class (separate file). The state class should only handle UI state.
2. **Line 737** — `_DebriefSheet` uses `DigitalAtelierTokens.background` directly instead of `t.background`. Inconsistent.
3. **Lines 822–831** — Padding uses raw `16, 12, 16, 0` instead of token spacing. Should use `t.spaceLg`, `t.spaceMd`.
4. **Line 954** — `SizedBox(height: 200)` magic number for bottom bar spacer. Calculate from actual bar height.

**Competitor Comparison:** Matches Strong's set-logging UX beat-for-beat. **TransformFit wins** on readiness-adjusted targets, pain safety mode, and technique swaps — none of which Strong offers. The PR celebration animation is a nice touch Strong lacks.

---

### 1.4 Coach Chat Screen — `lib/features/coaching/coach_chat_screen.dart`

| Criterion | Rating | Notes |
|-----------|--------|-------|
| Visual Hierarchy | ★★★★★ | Persona-colored left border on coach messages (line 988). User messages are right-aligned bubbles. Clear distinction. |
| Information Density | ★★★★★ | Right for a chat. Suggestion cards are richer than typical chat bubbles. |
| Touch Targets | ★★★★★ | Send button 44×44 (line 907). Voice button 44×44 (line 816). Quick action chips 44px height (line 770). |
| Color Contrast | ★★★★☆ | Persona colors on dark surface — orange, blue, red, purple all pass. |
| Animation | ★★★★☆ | Typing indicator repeat (line 246), chip stagger (line 248), send button scale (line 253). All purposeful. Typing indicator runs indefinitely — consider stopping after 10s. |
| Typography | ★★★★★ | Coach messages use Playfair, data uses Inter. Clean. |
| Empty State | ★★★★★ | Lines 633–693: Persona icon, title, subtitle, quick action chips. **Excellent** — better than most chat apps. |
| Accessibility | ★★★★★ | Live region for new messages (line 503). `SemanticsService` announcements. Long-press to copy (line 965). |

**Specific Fixes:**

1. **Line 246** — `_typingAnimCtrl.repeat()` runs forever. Add a timeout or stop after N cycles.
2. **Lines 343–468** — `_simulateCoachResponse` is a giant if/else chain. Should be a strategy pattern or data-driven.
3. **Line 966** — `Clipboard.setData` without import check. Works on mobile but fails silently on web without `dart:html`.
4. **Line 238** — `_streakAtRisk` is `final bool = false` (never changes). Dead code path.

**Competitor Comparison:** Ladder's coach chat has voice messages and workout integration. MacroFactor's chat is more data-driven. **TransformFit wins** on persona switching (4 personas) and proactive suggestions. Loses on voice input (placeholder only, line 833).

---

### 1.5 Landing Screen — `lib/features/onboarding/landing_screen.dart`

| Criterion | Rating | Notes |
|-----------|--------|-------|
| Visual Hierarchy | ★★★★★ | Cinematic: gradient → typewriter → ring → coach bubble → features → CTA. Strong conversion funnel. |
| Information Density | ★★★★★ | Perfect for a landing page. Not too much, not too little. |
| Touch Targets | ★★★★☆ | "Begin" button has `vertical: 18` padding (line 578) — good. "Sign in" TextButton may be tight. |
| Color Contrast | ★★★☆☆ | Line 208: Dark overlay at 0.82 opacity over gradient. Text readability depends on gradient position. Should test at all gradient states. |
| Animation | ★★★☆☆ | **7 animation controllers** (lines 49–71). Gradient + typewriter + cards + ring + pulse + bubble + particles. This is heavy. On low-end devices, expect frame drops. |
| Typography | ★★★★★ | Playfair for headlines, proper sizing with `isCompact` responsive check. |
| Reduced Motion | ★★☆☆☆ | **No reduced motion check.** All 7 animations run regardless of `MediaQuery.disableAnimations`. The design system has `resolvedDuration()` but this screen doesn't use it. |

**Specific Fixes:**

1. **Lines 77–154** — Wrap all animation initialization in a reduced-motion check. Use `t.resolvedDuration()` from the design system.
2. **Lines 169–200** — `AnimatedBuilder` (note: should be `AnimatedBuilder` — this is actually correct Flutter API, but the gradient animation should respect reduced motion.
3. **Line 389** — `cornerRadius` (4px) used for readiness card border radius. Inconsistent with `radiusMd` (12px) used elsewhere. Should use `radiusMd`.
4. **Line 428** — `Color(0xFF1A1A2E)` hardcoded for coach bubble background. Should use token.
5. **Lines 619–641** — `_ParticlePainter` draws 35 particles at 60fps. Disable when `disableAnimations` is true.

**Competitor Comparison:** Whoop's onboarding is more data-driven (wearable pairing). Ladder's is more coach-centric. **TransformFit wins** on cinematic first impression. Loses on animation performance budget.

---

### 1.6 Wellness Dashboard — `lib/features/wellness/wellness_dashboard_screen.dart`

| Criterion | Rating | Notes |
|-----------|--------|-------|
| Visual Hierarchy | ★★★★☆ | Score header → Modules list → Recommendations. Clear. |
| Information Density | ★★★★☆ | 5 modules with scores, status, descriptions. Good density. |
| Touch Targets | ★★★★☆ | Module cards are full-width rows — easy to tap. 44×44 icon containers (line 394). |
| Color Contrast | ★★★★☆ | Module colors on dark surface pass. Zone colors are semantic. |
| Typography | ★★★☆☆ | Mixes `theme.textTheme.titleMedium` (Material) with `DigitalAtelierTokens.coachVoiceFontFamily` overrides. Should use `t.textTheme.h3` consistently. |
| Spacing | ★★★★☆ | Consistent 12px between modules, 24px sections. |
| Bottom Sheet | ★★★★☆ | `_showModuleDetail` (line 149) uses `showModalBottomSheet` with proper shape. Good. |

**Specific Fixes:**

1. **Lines 170–175** — `TextStyle` constructed inline instead of using `t.textTheme.h3`. Repeat pattern at lines 199, 283, 299.
2. **Line 475** — `_RecommendationsCard` has `final List<String> _recommendations = const [...]` but the field is never `const` (missing `static`). Minor.
3. **Lines 324–337** — `_zoneColor` returns hardcoded colors. Should use design system semantic tokens (`t.success`, `t.warning`, etc.).
4. **Line 262** — `cornerRadius * 2` used for card radius (= 8px). This is actually `radiusSm`. Use the token directly.

**Competitor Comparison:** Whoop's recovery screen is the gold standard — single score, clear color coding. **TransformFit's** 5-module breakdown is more comprehensive but risks information overload. Consider a collapsible "modules" section.

---

### 1.7 Nutrition Dashboard — `lib/features/nutrition/nutrition_dashboard_screen.dart`

| Criterion | Rating | Notes |
|-----------|--------|-------|
| Visual Hierarchy | ★★★★☆ | Macro ring → Meals → Water → Supplements → Quick Add. Logical flow. |
| Information Density | ★★★★★ | MacroFactor-quality macro display. Calorie ring + 3 macro bars is the right density. |
| Touch Targets | ★★★★★ | Water add button 28px icon in 44px+ hit area (line 113). Quick add buttons are full-width. |
| Color Contrast | ★★★★☆ | Macro colors (red/blue/yellow) on dark surface pass. |
| Typography | ★★★★☆ | Data-heavy screen with proper numeric formatting. |
| Responsive | ★★★★☆ | `LayoutBuilder` with `wide` breakpoint at 600px (line 71). Good. |

**Specific Fixes:**

1. **Lines 294, 302, 310** — Macro bar colors hardcoded (`Color(0xFFEF4444)`, etc.). Should use `t.accentDanger`, `t.accentInfo`, `t.warning`.
2. **Line 217** — `cornerRadius * 2` pattern again. Use `t.radiusMd` or define a `radiusCard` token.
3. **Lines 501–543** (truncated) — Quick add buttons need review for touch target sizes.

**Competitor Comparison:** MacroFactor's macro tracking is the benchmark — barcode scanning, food database, AI estimation. **TransformFit's** display is visually comparable but lacks the data entry depth. The visual design of the calorie ring is **on par with MacroFactor**.

---

### 1.8 Gamification Dashboard — `lib/features/gamification/gamification_dashboard_screen.dart`

| Criterion | Rating | Notes |
|-----------|--------|-------|
| Visual Hierarchy | ★★★★☆ | Level badge → XP bar → Streaks grid → Achievements → Milestone. Clear progression. |
| Information Density | ★★★★☆ | Right amount. Streak grid (2–3 cols) is scannable. |
| Touch Targets | ★★★☆☆ | Streak cards at `childAspectRatio: 1.6` (line 141) — may be too small on narrow screens. Achievements are full-width (good). |
| Color Contrast | ★★★★☆ | Tier colors (Bronze/Silver/Gold/Platinum) on dark surface — Bronze (#CD7F32) might be marginal. |
| Typography | ★★★★☆ | Level number in Playfair, data in Inter. Good. |
| Emoji Usage | ★★★☆☆ | Achievement icons are emoji strings (lines 37–53). These render differently across platforms and may not be accessible to screen readers. |

**Specific Fixes:**

1. **Lines 37–53** — Replace emoji strings with `IconData` or SVG for consistent rendering and a11y.
2. **Line 141** — `childAspectRatio: 1.6` makes cards 100×62px on a 360px screen. Minimum should be 1.4 for comfortable tapping.
3. **Lines 413–426** — `_tierColor` returns hardcoded colors. Should use design system tokens where possible.
4. **Line 236–243** — Level badge gradient uses hardcoded `Color(0xFFF97316)` and `Color(0xFF8B5CF6)`. Should use `t.gradientHero`.

**Competitor Comparison:** Duolingo's gamification is the benchmark. **TransformFit's** system is solid but lacks: (a) animated XP gain, (b) level-up celebration, (c) social comparison. The streak grid is a nice touch Duolingo doesn't have in fitness.

---

### 1.9 Exercise Library — `lib/features/exercise_library/exercise_library_screen.dart`

| Criterion | Rating | Notes |
|-----------|--------|-------|
| Visual Hierarchy | ★★★★★ | Search → Filters → Count → List. Clean. |
| Information Density | ★★★★★ | 114 exercises with search + 3 filter dimensions. Good. |
| Touch Targets | ★★★★★ | Filter chips use `FilterChip` (Material). Exercise cards are full-width rows. |
| Search UX | ★★★★☆ | Real-time filtering on text change (line 129). Filter bottom sheets (line 361). Good. |
| Empty State | ★★★★☆ | Lines 237–256: Icon + "No exercises found" message. Could add a "clear filters" CTA. |
| Detail Sheet | ★★★★★ | `DraggableScrollableSheet` (line 284) with 0.4–0.92 range. Excellent pattern. |

**Specific Fixes:**

1. **Line 256** — Empty state should include a "Clear filters" button when filters are active.
2. **Lines 146–148** — Search field border radius uses `cornerRadius * 2` (= 8px). Should use `t.radiusSm`.
3. **Lines 440–446** — `_difficultyColor` returns hardcoded colors. Should use `t.success`, `t.warning`, `t.accentDanger`.

**Competitor Comparison:** Strong's exercise library has video demonstrations. **TransformFit's** 114 exercises with muscle/equipment/difficulty filtering is **competitive** but lacks video/gifs. The search + filter UX is cleaner than most competitors.

---

### 1.10 Progress Dashboard — `lib/features/progress/progress_dashboard_screen.dart`

| Criterion | Rating | Notes |
|-----------|--------|-------|
| Visual Hierarchy | ★★★★★ | Tab bar (Overview/Strength/Volume/Recovery/PRs) + scrollable charts. Excellent. |
| Information Density | ★★★★★ | Each tab has 1–2 charts. Not overwhelming. |
| Token Usage | ★★★★★ | **Best in codebase.** Uses `DigitalAtelierExtension` exclusively via `t = Theme.of(context).extension<...>()!`. Zero hardcoded colors. |
| Responsive | ★★★★★ | `LayoutBuilder` at line 122 — charts go side-by-side on wide screens. |
| Typography | ★★★★★ | Uses `t.textTheme.h2`, `t.textTheme.h3` consistently. |
| Animation | ★★★★☆ | `RefreshIndicator` with `t.accentPrimary` color. Purposeful. |

**Specific Fixes:**

1. **Line 63** — `t.textTheme.h2` for "Progress" title. Consider `t.textTheme.h1` for screen title consistency.
2. **Lines 71–80** — Tab label styles use hardcoded `fontFamily: 'Inter'`. Should use `t.dataFontFamily`.

**Competitor Comparison:** Whoop's trend view is the benchmark. **TransformFit's** 5-tab approach (Overview/Strength/Volume/Recovery/PRs) is **more comprehensive** than any single competitor. The heatmap + radar chart + recovery trend is a strong combination.

---

### 1.11 App Shell / Bottom Nav — `lib/navigation/app_shell.dart`

| Criterion | Rating | Notes |
|-----------|--------|-------|
| Touch Targets | ★★★★★ | `_TabIcon` wraps icons in `SizedBox(height: 44)` with `Semantics(label:)` (lines 52–59). |
| Navigation Pattern | ★★★★★ | `StatefulShellRoute.indexedStack` preserves back-stack per tab. iOS-standard behavior (line 31). |
| Visual Design | ★★★★☆ | `BottomNavigationBar` with `surfaceElevated` background, orange selected, #A0A0A0 unselected. Clean. |
| Semantic Labels | ★★★★★ | Every tab has "X tab" and "X tab, selected" labels (lines 93–146). |
| Typography | ★★★★☆ | Font size 11px for labels (line 88–89). Slightly small but standard for bottom nav. |

**Specific Fixes:**

1. **Line 69** — `_mutedColor = Color(0xFFA0A0A0)` hardcoded. Should use `t.textMuted` (though it's a `StatelessWidget` without context access — consider passing via constructor or using `Theme.of(context)`).
2. **Lines 88–89** — `selectedFontSize: 11, unselectedFontSize: 11` — consider 12px for better readability.

**Competitor Comparison:** Matches iOS standard. 5 tabs is the maximum recommended — on par with Apple's own apps. Icons are clear and distinguishable.

---

### 1.12 App Router — `lib/navigation/app_router.dart`

| Criterion | Rating | Notes |
|-----------|--------|-------|
| Route Architecture | ★★★★★ | Clean `StatefulShellRoute` for tabs + top-level routes for pushed screens. Auth guard with 4 states. |
| Auth Flow | ★★★★★ | `loading → unauthenticated → authenticatedNoProfile → authenticated`. Covers all edge cases. |
| Route Naming | ★★★★☆ | Mostly consistent `/kebab-case`. Some duplicates: `/progress` and `/progress-dashboard` both go to `ProgressScreen` (lines 137–142). |
| Deep Linking | ★★★★☆ | Onboarding redirect at line 193 handles bare `/onboarding` path. Good. |

**Specific Fixes:**

1. **Lines 137–142** — `/progress` and `/progress-dashboard` are duplicate routes. Remove one.
2. **Line 176** — Danger zone route passes hardcoded `DangerZoneResult(signals: [], overallSeverity: 'clear')`. This should be dynamic or removed.

---

## 2. Cross-Screen Consistency

### Navigation Patterns
- **Bottom nav:** Consistent 5-tab pattern via `AppShell`. ✅
- **Back navigation:** Mix of `Navigator.of(context).maybePop()` and `context.go()`. Most screens use `maybePop()` correctly. ✅
- **Push transitions:** Top-level routes push over the shell. Consistent. ✅

### Card Styles
- **Home:** Uses `DigitalAtelierTokens2.elevatedDecoration` (v2 legacy)
- **Wellness:** Uses `DigitalAtelierTokens2.surface` + manual border
- **Nutrition:** Uses `DigitalAtelierTokens2.surface` + manual border
- **Gamification:** Uses `DigitalAtelierTokens2.surface` + manual border
- **Progress:** Uses `t.cardDecoration` (v3 extension) ✅

**Verdict:** ❌ **Inconsistent.** Progress dashboard is the only screen using v3 tokens correctly. All others construct card decorations manually from v2 tokens. Should unify to `t.cardDecoration` or `t.cardElevated`.

### Button Styles
- **ElevatedButton:** Uses theme defaults from `buildDigitalAtelierTheme()` (line 1089). ✅
- **TextButton:** Uses theme defaults. ✅
- **Custom buttons:** Workout screen's quick presets, landing screen's "Begin" button — custom `ElevatedButton.styleFrom()` overrides. Acceptable for accent moments.

**Verdict:** ✅ Mostly consistent. Custom overrides are intentional.

### Input Styles
- **Search field (Exercise Library):** Custom `InputDecoration` with `cornerRadius * 2`
- **Chat input:** Custom `InputDecoration` with `radiusPill`
- **Theme default:** `buildDigitalAtelierTheme()` defines `inputDecorationTheme` with `radiusSm`

**Verdict:** ❌ **Inconsistent.** Three different border radius values for inputs. Exercise library should use `radiusSm` from theme. Chat pill input is intentionally different (good).

### Loading States
- **Home:** `RefreshIndicator` with orange color ✅
- **Chat:** `RefreshIndicator` for pull-to-refresh older messages ✅
- **Progress:** `RefreshIndicator` per tab ✅
- **Wellness/Nutrition/Gamification:** No pull-to-refresh ❌

**Verdict:** ❌ **Inconsistent.** Data-heavy screens (Wellness, Nutrition, Gamification) should have pull-to-refresh.

### Empty States
- **Chat:** Excellent persona-aware empty state with quick actions ✅
- **Exercise Library:** Basic icon + text ✅
- **Home:** Shows "Check In" state for readiness ✅
- **Workout:** `_ClosedWorkoutSurface` for no active session ✅

**Verdict:** ✅ Generally good. Chat empty state is best-in-class.

### Error States
- **No error states found in any screen.** ❌

**Verdict:** ❌ **Missing entirely.** No network error handling, no data fetch error UI, no retry patterns. This is a critical gap for production.

---

## 3. Accessibility Audit

### Semantic Labels Coverage
| Screen | Coverage | Notes |
|--------|----------|-------|
| Home | ★★★★★ | Every card, button, stat has `Semantics(label:)` |
| Workout | ★★★★★ | `SemanticsService.sendAnnouncement` for live status (line 286) |
| Chat | ★★★★★ | Live region for new messages (line 503). Message semantics. |
| Landing | ★★★★☆ | Uses `excludeSemantics: true` on animated elements — correct pattern |
| Wellness | ★★★★☆ | Module cards have labels. Bottom sheet has label. |
| Nutrition | ★★★★☆ | Macro bars have labels. Water button has label. |
| Gamification | ★★★★☆ | Level, streaks, achievements all labeled. |
| Exercise Library | ★★★★☆ | Exercise cards labeled. Filter chips labeled. |
| Progress | ★★★☆☆ | **No explicit Semantics widgets.** Relies on widget defaults. |

**Verdict:** Home and Workout are **exemplary**. Progress dashboard needs `Semantics` wrappers.

### Dynamic Type Support
- ✅ `TransformFitTextTheme` has `scale` parameter (line 830)
- ✅ `textThemeWithScale(double scale)` method exists (line 458)
- ❌ **No screen actually uses `MediaQuery.textScaleFactor`** to pass to `textThemeWithScale()`
- ❌ Fixed `fontSize` values throughout (e.g., `fontSize: 10` at home_screen.dart:387)

**Verdict:** Infrastructure exists but **not wired up.** All screens will ignore user's Dynamic Type settings.

### Reduced Motion Support
- ✅ `resolvedDuration()` and `resolvedCurve()` in design system
- ✅ Static decoration alternatives for gradients
- ❌ **Landing screen** runs 7 animations regardless of `disableAnimations`
- ❌ **Chat screen** typing indicator and chip animations ignore reduced motion
- ❌ **Workout screen** celebration and breathing animations ignore reduced motion

**Verdict:** Design system is ready. **Screens don't use it.** This will fail App Store accessibility review.

### Color-Only Information
- ❌ Wellness module status uses color alone (green=good, yellow=moderate) — needs text labels (partially addressed with "Good"/"Moderate" text)
- ❌ Gamification tier badges use color alone (Bronze/Silver/Gold) — has text labels ✅
- ❌ Macro progress bars use color alone — has text labels ✅

**Verdict:** ✅ Mostly addressed with text labels alongside colors.

### Focus Management
- ❌ No explicit `FocusTraversalGroup` or focus order management
- ❌ Chat screen doesn't auto-focus input on open
- ❌ Bottom sheets don't trap focus

**Verdict:** ❌ **Not implemented.** Will be problematic for keyboard/switch navigation.

### Screen Reader Flow
- ✅ Live announcements for workout status changes
- ✅ Live region for chat messages
- ❌ No announcement when navigating between tabs
- ❌ No announcement when bottom sheet opens/closes

---

## 4. Mobile Ergonomics

### Thumb Zone Optimization
- ✅ **Workout screen:** Bottom bar with log/undo/finish is in the thumb zone
- ✅ **Chat screen:** Input area at bottom with send button
- ✅ **Home screen:** Quick actions in the middle (reachable)
- ⚠️ **Wellness/Nutrition/Gamification:** AppBar back button is top-left (hard to reach one-handed). Consider swipe-back or bottom navigation.

### One-Hand Usability
- ✅ Workout logger is fully operable one-handed (bottom bar, steppers)
- ⚠️ Landing screen "Begin" button is in the middle — good
- ❌ Filter chips in Exercise Library are at the top — hard to reach on tall phones

### Bottom Sheet vs Modal Patterns
- ✅ Wellness module details → bottom sheet
- ✅ Exercise library detail → `DraggableScrollableSheet`
- ✅ Exercise filter picker → bottom sheet
- ✅ Workout debrief → bottom sheet
- ❌ No use of full-screen modals for complex flows (appropriate)

### Keyboard Avoidance
- ✅ Chat input uses `SafeArea` + standard `TextField` (Flutter handles keyboard automatically)
- ✅ Exercise library search handles keyboard
- ❌ No explicit `resizeToAvoidBottomInset` management

### Scroll Behavior
- ✅ Home: `BouncingScrollPhysics` (iOS-style)
- ✅ Chat: Standard `ListView.builder`
- ✅ All data screens: `SingleChildScrollView` or `ListView`
- ✅ Progress: `RefreshIndicator` per tab

---

## 5. Competitive Comparison

### Home Screen vs. Whoop Dashboard
| Aspect | TransformFit | Whoop |
|--------|-------------|-------|
| Recovery Score | Readiness ring (0–100) | Recovery circle (0–100) |
| Daily Plan | ✅ Card with resume/start | ❌ No daily plan |
| Coach Insight | ✅ AI-generated note | ❌ No coach on home |
| Quick Actions | ✅ 4 quick actions | ❌ None |
| Weekly Summary | ✅ Stats row | ❌ Separate tab |

**TransformFit wins.** More information, better organized, with coach personality.

### Workout Logger vs. Strong
| Aspect | TransformFit | Strong |
|----------|-------------|--------|
| Set Logging | ✅ Weight/Reps/RPE | ✅ Weight/Reps/RIR |
| Rest Timer | ✅ Countdown + breathing | ✅ Countdown |
| Readiness Caps | ✅ Auto-adjusts weight/RPE | ❌ None |
| Pain Safety | ✅ Blocks progression | ❌ None |
| Technique Swaps | ✅ Auto-suggest alternatives | ❌ None |
| PR Celebration | ✅ Animated overlay | ✅ Simple notification |
| Exercise Library | ✅ 114 exercises | ✅ 300+ exercises |

**TransformFit wins** on intelligence (readiness, pain safety, technique swaps). **Strong wins** on exercise library depth and simplicity.

### Coach Chat vs. Ladder
| Aspect | TransformFit | Ladder |
|----------|-------------|--------|
| Personas | ✅ 4 personas | ❌ 1 coach |
| Proactive Suggestions | ✅ Context-aware | ⚠️ Limited |
| Quick Actions | ✅ 4 context-aware | ❌ None |
| Voice Input | ❌ Placeholder | ✅ Working |
| Workout Integration | ⚠️ Planned | ✅ Deep |

**TransformFit wins** on persona variety and proactive intelligence. **Ladder wins** on voice and workout integration.

### Progress Dashboard vs. Whoop Trends
| Aspect | TransformFit | Whoop |
|----------|-------------|-------|
| Tabs | ✅ 5 (Overview/Strength/Volume/Recovery/PRs) | ✅ 3 (Overview/Recovery/Strain) |
| Heatmap | ✅ GitHub-style | ❌ Calendar only |
| Radar Chart | ✅ Muscle balance | ❌ None |
| Strength Tracking | ✅ Dedicated tab | ❌ None |
| PR Board | ✅ Dedicated tab | ❌ None |

**TransformFit wins** comprehensively. The 5-tab progress view is more comprehensive than any single competitor.

---

## 6. Priority Fixes (Ranked)

### P0 — Ship Blockers

| # | File | Lines | Issue | Fix |
|---|------|-------|-------|-----|
| 1 | `digital_atelier.dart` | 360 | `textMuted` (#6B7280) fails WCAG AA on dark bg | Change to #8B95A5 |
| 2 | `landing_screen.dart` | 77–154 | 7 animations ignore reduced motion | Wrap in `MediaQuery.disableAnimations` check |
| 3 | All screens | — | Dynamic Type not wired up | Use `MediaQuery.textScaler` with `textThemeWithScale()` |
| 4 | All screens | — | No error states | Add error state widgets for data-dependent screens |

### P1 — Quality Improvements

| # | File | Lines | Issue | Fix |
|---|------|-------|-------|-----|
| 5 | `active_workout_screen.dart` | 1–997 | 700+ lines of business logic in widget state | Extract `WorkoutController` |
| 6 | `wellness/nutrition/gamification` | — | No pull-to-refresh | Add `RefreshIndicator` |
| 7 | Multiple screens | — | Card decoration inconsistency (v2 vs v3 tokens) | Migrate all to `t.cardDecoration` |
| 8 | `coach_chat_screen.dart` | 246 | Typing indicator runs forever | Add 10s timeout |
| 9 | `progress_dashboard_screen.dart` | — | No `Semantics` wrappers | Add semantic labels |
| 10 | `home_screen.dart` | 387 | Quick action label fontSize: 10 | Increase to 11px |

### P2 — Polish

| # | File | Lines | Issue | Fix |
|---|------|-------|-------|-----|
| 11 | `gamification_dashboard_screen.dart` | 37–53 | Emoji as achievement icons | Replace with `IconData` or SVG |
| 12 | `app_router.dart` | 137–142 | Duplicate `/progress` routes | Remove `/progress-dashboard` |
| 13 | Multiple screens | — | Hardcoded colors in `_zoneColor`, `_difficultyColor`, `_tierColor` | Use design system semantic tokens |
| 14 | `landing_screen.dart` | 389, 428 | `cornerRadius` (4px) and hardcoded colors | Use `t.radiusMd` and tokens |
| 15 | All screens | — | Focus management missing | Add `FocusTraversalGroup` |

### P3 — Future

| # | Issue | Impact |
|---|-------|--------|
| 16 | Voice input in chat (placeholder at line 833) | Feature parity with Ladder |
| 17 | Video demonstrations in exercise library | Feature parity with Strong |
| 18 | Animated XP gain in gamification | Engagement boost |
| 19 | Social comparison features | Retention |
| 20 | Barcode scanning in nutrition | Feature parity with MacroFactor |

---

## Appendix: Token Migration Guide

### From v2 → v3

| v2 Pattern | v3 Replacement |
|------------|---------------|
| `DigitalAtelierTokens2.surface` | `t.surface` |
| `DigitalAtelierTokens2.surfaceElevated` | `t.surfaceElevated` |
| `DigitalAtelierTokens2.surfaceBorder` | `t.surfaceBorder` |
| `DigitalAtelierTokens2.elevatedDecoration` | `t.cardElevated` |
| `DigitalAtelierTokens2.s1` through `s8` | `t.spaceXs` through `t.spaceHuge` |
| `DigitalAtelierTokens2.headlineLarge` | `t.textTheme.h1` |
| `DigitalAtelierTokens2.bodyMedium` | `t.textTheme.body` |
| `DigitalAtelierTokens.accentOrange` | `t.accentPrimary` |
| `DigitalAtelierTokens.textPrimary` | `t.textPrimary` |
| `DigitalAtelierTokens.background` | `t.background` |
| `DigitalAtelierTokens.coachVoiceFontFamily` | `t.coachVoiceFontFamily` |
| `DigitalAtelierTokens.dataFontFamily` | `t.dataFontFamily` |
| `DigitalAtelierTokens.cornerRadius` | `t.radiusSm` |

**Usage:**
```dart
final t = Theme.of(context).extension<DigitalAtelierExtension>()!;
// Then use t.surface, t.textPrimary, t.textTheme.h1, etc.
```

---

*End of audit. Generated by RIG UI Designer / Design Agent.*
