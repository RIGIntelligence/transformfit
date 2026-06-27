#!/usr/bin/env bash
# ship_gate.sh — TransformFit Harness HARD-AND ship gate orchestrator.
#
# Mirrors rig-design-studio/gtm gate-shared.mjs (the anti-fake-green law) +
# bridge.json (artifact-type routing). HARD-AND over the BUILT Tier-1 gates:
#   doctrine_lint  ∧  message_rule_lint  ∧  design_lint  ∧  build_test_gate
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

FLUTTER_SDK="/Users/rig128gb/Developer/flutter-sdk"
export PATH="${FLUTTER_SDK}/bin:${PATH}"

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

# ── Tier-1 gate 1/4: doctrine_lint on the coach message ─────────────────────
echo "── Tier-1 1/4: doctrine_lint ───────────────────────────────────────────"
if python3 "${DOCTRINE_LINT}" "${MESSAGE}"; then
  record_green "doctrine_lint"
else
  record_red "doctrine_lint (exit $?)"
fi
echo

# ── Tier-1 gate 2/4: message_rule_lint on the coach message ─────────────────
echo "── Tier-1 2/4: message_rule_lint ───────────────────────────────────────"
if python3 "${MESSAGE_RULE_LINT}" "${MESSAGE}"; then
  record_green "message_rule_lint"
else
  record_red "message_rule_lint (exit $?)"
fi
echo

# ── Tier-1 gate 3/4: design_lint on the screen sample ───────────────────────
echo "── Tier-1 3/4: design_lint ─────────────────────────────────────────────"
if bash "${DESIGN_LINT}" "${SCREEN}"; then
  record_green "design_lint"
else
  record_red "design_lint (exit $?)"
fi
echo

# ── Tier-1 gate 4/4: build_test_gate on the Flutter project ─────────────────
echo "── Tier-1 4/4: build_test_gate ──────────────────────────────────────────"
if bash "${BUILD_TEST_GATE}" "${REPO_ROOT}"; then
  record_green "build_test_gate"
else
  record_red "build_test_gate (exit $?)"
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

# Also seal the screen artifact so both a coach message AND a screen have a
# ProofPacket (VAL-CROSS-011 end-to-end seal on both sample types).
if [ "$SEAL_OK" -eq 1 ]; then
  if ! python3 "${SEALER}" "${SCREEN}" --identity "${IDENTITY}" --packets-dir "${PACKETS_DIR}" 2>>"${PACKETS_DIR}/.seal_stderr"; then
    echo "[SHIP-GATE: ERROR] screen ProofPacket seal failed (exit $?)" >&2
    cat "${PACKETS_DIR}/.seal_stderr" >&2 2>/dev/null || true
    fail=1
  fi
fi

if [ "$fail" -ne 0 ]; then
  echo "[SHIP-GATE: RED] seal failed after GREEN gates — no valid ProofPacket." >&2
  exit 1
fi

echo "[SHIP-GATE: GREEN] ProofPacket(s) sealed under ${PACKETS_DIR}/ (FISH fields + deterministic hash)."
echo "[SHIP-GATE: GREEN] Tier 2/3 logged as RECORDED-PENDING/future — not auto-greened, not blocking."
exit 0
