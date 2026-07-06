#!/usr/bin/env bash
# ship_gate.sh — TransformFit Harness HARD-AND ship gate orchestrator.
#
# Mirrors rig-design-studio/gtm gate-shared.mjs (the anti-fake-green law) +
# bridge.json (artifact-type routing). HARD-AND over the BUILT Tier-1 gates:
#   doctrine_lint  ∧  message_rule_lint  ∧  design_lint  ∧  build_test_gate
#   ∧ coaching_harness_gate ∧ competitive_reverse_engineering_gate
#   ∧ ux_ui_research_ingestion_gate ∧ coaching_runtime_gate
#   ∧ coach_quality_eval_gate ∧ nutrition_target_gate
#   ∧ body_composition_trust_gate
#   ∧ workout_logger_intelligence_gate
#   ∧ wearable_dai_interface_gate
#   ∧ coach_command_center_gate
#   ∧ behavioral_repair_loop_gate
#   ∧ emotional_experience_map_gate
#   ∧ rig_systems_engineering_gate
#   ∧ testsprite_full_user_testing_gate
#   ∧ fitness_agent_review_swarm_gate
#   ∧ native_mobile_setup_gate ∧ two_day_war_room_gate
#   ∧ five_star_experience_gate ∧ value_before_auth_gate
#   ∧ first_session_handoff_gate ∧ accessibility_low_end_device_gate
#   ∧ perf_frame_budget_gate ∧ ship_gate_non_vacuity_gate
#
# Fail-closed (VAL-HAR-026, VAL-HAR-034):
#   - ANY Tier-1 RED -> exit non-zero, AND NO ProofPacket is sealed (incl. a
#     MIXED case where one gate is RED and others GREEN).
#   - GREEN ONLY when every built Tier-1 gate is GREEN.
#
# Future tiers (VAL-HAR-027, VAL-HAR-032, VAL-CROSS-010):
#   - Tier-2 (adversarial_teardown) and Tier-3 (coach_buyer_panel) are DEFINED
#     in bridge.json as future HUMAN-GATE-ONLY RECORDED-PENDING gates. At
#     runtime the ship-gate LOGS them as RECORDED-PENDING/future — they are
#     neither auto-greened nor fatally blocking (not yet built).
#
# Proof-or-it-didn't-happen (VAL-CROSS-001, VAL-CROSS-011):
#   - On a GREEN run, a ProofPacket is sealed for the primary artifact via
#     seal_proofpacket.py (FISH fields + deterministic hash). On a RED run,
#     NO ProofPacket is sealed.
#
# Usage:
#   bash ship_gate.sh [--message <coach-message-file>] [--screen <design-sample-file>] [--repo-root <dir>] [--identity <name>]
#
#   Defaults:
#     --message   transformfit-harness/samples/clean_message.md
#     --screen    transformfit-harness/samples/design_clean.json
#     --repo-root <parent of this script's dir>
#     --identity  transformfit-harness
set -u

FLUTTER_SDK="${FLUTTER_SDK:-}"
if [ -n "${FLUTTER_SDK}" ] && [ -x "${FLUTTER_SDK}/bin/flutter" ]; then
  export PATH="${FLUTTER_SDK}/bin:${PATH}"
fi
if ! command -v flutter >/dev/null 2>&1 && [ -x "/Users/rig128gb/.homebrew/share/flutter/bin/flutter" ]; then
  export PATH="/Users/rig128gb/.homebrew/share/flutter/bin:${PATH}"
fi
if ! command -v flutter >/dev/null 2>&1 && [ -x "/Users/rig128gb/Developer/flutter-sdk/bin/flutter" ]; then
  export PATH="/Users/rig128gb/Developer/flutter-sdk/bin:${PATH}"
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT_DEFAULT="$(cd "${SCRIPT_DIR}/.." && pwd)"

MESSAGE_DEFAULT="${SCRIPT_DIR}/samples/clean_message.md"
SCREEN_DEFAULT="${SCRIPT_DIR}/samples/design_clean.json"
IDENTITY_DEFAULT="transformfit-harness"

