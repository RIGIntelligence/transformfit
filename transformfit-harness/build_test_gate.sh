#!/usr/bin/env bash
# build_test_gate.sh — TransformFit Harness Tier-1 build + test gate.
#
# Runs `flutter analyze` AND `flutter test` against the real Flutter project.
# HARD-AND: exits 0 ONLY when both pass; exits non-zero if either fails
# (VAL-HAR-018, VAL-HAR-019, VAL-CROSS-002). Fail-closed, deterministic,
# GREEN/RED only.
#
# The gate prefers an already configured Flutter on PATH, then falls back to
# known local installs. FLUTTER_SDK may override discovery when needed.
#
# Usage:
#   bash build_test_gate.sh [repo-root]
#   bash build_test_gate.sh            # repo-root auto-detected (..)
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
REPO_ROOT="${1:-$(cd "${SCRIPT_DIR}/.." && pwd)}"

fail=0
red()   { echo "  ✗ RED   $1"; fail=1; }
green() { echo "  ✓ GREEN $1"; }

echo "[BUILD-TEST-GATE] repo: ${REPO_ROOT}"

if [ ! -f "${REPO_ROOT}/pubspec.yaml" ]; then
  echo "ERROR: pubspec.yaml not found at ${REPO_ROOT} — not a Flutter project root" >&2
  exit 2
fi
if ! command -v flutter >/dev/null 2>&1; then
  echo "ERROR: flutter not on PATH; set FLUTTER_SDK or install Flutter" >&2
  exit 2
fi

cd "${REPO_ROOT}" || { echo "ERROR: cannot cd to ${REPO_ROOT}" >&2; exit 2; }

echo "[BUILD-TEST-GATE] flutter: $(command -v flutter)"
flutter --version | sed -n '1p'

echo "[BUILD-TEST-GATE] socket preflight:"
python3 - <<'PY'
import socket
for host, family in [("127.0.0.1", socket.AF_INET), ("0.0.0.0", socket.AF_INET), ("::1", socket.AF_INET6), ("::", socket.AF_INET6)]:
    s = socket.socket(family, socket.SOCK_STREAM)
    try:
        s.bind((host, 0))
        print(f"  GREEN bind {host}")
    except OSError as exc:
        print(f"  RED   bind {host}: {exc}")
    finally:
        s.close()
PY

# Stage 1 — flutter analyze.
echo
echo "── Stage 1/2: flutter analyze ───────────────────────────────"
if flutter analyze; then
  green "flutter analyze passed"
  analyze_rc=0
else
  red "flutter analyze failed (exit $?)"
  analyze_rc=1
fi

# Stage 2 — flutter test.
echo
echo "── Stage 2/2: flutter test ──────────────────────────────────"
if flutter test; then
  green "flutter test passed"
  test_rc=0
else
  red "flutter test failed (exit $?)"
  test_rc=1
fi

echo
echo "------------------------------------------------------------"
echo "  analyze: $([ $analyze_rc -eq 0 ] && echo GREEN || echo RED)   test: $([ $test_rc -eq 0 ] && echo GREEN || echo RED)"
if [ $analyze_rc -eq 0 ] && [ $test_rc -eq 0 ]; then
  echo "[BUILD-TEST-GATE: GREEN] both flutter analyze and flutter test passed"
  exit 0
else
  [ $analyze_rc -ne 0 ] && echo "[BUILD-TEST-GATE: RED] flutter analyze failed"
  [ $test_rc -ne 0 ]     && echo "[BUILD-TEST-GATE: RED] flutter test failed"
  echo "[BUILD-TEST-GATE: RED] HARD-AND failed — one or both stages failed"
  exit 1
fi
