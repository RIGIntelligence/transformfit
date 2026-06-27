#!/usr/bin/env python3
"""
doctrine_lint.py — TransformFit Harness Tier-1 doctrine lint.

Structural scan mirroring rig-instagram-studio/anti_slop/slop_detector.py:
loads banned_phrases.json at runtime (JSON-driven, NOT hardcoded), scans an
input file for banned phrase matches, and reports GREEN (exit 0, zero
matches) or RED (exit non-zero, fail-closed) with matched pattern(s) and
their L1/L2 layer.

This is the kill-switch for the dai-adapt silent hardcoded-template fallback
and all Doctrine L1/L2 banned anti-patterns (body-shame, generic-fitness
slop, false promises, streak-shame, guilt, over-notification, fake scarcity,
dark-pattern cancel, motivational-theatre, silent-fallback).

Usage:
    python3 doctrine_lint.py <file>
    python3 doctrine_lint.py <file> --json   # machine-readable output

Exit codes:
    0  = GREEN (0 banned patterns matched)
    1  = RED   (>=1 banned pattern matched — fail-closed)
    2  = ERROR (could not load banned_phrases.json or read input file)
"""
from __future__ import annotations

import argparse
import json
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent
BANNED_PATH = ROOT / "banned_phrases.json"


def load_banned(path: pathlib.Path = BANNED_PATH) -> dict:
    """Load and validate banned_phrases.json. Raises on invalid JSON or structure."""
    data = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(data, dict):
        raise ValueError("banned_phrases.json root must be an object")
    # Require L1 and L2 keys (VAL-HAR-001).
    for layer in ("L1", "L2"):
        if layer not in data or not isinstance(data[layer], dict):
            raise ValueError(f"banned_phrases.json missing required layer key: {layer}")
    # Require the 4 categories present in L1 (VAL-HAR-001).
    required_categories = ("body_shame", "generic_fitness_slop", "false_promises", "streak_shame")
    for cat in required_categories:
        if cat not in data["L1"] or not isinstance(data["L1"][cat], list):
            raise ValueError(f"banned_phrases.json L1 missing required category: {cat}")
    return data


def flatten_banned(data: dict) -> list[dict]:
    """Flatten the L1/L2 nested structure into a flat scan list.

    Returns [{phrase, layer, category}, ...] for every phrase entry.
    Skips _meta and any non-list entries.
    """
    out = []
    for layer in ("L1", "L2"):
        block = data.get(layer, {})
        if not isinstance(block, dict):
            continue
        for category, phrases in block.items():
            if category.startswith("_"):
                continue
            if not isinstance(phrases, list):
                continue
            for p in phrases:
                if not isinstance(p, str) or not p.strip():
                    continue
                out.append({
                    "phrase": p.lower(),
                    "layer": layer,
                    "category": category,
                })
    return out


def scan(text: str, banned_flat: list[dict]) -> list[dict]:
    """Scan text for banned phrase matches (case-insensitive substring match).

    Returns list of matched findings: [{phrase, layer, category}, ...].
    """
    lower = text.lower()
    hits = []
    for entry in banned_flat:
        if entry["phrase"] in lower:
            hits.append(entry)
    return hits


def run(path: pathlib.Path, banned_path: pathlib.Path = BANNED_PATH, json_out: bool = False) -> int:
    """Run the lint on a file. Returns process exit code."""
    # Load banned phrases JSON at runtime (JSON-driven, not hardcoded).
    try:
        data = load_banned(banned_path)
    except Exception as e:
        msg = f"ERROR: could not load banned_phrases.json: {e}"
        if json_out:
            print(json.dumps({"verdict": "ERROR", "error": str(e)}, indent=2))
        else:
            print(msg, file=sys.stderr)
        return 2

    try:
        text = path.read_text(encoding="utf-8")
    except Exception as e:
        msg = f"ERROR: could not read input file {path}: {e}"
        if json_out:
            print(json.dumps({"verdict": "ERROR", "error": str(e)}, indent=2))
        else:
            print(msg, file=sys.stderr)
        return 2

    banned_flat = flatten_banned(data)
    hits = scan(text, banned_flat)

    if json_out:
        result = {
            "verdict": "RED" if hits else "GREEN",
            "matched_patterns": hits,
            "total_matches": len(hits),
            "file": str(path),
        }
        print(json.dumps(result, indent=2))
    else:
        if hits:
            print(f"RED doctrine_lint: {len(hits)} banned pattern(s) matched in {path}")
            print()
            print("Matched patterns:")
            for h in hits:
                print(f"  - '{h['phrase']}' [{h['layer']}/{h['category']}]")
        else:
            print(f"GREEN doctrine_lint: 0 banned patterns in {path}")

    return 1 if hits else 0


def main() -> None:
    ap = argparse.ArgumentParser(description="TransformFit doctrine lint (GREEN/RED, fail-closed, JSON-driven)")
    ap.add_argument("file", type=pathlib.Path, help="file to scan")
    ap.add_argument("--banned", type=pathlib.Path, default=BANNED_PATH,
                    help="path to banned_phrases.json (default: co-located)")
    ap.add_argument("--json", action="store_true", help="machine-readable JSON output")
    args = ap.parse_args()

    sys.exit(run(args.file, args.banned, args.json))


if __name__ == "__main__":
    main()