MESSAGE="${MESSAGE_DEFAULT}"
SCREEN="${SCREEN_DEFAULT}"
REPO_ROOT="${REPO_ROOT_DEFAULT}"
IDENTITY="${IDENTITY_DEFAULT}"

print_usage() {
  cat <<EOF
Usage: bash ship_gate.sh [--message <file>] [--screen <file>] [--repo-root <dir>] [--identity <name>]
  --message    coach message sample for doctrine_lint + message_rule_lint (default: samples/clean_message.md)
  --screen     design sample for design_lint (default: samples/design_clean.json)
  --repo-root  Flutter project root for build_test_gate (default: parent of harness dir)
  --identity   sealing identity for the ProofPacket (default: transformfit-harness)
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --message) MESSAGE="$2"; shift 2 ;;
    --screen)  SCREEN="$2";  shift 2 ;;
    --repo-root) REPO_ROOT="$2"; shift 2 ;;
    --identity) IDENTITY="$2"; shift 2 ;;
    -h|--help) print_usage; exit 0 ;;
    *) echo "ERROR: unknown argument: $1" >&2; print_usage >&2; exit 2 ;;
  esac
done

SEALER="${SCRIPT_DIR}/seal_proofpacket.py"
DOCTRINE_LINT="${SCRIPT_DIR}/doctrine_lint.py"
MESSAGE_RULE_LINT="${SCRIPT_DIR}/message_rule_lint.py"
DESIGN_LINT="${SCRIPT_DIR}/design_lint.sh"
BUILD_TEST_GATE="${SCRIPT_DIR}/build_test_gate.sh"
COACHING_HARNESS_GATE="${SCRIPT_DIR}/coaching_harness_gate.py"
COMPETITIVE_REVERSE_ENGINEERING_GATE="${SCRIPT_DIR}/competitive_reverse_engineering_gate.py"
UX_UI_RESEARCH_INGESTION_GATE="${SCRIPT_DIR}/ux_ui_research_ingestion_gate.py"
COACHING_RUNTIME_GATE="${SCRIPT_DIR}/coaching_runtime_gate.py"
COACH_QUALITY_EVAL_GATE="${SCRIPT_DIR}/coach_quality_eval_gate.py"
NUTRITION_TARGET_GATE="${SCRIPT_DIR}/nutrition_target_gate.py"
BODY_COMPOSITION_TRUST_GATE="${SCRIPT_DIR}/body_composition_trust_gate.py"
WORKOUT_LOGGER_INTELLIGENCE_GATE="${SCRIPT_DIR}/workout_logger_intelligence_gate.py"
WEARABLE_DAI_INTERFACE_GATE="${SCRIPT_DIR}/wearable_dai_interface_gate.py"
COACH_COMMAND_CENTER_GATE="${SCRIPT_DIR}/coach_command_center_gate.py"
BEHAVIORAL_REPAIR_LOOP_GATE="${SCRIPT_DIR}/behavioral_repair_loop_gate.py"
EMOTIONAL_EXPERIENCE_MAP_GATE="${SCRIPT_DIR}/emotional_experience_map_gate.py"
RIG_SYSTEMS_ENGINEERING_GATE="${SCRIPT_DIR}/rig_systems_engineering_gate.py"
TESTSPRITE_FULL_USER_TESTING_GATE="${SCRIPT_DIR}/testsprite_full_user_testing_gate.py"
FITNESS_AGENT_REVIEW_SWARM_GATE="${SCRIPT_DIR}/fitness_agent_review_swarm_gate.py"
NATIVE_MOBILE_SETUP_GATE="${SCRIPT_DIR}/native_mobile_setup_gate.py"
TWO_DAY_WAR_ROOM_GATE="${SCRIPT_DIR}/two_day_war_room_gate.py"
FIVE_STAR_EXPERIENCE_GATE="${SCRIPT_DIR}/five_star_experience_gate.py"
VALUE_BEFORE_AUTH_GATE="${SCRIPT_DIR}/value_before_auth_gate.py"
FIRST_SESSION_HANDOFF_GATE="${SCRIPT_DIR}/first_session_handoff_gate.py"
ACCESSIBILITY_LOW_END_DEVICE_GATE="${SCRIPT_DIR}/accessibility_low_end_device_gate.py"
PERF_FRAME_BUDGET_GATE="${SCRIPT_DIR}/perf_frame_budget_gate.py"
SHIP_GATE_NON_VACUITY_GATE="${SCRIPT_DIR}/ship_gate_non_vacuity_gate.py"
COACHING_HARNESS="${SCRIPT_DIR}/coaching_harness.json"
COMPETITIVE_LEDGER="${SCRIPT_DIR}/competitive_reverse_engineering.json"
UX_UI_RESEARCH_INGESTION="${SCRIPT_DIR}/ux_ui_research_ingestion.json"
NUTRITION_TARGET_SOURCES="${SCRIPT_DIR}/nutrition_target_sources.json"
BODY_COMPOSITION_SOURCES="${SCRIPT_DIR}/body_composition_sources.json"
WORKOUT_LOGGER_SOURCES="${SCRIPT_DIR}/workout_logger_sources.json"
WEARABLE_DAI_SOURCES="${SCRIPT_DIR}/wearable_dai_sources.json"
TESTSPRITE_FULL_USER_TESTING="${SCRIPT_DIR}/testsprite_full_user_testing.json"
FITNESS_AGENT_REVIEW_SWARM="${SCRIPT_DIR}/fitness_agent_review_swarm.json"
TWO_DAY_WAR_ROOM="${SCRIPT_DIR}/two_day_war_room.json"
PACKETS_DIR="${SCRIPT_DIR}/packets"

