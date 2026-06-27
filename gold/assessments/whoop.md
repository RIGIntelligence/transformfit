# Whoop — How They Work

- **Prior profile:** **no prior profile / newly researched.** Whoop is not among the existing 10 profiles in `competitors/`; this assessment was authored fresh from public sources.
- **Sources used:** public web (`https://www.whoop.com`) + App Store listing (`https://apps.apple.com/us/app/whoop/id933944389`).
- **Captures:** `gold/screenshots/whoop_home.png` (marketing), `gold/screenshots/whoop_appstore.png` (App Store listing; no authenticated in-app screens).

## What it is

Whoop is a screenless wearable strap plus a subscription app focused on recovery, strain, and sleep. There is no device price gate in the usual sense — the hardware comes with the membership, so the **recurring subscription is the business**, and daily app engagement is what justifies it. It is a canonical reference for the **post-session debrief** and recovery-driven daily readiness surfaces.

## Core flows

1. **Onboarding / first-run:** the user sets up the strap, answers a baseline questionnaire (sleep needs, goals), and the app begins collecting continuous heart-rate and HRV data to establish a personal baseline.
2. **Morning recovery loop (core mechanic):** each morning the app computes a **Recovery score (0-100%, green/yellow/red)** from HRV, resting heart rate, sleep performance, and respiratory rate. This single color-coded number is the daily return trigger — the user opens the app to "see what color they are."
3. **Strain loop:** during the day the app accumulates a cardiovascular **Strain score** and compares it against the morning recovery — coaching the user to push or pull back. After a workout, the **post-session debrief** surfaces the strain incurred, calories, and heart-rate zones.
4. **Sleep loop:** at night Whoop recommends a sleep target sized to the next day's planned strain, then scores sleep performance against need.
5. **Weekly/monthly reports + Whoop Coach:** trends are summarized and an AI coach answers questions and contextualizes the data.

## Mechanics (how it works under the hood)

Whoop's pipeline is continuous-sensor → baseline model → daily scores (Recovery, Strain, Sleep) → recommendations → narration. The decisions (what your recovery is, how much strain to target) are computed deterministically from physiology; the coaching layer narrates them. The closed loop — recovery informs strain target, strain informs sleep need, sleep feeds tomorrow's recovery — is what makes the data feel actionable rather than decorative.

## Key surfaces

- Morning Recovery screen (the green/yellow/red readiness number — gold for daily readiness).
- Strain dashboard + post-workout strain debrief.
- Sleep performance / sleep coach.
- Trends + Whoop Coach (AI Q&A).

## What drives retention / activation

The **retention driver is the daily Recovery score as a habit-forming return trigger**: a single, color-coded, physiologically-personal number that changes every morning gives users a Pavlovian reason to open the app before they even decide what to do that day. The stickiness mechanic is the **continuous data baseline** — value compounds over time (your scores are only meaningful relative to your own history), so churning means losing your baseline and the recommendations built on it. Activation is driven by the first week of personalized recovery readings: once the score visibly reacts to a bad night of sleep or a hard workout, the user trusts the loop and integrates the morning check into their routine. Because the membership bundles the hardware, daily engagement is also the explicit anti-churn lever.

## Relevance to TransformFit

Whoop is the named gold for the **daily readiness / recovery** debrief mechanic: a deterministic physiological score that becomes a daily return trigger and adjusts the day's plan. This is structurally identical to TransformFit's readiness-adjusted session loop and its Week-2 activation goal — the lesson is that one trustworthy, personal, daily number can carry the entire habit.
