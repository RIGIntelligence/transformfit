# Hevy — How They Work

- **Prior profile:** references and extends `competitors/hevy.com.md` (existing 10-profile research set). Note: the prior profile is thin — the `hevy.com` root redirects to a public login screen, so the existing profile captured only the login surface. This assessment extends it with public marketing, App Store, and known product mechanics.
- **Sources used:** existing profile + public web (`https://hevy.com`, which redirects to `/login`) + App Store listing (`https://apps.apple.com/us/app/hevy-workout-tracker-planner/id1563470925`).
- **Captures:** `gold/screenshots/hevy_home.png` (public login surface), `gold/screenshots/hevy_appstore.png` (no authenticated in-app screens).

## What it is

Hevy is a workout-logging app for resistance training. Its reputation is built on a fast, clean, frictionless logging experience plus a light social layer. It is the canonical reference for the **workout logging / active-set** surface.

## Core flows

1. **Routine setup:** the user builds or imports a routine (a template of exercises with target sets/reps). Routines are reusable, which removes setup friction on every subsequent session.
2. **Active workout / set logging loop:** the user starts a routine, and during the session logs each set (weight × reps), with a per-set **rest timer** that auto-triggers after a logged set. The active-set surface keeps the current exercise, previous-session numbers, and the running total visible. This "log set → rest timer → next set" loop is the core mechanic.
3. **Previous-performance surfacing:** Hevy shows last session's numbers inline so the user can apply progressive overload without leaving the screen. This is the key feedback mechanism that turns logging into a decision aid.
4. **Post-session summary:** on finishing, the user gets a workout summary (volume, PRs, duration) and can post it to the feed.
5. **Social feed:** workouts can be shared and others can react — a light accountability surface.

## Mechanics (how it works under the hood)

The product optimizes the **time-to-log** path: minimal taps per set, auto-advancing rest timer, and inline history. PRs and volume are computed from logged sets and surfaced immediately. The feed is a re-engagement pipeline: completing a workout produces shareable proof, which triggers social reactions, which pull the user back.

## Key surfaces

- Routine / template builder.
- Active-set logging screen with rest timer + previous-set reference (the gold surface).
- Post-session summary (volume / PR / duration).
- Social feed + profile.

## What drives retention / activation

The **primary retention driver is the frictionless logging habit loop**: because logging a set is nearly instant and the rest timer paces the session, the app becomes the path of least resistance during every workout, and the workout itself becomes the recurring return trigger. The secondary driver is **streak-and-PR feedback plus the social feed** — PRs and shared workouts create a stickiness mechanic (identity + accountability) that re-engages lapsed users. Activation hinges on getting the user to log their first full session: once a routine exists and one workout is logged with history, the next session's "beat your last numbers" prompt is a strong return trigger.

## Relevance to TransformFit

Hevy is the named gold for the **workout logging / active-set** surface. TransformFit must match Hevy's logging speed and inline previous-set surfacing while layering readiness-adjusted coaching on top — the logger must feel as effortless as Hevy's, or the coaching never gets a chance to land.