# Fail-closed tally. Any RED sets fail=1; the gate exits non-zero and NO
# ProofPacket is sealed.
fail=0
gates_red=()
gates_green=()

record_green() { gates_green+=("$1"); echo "  ✓ GREEN $1"; }
record_red()   { gates_red+=("$1");   echo "  ✗ RED   $1"; fail=1; }

echo "[SHIP-GATE] repo: ${REPO_ROOT}"
echo "[SHIP-GATE] message: ${MESSAGE}"
echo "[SHIP-GATE] screen:  ${SCREEN}"
echo

# ── Tier-1 gate 1/27: doctrine_lint on the coach message ────────────────────
echo "── Tier-1 1/27: doctrine_lint ──────────────────────────────────────────"
if python3 "${DOCTRINE_LINT}" "${MESSAGE}"; then
  record_green "doctrine_lint"
else
  record_red "doctrine_lint (exit $?)"
fi
echo

# ── Tier-1 gate 2/27: message_rule_lint on the coach message ────────────────
echo "── Tier-1 2/27: message_rule_lint ──────────────────────────────────────"
if python3 "${MESSAGE_RULE_LINT}" "${MESSAGE}"; then
  record_green "message_rule_lint"
else
  record_red "message_rule_lint (exit $?)"
fi
echo

# ── Tier-1 gate 3/27: design_lint on the screen sample ──────────────────────
echo "── Tier-1 3/27: design_lint ────────────────────────────────────────────"
if bash "${DESIGN_LINT}" "${SCREEN}"; then
  record_green "design_lint"
else
  record_red "design_lint (exit $?)"
fi
echo

# ── Tier-1 gate 4/27: build_test_gate on the Flutter project ────────────────
echo "── Tier-1 4/27: build_test_gate ─────────────────────────────────────────"
if bash "${BUILD_TEST_GATE}" "${REPO_ROOT}"; then
  record_green "build_test_gate"
else
  record_red "build_test_gate (exit $?)"
fi
echo

# ── Tier-1 gate 5/27: coaching_harness_gate ─────────────────────────────────
echo "── Tier-1 5/27: coaching_harness_gate ──────────────────────────────────"
if python3 "${COACHING_HARNESS_GATE}" "${COACHING_HARNESS}"; then
  record_green "coaching_harness_gate"
else
  record_red "coaching_harness_gate (exit $?)"
fi
echo

# ── Tier-1 gate 6/27: competitive_reverse_engineering_gate ──────────────────
echo "── Tier-1 6/27: competitive_reverse_engineering_gate ───────────────────"
if python3 "${COMPETITIVE_REVERSE_ENGINEERING_GATE}" "${COMPETITIVE_LEDGER}" --require-complete; then
  record_green "competitive_reverse_engineering_gate"
