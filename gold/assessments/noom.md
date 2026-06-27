# Noom — How They Work

- **Prior profile:** **no prior profile / newly researched.** Noom is not among the existing 10 profiles in `competitors/`; this assessment was authored fresh from public sources.
- **Sources used:** public web (`https://www.noom.com`).
- **Captures:** `gold/screenshots/noom_home.png` (marketing; no authenticated in-app screens).

## What it is

Noom is a behavior-change weight-management app built on psychology (CBT-style cognitive behavioral techniques) rather than pure calorie counting. Its differentiation is the **onboarding quiz and the daily psychology lessons**, not the food logger. Noom is the canonical reference for the **onboarding / first-run** surface and for **paywall / upgrade** mechanics, because both are unusually well engineered (and, in places, controversial).

## Core flows

1. **Onboarding quiz (the signature mechanic):** before the user ever sees the app, Noom runs a long, conversational, multi-step quiz — goals, weight history, "why now," psychological triggers, eating patterns. The quiz is the activation engine: it builds investment and a personalized narrative, then presents a projected weight-loss curve and a custom plan. This is a textbook commitment-and-consistency funnel.
2. **Paywall / upgrade step:** at the end of the quiz, the app surfaces a personalized plan behind a paywall, often with a trial framed around the user's stated goal date. The upgrade copy is tightly coupled to the quiz answers ("your plan to reach X by Y"). Noom has historically been scrutinized for friction in the cancel flow — a cautionary anti-pattern, not a model to copy.
3. **Daily lesson loop (core retention mechanic):** the user gets short, gamified daily psychology lessons (5-10 minutes) that teach concepts like the "elephant and rider," food categorization (green/yellow/red foods), and trigger awareness. Completing lessons builds a streak.
4. **Logging + coaching loop:** the user logs food (color-categorized) and weight, and can message a human/group coach for accountability.
5. **Progress surfacing:** weight trend, lesson streak, and behavior insights are charted.

## Mechanics (how it works under the hood)

Noom's pipeline is quiz → personalized plan + projection → paywall → daily lesson curriculum + logging → coach/group accountability → progress feedback. The behavioral engine is the curriculum: it sequences psychology content to reframe the user's relationship with food, while the streak and daily-lesson cadence create a return habit. The color-food categorization is a reduction mechanic that makes logging fast and judgment-light.

## Key surfaces

- Conversational onboarding quiz + projected-results screen (gold for onboarding/first-run).
- Personalized-plan paywall / upgrade screen (gold-adjacent for paywall, with explicit anti-pattern caveats).
- Daily psychology lesson (gamified, streak-tracked).
- Color-categorized food log + coach/group chat.

## What drives retention / activation

The **activation driver is the onboarding quiz**: by investing 5-10 minutes answering personal questions and seeing a tailored projection, the user is psychologically committed before paying — one of the most effective activation funnels in consumer health. The **retention driver is the daily-lesson streak habit loop**: short, gamified lessons create a low-friction daily return trigger, and the streak plus coach/group accountability provide the stickiness mechanic. The progress-projection ("on track to your goal") is a recurring re-engagement hook. Noom's cancel-flow friction is explicitly a **banned dark-pattern** under TransformFit's L2/L5 doctrine — Noom is gold for activation/onboarding craft but a negative example for ethical paywall placement.

## Relevance to TransformFit

Noom is the named gold for the **onboarding / first-run** surface (and a studied reference for paywall mechanics). Its lesson for TransformFit: a personalized, investment-building onboarding plus a daily micro-habit loop drives activation — but TransformFit must achieve the activation without Noom's dark-pattern cancel friction, honoring the "never gate the core loop, no dark patterns, paywall Day-15 only" laws.
