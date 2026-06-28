# TransformFit - Build Status

Snapshot of what has been built and what remains for the **TransformFit full-app** mission
(Flutter web client + real Supabase backend + real OpenRouter AI coaching), built on top of
the completed "first slice" (Doctrine + Harness + gold + walking skeleton).

Last updated: 2026-06-28

---

## 1. What this product is

TransformFit is an adaptive strength/conditioning coaching app. Its defining invariant is
**deterministic-before-agentic**: deterministic engines compute every training-changing number
(readiness score/zone, volume multiplier, per-exercise weight/reps, deload), and the LLM may
**only** write narrative (headline, reasoning, changes_made, coaching_cue) and may never alter a
number, exercise, or zone. If the LLM call fails, the app surfaces an explicitly-flagged
deterministic fallback (never a silent hardcoded template).

**Stack**
- **Client:** Flutter 3.44.4 / Dart 3.12.2, **web** target, Riverpod, go_router, drift (offline), supabase_flutter.
- **Backend:** Supabase (Postgres + RLS + Auth + Edge Functions on Deno 2.8.3), project `zuwtgdqsxmtiqojckpus`.
- **AI:** OpenRouter (`z-ai/glm-5.1`), called server-side from an Edge Function (key never reaches the client).
- **Validation surface:** Flutter web on port **7357**, driven by agent-browser against a labeled semantics DOM.
- **Quality spine:** the existing `transformfit-harness/` ship-gate (Tier-1 lints + build/test) seals a ProofPacket on GREEN.

---

## 2. Built and committed

### First slice (complete - 124/124 validations)
- **TRANSFORMFIT-DOCTRINE** - 6-layer binding law-book with tests.
- **Harness** - coaching/copy lint (`doctrine_lint.py`, `message_rule_lint.py`, banned-phrases),
  design/engineering lint (`design_lint.sh`: orange<=3, WCAG AA contrast, font-role, radius 0-4px;
  `build_test_gate.sh`), seal + ship-gate (`seal_proofpacket.py`, `bridge.json`, `ship_gate.sh`) + CI.
- **Gold** - competitor assessments, `named-gold.json`, L4<->gold consistency, provenance manifest.
- **Walking skeleton** + accurate README.

### Full-app mission so far
- **Mission setup** - hardened `.gitignore` for `.env.*`, added `sample.env.example` template.
- **M0 - App shell bootstrap** (`5bfc4a6`) - semantics-enabled Flutter web shell:
  `main()` runs `WidgetsFlutterBinding.ensureInitialized()` then (web) `SemanticsBinding.instance.ensureSemantics()`
  before `runApp(ProviderScope(...))`; `MaterialApp.router`; first screen exposes labeled semantic nodes
  (`Today heading`, `Coach note`, `Start today session`). Serves on 7357 with a populated accessibility DOM.
  Analyzer + widget tests green; verified via agent-browser including reload persistence.
- **M0 - Routing + guards** (this commit) - go_router with URL-addressable, deep-linkable routes,
  auth-redirect guard (no session -> /auth; authed but no profile -> /onboarding) without flashing
  protected content, browser back/forward integration, and a controlled fallback for unknown routes.
  New: `lib/navigation/auth_state.dart`, `lib/screens/{auth,loading,not_found,onboarding,profile}_screen.dart`,
  `test/navigation/`. **Status: implementation complete and `flutter analyze` clean; browser
  verification + final sign-off still pending** (see Known Issues).

---

## 3. In progress

- **m0-routing-and-guards** - implementation done and analyze-clean; the agent-browser verification
  pass (deep links, back/forward, guard redirects, no-flash) and harness sign-off are not yet committed.

---

## 4. What is left to build (milestones M0-M8)

37 leaf features total: **1 completed, 1 in progress, 35 pending**. Each milestone is sealed by two
auto-injected validators (scrutiny + user-testing); 9 milestones => ~18 validation passes.

Worker types: `flutter-client` (UI/routing/theme/drift/state), `supabase-backend` (schema/RLS/auth/edge functions),
`deterministic-engine` (Dart+Deno engine duality - identical numbers on both runtimes).

| Milestone | Remaining features |
|-----------|--------------------|
| **M0 foundation** | theme/design-tokens (Digital Atelier ThemeData), drift + supabase client init |
| **M1 auth + data** | schema/RLS/`handle_new_user` trigger, auth client flows, edge auth/entitlement |
| **M2 onboarding** | landing/welcome, intake quiz, plan-generation engine, onboarding narration fn, plan reveal, first-session handoff |
| **M3 readiness** | readiness engine, process-readiness fn, dai-adapt fn, check-in UI, home/Today surface, first-visit nav |
| **M4 logging** | progression engine, fatigue/ACWR engine, active logger UI, offline sync, progression-corridor integration |
| **M5 debrief** | post-session-analysis fn, debrief UI |
| **M6 trends** | recalibration engine parity, weekly-recalibration fn, trends UI, recommit flow, core-loop harness gate |
| **M7 coaching** | personas/tone-arc, message-linter guardrail, AI-coach streaming fn, coach-consistency UI |
| **M8 danger zones** | danger-zone engine + dispatch, danger-zone screens |

### Validation
- **443 behavioral assertions** across 10 areas (FND, AUTH, ONB, TRD, RDY, LOG, DBR, COACH, DZ, CROSS),
  defined in the mission's `validation-contract.md`. **All currently pending** - the definition of done
  is "every assertion passed via end-to-end (real Supabase + real OpenRouter) agent-browser testing."

---

## 5. Known issues / mission infra notes

- **Worker model:** the custom LAN reasoning model returned `content:null` with output only in a
  non-standard `reasoning` field (no `tool_calls`), so worker sessions exited immediately. Switched the
  mission worker model to a standard agentic tool-calling model; M0 app shell then passed cleanly.
- **Daemon inactivity timeout:** browser-heavy features can blow past the worker-session inactivity
  window during the long agent-browser verification phase (cold Flutter web compile + many UI steps),
  killing an otherwise-healthy session and losing uncommitted work. Mitigation applied to mission
  guidance: **commit the implementation as soon as analyze + scoped tests are green, before the browser
  verification phase**, reuse a pre-warmed web server (healthcheck first, never foreground `flutter run`),
  and avoid single long-blocking commands. (This is why M0 routing is committed as a pre-verification checkpoint.)

---

## 6. Run / test

```bash
# Canonical PATH (flutter-sdk pins 3.44.4; supabase + deno live only in .homebrew/bin)
export PATH="/Users/rig128gb/Developer/flutter-sdk/bin:/Users/rig128gb/.homebrew/bin:$PATH"

flutter pub get
flutter analyze            # typecheck + lint gate
flutter test               # Dart unit/widget tests

# Web dev server (validation surface on 7357); only SUPABASE_URL + SUPABASE_ANON_KEY reach the client
set -a; eval "$(grep -E '^(SUPABASE_URL|SUPABASE_ANON_KEY)=' .env.local)"; set +a
flutter run -d web-server --web-port 7357 --web-hostname 0.0.0.0 \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY"
```

Secrets live only in gitignored `.env.local` (see `sample.env.example`). `SUPABASE_SERVICE_ROLE_KEY`
and `OPENROUTER_API_KEY` are server-side only and must never reach the web client.