else
  record_red "competitive_reverse_engineering_gate (exit $?)"
fi
echo

# ── Tier-1 gate 7/27: ux_ui_research_ingestion_gate ─────────────────────────
echo "── Tier-1 7/27: ux_ui_research_ingestion_gate ──────────────────────────"
if python3 "${UX_UI_RESEARCH_INGESTION_GATE}" "${UX_UI_RESEARCH_INGESTION}" \
  --competitive-ledger "${COMPETITIVE_LEDGER}" \
  --coaching-harness "${COACHING_HARNESS}" \
  --repo-root "${REPO_ROOT}"; then
  record_green "ux_ui_research_ingestion_gate"
else
  record_red "ux_ui_research_ingestion_gate (exit $?)"
fi
echo

# ── Tier-1 gate 8/27: coaching_runtime_gate ─────────────────────────────────
echo "── Tier-1 8/27: coaching_runtime_gate ──────────────────────────────────"
if python3 "${COACHING_RUNTIME_GATE}" --repo-root "${REPO_ROOT}"; then
  record_green "coaching_runtime_gate"
else
  record_red "coaching_runtime_gate (exit $?)"
fi
echo

# ── Tier-1 gate 9/27: coach_quality_eval_gate ───────────────────────────────
echo "── Tier-1 9/27: coach_quality_eval_gate ────────────────────────────────"
if python3 "${COACH_QUALITY_EVAL_GATE}" --repo-root "${REPO_ROOT}"; then
  record_green "coach_quality_eval_gate"
else
  record_red "coach_quality_eval_gate (exit $?)"
fi
echo

# ── Tier-1 gate 10/27: nutrition_target_gate ────────────────────────────────
echo "── Tier-1 10/27: nutrition_target_gate ─────────────────────────────────"
if python3 "${NUTRITION_TARGET_GATE}" --repo-root "${REPO_ROOT}"; then
  record_green "nutrition_target_gate"
else
  record_red "nutrition_target_gate (exit $?)"
fi
echo

# ── Tier-1 gate 11/27: body_composition_trust_gate ─────────────────────────
echo "── Tier-1 11/27: body_composition_trust_gate ───────────────────────────"
if python3 "${BODY_COMPOSITION_TRUST_GATE}" --repo-root "${REPO_ROOT}"; then
  record_green "body_composition_trust_gate"
else
  record_red "body_composition_trust_gate (exit $?)"
fi
echo

# ── Tier-1 gate 12/27: workout_logger_intelligence_gate ─────────────────────
echo "── Tier-1 12/27: workout_logger_intelligence_gate ──────────────────────"
if python3 "${WORKOUT_LOGGER_INTELLIGENCE_GATE}" --repo-root "${REPO_ROOT}"; then
  record_green "workout_logger_intelligence_gate"
else
  record_red "workout_logger_intelligence_gate (exit $?)"
fi
echo

# ── Tier-1 gate 13/27: wearable_dai_interface_gate ─────────────────────────
echo "── Tier-1 13/27: wearable_dai_interface_gate ───────────────────────────"
if python3 "${WEARABLE_DAI_INTERFACE_GATE}" --repo-root "${REPO_ROOT}"; then
  record_green "wearable_dai_interface_gate"
else
  record_red "wearable_dai_interface_gate (exit $?)"
fi
echo

# ── Tier-1 gate 14/27: coach_command_center_gate ────────────────────────────
echo "── Tier-1 14/27: coach_command_center_gate ─────────────────────────────"
if python3 "${COACH_COMMAND_CENTER_GATE}" --repo-root "${REPO_ROOT}"; then
  record_green "coach_command_center_gate"
else
  record_red "coach_command_center_gate (exit $?)"
fi
echo

# ── Tier-1 gate 15/27: behavioral_repair_loop_gate ─────────────────────────
echo "── Tier-1 15/27: behavioral_repair_loop_gate ──────────────────────────"
if python3 "${BEHAVIORAL_REPAIR_LOOP_GATE}" --repo-root "${REPO_ROOT}"; then
  record_green "behavioral_repair_loop_gate"
else
  record_red "behavioral_repair_loop_gate (exit $?)"
fi
echo

