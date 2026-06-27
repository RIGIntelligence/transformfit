# Future — How They Work

- **Prior profile:** references and extends `competitors/future.co.md` (existing 10-profile research set).
- **Sources used:** existing profile + public web (`https://future.co`).
- **Captures:** `gold/screenshots/future_home.png` (public marketing; no authenticated in-app screens).

## What it is

Future is a premium 1:1 human-coaching app. Every member is matched with a real, vetted coach who builds and continuously adjusts their program and messages them throughout the week. The product is the **coach relationship**, delivered through software; the app is the channel, not the differentiator. Pricing is positioned as "$50 first month, then $199/month," which frames it as a coaching service rather than a SaaS logger.

## Core flows

1. **Onboarding / matching:** a 1-minute quiz captures schedule, equipment, experience, injury record, and goals (the marketing site literally renders a member profile card with Schedule / Equipment / Experience / Injury Record / Goals). This intake feeds a coach match — a human is assigned, not just a plan.
2. **Program delivery loop:** the coach builds a personalized plan. Each workout is delivered with video demos, voice cues, and form guidance, and is trackable in-session (including Apple Watch).
3. **Coach check-in loop (the core mechanic):** the coach proactively messages — "Nice lift, Alex! You recovered quickly between sets. That Zone 2 work is paying off." These check-ins reference specific logged performance, which is the exact coach-presence pattern (specific observation + forward hook) TransformFit's doctrine prizes.
4. **Adaptation flow:** the user can move workouts, adjust days, and adapt the plan "without penalty," and the coach refines the plan over time.

## Mechanics (how it works under the hood)

Future's engine is a human coach augmented by software: intake → coach match → authored plan → in-app delivery with media → logged performance flows back to the coach → coach sends a personalized check-in and adjusts the plan. The accountability loop is the product: a real person sees your data and reaches out, which is a fundamentally different return trigger than an algorithmic notification.

## Key surfaces

- 1-minute intake quiz + member-profile card.
- Coach-match reveal.
- Guided workout screen (video / voice cues / Apple Watch tracking).
- Coach check-in / messaging thread (the gold surface for coach presence).

## What drives retention / activation

The **retention driver is human accountability**: the coach check-in is a social return trigger that no purely algorithmic app can replicate — members report being "more consistent within 4 weeks" because someone is watching and responding. The stickiness mechanic is the relationship plus sunk-cost personalization: the coach knows your injuries, schedule, and history, so leaving means abandoning a real relationship and re-explaining yourself elsewhere. Activation is driven by the early coach touch — the first personalized message referencing the member's actual workout is the moment the service stops feeling like an app and starts feeling like coaching, which is precisely the feeling TransformFit is chasing.

## Relevance to TransformFit

Future is the named gold for the **post-session debrief / coach-presence** surface and the north-star feeling itself ("a text from a coach who watched your last workout"). TransformFit's bet is to deliver Future's coach-presence retention driver at software margins via deterministic readiness adjustment + authored narration, rather than a 1:1 human per member.
