# MacroFactor — How They Work

- **Prior profile:** references and extends `competitors/macrofactorapp.com.md` (existing 10-profile research set).
- **Sources used:** existing profile + public web (`https://macrofactor.com`) + App Store listing (`https://apps.apple.com/us/app/macrofactor-macro-tracker/id1553503471`).
- **Captures:** `gold/screenshots/macrofactor_home.png`, `gold/screenshots/macrofactor_appstore.png` (public marketing + store; no authenticated in-app screens).

## What it is

MacroFactor is a nutrition / macro-tracking app built by the Stronger By Science team. It positions itself as "the fastest, smartest macro tracker," and its differentiation is not the logging UI but the **adaptive algorithm** that recalculates your energy expenditure and macro targets from your own logged data.

## Core flows

1. **Onboarding / first-run:** the user answers a short intake (goal direction — lose / maintain / gain, rate of change, diet style) and the app sets an initial expenditure estimate and macro target. Crucially the user is told the targets will be recalculated, not fixed.
2. **Daily logging loop:** the user logs food via a fast search, barcode scan, AI photo logging, saved "Favorite Foods," or quick-add. The logging surface is engineered for speed (the "Fastest Food Logger" claim is a positioning pillar).
3. **Weekly recalibration step:** this is the mechanic that defines the product. Each week the algorithm ingests weight trend + logged intake, runs an expenditure model (a dynamic TDEE estimate rather than a static equation), and **surfaces a new target**. The user does not have to do the math; the pipeline does it and narrates the change.
4. **Progress / trends surface:** weight trend smoothing, expenditure-over-time, adherence, and macro distribution are charted so the user can see the system reacting to them.

## Mechanics (how it works under the hood)

The engine treats body weight as a noisy signal and intake as a second signal, then continuously fits an expenditure estimate (the "expenditure modifier" and step-informed adjustments are public feature notes). The feedback loop is: log → weekly trend computed → expenditure re-estimated → target adjusted → coached explanation. This is a closed deterministic loop where the math owns the decision and the copy explains it — exactly the "code owns the decision, narration explains it" pattern TransformFit's L6 invariant cares about.

## Key surfaces

- Fast food-logging entry screen (search / barcode / AI photo / favorites).
- Weekly check-in / target-update card.
- Expenditure + weight-trend charts (progress/trends).
- Coaching/explanation copy attached to each recalculation.

## What drives retention / activation

The **retention driver is the weekly recalibration return-trigger**: because targets visibly adapt to the user's own data every week, the user has a recurring reason to come back and log — skipping logging degrades the very algorithm that is working for them. The habit loop is "log honestly → the system rewards you with an accurate, personalized target," which converts logging from a chore into an investment. Activation is driven by the early "the app adjusted for me" moment — when the first weekly update changes a target based on the user's real trend, the user experiences the product as a coach reacting to them rather than a static calculator. The stickiness mechanic is data-compounding: the longer you log, the smarter and more personalized the targets, which raises the switching cost.

## Relevance to TransformFit

MacroFactor is the named gold for the **progress / trends** surface: it shows how a deterministic engine plus honest narration produces a calibrated, personal trend view that earns a return visit — directly analogous to TransformFit's readiness-adjusted loop and the ≥30% Week-2 activation metric.
