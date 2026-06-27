# TransformFit (Flutter rebuild, first slice)

This repository is the first slice of a TransformFit Flutter rebuild. It is not a
full app yet. It contains a binding doctrine, a fail-closed quality harness, a
competitor gold reference library, and a Flutter walking skeleton. The full app
build (later phases) is out of scope here and is future work.

## What is in this repo

### 1. Doctrine (binding law)

`TRANSFORMFIT-DOCTRINE.md` (repo root) is a binding, checkable law-book organized
into six layers: L1 Coaching, L2 Behavioral, L3 Experience, L4 Design, L5
Business, L6 Engineering. Every law carries a `Test:` line with a binary or scored
criterion, and every law traces in one step to the North-Star metric
(>=30% Week-2 activated retention = >=3 readiness-adjusted sessions in 14 days).
It is binding law, not a suggestion. Per `AGENTS.md` it is required reading for all
agents working in this repo.

### 2. Quality harness (`transformfit-harness/`)

A fail-closed quality harness built on the Python standard library and bash, with
no pip dependencies.

- `doctrine_lint.py` - JSON-driven copy and coaching lint, sourcing banned copy
  from `banned_phrases.json`.
- `message_rule_lint.py` - enforces the L1 coach-message rules.
- `design_lint.sh` - Digital Atelier token, WCAG-AA contrast, font-role, and
  corner-radius checks. Also supports `--verify-tokens` for a token match check.
- `build_test_gate.sh` - HARD-AND of `flutter analyze` and `flutter test`.
- `seal_proofpacket.py` - deterministic, tamper-evident FISH-field ProofPacket
  sealer.
- `bridge.json` - artifact to Tier-1/2/3 routing. Tier-2 and Tier-3 are future
  HUMAN-GATE-ONLY RECORDED-PENDING gates.
- `ship_gate.sh` - HARD-AND orchestrator over the Tier-1 gates that seals a
  ProofPacket only on a fully GREEN run.
- `samples/` - clean and intentionally failing fixtures for each linter.

Tier-1 is automated GREEN/RED. Tier-2 (adversarial teardown versus gold) and
Tier-3 (panel plus Week-2 activation metric trace) are future human gates and are
never auto-greened.

### 3. Gold reference (`gold/`)

A competitor gold reference library.

- `named-gold.json` - 6 named in-app surfaces (daily-readiness-home,
  workout-logging-active-set, post-session-debrief, onboarding-first-run,
  progress-trends, paywall-upgrade) plus 3 design references (Linear, Vercel,
  Apple). Each entry has a `screenshot_ref`, scored dimensions, and rationale.
- `assessments/` - 7 competitor write-ups: MacroFactor, Hevy, Caliber, Future,
  Whoop, Oura, Noom.
- `screenshots/` - 15 PNG captures plus provenance in `manifest.json`.
- `LIMITATIONS.md` - honest scope. Captures are from public web and app-store
  surfaces only; no authenticated in-app captures were taken.

Note: `caliberstrong.com` is the real Caliber fitness app. The older `caliber.co`
profile was an unrelated luxury home builder (a documented domain collision).

### 4. Flutter walking skeleton

A `flutter create` project targeting web and macOS.

- Riverpod is wired: `ProviderScope` bootstraps the app in `lib/main.dart`, and
  the provider (`coachNoteProvider`) lives in `lib/app_providers.dart`.
- Digital Atelier design tokens are expressed as a real `ThemeData` in
  `lib/theme/digital_atelier.dart`: background `#0A0A0A`, text `#F0EDE8`, accent
  orange `#F97316`, Playfair for coach voice, Inter for data, corner radius 4.
- One placeholder coach-voice "Today" screen in `lib/screens/today_screen.dart`.
- Widget tests in `test/` (`today_screen_test.dart`, `widget_test.dart`) that
  assert the Today screen content, not the counter boilerplate.
- `.github/workflows/ci.yml` runs the Tier-1 harness gates, then
  `flutter pub get`, `flutter analyze`, `flutter test`, and `flutter build web`.
- `BUILD-STATUS.md` records build outcomes honestly: web is GREEN, macOS failed
  (xcodebuild unavailable), Android APK and iOS simulator are UNAVAILABLE with
  `flutter doctor -v` evidence.

## Environment

- Flutter 3.44.4 / Dart 3.12.2 at `/Users/rig128gb/Developer/flutter-sdk`.
- Node v22.22.3 via nvm (`source ~/.nvm/nvm.sh`).
- Python 3.9.6 (`python3`).
- Target platforms: web and macOS only. Android and iOS are UNAVAILABLE in this
  environment (see `BUILD-STATUS.md`).

Add Flutter to PATH before running Flutter commands:

```bash
export PATH="/Users/rig128gb/Developer/flutter-sdk/bin:$PATH"
```

## How to run

### Flutter

```bash
flutter pub get
flutter analyze
flutter test
flutter build web
flutter build macos   # fails here: xcodebuild unavailable, see BUILD-STATUS.md
```

### Harness self-tests

Linters pass (exit 0) on clean fixtures and fail (non-zero) on bad fixtures:

```bash
python3 transformfit-harness/doctrine_lint.py transformfit-harness/samples/clean.md      # exit 0
python3 transformfit-harness/doctrine_lint.py transformfit-harness/samples/banned.md      # non-zero

python3 transformfit-harness/message_rule_lint.py transformfit-harness/samples/clean_message.md   # exit 0
python3 transformfit-harness/message_rule_lint.py transformfit-harness/samples/msg_emoji.md        # non-zero

bash transformfit-harness/design_lint.sh transformfit-harness/samples/design_clean.json            # exit 0
bash transformfit-harness/design_lint.sh transformfit-harness/samples/design_bad_contrast.json     # non-zero
```

Run the full HARD-AND ship gate (GREEN on clean inputs, seals a ProofPacket only
when every Tier-1 gate is GREEN):

```bash
bash transformfit-harness/ship_gate.sh
```

## Scope

This slice is Phase 0 plus the gold reference and the walking skeleton. The full
TransformFit app build (the later phases) is intentionally out of scope and is
future work.
