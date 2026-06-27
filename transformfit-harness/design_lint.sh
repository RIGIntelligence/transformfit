#!/usr/bin/env bash
# design_lint.sh — TransformFit Harness Tier-1 design lint.
#
# Mirrors rig-design-studio/.rig/verify-design-laws.sh (deterministic grep
# tripwires) + rig-gtm-studio-v2/.../deviation_engines.py (per-rule named
# engines). DETERMINISTIC-BEFORE-AGENTIC: these are mechanical checks, not
# taste. Exit 0 = GREEN, non-zero = RED (fail-closed).
#
# Implements Doctrine L4 design laws (TRANSFORMFIT-DOCTRINE.md L4-1/L4-2):
#   R1 orange_restraint   — #F97316 used <= 3 times per screen
#   R2 wcag_aa_contrast   — every fg/bg pair meets WCAG AA (>= 4.5:1)
#   R3 font_role          — Playfair = coach voice, Inter = data
#   R4 radius_range       — corner radius 0-4px
#
# The canonical token values below are the SINGLE SOURCE OF TRUTH the lint
# checks against. They MUST be byte-identical to TRANSFORMFIT-DOCTRINE.md L4
# AND to lib/theme/digital_atelier.dart (3-way match, no drift — VAL-CROSS-016).
# Run `design_lint.sh --verify-tokens` to prove the 3-way match at runtime.
#
# Usage:
#   bash design_lint.sh <sample.json>          # lint a design sample
#   bash design_lint.sh --verify-tokens        # prove 3-way token match
#   bash design_lint.sh --verify-tokens <repo-root>
#
# Sample format (JSON):
#   {
#     "screen": "name",
#     "contrast_pairs": [{"fg":"#F0EDE8","bg":"#0A0A0A","label":"..."}],
#     "orange_uses": ["...","...","..."],
#     "fonts": [{"element":"...","role":"coach_voice|data","family":"Playfair|Inter"}],
#     "radii": [{"element":"...","radius": 4}]
#   }
set -u

# ── Canonical Digital Atelier tokens (3-way match source of truth) ──────────
CANON_BG="#0A0A0A"
CANON_TEXT="#F0EDE8"
CANON_ORANGE="#F97316"
CANON_COACH_FONT="Playfair"
CANON_DATA_FONT="Inter"
CANON_RADIUS_MAX=4
WCAG_AA_THRESHOLD="4.5"

# Resolve repo root (parent of the harness dir) for --verify-tokens.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT_DEFAULT="$(cd "${SCRIPT_DIR}/.." && pwd)"

print_usage() {
  cat <<EOF
Usage: bash design_lint.sh <sample.json>          # lint a design sample
       bash design_lint.sh --verify-tokens [repo-root]  # 3-way token match
EOF
}

# ── --verify-tokens: prove Doctrine L4 / Flutter app / design_lint match ────
verify_tokens() {
  repo_root="${1:-${REPO_ROOT_DEFAULT}}"
  doctrine="${repo_root}/TRANSFORMFIT-DOCTRINE.md"
  flutter_tokens="${repo_root}/lib/theme/digital_atelier.dart"
  fail=0
  red_t()   { echo "  ✗ RED   $1"; fail=1; }
  green_t() { echo "  ✓ GREEN $1"; }

  echo "[DESIGN-LINT:VERIFY-TOKENS] repo: ${repo_root}"
  [ -f "$doctrine" ]        || { red_t "Doctrine file missing: $doctrine"; exit 1; }
  [ -f "$flutter_tokens" ] || { red_t "Flutter tokens file missing: $flutter_tokens"; exit 1; }

  # Extract the L4 token section from the Doctrine (between "## L4" and "## L5").
  l4_section="$(awk '/^## L4 Design/{f=1} /^## L5 Business/{f=0} f' "$doctrine")"

  check_doctrine() {  # <needle>
    if printf '%s' "$l4_section" | grep -qF "$1"; then green_t "Doctrine L4 contains $1"; else red_t "Doctrine L4 missing $1"; fi
  }
  check_flutter() {  # <needle>
    if grep -qF "$1" "$flutter_tokens"; then green_t "Flutter tokens contain $1"; else red_t "Flutter tokens missing $1"; fi
  }

  echo "  -- background #0A0A0A --"
  [ "$CANON_BG" = "#0A0A0A" ] && green_t "design_lint CANON_BG=#0A0A0A" || red_t "design_lint CANON_BG drift"
  check_doctrine "#0A0A0A"; check_flutter "0xFF0A0A0A"
  echo "  -- text #F0EDE8 --"
  [ "$CANON_TEXT" = "#F0EDE8" ] && green_t "design_lint CANON_TEXT=#F0EDE8" || red_t "design_lint CANON_TEXT drift"
  check_doctrine "#F0EDE8"; check_flutter "0xFFF0EDE8"
  echo "  -- orange #F97316 --"
  [ "$CANON_ORANGE" = "#F97316" ] && green_t "design_lint CANON_ORANGE=#F97316" || red_t "design_lint CANON_ORANGE drift"
  check_doctrine "#F97316"; check_flutter "0xFFF97316"
  echo "  -- coach font Playfair --"
  [ "$CANON_COACH_FONT" = "Playfair" ] && green_t "design_lint CANON_COACH_FONT=Playfair" || red_t "design_lint coach font drift"
  check_doctrine "Playfair"; check_flutter "'Playfair'"
  echo "  -- data font Inter --"
  [ "$CANON_DATA_FONT" = "Inter" ] && green_t "design_lint CANON_DATA_FONT=Inter" || red_t "design_lint data font drift"
  check_doctrine "Inter"; check_flutter "'Inter'"
  echo "  -- radius 0-4px --"
  [ "$CANON_RADIUS_MAX" -eq 4 ] && green_t "design_lint CANON_RADIUS_MAX=4 (0-4px)" || red_t "design_lint radius drift"
  check_doctrine "0-4px"; check_flutter "cornerRadius = 4"

  echo "------------------------------------------------------------"
  if [ "$fail" -eq 0 ]; then
    echo "[DESIGN-LINT:TOKENS GREEN] 3-way match — Doctrine L4 / Flutter app / design_lint"
    exit 0
  else
    echo "[DESIGN-LINT:TOKENS RED] token drift detected — single source of truth violated"
    exit 1
  fi
}