# ── Tier-1 gate 16/27: emotional_experience_map_gate ───────────────────────
echo "── Tier-1 16/27: emotional_experience_map_gate ────────────────────────"
if python3 "${EMOTIONAL_EXPERIENCE_MAP_GATE}" --repo-root "${REPO_ROOT}"; then
  record_green "emotional_experience_map_gate"
else
  record_red "emotional_experience_map_gate (exit $?)"
fi
echo

# ── Tier-1 gate 17/27: rig_systems_engineering_gate ─────────────────────────
echo "── Tier-1 17/27: rig_systems_engineering_gate ──────────────────────────"
if python3 "${RIG_SYSTEMS_ENGINEERING_GATE}" --repo-root "${REPO_ROOT}"; then
  record_green "rig_systems_engineering_gate"
else
  record_red "rig_systems_engineering_gate (exit $?)"
fi
echo

# ── Tier-1 gate 18/27: testsprite_full_user_testing_gate ────────────────────
echo "── Tier-1 18/27: testsprite_full_user_testing_gate ─────────────────────"
if python3 "${TESTSPRITE_FULL_USER_TESTING_GATE}" "${TESTSPRITE_FULL_USER_TESTING}" --repo-root "${REPO_ROOT}"; then
  record_green "testsprite_full_user_testing_gate"
else
  record_red "testsprite_full_user_testing_gate (exit $?)"
fi
echo

# ── Tier-1 gate 19/27: native_mobile_setup_gate ─────────────────────────────
echo "── Tier-1 19/27: native_mobile_setup_gate ──────────────────────────────"
if python3 "${NATIVE_MOBILE_SETUP_GATE}" --repo-root "${REPO_ROOT}"; then
  record_green "native_mobile_setup_gate"
else
  record_red "native_mobile_setup_gate (exit $?)"
fi
echo

# ── Tier-1 gate 20/27: fitness_agent_review_swarm_gate ─────────────────────
echo "── Tier-1 20/27: fitness_agent_review_swarm_gate ──────────────────────"
if python3 "${FITNESS_AGENT_REVIEW_SWARM_GATE}" "${FITNESS_AGENT_REVIEW_SWARM}" --repo-root "${REPO_ROOT}"; then
  record_green "fitness_agent_review_swarm_gate"
else
  record_red "fitness_agent_review_swarm_gate (exit $?)"
fi
echo

# ── Tier-1 gate 21/27: two_day_war_room_gate ────────────────────────────────
echo "── Tier-1 21/27: two_day_war_room_gate ─────────────────────────────────"
if python3 "${TWO_DAY_WAR_ROOM_GATE}" "${TWO_DAY_WAR_ROOM}"; then
  record_green "two_day_war_room_gate"
else
  record_red "two_day_war_room_gate (exit $?)"
fi
echo

# ── Tier-1 gate 22/27: five_star_experience_gate ───────────────────────────
echo "── Tier-1 22/27: five_star_experience_gate ────────────────────────────"
if python3 "${FIVE_STAR_EXPERIENCE_GATE}" --repo-root "${REPO_ROOT}"; then
  record_green "five_star_experience_gate"
else
  record_red "five_star_experience_gate (exit $?)"
fi
echo

# ── Tier-1 gate 23/27: value_before_auth_gate ──────────────────────────────
echo "── Tier-1 23/27: value_before_auth_gate ───────────────────────────────"
if python3 "${VALUE_BEFORE_AUTH_GATE}" --repo-root "${REPO_ROOT}"; then
  record_green "value_before_auth_gate"
else
  record_red "value_before_auth_gate (exit $?)"
fi
echo

# ── Tier-1 gate 24/27: first_session_handoff_gate ──────────────────────────
echo "── Tier-1 24/27: first_session_handoff_gate ───────────────────────────"
if python3 "${FIRST_SESSION_HANDOFF_GATE}" --repo-root "${REPO_ROOT}"; then
  record_green "first_session_handoff_gate"
else
  record_red "first_session_handoff_gate (exit $?)"
fi
echo

