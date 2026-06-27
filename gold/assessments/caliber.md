# Caliber — How They Work

- **Prior profile:** a profile file exists at `competitors/caliber.co.md`, but it is a **DOMAIN COLLISION** — that file describes "Caliber Luxury Homes," an unrelated custom home builder in Denver (Wash Park / Cherry Hills), NOT the Caliber strength-training app. This assessment therefore does **not** treat the luxury-home-builder profile as the fitness app. The real Caliber fitness app's actual source is **`caliberstrong.com`** (marketing) and the App Store listing for "Caliber - Strength Training."
- **Sources used:** the actual Caliber fitness app sources — public web (`https://caliberstrong.com`) + App Store listing (`https://apps.apple.com/us/app/caliber-strength-training/id1482405410`). The `competitors/caliber.co.md` profile is noted only to record the collision; it is not a valid prior profile for this competitor.
- **Captures:** `gold/screenshots/caliber_home.png` (caliberstrong.com marketing), `gold/screenshots/caliber_appstore.png` (App Store listing; no authenticated in-app screens).

## What it is

Caliber (caliberstrong.com) is a strength-training app combining a structured, periodized training program with optional human coaching. It blends an algorithmic program builder with a coach relationship — sitting between a pure logger (Hevy) and full human coaching (Future).

## Core flows

1. **Onboarding / assessment:** the user provides goals, experience, equipment, and schedule. The app generates a structured strength program (push/pull/legs or similar splits) periodized over weeks.
2. **Guided session loop:** each workout prescribes specific exercises, sets, reps, and a target intensity (often RPE/RIR-based). The user logs each set and the app adjusts subsequent prescriptions based on logged performance — a progression mechanism rather than a static template.
3. **Strength-score feedback:** Caliber computes a normalized "strength score" / standards comparison so the user can see how they rank and how they are improving over time. This quantified progress surface is a core feedback loop.
4. **Coach layer (paid tier):** higher tiers pair the user with a human coach who reviews progress, messages, and adjusts the plan — an accountability surface on top of the algorithm.

## Mechanics (how it works under the hood)

The engine periodizes training and uses logged set performance (and RPE/RIR feedback) to drive autoregulated progression — if you hit targets, load advances; if you miss, it backs off. The strength score is computed from lifts normalized to bodyweight/standards, giving a single trackable number. The human-coach tier adds a check-in pipeline that converts data into personalized adjustments and messages.

## Key surfaces

- Onboarding / program-generation flow.
- Guided active-session screen with prescribed sets + logging.
- Strength-score / standards progress surface.
- Coach messaging + check-in (paid).

## What drives retention / activation

The **retention driver is the combination of a visible strength score (quantified-progress return trigger) and the human-coach accountability relationship**. The strength score gives a recurring "did my number go up?" reason to return, while the coach relationship creates a social-obligation stickiness mechanic — users are less likely to ghost a real person who is watching their progress. Activation is driven by the structured first program plus the early coach touch: a user who completes onboarding gets an authored plan (not a blank logger) and, on paid tiers, a coach who reaches out, both of which pull them into the first two weeks.

## Relevance to TransformFit

Caliber demonstrates the algorithm-plus-coach hybrid TransformFit is aiming at: deterministic progression owns the prescription, a quantified score makes progress legible, and a coaching layer drives accountability — all directly relevant to the readiness-adjusted, coach-voice model and the Week-2 activation metric.