# ── arg parsing ─────────────────────────────────────────────────────────────
if [ "$#" -lt 1 ]; then
  print_usage
  echo "ERROR: no arguments provided" >&2
  exit 2
fi

if [ "$1" = "--verify-tokens" ]; then
  shift
  verify_tokens "${1:-}"
  exit $?
elif [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
  print_usage
  exit 0
fi

SAMPLE="$1"
if [ ! -f "$SAMPLE" ]; then
  echo "ERROR: sample file not found: $SAMPLE" >&2
  exit 2
fi

# ── core analysis (python3 for JSON parse + WCAG contrast float math) ────────
# Pass canonical values + sample path to python via environment.
export TF_CANON_BG="$CANON_BG"
export TF_CANON_TEXT="$CANON_TEXT"
export TF_CANON_ORANGE="$CANON_ORANGE"
export TF_CANON_COACH_FONT="$CANON_COACH_FONT"
export TF_CANON_DATA_FONT="$CANON_DATA_FONT"
export TF_CANON_RADIUS_MAX="$CANON_RADIUS_MAX"
export TF_WCAG_AA_THRESHOLD="$WCAG_AA_THRESHOLD"
export TF_SAMPLE="$SAMPLE"

python3 - <<'PYEOF'
import json
import os
import re
import sys

CANON_BG = os.environ["TF_CANON_BG"].lstrip("#").lower()
CANON_TEXT = os.environ["TF_CANON_TEXT"].lstrip("#").lower()
CANON_ORANGE = os.environ["TF_CANON_ORANGE"].lstrip("#").lower()
CANON_COACH_FONT = os.environ["TF_CANON_COACH_FONT"]
CANON_DATA_FONT = os.environ["TF_CANON_DATA_FONT"]
CANON_RADIUS_MAX = int(os.environ["TF_CANON_RADIUS_MAX"])
WCAG_AA = float(os.environ["TF_WCAG_AA_THRESHOLD"])
SAMPLE = os.environ["TF_SAMPLE"]


def hex_to_rgb(h):
    h = h.lstrip("#").lower()
    if len(h) == 3:
        h = "".join(c * 2 for c in h)
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def channel_lum(c):
    cs = c / 255.0
    return cs / 12.92 if cs <= 0.03928 else ((cs + 0.055) / 1.055) ** 2.4


def luminance(hex_color):
    r, g, b = hex_to_rgb(hex_color)
    return 0.2126 * channel_lum(r) + 0.7152 * channel_lum(g) + 0.0722 * channel_lum(b)


def contrast_ratio(fg, bg):
    l1 = luminance(fg)
    l2 = luminance(bg)
    light, dark = (l1, l2) if l1 >= l2 else (l2, l1)
    return (light + 0.05) / (dark + 0.05)


def norm_hex(h):
    h = h.lstrip("#").lower()
    if len(h) == 3:
        h = "".join(c * 2 for c in h)
    return h


fail = False
findings = []


def red(rule, detail):
    global fail
    fail = True
    findings.append(("RED", rule, detail))


def green(rule, detail):
    findings.append(("GREEN", rule, detail))


# Load sample JSON.
try:
    with open(SAMPLE, encoding="utf-8") as f:
        sample = json.load(f)
except Exception as e:
    print(f"ERROR: could not parse sample JSON {SAMPLE}: {e}", file=sys.stderr)
    sys.exit(2)

screen = sample.get("screen", "(unnamed)")
print(f"[DESIGN-LINT] screen: {screen}  file: {SAMPLE}")

# R1 — orange restraint (#F97316 <= 3 uses per screen).
orange_uses = sample.get("orange_uses", [])
if not isinstance(orange_uses, list):
    orange_uses = []
orange_count = len(orange_uses)
if orange_count <= 3:
    green("R1_orange_restraint", f"#F97316 used {orange_count} time(s) (<=3) — L4-2")
else:
    red("R1_orange_restraint", f"#F97316 used {orange_count} time(s) (>3) — L4-2 orange-restraint violated: {orange_uses}")

# R2 — WCAG AA contrast on every fg/bg pair.
contrast_pairs = sample.get("contrast_pairs", [])
if not isinstance(contrast_pairs, list) or not contrast_pairs:
    red("R2_wcag_aa_contrast", "no contrast_pairs declared — cannot verify L4-1 contrast (L4-1)")
else:
    for pair in contrast_pairs:
        fg = pair.get("fg", "")
        bg = pair.get("bg", "")
        label = pair.get("label", f"{fg} on {bg}")
        try:
            ratio = contrast_ratio(fg, bg)
        except Exception as e:
            red("R2_wcag_aa_contrast", f"could not compute contrast for '{label}': {e}")
            continue
        if ratio >= WCAG_AA:
            green("R2_wcag_aa_contrast", f"'{label}': contrast {ratio:.2f}:1 (>= {WCAG_AA}:1 AA) — L4-1")
        else:
            red("R2_wcag_aa_contrast", f"'{label}': contrast {ratio:.2f}:1 (< {WCAG_AA}:1 AA) — L4-1 WCAG AA contrast violated")

# R3 — font-role usage (Playfair = coach voice, Inter = data).
fonts = sample.get("fonts", [])
if not isinstance(fonts, list) or not fonts:
    red("R3_font_role", "no fonts declared — cannot verify L4-1 font roles (L4-1)")
else:
    for entry in fonts:
        element = entry.get("element", "(?)")
        role = entry.get("role", "")
        family = entry.get("family", "")
        expected = CANON_COACH_FONT if role == "coach_voice" else CANON_DATA_FONT if role == "data" else None
        if expected is None:
            red("R3_font_role", f"element '{element}': unknown role '{role}' (expected coach_voice|data) — L4-1")
        elif family == expected:
            green("R3_font_role", f"element '{element}': role '{role}' -> {family} (correct) — L4-1")
        else:
            red("R3_font_role", f"element '{element}': role '{role}' -> {family} (expected {expected}) — L4-1 font-role violated")

# R4 — radius range (0-4px).
radii = sample.get("radii", [])
if not isinstance(radii, list) or not radii:
    red("R4_radius_range", "no radii declared — cannot verify L4-1 radius (L4-1)")
else:
    for entry in radii:
        element = entry.get("element", "(?)")
        try:
            r = float(entry.get("radius"))
        except (TypeError, ValueError):
            red("R4_radius_range", f"element '{element}': radius not a number ({entry.get('radius')}) — L4-1")
            continue
        if 0 <= r <= CANON_RADIUS_MAX:
            green("R4_radius_range", f"element '{element}': radius {r:g}px (0-4px) — L4-1")
        else:
            red("R4_radius_range", f"element '{element}': radius {r:g}px (outside 0-4px) — L4-1 radius-range violated")

# Print findings.
print()
for verdict, rule, detail in findings:
    mark = "✓" if verdict == "GREEN" else "✗"
    print(f"  {mark} {verdict:5} {rule}: {detail}")
print("------------------------------------------------------------")
if not fail:
    print(f"[DESIGN-LINT: GREEN] screen '{screen}' — all design laws pass")
    sys.exit(0)
else:
    failed = sorted({r for v, r, _ in findings if v == "RED"})
    print(f"[DESIGN-LINT: RED] screen '{screen}' — {len(findings)} finding(s), failed rules: {', '.join(failed)}")
    sys.exit(1)
PYEOF