# ── Tier-1 gate 25/27: accessibility_low_end_device_gate ───────────────────
echo "── Tier-1 25/27: accessibility_low_end_device_gate ────────────────────"
if python3 "${ACCESSIBILITY_LOW_END_DEVICE_GATE}" --repo-root "${REPO_ROOT}"; then
  record_green "accessibility_low_end_device_gate"
else
  record_red "accessibility_low_end_device_gate (exit $?)"
fi
echo

# ── Tier-1 gate 26/27: perf_frame_budget_gate ──────────────────────────────
echo "── Tier-1 26/27: perf_frame_budget_gate ───────────────────────────────"
if python3 "${PERF_FRAME_BUDGET_GATE}" --repo-root "${REPO_ROOT}"; then
  record_green "perf_frame_budget_gate"
else
  record_red "perf_frame_budget_gate (exit $?)"
fi
echo

# ── Tier-1 gate 27/27: ship_gate_non_vacuity_gate ──────────────────────────
echo "── Tier-1 27/27: ship_gate_non_vacuity_gate ───────────────────────────"
if python3 "${SHIP_GATE_NON_VACUITY_GATE}" --repo-root "${REPO_ROOT}"; then
  record_green "ship_gate_non_vacuity_gate"
else
  record_red "ship_gate_non_vacuity_gate (exit $?)"
fi
echo

# ── Future tiers: RECORDED-PENDING / not-run (logged at runtime) ────────────
# Anti-fake-green: these are NEVER auto-greened. They are logged as future /
# RECORDED-PENDING so the disposition is auditable, but they do NOT block
# (not yet built) and do NOT green the run.
echo "── Tier-2 (future): adversarial_teardown ───────────────────────────────"
echo "  · RECORDED-PENDING — future HUMAN-GATE-ONLY gate (built: false)."
echo "  · Grading target: gold/named-gold.json (calibrated in M3)."
echo "  · pass condition: authored-exp >= 86 AND activation >= 82 (maker != grader)."
echo "  · NOT auto-greened. NOT blocking (not yet built). RECORDED-PENDING."
echo
echo "── Tier-3 (future): coach_buyer_panel ───────────────────────────────────"
echo "  · RECORDED-PENDING — future HUMAN-GATE-ONLY gate (built: false)."
echo "  · Metric trace: does it move Week-2 activation? (>=30% Week-2 activated"
echo "    retention = >=3 readiness-adjusted sessions in 14 days)."
echo "  · pass condition: verdict = BOOK (Marcus/David/Jordan persona panel)."
echo "  · NOT auto-greened. NOT blocking (not yet built). RECORDED-PENDING."
echo

# ── Verdict ─────────────────────────────────────────────────────────────────
echo "============================================================"
echo "  Tier-1 GREEN: ${#gates_green[@]}  RED: ${#gates_red[@]}"
if [ "${#gates_red[@]}" -gt 0 ]; then
  for g in "${gates_red[@]}"; do echo "  ✗ RED   ${g}"; done
fi
echo "  Tier-2: RECORDED-PENDING (future, not auto-green, not blocking)"
echo "  Tier-3: RECORDED-PENDING (future, not auto-green, not blocking)"
echo "============================================================"

if [ "$fail" -ne 0 ]; then
  echo "[SHIP-GATE: RED] HARD-AND failed — ${#gates_red[@]} Tier-1 gate(s) RED."
  echo "[SHIP-GATE: RED] NO ProofPacket sealed (fail-closed: no seal on a RED run)."
  exit 1
fi

# ── GREEN: seal a ProofPacket for the primary artifact (the coach message) ──
# Proof-or-it-didn't-happen: a GREEN run seals a deterministic, immutable
# ProofPacket with FISH fields. The coach message is the primary artifact;
# the screen and build are recorded in the gate-results provenance.
echo "[SHIP-GATE: GREEN] all built Tier-1 gates GREEN; sealing ProofPacket..."

SEAL_OK=0
if python3 "${SEALER}" "${MESSAGE}" --identity "${IDENTITY}" --packets-dir "${PACKETS_DIR}" 2>"${PACKETS_DIR}/.seal_stderr"; then
  SEAL_OK=1
else
  echo "[SHIP-GATE: ERROR] ProofPacket seal failed (exit $?) — see ${PACKETS_DIR}/.seal_stderr" >&2
  cat "${PACKETS_DIR}/.seal_stderr" >&2 2>/dev/null || true
  fail=1
