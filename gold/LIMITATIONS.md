# Gold Library — Honest Scope & Limitations

This note documents, honestly and up front, exactly what the TransformFit gold-reference library is and is not. It is required reading before grading anything against `gold/named-gold.json`.

## In-app mobile screens are OUT OF SCOPE

**Authenticated, logged-in, in-app mobile screens are out of reach for this mission and were NOT captured.** We were provided **no accounts and no devices** for any competitor (MacroFactor, Whoop, Oura, Hevy, Caliber, Future, Noom) or design reference (Linear, Vercel, Apple). Capturing a real in-app readiness home, active-set logger, or paywall would require:

- a paid account / membership per competitor, and
- in several cases a physical wearable device (Whoop strap, Oura ring) to generate the data those screens display.

Neither was available, so **no authenticated in-app capture was attempted or faked.**

## What the gold IS built from

The gold library is built **only** from publicly accessible sources:

- **Public marketing websites** (e.g. `macrofactor.com`, `ouraring.com`, `whoop.com`, `future.co`, `caliberstrong.com`, `hevy.com`, `noom.com`, `linear.app`, `vercel.com`, `apple.com`).
- **Public App Store listing pages** (the public store preview screenshots and copy — not the installed, logged-in app).
- **Existing competitor research** in `adapt-evolve-progress/docs/research/competitors/` (the prior 10 profiles), referenced where one exists.

All captures were taken via **headless agent-browser** and are recorded in `gold/screenshots/manifest.json` with `headless: true`, a source URL, and a timestamp. Surface labels and provenance fields describe **web / marketing / app-store / listing** sources — never in-app or authenticated provenance.

## No faked authenticated captures

- No screenshot file claims to be an authenticated, logged-in, in-app mobile screen.
- Filenames use `_home` (marketing home) and `_appstore` (public store listing) suffixes only.
- Each `named-gold.json` anatomy `screenshot_ref` resolves to one of these public captures.
- The anatomies (scored dimensions + prose) are calibrated from these public sources plus prior research and well-documented product mechanics — they are explicitly **not** claimed to be pixel-measurements of private in-app screens.

## Domain-collision caveat (Caliber)

The existing profile `competitors/caliber.co.md` is a **domain collision**: it describes "Caliber Luxury Homes," an unrelated Denver custom-home builder, NOT the Caliber strength-training app. The real Caliber fitness app's sources are `caliberstrong.com` (marketing) and the "Caliber - Strength Training" App Store listing, which is what `caliber_home.png` / `caliber_appstore.png` and `gold/assessments/caliber.md` actually reference. The luxury-home-builder profile is recorded only to note the collision and is **not** treated as the fitness app.

## Consequence for grading

Because the gold is public-surface only, the future Tier-2 adversarial teardown should grade TransformFit artifacts against these anatomies as **directional craft + mechanics benchmarks**, not as pixel-exact replicas of private in-app screens. When (in a later mission) accounts/devices become available, the gold should be upgraded with real in-app captures and this limitation revisited.
