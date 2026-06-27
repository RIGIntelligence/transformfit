# Oura — How They Work

- **Prior profile:** **no prior profile / newly researched.** Oura is not among the existing 10 profiles in `competitors/`; this assessment was authored fresh from public sources.
- **Sources used:** public web (`https://ouraring.com`) + App Store listing (`https://apps.apple.com/us/app/oura/id1043837948`).
- **Captures:** `gold/screenshots/oura_home.png` (marketing), `gold/screenshots/oura_appstore.png` (App Store listing; no authenticated in-app screens).

## What it is

Oura is a smart-ring wearable plus a subscription app focused on sleep, readiness, and activity. The ring captures temperature, heart rate, HRV, and movement overnight and across the day, and the app distills this into a small set of daily scores. Oura essentially **invented the consumer "Readiness Score"** and is the canonical reference for the **daily readiness / home** surface.

## Core flows

1. **Onboarding / first-run:** the user sizes and pairs the ring, answers baseline questions, and the app collects a few nights of data to establish personal baselines for temperature, resting heart rate, and HRV.
2. **Daily Readiness loop (core mechanic):** every morning the app surfaces three headline scores — **Readiness, Sleep, and Activity (each 0-100)** — on the home screen. Readiness blends sleep, recovery, HRV balance, body temperature, and recent activity into a single number with a plain-language message ("Pay attention," "Good to go"). This morning glance is the daily return trigger.
3. **Sleep loop:** detailed sleep staging (deep / REM / light), efficiency, and timing are computed overnight and scored; the app nudges a consistent bedtime.
4. **Activity + tags loop:** the user can tag behaviors (caffeine, alcohol, late meal, stress) and Oura correlates them with score changes, closing a personalized feedback loop ("late alcohol → lower readiness").
5. **Trends + insights:** longer-term temperature trends, cycle insights, and the chatty "Oura Advisor" contextualize the data.

## Mechanics (how it works under the hood)

Oura's pipeline is overnight sensor capture → personal-baseline model → three daily scores → a plain-language recommendation → optional tag-based correlation. The scoring is deterministic and relative to the individual's own baseline; the messaging narrates it. The behavioral genius is reduction — collapsing a mass of physiological data into one Readiness number plus one sentence of guidance, so the user gets an instant, low-effort verdict each morning.

## Key surfaces

- Home screen with Readiness / Sleep / Activity scores (gold for daily readiness/home).
- Detailed sleep-staging screen.
- Tags + correlation insights.
- Trends + Oura Advisor.

## What drives retention / activation

The **retention driver is the morning Readiness score as a daily habit loop**: a single personalized number waiting each morning makes the first action of the day "check my ring," which is one of the strongest return triggers in consumer health. The stickiness mechanic is **baseline lock-in plus subscription** — scores are only meaningful relative to your own accumulated history, and the membership model means daily engagement is the retention lever. Activation is driven by the first week of readiness/sleep feedback: once the user sees Readiness drop after a poor night and the guidance match how they feel, the loop earns trust and becomes routine. Tag-based correlations deepen stickiness by making the app feel like it is learning the user's specific body.

## Relevance to TransformFit

Oura is the named gold for the **daily readiness / home** surface. Its lesson for TransformFit is the power of reduction: one authored, personal Readiness number plus a single plain-language coaching line can anchor the entire daily wake-up loop and drive the ≥30% Week-2 activation metric — exactly TransformFit's "open it to see what your coach already adjusted" thesis.