fi

# Also seal the screen and harness artifacts so the message, screen, coaching
# contract, competitive ledger, research-ingestion map, runtime gate, coach
# quality eval gate, nutrition target gate, body composition trust gate, workout
# logger intelligence gate, wearable DAI interface gate, coach command center
# gate, behavioral repair loop gate, emotional experience map gate, RIG systems
# engineering gate, TestSprite user-testing gate, fitness agent review swarm
# gate, native mobile setup gate, two-day war-room gate, five-star experience
# gate, value-before-auth gate, first-session handoff gate, accessibility low-end
# device gate, performance frame-budget gate, and ship-gate non-vacuity gate
# each have a ProofPacket
# (VAL-CROSS-011 end-to-end seal on every routed sample type).
if [ "$SEAL_OK" -eq 1 ]; then
  if ! python3 "${SEALER}" "${SCREEN}" --identity "${IDENTITY}" --packets-dir "${PACKETS_DIR}" 2>>"${PACKETS_DIR}/.seal_stderr"; then
    echo "[SHIP-GATE: ERROR] screen ProofPacket seal failed (exit $?)" >&2
    cat "${PACKETS_DIR}/.seal_stderr" >&2 2>/dev/null || true
    fail=1
  fi
fi
if [ "$SEAL_OK" -eq 1 ]; then
  for ARTIFACT in "${COACHING_HARNESS}" "${COMPETITIVE_LEDGER}" "${UX_UI_RESEARCH_INGESTION}" "${COACHING_RUNTIME_GATE}" "${COACH_QUALITY_EVAL_GATE}" "${NUTRITION_TARGET_GATE}" "${NUTRITION_TARGET_SOURCES}" "${BODY_COMPOSITION_TRUST_GATE}" "${BODY_COMPOSITION_SOURCES}" "${WORKOUT_LOGGER_INTELLIGENCE_GATE}" "${WORKOUT_LOGGER_SOURCES}" "${WEARABLE_DAI_INTERFACE_GATE}" "${WEARABLE_DAI_SOURCES}" "${COACH_COMMAND_CENTER_GATE}" "${BEHAVIORAL_REPAIR_LOOP_GATE}" "${EMOTIONAL_EXPERIENCE_MAP_GATE}" "${RIG_SYSTEMS_ENGINEERING_GATE}" "${TESTSPRITE_FULL_USER_TESTING_GATE}" "${TESTSPRITE_FULL_USER_TESTING}" "${FITNESS_AGENT_REVIEW_SWARM_GATE}" "${FITNESS_AGENT_REVIEW_SWARM}" "${NATIVE_MOBILE_SETUP_GATE}" "${TWO_DAY_WAR_ROOM}" "${TWO_DAY_WAR_ROOM_GATE}" "${FIVE_STAR_EXPERIENCE_GATE}" "${VALUE_BEFORE_AUTH_GATE}" "${FIRST_SESSION_HANDOFF_GATE}" "${ACCESSIBILITY_LOW_END_DEVICE_GATE}" "${PERF_FRAME_BUDGET_GATE}" "${SHIP_GATE_NON_VACUITY_GATE}"; do
    if ! python3 "${SEALER}" "${ARTIFACT}" --identity "${IDENTITY}" --packets-dir "${PACKETS_DIR}" 2>>"${PACKETS_DIR}/.seal_stderr"; then
      echo "[SHIP-GATE: ERROR] ProofPacket seal failed for ${ARTIFACT} (exit $?)" >&2
      cat "${PACKETS_DIR}/.seal_stderr" >&2 2>/dev/null || true
      fail=1
    fi
  done
fi

if [ "$fail" -ne 0 ]; then
  echo "[SHIP-GATE: RED] seal failed after GREEN gates — no valid ProofPacket." >&2
  exit 1
fi

echo "[SHIP-GATE: GREEN] ProofPacket(s) sealed under ${PACKETS_DIR}/ (FISH fields + deterministic hash)."
echo "[SHIP-GATE: GREEN] Tier 2/3 logged as RECORDED-PENDING/future — not auto-greened, not blocking."
exit 0
